---
name: scaffold-expo
description: Mobile stack — Expo + expo-router (+ expo-sqlite when offline-first). Load when dispatched as architect on this stack.
---

# Scaffold — expo

## Setup

```bash
bunx create-expo-app@latest . --template default   # includes expo-router + TS
```

## Folder tree

```
.
├── app/                    # expo-router file routes only
│   ├── _layout.tsx
│   └── index.tsx
├── components/<feature>/
├── hooks/
├── lib/                    # business logic + db.ts (single SQLite access point)
├── constants.ts
├── tests/
├── tsconfig.json           # strict config from skills/standards
├── app.json
└── package.json
```

## Stack-specific standards

- Routes in `app/` contain layout + navigation only — logic lives in `lib/`.
- SQLite access through one `lib/db.ts` module with typed queries; migrations
  run at startup, versioned in one place.
- All user input validated with zod before touching the DB.
- No platform forks inline — `Platform.select` wrapped in lib helpers.
- Test on both platforms before Done; typecheck via `tsc --noEmit`.

## Failure classes for tester

- SQLite migration failing on an existing install (upgrade path).
- Back-gesture/navigation state loss on Android.
- Keyboard covering inputs on small screens.
- Offline writes lost when the app is killed mid-transaction.
