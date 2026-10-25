# Game test bridge — scaffold

The fixed part of e2e-verification layer 3. The architect copies it into a game
or mod project at design time; the planner and dev fill the project-specific part
per story. Protocol: one JSON line per request over `127.0.0.1:<port>`,
`{"id","method","params"}` → `{"id","result"}` or `{"id","error"}`. Methods:
`health`, `list`, `read_logs {since}`, `query {name,args}`, `command {name,args}`.

## Copy (architect, design mode)

| From | To (in the project) |
|---|---|
| `game/GameBridge.cs` | `tests/tools/bridge/GameBridge.cs` |
| `mcp/server.mjs`, `mcp/fake-game.mjs`, `mcp/package.json` | `tests/tools/mcp/game-bridge/` |
| `mcp/bridge.config.example.json` | `tests/tools/mcp/game-bridge/bridge.config.json`, filled in |

Register it in `.mcp.json`:
```json
"game-bridge": { "command": "node", "args": ["tests/tools/mcp/game-bridge/server.mjs"] }
```
and run `npm install` in `tests/tools/mcp/game-bridge/` as part of setup (commit its
lockfile; `node_modules/` stays gitignored).

## Fill in (per project)

1. **Dev-only build** — in the mod's .csproj, Debug only: link the file and
   define the guard, so a Release build cannot contain the bridge:
   ```xml
   <ItemGroup Condition="'$(Configuration)'=='Debug'">
     <Compile Include="../../tests/tools/bridge/GameBridge.cs" />
   </ItemGroup>
   <PropertyGroup Condition="'$(Configuration)'=='Debug'">
     <DefineConstants>$(DefineConstants);TEAMCLAUDE_BRIDGE</DefineConstants>
   </PropertyGroup>
   ```
   Adjust the relative path to where the .csproj sits.
2. **Loader hooks** — in the mod's entry point (`#if TEAMCLAUDE_BRIDGE`):
   `GameBridge.Start(port, version)` on init, `GameBridge.Pump()` from the
   loader's per-frame main-thread update callback, `GameBridge.Log(...)` from the
   mod's logger. Find the loader's exact callback names in its docs/SDK — verify,
   never guess.
3. **Config** — `bridge.config.json`: same `port`, the game's `processName`,
   `launch` (e.g. a `steam://rungameid/<appid>` start command), the loader's
   `modsDir`, the Debug build output in `buildFiles`, and the in-game command
   name that loads a save (`loadSaveCommand`).
4. **Probes and commands** — added per story, from the plan's Contract:
   `GameBridge.Probe("player_position", _ => new { x, y, z })`,
   `GameBridge.Command("teleport", args => …)`. Probes return structured data;
   commands set up the state a criterion needs. Always include a `load_save`
   command so the verifier starts from a known save.

## Test without the game

`node tests/tools/mcp/game-bridge/fake-game.mjs` serves the same protocol with fake
state on the same port — use it to check the MCP wiring and a verifier flow
before the real game is involved.
