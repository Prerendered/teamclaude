---
name: scaffold-tauri
description: Desktop stack — Tauri + Vite + React (+ SQLite plugin when offline-first). Load when dispatched as architect on this stack.
---

# Scaffold — tauri

## Setup

```bash
bun create tauri-app@latest . --template react-ts --manager bun
```

## Folder tree

```
.
├── src/                    # React frontend
│   ├── main.tsx
│   ├── app.tsx
│   ├── components/<feature>/
│   ├── hooks/
│   ├── lib/                # incl. ipc.ts — the only file calling invoke()
│   └── constants.ts
├── src-tauri/
│   ├── src/
│   │   ├── main.rs
│   │   └── commands/       # one module per domain
│   ├── capabilities/       # permission scopes — narrowest possible
│   └── tauri.conf.json
├── tests/
├── tsconfig.json           # strict config from skills/standards
└── package.json
```

## Stack-specific standards

- All IPC through one typed wrapper (`src/lib/ipc.ts`) — components never call
  `invoke()` directly.
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
