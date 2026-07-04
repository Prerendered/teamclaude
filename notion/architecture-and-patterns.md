# Architecture & Patterns

> Pulled from Notion 2026-07-04 — https://app.notion.com/p/393c946c280181b58dfafaba888c2d87

## Workflow state machine

```
INTAKE (main thread Q&A)
   │  writes plan.md
   ▼
══ GATE 1: Brian approves plan ══
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
══ GATE 2: reviewer merge mode + CI green + Brian approves ══
   │
   ▼
PUSH TO MAIN
```

## Agent contracts

| Agent | reads | writes | never |
|---|---|---|---|
| `seer` | plan.md, board-conventions, test-report.md (validate mode) | board.md | writes code; marks Done without evidence |
| `architect` | plan.md, stack skill, reference-library | architecture.md, scaffold | implements features; skips Decisions section |
| `dev` | one story, architecture.md, standards | code on feature branch | touches board.md; edits other stories' files |
| `reviewer` | diff, standards, architecture.md | review-report.md | implements fixes; reviews own suggestions |
| `tester` | story criteria, code | tests/, test-report.md, bug cards | fixes code; deletes failing tests |
| `cicd` | plan.md, gh-workflows skill | .github/, repo config | touches application code |

## Senior behaviors per agent

| Agent | Senior behavior mandated in its md |
|---|---|
| `seer` | Challenges the plan: unstated edge cases, comparable-product checks, adds non-functional stories (error/empty/loading states) |
| `architect` | Pulls structure from 2–3 reference repos in the same stack, compares against scaffold skill, records every deviation with reason |
| `dev` | Verifies current API signatures in official docs for every library touched; matches existing codebase idioms before inventing new ones |
| `reviewer` | Checklist + design review (coupling, naming, 3-month test); every violation cites a rule, tagged blocker / should-fix / nit |
| `tester` | Beyond criteria: boundary values, race conditions, stack-specific failure classes; every finding filed as a card with repro |
| `cicd` | Verifies current action versions, pins SHAs, adds caching, matches CI to what the project actually uses |

## Patterns

### Dispatch payload (Overseer → agent)

Agents receive only their contract inputs, never conversation history:

```
Task: <story title + acceptance criteria verbatim>
Context files: team/architecture.md, .claude/skills/standards/
Branch: <feature-name>
Return: summary + files touched + self-check result
```

Rule: if an agent needs something not in its `reads:`, that is an Overseer bug — fix the contract, do not widen the payload ad hoc.

### Review loop cap

```
dev → reviewer → fail(report) → dev → reviewer → fail → ESCALATE
```

Rule: reviewer must tag severity; dev fixes blockers first. Two failed cycles means the story or the architecture is ambiguous — a human call, not a third loop.

### Parallel dispatch

Rule: Overseer checks the file footprint in each story's Notes before parallelizing. Shared file = sequential. No shared files = parallel dev dispatches, reviews still sequential.

### Decisions block (ADR-lite)

Every artifact with choices carries:

```
## Decisions
- chose <X> over <Y, Z> because <reason>  [ref: <link>]
```

Rule: one line per decision. If it needs a paragraph, it needs Brian.

### Escalation format

```
⚠ ESCALATION — <story>
Blocked by: <review loop | ambiguous criteria | destructive action>
Tried: <what was attempted>
Options: A) …  B) …  (recommendation: A because …)
```

## Pattern summary

| Pattern | Where used | Why |
|---|---|---|
| Artifact contracts (reads/writes/never) | all agents | deterministic handoffs, no role bleed |
| Two-gate autonomy | Overseer | speed between gates, control at the edges |
| Review loop cap | task loop | prevents dev↔reviewer ping-pong burning context |
| Dispatch payload | every Task call | small contexts stay sharp on long runs |
| Decisions block | architecture, reviews | Gate reviews read rationale, not reverse-engineering |
| Senior protocol skill | all agents | one source for evidence/budget/record rules |
| Version pinning | install.sh • tags | old projects re-fetch exact team version |
