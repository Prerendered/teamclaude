#!/usr/bin/env node
// teamclaude CLI — installs or updates the team template in the current project.
//   bunx github:Prerendered/teamclaude init   [--stack next-convex] [--repertoire <url>] [--force]
//   bunx github:Prerendered/teamclaude update [--stack next-convex] [--repertoire <url>]
// Only template-owned paths are ever removed: .claude/settings.json, a project's
// own agents/skills, and everything outside .claude/ survive both commands.
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
  `Usage: teamclaude init   [--stack <name>] [--repertoire <url>] [--force]
       teamclaude update [--stack <name>] [--repertoire <url>]

Commands:
  init                Install the team into a project that has none.
  update              Refresh an existing install to ${VERSION}. Replaces the
                      template's agents, skills, and CLAUDE.md; leaves your
                      .claude/settings.json, project-local agents/skills, and
                      team/ artifacts untouched.

Flags:
  --stack <name>      Optional. The stack is normally chosen at intake; pass it only
                      to decide up front. Scaffolded: ${SCAFFOLDED.join(', ')}.
                      Any other name installs without a scaffold. Omit to keep all
                      scaffold skills and let intake pick. On update, defaults to
                      the stack recorded in team/state.md.
  --repertoire <url>  Optional. Git URL of a cross-project repertoire repo.
  --force             init only. Reinstall over an existing .claude/ directory.`;

// ── parse args ────────────────────────────────────────────────────────────────
const argv = process.argv.slice(2);
if (argv[0] === '-h' || argv[0] === '--help') { console.log(usage()); process.exit(0); }
if (argv[0] === '-v' || argv[0] === '--version') { console.log(VERSION); process.exit(0); }

const cmd = argv[0];
if (cmd !== 'init' && cmd !== 'update') fail(`unknown command '${cmd ?? ''}'\n${usage()}`);

let stack = '', repertoire = '', force = false;
for (let i = 1; i < argv.length; i++) {
  const a = argv[i];
  if (a === '--stack') stack = argv[++i] ?? '';
  else if (a === '--repertoire') repertoire = argv[++i] ?? '';
  else if (a === '--force') force = true;
  else fail(`unknown flag: ${a}\n${usage()}`);
}
if (force && cmd === 'update') fail('--force is not valid for update — update never removes files it did not install');

if (!existsSync(TEMPLATE)) fail(`template/ missing at ${TEMPLATE} — corrupt package?`);

// ── shared install steps ──────────────────────────────────────────────────────
const upsert = (content, key, value) => {
  const line = `${key}: ${value}`;
  const re = new RegExp(`^${key}:.*$`, 'm');
  return re.test(content) ? content.replace(re, line) : `${line}\n${content}`;
};

const read = (f) => fs.readFile(f, 'utf8');

// Replace each entry the template ships, one by one. A blanket rm of .claude/
// would also take settings.json and any agent or skill the project added itself.
const syncTree = async (name) => {
  const src = path.join(TEMPLATE, name);
  const dest = path.join('.claude', name);
  await fs.mkdir(dest, { recursive: true });
  const owned = await fs.readdir(src);
  for (const entry of owned) {
    const to = path.join(dest, entry);
    await fs.rm(to, { recursive: true, force: true });
    await fs.cp(path.join(src, entry), to, { recursive: true });
  }
  const present = existsSync(dest) ? await fs.readdir(dest) : [];
  return present.filter((e) => !owned.includes(e)).map((e) => `${name}/${e}`);
};

// Stack decided up front → keep only its scaffold. Omitted → keep all; intake picks.
const pruneScaffolds = async (chosen) => {
  if (!chosen) return;
  for (const entry of await fs.readdir('.claude/skills')) {
    if (entry.startsWith('scaffold-') && entry !== `scaffold-${chosen}`) {
      await fs.rm(path.join('.claude/skills', entry), { recursive: true, force: true });
    }
  }
  if (SCAFFOLDED.includes(chosen) && !existsSync(path.join('.claude/skills', `scaffold-${chosen}`))) {
    fail(`scaffold skill for ${chosen} missing in this version`);
  }
};

