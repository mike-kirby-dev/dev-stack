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
- **Modifications:**
  - Stripped gstack preamble blocks (`Preamble (run first)`, `Plan Mode Safe Operations`, `Skill Invocation During Plan Mode`, `Skill routing`, `AskUserQuestion Format`, `Artifacts Sync`, `Model-Specific Behavioral Patch`, `Voice`, `Context Recovery`, `Writing Style`, `Operational Self-Improvement`, `Completion Status Protocol`, `Telemetry`, `Plan Status Footer`, `Repo Ownership`, `Search Before Building`, `SETUP (browse)`) — these depend on the missing `~/.claude/skills/gstack/bin/gstack-*` toolchain and don't function in our environment.
  - Stripped trailing `GSTACK REVIEW REPORT` and `EXIT PLAN MODE GATE` sections (depend on gstack plan-mode infrastructure we don't run).
  - Stripped `triggers` and `voice-triggers` frontmatter lists to enforce milestone-only invocation.
  - Appended `(MILESTONE-LEVEL ONLY — do not invoke per-phase)` to each skill's description.
  - `gs-office-hours`: changed design doc save path from `~/.gstack/projects/{slug}/{user}-{branch}-design-{datetime}.md` to `.planning/decisions/YYYY-MM-DD-<topic>.md` (matches our GSD tree convention).
  - `gs-plan-design-review`: replaced the designer-binary `Step 0.5: Visual Mockups` section with a text-only `Variant Descriptions` stub. The 7 rated dimensions and AI Slop blacklist are preserved.

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
- **Modifications:**
  - `gsd-discuss-phase`: verbatim copy; added attribution header on SKILL.md only (workflow bodies copied verbatim, no header).
  - `gsd-plan-phase`: verbatim copy; added attribution header on SKILL.md only.
  - `gsd-quick`: verbatim copy; added attribution header on SKILL.md only.

## Superpowers — Jesse Vincent

- **Upstream:** https://github.com/obra/superpowers
- **License:** MIT (see `licenses/superpowers-LICENSE`)
- **Original author / copyright:** © Jesse Vincent
- **Fork date:** 2026-05-18
- **Upstream commit SHA at fork:** `f2cbfbefebbfef77321e4c9abc9e949826bea9d7`
- **Skills taken from this upstream:**
  - `skills/sp-brainstorming/SKILL.md` (from upstream `skills/brainstorming/SKILL.md`)
- **Modifications:**
  - Appended `(MILESTONE-LEVEL ONLY — do not invoke per-phase)` to description.
  - Changed default save path from `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` to `.planning/specs/YYYY-MM-DD-<topic>.md` (matches our GSD tree convention).
