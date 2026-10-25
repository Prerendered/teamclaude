---
name: e2e-verification
description: The three verification layers — flow tests in code, runtime observation through MCP/CLI, and a per-project game test bridge — plus per-stack drivers and the .mcp.json rules. Load when designing ## Verification (architect, scout), planning tests (planner), writing flow tests (tester), or running the runtime check (verifier).
---

# E2E verification

Three layers, cheapest first. A lower layer never replaces a higher one; each
catches what the one below can't.

| Layer | What | When | Who |
|---|---|---|---|
| 1 — Flow tests | Code that replays a whole user flow through the real modules | Every story, in CI | tester |
| 2 — Runtime observation | The real app running; Claude drives it and reads its logs, console, network, state | Feature acceptance | verifier |
| 3 — Game test bridge | A dev-only bridge inside the game so layer 2 can drive and read it | Game/mod projects | designed per project |

## Layer 1 — flow tests

- A flow test starts where the user starts (a route, a command, an event) and
  asserts what the user would see at the end, passing through the real logic,
  real storage (a local or in-memory instance of the real DB, never a mock of
  it), and real validation. Only true externals (payment provider, third-party
  API, the game engine) are faked, at their boundary.
- One flow test per user-facing criterion; unit tests cover the rest.
- Web UI flows: Playwright tests in the test tree, run headless in CI.
- Games and mods: the plan splits game-independent logic from thin engine
  hooks; flow tests drive the logic through fakes of the hooks. No game launch.
- Flow tests are committed and run in CI like every other test.

## Layer 2 — runtime observation

architecture.md `## Verification` records, for every runtime component:
`component — how to run it — how Claude drives it — where its logs come from`.
Logs are ephemeral and never written into the repo: run each component as a
background command and read its captured output, or read the platform's log
stream.

| Stack piece | Drive | Logs / evidence |
|---|---|---|
| Web frontend | Chrome DevTools MCP (`chrome-devtools-mcp`): navigate, click, fill, screenshot | console with source-mapped stacks, network requests, performance trace |
| Local server / API | its dev command, run in the background; HTTP calls | the background command's captured stdout/stderr |
| Hosted backend (Convex, Supabase, …) | its CLI or official MCP | the platform's log command or MCP |
| Desktop webview (Tauri) | Chrome DevTools MCP attached to the webview's remote-debugging port (WebView2) — verify per project | console + network as web; Rust side via the background command's captured output |
| Mobile (Expo) | device/simulator; Metro | Metro's captured output |
| Game / mod | the project's game test bridge (layer 3) | bridge `read_logs` (in-memory buffer) + the loader's own log in the game folder |

Rules:
- Every component needs a log source Claude can read without the User. "Look at
  the window" is not a log source.
- An error in the logs, console, or network during a flow is a finding even if
  the screen looks right.
- What can't be driven from here (real hardware, a payment sandbox needing a
  human, a GUI-only step) is listed as a `manual test — confirm` item, never
  silently passed.

## `.mcp.json` (committed — it ships with the tests)

- Project-scope MCP servers live in `.mcp.json` at the repo root, committed, so
  every checkout can run the verification. The User approves them once in Claude
  Code on first use.
- Pin every server to an exact version verified in its repo or registry — never
  `@latest` — same rule as CI actions.
- Only servers the project's `## Verification` actually uses. No secrets in the
  file: reference env vars by name.

Example:
```json
{
  "mcpServers": {
    "chrome-devtools": { "command": "npx", "args": ["-y", "chrome-devtools-mcp@<verified-version>"] },
    "game-bridge": { "command": "node", "args": ["tests/tools/mcp/game-bridge/server.mjs"] }
  }
}
```

## Layer 3 — game test bridge (designed per project)

The bridge removes the manual loop — relaunch, walk to the spot, perform the
setup by hand, watch the screen. Start from the scaffold in
`.claude/skills/e2e-verification/game-bridge/` (README there says what to copy and
what to fill): the protocol, the MCP wrapper with every lifecycle tool, a C#
in-game side for .NET-hosted loaders, and a fake game for testing without
launching. The architect adapts it to the project's engine and loader (another
engine → port `GameBridge.cs`, keep the protocol); existing projects (MelonMCP,
UnityInfoMCP, bepinex-mcp) are references, not dependencies. Every bridge
provides:

**Inside the game** (`tests/tools/bridge/`, linked into the mod's Debug build only):
- `health` — ready + mod version, so a restart can wait for it.
- `read_logs(since)` — the mod's and loader's log lines since a cursor.
- `query(probe)` — named state probes returning structured data (player
  position, inventory, flags, the mod's own state). Never screenshots-as-state.
- `command(action, args)` — named setup actions: teleport, give item, set
  time/flag, trigger the event the mod reacts to, load a save slot.
- `screenshot` — visual evidence only, when the criterion is visual.
- Transport: `127.0.0.1` only, fixed port, JSON lines. Never bound to a public
  interface.

**Outside the game** (the MCP wrapper in `tests/tools/mcp/game-bridge/`, registered in `.mcp.json`):
- `deploy_build` — copy the fresh build into the loader's mods folder.
- `restart_game` — kill the process, launch it, wait for `health`.
- `load_test_save(name)` — start from a known save instead of the menus.
- Proxies for every in-game tool above.

Per story, the planner adds the probes and commands its criteria need to the
plan (they are part of the Contract); dev builds them with the story. A story
whose criteria can't be reached by a probe or command lists that leg as a
manual test. No hot reload is assumed — a code change means `deploy_build` +
`restart_game`, one call instead of a manual relaunch.
