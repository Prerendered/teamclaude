# teamclaude

A versioned repo of Claude Code agents, skills, and artifact templates that installs into any project with one command — turning Claude Code into a senior software team that takes a project from intake (greenfield) or a codebase survey (brownfield) to merged code. You approve the plan, pick the stack, and test each finished feature; the team does the rest.

## Install

From your project's root:

```bash
bunx github:Prerendered/teamclaude init
```

Downloads the template and lays the team into `./.claude/`, `CLAUDE.md`, and `team/`.
`team/` is the team's local working state (plan, boards, reports, story plans) and is added
to `.gitignore` so it never reaches your remote — pass `--track-team` to commit it.
`.worktrees/` (one checkout per story in flight) is always ignored.
The **stack is chosen at the Tech gate** (the architect researches options, you pick), so no flags are needed. `npx` works identically.
Pin a release with a ref: `bunx github:Prerendered/teamclaude#v2.0 init`.

| Flag | Meaning |
|---|---|
| `--stack <name>` | Optional. The stack is normally chosen at the Tech gate — pass this only to lock the app framework up front (the architect still researches the other use cases). Scaffolded stacks: `next-convex`, `tauri`, `expo`, `extension` (keeps only the matching scaffold skill). Any other name (`unity`, `react-spa`, …) installs without a scaffold. Omit to keep all scaffolds and let the Tech gate pick. |
| `--repertoire <url>` | Optional. Git URL of a cross-project [repertoire](#repertoire-cross-project-memory) repo. When set, the team consults past projects at intake and saves this one at wrap. Omit to disable. |
| `--track-team` | Optional. Commit `team/` with the project instead of gitignoring it. Recorded in `team/state.md`, so `update` keeps it. |
| `--force` | `init` only. Reinstall over an existing `.claude/` directory. |

**Updating** an existing install: `bunx github:Prerendered/teamclaude update`. It replaces the
template's agents, skills, and `CLAUDE.md` (a changed `CLAUDE.md` is kept as `CLAUDE.md.bak`),
seeds any new `team/` stubs, and leaves `.claude/settings.json`, your own agents/skills, and
existing `team/` artifacts untouched. The bash installer's equivalent is `--update`.

**Other ways to install**

```bash
# curl one-liner
curl -sL https://raw.githubusercontent.com/Prerendered/teamclaude/main/install.sh | bash

# clone and run — no network hop
git clone https://github.com/Prerendered/teamclaude.git
cd <your-project>
node ../teamclaude/bin/cli.mjs init
#   or the bash installer: bash ../teamclaude/install.sh --local
```

The bash installer (`install.sh -h`) additionally takes `--version <tag>` and `--local`.
It copies `agents/` and `skills/` into `./.claude/`, the Overseer `CLAUDE.md` into the
repo root, seeds `team/` stubs (never clobbering existing project state), and stamps the
installed version into `team/state.md`.

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
   ├─► architect ──► research: tech-options.md (per use case: ★ + 5 alternatives)
   ├══ TECH GATE: User picks the stack ══
   ├─► architect ──► architecture.md + scaffold (the one direct commit to main)
   ├─► cicd ──────► repo, CI, branch protection, auto-merge
   ├─► designer ──► design.md + tokens            (UI stacks)
   └─► seer ──────► board.md: features in delivery order, stories per feature
   │
   ▼
DELIVERY LOOP — one feature at a time (open critical/high bug first)
   │
   │  feature start: planner writes every story's plan at once (opus/fable),
   │  then one contract PR lands the feature's new types and constants
   │  then every READY story (Needs merged, no shared files) runs at once, up to wip: 4
   │  per story, in its own bootstrapped worktree (env + deps) on branch us-<n>-<slug>
   ├► dev ‖ tester ─ in parallel from the plan: dev builds, tester writes the tests
   │              └ QUESTION: technical → planner on fable · feature → User
   ├► tester ─── runs its tests against dev's code (flow tests per criterion)
   ├► reviewer ─ check: lint, typecheck, suite, standards, plan conformance
   ├► Overseer ─ opens the PR
   ├► reviewer ─ PR review posted on GitHub (+ security if sensitive)
   └► auto-merge on green CI ─► story Done
   │                 any FAIL ─► back to dev (escalate after 2)
   │
   ▼  every story of the feature merged
FEATURE ACCEPTANCE
   ├► reviewer + security ─ feature mode (opus) on the cumulative diff
   ├► verifier ──────────── runs the real app, drives it via MCP, reads logs/console/network
   ├► User tests the feature ─► findings → bug-board ─► Accepted
   └► scribe ─ docs PR
   │
   ▼  next feature … last feature Accepted
PROJECT WRAP (if a repertoire is configured)
   └► archivist ─ distils the project → entry pushed to the repertoire repo
```

The main Claude Code session is the **Overseer** — the only process that dispatches agents. Agents communicate through artifacts in `team/`, never messages.

`team/board.md` starts with a Features table (Building → Testing → Accepted), then stories
in sections — In Progress, In Review, Backlog, Done — so live work is at the top and history
sinks to the bottom. Bugs go on a separate `team/bug-board.md` (In Progress, Open, Fixed)
with a severity and a one-line repro. An Open critical/high bug is fixed before the next
story; medium/low are worked before the feature's acceptance. Each bug is fixed test-first:
tester writes a failing regression test, dev makes it pass.

**End-to-end verification** (`e2e-verification` skill) runs in three layers:
1. **Flow tests in code**, every story, in CI: tests that replay a whole user flow through
   the real logic and storage (Playwright for web UI).
2. **Runtime observation**, at feature acceptance: the `verifier` agent runs the real app
   and drives it, reading logs, console, network, and state. Web uses the Chrome DevTools
   MCP; every runtime component has a log source recorded in `architecture.md`
   `## Verification`.
3. **Game test bridge**, for game/mod projects: a dev-only bridge inside the game plus an
   MCP wrapper (`restart_game`, `deploy_build`, `load_test_save`, state probes, setup
   commands, logs), so a relaunch-and-set-up loop is one call. The scaffold ships in the
   skill; each project fills in its loader hooks, probes, and commands.

Project MCP servers live in a committed `.mcp.json`, pinned to exact versions — they ship
with the tests.

**Code standards** (`standards` skill) are split: a core every stack follows — naming from a per-project
glossary (one name per concept, so parallel agents agree), why-not-what comments with the usual
AI habits banned (changelog notes, ticket references, commented-out code), a one-line file header,
design principles, git — plus one file per language (`typescript`, `csharp`, `rust`) with its
casing, error model, and short ✗/✓ examples. Every rule a linter or compiler can check is enforced
by config in CI; the prose covers only what review must catch.

**Project layout** (standards, same for every stack): `src/` holds `features/<domain>/`, `lib/`, `types/<domain>` and `constants/<domain>` — every type and constant has one home, and a feature’s new ones land first in a small contract PR so parallel stories never collide. `tests/` at the root mirrors `src/` path for path, with `tests/flows/` for flow tests and `tests/tools/` for test tooling (MCP servers, the game bridge). Logs are never written to disk. Every folder carries a short README and the root README has a Project structure section, so a new dev or a fresh Claude session can find their way without `team/`.

**GitHub conventions.** One branch per ticket (`us-<n>-<slug>`, `b<n>-<slug>`). Commits and
PR titles are `<type>: <description>` — the PR title becomes the single squash commit on
main. PR bodies are lean: the ticket line, a short summary, the criteria checklist.
Everything is authored under your own git/gh identity with no AI attribution lines, so
reviews are posted as PR comments (GitHub won't let an author approve their own PR) and
green CI is the merge gate. A private repo on GitHub Free has no branch protection or
auto-merge; the team detects that and runs in manual merge mode, where the Overseer
waits for green CI and an up-to-date branch before it squash-merges.

After Gate 1 and the Tech gate the team runs autonomously. It comes back to you to test each finished
feature, for feature questions (behavior, criteria, scope), for review loops past 2, and
for destructive actions.

## Agent roster

| Agent | reads | writes | never |
|---|---|---|---|
| `seer` | plan.md, board-conventions | board.md (features + stories) | writes code; plans implementation |
| `planner` | story, architecture.md, map.md, design.md, the code, scout brief | plans/US-<n>.md (plan + Amendments) | writes code; changes criteria or scope; answers feature questions |
| `architect` | plan.md (constraints, invariants), web research, stack skill, reference-library | tech-options.md (research), architecture.md + scaffold (design) | implements features; lists tech that breaks the plan; picks the stack for the User |
| `scout` | existing codebase, codebase-survey, standards | architecture.md, map.md, recon briefs | writes code; invents structure the code lacks |
| `dev` | one story or bug card, its plan, architecture.md, standards | code + commits on the story branch | touches team/; edits files outside the plan; decides what the plan leaves closed; writes tests |
| `refactor` | refactor card, target code, map.md, refactor-catalog, standards | refactored code on a branch | changes behavior; adds features; edits tests; refactors untested code |
| `reviewer` | diff, plan, criteria, test-report.md, standards, architecture.md | review-report.md, PR review comment, bug cards (feature mode) | implements fixes; approves its own PR on GitHub |
| `security` | PR diff / feature diff, security-standards, architecture.md | security-report.md, PR review comment | implements fixes; passes without a dep check |
| `designer` | plan.md, design-system, existing UI | design.md, token config | writes business logic; ships a token without rationale |
| `tester` | story criteria or bug card, plan test list, code | tests/ + commits on the story branch, test-report.md, bug-board.md cards | fixes code; deletes failing tests; writes to board.md |
| `verifier` | feature criteria, architecture.md ## Verification, e2e-verification, `.mcp.json` servers | verify-report.md, bug-board.md cards | fixes code; passes a leg nothing exercised |
| `scribe` | merged code, architecture.md, board.md | README.md, docs/ on a docs PR | changes code; documents unbuilt features; links into team/ |
| `cicd` | plan.md, gh-workflows skill | .github/, branch protection, merge settings | touches application code |
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
  (`raw.githubusercontent.com`, no clone) and notes up to 2 matching past projects.
  The architect's research lists each one's tech as a candidate at the Tech gate,
  with its recorded pitfalls in the cons. Precedent is a candidate, never law — you
  pick, and the choice lands in the Decisions block.

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
5. New language? Add `template/skills/standards/<language>.md` — commands, the rules tooling enforces (with the config), review-only rules, and native ✗/✓ examples. Without one, the architect translates the core standards into `architecture.md ## Conventions` once per project.
6. Tag a minor release.

## Adding a new agent

1. Create `template/agents/<name>.md` following the format in the repo's engineering guidelines: frontmatter, Contract (reads/writes/never — `never:` is mandatory), Senior protocol reference, Procedure, Done when, Output format. Keep it under ~120 lines.
2. Reference skills by path — never duplicate their content.
3. Wire the dispatch point into `template/CLAUDE.md` (setup phase or delivery loop).
4. Update the agent roster table above.
5. New agent = minor bump; changing an existing agent's contract = major bump.
