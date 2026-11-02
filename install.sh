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
DRY_RUN=0
BACKUP_ROOT=".teamclaude-backup"
IGNORE_MARK="# teamclaude working state — local only"
IGNORE_RULE="/team/"
WORKTREE_RULE="/.worktrees/"
BACKUP_RULE="/$BACKUP_ROOT/"

usage() {
  cat <<EOF
Usage: install.sh [--stack <name>] [--version <tag>] [--repertoire <url>] [--track-team] [--local] [--force] [--dry-run]
       install.sh --update [--stack <name>] [--version <tag>] [--track-team] [--local] [--dry-run]

Anything replaced or removed that differs from the installed version is first
copied to $BACKUP_ROOT/<timestamp>/, and a changed CLAUDE.md also to CLAUDE.md.bak.

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
  --dry-run           List what would be added, replaced, removed, and backed up.
                      Writes nothing.

Env:
  TEAMCLAUDE_REPO   Override the source repo URL (ignored with --local).
EOF
}

fail() { echo "error: $*" >&2; exit 1; }
need_value() { if [ -z "${2:-}" ] || [ "${2#--}" != "$2" ]; then fail "$1 needs a value"; fi; }

while [ $# -gt 0 ]; do
  case "$1" in
    --stack)      need_value "$@"; STACK="$2"; shift 2 ;;
    --version)    need_value "$@"; VERSION="$2"; shift 2 ;;
    --repertoire) need_value "$@"; REPERTOIRE="$2"; shift 2 ;;
    --local)      LOCAL=1; shift ;;
    --force)      FORCE=1; shift ;;
    --update)     UPDATE=1; shift ;;
    --track-team) TRACK_TEAM=1; shift ;;
    --dry-run)    DRY_RUN=1; shift ;;
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

is_pruned() {
  [ -n "$STACK" ] || return 1
  case "$1" in
    "scaffold-$STACK") return 1 ;;
    scaffold-*) return 0 ;;
    *) return 1 ;;
  esac
}

# Ignore rules this run needs that .gitignore doesn't already cover.
missing_ignore_rules() {
  if [ "$TRACK_TEAM" -eq 0 ] && ! grep -qsxE '[[:space:]]*/?team/?[[:space:]]*' .gitignore; then
    echo "$IGNORE_RULE"
  fi
  if ! grep -qsxE '[[:space:]]*/?\.worktrees/?[[:space:]]*' .gitignore; then
    echo "$WORKTREE_RULE"
  fi
  if [ -n "$PLAN_BACKUP" ] && ! grep -qsxE '[[:space:]]*/?\.teamclaude-backup/?[[:space:]]*' .gitignore; then
    echo "$BACKUP_RULE"
  fi
  if [ -n "$PLAN_BACKUP" ] && ! grep -qsxE '[[:space:]]*/?CLAUDE\.md\.bak[[:space:]]*' .gitignore; then
    echo "/CLAUDE.md.bak"
  fi
}

