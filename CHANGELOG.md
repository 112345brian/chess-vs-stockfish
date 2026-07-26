# Changelog

All notable changes to this project are documented here. See
`changelog.d/README.md` for how entries get added.

<!-- changelog-fragments -->

## v0.1.0 — 2026-07-26

### Added

- Adaptive difficulty mode that targets the engine roughly 100 Elo above your estimated rating and adjusts after each finished game, plus a fixed-strength option from Beginner (~800) to Full strength (~2600+).
- A single-file browser chess game against Stockfish, running entirely client-side via a Web Worker — no server, no account.
- Cross-platform setup scripts (`setup/install.sh`) for the optional local chess-mcp chat-analysis integration, covering macOS and Linux, with a WSL2 pointer for Windows.
- Offline opening-name recognition against roughly 3,800 known lines, plus a "Look up in chat" button that copies the current position for deeper master-game analysis elsewhere.
- A reproducible build pipeline (`build/fetch-deps.sh` + `build/build.py`) that assembles the game from pinned upstream sources, and a GitHub Actions workflow that builds and deploys it to GitHub Pages on every push to main.

