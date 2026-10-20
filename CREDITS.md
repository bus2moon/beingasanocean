# Credits and third-party assets

**Rule: only assets that are 100% free to use, change and sell, forever.** (D-009)

| Allowed | Not allowed |
|---|---|
| CC0 / public domain, MIT, Unlicense, BSD, zlib, Apache-2.0, CC-BY (credit only) | NC (non-commercial), ND (no derivatives), SA / GPL / LGPL (force their licence onto our game), "free for personal use", Mixamo or other platform-terms assets (can't sit in a public repo), paid packs re-uploaded for free, anything with an unknown licence |

Every folder under `assets/` with third-party files needs a `LICENSE.txt` and a row below. `tools/check_licenses.py` enforces this, and `tools/run_tests.sh` runs it.

| Asset | Author | Licence | Source | Used for |
|---|---|---|---|---|
| Universal Animation Library (Standard): mannequin plus 46 clips | Quaternius | CC0 1.0 | [Godot Asset Store](https://store.godotengine.org/asset/quaternius/universal-animation-library/) | Placeholder Cub and locomotion animations (`assets/characters/ual_mannequin/`) |
