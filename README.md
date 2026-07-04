# teamclaude

A versioned repo of Claude Code agents, skills, and artifact templates that installs into any new project with one command — turning Claude Code into a senior software team that takes a project from intake to merged code with only two approval gates.

## Install

```bash
curl -sL https://raw.githubusercontent.com/jesjugroo/claude-team/main/install.sh | bash -s -- --stack next-convex
```

| Flag | Meaning |
|---|---|
| `--stack <name>` | Required. Scaffolded stacks: `next-convex`, `tauri`, `expo`, `extension` (keeps only the matching scaffold skill). Any other name (`unity`, `react-spa`, …) installs without a scaffold — the architect derives structure from reference repos instead. |
| `--version <tag>` | Team version to install (e.g. `v1.0`). Defaults to the latest tag — never main HEAD. |
| `--force` | Overwrite an existing `.claude/` directory. |

Env: `TEAMCLAUDE_REPO` overrides the source repo URL.

The installer copies `agents/` and `skills/` into `./.claude/`, the Overseer `CLAUDE.md` into the repo root, seeds `team/` stubs (never clobbering existing project state), and stamps the installed tag into `team/state.md`. Needs only git, curl, and coreutils.

## How it works

```
INTAKE (main thread Q&A)
   │  writes plan.md
   ▼
══ GATE 1: User approves plan ══
   │
   ├─► architect ──► architecture.md + scaffold
   ├─► cicd ──────► repo, CI, branch rules
   └─► seer ──────► board.md (stories, criteria, order)
   │
   ▼
TASK LOOP (per card, lowest Order first)
   │
   ├► dev ────── implements on feature branch
   ├► reviewer ─ task mode ── fail ─► dev (max 2 loops → escalate)
   ├► tester ─── tests + report ── bugs → new cards
   ├► seer ───── validates criteria vs evidence
   └► Overseer ─ card → Done, commit, state.md, next card
   │
   ▼
══ GATE 2: reviewer merge mode + CI green + User approves ══
   │
   ▼
PUSH TO MAIN
```

The main Claude Code session is the **Overseer** — the only process that dispatches agents. Agents communicate through artifacts in `team/`, never messages. Between the two gates the team runs autonomously; it escalates only for review loops >2, ambiguous criteria, or destructive actions.

## Agent roster

| Agent | reads | writes | never |
|---|---|---|---|
| `seer` | plan.md, board-conventions, test-report.md (validate mode) | board.md | writes code; marks Done without evidence |
| `architect` | plan.md, stack skill, reference-library | architecture.md, scaffold | implements features; skips Decisions section |
| `dev` | one story, architecture.md, standards | code on feature branch | touches board.md; edits other stories' files; writes tests |
| `reviewer` | diff, standards, architecture.md | review-report.md | implements fixes; reviews own suggestions |
| `tester` | story criteria, code | tests/ (all tests, unit + criteria), test-report.md, bug cards | fixes code; deletes failing tests |
| `cicd` | plan.md, gh-workflows skill | .github/, repo config | touches application code |

## Versioning

Releases are annotated git tags (`v1.0`, `v1.1`, …). Every consuming project pins one — the installed tag is stamped into `team/state.md`, and re-running the installer with that tag reproduces identical files.

**Major bump** when a change breaks consuming projects: artifact formats or paths in `team/`, agent contract changes (reads/writes/never), or installer flag changes. Everything else is a minor bump.

## Adding a new stack

Any stack already works without a scaffold — the architect derives structure from reference repos. Add a scaffold skill when a stack becomes recurring:

1. Create `template/skills/scaffold-<name>/SKILL.md` with: setup commands, folder tree, structure rules, required config, stack-specific standards, and failure classes for the tester.
2. Add `<name>` to `SCAFFOLDED_STACKS` in `install.sh`.
3. Add 2–3 exemplar repos for the stack to `template/skills/reference-library.md`.
4. Add the stack's CI variation to `template/skills/gh-workflows/SKILL.md`.
5. Tag a minor release.

## Adding a new agent

1. Create `template/agents/<name>.md` following the format in the repo's engineering guidelines: frontmatter, Contract (reads/writes/never — `never:` is mandatory), Senior protocol reference, Procedure, Done when, Output format. Keep it under ~120 lines.
2. Reference skills by path — never duplicate their content.
3. Wire the dispatch point into `template/CLAUDE.md` (setup phase or task loop).
4. Update the agent roster table above.
5. New agent = minor bump; changing an existing agent's contract = major bump.
