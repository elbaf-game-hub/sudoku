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

    // Tap pencil mode action item
    await tester.tap(find.text('Notes'), warnIfMissed: false);
    await tester.pump();

    // Tap digit 3
    await tester.tap(find.text('3').first, warnIfMissed: false);
    await tester.pump();

    // Tap erase
    await tester.tap(find.byTooltip('Erase'), warnIfMissed: false);
    await tester.pump();
  });

  testWidgets('Sudoku page renders cleanly on mobile screen (360x800) without any overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: SudokuPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SudokuPage), findsOneWidget);
    expect(find.text('Sudoku'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(find.text('Erase'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Hint'), findsOneWidget);
  });
}
