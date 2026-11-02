---
name: design-system
description: Token structure, the component-state matrix, and the accessibility floor — load before writing team/design.md.
---

# Design system

## Tokens — live in the theme config, never in constants/
| Group | Defines |
|---|---|
| Color roles | background, surface, foreground, muted, primary, destructive, border — each with a light and a dark value |
| Type scale | font family, size steps, weight, line-height — a named scale, not ad-hoc px |
| Spacing | one scale (e.g. 4px base); components compose from it |
| Radii | named steps (sm / md / lg / full) |
| Elevation | shadow steps mapped to z-intent |
| Breakpoints | the named widths where the layout changes; the verifier grades at each |

Reference by role, never raw value — `bg-surface`, not `bg-[#111]`. Roles carry a
light and dark value; the theme toggle swaps the map, not the components.

## Component state matrix
Every interactive component specs all applicable states:

default · hover · focus-visible · active · disabled · loading (skeleton) · empty · error

A spec missing a state is incomplete — dev builds exactly what is specced, no more.

## Accessibility floor (non-negotiable)
- Contrast: 4.5:1 body text, 3:1 large text and UI boundaries — validate every
  color-role pair in both themes.
- Focus: a visible focus ring on every interactive element; never remove the
  outline without a replacement.
- Hit target: ≥ 44×44px interactive area.
- Motion: honor `prefers-reduced-motion`; never signal state through motion alone.

## Grading criteria
The designer writes design.md so that each criterion can be checked from a screenshot;
the verifier scores each screen against them at Feature acceptance, 1–5, in both
themes. Score < 3 on any criterion is a finding.

| Criterion | What a 5 looks like | What a 1 looks like |
|---|---|---|
| Design quality | clear hierarchy; type scale and spacing scale honoured; one visual idea per screen | arbitrary sizes, cramped or floating elements, no hierarchy |
| Consistency | every colour/space/radius is a token role from design.md; state matrix complete | raw hex/px values; missing hover/focus/disabled/empty states |
| Craft | aligned, responsive at the recorded breakpoints, no layout shift, visible focus rings, contrast floor met | misalignment, overflow, jank, invisible focus, failed contrast |
| Functionality | every state (loading, empty, error) renders as specced and is reachable | a state is unreachable, blank, or shows developer text |

## Decisions
Record token and pattern choices in team/design.md's Decisions block — chose X over
Y because Z (senior-protocol rule 3). A palette without rationale is guesswork.
