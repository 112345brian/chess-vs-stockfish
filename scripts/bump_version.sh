#!/usr/bin/env bash
# Bumps VERSION, commits, and creates an annotated git tag. Run this *after*
# scripts/build_changelog.py has already been run, committed, and pushed —
# these stay two separate commits on purpose (see changelog.d/README.md).
#
# Usage: bash scripts/bump_version.sh X.Y.Z
set -euo pipefail
cd "$(dirname "$0")/.."

TARGET_VERSION="${1:-}"
if [ -z "${TARGET_VERSION}" ]; then
  echo "Usage: bash scripts/bump_version.sh X.Y.Z" >&2
  exit 1
fi
if ! [[ "${TARGET_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must look like X.Y.Z (no leading v), got: ${TARGET_VERSION}" >&2
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "Working tree is dirty — commit or stash first. Refusing to bump on an unclean tree." >&2
  git status --short >&2
  exit 1
fi

if [ -f CHANGELOG.md ]; then
  TOP_VERSION="$(grep -m1 -oE '^## v[0-9]+\.[0-9]+\.[0-9]+' CHANGELOG.md | sed 's/^## v//')"
  if [ "${TOP_VERSION}" != "${TARGET_VERSION}" ]; then
    echo "CHANGELOG.md's top entry is v${TOP_VERSION:-<none>}, not v${TARGET_VERSION}." >&2
    echo "Run scripts/build_changelog.py --version ${TARGET_VERSION} --write and commit it first." >&2
    exit 1
  fi
fi

LAST_TAG="$(git tag -l 'v*' --sort=-v:refname | head -1)"
if [ "${LAST_TAG}" = "v${TARGET_VERSION}" ]; then
  echo "v${TARGET_VERSION} is already tagged." >&2
  exit 1
fi

echo "${TARGET_VERSION}" > VERSION
git add VERSION
git commit -q -m "Bump version to ${TARGET_VERSION}"
git tag -a "v${TARGET_VERSION}" -m "Release v${TARGET_VERSION}"

echo "Bumped to v${TARGET_VERSION} and tagged. Push with:"
echo "  git push origin main --tags"
