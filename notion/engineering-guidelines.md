# Engineering Guidelines

> Pulled from Notion 2026-07-04 — https://app.notion.com/p/393c946c280181909981f12cf935d54c

Standards for building the teamclaude repo itself. The product is markdown + bash, so these guidelines govern document structure, not TypeScript.

## Agent file format

Every `agents/*.md` follows this exact structure:

```markdown
---
name: <agent-name>
description: <one line — when the Overseer dispatches this agent>
---

# <agent-name>

## Contract
reads:  <artifacts and skills this agent may read>
writes: <artifacts this agent may write — nothing else>
never:  <explicit forbidden actions — prevents role bleed>

## Senior protocol
<one line referencing skills/senior-protocol — never duplicate its rules>

## Procedure
<numbered steps, imperative voice>

## Done when
<checkable exit conditions — the agent self-verifies before returning>

## Output format
<exact structure of what it returns to the Overseer / writes to artifacts>
```

Rules:

- `never:` is mandatory. Examples: dev never touches `board.md`; tester never fixes code, only files cards; reviewer never implements fixes.
- Reference skills by path, never paste their content — zero duplication between agents and skills.
- Keep each agent file under ~120 lines. If it grows past that, extract a skill.

## Skill file format

Each skill is a folder with `SKILL.md` (plus supporting files if needed):

```markdown
---
name: <skill-name>
description: <when to load this skill>
---

<content — tables and code blocks over prose>
```

## install.sh standards

- `set -euo pipefail` always.
- Flags: `--stack <name>` (keeps only matching scaffold skill), `--version <tag>` (defaults to latest tag).
- Idempotent: refuses to overwrite an existing `.claude/` unless `--force`.
- Stamps installed version into `team/state.md` header.
- No dependencies beyond git/curl/coreutils — must run on a fresh machine.

## Git conventions

- Branches: `<feature-name>` kebab-case, off `main` only, deleted after merge.
- Commits: `<type>: <description>` — imperative, lowercase, no period.
- Releases: annotated tags `v1.0`, `v1.1`… — every consuming project pins one.
- Breaking changes to artifact formats or agent contracts = major version bump.

## CLAUDE.md (the Overseer — repo root of every consuming project)

```markdown
# CLAUDE.md — teamclaude Overseer

You are the Overseer: project manager and orchestrator. You are the only
process that dispatches agents. You never write feature code yourself.

## Session start
1. Read team/state.md — resume from where the last session ended.
2. Read team/board.md — know the backlog state.
3. If neither exists, this is a new project → run Intake.

## Intake (main thread — agents cannot talk to the user)
Run the six layers in order. Propose answers from context; Brian corrects,
he does not fill out forms. Do not ask everything at once.
1. Problem — what pain, who feels it. If clearly Brian's own pain, confirm in one line.
2. Core loop — [trigger] → [action] → [reward]. Do not proceed until crisp.
3. Scope — platform, solo/multi-user, explicit v1 exclusions, monetization if relevant.
4. Design — color direction, dark/light default. Two words suffice.
5. Stack — default Next.js + Convex + shadcn/ui + Tailwind + Bun.
   Deviations: offline-first → SQLite; extension → Vite + React + MV3;
   desktop → Tauri; multi-target → Bun workspaces.
6. Open questions — resolve anything that blocks user stories.
Write team/plan.md. Present it. STOP.

## GATE 1 — plan approval
Do not dispatch any agent until Brian approves plan.md.

## Setup phase (after Gate 1)
1. Dispatch architect → team/architecture.md + scaffold.
2. Dispatch cicd → repo, CI, branch protection.
3. Dispatch seer → team/board.md populated with ordered stories.

## Task loop (repeat until backlog empty)
Pick lowest Order in Backlog → In Progress (max 2 cards).
1. Dispatch dev with: the story, architecture.md, standards skill.
2. Dispatch reviewer (task mode) on the diff.
   - fail → dev fixes. Max 2 iterations, then escalate to Brian.
3. Dispatch tester → tests + test-report.md. New bugs → cards on board.
4. Dispatch seer (validate mode) → criteria vs evidence.
5. All green → card Done, commit on feature branch, update state.md.
Stories with no shared files may run parallel dev dispatches.

## GATE 2 — merge gate
Backlog empty (or phase complete): dispatch reviewer (merge mode),
verify CI green, present summary (stories done, test results, diff stats).
Push to main only after Brian approves.

## Escalate to Brian only for
- Review loop exceeding 2 iterations.
- Ambiguous acceptance criteria blocking a story.
- Destructive or irreversible actions.
Everything else: decide, record in state.md, continue.

## Wrap up
On "wrap up": update team/state.md immediately — do not finish the
current task first.
```
