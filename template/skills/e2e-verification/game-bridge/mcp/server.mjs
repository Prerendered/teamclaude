#!/usr/bin/env node
// Game test bridge — MCP wrapper (e2e-verification layer 3).
// Runs outside the game: lifecycle tools (deploy, restart, load save) plus
// proxies to the in-game bridge over 127.0.0.1 JSON lines.
// Project-specific values live in bridge.config.json next to this file.
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';
import { spawn, execFileSync } from 'node:child_process';
import { promises as fs, readFileSync } from 'node:fs';
import net from 'node:net';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const CONFIG_PATH = process.env.GAME_BRIDGE_CONFIG ?? path.join(HERE, 'bridge.config.json');
const config = JSON.parse(readFileSync(CONFIG_PATH, 'utf8'));
const port = config.port ?? 27420;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// One request per connection keeps the in-game side trivial.
let nextId = 1;
const call = (method, params = {}, timeoutMs = config.requestTimeoutMs ?? 5000) =>
  new Promise((resolve, reject) => {
    const socket = net.createConnection({ host: '127.0.0.1', port });
    const id = nextId++;
    let buf = '';
    const timer = setTimeout(() => { socket.destroy(); reject(new Error(`bridge timeout on ${method}`)); }, timeoutMs);
    socket.on('connect', () => socket.write(`${JSON.stringify({ id, method, params })}\n`));
    socket.on('data', (chunk) => {
      buf += chunk;
      const nl = buf.indexOf('\n');
      if (nl < 0) return;
      clearTimeout(timer);
      socket.end();
      const res = JSON.parse(buf.slice(0, nl));
      res.error ? reject(new Error(res.error)) : resolve(res.result);
    });
    socket.on('error', (e) => { clearTimeout(timer); reject(e); });
  });

const ok = (value) => ({ content: [{ type: 'text', text: JSON.stringify(value, null, 2) }] });
const fail = (e) => ({ content: [{ type: 'text', text: `error: ${e.message}` }], isError: true });
const tool = (fn) => async (args) => { try { return ok(await fn(args)); } catch (e) { return fail(e); } };

const waitForHealth = async (timeoutSec) => {
  const deadline = Date.now() + timeoutSec * 1000;
  let last;
  while (Date.now() < deadline) {
    try { return await call('health', {}, 2000); } catch (e) { last = e; await sleep(1000); }
  }
  throw new Error(`bridge not healthy after ${timeoutSec}s (${last?.message ?? 'no response'})`);
};

const killGame = () => {
  const name = config.processName;
  if (!name) throw new Error('processName missing in bridge.config.json');
  try {
    if (process.platform === 'win32') execFileSync('taskkill', ['/IM', name, '/F'], { stdio: 'ignore' });
    else execFileSync('pkill', ['-x', name.replace(/\.exe$/, '')], { stdio: 'ignore' });
    return true;
  } catch { return false; } // not running
};

const launchGame = () => {
  if (!config.launch) throw new Error('launch missing in bridge.config.json');
  spawn(config.launch, { shell: true, detached: true, stdio: 'ignore' }).unref();
};

const server = new McpServer({ name: 'game-bridge', version: '1.0.0' });

server.registerTool('health', {
  description: 'Is the in-game bridge up? Returns mod version and readiness.',
  inputSchema: {},
}, tool(() => call('health')));

server.registerTool('list', {
  description: 'List the probes and commands the in-game bridge exposes.',
  inputSchema: {},
}, tool(() => call('list')));

server.registerTool('read_logs', {
  description: 'Log lines from the mod and loader since a cursor. Pass the returned cursor next time to get only new lines.',
  inputSchema: { since: z.number().int().min(0).default(0) },
}, tool(({ since }) => call('read_logs', { since })));

server.registerTool('query', {
  description: 'Run a named state probe (see list) and return structured game state.',
  inputSchema: { name: z.string(), args: z.record(z.string(), z.unknown()).default({}) },
}, tool(({ name, args }) => call('query', { name, args })));

server.registerTool('command', {
  description: 'Run a named setup action in the game (see list): teleport, give item, set flag, trigger event, …',
  inputSchema: { name: z.string(), args: z.record(z.string(), z.unknown()).default({}) },
}, tool(({ name, args }) => call('command', { name, args })));

server.registerTool('deploy_build', {
  description: 'Copy the freshly built mod files into the loader mods folder. The game must be stopped first.',
  inputSchema: {},
}, tool(async () => {
  const { buildFiles = [], modsDir } = config;
  if (!modsDir || !buildFiles.length) throw new Error('modsDir and buildFiles required in bridge.config.json');
  await fs.mkdir(modsDir, { recursive: true });
  const copied = [];
  for (const f of buildFiles) {
    const to = path.join(modsDir, path.basename(f));
    await fs.copyFile(path.resolve(HERE, f), to);
    copied.push(to);
  }
  return { copied };
}));

server.registerTool('stop_game', {
  description: 'Kill the game process.',
  inputSchema: {},
}, tool(() => ({ wasRunning: killGame() })));

server.registerTool('restart_game', {
  description: 'Kill the game, launch it, and wait until the in-game bridge reports healthy.',
  inputSchema: { deploy: z.boolean().default(false).describe('run deploy_build between stop and launch') },
}, tool(async ({ deploy }) => {
  killGame();
  await sleep(config.killGraceMs ?? 3000);
  if (deploy) {
    const { buildFiles = [], modsDir } = config;
    for (const f of buildFiles) await fs.copyFile(path.resolve(HERE, f), path.join(modsDir, path.basename(f)));
  }
  launchGame();
  return waitForHealth(config.readyTimeoutSec ?? 180);
}));

server.registerTool('load_test_save', {
  description: 'Load a named test save through the in-game command configured as loadSaveCommand, then wait for health.',
  inputSchema: { name: z.string() },
}, tool(async ({ name }) => {
  const cmd = config.loadSaveCommand;
  if (!cmd) throw new Error('loadSaveCommand missing in bridge.config.json');
  await call('command', { name: cmd, args: { save: name } }, config.loadTimeoutMs ?? 60000);
  return waitForHealth(config.readyTimeoutSec ?? 180);
}));

await server.connect(new StdioServerTransport());
