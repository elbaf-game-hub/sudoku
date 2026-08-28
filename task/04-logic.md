# 04 — Logic

> The engine lives in `lib/src/sudoku_state.dart`. **No imports of
> `package:flutter/*` allowed in this file.** The page imports the
> state, not the other way around.

## Class diagram

```
sudoku_state.dart (pure Dart)
  └── classes listed below
sudoku_page.dart (Flutter)
  └── owns the State subclass that wraps sudoku_state
```

## Classes

### `Difficulty`

enum { easy, medium, hard, expert }

### `SudokuStatus`

enum { playing, won, lost }

### `Cell`

int? value, bool isGiven, Set<int> pencilmarks, bool hasError

### `SudokuBoard`

List<List<Cell>> grid (9x9), Difficulty difficulty. Methods: setValue(int row, int col, int v), clearValue, togglePencilmark(int row, int col, int v), isComplete(), isValid().

### `SudokuGenerator`

SudokuBoard generate(Difficulty d) — fills a valid board then removes cells while ensuring unique solution. Difficulty = givens count.

### `SudokuSolver`

List<SudokuBoard> solve(SudokuBoard). Backtracking with constraint propagation. Returns empty list if unsolvable.

### `HintEngine`

({int row, int col, int value})? getHint(SudokuBoard) — returns the first cell with a unique candidate.

## Hard rules

1. **No `Widget` or `BuildContext` references** in the state file.
   If a UI helper is needed, put it in `*_page.dart`.
2. **No `import 'package:flutter/...'`** in the state file.
   Use only `dart:core`, `dart:math`, `dart:collection`.
3. **Constructor takes everything it needs** — no global state.
   The page passes initial values and listens via `Stream` or
   `Listenable` if needed.
4. **Methods return new state, not mutate** when possible. For
   performance-critical loops (e.g. 2048 slide), in-place mutation
   is OK as long as the previous state is captured for undo.
5. **Seedable RNG** for any shuffle/random. Use `Random(seed)` so
   tests can be deterministic.

## Integration with the page

```dart
class SudokuPage extends StatefulWidget {{
  const SudokuPage({{super.key}});
  @override
  State<SudokuPage> createState() => _SudokuPageState();
}}

class _SudokuPageState extends State<SudokuPage> {{
  late SudokuState _state;

  @override
  void initState() {{
    super.initState();
    _state = SudokuState.initial();
  }}

  void _onAction(...) {{
    setState(() {{
      _state = _state.copyWith(...);
    }});
    SfxPlayer.instance.play('tap');
  }}

  @override
  Widget build(BuildContext context) => /* see 05-ui.md */;
}}
```
