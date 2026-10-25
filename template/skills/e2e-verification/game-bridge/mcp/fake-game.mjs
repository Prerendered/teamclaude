#!/usr/bin/env node
// Stand-in for the in-game bridge: same protocol, fake state. Lets the MCP
// wrapper and a project's verifier flow be tested without launching the game.
//   node fake-game.mjs [port]
import net from 'node:net';

const port = Number(process.argv[2] ?? process.env.GAME_BRIDGE_PORT ?? 27420);
const logs = [];
const log = (line) => logs.push(`[${new Date().toISOString()}] ${line}`);
const state = { position: { x: 0, y: 0, z: 0 }, inventory: {}, save: 'none' };

const probes = {
  player_position: () => state.position,
  inventory: () => state.inventory,
};
const commands = {
  teleport: ({ x = 0, y = 0, z = 0 }) => { state.position = { x, y, z }; log(`teleported to ${x},${y},${z}`); return state.position; },
  give_item: ({ item, count = 1 }) => { state.inventory[item] = (state.inventory[item] ?? 0) + count; log(`gave ${count}x ${item}`); return state.inventory; },
  load_save: ({ save }) => { state.save = save; log(`loaded save ${save}`); return { save }; },
};

const handle = ({ method, params = {} }) => {
  switch (method) {
    case 'health': return { ready: true, mod: 'fake-game', version: '0.0.0', save: state.save };
    case 'list': return { probes: Object.keys(probes), commands: Object.keys(commands) };
    case 'read_logs': return { lines: logs.slice(params.since ?? 0), cursor: logs.length };
    case 'query': {
      const probe = probes[params.name];
      if (!probe) throw new Error(`unknown probe: ${params.name}`);
      return probe(params.args ?? {});
    }
    case 'command': {
      const cmd = commands[params.name];
      if (!cmd) throw new Error(`unknown command: ${params.name}`);
      return cmd(params.args ?? {});
    }
    default: throw new Error(`unknown method: ${method}`);
  }
};

net.createServer((socket) => {
  let buf = '';
  socket.on('data', (chunk) => {
    buf += chunk;
    let nl;
    while ((nl = buf.indexOf('\n')) >= 0) {
      const req = JSON.parse(buf.slice(0, nl));
      buf = buf.slice(nl + 1);
      let res;
      try { res = { id: req.id, result: handle(req) }; } catch (e) { res = { id: req.id, error: e.message }; }
      socket.write(`${JSON.stringify(res)}\n`);
    }
  });
  socket.on('error', () => {});
}).listen(port, '127.0.0.1', () => { log('fake game bridge up'); console.log(`fake game bridge on 127.0.0.1:${port}`); });
