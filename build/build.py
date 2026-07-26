#!/usr/bin/env python3
"""Assembles src/shell.html + build/vendor/* into a single self-contained
dist/index.html — a static page with no build step required to run it,
just to produce it.
"""
import csv
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VENDOR = ROOT / "build" / "vendor"
DIST = ROOT / "dist"


def load_openings():
    rows = []
    for letter in "abcde":
        path = VENDOR / f"openings_{letter}.tsv"
        with path.open(newline="", encoding="utf-8") as f:
            reader = csv.DictReader(f, delimiter="\t")
            for row in reader:
                moves = re.sub(r"\d+\.\s*", "", row["pgn"]).split()
                rows.append([row["eco"], row["name"], moves])
    return rows


def main():
    shell = (ROOT / "src" / "shell.html").read_text(encoding="utf-8")
    chessjs = (VENDOR / "chess.mjs").read_text(encoding="utf-8")
    stockfish = (VENDOR / "stockfish.js").read_text(encoding="utf-8")
    openings = json.dumps(load_openings(), ensure_ascii=False, separators=(",", ":"))

    # These get embedded inside <script type="text/plain">/<script type="application/json">
    # blocks, never executed as HTML, so only a literal "</script" sequence needs escaping.
    chessjs = chessjs.replace("</script", "<\\/script")
    stockfish = stockfish.replace("</script", "<\\/script")
    openings = openings.replace("</script", "<\\/script")

    out = (
        shell.replace("__CHESSJS_SOURCE__", chessjs)
        .replace("__STOCKFISH_SOURCE__", stockfish)
        .replace("__OPENINGS_SOURCE__", openings)
    )

    DIST.mkdir(exist_ok=True)
    out_path = DIST / "index.html"
    out_path.write_text(out, encoding="utf-8")
    print(f"Wrote {out_path} ({len(out):,} bytes)")


if __name__ == "__main__":
    main()
