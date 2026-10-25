# Rust standards

Loaded with the core standards when team/architecture.md ## Stack lists Rust
(e.g. a Tauri backend).

## Commands

| Check | Command |
|---|---|
| Format | `cargo fmt --check` |
| Lint | `cargo clippy --all-targets -- -D warnings` |
| Tests | `cargo test` |

## Enforced by tooling (don't re-check by eye)

The architect writes these at scaffold; verify lint names against the installed
toolchain's clippy docs.

- `rustfmt` defaults — formatting is never a review topic.
- `Cargo.toml`:

```toml
[lints.rust]
unsafe_code = "deny"

[lints.clippy]
unwrap_used = "deny"
expect_used = "deny"
todo = "deny"
dbg_macro = "deny"
print_stdout = "deny"
```

- `clippy.toml`: `allow-unwrap-in-tests = true`, `allow-expect-in-tests = true`.
- Naming by the compiler's own lints: `snake_case` functions, modules, files;
  `PascalCase` types and traits; `SCREAMING_SNAKE_CASE` consts and statics.

## Review-only rules (no tool checks these)

- **Errors**: `Result` everywhere a call can fail. Domain and library errors are a
  `thiserror` enum per module; `anyhow` only at the application edge (`main`,
  command handlers). Add context where an error crosses a layer. Tauri commands
  return `Result<T, E>` with a serializable `E` — never panic across the IPC
  boundary.
- **Booleans**: `is_`/`has_`/`can_`/`should_` prefix.
- **Types and constants** (core standards): `src/types/<domain>.rs` and
  `src/constants/<domain>.rs`, declared as modules in `types/mod.rs` /
  `constants/mod.rs`. Error enums stay with the module that returns them.
- **Doc comments**: `///` on the item (`//!` for a module) when a reason outgrows
  one inline line — summary line, blank `///`, then the why. Use `# Errors` /
  `# Panics` sections only when they add information beyond the signature.
- **`unsafe`**: denied by default; a real need is a recorded deviation with a
  `// SAFETY:` comment stating the invariant upheld.
- **Ownership**: borrow before clone; a `.clone()` to satisfy the borrow checker
  needs a reason. No `Rc<RefCell<…>>` where plain ownership works.
- **Tests**: integration tests in the crate's own `tests/` (e.g. `src-tauri/tests/`,
  mirroring `src-tauri/src/`, files `<module>_test.rs`) — Cargo fixes this location; no
  `#[cfg(test)] mod tests` in source files (core standards, Tests). Expose what
  tests need through the public API, not `pub(crate)` test hooks.

## Examples

```rust
// ✗ panics on bad input, stringly error, abbreviation
pub fn get_wkt(id: &str) -> Workout {
    let w = STORE.lock().unwrap().get(id).cloned().expect("missing");
    w
}

// ✓ typed error, Result out, glossary name
#[derive(Debug, thiserror::Error)]
pub enum WorkoutError {
    #[error("workout {0} not found")]
    NotFound(WorkoutId),
}

pub fn get_workout(store: &WorkoutStore, workout_id: &WorkoutId) -> Result<Workout, WorkoutError> {
    store
        .get(workout_id)
        .cloned()
        .ok_or_else(|| WorkoutError::NotFound(workout_id.clone()))
}
```

Doc comment — the reason on the item:

```rust
/// Pushes workouts to Strava in batches.
///
/// Strava bans the token for an hour past 100 requests per 15 minutes, so batches
/// stay at 90 and the first 429 stops the run instead of retrying.
pub fn sync_workouts_to_strava(client: &StravaClient, workouts: &[Workout]) -> Result<(), SyncError> {
    // …
}
```

Tauri command — serializable error, no panic across IPC:

```rust
#[tauri::command]
pub fn get_workout_command(
    state: tauri::State<'_, AppState>,
    workout_id: WorkoutId,
) -> Result<Workout, CommandError> {
    let store = state.workouts.lock().map_err(|_| CommandError::StoreUnavailable)?;
    Ok(get_workout(&store, &workout_id)?)
}
```

## Reference example — names and comments together

The shape every Rust file aims for. Glossary: Workout, WorkoutSet, Volume.

```rust
// src/constants/workout.rs
// Limits and defaults for workouts — every workout number lives here.

/// Sync payloads over 1 MB are rejected; 40 sets keeps a workout well under it.
pub const MAX_SETS_PER_WORKOUT: usize = 40;
```

```rust
// src/types/workout.rs
// The workout domain's shapes — the one place they're declared.

pub struct VolumeSummary {
    pub volume: f64,
    pub working_set_count: usize,
}
```

```rust
// src/workouts/volume.rs
// Derives training volume from logged sets — the number every progress chart reads.

use crate::types::workout::{VolumeSummary, WorkoutSet};

/// Training volume: reps × weight over working sets.
///
/// Warm-up sets are excluded — the coach's rule; counting them makes every
/// progress chart spike on deload weeks.
pub fn calculate_volume(sets: &[WorkoutSet]) -> VolumeSummary {
    let working_sets: Vec<&WorkoutSet> = sets.iter().filter(|s| is_working_set(s)).collect();
    // f64 before multiplying: reps × weight overflows u32 on a long powerlifting log.
    let volume = working_sets.iter().map(|s| f64::from(s.reps) * s.weight).sum();
    VolumeSummary { volume, working_set_count: working_sets.len() }
}

fn is_working_set(workout_set: &WorkoutSet) -> bool {
    !workout_set.is_warm_up
}
```
