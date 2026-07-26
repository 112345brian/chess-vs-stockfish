#!/usr/bin/env python3
"""Compiles changelog.d/ fragments into a dated CHANGELOG.md section.

Hand-rolled equivalent of towncrier, since this repo has no
pyproject.toml/package.json/Cargo.toml to hang a real changelog tool off
of. See changelog.d/README.md for the fragment naming convention.

Defaults to a dry run (prints what it would write). Pass --write to
actually update CHANGELOG.md and delete the consumed fragments.
"""
import argparse
import datetime
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FRAGMENTS_DIR = ROOT / "changelog.d"
CHANGELOG = ROOT / "CHANGELOG.md"
MARKER = "<!-- changelog-fragments -->"

# type -> section heading, in the order sections should appear
TYPE_HEADINGS = {
    "added": "Added",
    "changed": "Changed",
    "fixed": "Fixed",
    "removed": "Removed",
    "docs": "Docs",
}

FRAGMENT_RE = re.compile(r"^(?P<slug>.+)\.(?P<type>[a-z]+)\.md$")


def collect_fragments():
    by_type = {}
    unmatched = []
    for path in sorted(FRAGMENTS_DIR.glob("*.md")):
        if path.name == "README.md":
            continue
        m = FRAGMENT_RE.match(path.name)
        if not m or m.group("type") not in TYPE_HEADINGS:
            unmatched.append(path)
            continue
        by_type.setdefault(m.group("type"), []).append(path)
    return by_type, unmatched


def build_section(version, by_type, date):
    lines = [f"## v{version} — {date.isoformat()}", ""]
    for type_key, heading in TYPE_HEADINGS.items():
        paths = by_type.get(type_key)
        if not paths:
            continue
        lines.append(f"### {heading}")
        lines.append("")
        for path in paths:
            text = path.read_text(encoding="utf-8").strip()
            # Fold multi-line fragments into one bullet, indenting continuation lines.
            fragment_lines = text.splitlines()
            lines.append(f"- {fragment_lines[0]}")
            for cont in fragment_lines[1:]:
                lines.append(f"  {cont}")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True, help="Version being released, e.g. 0.2.0 (no leading v)")
    parser.add_argument("--write", action="store_true", help="Actually write CHANGELOG.md and delete fragments (default: dry run)")
    args = parser.parse_args()

    by_type, unmatched = collect_fragments()
    if unmatched:
        print("Fragments with unrecognized names (skipped):", file=sys.stderr)
        for p in unmatched:
            print(f"  {p.relative_to(ROOT)}", file=sys.stderr)

    all_fragments = [p for paths in by_type.values() for p in paths]
    if not all_fragments:
        print("No pending fragments in changelog.d/ — nothing to release.", file=sys.stderr)
        sys.exit(1)

    section = build_section(args.version, by_type, datetime.date.today())

    if not args.write:
        print("--- DRY RUN: would write this section, then delete the fragments below ---\n")
        print(section)
        print("--- fragments that would be deleted ---")
        for p in all_fragments:
            print(f"  {p.relative_to(ROOT)}")
        return

    changelog_text = CHANGELOG.read_text(encoding="utf-8")
    if MARKER not in changelog_text:
        print(f"Marker {MARKER!r} not found in {CHANGELOG} — refusing to guess where to insert.", file=sys.stderr)
        sys.exit(1)

    new_text = changelog_text.replace(MARKER, f"{MARKER}\n\n{section}", 1)
    CHANGELOG.write_text(new_text, encoding="utf-8")

    for p in all_fragments:
        p.unlink()

    print(f"Wrote v{args.version} section to {CHANGELOG.relative_to(ROOT)} and removed {len(all_fragments)} fragment(s).")


if __name__ == "__main__":
    main()
