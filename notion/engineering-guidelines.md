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

Source of truth: [`template/CLAUDE.md`](../template/CLAUDE.md) — never duplicated here
(duplication is drift). Structural rules the Overseer file must keep:

- **Two entry modes.** Session start branches on existing code: greenfield → Intake
  (six-layer Q&A), brownfield → Onboarding (scout surveys, then a change plan).
- **Two gates only.** Gate 1 approves the plan; Gate 2 approves the merge. Between
  them the team runs autonomously.
- **Setup dispatches** architect (greenfield), cicd, designer (UI stacks), seer.
- **Task loop** routes by card type — feature → dev, refactor → refactor — with
  scout briefs on demand, then reviewer, security (sensitive cards), tester, seer.
- **Gate 2** runs reviewer + security (merge) + scribe before the merge summary; a
  high or critical security finding blocks it.
- **Escalate** only for review loops >2, ambiguous criteria, or destructive actions.
