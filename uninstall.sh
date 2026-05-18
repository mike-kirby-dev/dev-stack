#!/usr/bin/env bash
# uninstall.sh — remove dev-stack symlinks from ~/.claude/skills/
#
# Only removes symlinks that resolve back to this repo's skills/<name>/.
# Never touches non-symlink entries or symlinks pointing elsewhere.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
TARGET_DIR="$HOME/.claude/skills"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Nothing to do: $TARGET_DIR does not exist."
    exit 0
fi

removed=0
kept=0

for entry in "$TARGET_DIR"/*; do
    [ -L "$entry" ] || continue
    name=$(basename "$entry")
    target=$(readlink -f "$entry" 2>/dev/null || true)
    expected_prefix=$(readlink -f "$SKILLS_DIR")
    if [ -n "$target" ] && [[ "$target" == "$expected_prefix"/* ]]; then
        rm "$entry"
        echo "UNLINK $name"
        removed=$((removed + 1))
    else
        kept=$((kept + 1))
    fi
done

echo ""
echo "Done: $removed dev-stack symlinks removed, $kept other entries left untouched."
