#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Chess
# @raycast.mode silent

# Optional parameters:
# @raycast.icon ♟️
# @raycast.argument1 { "type": "dropdown", "placeholder": "Game", "data": [{"title": "Resume game", "value": "resume"}, {"title": "New game", "value": "new"}] }
# @raycast.packageName Chess

# Documentation:
# @raycast.description Open your chess-vs-Stockfish game, resuming or starting fresh
# @raycast.author bri

URL="https://112345brian.github.io/chess-vs-stockfish/"

if [ "$1" = "new" ]; then
  open "${URL}?new=1"
else
  open "$URL"
fi
