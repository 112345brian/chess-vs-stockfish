# Chess vs. Stockfish

Play chess against Stockfish entirely in your browser — no server, no
account, no network calls once the page loads. A single static HTML page
that bundles chess.js (rules/state), an old single-threaded Stockfish
build running in a Web Worker, and an offline opening-name database.

**Play it live:** https://112345brian.github.io/chess-vs-stockfish/

- Adjustable opponent: adaptive (targets ~100 Elo above your estimated
  rating, adjusting after each finished game) or a fixed strength from
  Beginner (~800) to Full strength (~2600+)
- Progress autosaves to your browser's local storage — reopen the page to
  resume, or add `?new=1` to force a fresh game
- Opening recognition against ~3,800 named lines (offline, no lookup)
- Copy PGN, or copy a ready-made "look this position up" prompt to paste
  into a chat with Claude for real master-game stats and engine-checked
  best replies (see below)

## Why a single-threaded, ~2019-era Stockfish build

Modern multi-threaded Stockfish WASM builds need `SharedArrayBuffer`,
which requires COOP/COEP cross-origin-isolation headers — not something a
static page on GitHub Pages (or a sandboxed artifact) can set. The
single-threaded asm.js build has no such requirement and runs fine inside
a `Worker` created from a `Blob`, at the cost of being weaker/slower than
current Stockfish. See `build/fetch-deps.sh` for the pinned version.

## Repo layout

```
src/shell.html        Page template + all app logic (board rendering,
                       move handling, adaptive rating, opening lookup)
build/fetch-deps.sh    Downloads pinned chess.js / stockfish.js / opening
                       data from their upstream sources
build/build.py         Splices those into src/shell.html -> dist/index.html
setup/install-macos.sh Sets up the *separate* local chess-mcp MCP server
                       (Stockfish tool access for Claude Code in chat —
                       not used by the browser game itself)
raycast/chess.sh       Raycast Script Command: launch the game with a
                       Resume/New Game prompt
.github/workflows/     Builds and deploys dist/ to GitHub Pages on push
```

## Building it yourself

```bash
bash build/fetch-deps.sh
python3 build/build.py
open dist/index.html
```

Nothing is committed pre-built — every push to `main` re-fetches the
pinned dependencies and rebuilds via GitHub Actions, then deploys to
Pages.

## The separate chat-analysis setup

The browser game is fully self-contained and needs none of this. But if
you use [Claude Code](https://claude.com/claude-code) and want to paste a
PGN or a position (via the game's "Look up in chat" button) for real
master-database stats and engine-verified analysis, `setup/install.sh`
installs a local `chess-mcp` MCP server (a *different*, native Stockfish
setup) and registers it with Claude Code:

```bash
bash setup/install.sh
```

It detects your OS and runs the matching script:

| Platform | Script | Requires |
|---|---|---|
| macOS | `install-macos.sh` | Homebrew, [nvm](https://github.com/nvm-sh/nvm), `claude` CLI |
| Linux (Debian/Ubuntu) | `install-linux.sh` | apt, sudo, [nvm](https://github.com/nvm-sh/nvm), `claude` CLI |
| Windows | — | Use WSL2 (Ubuntu) and run `install.sh` inside it |

Native Windows isn't supported directly — `chess-mcp`'s `canvas` dependency
needs a full Cairo/Pango/GTK build toolchain that's painful outside
Linux/macOS, so WSL2 is the path there. This is all more involved than a
plain `npm install -g chess-mcp` because that package's `canvas` dependency
doesn't build against modern Node — see the comments in the scripts.

## Raycast (macOS only)

[Raycast](https://raycast.com) is macOS-only. Add `raycast/` (or wherever
you clone this repo) as a Script Commands directory in Raycast's settings,
then run "Chess" — it prompts Resume or New Game and opens the live URL
above. On other platforms, just bookmark the URL directly.

## Releasing

Changes get a one-file fragment in `changelog.d/` in the same commit that
makes them; releases compile pending fragments into `CHANGELOG.md`, then
bump `VERSION` and tag. See [changelog.d/README.md](./changelog.d/README.md)
for the full recipe — short version:

```bash
python3 scripts/build_changelog.py --version X.Y.Z --write
git add CHANGELOG.md changelog.d/ && git commit -m "Update changelog for vX.Y.Z"
bash scripts/bump_version.sh X.Y.Z
git push origin main --tags
```

## Licensing

This repository bundles a GPLv3-licensed Stockfish build, so the whole
repo is distributed under GPLv3. See [LICENSE](./LICENSE) and
[THIRD_PARTY_LICENSES.md](./THIRD_PARTY_LICENSES.md) for the full
breakdown (chess.js is BSD-2-Clause, the opening data is CC0).
