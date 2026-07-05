# Project Design

> Pulled from Notion 2026-07-04 — https://app.notion.com/p/393c946c2801814eb87afcd3d9006ec7

teamclaude has no UI — its "design" is the design of its documents. Agents read these files thousands of times; format quality is product quality.

## Document philosophy

- **Contracts over prose** — an agent file is a spec, not an essay. Tables, headers, numbered steps.
- **Reference, never duplicate** — any rule that exists in a skill is linked, not pasted. Duplication is drift.
- **Self-verifying** — every agent file ends with checkable "Done when" conditions; every artifact template has required sections an agent can validate.
- **Terse by design** — every line in an agent md costs context on every dispatch. Cut ruthlessly.

## Artifact templates

### team/plan.md

```markdown
# Plan — [Project]
## Problem
## Core loop
[trigger] → [action] → [reward]
## Scope (v1)
### In
### Out
## Stack
## Design direction
## Decisions
## Open questions (resolved)
```

### team/board.md

```markdown
# Board — [Project]
| # | Story | Status | Priority | Phase | Files | Acceptance criteria |
|---|-------|--------|----------|-------|-------|---------------------|
```

Status: Backlog / In Progress / In Review / Done. Order = the `#` column, dependency-sorted. Files column enables the parallel-dispatch check.

### team/review-report.md (append-only log)

```markdown
## [date] — [story] — [task|merge] — PASS|FAIL
- [blocker|should-fix|nit] <violation> — cites <rule> — fix: <suggestion>
```

### team/test-report.md (append-only log)

```markdown
## [date] — [story]
### Criteria coverage
- [✓|✗] <criterion> — <test file::case>
### Risk assessment
- <failure class considered> — <finding | clear>
### Cards filed
- <bug card # + one-line repro>
```

### team/map.md (brownfield)

Written by scout in onboarding — the reverse-engineered map of an existing codebase. Describes what the code **is**; aspirations become refactor cards, not map entries.

```markdown
# Codebase map — [Project]
## Entry points
## Build & run
## Modules
## Conventions in force
## Danger zones
```

### team/design.md (UI stacks)

Written by designer in setup. Dev builds against it; tokens live in the theme config, never `constants.ts`.

```markdown
# Design system — [Project]
## Tokens        (color roles light+dark, type scale, spacing, radii, elevation)
## Components     (each with the full state matrix)
## Accessibility floor
## Decisions
```

### team/security-report.md (append-only log)

```markdown
## [date] — [story|branch] — [card|merge] — PASS|FAIL
- [critical|high|medium|low] <vuln> @ <file:line> — exploit: <how> — fix: <suggestion>
```

### team/state.md

Same template as the Operating Manual (current phase, last worked on, in progress, up next, blockers, files touched) plus a header line: `team-version: vX.Y`.

## Voice rules for agent files

| Rule | Example |
|---|---|
| Imperative, second person | "Read architecture.md before writing code" |
| No hedging | never "try to", "if possible", "ideally" |
| Verifiable exit conditions | "typecheck exits 0", not "code works" |
| Explicit negatives | the `never:` line does the heavy lifting |

## Naming

- Agents: lowercase single word (`seer`, `dev`, `reviewer`).
- Skills: kebab-case folders (`senior-protocol`, `board-conventions`).
- Artifacts: fixed names in `team/` — agents hardcode paths, so paths never change without a major version bump.
