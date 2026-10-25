---
name: board-conventions
description: Feature, story, and bug card formats, acceptance criteria, feature sequencing, IDs and order, and section layout for team/board.md and team/bug-board.md — load when creating or editing either board.
---

# Board conventions

## board.md layout

A Features table, then story sections in this fixed order, each holding one table
with the same columns:

```markdown
## Features
| F | Feature | Status |

## In Progress
## In Review
## Backlog
## Done
| ID | # | Story | Feature | Needs | Priority | Files | Acceptance criteria |
```

- Feature Status: `Building` / `Testing` (merged, with the User) / `Accepted`.
  Features listed in delivery order; the current feature is the first not
  Accepted. Work finishes one feature before starting the next.
- The section is the story's status — there is no Status column. Changing status
  means moving the row to that section, never editing a field.
- Backlog rows sorted by Feature delivery order, then `#`. Done rows newest-first
  (a card moving to Done goes to the top of Done), so the board reads top-down
  from live work to history. Done means the PR is merged.
- New stories always start in Backlog.
- ID: `US-1`, `US-2`, … — permanent, never reused; the branch is
  `us-<n>-<slug>`. `#` is the order within the feature — dependency-sorted, see
  below.
- Needs: the story IDs it truly depends on (`—` if none). A story is ready once
  every ID in Needs is Done. Ordering preference goes in `#`, never in Needs.
- Files: the story's expected file footprint — the Overseer uses it for the
  parallel-dispatch check (shared file with a card in flight = wait).
- WIP cap: `wip:` in team/state.md (default 4) cards In Progress + In Review
  across both boards.
- board.md holds stories and refactor cards only. Bugs go on bug-board.md.
- Pre-2.0 board (Status or Phase column, no Features table) → restructure on
  first edit: group stories into features, assign IDs, move bug cards to
  bug-board.md.

## bug-board.md layout

Sections `## In Progress`, `## Open`, `## Fixed`, same rules (section is the
status; Fixed newest-first). Columns:

```markdown
| ID | Bug | Severity | Found by | Story | Files | Repro |
```

- ID: `B1`, `B2`, … — never reused; the branch is `b<n>-<slug>`.
- Severity: critical (data loss, crash or invariant broken in a core flow) / high
  (core flow broken, Done story's criterion fails) / medium (secondary flow broken
  or workaround exists) / low (cosmetic, edge case).
- Open rows sorted by severity, then ID.
- Found by: tester / reviewer / security / e2e gate / User.
- Story: the ID of the story it breaks, or `—`.
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
- A story is only Done when every criterion is checked and its PR is merged.

## Feature sequencing

A feature is a slice the User can test end to end on its own. Order features:

| Order | What goes here |
|---|---|
| First | Foundation — repo setup, auth, install flow, onboarding — only what the first real feature needs |
| Next | The core loop's primary path, as the first user-testable feature |
| Then | Features that complete the core loop, by dependency then user value |
| Later | Secondary features — history, ratings, analytics |
| Last | Nice to have — settings, profile editing, leave/delete flows |

Each feature carries its own error, empty, and loading states — polish ships with
the feature, not in a later sweep.

## Order number rules

- `#` reflects dependency within the feature — if B requires A, A gets a lower number.
- Stories in the same feature ordered by user-facing impact after dependency.
- Integers starting at 1 per feature, no duplicates within a feature.
- When adding stories mid-feature, use decimals temporarily (e.g. 4.5).
