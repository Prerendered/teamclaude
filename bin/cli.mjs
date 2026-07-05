#!/usr/bin/env node
// teamclaude CLI — installs the team template into the current project.
//   bunx github:Prerendered/teamclaude init --stack next-convex [--repertoire <url>] [--force]
// Cross-platform (no bash). Keep the install logic in sync with install.sh.
import { promises as fs } from 'node:fs';
import { existsSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, '..');
const TEMPLATE = path.join(ROOT, 'template');
const SCAFFOLDED = ['next-convex', 'tauri', 'expo', 'extension'];
const VERSION = `v${JSON.parse(readFileSync(path.join(ROOT, 'package.json'), 'utf8')).version}`;

const fail = (msg) => { console.error(`error: ${msg}`); process.exit(1); };
const usage = () =>
  `Usage: teamclaude init --stack <name> [--repertoire <url>] [--force]

  --stack <name>      Required. Scaffolded stacks: ${SCAFFOLDED.join(', ')}.
                      Any other name (unity, react-spa, ...) installs without a
                      scaffold — the architect derives structure from references.
  --repertoire <url>  Optional. Git URL of a cross-project repertoire repo.
  --force             Overwrite an existing .claude/ directory.`;

// ── parse args ────────────────────────────────────────────────────────────────
const argv = process.argv.slice(2);
if (argv[0] === '-h' || argv[0] === '--help') { console.log(usage()); process.exit(0); }
if (argv[0] !== 'init') fail(`unknown command '${argv[0] ?? ''}'\n${usage()}`);

let stack = '', repertoire = '', force = false;
for (let i = 1; i < argv.length; i++) {
  const a = argv[i];
  if (a === '--stack') stack = argv[++i] ?? '';
  else if (a === '--repertoire') repertoire = argv[++i] ?? '';
  else if (a === '--force') force = true;
  else fail(`unknown flag: ${a}\n${usage()}`);
}
if (!stack) fail(`--stack is required\n${usage()}`);

const hasScaffold = SCAFFOLDED.includes(stack);

// ── install ───────────────────────────────────────────────────────────────────
if (!existsSync(TEMPLATE)) fail(`template/ missing at ${TEMPLATE} — corrupt package?`);
if (existsSync('.claude') && !force) fail('.claude/ already exists — re-run with --force to overwrite');

const upsert = (content, key, value) => {
  const line = `${key}: ${value}`;
  const re = new RegExp(`^${key}:.*$`, 'm');
  return re.test(content) ? content.replace(re, line) : `${line}\n${content}`;
};

const main = async () => {
  // agents + skills into .claude/, Overseer into repo root.
  await fs.rm('.claude', { recursive: true, force: true });
  await fs.mkdir('.claude', { recursive: true });
  await fs.cp(path.join(TEMPLATE, 'agents'), '.claude/agents', { recursive: true });
  await fs.cp(path.join(TEMPLATE, 'skills'), '.claude/skills', { recursive: true });
  await fs.cp(path.join(TEMPLATE, 'CLAUDE.md'), 'CLAUDE.md');

  // keep only the requested stack's scaffold skill.
  for (const entry of await fs.readdir('.claude/skills')) {
    if (entry.startsWith('scaffold-') && entry !== `scaffold-${stack}`) {
      await fs.rm(path.join('.claude/skills', entry), { recursive: true, force: true });
    }
  }
  if (hasScaffold && !existsSync(path.join('.claude/skills', `scaffold-${stack}`))) {
    fail(`scaffold skill for ${stack} missing in this version`);
  }

  // seed team/ stubs — never clobber existing project state.
  await fs.mkdir('team', { recursive: true });
  for (const f of await fs.readdir(path.join(TEMPLATE, 'team'))) {
    const dest = path.join('team', f);
    if (!existsSync(dest)) await fs.cp(path.join(TEMPLATE, 'team', f), dest);
  }

  // stamp version (and repertoire URL) into team/state.md.
  let state = await fs.readFile('team/state.md', 'utf8');
  state = upsert(state, 'team-version', VERSION);
  if (repertoire) state = upsert(state, 'repertoire', repertoire);
  await fs.writeFile('team/state.md', state);

  console.log(`teamclaude ${VERSION} installed (stack: ${stack}).`);
  if (!hasScaffold) console.log(`note: no scaffold skill for '${stack}' — the architect will derive structure from reference repos.`);
  if (repertoire) console.log(`repertoire: ${repertoire} — consulted at intake, saved at wrap.`);
  console.log("Open Claude Code and say 'new project' to start intake.");
};

main().catch((e) => fail(e.message));
