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

None of the above are committed to this repository — `build/fetch-deps.sh`
downloads them at build time from the sources above.

## Lichess puzzle database

- Source: https://database.lichess.org/ (mirrored via the
  [Lichess/chess-puzzles](https://huggingface.co/datasets/Lichess/chess-puzzles)
  Hugging Face dataset for the filtered subset actually used here)
- License: **CC0 1.0 Universal** (public domain dedication)
- `build/puzzles.json` is a curated, one-time-fetched subset (540 positions
  spanning six rating bands, 400–2800) used by drill mode's "Puzzles" source
  and the calibration quiz. Unlike the other fetched dependencies, this one
  **is** committed to the repository — it was pulled from a queryable REST
  API in a single filtering pass rather than a bulk file, so there's no
  simple pinned-URL re-fetch step; regenerating it means re-running that
  filtering process against the source above.

Build/build.py loads this and the two originally-authored files below
directly from the repository (they aren't fetched from anywhere):
`build/opening_info.json` (this project's own writing) and `build/traps.json`
(this project's own curated + independently-verified trap dataset).
