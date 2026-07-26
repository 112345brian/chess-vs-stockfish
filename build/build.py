#!/usr/bin/env python3
"""Assembles src/shell.html + build/vendor/* into dist/. index.html is
(nearly) self-contained — a static page with no build step required to run
it, just to produce it — except for the analysis engine's WASM binary,
which ships as a sibling file (dist/stockfish-18-lite-single.wasm) rather
than being base64-inlined: it's lazy-loaded only when analysis/drill/
calibration actually runs, so inlining it would bloat every page load for
a cost most visits never pay, and base64 adds ~33% size for no benefit
once it's a separate, browser-cacheable request anyway.
"""
import csv
import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VENDOR = ROOT / "build" / "vendor"
DIST = ROOT / "dist"
OPENING_INFO = ROOT / "build" / "opening_info.json"
TRAPS = ROOT / "build" / "traps.json"
PUZZLES = ROOT / "build" / "puzzles.json"


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
    analysis_engine = (VENDOR / "stockfish-18-lite-single.js").read_text(encoding="utf-8")
    openings = json.dumps(load_openings(), ensure_ascii=False, separators=(",", ":"))
    opening_info = json.dumps(
        json.loads(OPENING_INFO.read_text(encoding="utf-8")), ensure_ascii=False, separators=(",", ":")
    )
    if TRAPS.exists():
        traps = json.dumps(json.loads(TRAPS.read_text(encoding="utf-8")), ensure_ascii=False, separators=(",", ":"))
    else:
        print(f"Warning: {TRAPS} not found — building with an empty traps dataset.")
        traps = "[]"
    puzzles = json.dumps(
        json.loads(PUZZLES.read_text(encoding="utf-8")), ensure_ascii=False, separators=(",", ":")
    )

    # These get embedded inside <script type="text/plain">/<script type="application/json">
    # blocks, never executed as HTML, so only a literal "</script" sequence needs escaping.
    chessjs = chessjs.replace("</script", "<\\/script")
    stockfish = stockfish.replace("</script", "<\\/script")
    analysis_engine = analysis_engine.replace("</script", "<\\/script")
    openings = openings.replace("</script", "<\\/script")
    opening_info = opening_info.replace("</script", "<\\/script")
    traps = traps.replace("</script", "<\\/script")
    puzzles = puzzles.replace("</script", "<\\/script")

    out = (
        shell.replace("__CHESSJS_SOURCE__", chessjs)
        .replace("__STOCKFISH_SOURCE__", stockfish)
        .replace("__ANALYSIS_ENGINE_SOURCE__", analysis_engine)
        .replace("__OPENINGS_SOURCE__", openings)
        .replace("__OPENING_INFO_SOURCE__", opening_info)
        .replace("__TRAPS_SOURCE__", traps)
        .replace("__PUZZLES_SOURCE__", puzzles)
    )

    DIST.mkdir(exist_ok=True)
    out_path = DIST / "index.html"
    out_path.write_text(out, encoding="utf-8")
    print(f"Wrote {out_path} ({len(out):,} bytes)")

    wasm_out = DIST / "stockfish-18-lite-single.wasm"
    shutil.copyfile(VENDOR / "stockfish-18-lite-single.wasm", wasm_out)
    print(f"Copied {wasm_out} ({wasm_out.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()
