# TypeScript standards

Loaded with the core standards when team/architecture.md ## Stack lists TypeScript.

## Commands

| Check | Command |
|---|---|
| Lint + format | `bun run check` (Biome) |
| Typecheck | `bun run typecheck` (`tsc --noEmit`) |
| Tests | `bun test` |

## Enforced by tooling (don't re-check by eye)

`tsconfig.json` — strict, non-negotiable:

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noImplicitReturns": true,
    "exactOptionalPropertyTypes": true,
    "isolatedModules": true,
    "target": "ES2022",
    "moduleResolution": "bundler",
    "paths": { "@/*": ["./*"] }
  }
}
```

`biome.json` — the architect writes it at scaffold; verify every rule name and the
overrides key against the installed Biome version's docs:

| Rule | Enforces |
|---|---|
| `suspicious/noExplicitAny` | no `any` |
| `suspicious/noConsole` | no `console.log` committed |
| `style/noNonNullAssertion` | no `!` |
| `style/noEnum` | no enums — `as const` or discriminated unions |
| `style/useImportType` | `import type` for type-only imports |
| `style/noDefaultExport` | named exports only (override off for framework files: pages, layouts, configs) |
| `style/useFilenamingConvention` (`kebab-case`) | kebab-case files and folders |
| `style/useNamingConvention` | camelCase values, PascalCase types/components, CONSTANT_CASE constants |
| `style/noNestedTernary` | no nested ternaries |
| `performance/noBarrelFile`, `performance/noReExportAll` | no barrel `index.ts` (allow-list one only when imported in 3+ places) |
| organize imports | import sorting into the groups below |

CI runs lint, typecheck, and tests on every PR (gh-workflows).

## Review-only rules (no tool checks these)

- **Types**: explicit return types on exported functions; `satisfies` over `as`;
  never `React.FC`; no `@ts-ignore` without a why-comment.
- **Doc comments**: TSDoc `/** … */` on the exported function, type, or component
  when a reason outgrows one inline line. Summary line, then the why. No `@param`
  / `@returns` that restate the signature — only tags that add information
  (`@throws`, `@deprecated`, `@see <external link>`).
- **Imports**: 5 groups, blank line between — Node built-ins → external packages →
  internal shared/lib → internal types → local same-folder. `@/` over deep
  relative paths.
- **Constants**: `CONSTANT_CASE`, all in `src/constants.ts`, grouped by domain.
  Design tokens (colors, spacing, radii) are not constants — they live in the
  Tailwind config. No magic numbers in code.
- **Components**: one per file, named export; props type above the component,
  never inline; file order `'use client'` → external imports → internal imports →
  local types → component (hooks → derived state → handlers → early returns →
  render); no inline styles — Tailwind only; no DB/API calls — through hooks or
  server actions; no business logic — it lives in the feature's `lib/`, shared
  `lib/`, or `convex/`; max 150 lines; `'use client'` only when needed; no prop
  drilling beyond 2 levels. Forms: `react-hook-form` + `zod`. Modals: Esc +
  backdrop dismissible. Loading: skeletons.
- **Hooks**: one per file; return an object, not an array (except simple toggles);
  explicit return type; no raw DB/fetch calls.
- **Errors**: Result type — errors are values. try/catch only at top-level
  boundaries (route handlers, framework glue); never nested, never in loops or hot
  paths, never swallowed. External input validated with zod (Convex args with
  `v.*`) at the boundary.
- **Tests**: Bun; `tests/` mirrors `src/` exactly; `@/` imports; `describe` by
  function, `it` as a sentence; no snapshot tests. Web UI flow tests: Playwright.

## Examples

Result type — the shape every fallible function returns:

```typescript
export type Result<T, E = AppError> =
  | { ok: true; value: T }
  | { ok: false; error: E }

export const ok = <T>(value: T): Result<T> => ({ ok: true, value })
export const err = <E = AppError>(error: E): Result<never, E> => ({ ok: false, error })
```

```typescript
// ✗ exception as control flow, any, null for failure
export async function getWorkout(id: any) {
  try { return await db.get(id) } catch { return null }
}

