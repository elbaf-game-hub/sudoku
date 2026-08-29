import 'dart:math';

/// Puzzle difficulty levels.
enum Difficulty {
  easy,
  medium,
  hard,
  expert,
}

/// Lifecycle status of a Sudoku game.
enum SudokuStatus {
  playing,
  won,
  lost,
}

/// 2D Board position for a cell.
class CellPosition {
  final int row;
  final int col;

  const CellPosition(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellPosition &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'CellPosition($row, $col)';
}

/// Logical single-candidate hint data.
class SudokuHint {
  final int row;
  final int col;
  final int value;
  final String reason;

  const SudokuHint({
    required this.row,
    required this.col,
    required this.value,
    required this.reason,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SudokuHint &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col &&
          value == other.value &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(row, col, value, reason);

  @override
  String toString() =>
      'SudokuHint(r: $row, c: $col, val: $value, reason: $reason)';
}

/// Individual Sudoku cell.
class Cell {
  final int? value;
  final int? solutionValue;
  final bool isGiven;
  final Set<int> pencilmarks;
  final bool hasError;

  const Cell({
    this.value,
    this.solutionValue,
    required this.isGiven,
    this.pencilmarks = const {},
    this.hasError = false,
  });

  Cell copyWith({
    int? value,
    bool clearValue = false,
    int? solutionValue,
    bool? isGiven,
    Set<int>? pencilmarks,
    bool? hasError,
  }) {
    return Cell(
      value: clearValue ? null : (value ?? this.value),
      solutionValue: solutionValue ?? this.solutionValue,
      isGiven: isGiven ?? this.isGiven,
      pencilmarks: pencilmarks ?? this.pencilmarks,
      hasError: hasError ?? this.hasError,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cell &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          solutionValue == other.solutionValue &&
          isGiven == other.isGiven &&
          hasError == other.hasError &&
          pencilmarks.length == other.pencilmarks.length &&
          pencilmarks.containsAll(other.pencilmarks);

  @override
  int get hashCode => Object.hash(
        value,
        solutionValue,
        isGiven,
        hasError,
        Object.hashAll(pencilmarks),
      );

  @override
  String toString() =>
      'Cell(val: $value, sol: $solutionValue, given: $isGiven, err: $hasError, notes: $pencilmarks)';
}

/// 9x9 Sudoku Board.
class SudokuBoard {
  final List<List<Cell>> grid;
  final Difficulty difficulty;

  const SudokuBoard({
    required this.grid,
    required this.difficulty,
  });

  Cell getCell(int row, int col) => grid[row][col];

  int? getValue(int row, int col) => grid[row][col].value;

  SudokuBoard setValue(
    int row,
    int col,
    int? value, {
    bool hasError = false,
  }) {
    if (grid[row][col].isGiven) return this;

    final newGrid = List<List<Cell>>.generate(9, (r) {
      return List<Cell>.generate(9, (c) {
        if (r == row && c == col) {
          return grid[r][c].copyWith(
            value: value,
            clearValue: value == null,
            pencilmarks: const {},
            hasError: hasError,
          );
        }
        return grid[r][c];
      });
    });

    return SudokuBoard(grid: newGrid, difficulty: difficulty);
  }

  SudokuBoard clearValue(int row, int col) {
    if (grid[row][col].isGiven) return this;

    return setValue(row, col, null, hasError: false);
  }

  SudokuBoard togglePencilmark(int row, int col, int digit) {
    final cell = grid[row][col];
    if (cell.isGiven || cell.value != null) return this;

    final updated = Set<int>.from(cell.pencilmarks);
    if (updated.contains(digit)) {
      updated.remove(digit);
    } else {
      updated.add(digit);
    }

    final newGrid = List<List<Cell>>.generate(9, (r) {
      return List<Cell>.generate(9, (c) {
        if (r == row && c == col) {
          return cell.copyWith(pencilmarks: updated);
        }
        return grid[r][c];
      });
    });

    return SudokuBoard(grid: newGrid, difficulty: difficulty);
  }

  SudokuBoard clearPencilmarks(int row, int col) {
    final cell = grid[row][col];
    if (cell.pencilmarks.isEmpty) return this;

    final newGrid = List<List<Cell>>.generate(9, (r) {
      return List<Cell>.generate(9, (c) {
        if (r == row && c == col) {
          return cell.copyWith(pencilmarks: const {});
        }
        return grid[r][c];
      });
    });

    return SudokuBoard(grid: newGrid, difficulty: difficulty);
  }

  /// Returns true if all placed non-null values have no duplicates in row, col, or box.
  bool isValid() {
    return getConflicts().isEmpty;
  }

  /// Returns true if all 81 cells are filled, valid, and error-free.
  bool isComplete() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final cell = grid[r][c];
        if (cell.value == null || cell.hasError) return false;
        if (cell.solutionValue != null && cell.value != cell.solutionValue) {
          return false;
        }
      }
    }
    return isValid();
  }

  /// Finds all coordinates of cells causing duplicates in row, col, or 3x3 block.
  List<CellPosition> getConflicts() {
    final conflicts = <CellPosition>{};

    // Check rows
    for (int r = 0; r < 9; r++) {
      final seen = <int, int>{}; // val -> col
      for (int c = 0; c < 9; c++) {
        final v = grid[r][c].value;
        if (v != null) {
          if (seen.containsKey(v)) {
            conflicts.add(CellPosition(r, seen[v]!));
            conflicts.add(CellPosition(r, c));
          } else {
            seen[v] = c;
          }
        }
      }
    }

    // Check cols
    for (int c = 0; c < 9; c++) {
      final seen = <int, int>{}; // val -> row
      for (int r = 0; r < 9; r++) {
        final v = grid[r][c].value;
        if (v != null) {
          if (seen.containsKey(v)) {
            conflicts.add(CellPosition(seen[v]!, c));
            conflicts.add(CellPosition(r, c));
          } else {
            seen[v] = r;
          }
        }
      }
    }

    // Check 3x3 boxes
    for (int br = 0; br < 3; br++) {
      for (int bc = 0; bc < 3; bc++) {
        final seen = <int, CellPosition>{};
        for (int r = br * 3; r < br * 3 + 3; r++) {
          for (int c = bc * 3; c < bc * 3 + 3; c++) {
            final v = grid[r][c].value;
            if (v != null) {
              if (seen.containsKey(v)) {
                conflicts.add(seen[v]!);
                conflicts.add(CellPosition(r, c));
              } else {
                seen[v] = CellPosition(r, c);
              }
            }
          }
        }
      }
    }

    return conflicts.toList();
  }

  int countGivenCells() {
    int count = 0;
    for (final row in grid) {
      for (final cell in row) {
        if (cell.isGiven) count++;
      }
    }
    return count;
  }

  int countEmptyCells() {
    int count = 0;
    for (final row in grid) {
      for (final cell in row) {
        if (cell.value == null) count++;
      }
    }
    return count;
  }

  /// Count how many times each digit 1..9 is currently placed on the board.
  Map<int, int> digitCounts() {
    final counts = {for (int i = 1; i <= 9; i++) i: 0};
    for (final row in grid) {
      for (final cell in row) {
        if (cell.value != null && cell.value! >= 1 && cell.value! <= 9) {
          counts[cell.value!] = (counts[cell.value!] ?? 0) + 1;
        }
      }
    }
    return counts;
  }
}

/// Backtracking solver with constraint propagation and uniqueness verification.
class SudokuSolver {
  /// Solves a 9x9 integer grid (0 = empty, 1..9 = digits).
  /// Returns a list of solutions up to [maxSolutions].
  static List<List<List<int>>> solve(
    List<List<int>> board, {
    int maxSolutions = 2,
  }) {
    final solutions = <List<List<int>>>[];
    final grid = List<List<int>>.generate(
      9,
      (r) => List<int>.from(board[r]),
    );

    final rowMask = List<int>.filled(9, 0);
    final colMask = List<int>.filled(9, 0);
    final boxMask = List<int>.filled(9, 0);

    // Initialize bitmasks
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final val = grid[r][c];
        if (val >= 1 && val <= 9) {
          final bit = 1 << val;
          final b = (r ~/ 3) * 3 + (c ~/ 3);
          if ((rowMask[r] & bit) != 0 ||
              (colMask[c] & bit) != 0 ||
              (boxMask[b] & bit) != 0) {
            // Invalid starting board with duplicate givens
            return const [];
          }
          rowMask[r] |= bit;
          colMask[c] |= bit;
          boxMask[b] |= bit;
        }
      }
    }

