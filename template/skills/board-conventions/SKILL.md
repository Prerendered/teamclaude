---
name: board-conventions
description: Story and bug card formats, acceptance criteria, phases, order numbers, and section layout for team/board.md and team/bug-board.md — load when creating or editing either board.
---

# Board conventions

## board.md layout

Sections in this fixed order, each holding one table with the same columns:

```markdown
## In Progress
## In Review
## Backlog
## Done
| # | Story | Priority | Phase | Files | Acceptance criteria |
```

- The section is the status — there is no Status column. Changing status means
  moving the row to that section, never editing a field.
- Backlog rows sorted by `#` ascending. Done rows newest-first (a card moving to
  Done goes to the top of Done), so the board reads top-down from live work to
  history.
- New stories always start in Backlog.
- `#` is the Order number — dependency-sorted, see below.
- Files: the story's expected file footprint — the Overseer uses it for the
  parallel-dispatch check (shared file = sequential).
- WIP limit: never more than 2 cards In Progress across both boards — finish
  before starting new.
- board.md holds stories and refactor cards only. Bugs go on bug-board.md.
- Pre-2.0 board (single table with a Status column) → restructure into sections on
  first edit and move any bug cards to bug-board.md.

## bug-board.md layout

Sections `## In Progress`, `## Open`, `## Fixed`, same rules (section is the
status; Fixed newest-first). Columns:

```markdown
| ID | Bug | Severity | Found by | Story | Files | Repro |
```

- ID: `B1`, `B2`, … — never reused.
- Severity: critical (data loss, crash or invariant broken in a core flow) / high
  (core flow broken, Done story's criterion fails) / medium (secondary flow broken
  or workaround exists) / low (cosmetic, edge case).
- Open rows sorted by severity, then ID.
- Found by: tester / e2e gate / security / User.
- Story: the `#` of the story it breaks, or `—`.
- Repro: one line — the exact input or steps and the observed vs expected result.

## Story format

- Title: `As a <role>, I can <action> <context>`
- Priority: High (core flow) / Medium (polish) / Low (nice-to-have)
- Notes: one-liner on implementation detail, component, or function

## Acceptance criteria rules

- 4–7 checkable conditions per story.
- Each condition independently verifiable (yes/no).
- Cover the happy path, at least one edge case, at least one technical/data requirement.
- No vague conditions like "works correctly" — specify the expected behaviour.
- A story is only Done when every criterion is checked.

## Sequencing phases

| Phase | What goes here | Priority |
|---|---|---|
| 1 — Foundation | Repo setup, auth, install flow, onboarding | High |
| 2 — Core flow | Minimum path through the primary use case | High |
| 3 — Core interactions | Supporting interactions that complete the primary flow | High |
| 4 — Session/state polish | Edge cases, close/end states, status visibility | Medium |
| 5 — Secondary features | Calendar, history, ratings, analytics | Medium |
| 6 — Nice to have | Settings, profile editing, leave/delete flows | Low |

## Order number rules

- Order reflects dependency — if B requires A, A gets a lower number.
- Tasks in the same phase ordered by user-facing impact.
- Integers starting at 1, no duplicates.
- When adding tasks mid-project, use decimals temporarily (e.g. 4.5).
