# Project Board — teamclaude

> Pulled from Notion 2026-07-04 — https://app.notion.com/p/393c946c28018157ab49c619e6832f99
> Kanban database: https://app.notion.com/p/16b4f80ae14449d5a4e0c9963490a3cc

Kanban for building the teamclaude repo itself. Note: this board tracks construction of the team. Once teamclaude is live, consuming projects use their local `team/board.md` — not Notion.

All 20 stories are currently **Backlog**.

| # | Story | Priority | Notes |
|---|-------|----------|-------|
| 1 | As a user, I can create the teamclaude repo with the full template structure | High | GitHub repo `teamclaude` with install.sh, README, template/ tree |
| 2 | As a user, I can install the team into a new project with one command | High | install.sh — curl \| bash -s -- --stack \<name\> |
| 3 | As a user, I can pin and re-fetch an exact team version per project | High | git tags + --version flag |
| 4 | As a user, I can run intake by saying 'new project' and approve the plan at Gate 1 | High | CLAUDE.md intake section — Layers 1–6 in main thread |
| 5 | As the Overseer, I can run the workflow state machine end to end | High | CLAUDE.md — setup phase, task loop, Gate 2, escalation rules |
| 6 | As any agent, I follow the senior protocol | High | skills/senior-protocol — the 4 rules, referenced by all agents |
| 7 | As a seer agent, I can turn plan.md into an ordered board and validate completed work | High | agents/seer.md — story mode + validate mode |
| 8 | As an architect agent, I can design structure from the plan and vetted references | High | agents/architect.md — reads reference-library, writes architecture.md + scaffold |
| 9 | As a dev agent, I can implement one story on a feature branch to senior standard | High | agents/dev.md |
| 10 | As a reviewer agent, I can review in task mode and merge mode with cited severities | High | agents/reviewer.md — one agent, two modes |
| 11 | As a tester agent, I can test criteria and attack beyond them | High | agents/tester.md |
| 12 | As a cicd agent, I can set up the GitHub repo and CI to senior standard | High | agents/cicd.md + skills/gh-workflows |
| 13 | As a user, I have the global coding standards migrated into a versioned skill | High | skills/standards — migrate _standards.md from Operating Manual |
| 14 | As a user, I have board conventions as a skill | High | skills/board-conventions — story format, criteria rules, phases, order numbers |
| 15 | As an architect, I have a scaffold skill per supported stack | Medium | scaffold-next-convex, scaffold-tauri, scaffold-expo, scaffold-extension |
| 16 | As an agent, I can consult a vetted reference library | Medium | skills/reference-library.md — 2–3 exemplar repos per stack |
| 17 | As an agent, I read and write artifacts from fixed templates | Medium | team/ stubs — plan, board, architecture, review-report, test-report, state |
| 18 | As a user, I can run a pilot project through both gates | Medium | Dry run on a small dummy project (e.g. a tiny CLI or single-page app) |
| 19 | As a user, I can read a README that explains the whole system | Low | README — install, workflow diagram, agent roster, versioning policy |
| 20 | As a user, I can optionally sync the local board to Notion | Low | Add-on skill — board.md ↔ Notion Kanban via MCP, off by default |

---

## Acceptance criteria

### 1. Create the teamclaude repo with the full template structure
- Repo exists on GitHub with main branch protected
- template/ contains CLAUDE.md, agents/, skills/, team/ exactly as specced
- All 6 agent stub files present with contract headers
- README documents the install one-liner and flags
- Repo tagged v0.1

### 2. Install the team into a new project with one command
- `curl -sL <raw-url>/install.sh | bash -s -- --stack next-convex` copies template/ into ./.claude/
- --stack flag keeps only the matching scaffold skill, removes the rest
- Refuses to overwrite existing .claude/ unless --force
- Installed version stamped into team/state.md header
- set -euo pipefail; exits non-zero with clear message on any failure
- Runs on a machine with only git/curl/coreutils

### 3. Pin and re-fetch an exact team version per project
- install.sh accepts --version vX.Y and fetches that tag
- Omitting --version installs the latest tag, not main HEAD
- team/state.md records the installed tag
- Re-running with the recorded tag reproduces identical files
- Invalid tag fails with a list of available tags

### 4. Run intake by saying 'new project' and approve the plan at Gate 1
- CLAUDE.md defines all six intake layers with propose-then-correct behavior
- Layers asked in order, never all at once
- Core loop must be crisp before Layer 3 proceeds
- Output is team/plan.md matching the plan template including Decisions section
- Overseer stops and waits for explicit approval before any dispatch
- Stack deviation rules (offline/extension/desktop/multi-target) encoded

### 5. Overseer runs the workflow state machine end to end
- Setup phase dispatches architect, cicd, seer in order after Gate 1
- Task loop picks lowest Order, max 2 cards In Progress
- Review loop capped at 2 iterations then escalates using the escalation format
- Parallel dispatch only when stories share no files (checked via board Files column)
- Gate 2 requires reviewer merge mode + CI green + explicit approval before push
- 'wrap up' trigger updates state.md immediately
- Dispatch payloads contain only contract inputs, never conversation history