    void search() {
      if (solutions.length >= maxSolutions) return;

      // Find empty cell with minimum candidate count (MRV heuristic)
      int bestRow = -1;
      int bestCol = -1;
      int minCandidates = 10;
      int bestCandidatesMask = 0;

      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (grid[r][c] == 0) {
            final b = (r ~/ 3) * 3 + (c ~/ 3);
            final used = rowMask[r] | colMask[c] | boxMask[b];
            int count = 0;
            int candidatesMask = 0;
            for (int d = 1; d <= 9; d++) {
              if ((used & (1 << d)) == 0) {
                count++;
                candidatesMask |= (1 << d);
              }
            }

            if (count == 0) {
              // Dead end
              return;
            }

            if (count < minCandidates) {
              minCandidates = count;
              bestRow = r;
              bestCol = c;
              bestCandidatesMask = candidatesMask;
              if (count == 1) break;
            }
          }
        }
        if (minCandidates == 1) break;
      }

      if (bestRow == -1) {
        // Solved!
        solutions.add(
          List<List<int>>.generate(9, (r) => List<int>.from(grid[r])),
        );
        return;
      }

      final b = (bestRow ~/ 3) * 3 + (bestCol ~/ 3);
      for (int d = 1; d <= 9; d++) {
        final bit = 1 << d;
        if ((bestCandidatesMask & bit) != 0) {
          grid[bestRow][bestCol] = d;
          rowMask[bestRow] |= bit;
          colMask[bestCol] |= bit;
          boxMask[b] |= bit;

          search();

          grid[bestRow][bestCol] = 0;
          rowMask[bestRow] &= ~bit;
          colMask[bestCol] &= ~bit;
          boxMask[b] &= ~bit;

          if (solutions.length >= maxSolutions) return;
        }
      }
    }

    search();
    return solutions;
  }

  /// Returns true iff the puzzle has exactly one valid solution.
  static bool hasUniqueSolution(List<List<int>> board) {
    return solve(board, maxSolutions: 2).length == 1;
  }

  /// Solves board from SudokuBoard model.
  static List<SudokuBoard> solveBoard(SudokuBoard board, {int maxSolutions = 2}) {
    final intGrid = List<List<int>>.generate(
      9,
      (r) => List<int>.generate(9, (c) => board.grid[r][c].value ?? 0),
    );

    final solutions = solve(intGrid, maxSolutions: maxSolutions);
    return solutions.map((sol) {
      final newGrid = List<List<Cell>>.generate(9, (r) {
        return List<Cell>.generate(9, (c) {
          final orig = board.grid[r][c];
          return Cell(
            value: sol[r][c],
            solutionValue: sol[r][c],
            isGiven: orig.isGiven,
            pencilmarks: const {},
            hasError: false,
          );
        });
      });
      return SudokuBoard(grid: newGrid, difficulty: board.difficulty);
    }).toList();
  }
}