# What this run would do. Read-only: --dry-run prints it, a real run backs up from it.
PLAN_ADD=""
PLAN_REPLACE=""
PLAN_REMOVE=""
PLAN_SEED=""
PLAN_BACKUP=""
PLAN_SAME=0
for kind in agents skills; do
  for entry in "$SRC/$kind"/*; do
    name="$(basename "$entry")"
    to=".claude/$kind/$name"
    if [ -e "$to" ] && diff -rq "$entry" "$to" >/dev/null 2>&1; then same=1; else same=0; fi
    if [ "$kind" = skills ] && is_pruned "$name"; then
      if [ -e "$to" ]; then
        PLAN_REMOVE="$PLAN_REMOVE $to"
        [ "$same" -eq 1 ] || PLAN_BACKUP="$PLAN_BACKUP $to"
      fi
    elif [ ! -e "$to" ]; then
      PLAN_ADD="$PLAN_ADD $to"
    elif [ "$same" -eq 1 ]; then
      PLAN_SAME=$((PLAN_SAME + 1))
    else
      PLAN_REPLACE="$PLAN_REPLACE $to"
      PLAN_BACKUP="$PLAN_BACKUP $to"
    fi
  done
done
if [ ! -f CLAUDE.md ]; then
  PLAN_ADD="$PLAN_ADD CLAUDE.md"
elif cmp -s "$SRC/CLAUDE.md" CLAUDE.md; then
  PLAN_SAME=$((PLAN_SAME + 1))
else
  PLAN_REPLACE="$PLAN_REPLACE CLAUDE.md"
  PLAN_BACKUP="$PLAN_BACKUP CLAUDE.md"
fi
for f in "$SRC"/team/*; do
  dest="team/$(basename "$f")"
  [ -e "$dest" ] || PLAN_SEED="$PLAN_SEED $dest"
done

if [ "$DRY_RUN" -eq 1 ]; then
  if [ "$UPDATE" -eq 1 ]; then cmd=update; else cmd=init; fi
  echo "teamclaude $VERSION $cmd — dry run, nothing written."
  for p in $PLAN_ADD; do printf '  %-8s%s\n' add "$p"; done
  for p in $PLAN_REPLACE; do printf '  %-8s%s\n' replace "$p"; done
  for p in $PLAN_REMOVE; do printf '  %-8s%s\n' remove "$p"; done
  for p in $PLAN_SEED; do printf '  %-8s%s\n' seed "$p"; done
  for p in $PLAN_BACKUP; do printf '  %-8s%s\n' backup "$p"; done
  if [ "$TRACK_TEAM" -eq 1 ] && grep -qsxF "$IGNORE_RULE" .gitignore; then
    printf '  %-8s%s\n' ignore "-$IGNORE_RULE"
  fi
  for rule in $(missing_ignore_rules); do printf '  %-8s%s\n' ignore "+$rule"; done
  echo "$PLAN_SAME template entries already match. team/state.md gets the version stamp."
  [ -z "$PLAN_BACKUP" ] || echo "Backups would go to $BACKUP_ROOT/<timestamp>/."
  exit 0
fi

BACKUP_DIR=""
if [ -n "$PLAN_BACKUP" ]; then
  BACKUP_DIR="$BACKUP_ROOT/$(date -u +%Y-%m-%dT%H-%M-%SZ)"
  for p in $PLAN_BACKUP; do
    mkdir -p "$BACKUP_DIR/$(dirname "$p")"
    cp -R "$p" "$BACKUP_DIR/$p"
  done
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

# CLAUDE.md is template-owned, but a project may have its own or have appended to
# this one — keep a copy before replacing a changed one.
BACKED_UP=0
if [ -f CLAUDE.md ] && ! cmp -s "$SRC/CLAUDE.md" CLAUDE.md; then
  cp CLAUDE.md CLAUDE.md.bak
  BACKED_UP=1
fi
cp "$SRC/CLAUDE.md" ./CLAUDE.md

# Stack chosen up front → keep only its scaffold skill (none for custom stacks).
# Stack omitted → keep all scaffold skills; the Tech gate picks later.
# A scaffold skill the template doesn't ship is the project's own, so it stays.
if [ -n "$STACK" ]; then
  for dir in .claude/skills/scaffold-*; do
    name="$(basename "$dir")"
    if is_pruned "$name" && [ -e "$SRC/skills/$name" ]; then rm -rf "$dir"; fi
  done
  if [ "$HAS_SCAFFOLD" -eq 1 ] && [ ! -d ".claude/skills/scaffold-$STACK" ]; then
    fail "scaffold skill for $STACK missing in $VERSION"
  fi
fi

# Seed team/ stubs — never clobber existing project state.
mkdir -p team
SEEDED=""
for f in "$SRC"/team/*; do
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
MISSING="$(missing_ignore_rules)"
if [ -n "$MISSING" ]; then
  if grep -qxF "$IGNORE_MARK" .gitignore; then
    ADD="$MISSING" awk -v mark="$IGNORE_MARK" '{ print } $0 == mark { print ENVIRON["ADD"] }' .gitignore > .gitignore.tmp
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
if [ -n "$BACKUP_DIR" ]; then
  echo "Backed up items that differ from $VERSION to $BACKUP_DIR:$PLAN_BACKUP"
fi
[ "$BACKED_UP" -eq 0 ] || echo "CLAUDE.md replaced — your previous copy is at CLAUDE.md.bak. Merge anything you still need."
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
