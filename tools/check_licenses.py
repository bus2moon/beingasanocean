"""Fail if any third-party asset folder lacks a LICENSE.txt or a CREDITS.md row.

Folders listed in GENERATED are built by our own tools and need neither.
Run: python3 tools/check_licenses.py   (exit code 0 = OK)
"""

import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
GENERATED = {"assets/levels"}
BANNED = ("non-commercial", "noncommercial", "by-nc", "-nd", "sharealike", "share-alike", "by-sa", "gnu general public", "personal use only")


def main():
    credits = (ROOT / "CREDITS.md").read_text()
    problems = []
    for folder in sorted({p.parent for p in (ROOT / "assets").rglob("*") if p.is_file() and not p.name.endswith(".import")}):
        rel = folder.relative_to(ROOT).as_posix()
        if any(rel == g or rel.startswith(g + "/") for g in GENERATED):
            continue
        lic = folder / "LICENSE.txt"
        if not lic.exists():
            problems.append(f"{rel}: missing LICENSE.txt")
            continue
        text = lic.read_text(errors="ignore").lower()
        if any(b in text for b in BANNED):
            problems.append(f"{rel}: licence looks restricted (NC/ND/SA/GPL/personal use)")
        if rel not in credits:
            problems.append(f"{rel}: no row in CREDITS.md")
    for p in problems:
        print("LICENCE CHECK FAIL", p)
    print(f"licence check: {len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
