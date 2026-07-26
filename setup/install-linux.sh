#!/usr/bin/env bash
# Linux (Debian/Ubuntu apt-based) equivalent of install-macos.sh — sets up
# the optional chess-mcp MCP server that gives Claude live Stockfish
# analysis / masters-database lookups in chat. The browser game itself
# needs none of this; it's a static page that runs anywhere.
#
# Same underlying issue as macOS: chess-mcp depends on node-canvas, which
# has no prebuilt binary for modern Node ABIs and fails to compile against
# modern Node's V8 (a removed `GetIsolate` API). Fix: install under Node 20
# via nvm, then wrap the entry point to always launch with that version.
set -euo pipefail

NODE_VERSION="20"
WRAPPER_DIR="${HOME}/.local/bin"
WRAPPER_PATH="${WRAPPER_DIR}/chess-mcp-node20.sh"

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This script targets Debian/Ubuntu (apt-get not found)."
  echo "On other distros, install stockfish + libcairo2-dev + libpango1.0-dev"
  echo "+ pkg-config + build-essential via your package manager, then continue"
  echo "from the 'nvm' step below."
  exit 1
fi

echo "==> Installing Stockfish + canvas's native build dependencies via apt..."
sudo apt-get update
sudo apt-get install -y stockfish libcairo2-dev libpango1.0-dev libjpeg-dev \
  libgif-dev librsvg2-dev pkg-config build-essential

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
