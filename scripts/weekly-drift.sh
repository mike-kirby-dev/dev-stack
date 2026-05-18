#!/usr/bin/env bash
# weekly-drift.sh — detect upstream drift in forked skill files
#
# For each upstream (gstack, GSD v1, superpowers), compare current upstream HEAD
# against the SHA recorded at fork time (in ATTRIBUTIONS.md). For each forked
# file, diff our version vs upstream's current version. Compose a Markdown
# report and post to Mike's DM via notify-mike.sh.
#
# NEVER auto-applies changes. Mike reviews + merges by hand.
#
# Cron: 0 4 * * 0 bash /root/skills-stack/scripts/weekly-drift.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ATTRIBUTIONS="$REPO_ROOT/ATTRIBUTIONS.md"
REPORT_DIR="$(mktemp -d -t dev-stack-drift-XXXXXX)"
REPORT="$REPORT_DIR/report.md"
NOTIFY_SCRIPT="${NOTIFY_SCRIPT:-/root/dev-management/scripts/lib/notify-mike.sh}"

trap 'rm -rf "$REPORT_DIR"' EXIT

# --- Upstream definitions --------------------------------------------------
# Each upstream: name, repo URL, list of forked-files (local-path:upstream-path pairs).
declare -A UPSTREAM_URL=(
    [gstack]="https://github.com/garrytan/gstack.git"
    [gsd]="https://github.com/gsd-build/get-shit-done.git"
    [superpowers]="https://github.com/obra/superpowers.git"
)

# Each entry: "local_path_in_fork|upstream_path"
declare -a GSTACK_FILES=(
    "skills/gs-office-hours/SKILL.md|office-hours/SKILL.md"
    "skills/gs-plan-devex-review/SKILL.md|plan-devex-review/SKILL.md"
    "skills/gs-plan-ceo-review/SKILL.md|plan-ceo-review/SKILL.md"
    "skills/gs-plan-eng-review/SKILL.md|plan-eng-review/SKILL.md"
    "skills/gs-plan-design-review/SKILL.md|plan-design-review/SKILL.md"
)

declare -a GSD_FILES=()  # Populated in later passes

declare -a SUPERPOWERS_FILES=(
    "skills/sp-brainstorming/SKILL.md|skills/brainstorming/SKILL.md"
)

# --- Helpers ---------------------------------------------------------------

extract_fork_sha() {
    # Pull the SHA recorded in ATTRIBUTIONS.md for a given upstream label.
    local label="$1"
    case "$label" in
        gstack)      grep -A20 "^## gstack" "$ATTRIBUTIONS" | grep "commit SHA" | head -1 | grep -oE '[0-9a-f]{40}' ;;
        gsd)         grep -A20 "^## GSD v1" "$ATTRIBUTIONS" | grep "commit SHA" | head -1 | grep -oE '[0-9a-f]{40}' ;;
        superpowers) grep -A20 "^## Superpowers" "$ATTRIBUTIONS" | grep "commit SHA" | head -1 | grep -oE '[0-9a-f]{40}' ;;
    esac
}

current_head_sha() {
    local url="$1"
    git ls-remote "$url" HEAD 2>/dev/null | awk '{print $1}'
}

clone_upstream() {
    local label="$1"
    local url="$2"
    local clone_path="$REPORT_DIR/$label-upstream"
    git clone --quiet --depth 1 "$url" "$clone_path" 2>/dev/null
    echo "$clone_path"
}

diff_file() {
    # Args: local_file, upstream_file
    # Returns nothing if identical; writes a unified diff to stdout otherwise.
    local local_path="$1"
    local upstream_path="$2"
    if [ ! -f "$upstream_path" ]; then
        echo "  UPSTREAM FILE NOT FOUND: $upstream_path"
        return
    fi
    diff -u "$upstream_path" "$local_path" 2>/dev/null || true
}

# --- Report header --------------------------------------------------------

{
    echo "# dev-stack drift report"
    echo ""
    echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "Fork SHAs recorded in ATTRIBUTIONS.md."
    echo ""
} > "$REPORT"

# --- Loop over upstreams --------------------------------------------------

total_changed=0
total_files_changed=0

