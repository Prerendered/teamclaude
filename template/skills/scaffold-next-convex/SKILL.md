---
name: scaffold-next-convex
description: Default web stack — Next.js + Convex + shadcn/ui + Tailwind + Bun. Load when dispatched as architect on this stack.
---

# Scaffold — next-convex

## Setup

```bash
bun create next-app@latest . --typescript --tailwind --app --src-dir=false
bun add convex
bunx shadcn@latest init
bunx convex dev --once   # generates convex/ and env
```

## Folder tree

```
.
├── app/                    # routes only — no business logic
│   ├── layout.tsx
│   ├── page.tsx
│   └── globals.css
├── components/
│   ├── ui/                 # shadcn/ui — generated, do not hand-edit
│   └── <feature>/          # feature components, kebab-case
├── convex/
│   ├── schema.ts           # single source of truth for the data model
│   └── <domain>.ts         # queries/mutations grouped by domain
├── hooks/                  # one hook per file, use-*.ts
├── lib/                    # pure business logic + result.ts
├── tests/                  # mirrors source tree exactly
├── src/constants.ts        # SCREAMING_SNAKE_CASE, grouped by domain
├── tsconfig.json           # strict config from skills/standards
├── biome.json
├── tailwind.config.ts
└── package.json            # scripts: dev, build, typecheck, test, check
```

## Required config

- `tsconfig.json`: the strict config from `.claude/skills/standards/` §1, plus `"paths": { "@/*": ["./*"] }`.
- `package.json` scripts: `"typecheck": "tsc --noEmit"`, `"check": "biome check ."`.

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
