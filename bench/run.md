# Running the benchmark

One run takes about an evening and spends real tokens, on top of a throwaway GitHub
repo. Run it for the baseline, at each release, and when an item asks for a comparison.

The `bench/` folder doesn't ship to consuming projects.

## Steps

1. Note the version under test: a tag, or a commit for a run between releases.
2. Create an empty throwaway GitHub repo and clone it. Run in a fresh Claude Code
   session on the model `template/CLAUDE.md` names for the Overseer, using the same
   model settings as the run you're comparing with.
3. Install that version from a clean checkout of it:
   ```bash
   git -C <teamclaude> worktree add --detach <temp> <tag-or-commit>
   cd <throwaway-repo>
   node <temp>/bin/cli.mjs init
   ```
4. Start the session with "new project" and answer Intake from [spec.md](spec.md).
   Approve the plan, and accept the recommended stack at the Tech gate.
5. Let it run to Feature acceptance of F3. At each User test, accept without trying
   the feature. Answer any escalation with the option it recommends, and count on it
   showing up in the results.
6. Read the numbers:
   ```bash
   node <teamclaude>/bench/metrics.mjs <throwaway-repo>
   ```
7. Add the printed row to [results.md](results.md), with the cost from your usage
   page or `/cost`, and any notes about the run.
8. Delete the throwaway repo, and remove the temp worktree.

## Comparing runs

One run is one sample, and agents vary between runs. Treat a small difference as
noise; a change in bugs reaching the e2e gate or the User, or a large cost swing, is
worth investigating. Read the log before crediting a template change with the result.
