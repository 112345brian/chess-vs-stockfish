#!/usr/bin/env bash
# Single entry point: detects your OS and runs the matching setup script
# for the optional chess-mcp chat-analysis integration.
#
# The browser game itself needs none of this — it's a static page that
# runs on any OS/browser. This only matters if you want Claude Code to
# have live Stockfish/masters-database tool access in chat.
set -euo pipefail
cd "$(dirname "$0")"

case "$(uname -s)" in
  Darwin)
    exec bash install-macos.sh
    ;;
  Linux)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      echo "Detected WSL — running the Linux (apt-based) setup."
    fi
    exec bash install-linux.sh
    ;;
  *)
    echo "Unsupported platform: $(uname -s)."
    echo
    echo "On native Windows, chess-mcp's canvas dependency needs a full"
    echo "GTK/Cairo/Pango build toolchain that's painful to set up outside"
    echo "Linux. Use WSL2 (Ubuntu) instead, then re-run this script inside"
    echo "it — it will detect WSL and run the Linux setup."
    echo
    echo "Remember: the browser game itself works fine on Windows already,"
    echo "in any browser, with no setup at all. This step is only for the"
    echo "optional Claude Code chat-analysis integration."
    exit 1
    ;;
esac
