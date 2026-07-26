# Third-party components

This project's build fetches and embeds the following, all pinned to exact
versions/commits in `build/fetch-deps.sh`:

## Stockfish (via stockfish.js)

- Source: https://github.com/nmrugg/stockfish.js (npm package `stockfish.js@10.0.2`)
- License: **GNU GPL v3**
- Copyright T. Romstad, M. Costalba, J. Kiiski, G. Linscott and other
  Stockfish contributors. Multi-variant fork by Daniel Dugovic and
  contributors.
- This is why the repository as a whole is licensed under GPLv3 — see
  [LICENSE](./LICENSE).

## chess.js

- Source: https://github.com/jhlywa/chess.js (npm package `chess.js@1.4.0`)
- License: **BSD 2-Clause**
- Copyright (c) Jeff Hlywa

## lichess-org/chess-openings

- Source: https://github.com/lichess-org/chess-openings (commit `51b886249b9e418498d25b6e39b926c3de99c29a`)
- License: **CC0 1.0 Universal** (public domain dedication)
- Used as the offline opening-name/ECO lookup data.

None of these are committed to this repository — `build/fetch-deps.sh`
downloads them at build time from the sources above.
