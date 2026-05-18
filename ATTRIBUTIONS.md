# ATTRIBUTIONS

This repo is a curated, modified subset of three upstream Claude Code skill packages, each MIT-licensed. Every skill file is either a verbatim copy or a modification of an upstream file; modified files carry an HTML-comment attribution header near the top of the file pointing back at the upstream URL.

## gstack — Garry Tan

- **Upstream:** https://github.com/garrytan/gstack
- **License:** MIT (see `licenses/gstack-LICENSE`)
- **Original author / copyright:** © Garry Tan
- **Fork date:** 2026-05-18
- **Upstream commit SHA at fork:** `026751ea2012ec7cbedc149ba615929a20026501`
- **Skills taken from this upstream:**
  - `skills/gs-office-hours/SKILL.md` (from upstream `office-hours/SKILL.md`)
  - `skills/gs-plan-devex-review/SKILL.md` (from upstream `plan-devex-review/SKILL.md`)
  - `skills/gs-plan-ceo-review/SKILL.md` (from upstream `plan-ceo-review/SKILL.md`)
  - `skills/gs-plan-eng-review/SKILL.md` (from upstream `plan-eng-review/SKILL.md`)
  - `skills/gs-plan-design-review/SKILL.md` (from upstream `plan-design-review/SKILL.md`)
  - `skills/gs-canary/SKILL.md` (from upstream `canary/SKILL.md`) — PHASE-LEVEL, not milestone-only. Fires after every deploy via `verify-deploy.sh`.
