# browse

Headless browser daemon — Chromium over CDP, exposed as a long-lived local server with a thin CLI in front. Used by skills that need to inspect, screenshot, monitor, or interact with web pages.

Bundled from [gstack/browse](https://github.com/garrytan/gstack) (Garry Tan) under the MIT license. See [../ATTRIBUTIONS.md](../ATTRIBUTIONS.md) for fork details and upstream commit SHA.

## Build

```bash
cd browse
bun install
bun run build
```

Produces `browse/dist/browse` (compiled standalone binary). The repo's top-level `install.sh` calls this build step automatically and symlinks the resulting binary to `~/.local/bin/browse`.

## Dependencies

- [Bun](https://bun.sh) >= 1.0.0 (build + runtime)
- Playwright (installed via `bun install`) — bundles its own Chromium

## Skills that depend on this binary

- `gs-canary` — post-deploy monitoring (lands in Pass 4 of the dev-stack build)
- Future: `gs-qa`, `gs-benchmark` (not installed in dev-stack as of 2026-05-18, but would depend on `browse` if added later)
