#!/usr/bin/env bash
# Reproduces the local dev-environment setup for chess-mcp (the Claude Code
# MCP server that gives Claude live Stockfish analysis / masters-database
# lookups in chat — separate from the browser game, which bundles its own
# copy of Stockfish and needs none of this).
#
# Why this is more involved than `npm install -g chess-mcp`: chess-mcp
# depends on node-canvas for board rendering, which ships prebuilt binaries
# only for older Node ABIs and fails to compile from source against modern
# Node's V8 (a `GetIsolate` API removal breaks the build). The workaround is
# installing it under Node 20 via nvm, then wrapping the entry point so
# Claude Code always launches it with that Node version regardless of your
# shell's active one.
set -euo pipefail

NODE_VERSION="20"
WRAPPER_DIR="${HOME}/.local/bin"
WRAPPER_PATH="${WRAPPER_DIR}/chess-mcp-node20.sh"

echo "==> Installing Stockfish + canvas's native dependencies via Homebrew..."
brew install stockfish pango pkg-config

echo "==> Ensuring nvm is available..."
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ ! -s "${NVM_DIR}/nvm.sh" ]; then
  echo "nvm not found at ${NVM_DIR}. Install it first: https://github.com/nvm-sh/nvm"
  exit 1
fi
# shellcheck source=/dev/null
source "${NVM_DIR}/nvm.sh"

echo "==> Installing Node ${NODE_VERSION} (for chess-mcp's canvas dependency only)..."
nvm install "${NODE_VERSION}"
nvm use "${NODE_VERSION}"

echo "==> Installing chess-mcp under Node ${NODE_VERSION}..."
npm install -g chess-mcp

NODE20_BIN="$(nvm which "${NODE_VERSION}")"
CHESS_MCP_ENTRY="$(dirname "$(dirname "${NODE20_BIN}")")/lib/node_modules/chess-mcp/build/index.js"

if [ ! -f "${CHESS_MCP_ENTRY}" ]; then
  echo "Expected chess-mcp entry point not found at ${CHESS_MCP_ENTRY}"
  exit 1
fi

echo "==> Writing wrapper script to ${WRAPPER_PATH}..."
mkdir -p "${WRAPPER_DIR}"
cat > "${WRAPPER_PATH}" <<EOF
#!/bin/bash
exec "${NODE20_BIN}" "${CHESS_MCP_ENTRY}" "\$@"
EOF
chmod +x "${WRAPPER_PATH}"

echo "==> Registering with Claude Code (user scope)..."
if command -v claude >/dev/null 2>&1; then
  claude mcp remove chess -s user 2>/dev/null || true
  claude mcp add chess "${WRAPPER_PATH}" -s user
  echo "Registered. Restart Claude Code for the 'chess' MCP tools to load."
else
  echo "claude CLI not found — skipping MCP registration."
  echo "Once installed, run: claude mcp add chess ${WRAPPER_PATH} -s user"
fi

echo "==> Done."