// CLAUDE.md is template-owned, but a project may have appended to it. Keep a copy
// when we are about to change it so nothing is lost to an untracked overwrite.
const writeOverseer = async ({ backup }) => {
  const next = await read(path.join(TEMPLATE, 'CLAUDE.md'));
  const existed = existsSync('CLAUDE.md');
  const changed = !existed || (await read('CLAUDE.md')) !== next;
  if (changed && existed && backup) await fs.copyFile('CLAUDE.md', 'CLAUDE.md.bak');
  await fs.writeFile('CLAUDE.md', next);
  return changed && existed && backup;
};

// Seed team/ stubs — never clobber existing project state.
const seedTeam = async () => {
  await fs.mkdir('team', { recursive: true });
  const added = [];
  for (const f of await fs.readdir(path.join(TEMPLATE, 'team'))) {
    const dest = path.join('team', f);
    if (!existsSync(dest)) { await fs.cp(path.join(TEMPLATE, 'team', f), dest); added.push(f); }
  }
  return added;
};

const stampState = async () => {
  let state = await read('team/state.md');
  state = upsert(state, 'team-version', VERSION);
  if (stack) state = upsert(state, 'stack', stack);
  if (repertoire) state = upsert(state, 'repertoire', repertoire);
  await fs.writeFile('team/state.md', state);
};

const readStack = async () => {
  if (!existsSync('team/state.md')) return '';
  return (await read('team/state.md')).match(/^stack:\s*(.+)$/m)?.[1].trim() ?? '';
};

const reportPreserved = (preserved) => {
  if (preserved.length) console.log(`preserved (not from the template): ${preserved.join(', ')}`);
};

// ── init ──────────────────────────────────────────────────────────────────────
const init = async () => {
  if (existsSync('.claude') && !force) {
    fail('.claude/ already exists — run `teamclaude update` to refresh it, or `init --force` to reinstall');
  }
  const preserved = [...(await syncTree('agents')), ...(await syncTree('skills'))];
  await pruneScaffolds(stack);
  await writeOverseer({ backup: force });
  await seedTeam();
  await stampState();

  if (stack) {
    console.log(`teamclaude ${VERSION} installed (stack: ${stack}).`);
    if (!SCAFFOLDED.includes(stack)) console.log(`note: no scaffold skill for '${stack}' — the architect will derive structure from reference repos.`);
  } else {
    console.log(`teamclaude ${VERSION} installed. Stack: chosen at intake (all scaffold skills kept).`);
  }
  if (repertoire) console.log(`repertoire: ${repertoire} — consulted at intake, saved at wrap.`);
  reportPreserved(preserved);
  console.log("Open Claude Code and say 'new project' to start intake.");
};

// ── update ────────────────────────────────────────────────────────────────────
const update = async () => {
  if (!existsSync('.claude/agents') || !existsSync('team/state.md')) {
    fail('no teamclaude install found here (need .claude/agents and team/state.md) — run `teamclaude init` first');
  }
  const from = (await read('team/state.md')).match(/^team-version:\s*(.+)$/m)?.[1].trim() ?? 'unknown';
  stack = stack || (await readStack());

  const preserved = [...(await syncTree('agents')), ...(await syncTree('skills'))];
  await pruneScaffolds(stack);
  const backedUp = await writeOverseer({ backup: true });
  const seeded = await seedTeam();
  await stampState();

  console.log(`teamclaude ${from} → ${VERSION}. Refreshed: .claude/agents, .claude/skills, CLAUDE.md.`);
  console.log(stack ? `stack: ${stack} (from team/state.md unless overridden).` : 'stack: unset — all scaffold skills kept.');
  if (backedUp) console.log('CLAUDE.md replaced — your previous copy is at CLAUDE.md.bak. Diff it if you had added to it.');
  if (seeded.length) console.log(`new team/ stubs added: ${seeded.join(', ')}`);
  reportPreserved(preserved);
  console.log('Existing team/ artifacts and .claude/settings.json were not touched.');
};

(cmd === 'init' ? init() : update()).catch((e) => fail(e.message));
