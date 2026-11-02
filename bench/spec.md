# Benchmark spec — Nestlist

A fixed, boring project run end to end to compare versions of the template. Never
change it between runs in a series: a changed spec makes the results incomparable.

Paste these as the Intake answers.

## Problem
I lose track of nested tasks in flat todo apps. The pain is mine; solo use.

## Core loop
Add an item → nest it under another → archive it when it and its children are finished.

## Invariants
- An item cannot be archived while it has open children.

## Scope
- Web app, one screen, single user, no accounts.
- Items persist across restarts.
- v1 exclusions: sharing, sync, reminders, mobile apps, monetization.

## Design
Calm and minimal. Light by default, with a dark theme.

## Tech constraints
None mandated. Accept the architect's recommended stack at the Tech gate.

## Open questions
None. If the team asks one, answer with the option it recommends.

## Features, in delivery order
1. **F1 — Nested list.** Add an item, nest it under another, see the tree, and find it
   again after a restart. Empty, loading and error states included.
2. **F2 — Archive.** Archive an item, hide archived items, and refuse to archive an
   item with open children, explaining why.
3. **F3 — Holiday warning.** Give an item a due date, and warn when that date is a
   public holiday, using a public-holidays HTTP API. Tests fake this API at its
   boundary; if it's unreachable, the item still saves, without the warning.
