# Architecture & Patterns

> Pulled from Notion 2026-07-04 — https://app.notion.com/p/393c946c280181b58dfafaba888c2d87

## Workflow state machine

```
ENTRY
  greenfield ─► INTAKE (main thread Q&A) ──────────────► writes plan.md
  brownfield ─► ONBOARDING ─► scout ─► architecture.md + map.md ─► change plan
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
   ├► refactor ─ refactor card: behavior-preserving, tests green before+after
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

## Agent contracts

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
| `tester` | story criteria, code | tests/, test-report.md, bug cards | fixes code; deletes failing tests |
| `scribe` | finished code, architecture.md, board.md | README.md, docs/ | changes code; documents unbuilt features |
| `cicd` | plan.md, gh-workflows skill | .github/, repo config | touches application code |
| `archivist` | team/ artifacts, state.md, repertoire skill | entry + ToC pushed to the repertoire repo | pushes to the project repo; includes secrets in an entry |

## Senior behaviors per agent

| Agent | Senior behavior mandated in its md |
|---|---|
| `seer` | Challenges the plan: unstated edge cases, comparable-product checks, adds non-functional stories (error/empty/loading states) |
| `architect` | Pulls structure from 2–3 reference repos in the same stack, compares against scaffold skill, records every deviation with reason |
| `scout` | Reads what the code *is*, not what it should be; every inferred convention cites a file; standards drift becomes candidate refactor cards |
| `dev` | Verifies current API signatures in official docs for every library touched; matches existing codebase idioms before inventing new ones |
| `refactor` | Never touches code without a passing test; same suite green before and after; one concern per branch; no new patterns |
| `reviewer` | Checklist + design review (coupling, naming, 3-month test); every violation cites a rule, tagged blocker / should-fix / nit |
| `security` | Walks every checklist class; each finding names code, exploit path, and fix with a severity; audits dependencies in merge mode |
| `designer` | Extracts existing design language before proposing (brownfield); validates contrast in both themes; every token choice has a rationale |
| `tester` | Beyond criteria: boundary values, race conditions, stack-specific failure classes; every finding filed as a card with repro |
| `scribe` | Documents only what is Done on the board; verifies every API signature against source, never memory |
| `cicd` | Verifies current action versions, pins SHAs, adds caching, matches CI to what the project actually uses |
| `archivist` | Distils from artifacts only, never invents; proposes an existing category before a new one; self-scans for secrets and gets approval before an external push |

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

Rule: Overseer checks the file footprint in each story's Notes before parallelizing. Shared file = sequential. No shared files = parallel builder dispatches, reviews still sequential.

### Decisions block (ADR-lite)

Every artifact with choices carries:

```
## Decisions
- chose <X> over <Y, Z> because <reason>  [ref: <link>]
```

Rule: one line per decision. If it needs a paragraph, it needs the User.

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
