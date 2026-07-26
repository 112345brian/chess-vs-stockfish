# Changelog fragments

This project has no package-manager-native changelog tool (no
`pyproject.toml`/`package.json`/`Cargo.toml`), so this is a small
hand-rolled equivalent of towncrier/Changesets: one fragment file per
change, written in the *same commit* as the change it describes, compiled
into `CHANGELOG.md` at release time.

## Adding a fragment

Create a file here named:

```
<slug>.<type>.md
```

- `<slug>`: a few hyphenated words describing the change (no ticket number needed)
- `<type>`: one of `added`, `changed`, `fixed`, `removed`, `docs`

Example: `changelog.d/adaptive-difficulty.added.md` containing:

```
Adaptive difficulty mode that targets the engine ~100 Elo above your
estimated rating and adjusts after each finished game.
```

One or two plain-English sentences. Lead with *what* changed, not *why* —
reasoning belongs in the commit message. Write for someone reading the
changelog cold, not someone who was in this conversation.

One fragment per logical change — if a single commit bundles several
distinct changelog-worthy things, write one fragment per thing.

## Releasing

```bash
# 1. See what would be written (dry-run is the default):
python3 scripts/build_changelog.py --version X.Y.Z

# 2. Actually write it (compiles fragments into CHANGELOG.md, deletes them):
python3 scripts/build_changelog.py --version X.Y.Z --write
git add CHANGELOG.md changelog.d/
git commit -m "Update changelog for vX.Y.Z"

# 3. Bump the version and tag, in a separate commit:
bash scripts/bump_version.sh X.Y.Z
git push origin main --tags
```

See `../README.md`'s "Releasing" section for the short version, and
`scripts/build_changelog.py` / `scripts/bump_version.sh` for exactly what
each step checks.
