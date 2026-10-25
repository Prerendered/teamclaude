# C# standards

Loaded with the core standards when team/architecture.md ## Stack lists C#
(Unity, game mods, .NET apps). Follows the .NET runtime coding style; where it
conflicts with the core verb table, keep the verbs and use .NET casing.

## Commands

| Check | Command |
|---|---|
| Format + style | `dotnet format --verify-no-changes` |
| Build (analyzers as errors) | `dotnet build -warnaserror` |
| Tests | `dotnet test` |

Unity projects without a buildable .csproj: the architect records the
equivalents (Unity's test runner in batch mode, an analyzer DLL) in
team/architecture.md ## Conventions.

## Enforced by tooling (don't re-check by eye)

The architect writes these at scaffold; verify option names against the
installed SDK's docs.

- `Directory.Build.props`: `<Nullable>enable</Nullable>`,
  `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`,
  `<AnalysisLevel>latest-recommended</AnalysisLevel>`,
  `<EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>`.
- `.editorconfig` naming rules (severity `error`):

| Symbol | Casing | Example |
|---|---|---|
| types, methods, properties, events, public fields | PascalCase | `WorkoutLog`, `GetWorkout` |
| interfaces | `I` + PascalCase | `IWorkoutStore` |
| parameters, locals | camelCase | `workoutId` |
| private fields | `_camelCase` | `_workoutStore` |
| constants, static readonly | PascalCase | `MaxSetsPerWorkout` |
| async methods | `Async` suffix | `GetWorkoutAsync` |

- File-scoped namespaces, `var` when the type is obvious, braces always — set in
  `.editorconfig`, fixed by `dotnet format`.

## Review-only rules (no tool checks these)

- **Files**: one top-level type per file; file name = type name (`WorkoutLog.cs`);
  folders by feature, not by kind.
- **Types and constants** (core standards): domain data types (records, DTOs,
  enums) in `Types/<Domain>/`, one per file; constants in
  `Constants/<Domain>Constants.cs` as a `static class` of `const` /
  `static readonly`. Services and behavior stay in their feature folders.
- **Booleans**: `Is`/`Has`/`Can`/`Should`/`Did` prefix (`IsComplete`).
- **Errors**: exceptions are idiomatic in .NET — throw for programmer errors and
  broken invariants; return `bool TryX(out T)` or a result type for expected
  failures (not found, invalid input). Never catch `Exception` except at a
  top-level boundary that logs it. Never swallow.
- **Doc comments**: XML `/// <summary>` on the type or member when a reason
  outgrows one inline line — summary sentence, then the why in `<remarks>`. No
  `<param>`/`<returns>` that restate the signature. Public API of a library gets a
  summary even when short.
- **No `dynamic`**, no reflection where a direct call works, no `#region`.
- **Unity / game mods**:
  - Game APIs only on the main thread.
  - No allocation, `GetComponent`, or `Find` in per-frame code — cache the lookup
    on init.
  - Harmony patches: one class per patched target, named `<Target>Patch`, with a
    why-comment on what the original does wrong for the mod.
  - Dev-only code (the game test bridge) lives in `tests/tools/bridge/`, linked
    into Debug builds only (a Debug-conditioned `<Compile Include>`) and guarded by
    `#if TEAMCLAUDE_BRIDGE` — a Release build cannot contain it.
- **Tests**: a separate test project, `tests/<Project>.Tests/`, mirroring the
  project's source folders, files `<Type>Tests.cs`. Unity Editor projects: the
  Unity Test Framework only runs tests inside `Assets/`, so tests go in
  `Assets/Tests/` (own `.asmdef`) mirroring `Assets/Scripts/`; game logic tested through fakes of the engine hooks
  (e2e-verification layer 1).

## Examples

```csharp
// ✗ abbreviation, Hungarian field, swallowed exception, null for failure
public class WkStore {
    private Dictionary<string, Workout> m_dict;
    public Workout getWkt(string id) {
        try { return m_dict[id]; } catch { return null; }
    }
}

// ✓ .NET casing, glossary name, expected failure as TryGet
public sealed class WorkoutStore : IWorkoutStore
{
    private readonly Dictionary<WorkoutId, Workout> _workouts = new();

    public bool TryGetWorkout(WorkoutId workoutId, out Workout workout) =>
        _workouts.TryGetValue(workoutId, out workout);
}
```

Doc comment — the reason on the member, not in the body:

```csharp
/// <summary>Restores the mod's persisted stamina after the game loads a save.</summary>
/// <remarks>The base game resets stamina in ResetOnLoad; without this the value
/// the player earned is lost on every reload.</remarks>
public static void RestoreStamina(PlayerStats stats) => stats.Stamina = StaminaStore.LoadSaved();
```

Unity per-frame code — cache on init, no lookups in Update:

```csharp
// ✗ lookup and allocation every frame
void Update() { var hud = GameObject.Find("Hud").GetComponent<Hud>(); hud.Show($"{_count}"); }

// ✓ resolved once; Update only does the per-frame work
private Hud _hud;

private void Awake() => _hud = FindObjectOfType<Hud>();

private void Update() => _hud.SetCount(_count);
```

Harmony patch — one target, named for it, why stated:

```csharp
// The base game resets stamina on every load, wiping the mod's persisted value.
[HarmonyPatch(typeof(PlayerStats), nameof(PlayerStats.ResetOnLoad))]
internal static class PlayerStatsResetOnLoadPatch
{
    private static void Postfix(PlayerStats __instance) =>
        __instance.Stamina = StaminaStore.LoadSaved();
}
```

## Reference example — names and comments together

The shape every C# file aims for. Glossary: Workout, WorkoutSet, Volume.

```csharp
// Constants/WorkoutConstants.cs
// Limits and defaults for workouts — every workout number lives here.

namespace Gym.Constants;

public static class WorkoutConstants
{
    // Sync payloads over 1 MB are rejected; 40 sets keeps a workout well under it.
    public const int MaxSetsPerWorkout = 40;
}
```

```csharp
// Types/Workout/VolumeSummary.cs
// Training volume for one workout, as every progress chart consumes it.

namespace Gym.Types.Workout;

public sealed record VolumeSummary(double Volume, int WorkingSetCount);
```

```csharp
// Workouts/VolumeCalculator.cs
// Derives training volume from logged sets — the number every progress chart reads.

using Gym.Types.Workout;

namespace Gym.Workouts;

public sealed class VolumeCalculator
{
    private readonly IWorkoutStore _workoutStore;

    public VolumeCalculator(IWorkoutStore workoutStore) => _workoutStore = workoutStore;

    /// <summary>Training volume: reps × weight over working sets.</summary>
    /// <remarks>Warm-up sets are excluded — the coach's rule; counting them makes
    /// every progress chart spike on deload weeks.</remarks>
    public VolumeSummary CalculateVolume(IReadOnlyList<WorkoutSet> sets)
    {
        var workingSets = sets.Where(IsWorkingSet).ToList();
        var volume = workingSets.Sum(workoutSet => workoutSet.Reps * workoutSet.Weight);
        return new VolumeSummary(volume, workingSets.Count);
    }

    public async Task<Workout> GetWorkoutAsync(WorkoutId workoutId) { … }

    public bool TryGetWorkout(WorkoutId workoutId, out Workout workout) =>
        _workoutStore.TryGet(workoutId, out workout);

    private static bool IsWorkingSet(WorkoutSet workoutSet) => !workoutSet.IsWarmUp;
}
```
