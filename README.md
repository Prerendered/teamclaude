# teamclaude

A versioned repo of Claude Code agents, skills, and artifact templates that installs into any project with one command — turning Claude Code into a senior software team that takes a project from intake (greenfield) or a codebase survey (brownfield) to merged code with only two approval gates.

## Install

```bash
curl -sL https://raw.githubusercontent.com/jesjugroo/claude-team/main/install.sh | bash -s -- --stack next-convex
```

| Flag | Meaning |
|---|---|
| `--stack <name>` | Required. Scaffolded stacks: `next-convex`, `tauri`, `expo`, `extension` (keeps only the matching scaffold skill). Any other name (`unity`, `react-spa`, …) installs without a scaffold — the architect derives structure from reference repos instead. |
| `--version <tag>` | Team version to install (e.g. `v1.0`). Defaults to the latest tag — never main HEAD. |
| `--repertoire <url>` | Optional. Git URL of a cross-project [repertoire](#repertoire-cross-project-memory) repo. When set, the team consults past projects at intake and saves this one at wrap. Omit to disable. |
| `--force` | Overwrite an existing `.claude/` directory. |

Env: `TEAMCLAUDE_REPO` overrides the source repo URL.

The installer copies `agents/` and `skills/` into `./.claude/`, the Overseer `CLAUDE.md` into the repo root, seeds `team/` stubs (never clobbering existing project state), and stamps the installed tag into `team/state.md`. Needs only git, curl, and coreutils.

## How it works

```
ENTRY
  greenfield ─► INTAKE (main thread Q&A) ──────────────► writes plan.md
  brownfield ─► ONBOARDING ─► scout ─► architecture.md + map.md
                            └─► change plan ──────────► writes plan.md
   │
   ▼
══ GATE 1: User approves plan ══
   │
   ├─► architect ──► architecture.md + scaffold   (greenfield)
   ├─► cicd ──────► repo, CI, branch rules
   ├─► designer ──► design.md + tokens            (UI stacks)
   └─► seer ──────► board.md (stories, criteria, order)
   │
   ▼
TASK LOOP (per card, lowest Order first)
   │
   ├► scout ──── brief mode: recon for unfamiliar code (on demand)
   ├► dev ────── feature card: implements on feature branch
   ├► refactor ─ refactor card: behavior-preserving cleanup, tests green before+after
   ├► reviewer ─ task mode ── fail ─► builder (max 2 loops → escalate)
   ├► security ─ security-sensitive card: card-mode review
   ├► tester ─── tests + report ── bugs → new cards
   ├► seer ───── validates criteria vs evidence
   └► Overseer ─ card → Done, commit, state.md, next card
   │
   ▼
══ GATE 2: reviewer merge + security merge + scribe docs + CI green + User approves ══
   │
   ▼
PUSH TO MAIN
   │
   ▼
PROJECT WRAP (if a repertoire is configured)
   └► archivist ─ distils the project → entry pushed to the repertoire repo
```

The main Claude Code session is the **Overseer** — the only process that dispatches agents. Agents communicate through artifacts in `team/`, never messages. Between the two gates the team runs autonomously; it escalates only for review loops >2, ambiguous criteria, or destructive actions. A high or critical security finding blocks Gate 2.

## Agent roster

| Agent | reads | writes | never |
|---|---|---|---|
| `seer` | plan.md, board-conventions, test-report.md (validate mode) | board.md | writes code; marks Done without evidence |
| `architect` | plan.md, stack skill, reference-library | architecture.md, scaffold | implements features; skips Decisions section |
| `scout` | existing codebase, codebase-survey, standards | architecture.md, map.md, recon briefs | writes code; invents structure the code lacks |
| `dev` | one story, architecture.md, design.md, standards | code on feature branch | touches board.md; edits other stories' files; writes tests |
| `refactor` | refactor card, target code, map.md, refactor-catalog, standards | refactored code on a branch | changes behavior; adds features; edits tests; refactors untested code |
| `reviewer` | diff, standards, architecture.md | review-report.md | implements fixes; reviews own suggestions |
| `security` | diff/branch, security-standards, architecture.md | security-report.md | implements fixes; passes without a dep check |
| `designer` | plan.md, design-system, existing UI | design.md, token config | writes business logic; ships a token without rationale |
| `tester` | story criteria, code | tests/ (all tests, unit + criteria), test-report.md, bug cards | fixes code; deletes failing tests |
| `scribe` | finished code, architecture.md, board.md | README.md, docs/ | changes code; documents unbuilt features |
| `cicd` | plan.md, gh-workflows skill | .github/, repo config | touches application code |
| `archivist` | team/ artifacts, state.md, repertoire skill | entry + ToC pushed to the repertoire repo | pushes to the project repo; includes secrets in an entry |

## Brownfield: dropped into an existing project

Install into a repo that already has code and, on the next session, the Overseer
detects existing source with no `team/` state and runs **Onboarding** instead of
Intake:

1. `scout` surveys the codebase and reverse-engineers `team/architecture.md` plus a
   `team/map.md` (entry points, modules, conventions in force, danger zones),
   filing standards drift as candidate refactor cards.
2. You confirm the map, then state what you want changed. The Overseer writes a
   *change plan* against the existing system.
3. After Gate 1, `seer` builds a board mixing **feature** and **refactor** cards.
   Refactor cards run through the `refactor` agent — behavior-preserving, with the
   same test suite green before and after (characterization tests come from
   `tester` first when coverage is missing).

During the loop, `scout` (brief mode) gives any builder focused recon on unfamiliar
code without dumping the whole repo into context.

## Repertoire: cross-project memory

Install with `--repertoire <url>` (e.g. `https://github.com/Prerendered/projects-repertoire.git`)
and every project feeds a shared library of past work, so the next one starts from
precedent instead of zero.

- **At wrap** (after push to main), `archivist` distils the finished project — its
  stack, decisions, patterns that worked, and pitfalls from the review/test/security
  reports — into an entry and, once you approve, pushes it to the repertoire repo.
- **At intake**, when a `repertoire:` is configured the Overseer raw-fetches the ToC
  (`raw.githubusercontent.com`, no clone) and proposes a matching past project's
  stack and patterns as the default; the architect gets the matched entries as
  references. Precedent is a default, never law — you confirm, deviations go in the
  Decisions block.

The repertoire is a plain git repo you own:

```
Projects/
├── README.md            ToC — | Project | Category | Stack | Tags | One-liner | Date |
└── <Category>/          e.g. Food/
    └── <project>/       e.g. meal-planner/
        └── README.md    the project entry
```

Tags on the ToC row are the match surface, so a single fetch finds precedent without
opening any entry. Entries never contain secrets — variable names only.

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
