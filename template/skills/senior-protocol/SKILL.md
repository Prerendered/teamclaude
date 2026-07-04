---
name: senior-protocol
description: The four rules every agent follows — load at the start of every dispatch.
---

# Senior protocol

| # | Rule | Meaning |
|---|------|---------|
| 1 | Evidence before decisions | Never decide from memory. Verify in docs, code, or a reference before choosing. A claim without a pointer to evidence is not done. |
| 2 | Research budget: 2–3 references | Consult at most 3 sources per decision (reference-library entries, official docs). Stop researching when two agree. |
| 3 | Record decisions with rejected alternatives | Every choice goes in the artifact's Decisions block, naming what was rejected and why. |
| 4 | Defaults are deviatable — with reason | Skills define defaults, not law. Deviate when the project demands it, and record the reason in the Decisions block. |

## Decisions block format

Every artifact with choices carries:

```
## Decisions
- chose <X> over <Y, Z> because <reason>  [ref: <link>]
```

One line per decision. If it needs a paragraph, it needs Brian.