// ✓ typed input, Result out, error carried as a value
export async function getWorkout(id: WorkoutId): Promise<Result<Workout>> {
  const workout = await db.workouts.get(id)
  return workout ? ok(workout) : err({ code: 'workout-not-found', id })
}
```

Doc comment — the long reason lives on the declaration, the body stays clean:

```typescript
// ✗ block of inline comments inside the body, @param restating the types
/** @param sets the sets @returns number */
export function calculateVolume(sets: WorkoutSet[]): number {
  // we filter warm-ups because the coach said they don't count
  // and also because the progress chart would spike otherwise
  // see the training FAQ for details
  return sets.filter(isWorkingSet).reduce(addRepsTimesWeight, 0)
}

// ✓
/**
 * Training volume: reps × weight over working sets.
 * Warm-up sets are excluded — the coach's rule, and counting them makes every
 * progress chart spike on deload weeks.
 */
export function calculateVolume(sets: WorkoutSet[]): number {
  return sets.filter(isWorkingSet).reduce(addRepsTimesWeight, 0)
}
```

Component — logic in a hook, render only:

```typescript
// ✗ inline props, data fetch and business rule inside the component
export const WorkoutCard: React.FC<{ id: string }> = ({ id }) => {
  const [w, setW] = useState<any>()
  useEffect(() => { fetch(`/api/w/${id}`).then(r => r.json()).then(setW) }, [id])
  const volume = w?.sets.filter((s: any) => !s.warmup).reduce((a: number, s: any) => a + s.reps * s.kg, 0)
  return <div style={{ padding: 8 }}>{volume}</div>
}

// ✓ props type above, data via hook, rule in lib/, Tailwind
type WorkoutCardProps = { workoutId: WorkoutId }

export function WorkoutCard({ workoutId }: WorkoutCardProps): JSX.Element {
  const { workout, isLoading } = useWorkout(workoutId)
  if (isLoading) return <WorkoutCardSkeleton />
  return <div className="p-2">{formatVolume(calculateVolume(workout.sets))}</div>
}
```

Hook — object out, explicit type:

```typescript
type UseWorkoutResult = { workout: Workout | undefined; isLoading: boolean }

export function useWorkout(workoutId: WorkoutId): UseWorkoutResult {
  const workout = useQuery(api.workouts.get, { workoutId })
  return { workout, isLoading: workout === undefined }
}
```

## Reference example — names and comments together

The shape every TypeScript file aims for. Glossary: Workout, WorkoutSet, Volume.

```typescript
// src/constants.ts (excerpt — constants grouped by domain, no divider banners)
// Convex rejects documents over 1 MB; 40 sets keeps a workout well under it.
export const MAX_SETS_PER_WORKOUT = 40
```

```typescript
// src/features/workouts/lib/calculate-volume.ts
// Derives training volume from logged sets — the number every progress chart reads.

import type { WorkoutSet } from '@/features/workouts/workout-types'

type VolumeSummary = { volume: number; workingSetCount: number }

/**
 * Training volume: reps × weight over working sets.
 * Warm-up sets are excluded — the coach's rule, and counting them makes every
 * progress chart spike on deload weeks.
 */
export function calculateVolume(sets: WorkoutSet[]): VolumeSummary {
  const workingSets = sets.filter(isWorkingSet)
  const volume = workingSets.reduce(addRepsTimesWeight, 0)
  return { volume, workingSetCount: workingSets.length }
}

function isWorkingSet(workoutSet: WorkoutSet): boolean {
  return !workoutSet.isWarmUp
}
```

```typescript
// src/features/workouts/components/workout-logger.tsx
// Lets the user log sets against a planned workout.

import { MAX_SETS_PER_WORKOUT } from '@/constants'

type WorkoutLoggerProps = { workoutId: WorkoutId }

export function WorkoutLogger({ workoutId }: WorkoutLoggerProps): JSX.Element {
  const { workout, isLoading } = useWorkout(workoutId)
  const hasReachedSetLimit = (workout?.sets.length ?? 0) >= MAX_SETS_PER_WORKOUT

  function handleAddSet(): void { … }

  if (isLoading || !workout) return <WorkoutLoggerSkeleton />
  return <SetList sets={workout.sets} canAddSet={!hasReachedSetLimit} onAddSet={handleAddSet} />
}
```
