<!-- owner: architect · readers: planner, dev, reviewer, verifier -->

# Architecture — [Project]

## Stack
<!-- the chosen tech per use case (from tech-options.md) and the languages in use:
     Languages: typescript, rust — agents load standards/<language>.md for each -->

## Glossary
<!-- one name per domain concept, used everywhere (code, tests, stories, commits):
     <Term> — <meaning> · banned: <synonyms agents must not use> -->

## Invariants
<!-- carried from plan.md: rules that must ALWAYS hold. The Overseer checks every
     new flow against these before it becomes a story. -->

## Flows
<!-- major data/request flows as ASCII diagrams -->

## Patterns
<!-- one section per pattern: code example + rules -->

## Structure
<!-- folder tree as scaffolded on disk — must match the repo exactly -->

## Verification
<!-- per runtime component: <component> — run: <command> — drive: <MCP | CLI | bridge>
     — logs: <file | command | MCP tool>. See .claude/skills/e2e-verification/. -->

## Conventions
<!-- only for a language with no standards/<language>.md: the core standards
     translated once into it — casing, files, error model, tests tree, lint/format
     commands — plus native ✗/✓ examples. Agents never re-translate. -->

## Decisions
<!-- one line per decision: chose <X> over <Y, Z> because <reason>  [ref: <link>] -->