/// Dynamic Sudoku puzzle generator.
class SudokuGenerator {
  /// Target givens per difficulty level.
  static int targetGivens(Difficulty difficulty, Random rng) {
    switch (difficulty) {
      case Difficulty.easy:
        return 36 + rng.nextInt(5); // 36..40
      case Difficulty.medium:
        return 30 + rng.nextInt(6); // 30..35
      case Difficulty.hard:
        return 25 + rng.nextInt(5); // 25..29
      case Difficulty.expert:
        return 22 + rng.nextInt(3); // 22..24
    }
  }

  /// Generates a valid puzzle with a guaranteed unique solution.
  static SudokuBoard generate(Difficulty difficulty, {int? seed, Random? random}) {
    final rng = random ?? Random(seed);
    final targetCount = targetGivens(difficulty, rng);

    // Step 1: Generate a fully solved random valid board
    final fullSolution = _generateFullBoard(rng);

    // Step 2: Dig holes while preserving uniqueness
    final puzzle = List<List<int>>.generate(
      9,
      (r) => List<int>.from(fullSolution[r]),
    );

    final positions = <CellPosition>[];
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        positions.add(CellPosition(r, c));
      }
    }
    positions.shuffle(rng);

    int currentGivens = 81;
    for (final pos in positions) {
      if (currentGivens <= targetCount) break;

      final val = puzzle[pos.row][pos.col];
      puzzle[pos.row][pos.col] = 0;

      if (SudokuSolver.hasUniqueSolution(puzzle)) {
        currentGivens--;
      } else {
        // Restore value
        puzzle[pos.row][pos.col] = val;
      }
    }

    // Step 3: Construct SudokuBoard
    final grid = List<List<Cell>>.generate(9, (r) {
      return List<Cell>.generate(9, (c) {
        final val = puzzle[r][c];
        final sol = fullSolution[r][c];
        if (val != 0) {
          return Cell(
            value: val,
            solutionValue: sol,
            isGiven: true,
            pencilmarks: const {},
            hasError: false,
          );
        } else {
          return Cell(
            value: null,
            solutionValue: sol,
            isGiven: false,
            pencilmarks: const {},
            hasError: false,
          );
        }
      });
    });

    return SudokuBoard(grid: grid, difficulty: difficulty);
  }

  static List<List<int>> _generateFullBoard(Random rng) {
    final grid = List<List<int>>.generate(9, (_) => List<int>.filled(9, 0));

    // Fill diagonal 3x3 blocks independently
    for (int b = 0; b < 3; b++) {
      final nums = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle(rng);
      int idx = 0;
      for (int r = b * 3; r < b * 3 + 3; r++) {
        for (int c = b * 3; c < b * 3 + 3; c++) {
          grid[r][c] = nums[idx++];
        }
      }
    }

    // Solve the rest
    final solutions = SudokuSolver.solve(grid, maxSolutions: 1);
    if (solutions.isNotEmpty) {
      return solutions.first;
    }

    // Fallback standard Latin-shifted base board if ever needed
    final base = [
      [1, 2, 3, 4, 5, 6, 7, 8, 9],
      [4, 5, 6, 7, 8, 9, 1, 2, 3],
      [7, 8, 9, 1, 2, 3, 4, 5, 6],
      [2, 3, 1, 5, 6, 4, 8, 9, 7],
      [5, 6, 4, 8, 9, 7, 2, 3, 1],
      [8, 9, 7, 2, 3, 1, 5, 6, 4],
      [3, 1, 2, 6, 4, 5, 9, 7, 8],
      [6, 4, 5, 9, 7, 8, 3, 1, 2],
      [9, 7, 8, 3, 1, 2, 6, 4, 5],
    ];
    return base;
  }
}

