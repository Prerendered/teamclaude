---
name: gh-workflows
description: CI workflow, merge settings, and branch protection templates — load when dispatched as cicd.
---

# GitHub workflows

## Rules

- Verify each action's current release in its repo, then pin the **commit SHA**
  with the tag as a trailing comment. Never pin a mutable tag.
- Only include jobs the project actually uses — no template leftovers.
- Cache dependencies for the stack's package manager.
- CI must run lint + format check, typecheck, and tests on every PR — the
  commands from each language's standards file.

## CI template (Bun stacks)

`.github/workflows/ci.yml`:

```yaml
name: ci
on:
  pull_request:
    branches: [main]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<verify-current-sha> # vX.Y.Z
      - uses: oven-sh/setup-bun@<verify-current-sha> # vX.Y.Z
        with:
          bun-version: latest
      - uses: actions/cache@<verify-current-sha> # vX.Y.Z
        with:
          path: ~/.bun/install/cache
          key: bun-${{ runner.os }}-${{ hashFiles('bun.lock', 'bun.lockb') }}
      - run: bun install --frozen-lockfile
      - run: bun run check
      - run: bun run typecheck
      - run: bun test
```

Replace every `<verify-current-sha>` after checking the action's releases page —
that verification is the cicd agent's job, per its contract.

Stack variations:
- expo: add `npx expo-doctor`; typecheck via `tsc --noEmit`.
- tauri: frontend checks as above; add `cargo check` in `src-tauri/` only if Rust code changed.
- extension: add a production build step (`bun run build`) to catch MV3 manifest errors.
- any other stack (unity, react-spa, …): same rules, different tools — find the
  stack's canonical CI actions (e.g. game-ci for Unity), verify and pin their
  SHAs, cache the stack's package/build artifacts, run whatever the project's
  real check commands are per team/architecture.md.

## Branch protection

Apply via gh after the repo exists:

```bash
gh api -X PUT "repos/{owner}/{repo}/branches/main/protection" \
  -H "Accept: application/vnd.github+json" \
  -F "required_status_checks[strict]=true" \
  -F "required_status_checks[contexts][]=check" \
  -F "enforce_admins=true" \
  -F "required_pull_request_reviews=null" \
  -F "restrictions=null"
```

Result to verify: direct push to main rejected; PRs require the `check` job green.
No required approvals: the same identity opens and reviews every PR, and GitHub
does not let an author approve their own PR — reviews are comments, CI is the gate.

## Merge settings

Every story PR is squash-merged by auto-merge, and its title becomes the one
commit on main:

```bash
gh repo edit --enable-auto-merge --delete-branch-on-merge   --enable-squash-merge --enable-merge-commit=false --enable-rebase-merge=false
gh api -X PATCH "repos/{owner}/{repo}"   -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=BLANK
```

Result to verify (`gh api repos/{owner}/{repo}`): `allow_auto_merge` and
`delete_branch_on_merge` true, only `allow_squash_merge` true, squash title
`PR_TITLE`, message `BLANK` — so main reads `<type>: <description> (#n)` and
nothing else.
