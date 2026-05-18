#!/usr/bin/env bash
# install.sh — symlink dev-stack skills into ~/.claude/skills/
#
# Idempotent: skips skills already symlinked to this repo.
# Aborts on conflict: if a non-symlink (or wrong-target symlink) exists, exit 1.
#
# Pass 1 scope: symlinker only. Pass 2 will add the browse-binary build step
# needed by gs-canary (which lands in a later pass).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
TARGET_DIR="$HOME/.claude/skills"

if [ ! -d "$SKILLS_DIR" ]; then
    echo "ERROR: $SKILLS_DIR does not exist" >&2
    exit 1
fi

mkdir -p "$TARGET_DIR"

installed=0
skipped=0
skill_count=0

for skill_path in "$SKILLS_DIR"/*/; do
    [ -d "$skill_path" ] || continue
    skill_name=$(basename "$skill_path")
    skill_count=$((skill_count + 1))
    target="$TARGET_DIR/$skill_name"

    if [ -L "$target" ]; then
        # Already a symlink — verify it points at our repo
        existing_target=$(readlink -f "$target" 2>/dev/null || readlink "$target")
        expected_target=$(readlink -f "$skill_path")
        if [ "$existing_target" = "$expected_target" ]; then
            echo "SKIP   $skill_name (already linked)"
            skipped=$((skipped + 1))
            continue
        else
            echo "ERROR: $target is a symlink to $existing_target — expected $expected_target" >&2
            echo "       Remove the conflicting symlink and re-run install.sh." >&2
            exit 1
        fi
    elif [ -e "$target" ]; then
        echo "ERROR: $target exists and is not a symlink." >&2
        echo "       Refusing to clobber. Back up the existing file/dir and re-run." >&2
        exit 1
    fi

    ln -s "$skill_path" "$target"
    echo "LINK   $skill_name -> $skill_path"
    installed=$((installed + 1))
done

echo ""
echo "Done: $skill_count skills total, $installed newly linked, $skipped already linked."
