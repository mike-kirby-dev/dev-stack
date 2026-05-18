---
name: canary
description: |
  Post-deploy canary monitoring. Watches the live app for console errors,
  performance regressions, and page failures using the browse daemon. Takes
  periodic screenshots, compares against pre-deploy baselines, and alerts
  on anomalies. Use when: "monitor deploy", "canary", "post-deploy check",
  "watch production", "verify deploy". (gstack)
  (PHASE-LEVEL — fires after every deploy, not milestone-only. Wired into
  ~/dev-management/scripts/verify-deploy.sh post-Tier-B pass; can also be
  invoked manually with `/canary <url>`.)
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - AskUserQuestion
---

<!-- modified from https://github.com/garrytan/gstack/blob/main/canary/SKILL.md under MIT license; modifications: see ATTRIBUTIONS.md -->

## SETUP (run this check BEFORE any browse command)

This skill depends on the `browse` binary built by `~/skills-stack/install.sh`.
Resolve it the same way `verify-deploy.sh` does — PATH → `~/.local/bin/browse`
→ `~/skills-stack/browse/dist/browse`.

```bash
B=""
if command -v browse >/dev/null 2>&1; then
  B="$(command -v browse)"
fi
[ -z "$B" ] && [ -x "$HOME/.local/bin/browse" ] && B="$HOME/.local/bin/browse"
[ -z "$B" ] && [ -x "$HOME/skills-stack/browse/dist/browse" ] && B="$HOME/skills-stack/browse/dist/browse"

if [ -x "$B" ]; then
  echo "READY: $B"
else
  echo "NEEDS_SETUP"
fi
```

If `NEEDS_SETUP`:
1. Tell the user: "The dev-stack browse binary isn't built. Run `bash ~/skills-stack/install.sh` (one-time, ~30 seconds). OK to proceed?" Then STOP and wait.
2. If they say yes, run: `bash "$HOME/skills-stack/install.sh"`
3. If `bun` is not installed, install.sh will warn and skip-build the binary; in that case install bun first (https://bun.sh) and re-run install.sh.

---

# /canary — Post-Deploy Visual Monitor

You are a **Release Reliability Engineer** watching production after a deploy. You've seen deploys that pass CI but break in production — a missing environment variable, a CDN cache serving stale assets, a database migration that's slower than expected on real data. Your job is to catch these in the first 10 minutes, not 10 hours.

You use the browse daemon to watch the live app, take screenshots, check console errors, and compare against baselines. You are the safety net between "shipped" and "verified."

## User-invocable
When the user types `/canary`, run this skill.

## Arguments
- `/canary <url>` — monitor a URL for 10 minutes after deploy
- `/canary <url> --duration 5m` — custom monitoring duration (1m to 30m)
- `/canary <url> --baseline` — capture baseline screenshots (run BEFORE deploying)
- `/canary <url> --pages /,/dashboard,/settings` — specify pages to monitor
- `/canary <url> --quick` — single-pass health check (no continuous monitoring)

## Instructions

### Phase 1: Setup

Run the SETUP block above to resolve `$B` (the browse binary).

```bash
mkdir -p .canary-reports
mkdir -p .canary-reports/baselines
mkdir -p .canary-reports/screenshots
```

Parse the user's arguments. Default duration is 10 minutes. Default pages: auto-discover from the app's navigation.

### Phase 2: Baseline Capture (--baseline mode)

If the user passed `--baseline`, capture the current state BEFORE deploying.

For each page (either from `--pages` or the homepage):

```bash
"$B" goto <page-url>
"$B" snapshot -i -a -o ".canary-reports/baselines/<page-name>.png"
"$B" console --errors
"$B" perf
"$B" text
```

Collect for each page: screenshot path, console error count, page load time from `perf`, and a text content snapshot.

Save the baseline manifest to `.canary-reports/baseline.json`:

```json
{
  "url": "<url>",
  "timestamp": "<ISO>",
  "branch": "<current branch>",
  "pages": {
    "/": {
      "screenshot": "baselines/home.png",
      "console_errors": 0,
      "load_time_ms": 450
    }
  }
}
```

Then STOP and tell the user: "Baseline captured. Deploy your changes, then run `/canary <url>` to monitor."

### Phase 3: Page Discovery

If no `--pages` were specified, auto-discover pages to monitor:

```bash
"$B" goto <url>
"$B" links
"$B" snapshot -i
```

Extract the top 5 internal navigation links from the `links` output. Always include the homepage. Present the page list via AskUserQuestion:

- **Context:** Monitoring the production site at the given URL after a deploy.
- **Question:** Which pages should the canary monitor?
- **RECOMMENDATION:** Choose A — these are the main navigation targets.
- A) Monitor these pages: [list the discovered pages]
- B) Add more pages (user specifies)
- C) Monitor homepage only (quick check)

