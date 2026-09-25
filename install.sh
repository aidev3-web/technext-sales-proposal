#!/usr/bin/env bash
#
# Install the technext-sales-proposal skill into an agent's skills directory.
#
# Links <DEST>/technext-sales-proposal to this repository, and links each of the 10
# sub-skills under skills/ into <DEST>/<name> - the pipeline dispatches those
# sub-skills by name, so they must be discoverable on their own.
#
# An existing real directory is never overwritten; it is reported and skipped.
# Use --copy where symlinks are not available.
#
# Usage:
#   ./install.sh [--dest DIR] [--copy] [--skip-sub-skills] [--dry-run]
#   ./install.sh --dest "$HOME/.codex/skills"

set -euo pipefail

SKILL_NAME="technext-sales-proposal"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUB_DIR="$REPO_ROOT/skills"

DEST=""
COPY=0
SKIP_SUBS=0
DRY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dest)            DEST="${2:-}"; shift 2 ;;
    --dest=*)          DEST="${1#*=}"; shift ;;
    --copy)            COPY=1; shift ;;
    --skip-sub-skills) SKIP_SUBS=1; shift ;;
    --dry-run)         DRY=1; shift ;;
    -h|--help)
      sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

if [ ! -f "$REPO_ROOT/SKILL.md" ]; then
  echo "SKILL.md not found next to this script - run the installer from the repository root." >&2
  exit 1
fi

if [ -z "$DEST" ]; then
  CANDIDATES=()
  for d in \
    "$HOME/.claude/skills" \
    "$HOME/.codex/skills" \
    "$HOME/.config/opencode/skills" \
    "$HOME/.gemini/skills" \
    "$HOME/.copilot/skills" \
    "$HOME/.cursor/skills"
  do
    [ -d "$d" ] && CANDIDATES+=("$d")
  done

  if [ "${#CANDIDATES[@]}" -eq 1 ]; then
    DEST="${CANDIDATES[0]}"
    echo "Using the only agent skills directory found: $DEST"
    echo
  elif [ "${#CANDIDATES[@]}" -eq 0 ]; then
    echo "No agent skills directory found. Re-run with --dest <path to your agent's skills dir>." >&2
    exit 1
  else
    echo "Several agent skills directories exist. Re-run with --dest <path>:"
    echo
    for d in "${CANDIDATES[@]}"; do echo "  --dest \"$d\""; done
    exit 1
  fi
fi

echo "Source      : $REPO_ROOT"
echo "Destination : $DEST"
echo "Mode        : $([ "$COPY" -eq 1 ] && echo copy || echo link)$([ "$DRY" -eq 1 ] && echo ' (dry run)')"
echo

install_link() {
  local link_path="$1" target_path="$2"

  if [ -e "$link_path" ] || [ -L "$link_path" ]; then
    if [ -L "$link_path" ]; then
      if [ "$DRY" -eq 1 ]; then echo "  [dry-run] would refresh $link_path"; return; fi
      rm -f "$link_path"
    else
      echo "  skipped (a real directory already exists): $link_path" >&2
      return
    fi
  fi

  if [ "$DRY" -eq 1 ]; then echo "  [dry-run] $link_path -> $target_path"; return; fi

  if [ "$COPY" -eq 1 ]; then
    cp -R "$target_path" "$link_path"
    echo "  copied  $link_path"
    return
  fi

  if ln -s "$target_path" "$link_path" 2>/dev/null; then
    echo "  linked  $link_path"
  else
    echo "  symlink failed; copying instead" >&2
    cp -R "$target_path" "$link_path"
    echo "  copied  $link_path"
  fi
}

[ "$DRY" -eq 1 ] || mkdir -p "$DEST"

echo "Orchestrator skill"
install_link "$DEST/$SKILL_NAME" "$REPO_ROOT"

if [ "$SKIP_SUBS" -eq 0 ]; then
  echo
  echo "Sub-skills"
  for d in "$SUB_DIR"/*/; do
    [ -d "$d" ] || continue
    install_link "$DEST/$(basename "$d")" "${d%/}"
  done
fi

echo
echo "Done. Ask your agent for a sales proposal to test the install."
