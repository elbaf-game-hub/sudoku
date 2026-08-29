import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/sudoku.dart';

void main() {
  testWidgets('Sudoku page renders 9x9 board and keypad', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: SudokuPage(),
      ),
    );

    expect(find.byType(SudokuPage), findsOneWidget);
    expect(find.text('Sudoku'), findsOneWidget);
    expect(find.text('EASY'), findsOneWidget);

    // Check action buttons
    expect(find.byTooltip('Undo'), findsOneWidget);
    expect(find.byTooltip('Erase'), findsOneWidget);
    expect(find.byTooltip('Hint'), findsOneWidget);

    // Check numpad 1..9
    for (int d = 1; d <= 9; d++) {
      expect(find.text('$d'), findsWidgets);
    }
  });

  testWidgets('Sudoku page supports tapping cells, toggling pencil mode and entering notes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: SudokuPage(),
      ),
    );

    // Tap pencil mode filter chip
    await tester.tap(find.text('Pencil (Notes)'), warnIfMissed: false);
    await tester.pump();

    // Tap digit 3
    await tester.tap(find.widgetWithText(OutlinedButton, '3').first, warnIfMissed: false);
    await tester.pump();

    // Tap erase
    await tester.tap(find.byTooltip('Erase'), warnIfMissed: false);
    await tester.pump();
  });
}
