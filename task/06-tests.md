# 06 — Tests

Two test files: `test/sudoku_state_test.dart` (engine) and
`test/sudoku_widget_test.dart` (page).

## Engine tests (state)

> Target: ≥90% line coverage on `lib/src/sudoku_state.dart`.

1. Generator: produces a 9x9 board with the requested number of givens (test 100x per difficulty)
2. Generator: every produced puzzle is solvable
3. Generator: every produced puzzle has a unique solution (assert Solver returns exactly 1 result)
4. Solver: returns 1 result for any well-formed puzzle
5. Solver: returns empty list for an unsolvable board (e.g. two cells with the same givens)
6. isValid: detects row, column, and 3x3 box conflicts
7. isComplete: true when all 81 cells are non-null and isValid is true
8. setValue: editable cells accept input, given cells reject input
9. togglePencilmark: add/remove digit in cell's pencilmark set
10. Hint: returns a cell with a unique candidate
11. Pencilmarks are cleared when a value is set
12. Mistake mode: 3rd conflict sets status = lost
13. Widget test: 9x9 board renders 81 cells

## Widget tests (page)

A minimal smoke test that the page renders and the primary
interaction works:

```dart
// test/sudoku_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/sudoku.dart';

void main() {
  testWidgets('Sudoku page renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SudokuPage()));
    expect(find.byType(SudokuPage), findsOneWidget);
  });
}
```

## Coverage bar

```bash
cd game_hub_modules/sudoku
flutter test --coverage
# open coverage/lcov-report.html
```

Required: lines covered on `lib/src/sudoku_state.dart` ≥ 90%.
The CI step in the wrapper fails the build otherwise.

## What NOT to test

- Pure widget rendering details (e.g. "the title is centered").
- SFX firing (you'd have to mock `audioplayers`; not worth it).
- The `GameModule` descriptor — it's a static const.

## How to run a single test

```bash
flutter test test/sudoku_state_test.dart --plain-name "tap places"
```