- **Modifications:**
  - Stripped gstack preamble blocks (`Preamble (run first)`, `Plan Mode Safe Operations`, `Skill Invocation During Plan Mode`, `Skill routing`, `AskUserQuestion Format`, `Artifacts Sync`, `Model-Specific Behavioral Patch`, `Voice`, `Context Recovery`, `Writing Style`, `Operational Self-Improvement`, `Completion Status Protocol`, `Telemetry`, `Plan Status Footer`, `Repo Ownership`, `Search Before Building`, `SETUP (browse)`) — these depend on the missing `~/.claude/skills/gstack/bin/gstack-*` toolchain and don't function in our environment.
  - Stripped trailing `GSTACK REVIEW REPORT` and `EXIT PLAN MODE GATE` sections (depend on gstack plan-mode infrastructure we don't run).
  - Stripped `triggers` and `voice-triggers` frontmatter lists to enforce milestone-only invocation (gs-canary keeps no triggers list but is explicitly tagged phase-level in its description).
  - Appended `(MILESTONE-LEVEL ONLY — do not invoke per-phase)` to each milestone-only skill's description. `gs-canary` instead appends `(PHASE-LEVEL — fires after every deploy, not milestone-only. Wired into ~/dev-management/scripts/verify-deploy.sh post-Tier-B pass; can also be invoked manually with /canary <url>.)`.
  - `gs-office-hours`: changed design doc save path from `~/.gstack/projects/{slug}/{user}-{branch}-design-{datetime}.md` to `.planning/decisions/YYYY-MM-DD-<topic>.md` (matches our GSD tree convention).
  - `gs-plan-design-review`: replaced the designer-binary `Step 0.5: Visual Mockups` section with a text-only `Variant Descriptions` stub. The 7 rated dimensions and AI Slop blacklist are preserved.
  - `gs-canary`: replaced gstack browse-binary resolution (`$_ROOT/.claude/skills/gstack/browse/dist/browse` → `$HOME/.claude/skills/gstack/browse/dist/browse`) with the dev-stack resolution pattern: PATH → `~/.local/bin/browse` → `~/skills-stack/browse/dist/browse`. Matches `~/dev-management/scripts/verify-deploy.sh` canary block (lines 785-880). Changed report save path from `.gstack/canary-reports/` to `.canary-reports/` so the skill works outside gstack-managed projects. Stripped the upstream `Phase 1` `gstack-slug` invocation and the JSONL telemetry write in Phase 6 (both depend on missing gstack bin). Added an explicit "flag-only when invoked from verify-deploy.sh" rule so the model doesn't trigger auto-rollback for canary findings — Tier A/B failures keep their existing auto-rollback path.

## GSD v1 — TÂCHES (gsd-build)

- **Upstream:** https://github.com/gsd-build/get-shit-done
- **License:** MIT (see `licenses/gsd-LICENSE`)
- **Original author / copyright:** © Lex Christopherson / TÂCHES
- **Fork date:** 2026-05-18
- **Upstream commit SHA at fork:** `cb154569cf2c174567edde737bb41ec01e540f0f`
- **Source-of-record note:** GSD v1 is locally installed at `/root/.claude/get-shit-done/` (`skills/` for slash-command SKILL.md files; `workflows/` for invoked workflow bodies). The cherry-pick used those local paths as "upstream" rather than the public repo because the locally installed copy is the version we actually run. Per-file attribution headers point at the local paths; SHAs above are the upstream public-repo SHA the local install was built from.
- **Skills taken from this upstream:**
  - `skills/gsd-discuss-phase/SKILL.md` (from `/root/.claude/get-shit-done/skills/gsd-discuss-phase/SKILL.md`) + workflow bodies `workflows/{discuss-phase,discuss-phase-assumptions,discuss-phase-power}.md`
  - `skills/gsd-plan-phase/SKILL.md` (from `/root/.claude/get-shit-done/skills/gsd-plan-phase/SKILL.md`) + workflow body `workflows/plan-phase.md`
  - `skills/gsd-quick/SKILL.md` (from `/root/.claude/get-shit-done/skills/gsd-quick/SKILL.md`) + workflow body `workflows/quick.md`
  - `skills/gsd-execute-phase/SKILL.md` (from `/root/.claude/get-shit-done/skills/gsd-execute-phase/SKILL.md`) + workflow bodies `workflows/{execute-phase,execute-plan,transition,node-repair}.md`
  - `skills/gsd-code-review/SKILL.md` (from `/root/.claude/get-shit-done/skills/gsd-code-review/SKILL.md`) + workflow body `workflows/code-review.md`
  - `skills/gsd-code-review-fix/SKILL.md` (from `/root/.claude/get-shit-done/skills/gsd-code-review-fix/SKILL.md`) + workflow body `workflows/code-review-fix.md`
  - `skills/gsd-verify-work/SKILL.md` (from `/root/.claude/get-shit-done/skills/gsd-verify-work/SKILL.md`) + workflow bodies `workflows/{verify-work,diagnose-issues,transition}.md`
  - `skills/gsd-ship/SKILL.md` (from `/root/.claude/get-shit-done/skills/gsd-ship/SKILL.md`) + workflow body `workflows/ship.md`
  - `skills/gsd-debug/SKILL.md` (from `/root/.claude/get-shit-done/skills/gsd-debug/SKILL.md`) + workflow body `workflows/diagnose-issues.md` — **slash command renamed to `/gsd-diagnose-issues`** via `name:` frontmatter rewrite. Directory name kept as `gsd-debug/` (matches upstream package name → drift-detection-friendly).
- **Modifications:**
  - `gsd-discuss-phase`: verbatim copy; added attribution header on SKILL.md only (workflow bodies copied verbatim, no header).
  - `gsd-plan-phase`: verbatim copy; added attribution header on SKILL.md only.
  - `gsd-quick`: verbatim copy; added attribution header on SKILL.md only.
  - `gsd-execute-phase`: verbatim copy; added attribution header on SKILL.md only. Bundled cross-referenced workflows (`execute-plan.md`, `transition.md`, `node-repair.md`) alongside the main `execute-phase.md` to keep the skill self-contained.
  - `gsd-code-review`: verbatim copy; added attribution header on SKILL.md only.
  - `gsd-code-review-fix`: verbatim copy; added attribution header on SKILL.md only.
  - `gsd-verify-work`: verbatim copy; added attribution header on SKILL.md only. Bundled cross-referenced `diagnose-issues.md` (verify→diagnose handoff) and `transition.md` workflows alongside the main `verify-work.md`. Note: `diagnose-issues.md` is also bundled under `skills/gsd-debug/` (where it's the primary workflow body) — duplicated by design so each skill is self-contained.
  - `gsd-ship`: verbatim copy; added attribution header on SKILL.md only.
  - `gsd-debug` (slash command `/gsd-diagnose-issues`): added attribution header. Updated `name:` frontmatter from `gsd-debug` to `gsd-diagnose-issues` so the slash command reflects the actual workflow scope (UAT-gap diagnosis, not general debugging). Updated `description:` to clarify scope and point at `sp-systematic-debugging` for general debugging. Added a `> Note on scope.` paragraph at the top of the SKILL.md body explaining the rename. Workflow body (`diagnose-issues.md`) copied verbatim. Directory name kept as `gsd-debug/` to match upstream package — drift detection compares against the upstream `gsd-debug/SKILL.md` path.

## Superpowers — Jesse Vincent

- **Upstream:** https://github.com/obra/superpowers
- **License:** MIT (see `licenses/superpowers-LICENSE`)
- **Original author / copyright:** © Jesse Vincent
- **Fork date:** 2026-05-18
- **Upstream commit SHA at fork:** `f2cbfbefebbfef77321e4c9abc9e949826bea9d7`
- **Skills taken from this upstream:**
  - `skills/sp-brainstorming/SKILL.md` (from upstream `skills/brainstorming/SKILL.md`)
  - `skills/sp-subagent-driven-development/SKILL.md` (from upstream `skills/subagent-driven-development/SKILL.md`) + prompt template deps `implementer-prompt.md`, `spec-reviewer-prompt.md`, `code-quality-reviewer-prompt.md`
  - `skills/sp-verification-before-completion/SKILL.md` (from upstream `skills/verification-before-completion/SKILL.md`)
  - `skills/sp-systematic-debugging/SKILL.md` (from upstream `skills/systematic-debugging/SKILL.md`) + sub-technique deps `root-cause-tracing.md`, `defense-in-depth.md`, `condition-based-waiting.md`
- **Modifications:**
  - `sp-brainstorming`: appended `(MILESTONE-LEVEL ONLY — do not invoke per-phase)` to description. Changed default save path from `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` to `.planning/specs/YYYY-MM-DD-<topic>.md` (matches our GSD tree convention).
  - `sp-subagent-driven-development`: added attribution header. **Inserted an `## Optionality: task-size-gated review tiers (fork modification)` section** before the `When to Use` block. It defines a small-task threshold (under ~50 lines AND under 3 files) below which the orchestrator skips the code-quality reviewer (single-tier review = spec-compliance only); larger or sensitive tasks still get the full two-tier upstream pattern. The orchestrator (`gsd-execute-phase` or human) reads task scope from the plan and picks the tier before dispatching the implementer. The spec-compliance reviewer always runs. Prompt template deps (`implementer-prompt.md`, `spec-reviewer-prompt.md`, `code-quality-reviewer-prompt.md`) copied verbatim alongside the SKILL.md.
  - `sp-verification-before-completion`: added attribution header. Added a `> **Invocation note (fork addition).**` block immediately under the H1 heading, before `## Overview` — clarifies the skill is invoked as a sub-skill by `gsd-execute-phase`, `sp-systematic-debugging`, and `gsd-code-review-fix`, not typically by users directly.
  - `sp-systematic-debugging`: added attribution header. Added a `> **Scope note (fork addition).**` block immediately under the H1 heading, before `## Overview` — clarifies this is the **general-purpose** debugger (fires from `gsd-execute-phase` unresolvable errors, `gsd-verify-work` AC fails, or direct user invocation for production crashes / middleware / integration failures) and is **distinct from `/gsd-diagnose-issues`** (which is UAT-gap-specific). Sub-technique dependency files (`root-cause-tracing.md`, `defense-in-depth.md`, `condition-based-waiting.md`) copied verbatim alongside the SKILL.md.
  - `sp-writing-plans` (Pass 3, **Woz-only**): cherry-picked from upstream `skills/writing-plans/SKILL.md`. Added attribution header. Added a `> **SCOPE: Woz-only.**` block immediately after frontmatter declaring the skill intended for agent-cto inline DEVMGMT work only — project-owner sessions should route to `/gsd-plan-phase` or `/gsd-quick` instead. Default save path changed from `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md` to `.planning/devmgmt-quicks/YYYY-MM-DD-<feature-name>.md` (the agent-cto inline DEVMGMT path). Description suffixed with `WOZ-ONLY` tag. Sub-workflow dependency `plan-document-reviewer-prompt.md` copied verbatim alongside the SKILL.md. Enforcement is via `install.sh` symlink scope: the default install skips this skill; only `install.sh --include-woz-only` symlinks it. Per `life/resources/fork-stack-locks-2026-05-18.md`: option (a) — keep upstream name, control via symlink scope.

## gstack/browse — Garry Tan (bundled binary source)

- **Upstream:** https://github.com/garrytan/gstack (the `browse/` subdirectory of the gstack monorepo)
- **License:** MIT (see `licenses/gstack-LICENSE` — same LICENSE covers both the gstack skills and the bundled browse binary source)
- **Original author / copyright:** © Garry Tan
- **Fork date:** 2026-05-18 (same as the gstack skill fork)
- **Upstream commit SHA at fork:** `e3c961d00f24334066b4caeb57634c012a346c00`
- **Component vendored:** the entire `browse/` directory — Bun+TypeScript source for the headless-browser daemon, plus tests, helper bin scripts, and the Node-server build script.
- **What was copied:**
  - `browse/src/*.ts` (30 source files: browser-manager, cdp-inspector, commands, audit, content-security, server, snapshot, tab-session, cookie-picker, etc.)
  - `browse/test/*.test.ts` (42 test files + `test/fixtures/`)
  - `browse/bin/{find-browse,remote-slug}` (existing helper scripts)
  - `browse/scripts/build-node-server.sh` (Node-compat server bundle build for Windows path)
  - `browse/SKILL.md.tmpl` + `browse/PLAN-snapshot-dropdown-interactive.md` (kept for parity with upstream)
- **What was excluded:**
  - `browse/dist/` — pre-built artefacts (~200MB compiled binaries). Regenerated by `install.sh build_browse()` into the same path. Added to repo-root `.gitignore`.
  - `browse/SKILL.md` (39KB) — gstack-internal generated artefact, not used by our fork.
- **Modifications:**
  - **Added `browse/package.json`** — minimal self-contained shape (`name: "dev-stack-browse"`, MIT). Includes the four runtime deps extracted from the parent monorepo's `package.json` (`@ngrok/ngrok`, `diff`, `playwright`, `puppeteer-core`) so `cd browse && bun install && bun run build` works standalone without the rest of the gstack monorepo. The `build` script invokes `bun --compile` for `src/cli.ts` and `src/find-browse.ts` plus the Node-server bundle build via the existing shell script.
  - **Added `browse/README.md`** — attribution header pointing at this file, build instructions, list of skills that depend on the binary.
  - All `.ts` source files, the helper scripts under `bin/`, the build script under `scripts/`, and the test files are **verbatim copies** of upstream — no per-file modifications. The component is intended to track upstream closely; if upstream changes the source structure, the fork should re-vendor rather than maintain divergent edits.
- **Skills that depend on this binary:**
  - `gs-canary` — post-deploy monitoring (`skills/gs-canary/SKILL.md`, landed in Pass 4 of the dev-stack build).
  - Future: `gs-qa` and `gs-benchmark` would depend on it too if ever added — both were dropped from the dev-stack cherry-pick (`gs-benchmark` explicitly dropped per `life/resources/fork-stack-locks-2026-05-18.md`; `gs-qa` not in the locked skill list as of 2026-05-18).
