#!/usr/bin/env bash
# teamclaude installer (bash / curl path) — installs the team template.
# Primary installer is bin/cli.mjs (bunx github:Prerendered/teamclaude init);
# keep the install logic here in sync with it.
# Public repo:  curl -sL <raw-url>/install.sh | bash -s --
# Private repo: git clone <repo> && bash teamclaude/install.sh --local
# --stack is optional; the stack is normally chosen at the Tech gate.
set -euo pipefail

REPO_URL="${TEAMCLAUDE_REPO:-https://github.com/Prerendered/teamclaude.git}"
SCAFFOLDED_STACKS="next-convex tauri expo extension"
STACK=""
VERSION=""
FORCE=0
UPDATE=0
REPERTOIRE=""
LOCAL=0
TRACK_TEAM=0
IGNORE_MARK="# teamclaude working state — local only"
IGNORE_RULE="/team/"
WORKTREE_RULE="/.worktrees/"

usage() {
  cat <<EOF
Usage: install.sh [--stack <name>] [--version <tag>] [--repertoire <url>] [--track-team] [--local] [--force]
       install.sh --update [--stack <name>] [--version <tag>] [--track-team] [--local]

Flags:
  --update            Refresh an existing install. Replaces the template's agents,
                      skills, and CLAUDE.md; leaves .claude/settings.json,
                      project-local agents/skills, and team/ artifacts untouched.
                      Defaults --stack to the value in team/state.md.
  --stack <name>      Optional. The stack is normally chosen at the Tech gate; pass it only
                      to decide up front. Stacks with a scaffold skill:
                      ${SCAFFOLDED_STACKS// /, }.
                      Any other name installs without a scaffold. Omit to keep all
                      scaffold skills and let the Tech gate pick.
  --version <tag>     Team version to install (git tag, e.g. v1.0).
                      Defaults to the latest tag — never main HEAD.
  --repertoire <url>  Optional. Git URL of a cross-project repertoire repo. When
                      set, the team consults past projects at intake and saves
                      this one at wrap. Omit to disable the feature.
  --track-team        Commit team/ with the project. By default team/ is local
                      working state and gets added to .gitignore. Recorded in
                      team/state.md, so --update keeps it.
  --local            Install from the template/ next to this script instead of
                      cloning. Use when running from a checkout — required for
                      private repos, where raw/anonymous fetch does not work.
  --force             Reinstall over an existing .claude/ directory.

Env:
  TEAMCLAUDE_REPO   Override the source repo URL (ignored with --local).
EOF
}

fail() { echo "error: $*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --stack)      STACK="${2:-}"; shift 2 ;;
    --version)    VERSION="${2:-}"; shift 2 ;;
    --repertoire) REPERTOIRE="${2:-}"; shift 2 ;;
    --local)      LOCAL=1; shift ;;
    --force)      FORCE=1; shift ;;
    --update)     UPDATE=1; shift ;;
    --track-team) TRACK_TEAM=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; fail "unknown flag: $1" ;;
  esac
done

if [ "$UPDATE" -eq 1 ] && [ "$FORCE" -eq 1 ]; then
  fail "--force is not valid with --update — update never removes files it did not install"
fi

if [ "$UPDATE" -eq 1 ]; then
  [ -d .claude/agents ] && [ -f team/state.md ] \
    || fail "no teamclaude install found here (need .claude/agents and team/state.md) — run without --update first"
  # An update inherits the stack the project was installed with.
  if [ -z "$STACK" ]; then
    STACK="$(sed -n 's/^stack:[[:space:]]*//p' team/state.md | head -n 1)"
  fi
  FROM="$(sed -n 's/^team-version:[[:space:]]*//p' team/state.md | head -n 1)"
  FROM="${FROM:-unknown}"
  grep -q '^team-tracked:[[:space:]]*true' team/state.md && TRACK_TEAM=1
elif [ -d .claude ] && [ "$FORCE" -eq 0 ]; then
  fail ".claude/ already exists — re-run with --update to refresh it, or --force to reinstall"
fi

