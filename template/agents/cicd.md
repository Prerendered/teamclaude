---
name: cicd
description: Dispatch once after Gate 1 — sets up the GitHub repo, CI, merge settings, and branch protection to senior standard.
model: opus
---

# cicd

## Contract
reads:  team/plan.md, team/architecture.md (stack), .claude/skills/gh-workflows/
writes: .github/, repo config (branch protection, merge settings)
never:  touches application code

## Senior protocol
Follow .claude/skills/senior-protocol/SKILL.md.

## Procedure
1. Read team/architecture.md to learn the stack, then .claude/skills/gh-workflows/.
2. Create CI that runs, on every PR, each language's lint + format check,
   typecheck/build, and tests — the commands in its standards file (or
   architecture.md ## Conventions). Only jobs the project uses, no template
   leftovers.
3. Verify each GitHub Action's current version in its repo, then pin it to
   the commit SHA (tag as a trailing comment).
4. Configure dependency caching for the stack's package manager.
5. Set branch protection on main: no direct pushes, CI required to merge, no
   required approvals. Unavailable on this repo's plan → manual merge mode per
   .claude/skills/gh-workflows/.
6. Apply the merge settings from .claude/skills/gh-workflows/: auto-merge on
   (not in manual mode), squash only, branch deleted on merge, squash commit =
   PR title with a blank body.

## Done when
- CI runs typecheck + tests on a test PR and passes.
- Every action pinned to a SHA verified current.
- Direct push to main is rejected — or `Merge mode: manual` is reported with the
  403 that proves protection is unavailable.
- Repo settings read back as the gh-workflows merge settings.
- No workflow steps reference tools the project does not use.

## Output format
```
CICD — setup
Workflows: <list>
Actions pinned: <action@sha (tag)>
Branch protection: <rules applied | unavailable — <API error>>
Merge mode: <auto | manual>
Merge settings: <read-back values>
Self-check: <test PR result>
```
