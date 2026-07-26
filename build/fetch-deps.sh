#!/usr/bin/env bash
# Fetches pinned third-party sources used to assemble the single-file game.
# Nothing here is committed to the repo — this script is the reproducible
# record of exactly which upstream versions/commits are used.
set -euo pipefail

CHESSJS_VERSION="1.4.0"
STOCKFISHJS_VERSION="10.0.2"
OPENINGS_COMMIT="51b886249b9e418498d25b6e39b926c3de99c29a"
SF18_RELEASE_TAG="v18.0.0"

cd "$(dirname "$0")"
mkdir -p vendor
cd vendor

echo "Fetching chess.js@${CHESSJS_VERSION}..."
curl -sL -o chess.mjs "https://unpkg.com/chess.js@${CHESSJS_VERSION}/dist/esm/chess.js"

echo "Fetching stockfish.js@${STOCKFISHJS_VERSION} (asm.js, single-threaded, no wasm fetch) — used for live play only..."
curl -sL -o stockfish.js "https://unpkg.com/stockfish.js@${STOCKFISHJS_VERSION}/stockfish.js"

echo "Fetching Stockfish 18 lite-single (NNUE, single-threaded, no SharedArrayBuffer) — lazy-loaded for analysis/drill/calibration only..."
curl -sL -o stockfish-18-lite-single.js \
  "https://github.com/nmrugg/stockfish.js/releases/download/${SF18_RELEASE_TAG}/stockfish-18-lite-single.js"
curl -sL -o stockfish-18-lite-single.wasm \
  "https://github.com/nmrugg/stockfish.js/releases/download/${SF18_RELEASE_TAG}/stockfish-18-lite-single.wasm"

echo "Fetching lichess-org/chess-openings@${OPENINGS_COMMIT}..."
for f in a b c d e; do
  curl -sL -o "openings_${f}.tsv" \
    "https://raw.githubusercontent.com/lichess-org/chess-openings/${OPENINGS_COMMIT}/${f}.tsv"
done

echo "Done. Fetched into build/vendor/"
