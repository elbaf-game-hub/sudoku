import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/sudoku.dart';

void main() {
  group('Cell and Model Tests', () {
    test('CellPosition equality, hashCode and toString', () {
      const p1 = CellPosition(2, 3);
      const p2 = CellPosition(2, 3);
      const p3 = CellPosition(2, 4);
      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
      expect(p1.toString(), 'CellPosition(2, 3)');
    });

    test('SudokuHint equality, hashCode and toString', () {
      const h1 = SudokuHint(row: 1, col: 2, value: 3, reason: 'test');
      const h2 = SudokuHint(row: 1, col: 2, value: 3, reason: 'test');
      const h3 = SudokuHint(row: 1, col: 2, value: 4, reason: 'test');
      const h4 = SudokuHint(row: 1, col: 3, value: 3, reason: 'test');
      const h5 = SudokuHint(row: 2, col: 2, value: 3, reason: 'test');
      const h6 = SudokuHint(row: 1, col: 2, value: 3, reason: 'diff');
      expect(h1, equals(h2));
      expect(h1.hashCode, equals(h2.hashCode));
      expect(h1, isNot(equals(h3)));
      expect(h1, isNot(equals(h4)));
      expect(h1, isNot(equals(h5)));
      expect(h1, isNot(equals(h6)));
      expect(h1.toString(), contains('SudokuHint'));
    });

    test('Cell copyWith, equality, hashCode and toString', () {
      const c1 = Cell(value: 5, solutionValue: 5, isGiven: true, pencilmarks: {1, 2}, hasError: false);
      const c2 = Cell(value: 5, solutionValue: 5, isGiven: true, pencilmarks: {1, 2}, hasError: false);
      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1.toString(), contains('Cell(val: 5'));

      final c3 = c1.copyWith(
        value: 6,
        solutionValue: 6,
        isGiven: false,
        pencilmarks: {3, 4},
        hasError: true,
      );
      expect(c3.value, 6);
      expect(c3.solutionValue, 6);
      expect(c3.isGiven, isFalse);
      expect(c3.pencilmarks, {3, 4});
      expect(c3.hasError, isTrue);

      final c4 = c1.copyWith(clearValue: true);
      expect(c4.value, isNull);
    });
  });

  group('SudokuSolver and Backtracking Engine Tests', () {
    test('solves a standard valid puzzle with unique solution', () {
      final puzzle = [
        [5, 3, 0, 0, 7, 0, 0, 0, 0],
        [6, 0, 0, 1, 9, 5, 0, 0, 0],
        [0, 9, 8, 0, 0, 0, 0, 6, 0],
        [8, 0, 0, 0, 6, 0, 0, 0, 3],
        [4, 0, 0, 8, 0, 3, 0, 0, 1],
        [7, 0, 0, 0, 2, 0, 0, 0, 6],
        [0, 6, 0, 0, 0, 0, 2, 8, 0],
        [0, 0, 0, 4, 1, 9, 0, 0, 5],
        [0, 0, 0, 0, 8, 0, 0, 7, 9],
      ];

      final solutions = SudokuSolver.solve(puzzle);
      expect(solutions.length, 1);
      expect(SudokuSolver.hasUniqueSolution(puzzle), isTrue);

      final sol = solutions.first;
      expect(sol[0][0], 5);
      expect(sol[0][2], 4);
      expect(sol[8][8], 9);
    });

    test('returns empty list for invalid initial board with duplicate givens', () {
      final invalidPuzzle = [
        [5, 5, 0, 0, 0, 0, 0, 0, 0], // Two 5s in row 0
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];

      final solutions = SudokuSolver.solve(invalidPuzzle);
      expect(solutions, isEmpty);
      expect(SudokuSolver.hasUniqueSolution(invalidPuzzle), isFalse);
    });

    test('returns empty list for board with duplicate in column or box', () {
      final colDup = [
        [1, 0, 0, 0, 0, 0, 0, 0, 0],
        [1, 0, 0, 0, 0, 0, 0, 0, 0], // Duplicate in col 0
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];
      expect(SudokuSolver.solve(colDup), isEmpty);

      final boxDup = [
        [0, 2, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 2, 0, 0, 0, 0, 0, 0], // Duplicate in box (0,0)
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];
      expect(SudokuSolver.solve(boxDup), isEmpty);
    });

    test('empty board returns multiple solutions up to maxSolutions', () {
      final emptyGrid = List.generate(9, (_) => List.filled(9, 0));
      final sols = SudokuSolver.solve(emptyGrid, maxSolutions: 2);
      expect(sols.length, equals(2));
      expect(SudokuSolver.hasUniqueSolution(emptyGrid), isFalse);
    });

    test('solveBoard on SudokuBoard model', () {
      final board = SudokuGenerator.generate(Difficulty.easy, seed: 100);
      final solvedList = SudokuSolver.solveBoard(board);
      expect(solvedList.length, 1);
      expect(solvedList.first.isComplete(), isTrue);
    });
  });

  group('SudokuGenerator Tests', () {
    test('target givens per difficulty brackets', () {
      final rng = Random(42);
      for (final diff in Difficulty.values) {
        final count = SudokuGenerator.targetGivens(diff, rng);
        switch (diff) {
          case Difficulty.easy:
            expect(count, inInclusiveRange(36, 40));
            break;
          case Difficulty.medium:
            expect(count, inInclusiveRange(30, 35));
            break;
          case Difficulty.hard:
            expect(count, inInclusiveRange(25, 29));
            break;
          case Difficulty.expert:
            expect(count, inInclusiveRange(22, 24));
            break;
        }
      }
    });

    test('generates valid solvable puzzle with unique solution for each difficulty', () {
      for (final diff in Difficulty.values) {
        final board = SudokuGenerator.generate(diff, seed: 12345);
        expect(board.difficulty, diff);
        expect(board.isValid(), isTrue);

        final givens = board.countGivenCells();
        expect(givens, greaterThanOrEqualTo(22));

        final intGrid = List<List<int>>.generate(
          9,
          (r) => List<int>.generate(9, (c) => board.grid[r][c].value ?? 0),
        );
        expect(SudokuSolver.hasUniqueSolution(intGrid), isTrue);
      }
    });
  });

  group('SudokuBoard Operations & Validation Tests', () {
    test('setValue on editable vs given cells', () {
      final board = SudokuGenerator.generate(Difficulty.easy, seed: 99);
      // Find a given cell and an empty cell
      int givenR = -1, givenC = -1;
      int emptyR = -1, emptyC = -1;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (board.grid[r][c].isGiven && givenR == -1) {
            givenR = r;
            givenC = c;
          }
          if (!board.grid[r][c].isGiven && emptyR == -1) {
            emptyR = r;
            emptyC = c;
          }
        }
      }

      // Setting value on given cell is ignored
      final origVal = board.getValue(givenR, givenC);
      final ignored = board.setValue(givenR, givenC, 9);
      expect(ignored.getValue(givenR, givenC), origVal);

      // Setting value on empty cell succeeds and clears pencilmarks
      final withPencil = board.togglePencilmark(emptyR, emptyC, 3);
      expect(withPencil.getCell(emptyR, emptyC).pencilmarks, {3});

      final updated = withPencil.setValue(emptyR, emptyC, 7);
      expect(updated.getValue(emptyR, emptyC), 7);
      expect(updated.getCell(emptyR, emptyC).pencilmarks, isEmpty);

      // Clear value
      final cleared = updated.clearValue(emptyR, emptyC);
      expect(cleared.getValue(emptyR, emptyC), isNull);
      expect(cleared.clearValue(givenR, givenC), same(cleared));
    });

    test('toggle and clear pencilmarks', () {
      final board = SudokuGenerator.generate(Difficulty.easy, seed: 12);
      int emptyR = -1, emptyC = -1;
      int givenR = -1, givenC = -1;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (!board.grid[r][c].isGiven && emptyR == -1) {
            emptyR = r;
            emptyC = c;
          }
          if (board.grid[r][c].isGiven && givenR == -1) {
            givenR = r;
            givenC = c;
          }
        }
      }

      // Toggle on given cell is ignored
      expect(board.togglePencilmark(givenR, givenC, 1), same(board));

      var b = board.togglePencilmark(emptyR, emptyC, 4);
      expect(b.getCell(emptyR, emptyC).pencilmarks, {4});

      b = b.togglePencilmark(emptyR, emptyC, 8);
      expect(b.getCell(emptyR, emptyC).pencilmarks, {4, 8});

      b = b.togglePencilmark(emptyR, emptyC, 4);
      expect(b.getCell(emptyR, emptyC).pencilmarks, {8});

      b = b.clearPencilmarks(emptyR, emptyC);
      expect(b.getCell(emptyR, emptyC).pencilmarks, isEmpty);
      expect(b.clearPencilmarks(emptyR, emptyC), same(b));
    });

    test('conflict detection across row, col, and 3x3 block', () {
      final base = SudokuGenerator.generate(Difficulty.easy, seed: 77);
      expect(base.isValid(), isTrue);
      expect(base.getConflicts(), isEmpty);

      // Find two editable cells in the same row
      int r = -1;
      int c1 = -1, c2 = -1;
      for (int i = 0; i < 9; i++) {
        final empties = <int>[];
        for (int j = 0; j < 9; j++) {
          if (!base.grid[i][j].isGiven) empties.add(j);
        }
        if (empties.length >= 2) {
          r = i;
          c1 = empties[0];
          c2 = empties[1];
          break;
        }
      }

      final conflicting = base
          .setValue(r, c1, 9)
          .setValue(r, c2, 9);
      expect(conflicting.isValid(), isFalse);
      final conflicts = conflicting.getConflicts();
      expect(conflicts, contains(CellPosition(r, c1)));
      expect(conflicts, contains(CellPosition(r, c2)));
    });

    test('isComplete and digitCounts', () {
      final board = SudokuGenerator.generate(Difficulty.easy, seed: 55);
      expect(board.isComplete(), isFalse);

      final solved = SudokuSolver.solveBoard(board).first;
      expect(solved.isComplete(), isTrue);
      expect(solved.countEmptyCells(), 0);

      final counts = solved.digitCounts();
      for (int d = 1; d <= 9; d++) {
        expect(counts[d], 9);
      }
    });
  });

  group('HintEngine Detailed Branch Tests', () {
    test('HintEngine detects single candidate or fallback on board', () {
      final board = SudokuGenerator.generate(Difficulty.easy, seed: 88);
      final hint = HintEngine.getHint(board);
      expect(hint, isNotNull);
      expect(hint!.row, inInclusiveRange(0, 8));
      expect(hint.col, inInclusiveRange(0, 8));
      expect(hint.value, inInclusiveRange(1, 9));
      expect(hint.reason, isNotEmpty);

      // Solved board produces null hint
      final solved = SudokuSolver.solveBoard(board).first;
      expect(HintEngine.getHint(solved), isNull);
    });

    test('HintEngine exercises Hidden Single across Row, Col, and Box', () {
      // Create custom board where row hidden single is forced
      final solved = SudokuGenerator.generate(Difficulty.easy, seed: 44);
      final full = SudokuSolver.solveBoard(solved).first;

      // Clear two cells in row 0
      final b1 = full.clearValue(0, 1).clearValue(0, 2);
      final h1 = HintEngine.getHint(b1);
      expect(h1, isNotNull);

      // Clear two cells in col 0
      final b2 = full.clearValue(1, 0).clearValue(2, 0);
      final h2 = HintEngine.getHint(b2);
      expect(h2, isNotNull);

      // Clear two cells in box 0
      final b3 = full.clearValue(1, 1).clearValue(2, 2);
      final h3 = HintEngine.getHint(b3);
      expect(h3, isNotNull);
    });
  });

  group('SudokuState Controller Tests', () {
    test('initial state defaults', () {
      final state = SudokuState.initial(difficulty: Difficulty.medium, seed: 10);
      expect(state.status, SudokuStatus.playing);
      expect(state.mistakes, 0);
      expect(state.maxMistakes, 3);
      expect(state.mistakeMode, isTrue);
      expect(state.pencilMode, isFalse);
      expect(state.selectedCell, const CellPosition(4, 4));
      expect(state.elapsed, Duration.zero);
      expect(state.history, isEmpty);
    });

    test('selectCell ignores out-of-bounds coordinates', () {
      final state = SudokuState.initial();
      final valid = state.selectCell(2, 3);
      expect(valid.selectedCell, const CellPosition(2, 3));

      final invalid = valid.selectCell(-1, 10);
      expect(invalid.selectedCell, const CellPosition(2, 3));
    });

    test('pencil mode toggle and inputting pencil notes', () {
      var state = SudokuState.initial(seed: 123);
      // Select an empty cell
      int er = -1, ec = -1;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (!state.board.grid[r][c].isGiven) {
            er = r;
            ec = c;
            break;
          }
        }
        if (er != -1) break;
      }

      state = state.selectCell(er, ec).togglePencilMode();
      expect(state.pencilMode, isTrue);

      state = state.inputDigit(4);
      expect(state.board.getCell(er, ec).pencilmarks, {4});

      state = state.inputDigit(4);
      expect(state.board.getCell(er, ec).pencilmarks, isEmpty);

      // Toggle pencilmark directly
      state = state.togglePencilmark(7);
      expect(state.board.getCell(er, ec).pencilmarks, {7});
    });

    test('inputDigit edge cases: invalid digits, already placed, given cell', () {
      var state = SudokuState.initial(seed: 123);
      int givenR = -1, givenC = -1;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (state.board.grid[r][c].isGiven) {
            givenR = r;
            givenC = c;
            break;
          }
        }
        if (givenR != -1) break;
      }

      // Input on given cell is ignored
      state = state.selectCell(givenR, givenC);
      expect(state.inputDigit(5), same(state));

      // Input digit out of range 1..9 is ignored
      expect(state.inputDigit(0), same(state));
      expect(state.inputDigit(10), same(state));

      // Input when status is won or lost is ignored
      final wonState = state.copyWith(status: SudokuStatus.won);
      expect(wonState.inputDigit(1), same(wonState));
      expect(wonState.togglePencilmark(1), same(wonState));
      expect(wonState.erase(), same(wonState));
      expect(wonState.undo(), same(wonState));
      expect(wonState.getHint(), same(wonState));
      expect(wonState.applyHint(), same(wonState));
      expect(wonState.tick(const Duration(seconds: 1)), same(wonState));
    });

    test('correct digit entry, error entry, and 3-strike loss in mistake mode', () {
      var state = SudokuState.initial(seed: 456, mistakeMode: true);
      int er = -1, ec = -1;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (!state.board.grid[r][c].isGiven) {
            er = r;
            ec = c;
            break;
          }
        }
        if (er != -1) break;
      }

      final correctSol = state.board.getCell(er, ec).solutionValue!;
      final wrongSol = (correctSol % 9) + 1;

      state = state.selectCell(er, ec);

      // Strike 1
      state = state.inputDigit(wrongSol);
      expect(state.mistakes, 1);
      expect(state.status, SudokuStatus.playing);
      expect(state.board.getCell(er, ec).hasError, isTrue);

      // Placing same digit again is ignored
      expect(state.inputDigit(wrongSol), same(state));

      // Strike 2
      final wrongSol2 = (wrongSol % 9) + 1;
      state = state.inputDigit(wrongSol2);
      expect(state.mistakes, 2);
      expect(state.status, SudokuStatus.playing);

      // Strike 3 -> Lost
      final wrongSol3 = (wrongSol2 % 9) + 1;
      state = state.inputDigit(wrongSol3);
      expect(state.mistakes, 3);
      expect(state.status, SudokuStatus.lost);
    });

    test('non-mistake mode allows errors without loss', () {
      var state = SudokuState.initial(seed: 456, mistakeMode: false);
      int er = -1, ec = -1;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (!state.board.grid[r][c].isGiven) {
            er = r;
            ec = c;
            break;
          }
        }
        if (er != -1) break;
      }

      final correctSol = state.board.getCell(er, ec).solutionValue!;
      final wrongSol = (correctSol % 9) + 1;

      state = state.selectCell(er, ec).inputDigit(wrongSol);
      expect(state.mistakes, 0);
      expect(state.status, SudokuStatus.playing);
    });

    test('erase and undo operations', () {
      var state = SudokuState.initial(seed: 789);
      int er = -1, ec = -1;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (!state.board.grid[r][c].isGiven) {
            er = r;
            ec = c;
            break;
          }
        }
        if (er != -1) break;
      }

      state = state.selectCell(er, ec);
      final sol = state.board.getCell(er, ec).solutionValue!;

      // Place value
      state = state.inputDigit(sol);
      expect(state.board.getValue(er, ec), sol);
      expect(state.history.length, 1);

      // Erase
      state = state.erase();
      expect(state.board.getValue(er, ec), isNull);
      expect(state.history.length, 2);

      // Undo
      state = state.undo();
      expect(state.board.getValue(er, ec), sol);

      state = state.undo();
      expect(state.board.getValue(er, ec), isNull);

      // Undo on empty history returns same state
      expect(state.undo(), same(state));
    });

    test('hint getting and applying', () {
      var state = SudokuState.initial(seed: 321);
      // Calling applyHint without activeHint returns same
      expect(state.applyHint(), same(state));

      state = state.getHint();
      expect(state.activeHint, isNotNull);

      final hintRow = state.activeHint!.row;
      final hintCol = state.activeHint!.col;
      final hintVal = state.activeHint!.value;

      state = state.applyHint();
      expect(state.board.getValue(hintRow, hintCol), hintVal);
      expect(state.activeHint, isNull);
    });

    test('tick updates elapsed time and newGame resets state', () {
      var state = SudokuState.initial(seed: 111);
      state = state.tick(const Duration(seconds: 5));
      expect(state.elapsed, const Duration(seconds: 5));

      final fresh = state.newGame(Difficulty.hard, seed: 222);
      expect(fresh.board.difficulty, Difficulty.hard);
      expect(fresh.elapsed, Duration.zero);
      expect(fresh.mistakes, 0);
    });

    test('winning board transitions status to won', () {
      final initialBoard = SudokuGenerator.generate(Difficulty.easy, seed: 999);
      final solved = SudokuSolver.solveBoard(initialBoard).first;

      // Find an empty cell on initialBoard
      int targetR = -1, targetC = -1;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (!initialBoard.grid[r][c].isGiven) {
            targetR = r;
            targetC = c;
            break;
          }
        }
        if (targetR != -1) break;
      }

      // Create board that is 1 move away from solved
      final almostSolved = solved.clearValue(targetR, targetC);
      var state = SudokuState(
        board: almostSolved,
        selectedCell: CellPosition(targetR, targetC),
      );

      final lastDigit = solved.getCell(targetR, targetC).solutionValue!;
      state = state.inputDigit(lastDigit);
      expect(state.status, SudokuStatus.won);
    });
  });
}
