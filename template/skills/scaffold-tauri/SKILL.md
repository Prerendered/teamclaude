---
name: scaffold-tauri
description: Desktop stack — Tauri + Vite + React (+ SQLite plugin when offline-first). Load when dispatched as architect on this stack.
---

# Scaffold — tauri

## Setup

```bash
bun create tauri-app@latest . --template react-ts --manager bun
```

## Folder tree (feature-first, big-project layout)

This stack's form of the standards Project layout (generic rules, READMEs,
types/constants, tests) — the tree adds only what the stack needs. Every
folder below with a role gets its README.md per that section.

```
.
├── src/                    # React frontend
│   ├── main.tsx
│   ├── app.tsx
│   ├── features/           # one folder per domain feature
│   │   └── <feature>/
│   │       ├── components/
│   │       ├── hooks/
│   │       └── lib/
│   ├── components/
│   │   └── ui/             # shared primitives only
│   ├── types/              # one file per glossary domain — every type except props
│   ├── constants/          # one file per glossary domain — CONSTANT_CASE
│   ├── hooks/              # cross-cutting hooks only (use-*.ts)
│   └── lib/                # cross-cutting: result.ts + ipc.ts (the only file calling invoke())
├── src-tauri/
│   ├── src/
│   │   ├── main.rs
│   │   ├── commands/       # one module per domain — mirrors src/features/ domains
│   │   ├── types/          # one module per glossary domain
│   │   └── constants/      # one module per glossary domain
│   ├── tests/              # Rust integration tests, mirroring src-tauri/src/ (Cargo's location)
│   ├── capabilities/       # permission scopes — narrowest possible
│   └── tauri.conf.json
├── tests/                  # mirrors src/ (the React side)
│   ├── flows/              # flow tests, one folder per glossary domain
│   └── tools/              # test tooling: tools/mcp/<server>/ — never imported by app code
├── .mcp.json               # project MCP servers, pinned (e2e-verification)
├── tsconfig.json           # strict config from skills/standards
└── package.json
```

## Structure rules

- Import direction is one-way: `app.tsx` → `features/` → shared. Never
  feature → feature internals; promote shared code to `lib/` at 3+ uses.
- Rust `commands/` modules mirror frontend feature domains 1:1 — a feature's
  IPC surface is findable by name on both sides.
- Delete empty layers: don't pre-create hooks/lib inside a feature.

## Stack-specific standards

- All IPC through one typed wrapper (`src/lib/ipc.ts`) — feature code never
  calls `invoke()` directly.
- Every Tauri command returns `Result<T, String>` on the Rust side; the ipc
  wrapper maps it to the standards Result type.
- Capabilities scoped to exactly what the app uses — never a wildcard.
- Offline-first: state lives in SQLite (tauri-plugin-sql); the frontend is a
  view over it, no duplicate in-memory stores.
- Long-running work in Rust with progress events — never block the webview.

## Failure classes for tester

- IPC call with mismatched Rust/TS types (serde silently dropping fields).
- Unhandled command error crossing the boundary as an opaque string.
- SQLite write race between concurrent commands.
- Path handling that breaks on Windows separators.
- Cross-feature import bypassing the promotion rule (coupling debt).
