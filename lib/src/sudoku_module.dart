import 'package:flutter/material.dart';
import 'package:game_module/game_module.dart';

import 'sudoku_page.dart';

GameModule get sudokuModule => const _SudokuModule();

class _SudokuModule implements GameModule {
  const _SudokuModule();

  @override
  GameDescriptor get descriptor => const GameDescriptor(
        id: 'sudoku',
        name: 'Sudoku',
        description: 'Fill the 9×9 grid with numbers 1–9.',
        icon: Icons.calculate_outlined,
        color: Color(0xFF5B8DEF),
        build: _buildPage,
      );

  static Widget _buildPage(BuildContext context) => const SudokuPage();
}