# Recompute now that --update may have supplied the stack from team/state.md.
HAS_SCAFFOLD=0
if [ -n "$STACK" ]; then
  case " $SCAFFOLDED_STACKS " in
    *" $STACK "*) HAS_SCAFFOLD=1 ;;
  esac
fi

command -v git >/dev/null 2>&1 || fail "git is required"

if [ "$LOCAL" -eq 1 ]; then
  # Install from the checkout this script lives in — no network, works for private repos.
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  SRC="$SCRIPT_DIR/template"
  [ -d "$SRC" ] || fail "--local: no template/ next to install.sh ($SRC) — run from a teamclaude checkout"
  if [ -z "$VERSION" ]; then
    VERSION="$(git -C "$SCRIPT_DIR" describe --tags --always 2>/dev/null || echo local)"
  fi
else
  # Resolve version against release tags, then clone the pinned tag.
  TAGS="$(git ls-remote --tags --refs "$REPO_URL" 2>/dev/null | sed 's|.*refs/tags/||' | sort -V)" \
    || fail "cannot reach $REPO_URL"
  [ -n "$TAGS" ] || fail "no release tags found at $REPO_URL"

  if [ -z "$VERSION" ]; then
    VERSION="$(printf '%s\n' "$TAGS" | tail -n 1)"
  elif ! printf '%s\n' "$TAGS" | grep -qx "$VERSION"; then
    fail "unknown version: $VERSION — available tags: $(printf '%s' "$TAGS" | tr '\n' ' ')"
  fi

  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT

  git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$VERSION" "$REPO_URL" "$TMP/repo" \
    || fail "clone of $VERSION failed"
  SRC="$TMP/repo/template"
  [ -d "$SRC" ] || fail "template/ missing in $VERSION — corrupt release?"
fi

# Replace each agent/skill the template ships, one by one. A blanket rm of .claude/
# would also take settings.json and any agent or skill the project added itself.
for kind in agents skills; do
  mkdir -p ".claude/$kind"
  for entry in "$SRC/$kind"/*; do
    name="$(basename "$entry")"
    rm -rf ".claude/$kind/$name"
    cp -R "$entry" ".claude/$kind/$name"
  done
done

# CLAUDE.md is template-owned, but a project may have appended to it — keep a copy
# before replacing a changed one on update/force.
BACKED_UP=0
if [ -f CLAUDE.md ] && ! cmp -s "$SRC/CLAUDE.md" CLAUDE.md && { [ "$UPDATE" -eq 1 ] || [ "$FORCE" -eq 1 ]; }; then
  cp CLAUDE.md CLAUDE.md.bak
  BACKED_UP=1
fi
cp "$SRC/CLAUDE.md" ./CLAUDE.md

# Stack chosen up front → keep only its scaffold skill (none for custom stacks).
# Stack omitted → keep all scaffold skills; the Tech gate picks later.
if [ -n "$STACK" ]; then
  for dir in .claude/skills/scaffold-*; do
    [ "$(basename "$dir")" = "scaffold-$STACK" ] || rm -rf "$dir"
  done
  if [ "$HAS_SCAFFOLD" -eq 1 ] && [ ! -d ".claude/skills/scaffold-$STACK" ]; then
    fail "scaffold skill for $STACK missing in $VERSION"
  fi
fi

# Seed team/ stubs — never clobber existing project state.
mkdir -p team
SEEDED=""
for f in "$SRC"/team/*.md; do
  dest="team/$(basename "$f")"
  [ -e "$dest" ] || { cp "$f" "$dest"; SEEDED="$SEEDED $(basename "$f")"; }
done

# Stamp the installed version into team/state.md.
if grep -q '^team-version:' team/state.md; then
  sed -i.bak "s/^team-version:.*/team-version: $VERSION/" team/state.md
  rm -f team/state.md.bak
else
  printf 'team-version: %s\n%s\n' "$VERSION" "$(cat team/state.md)" > team/state.md
fi

# Stamp the chosen stack into team/state.md when provided (intake honors it).
if [ -n "$STACK" ]; then
  if grep -q '^stack:' team/state.md; then
    sed -i.bak "s|^stack:.*|stack: $STACK|" team/state.md
    rm -f team/state.md.bak
  else
    printf 'stack: %s\n%s\n' "$STACK" "$(cat team/state.md)" > team/state.md
  fi