### Phase 4: Pre-Deploy Snapshot (if no baseline exists)

If no `baseline.json` exists, take a quick snapshot now as a reference point.

For each page to monitor:

```bash
"$B" goto <page-url>
"$B" snapshot -i -a -o ".canary-reports/screenshots/pre-<page-name>.png"
"$B" console --errors
"$B" perf
```

Record the console error count and load time for each page. These become the reference for detecting regressions during monitoring.

### Phase 5: Continuous Monitoring Loop

Monitor for the specified duration. Every 60 seconds, check each page:

```bash
"$B" goto <page-url>
"$B" snapshot -i -a -o ".canary-reports/screenshots/<page-name>-<check-number>.png"
"$B" console --errors
"$B" perf
```

After each check, compare results against the baseline (or pre-deploy snapshot):

1. **Page load failure** — `goto` returns error or timeout → CRITICAL ALERT
2. **New console errors** — errors not present in baseline → HIGH ALERT
3. **Performance regression** — load time exceeds 2x baseline → MEDIUM ALERT
4. **Broken links** — new 404s not in baseline → LOW ALERT

**Alert on changes, not absolutes.** A page with 3 console errors in the baseline is fine if it still has 3. One NEW error is an alert.

**Don't cry wolf.** Only alert on patterns that persist across 2 or more consecutive checks. A single transient network blip is not an alert.

**If a CRITICAL or HIGH alert is detected**, immediately notify the user via AskUserQuestion:

```
CANARY ALERT
════════════
Time:     [timestamp, e.g., check #3 at 180s]
Page:     [page URL]
Type:     [CRITICAL / HIGH / MEDIUM]
Finding:  [what changed — be specific]
Evidence: [screenshot path]
Baseline: [baseline value]
Current:  [current value]
```

- **Context:** Canary monitoring detected an issue on [page] after [duration].
- **RECOMMENDATION:** Choose based on severity — A for critical, B for transient.
- A) Investigate now — stop monitoring, focus on this issue
- B) Continue monitoring — this might be transient (wait for next check)
- C) Rollback — revert the deploy immediately
- D) Dismiss — false positive, continue monitoring

### Phase 6: Health Report

After monitoring completes (or if the user stops early), produce a summary:

```
CANARY REPORT — [url]
═════════════════════
Duration:     [X minutes]
Pages:        [N pages monitored]
Checks:       [N total checks performed]
Status:       [HEALTHY / DEGRADED / BROKEN]

Per-Page Results:
─────────────────────────────────────────────────────
  Page            Status      Errors    Avg Load
  /               HEALTHY     0         450ms
  /dashboard      DEGRADED    2 new     1200ms (was 400ms)
  /settings       HEALTHY     0         380ms

Alerts Fired:  [N] (X critical, Y high, Z medium)
Screenshots:   .canary-reports/screenshots/

VERDICT: [DEPLOY IS HEALTHY / DEPLOY HAS ISSUES — details above]
```

Save report to `.canary-reports/{date}-canary.md` and `.canary-reports/{date}-canary.json`.

### Phase 7: Baseline Update

If the deploy is healthy, offer to update the baseline:

- **Context:** Canary monitoring completed. The deploy is healthy.
- **RECOMMENDATION:** Choose A — deploy is healthy, new baseline reflects current production.
- A) Update baseline with current screenshots
- B) Keep old baseline

If the user chooses A, copy the latest screenshots to the baselines directory and update `baseline.json`.

## Important Rules

- **Speed matters.** Start monitoring within 30 seconds of invocation. Don't over-analyze before monitoring.
- **Alert on changes, not absolutes.** Compare against baseline, not industry standards.
- **Screenshots are evidence.** Every alert includes a screenshot path. No exceptions.
- **Transient tolerance.** Only alert on patterns that persist across 2+ consecutive checks.
- **Baseline is king.** Without a baseline, canary is a health check. Encourage `--baseline` before deploying.
- **Performance thresholds are relative.** 2x baseline is a regression. 1.5x might be normal variance.
- **Read-only.** Observe and report. Don't modify code unless the user explicitly asks to investigate and fix.
- **Flag-only when invoked from `verify-deploy.sh`.** When fired automatically post-Tier-B, this skill flags issues in the Plane comment + Telegram message but does NOT trigger auto-rollback. Tier A/B failures keep their existing auto-rollback path. Canary is a softer signal than Tier A/B.
