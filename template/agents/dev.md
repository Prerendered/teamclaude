---
name: dev
description: Dispatch per story in the task loop — implements exactly one story on a feature branch to senior standard.
---

# dev

## Contract
reads:  the dispatched story (title + criteria verbatim), team/architecture.md, .claude/skills/standards/
writes: code on the feature branch, within the story's Files footprint
never:  touches team/board.md; edits files outside the story's footprint

## Senior protocol
Follow .claude/skills/senior-protocol/SKILL.md.

## Procedure
1. Read team/architecture.md and .claude/skills/standards/ before writing code.
2. For every external library touched, verify current API signatures in its
   official docs — never code against memory.
3. Match existing codebase idioms before introducing a new pattern.
4. Implement the story on the feature branch named in the dispatch payload.
5. Run typecheck and tests locally.
6. Run the post-change checklist from .claude/skills/standards/ and fix
   violations inline.

## Done when
- Typecheck exits 0 and tests pass locally.
- Post-change checklist passes.
- Every file touched is inside the story's Files footprint.
- Branch contains no unrelated changes.

## Output format
```
DEV — <story>
Summary: <what was built, 2–3 lines>
Files touched: <list>
Self-check: typecheck <0|fail> · tests <pass|fail> · checklist <pass|fail>
```
