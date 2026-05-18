#!/usr/bin/env bash
# install.sh — symlink dev-stack skills into ~/.claude/skills/
#
# Idempotent: skips skills already symlinked to this repo.
# Aborts on conflict: if a non-symlink (or wrong-target symlink) exists, exit 1.
#
# Flags:
#   --include-woz-only   Also install Woz-scoped skills (e.g. sp-writing-plans).
#                        Default install skips them so project-owner sessions
#                        don't accidentally invoke them.
#   --skip-browse        Skip the browse-binary build step (useful for CI or
#                        when you only want the skill symlinks).
#
# sp-writing-plans is Woz-only — agent-cto installs with --include-woz-only;
# project-owner installs do not.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
TARGET_DIR="$HOME/.claude/skills"
BROWSE_DIR="$REPO_ROOT/browse"

# --- Flag parsing -----------------------------------------------------------

INCLUDE_WOZ_ONLY=0
SKIP_BROWSE=0

for arg in "$@"; do
    case "$arg" in
        --include-woz-only) INCLUDE_WOZ_ONLY=1 ;;
        --skip-browse)      SKIP_BROWSE=1 ;;
        -h|--help)
            sed -n '2,15p' "$0"
            exit 0
            ;;
        *)
            echo "ERROR: unknown flag: $arg" >&2
            echo "Run with --help for usage." >&2
            exit 1
            ;;
    esac
done

# Skills that are Woz-only — agent-cto session only, NOT project-owner sessions.
# Each entry is a skill directory name under skills/.
WOZ_ONLY_SKILLS=("sp-writing-plans")

is_woz_only() {
    local name="$1"
    local woz
    for woz in "${WOZ_ONLY_SKILLS[@]}"; do
        [ "$name" = "$woz" ] && return 0
    done
    return 1
}

# --- Skill symlinker --------------------------------------------------------

if [ ! -d "$SKILLS_DIR" ]; then
    echo "ERROR: $SKILLS_DIR does not exist" >&2
    exit 1
fi

mkdir -p "$TARGET_DIR"

installed=0
skipped=0
woz_skipped=0
skill_count=0

for skill_path in "$SKILLS_DIR"/*/; do
    [ -d "$skill_path" ] || continue
    skill_name=$(basename "$skill_path")
    skill_count=$((skill_count + 1))

    # Gate Woz-only skills behind --include-woz-only.
    if is_woz_only "$skill_name" && [ "$INCLUDE_WOZ_ONLY" -ne 1 ]; then
        echo "SKIP   $skill_name (Woz-only — pass --include-woz-only to install)"
        woz_skipped=$((woz_skipped + 1))
        continue
    fi

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
echo "Skills: $skill_count total, $installed newly linked, $skipped already linked, $woz_skipped Woz-only skipped."

# --- browse binary build ----------------------------------------------------

build_browse() {
    # Skip if browse/ directory not present in this repo.
    if [ ! -d "$BROWSE_DIR" ]; then
        echo ""
        echo "browse: directory not present at $BROWSE_DIR — skipping build."
        return 0
    fi

    if [ "$SKIP_BROWSE" -eq 1 ]; then
        echo ""
        echo "browse: --skip-browse passed — skipping build."
        return 0
    fi

    echo ""
    echo "browse: detected at $BROWSE_DIR"

    # Idempotency: if dist/browse exists and is newer than every file under src/,
    # skip the rebuild.
    local dist_bin="$BROWSE_DIR/dist/browse"
    if [ -x "$dist_bin" ]; then
        local newest_src
        newest_src=$(find "$BROWSE_DIR/src" -type f -newer "$dist_bin" -print -quit 2>/dev/null || true)
        if [ -z "$newest_src" ]; then
            echo "browse: dist/browse is up-to-date — skipping rebuild."
        else
            echo "browse: src/ is newer than dist/browse — rebuild needed."
            dist_bin=""  # force rebuild path below
        fi
    else
        dist_bin=""
    fi

    if [ -z "$dist_bin" ]; then
        if ! command -v bun >/dev/null 2>&1; then
            echo "WARN   browse: bun not found on PATH. Install Bun first: https://bun.sh" >&2
            echo "WARN   browse: skipping build (skills depending on browse will not function)." >&2
            return 0
        fi

        echo "browse: bun install"
        (cd "$BROWSE_DIR" && bun install)

        echo "browse: bun run build"
        (cd "$BROWSE_DIR" && bun run build)

        if [ ! -x "$BROWSE_DIR/dist/browse" ]; then
            echo "ERROR: browse: build completed but dist/browse not found or not executable." >&2
            return 1
        fi
    fi

    # Symlink dist/browse into ~/.local/bin/browse (must be on user's PATH).
    local bin_dir="$HOME/.local/bin"
    mkdir -p "$bin_dir"
    local bin_link="$bin_dir/browse"
    local browse_target="$BROWSE_DIR/dist/browse"

    if [ -L "$bin_link" ]; then
        local existing
        existing=$(readlink -f "$bin_link" 2>/dev/null || readlink "$bin_link")
        if [ "$existing" = "$(readlink -f "$browse_target")" ]; then
            echo "browse: $bin_link already symlinked to $browse_target"
        else
            echo "ERROR: $bin_link is a symlink to $existing — expected $browse_target" >&2
            echo "       Remove the conflicting symlink and re-run install.sh." >&2
            return 1
        fi
    elif [ -e "$bin_link" ]; then
        echo "ERROR: $bin_link exists and is not a symlink. Refusing to clobber." >&2
        return 1
    else
        ln -s "$browse_target" "$bin_link"
        echo "browse: symlinked $bin_link -> $browse_target"
    fi

    # PATH hint (don't try to modify the user's shell rc — just warn).
    case ":$PATH:" in
        *":$bin_dir:"*) ;;
        *)
            echo "WARN   browse: $bin_dir is not on your PATH. Add it to your shell rc:" >&2
            echo "WARN     export PATH=\"\$HOME/.local/bin:\$PATH\"" >&2
            ;;
    esac
}

build_browse

echo ""
echo "Done."