/// Logical single-candidate hint engine.
class HintEngine {
  /// Identifies the first single-candidate cell or returns fallback logical hint.
  static SudokuHint? getHint(SudokuBoard board) {
    // 1. Check for Naked Single: only 1 legal candidate in cell
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final cell = board.grid[r][c];
        if (cell.value == null) {
          final legal = _getLegalCandidates(board, r, c);
          if (legal.length == 1) {
            final val = legal.first;
            return SudokuHint(
              row: r,
              col: c,
              value: val,
              reason: 'Naked single: only $val can fit here.',
            );
          }
        }
      }
    }

    // 2. Check for Hidden Single: digit can only go in one cell in row/col/box
    // Row check
    for (int r = 0; r < 9; r++) {
      for (int d = 1; d <= 9; d++) {
        final possibleCols = <int>[];
        for (int c = 0; c < 9; c++) {
          if (board.grid[r][c].value == d) {
            possibleCols.clear();
            break;
          }
          if (board.grid[r][c].value == null &&
              _getLegalCandidates(board, r, c).contains(d)) {
            possibleCols.add(c);
          }
        }
        if (possibleCols.length == 1) {
          return SudokuHint(
            row: r,
            col: possibleCols.first,
            value: d,
            reason: 'Hidden single: $d can only be in column ${possibleCols.first + 1} of row ${r + 1}.',
          );
        }
      }
    }

    // Col check
    for (int c = 0; c < 9; c++) {
      for (int d = 1; d <= 9; d++) {
        final possibleRows = <int>[];
        for (int r = 0; r < 9; r++) {
          if (board.grid[r][c].value == d) {
            possibleRows.clear();
            break;
          }
          if (board.grid[r][c].value == null &&
              _getLegalCandidates(board, r, c).contains(d)) {
            possibleRows.add(r);
          }
        }
        if (possibleRows.length == 1) {
          return SudokuHint(
            row: possibleRows.first,
            col: c,
            value: d,
            reason: 'Hidden single: $d can only be in row ${possibleRows.first + 1} of column ${c + 1}.',
          );
        }
      }
    }

    // Box check
    for (int br = 0; br < 3; br++) {
      for (int bc = 0; bc < 3; bc++) {
        for (int d = 1; d <= 9; d++) {
          final possibleCells = <CellPosition>[];
          bool present = false;
          for (int r = br * 3; r < br * 3 + 3; r++) {
            for (int c = bc * 3; c < bc * 3 + 3; c++) {
              if (board.grid[r][c].value == d) {
                present = true;
                break;
              }
              if (board.grid[r][c].value == null &&
                  _getLegalCandidates(board, r, c).contains(d)) {
                possibleCells.add(CellPosition(r, c));
              }
            }
            if (present) break;
          }
          if (!present && possibleCells.length == 1) {
            return SudokuHint(
              row: possibleCells.first.row,
              col: possibleCells.first.col,
              value: d,
              reason: 'Hidden single: $d is the only candidate in 3x3 block.',
            );
          }
        }
      }
    }

    // 3. Fallback: find first empty cell and supply its solutionValue
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final cell = board.grid[r][c];
        if (cell.value == null && cell.solutionValue != null) {
          return SudokuHint(
            row: r,
            col: c,
            value: cell.solutionValue!,
            reason: 'Hint: placing ${cell.solutionValue}.',
          );
        }
      }
    }

    return null;
  }

  static Set<int> _getLegalCandidates(SudokuBoard board, int row, int col) {
    final candidates = {1, 2, 3, 4, 5, 6, 7, 8, 9};

    // Row & Col exclusions
    for (int i = 0; i < 9; i++) {
      final rv = board.grid[row][i].value;
      if (rv != null) candidates.remove(rv);

      final cv = board.grid[i][col].value;
      if (cv != null) candidates.remove(cv);
    }

    // Box exclusions
    final br = (row ~/ 3) * 3;
    final bc = (col ~/ 3) * 3;
    for (int r = br; r < br + 3; r++) {
      for (int c = bc; c < bc + 3; c++) {
        final bv = board.grid[r][c].value;
        if (bv != null) candidates.remove(bv);
      }
    }

    return candidates;
  }
}

