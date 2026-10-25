---
name: standards
description: Coding standards — load before writing or reviewing any code. This file holds the rules for every stack; then load only the language files for the project's languages.
---

# Coding standards

## Precedence and languages

This skill outranks repo precedent. When existing code contradicts a rule here,
follow the rule or ask the Overseer — never silently copy the existing pattern
because "that's how the repo does it". Inheriting debt is a deviation, and a
deviation needs a recorded reason (senior-protocol rule 4).

Then read the language file for each language in team/architecture.md ## Stack —
only those: `typescript.md`, `csharp.md`, `rust.md` beside this file. A language
with no file here: its conventions are in team/architecture.md ## Conventions —
the architect translates these core rules into it once, at design time, from the
ecosystem's official style guide, with native ✗/✓ examples in the language files'
format. Agents use that one translation; never re-translate per task.

Tooling first: every rule a linter, formatter, or compiler can check is enforced
by config and CI (each language file lists them). The prose rules are the ones no
tool can check — those are what review is for.

## Naming

- Names come from team/architecture.md ## Glossary. One name per domain concept,
  everywhere — code, tests, branches, commits. A banned synonym is a defect. A
  new domain concept is proposed in the plan, never invented in code.
- Casing follows the language file.
- Functions: verb + noun, no abbreviations. The verb says what happens:

| Verb | Use for |
|---|---|
| `get` | Read single item |
| `list` | Read collection |
| `create` | Insert record |
| `update` | Modify record |
| `delete` | Remove record |
| `format` | Transform for display |
| `parse` | Transform raw input |
| `validate` | Check validity |
| `calculate` | Compute derived value |
| `build` | Construct complex object |
| `handle` | Event handler only |
| `on` | Callback prop / event only |

- Booleans: `is` / `has` / `can` / `should` / `did` prefix, in the language's casing.
- A name that needs a comment to explain it is the wrong name — rename it.

```
Glossary: Workout — a planned set of exercises · banned: session, routine, training

✗ fetchSession(id)      ✗ getWkt(id)         ✗ data, info, temp, handleStuff
✓ getWorkout(id)        ✓ listWorkouts()     ✓ isWorkoutComplete
```

What review blocks, in every language (casing per the language file):

