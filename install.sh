#!/usr/bin/env bash
# teamclaude installer (bash / curl path) — installs the team template.
# Primary installer is bin/cli.mjs (bunx github:Prerendered/teamclaude init);
# keep the install logic here in sync with it.
# Public repo:  curl -sL <raw-url>/install.sh | bash -s --
# Private repo: git clone <repo> && bash teamclaude/install.sh --local
# --stack is optional; the stack is normally chosen at intake.
set -euo pipefail

REPO_URL="${TEAMCLAUDE_REPO:-https://github.com/Prerendered/teamclaude.git}"
SCAFFOLDED_STACKS="next-convex tauri expo extension"
STACK=""
VERSION=""
FORCE=0
REPERTOIRE=""
LOCAL=0

usage() {
  cat <<EOF
Usage: install.sh [--stack <name>] [--version <tag>] [--repertoire <url>] [--local] [--force]

Flags:
  --stack <name>      Optional. The stack is normally chosen at intake; pass it only
                      to decide up front. Stacks with a scaffold skill:
                      ${SCAFFOLDED_STACKS// /, }.
                      Any other name installs without a scaffold. Omit to keep all
                      scaffold skills and let intake pick.
  --version <tag>     Team version to install (git tag, e.g. v1.0).
                      Defaults to the latest tag — never main HEAD.
  --repertoire <url>  Optional. Git URL of a cross-project repertoire repo. When
                      set, the team consults past projects at intake and saves
                      this one at wrap. Omit to disable the feature.
  --local             Install from the template/ next to this script instead of
                      cloning. Use when running from a checkout — required for
                      private repos, where raw/anonymous fetch does not work.
  --force             Overwrite an existing .claude/ directory.

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
    -h|--help) usage; exit 0 ;;
    *) usage >&2; fail "unknown flag: $1" ;;
  esac
done

HAS_SCAFFOLD=0
if [ -n "$STACK" ]; then
  case " $SCAFFOLDED_STACKS " in
    *" $STACK "*) HAS_SCAFFOLD=1 ;;
  esac
fi

if [ -d .claude ] && [ "$FORCE" -eq 0 ]; then
  fail ".claude/ already exists — re-run with --force to overwrite"
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

# Install agents + skills into .claude/, Overseer into repo root.
rm -rf .claude
mkdir -p .claude
cp -R "$SRC/agents" "$SRC/skills" .claude/
cp "$SRC/CLAUDE.md" ./CLAUDE.md

# Stack chosen up front → keep only its scaffold skill (none for custom stacks).
# Stack omitted → keep all scaffold skills; intake picks later.
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
for f in "$SRC"/team/*.md; do
  dest="team/$(basename "$f")"
  [ -e "$dest" ] || cp "$f" "$dest"
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

if [ -z "$STACK" ]; then
  echo "teamclaude $VERSION installed. Stack: chosen at intake (all scaffold skills kept)."
else
  echo "teamclaude $VERSION installed (stack: $STACK)."
  if [ "$HAS_SCAFFOLD" -eq 0 ]; then
    echo "note: no scaffold skill for '$STACK' — the architect will derive structure from reference repos."
  fi
fi
if [ -n "$REPERTOIRE" ]; then
  echo "repertoire: $REPERTOIRE — consulted at intake, saved at wrap."
fi
echo "Open Claude Code and say 'new project' to start intake."