/// Pure Dart state controller for Sudoku.
class SudokuState {
  final SudokuBoard board;
  final CellPosition? selectedCell;
  final bool pencilMode;
  final int mistakes;
  final int maxMistakes;
  final bool mistakeMode;
  final SudokuStatus status;
  final Duration elapsed;
  final List<SudokuBoard> history;
  final SudokuHint? activeHint;
  final int? seed;

  const SudokuState({
    required this.board,
    this.selectedCell,
    this.pencilMode = false,
    this.mistakes = 0,
    this.maxMistakes = 3,
    this.mistakeMode = true,
    this.status = SudokuStatus.playing,
    this.elapsed = Duration.zero,
    this.history = const [],
    this.activeHint,
    this.seed,
  });

  factory SudokuState.initial({
    Difficulty difficulty = Difficulty.easy,
    int? seed,
    bool mistakeMode = true,
  }) {
    final board = SudokuGenerator.generate(difficulty, seed: seed);
    return SudokuState(
      board: board,
      selectedCell: const CellPosition(4, 4),
      pencilMode: false,
      mistakes: 0,
      maxMistakes: 3,
      mistakeMode: mistakeMode,
      status: SudokuStatus.playing,
      elapsed: Duration.zero,
      history: const [],
      activeHint: null,
      seed: seed,
    );
  }

  SudokuState selectCell(int row, int col) {
    if (row < 0 || row >= 9 || col < 0 || col >= 9) return this;
    return copyWith(
      selectedCell: CellPosition(row, col),
      activeHint: null,
    );
  }

  SudokuState togglePencilMode() {
    return copyWith(pencilMode: !pencilMode);
  }

  SudokuState togglePencilmark(int digit) {
    if (selectedCell == null || status != SudokuStatus.playing) return this;
    final r = selectedCell!.row;
    final c = selectedCell!.col;

    final newBoard = board.togglePencilmark(r, c, digit);
    return copyWith(
      board: newBoard,
      activeHint: null,
    );
  }

