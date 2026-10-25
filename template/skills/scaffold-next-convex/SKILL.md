---
name: scaffold-next-convex
description: Default web stack — Next.js + Convex + shadcn/ui + Tailwind + Bun. Load when dispatched as architect on this stack.
---

# Scaffold — next-convex

## Setup

Generate outside the repo, then copy in (architect design mode step 7):

```bash
bun create next-app@latest <tmp>/app --typescript --tailwind --app --src-dir
# copy <tmp>/app in (no .git/, no node_modules/, .gitignore merged), then in the repo:
bun install
bun add convex
bunx shadcn@latest init
bunx convex dev --once   # generates convex/ and env
```

## Folder tree (feature-first, big-project layout)

This stack's form of the standards Project layout (generic rules, READMEs,
types/constants, tests) — the tree adds only what the stack needs. Every
folder below with a role gets its README.md per that section.

```
.
├── src/
│   ├── app/                # routes only — thin, compose features, no logic
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   └── globals.css
│   ├── features/           # one folder per domain feature
│   │   └── <feature>/
│   │       ├── components/ # UI owned by this feature
│   │       ├── hooks/      # hooks owned by this feature
│   │       └── lib/        # business logic owned by this feature
│   ├── components/
│   │   └── ui/             # shadcn/ui + shared primitives only — generated, do not hand-edit
│   ├── types/              # one file per glossary domain — every type except props
│   ├── constants/          # one file per glossary domain — CONSTANT_CASE
│   ├── hooks/              # cross-cutting hooks only (use-*.ts)
│   └── lib/                # cross-cutting only: result.ts, utils shared by 3+ features
├── convex/
│   ├── schema.ts           # single source of truth for the data model
│   └── <domain>.ts         # queries/mutations grouped by domain
├── tests/                  # mirrors src/; tests/convex/ mirrors convex/
│   ├── flows/              # flow tests, one folder per glossary domain
│   └── tools/              # test tooling: tools/mcp/<server>/ — never imported by app code
├── .mcp.json               # project MCP servers, pinned (e2e-verification)
├── tsconfig.json           # strict config from skills/standards
├── biome.json
├── tailwind.config.ts
└── package.json            # scripts: dev, build, typecheck, test, check
```

## Structure rules

- Import direction is one-way: `app/` → `features/` → shared (`components/ui`,
  `hooks/`, `lib/`). Never feature → feature internals; if two features need
  the same code, promote it to shared.
- A route file composes feature components and passes params — nothing else.
- New code starts inside its feature folder; promote to shared only at 3+
  feature uses (standards, Design principles: Colocation).
- Delete empty layers: a feature with one component is just
  `features/<feature>/components/<name>.tsx` — don't pre-create hooks/lib.

## Required config

- `tsconfig.json`: the strict config from `.claude/skills/standards/typescript.md`, plus `"paths": { "@/*": ["./src/*"] }`.
- `package.json` scripts: `"typecheck": "tsc --noEmit"`, `"check": "biome check ."`.

## Local setup (architecture.md ## Local setup)

- untracked: `.env.local` — the Convex deployment and URL `convex dev` writes.
- shared: the Convex dev deployment. `convex dev` pushes the worktree's functions
  to it, so two worktrees on one cloud dev deployment overwrite each other's
  backend. Isolate: each worktree runs its own local deployment (state lives in
  the worktree's `.convex/`). The CLI's local-deployment commands have changed
  across releases — verify the current one in the Convex CLI docs (rule 1).
- shared: the Next.js dev port, and the Playwright `webServer` port — one per
  worktree, passed by env var, never hard-coded.

## Stack-specific standards

- Every Convex function declares `args` with `v.*` validators — no exceptions.
- `convex/schema.ts` defines all tables with validators and indexes; query by
  index, never `.filter()` on large tables.
- Mutations validate business rules server-side — never trust the client.
- Components call Convex only through `useQuery` / `useMutation` hooks.
- Auth checks live in Convex functions, not in components.

## Failure classes for tester

- Unvalidated Convex args accepting bad shapes.
- Race: two mutations on the same document (last-write-wins surprises).
- Query without index degrading on table growth.
- Client-side auth check with no server-side enforcement.
- Cross-feature import bypassing the promotion rule (coupling debt).