| Written | Why it fails | Fix |
|---|---|---|
| `getSession(id)` | `session` is a banned synonym of Workout | `getWorkout(workoutId)` |
| `calcVol(s)` | abbreviations | `calculateVolume(sets)` |
| `totalLoad` | `load`, `total` banned for Volume | `volume` |
| `data`, `info`, `result2`, `temp` | names that say nothing | the concept: `workout`, `volumeSummary` |
| `warmup` (boolean) | no boolean prefix | `isWarmUp` / `IsWarmUp` / `is_warm_up` |
| `processWorkout()` | vague verb | the table's verb: `validateWorkout()` |
| `m_store`, `strName` | Hungarian notation | `_workoutStore` (C#), `name` |

## Comments

Comments explain **why**, never **what**. If you need to explain what the code
does, rename or split it.

Comment for: business rule rationale, non-obvious workarounds, external links,
TODO/FIXME with owner. Nothing else — most functions carry no comment at all.

Length: **one line**, placed directly above the line it explains. A reason that
truly needs more:
- the language has doc comments (TSDoc `/** */`, C# `///`, Rust `///`, Python
  docstrings) → put it in the doc comment of the function or type it belongs to,
  not as an inline block. Summary line first, then the why — what a caller must
  know that the signature doesn't say. Never restate parameter names or types.
- no doc comments → 2–3 inline lines at most.
Either way, past a few lines is a design smell: split the code or move the
rationale to the Decisions block.

Never:
- restate the code, or narrate it step by step;
- changelog comments — `added for login`, `now uses the cache`, `fixed bug where…`.
  History lives in git, not in the file;
- ticket, plan, or team/ references — `see US-12`, `per the plan`. team/ is local
  and plans are gone after merge: the comment would point nowhere. State the
  reason itself;
- comments addressed to the reviewer or the User — `as requested`, `note: …`;
- commented-out code — delete it; git has it;
- section dividers or banners inside a file.

TODO format: `TODO(user): <what and why deferred>` — owner always required.

What gets a comment (each language file's Reference example shows it in code):

| Where | Comment | Why |
|---|---|---|
| Top of the file | header line | why the file exists |
| A function whose business rule needs 2+ lines | doc comment on the function | the rule lives on the declaration, not in the body |
| A constant or literal hiding a reason (`40`, a timeout) | one line, at its definition | the number alone doesn't say why |
| A line that looks pointless or wrong (a cast, a workaround) | one line above it | it would get "fixed" by the next reader |
| A function, field, or type whose name says it all | none | the name is the documentation |
| A signature that tells the caller everything | none | the doc comment would only restate it |

Expect a few comment lines per screen of code, each saying what the code can't.

```
✗ narrating, changelog, ticket ref, dead code — and a block where none is needed:
    // added for US-12 per the plan
    // loop over the sets and add up the reps
    // fixed: was returning null before
    // const legacyTotal = sumLegacy(sets)
    function calculateVolume(sets) {
      return sets.filter(isWorkingSet).reduce(addRepsTimesWeight, 0)
    }

✓ one line, only where the reason isn't in the code:
    function calculateVolume(sets) {
      // Warm-up sets don't count toward volume — coach's rule.
      return sets.filter(isWorkingSet).reduce(addRepsTimesWeight, 0)
    }

✓ a longer reason goes in the doc comment, not the body (syntax: language file):
    /**
     * Pushes workouts to Strava in batches.
     * Strava bans the token for an hour past 100 req/15 min, so batches stay at 90
     * and the first 429 stops the run instead of retrying.
     */
    function syncWorkoutsToStrava(workouts) { … }
```

## File header

One line at the top of each source file (after any directive the framework
requires first, such as `'use client'`), in the language's line-comment syntax:

```
// <why this file exists — one sentence>
// caution: <optional — a real non-obvious constraint only>
```

No exports list, no dependency list — the code already says both.

```
✗ // purpose: workout utils · owns: calculateVolume, formatDuration · deps: @/lib/units
✓ // Derives training volume from logged sets — the number every progress chart reads.
✓ // caution: runs inside the sync worker; no DOM access.
```

## Design principles

- **KISS**: Simplest solution that works. Exception: measurable perf/UX improvement earns complexity — but only when you can point to the specific problem it solves right now.
- **YAGNI**: Build for the current story. Generalise at the second real use case, not before.
- **Single Responsibility**: One file, one function, one component — one job. Split if you need "and".
- **Composition over Inheritance**: Compose small units. Inherit only where the framework requires it.
- **Fail Fast**: Validate at the boundary — every external input is checked where it enters. Never `null` to signal failure.
- **Colocation**: Keep code close to where it's used — new code starts in its feature folder. Promote to shared at 3+ feature uses. Duplication is cheaper than the wrong abstraction.

## Tests

Separate test tree on **every** stack — this rule survives repo precedent. A
separate file/dir, never inline with source: no Rust `#[cfg(test)] mod tests` in
the source file, no `Component.test.tsx` beside the component. The language file
names the stack's tree; if the ecosystem's idiom is genuinely inline, that is a
deviation with a recorded reason, not a default.

Ownership: the tester agent authors all tests (unit + criteria + flow). Dev never
writes tests — dev's obligation is to keep the existing suite green.

## Git

Branches: the ticket — `us-<n>-<slug>` (story), `b<n>-<slug>` (bug), `docs-f<n>` (feature docs); kebab-case. One ticket per branch. Branch off `origin/main` only. Deleted on merge. Never commit directly to `main`.

Commits: `<type>: <description>` — imperative, lowercase, no period (`feat: add user auth and cache`). Types: feat, fix, test, refactor, docs, chore, ci. No ticket ID in the message — the branch carries it. Squash merge to `main` via auto-merge; PRs require green CI.

Commit body: terse. The subject line alone is enough for most commits; add a body only to record *why* a non-obvious change was made, in one or two lines — never a multi-paragraph changelog restating the diff.

PR title: the squash commit on `main`, so the same `<type>: <description>` format. PR body, lean:

```
US-<n> · <story title>          (bug: B<n> · <bug>)

<2–3 line summary>

- [x] <criterion>                (bug: - [x] regression test passes)
```

Nothing else in the body, and never a link into team/ (local only).

Author: the User's own git and gh identity. No `Co-Authored-By` trailers and no "Generated with" lines in commits, PR titles, PR bodies, or review comments.

## Post-change checklist

Run after every code addition or edit. Fix violations inline — never report and
leave for the user.

1. **Tooling** — the language file's lint + format check, exit 0. This covers
   every mechanical rule; don't re-check those by eye.
2. **Self-review** — what no tool checks:

```
Names: glossary terms only, no banned synonyms; verb+noun functions; boolean prefixes
Comments: why-not-what; inline = one line; longer → doc comment (3 inline max without one); none where the code says it; no changelog, ticket/plan refs, reviewer notes, commented-out code
Header: one purpose line present
Design: one job per file/function; no speculative abstraction; boundary input validated
Errors: the language file's error model; nothing swallowed silently
Tests: existing suite passes; no tests deleted or weakened (authoring: tester)
Security: no secrets, no sensitive data in URLs or logs
Language file: its review-only rules
```

## Before opening the PR

```
[ ] typecheck/build — zero errors (language file's command)
[ ] test suite — zero failures
[ ] lint + format check — zero errors
[ ] Post-change checklist passed
[ ] Acceptance criteria fully met
[ ] Branch clean — no unrelated changes
[ ] Branch pushed
```