  SudokuState inputDigit(int digit) {
    if (selectedCell == null || status != SudokuStatus.playing) return this;
    if (digit < 1 || digit > 9) return this;

    final r = selectedCell!.row;
    final c = selectedCell!.col;
    final cell = board.getCell(r, c);

    if (cell.isGiven) return this;

    if (pencilMode) {
      return togglePencilmark(digit);
    }

    // Placing regular digit
    if (cell.value == digit) return this; // Already placed

    final isCorrect = cell.solutionValue == null || cell.solutionValue == digit;
    final hasError = !isCorrect;
    int newMistakes = mistakes;
    SudokuStatus newStatus = status;

    if (hasError && mistakeMode) {
      newMistakes += 1;
      if (newMistakes >= maxMistakes) {
        newStatus = SudokuStatus.lost;
      }
    }

    final newBoard = board.setValue(r, c, digit, hasError: hasError);

    if (newBoard.isComplete()) {
      newStatus = SudokuStatus.won;
    }

    final newHistory = List<SudokuBoard>.from(history)..add(board);

    return copyWith(
      board: newBoard,
      mistakes: newMistakes,
      status: newStatus,
      history: newHistory,
      activeHint: null,
    );
  }

  SudokuState erase() {
    if (selectedCell == null || status != SudokuStatus.playing) return this;
    final r = selectedCell!.row;
    final c = selectedCell!.col;
    final cell = board.getCell(r, c);

    if (cell.isGiven || (cell.value == null && cell.pencilmarks.isEmpty)) {
      return this;
    }

    final newBoard = cell.value != null
        ? board.clearValue(r, c)
        : board.clearPencilmarks(r, c);

    final newHistory = List<SudokuBoard>.from(history)..add(board);

    return copyWith(
      board: newBoard,
      history: newHistory,
      activeHint: null,
    );
  }

  SudokuState undo() {
    if (history.isEmpty || status != SudokuStatus.playing) return this;
    final previousBoard = history.last;
    final updatedHistory = List<SudokuBoard>.from(history)..removeLast();

    return copyWith(
      board: previousBoard,
      history: updatedHistory,
      activeHint: null,
    );
  }

  SudokuState getHint() {
    if (status != SudokuStatus.playing) return this;

    final hint = HintEngine.getHint(board);
    if (hint == null) return this;

    return copyWith(
      selectedCell: CellPosition(hint.row, hint.col),
      activeHint: hint,
    );
  }

  SudokuState applyHint() {
    if (activeHint == null || status != SudokuStatus.playing) return this;
    final hint = activeHint!;
    final r = hint.row;
    final c = hint.col;
    final val = hint.value;

    final newBoard = board.setValue(r, c, val, hasError: false);
    final newStatus = newBoard.isComplete() ? SudokuStatus.won : status;
    final newHistory = List<SudokuBoard>.from(history)..add(board);

    return copyWith(
      board: newBoard,
      status: newStatus,
      history: newHistory,
      activeHint: null,
      selectedCell: CellPosition(r, c),
    );
  }

  SudokuState tick(Duration delta) {
    if (status != SudokuStatus.playing) return this;
    return copyWith(elapsed: elapsed + delta);
  }

  SudokuState newGame(
    Difficulty difficulty, {
    int? seed,
    bool? mistakeMode,
  }) {
    return SudokuState.initial(
      difficulty: difficulty,
      seed: seed,
      mistakeMode: mistakeMode ?? this.mistakeMode,
    );
  }

  SudokuState copyWith({
    SudokuBoard? board,
    CellPosition? selectedCell,
    bool? pencilMode,
    int? mistakes,
    int? maxMistakes,
    bool? mistakeMode,
    SudokuStatus? status,
    Duration? elapsed,
    List<SudokuBoard>? history,
    SudokuHint? activeHint,
    int? seed,
  }) {
    return SudokuState(
      board: board ?? this.board,
      selectedCell: selectedCell ?? this.selectedCell,
      pencilMode: pencilMode ?? this.pencilMode,
      mistakes: mistakes ?? this.mistakes,
      maxMistakes: maxMistakes ?? this.maxMistakes,
      mistakeMode: mistakeMode ?? this.mistakeMode,
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      history: history ?? this.history,
      activeHint: activeHint,
      seed: seed ?? this.seed,
    );
  }
}
