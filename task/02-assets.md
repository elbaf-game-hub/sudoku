# 02 — Assets

All assets come from `package:game_assets`. The module declares a
path-dependency on it in `pubspec.yaml`. The wrapper's `game_assets`
package owns the actual files.

## Source of truth

- **Declarative YAML**: `game_hub_core/game_assets/tool/definitions/sudoku.yaml`
- **Procedural Python**: `game_hub_core/game_assets/tool/generate_tiles.py`
- **Regenerate**:
  ```bash
  cd game_hub_core/game_assets
  python3 tool/generate_svgs.py
  python3 tool/generate_tiles.py
  ```

## Core SVG assets

These are the visual primitives the page must reference. The table
maps each to a file under `game_assets/assets/svg/sudoku/`.

| File | Size | Purpose |
| --- | --- | --- |
| `digit_1.svg … digit_9.svg` | 48x48 each | Numbered digits 1–9 |
| `cell_empty.svg` | 48x48 | Empty editable cell |
| `cell_given.svg` | 48x48 | Cell with a puzzle-given number (slightly darker bg) |
| `cell_selected.svg` | 48x48 | Currently selected cell (yellow tint) |
| `cell_highlight.svg` | 48x48 | Same row/col/box highlight (light blue) |
| `cell_error.svg` | 48x48 | Conflict cell (red flash, 600 ms) |

## Fonts

System default.

## Extra assets (bundled in this module)

- `assets/data/puzzles.json` — 50 hand-checked puzzles (10 per difficulty × 5 sets)

These ship inside this module (not in `game_assets`) because they're
specific to this game. Register them in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/data/
```

## How the page loads an asset

```dart
import 'package:flutter_svg/flutter_svg.dart';

SvgPicture.asset(
  'assets/svg/sudoku/<file>.svg',
  package: 'game_assets',
  width: 48,
)
```

## Asset budget

- **Hard cap**: total `assets/` in this module ≤ 200 KB
  (CI step in `game_hub_wrapper/.github/workflows/ci.yml`).
- This module's known usage: see sizes in the table above.