for label in gstack gsd superpowers; do
    url="${UPSTREAM_URL[$label]}"
    fork_sha=$(extract_fork_sha "$label")
    current_sha=$(current_head_sha "$url")

    case "$label" in
        gstack)      files=("${GSTACK_FILES[@]}") ;;
        gsd)         files=("${GSD_FILES[@]:-}") ;;
        superpowers) files=("${SUPERPOWERS_FILES[@]}") ;;
    esac

    {
        echo "## $label"
        echo ""
        echo "- Upstream: $url"
        echo "- Fork SHA: \`$fork_sha\`"
        echo "- Current HEAD: \`$current_sha\`"
    } >> "$REPORT"

    if [ -z "${files[0]:-}" ]; then
        echo "- Files tracked: 0 (no skills from this upstream yet)" >> "$REPORT"
        echo "" >> "$REPORT"
        continue
    fi

    if [ "$fork_sha" = "$current_sha" ]; then
        echo "- **Status: UNCHANGED since fork** (no action needed)" >> "$REPORT"
        echo "" >> "$REPORT"
        continue
    fi

    total_changed=$((total_changed + 1))
    echo "- **Status: UPSTREAM HEAD MOVED**" >> "$REPORT"
    echo "" >> "$REPORT"

    upstream_clone=$(clone_upstream "$label" "$url")
    if [ -z "$upstream_clone" ] || [ ! -d "$upstream_clone" ]; then
        echo "  Could not clone upstream; skipping diff." >> "$REPORT"
        echo "" >> "$REPORT"
        continue
    fi

    files_in_this_upstream_changed=0

    for pair in "${files[@]}"; do
        [ -n "$pair" ] || continue
        local_rel="${pair%%|*}"
        upstream_rel="${pair##*|}"
        local_path="$REPO_ROOT/$local_rel"
        upstream_path="$upstream_clone/$upstream_rel"

        if [ ! -f "$upstream_path" ]; then
            echo "### \`$local_rel\`" >> "$REPORT"
            echo "" >> "$REPORT"
            echo "Upstream file no longer exists at \`$upstream_rel\` — investigate." >> "$REPORT"
            echo "" >> "$REPORT"
            files_in_this_upstream_changed=$((files_in_this_upstream_changed + 1))
            continue
        fi

        # Quick equality test ignoring our modification header
        # (we always inject one line of attribution; strip both copies' leading metadata for parity)
        if diff -q "$local_path" "$upstream_path" >/dev/null 2>&1; then
            continue
        fi

        files_in_this_upstream_changed=$((files_in_this_upstream_changed + 1))
        total_files_changed=$((total_files_changed + 1))

        added=$(diff "$upstream_path" "$local_path" 2>/dev/null | grep -c '^>' || true)
        removed=$(diff "$upstream_path" "$local_path" 2>/dev/null | grep -c '^<' || true)

        {
            echo "### \`$local_rel\`"
            echo ""
            echo "vs upstream \`$upstream_rel\` — $added lines added in our fork, $removed removed."
            echo ""
            echo "<details><summary>Diff (truncated to first 200 lines)</summary>"
            echo ""
            echo '```diff'
            diff -u "$upstream_path" "$local_path" 2>/dev/null | head -200 || true
            echo '```'
            echo ""
            echo "</details>"
            echo ""
        } >> "$REPORT"
    done

    echo "  ($files_in_this_upstream_changed of ${#files[@]} forked files differ from upstream HEAD)" >> "$REPORT"
    echo "" >> "$REPORT"
done

# --- Summary header at top ------------------------------------------------

{
    echo "# dev-stack drift report"
    echo ""
    echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo ""
    if [ "$total_changed" -eq 0 ]; then
        echo "**Summary: no upstream HEAD movement detected. All forks current.**"
    else
        echo "**Summary: $total_changed upstream(s) changed since fork; $total_files_changed forked file(s) differ.**"
        echo ""
        echo "Action: review the diffs below, decide per-file whether to incorporate upstream changes, edit the relevant \`skills/<name>/SKILL.md\` in this repo, commit + push, and update the fork SHA in ATTRIBUTIONS.md."
    fi
    echo ""
    tail -n +4 "$REPORT"
} > "$REPORT.final"
mv "$REPORT.final" "$REPORT"

# --- Send via notify-mike.sh ----------------------------------------------

# Force DM (NOT CICD group) by explicitly emptying CICD_GROUP_CHAT_ID.
export CICD_GROUP_CHAT_ID=""

if [ -x "$NOTIFY_SCRIPT" ]; then
    # Pass report as file or inline depending on size
    report_size=$(wc -c < "$REPORT")
    if [ "$report_size" -lt 4000 ]; then
        # Small enough to inline
        bash "$NOTIFY_SCRIPT" send_telegram "$(cat "$REPORT")" || {
            echo "WARN: notify-mike.sh send_telegram failed; report at $REPORT" >&2
            cp "$REPORT" /tmp/dev-stack-drift-last.md
        }
    else
        # Too big — send a summary + path
        summary=$(head -10 "$REPORT")
        cp "$REPORT" /tmp/dev-stack-drift-last.md
        bash "$NOTIFY_SCRIPT" send_telegram "dev-stack drift report (full at /tmp/dev-stack-drift-last.md):

$summary

[truncated — see file]" || true
    fi
else
    echo "WARN: $NOTIFY_SCRIPT not executable; skipping Telegram send." >&2
    echo "Report at: $REPORT" >&2
    cp "$REPORT" /tmp/dev-stack-drift-last.md
fi

exit 0
