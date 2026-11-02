# Why each part of the harness exists — and when to remove it

A harness component compensates for something the model cannot yet do on its own.
Each row names the weakness, the signal that it has gone, and what to do then. Review
this table at every model-tier change in `template/CLAUDE.md`.

The signals come from a project's `team/log.jsonl` and from `bench/results.md`. The
thresholds are starting estimates, not measurements: replace them as runs accumulate.

## Builders and planners

| Component | Compensates for | Signal it can go | Then |
|---|---|---|---|
| planner pins exact signatures and verifies every API | a sonnet dev cannot be trusted to research APIs mid-build | dev QUESTION rate < ~5% over a project (log.jsonl) and dev runs on opus-class | planner writes Approach + Files + Test list; Contract shrinks to the public surface only |
| contract PR before stories | parallel agents inventing divergent types | glossary / `types/` conflicts stop appearing in review-report.md | fold types into the first story that needs them |
| scout brief before unfamiliar code | builders dumping the repo into context | builders on models with larger effective context and `Explore`-style search | dispatch dev with map.md only |
| one worktree per ticket | parallel agents corrupting a shared tree, as fixed in `3b996ef` | model-independent | keep |
| `scripts/bootstrap-worktree.sh` | an agent inventing values for a missing env file or dependency | model-independent | keep |
| architect, designer, cicd, seer, scribe, refactor as separate roles | one context can't hold every concern at once | a single session on a current model matches their output in the benchmark | merge the roles that show no difference |
| model-tier escalation ladder | sonnet failing where opus succeeds | first-return success on sonnet ≈ opus over several projects | flatten tiers |

## Evaluators

| Component | Compensates for | Signal it can go | Then |
|---|---|---|---|
| tester writes tests in parallel, from the plan alone | a dev that writes its own tests grades itself | — | keep; this is the generator/evaluator split and is model-independent |
| reviewer check mode (pre-PR) | dev shipping red lint/typecheck | CI catches it identically; check-mode FAILs on commands drop to ~0 | fold into PR mode; CI is the gate |
| reviewer and security, PR and feature modes | a builder cannot judge its own work | — | keep; model-independent |
| verifier drives the real app | checks passing while the running app is broken | — | keep; model-independent |
| UI grading criteria | evaluators drifting lenient on visual work | sub-3 scores stop appearing and the User stops finding UI bugs | keep the criteria for the designer; drop the per-screen scoring |
| evaluator calibration examples | evaluators drifting lenient without examples | a benchmark run without them finds as many bugs | delete the examples |

## Memory and recovery

| Component | Compensates for | Signal it can go | Then |
|---|---|---|---|
| `/compact` at feature boundaries | context anxiety in Sonnet-4.5-era models | current models; log.jsonl + state.md now carry the memory | keep as cost hygiene only; stop treating it as correctness |
| session-start reconcile | a session dying mid-work, which any model can do | — | keep; model-independent |
| dispatch log | no single record of what ran, on which tier | — | keep; model-independent |
| lessons loop | agents repeating a mistake a fresh context can't remember | lessons stop recurring, and new lines add nothing a plan already had | keep the file for the User-found bugs only |
| archivist and repertoire | nothing carries over between projects | — | keep; model-independent |
