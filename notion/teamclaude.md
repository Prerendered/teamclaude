# teamclaude

> Pulled from Notion 2026-07-04 — https://app.notion.com/p/393c946c280181eaa1b8cb3eb1326da7

A versioned GitHub repo of Claude Code agents, skills, and artifact templates that installs into any project with one command — turning Claude Code into a senior software team that takes a project from intake (greenfield) or a codebase survey (brownfield) to merged code with only two approval gates.

## Tech Stack

| Layer | Value |
|---|---|
| Agent definitions | Markdown (`.claude/agents/*.md`) |
| Skills | Markdown (`.claude/skills/*/`) |
| Orchestrator | `CLAUDE.md` (main session = Overseer) |
| Installer | Bash (`install.sh`, curl one-liner) |
| Distribution | GitHub repo + git tags for versioning |
| Runtime | Claude Code |

## Architecture Principles

- **Overseer is the main session** — subagents cannot spawn subagents, so orchestration lives in `CLAUDE.md`, never in an agent file.
- **Agents communicate through artifacts, not messages** — every agent declares `reads:` / `writes:` / `never:`; the `team/` folder is the message bus.
- **Senior protocol everywhere** — evidence before decisions, research budgeted (2–3 references max), decisions recorded with rejected alternatives, defaults deviatable with reason.
- **Two gates only** — plan approval and merge gate. Between them the team runs autonomously; escalation only for review loops >2, ambiguous criteria, or destructive actions.
- **Single source of truth** — standards, board conventions, and intake live once in skills; agent files reference, never duplicate. This repo replaces the Operating Manual's intake flow.
- **Version pinning** — every project stamps the team version it was built with; re-fetch installs that exact tag.

## Artifact Model

| Artifact | Owner (writes) | Readers |
|---|---|---|
| `team/plan.md` | Intake / Onboarding (main session) | all agents |
| `team/board.md` | seer creates, Overseer maintains | dev, refactor, tester, seer |
| `team/architecture.md` | architect (greenfield), scout (brownfield) | dev, refactor, reviewer, security |
| `team/map.md` | scout | refactor, dev, Overseer |
| `team/design.md` | designer | dev |
| `team/review-report.md` | reviewer | dev, Overseer |
| `team/security-report.md` | security | Overseer |
| `team/test-report.md` | tester | seer, dev, refactor |
| `team/state.md` | Overseer | everyone, every session |
| repertoire entry (external repo) | archivist | Overseer (intake), architect |

## Platform Constraints

- Subagents run to completion in isolated context — no mid-run user Q&A, no agent-to-agent calls.
- Intake Q&A must run in the main thread (Overseer wearing the Seer hat).
- Parallel dispatch allowed only for stories with no shared files.
- Reviewer fix loop capped at 2 iterations, then escalate to the User.

## MVP Success Metrics

- One command installs the full team into a fresh project (`curl … | bash -s -- --stack next-convex`).
- A pilot project goes intake → merged main with ≤3 unplanned interruptions.
- Every architecture decision in the pilot has a recorded rationale with rejected alternatives.
- Zero standards duplicated between agent files and skills.

## Claude Code Setup

> Read all files in `.claude/` before writing any code.

### Repo structure (the product itself)

```
claude-team/
├── install.sh
├── README.md
└── template/
    ├── CLAUDE.md              Overseer — intake, state machine, gates
    ├── agents/
    │   ├── seer.md
    │   ├── architect.md
    │   ├── scout.md
    │   ├── dev.md
    │   ├── refactor.md
    │   ├── reviewer.md
    │   ├── security.md
    │   ├── designer.md
    │   ├── tester.md
    │   ├── scribe.md
    │   ├── cicd.md
    │   └── archivist.md
    ├── skills/
    │   ├── senior-protocol/
    │   ├── standards/
    │   ├── board-conventions/
    │   ├── codebase-survey/
    │   ├── refactor-catalog/
    │   ├── security-standards/
    │   ├── design-system/
    │   ├── repertoire/
    │   ├── reference-library.md
    │   ├── gh-workflows/
    │   ├── scaffold-next-convex/
    │   ├── scaffold-tauri/
    │   ├── scaffold-expo/
    │   └── scaffold-extension/
    └── team/
        ├── plan.md            (stub)
        ├── board.md           (stub)
        ├── architecture.md    (stub)
        ├── map.md             (stub)
        ├── design.md          (stub)
        ├── review-report.md   (stub)
        ├── security-report.md (stub)
        ├── test-report.md     (stub)
        └── state.md           (stub)
```

### Links

- Notion project: teamclaude (`393c946c-2801-81ea-a1b8-cb3eb1326da7`)
- [Engineering Guidelines](engineering-guidelines.md) — https://app.notion.com/p/393c946c280181909981f12cf935d54c
- [Architecture & Patterns](architecture-and-patterns.md) — https://app.notion.com/p/393c946c280181b58dfafaba888c2d87
- [Project Design](project-design.md) — https://app.notion.com/p/393c946c2801814eb87afcd3d9006ec7
- [Project Board](board.md) — https://app.notion.com/p/393c946c28018157ab49c619e6832f99
