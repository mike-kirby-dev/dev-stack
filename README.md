Mike's curated skills stack — cherry-picked from gstack, GSD v1, Superpowers.

Built 2026-05-18. See ATTRIBUTIONS.md.

This repo is a curated, modified subset of three upstream Claude Code skill packages. Skills are forked rather than vendored so we can trim preambles, lock invocation scopes, and integrate with our portfolio's `.planning/` tree and Plane sync hooks.

## Quick start

```bash
git clone git@github.com:mike-kirby-dev/dev-stack.git ~/skills-stack
cd ~/skills-stack
bash install.sh
```

`install.sh` symlinks `skills/*/` into `~/.claude/skills/`. Already-symlinked skills are skipped (idempotent). Conflicting non-symlink entries cause an abort with a useful error.

## Updates

```bash
cd ~/skills-stack && git pull
```

Symlinks auto-resolve to the new files. No re-install needed.

## Drift watcher

`scripts/weekly-drift.sh` reports upstream changes against the SHAs forked at build time. Wire into cron for weekly runs:

```cron
0 4 * * 0 bash /root/skills-stack/scripts/weekly-drift.sh
```

Posts a Markdown delta report to Mike's DM via `notify-mike.sh`. Never auto-applies.

## License

MIT. See `LICENSE` and `ATTRIBUTIONS.md` for upstream attributions.
