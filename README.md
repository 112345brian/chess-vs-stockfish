# Chess vs. Stockfish

Play chess against Stockfish entirely in your browser — no server, no
account. A static page that bundles chess.js (rules/state), two Stockfish
builds running in Web Workers (one for live play, one for analysis — see
below), and an offline opening-name database.

**Play it live:** https://112345brian.github.io/chess-vs-stockfish/

- Play White, Black, or a random side each game
- Adjustable opponent: adaptive (targets ~100 Elo above your estimated
  rating, with a provisional K-factor that swings fast for your first ~30
  games and settles down after) or a fixed strength from Beginner (~800) to
  Full strength (~2600+)
- A six-puzzle calibration quiz sets a much better starting rating than a
  cold 1200 guess, by fitting your pass/fail pattern across a spread of
  puzzle difficulties to an Elo estimate
- Progress autosaves to your browser's local storage — reopen the page to
  resume, or add `?new=1` to force a fresh game
- Opening recognition against ~3,800 named lines, with hand-written
  background for the ~130 most common families (offline, no lookup)
- Known-trap detection (Scholar's Mate, Fried Liver, Légal's Trap, and 21
  others) — a callout when you're about to walk into one or just did
- Post-game move-quality analysis (best/good/inaccuracy/mistake/blunder,
  ACPL) via a background re-evaluation with a much stronger, lazily-loaded
  engine (see below); a game-history panel with a rating chart, most-played
  openings, and recent-games list; click-through review mode with
  arrow-key navigation and mistake-jumping
- Drill mode: practice positions pulled from your own logged mistakes, the
  trap library, or a 540-puzzle set from the public Lichess database — find
  the best move, graded live, no effect on your rating or history
- Copy PGN, or copy a ready-made "look this position up" prompt to paste
  into a chat with Claude for real master-game stats and engine-checked
  best replies (see below)

## Two engines, not one

Live play and analysis want opposite things — live play wants instant
startup and doesn't need real strength (Skill Level already deliberately
weakens it to match your rating), while analysis needs to be genuinely
trustworthy or its blunder/mistake tags are just noise. So there are two
separate engines, both single-threaded (modern multi-threaded Stockfish
WASM needs `SharedArrayBuffer`, which needs COOP/COEP headers — not
something a static page on GitHub Pages, or a sandboxed artifact, can set):

- **Live play**: an old (~2019), small, classical-eval build, loaded
  eagerly at boot. Fast and tiny; its low ceiling doesn't matter since
  Skill Level caps it anyway.
- **Analysis** (post-game, drill mode, calibration): Stockfish 18, NNUE,
  single-threaded "lite" build — genuinely strong, not just "given more
  time." **Lazy-loaded**: nothing is fetched until analysis/drill/
  calibration actually runs, since most sessions are just live play. Its
  ~7MB `.wasm` binary ships as a sibling file next to `index.html` rather
  than base64-inlined, both to avoid the size bloat that would cause and
  so the browser can cache it independently across visits.

See `build/fetch-deps.sh` for both pinned versions.

## Repo layout

```
src/shell.html         Page template + all app logic (board rendering,
                        move handling, adaptive rating, opening lookup,
                        drill mode, calibration quiz)
build/fetch-deps.sh     Downloads pinned chess.js / stockfish.js / opening
                        data from their upstream sources
build/opening_info.json This project's own opening-background write-ups
build/traps.json        This project's own curated, verified trap dataset
build/puzzles.json      A committed, filtered subset of the Lichess puzzle
                        database (CC0) — see THIRD_PARTY_LICENSES.md
build/build.py          Splices all of the above into src/shell.html ->
                        dist/index.html
setup/install-macos.sh  Sets up the *separate* local chess-mcp MCP server
                        (Stockfish tool access for Claude Code in chat —
                        not used by the browser game itself)
raycast/chess.sh        Raycast Script Command: launch the game with a
                        Resume/New Game prompt
.github/workflows/      Builds and deploys dist/ to GitHub Pages on push
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
