#!/usr/bin/env bash
# teamclaude installer — installs the team template into the current project.
# Usage: curl -sL <raw-url>/install.sh | bash -s -- --stack next-convex [--version vX.Y] [--force]
set -euo pipefail

REPO_URL="${TEAMCLAUDE_REPO:-https://github.com/jesjugroo/claude-team.git}"
STACKS="next-convex tauri expo extension"
STACK=""
VERSION=""
FORCE=0

usage() {
  cat <<EOF
Usage: install.sh --stack <name> [--version <tag>] [--force]

Flags:
  --stack <name>    Required. One of: ${STACKS// /, }.
                    Keeps only the matching scaffold skill.
  --version <tag>   Team version to install (git tag, e.g. v1.0).
                    Defaults to the latest tag — never main HEAD.
  --force           Overwrite an existing .claude/ directory.

Env:
  TEAMCLAUDE_REPO   Override the source repo URL.
EOF
}

fail() { echo "error: $*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --stack)   STACK="${2:-}"; shift 2 ;;
    --version) VERSION="${2:-}"; shift 2 ;;
    --force)   FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; fail "unknown flag: $1" ;;
  esac
done

if [ -z "$STACK" ]; then usage >&2; fail "--stack is required"; fi
case " $STACKS " in
  *" $STACK "*) ;;
  *) fail "unknown stack: $STACK (available: $STACKS)" ;;
esac

if [ -d .claude ] && [ "$FORCE" -eq 0 ]; then
  fail ".claude/ already exists — re-run with --force to overwrite"
fi

command -v git >/dev/null 2>&1 || fail "git is required"

# Resolve version against release tags.
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

git clone --quiet --depth 1 --branch "$VERSION" "$REPO_URL" "$TMP/repo" \
  || fail "clone of $VERSION failed"
SRC="$TMP/repo/template"
[ -d "$SRC" ] || fail "template/ missing in $VERSION — corrupt release?"

# Install agents + skills into .claude/, Overseer into repo root.
rm -rf .claude
mkdir -p .claude
cp -R "$SRC/agents" "$SRC/skills" .claude/
cp "$SRC/CLAUDE.md" ./CLAUDE.md

# Keep only the requested stack's scaffold skill.
for dir in .claude/skills/scaffold-*; do
  [ "$(basename "$dir")" = "scaffold-$STACK" ] || rm -rf "$dir"
done
[ -d ".claude/skills/scaffold-$STACK" ] || fail "scaffold skill for $STACK missing in $VERSION"

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

echo "teamclaude $VERSION installed (stack: $STACK)."
echo "Open Claude Code and say 'new project' to start intake."