### 6. Senior protocol skill
- Skill defines: evidence before decisions, 2–3 reference budget, Decisions block with rejected alternatives, deviations allowed with recorded reason
- All 6 agent files reference the skill by path
- No agent file duplicates any protocol rule inline
- Decisions block format specified exactly (one line per decision + ref link)

### 7. Seer agent — story mode + validate mode
- Every plan feature maps to at least one story in board.md
- Stories follow 'As a \<role\>, I can \<action\>' with 4–7 verifiable criteria each
- Phases and order numbers follow board-conventions skill
- Senior: adds non-functional stories (error/empty/loading states) and unstated edge cases
- Validate mode checks each criterion against test-report evidence, never claims
- never: writes code; marks Done without evidence

### 8. Architect agent
- Reads plan.md, stack scaffold skill, and 2–3 entries from reference-library
- architecture.md contains flows, patterns with code examples, and a Decisions section
- Every deviation from the scaffold skill recorded with reason
- Scaffold on disk matches architecture.md exactly
- Research budget respected — max 3 references consulted
- never: implements features; skips the Decisions section

### 9. Dev agent
- Receives exactly one story + architecture.md + standards skill in dispatch payload
- Verifies current API signatures in official docs for each external library touched
- Matches existing codebase idioms before introducing new patterns
- Typecheck and tests pass locally before returning
- Returns summary + files touched + self-check result in fixed format
- never: touches board.md; edits files outside the story's footprint

### 10. Reviewer agent — task mode + merge mode
- Task mode reviews a single story diff; merge mode reviews the full branch diff
- Every violation tagged blocker / should-fix / nit and cites the specific standard
- Design review included: coupling, naming, 3-month maintainability
- Merge mode additionally checks for unrelated changes and criteria drift
- Appends to review-report.md in the fixed log format with PASS/FAIL verdict
- never: implements fixes; reviews code it wrote

### 11. Tester agent
- Every acceptance criterion has a corresponding test case in tests/
- Risk assessment covers boundary values, race conditions, and stack-specific failure classes
- Each finding beyond criteria filed as a board card with a one-line repro
- test-report.md appended in the fixed format (coverage + risk + cards)
- never: fixes code; deletes or weakens failing tests

### 12. Cicd agent
- CI runs typecheck + tests on every PR
- Action versions verified current and pinned to SHAs
- Dependency caching configured for the stack
- Branch protection: no direct pushes to main, CI required to merge
- Workflows match what the project actually uses — no template leftovers
- never: touches application code

### 13. Global coding standards migrated into a versioned skill
- All 16 sections of _standards.md migrated verbatim into skills/standards/
- Post-change checklist and Done checklist included
- Agent files reference the skill, zero duplicated rules
- Operating Manual page updated with a pointer note marking teamclaude as the new source of truth

### 14. Board conventions as a skill
- Story format, acceptance criteria rules, and the 6 sequencing phases migrated from the Operating Manual
- Order number rules included (dependency-sorted, decimals mid-project)
- board.md table template defined including the Files column for parallel-dispatch checks
- WIP limit (max 2 In Progress) documented

### 15. Scaffold skill per supported stack
- Each of the 4 skills contains a full folder tree and required config files
- next-convex includes Bun, Tailwind, shadcn/ui setup and strict tsconfig
- Each skill lists its stack-specific standards (Convex validators, Tauri IPC, MV3, Expo)
- install.sh --stack flag maps 1:1 to these skill names

### 16. Vetted reference library
- 2–3 exemplar repos listed per stack with a one-line 'what to learn from it'
- Initial entries marked 'unvetted — User to confirm'
- Append process defined: Overseer adds discoveries mid-project with date + reason
- Agents instructed to prefer library entries over web search results

### 17. Artifacts from fixed templates
- All 6 stubs match the templates in Project Design exactly
- Each stub header names its owner and readers
- state.md stub includes team-version header line
- review-report and test-report defined as append-only logs

### 18. Pilot project through both gates
- Pilot goes intake → Gate 1 → setup → task loop → Gate 2 → merged main
- Unplanned interruptions counted and ≤3
- Every escalation used the escalation format
- Decisions sections present in architecture.md and review-report.md
- Retro notes captured: what drifted, which agent files need tightening
- Fixes from retro committed and tagged v1.0

### 19. README that explains the whole system
- Install one-liner with all flags documented
- Workflow state machine included as ASCII diagram
- Agent contract table (reads/writes/never) included
- Versioning policy: what constitutes a major bump
- 'Adding a new stack' and 'adding a new agent' guides

### 20. Optionally sync the local board to Notion
- Opt-in flag or skill, absent from default install path behavior
- Sync maps board.md columns to the standard Kanban schema
- Conflict rule defined: board.md wins, Notion is a mirror
- Sync failures never block the task loop