fi

# Stamp the repertoire URL into team/state.md when provided.
if [ -n "$REPERTOIRE" ]; then
  if grep -q '^repertoire:' team/state.md; then
    sed -i.bak "s|^repertoire:.*|repertoire: $REPERTOIRE|" team/state.md
    rm -f team/state.md.bak
  else
    printf 'repertoire: %s\n%s\n' "$REPERTOIRE" "$(cat team/state.md)" > team/state.md
  fi
fi

# team/ is local working state — gitignore it unless the user opted to track it.
# .worktrees/ holds per-story checkouts and is never tracked. Only the /team/ line
# we add is ever removed.
touch .gitignore
if [ "$TRACK_TEAM" -eq 1 ]; then
  grep -q '^team-tracked:' team/state.md \
    || printf 'team-tracked: true\n%s\n' "$(cat team/state.md)" > team/state.md
  grep -vxF "$IGNORE_RULE" .gitignore > .gitignore.tmp || true
  mv .gitignore.tmp .gitignore
fi
MISSING=""
if [ "$TRACK_TEAM" -eq 0 ] && ! grep -qxE '[[:space:]]*/?team/?[[:space:]]*' .gitignore; then
  MISSING="$IGNORE_RULE"
fi
if ! grep -qxE '[[:space:]]*/?\.worktrees/?[[:space:]]*' .gitignore; then
  MISSING="${MISSING:+$MISSING
}$WORKTREE_RULE"
fi
if [ -n "$MISSING" ]; then
  if grep -qxF "$IGNORE_MARK" .gitignore; then
    awk -v mark="$IGNORE_MARK" -v add="$MISSING" '{ print } $0 == mark { print add }' .gitignore > .gitignore.tmp
    mv .gitignore.tmp .gitignore
  else
    if [ -s .gitignore ]; then
      [ -z "$(tail -c 1 .gitignore)" ] || echo >> .gitignore
      echo >> .gitignore
    fi
    printf '%s\n%s\n' "$IGNORE_MARK" "$MISSING" >> .gitignore
  fi
fi

if [ "$UPDATE" -eq 1 ]; then
  echo "teamclaude $FROM → $VERSION. Refreshed: .claude/agents, .claude/skills, CLAUDE.md."
  if [ -n "$STACK" ]; then echo "stack: $STACK (from team/state.md unless overridden)."
  else echo "stack: unset — all scaffold skills kept."; fi
  [ "$BACKED_UP" -eq 0 ] || echo "CLAUDE.md replaced — your previous copy is at CLAUDE.md.bak. Diff it if you had added to it."
  [ -z "$SEEDED" ] || echo "new team/ stubs added:$SEEDED"
  echo "Existing team/ artifacts and .claude/settings.json were not touched."
elif [ -z "$STACK" ]; then
  echo "teamclaude $VERSION installed. Stack: chosen at the Tech gate (all scaffold skills kept)."
else
  echo "teamclaude $VERSION installed (stack: $STACK)."
  if [ "$HAS_SCAFFOLD" -eq 0 ]; then
    echo "note: no scaffold skill for '$STACK' — the architect will derive structure from reference repos."
  fi
fi
if [ -n "$REPERTOIRE" ]; then
  echo "repertoire: $REPERTOIRE — consulted at intake, saved at wrap."
fi
if [ "$TRACK_TEAM" -eq 1 ]; then
  echo "team/: tracked in git (team-tracked: true)."
else
  echo "team/: local only — gitignored."
  # An ignore rule does not untrack files that are already committed.
  if [ -n "$(git ls-files -- team 2>/dev/null)" ]; then
    echo "note: team/ is already committed — .gitignore does not untrack it. To drop it from the repo:"
    echo "      git rm -r --cached team && git commit -m \"chore: stop tracking team/\""
  fi
fi
[ "$UPDATE" -eq 1 ] || echo "Open Claude Code and say 'new project' to start intake."
