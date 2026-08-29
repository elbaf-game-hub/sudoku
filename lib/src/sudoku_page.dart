import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_assets/game_assets.dart';

import 'sudoku_state.dart';

class SudokuPage extends StatefulWidget {
  const SudokuPage({super.key});

  @override
  State<SudokuPage> createState() => _SudokuPageState();
}

class _SudokuPageState extends State<SudokuPage> {
  late SudokuState _state;
  Timer? _timer;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _state = SudokuState.initial();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state.status == SudokuStatus.playing) {
        setState(() {
          _state = _state.tick(const Duration(seconds: 1));
        });
      }
    });
  }

  void _onSelectCell(int row, int col) {
    SfxPlayer.instance.play('tap');
    setState(() {
      _state = _state.selectCell(row, col);
    });
  }

  void _onInputDigit(int digit) {
    final prevStatus = _state.status;
    final prevMistakes = _state.mistakes;

    final next = _state.inputDigit(digit);

    if (next.status == SudokuStatus.won && prevStatus != SudokuStatus.won) {
      SfxPlayer.instance.play('win');
    } else if (next.status == SudokuStatus.lost &&
        prevStatus != SudokuStatus.lost) {
      SfxPlayer.instance.play('lose');
    } else if (next.mistakes > prevMistakes) {
      SfxPlayer.instance.play('lose');
    } else {
      SfxPlayer.instance.play('tap');
    }

    setState(() {
      _state = next;
    });
  }

  void _onErase() {
    SfxPlayer.instance.play('tap');
    setState(() {
      _state = _state.erase();
    });
  }

  void _onUndo() {
    SfxPlayer.instance.play('tap');
    setState(() {
      _state = _state.undo();
    });
  }

  void _onTogglePencil() {
    SfxPlayer.instance.play('tap');
    setState(() {
      _state = _state.togglePencilMode();
    });
  }

  void _onGetHint() {
    SfxPlayer.instance.play('tap');
    final next = _state.getHint();
    if (next.activeHint != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next.activeHint!.reason),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'PLACE',
            onPressed: () {
              setState(() {
                _state = _state.applyHint();
              });
            },
          ),
        ),
      );
    }
    setState(() {
      _state = next;
    });
  }

  void _onNewGame(Difficulty difficulty) {
    SfxPlayer.instance.play('tap');
    setState(() {
      _state = _state.newGame(difficulty);
    });
  }

  void _showDifficultySheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Select Difficulty',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                for (final diff in Difficulty.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _onNewGame(diff);
                      },
                      child: Text(diff.name.toUpperCase()),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      _onInputDigit(1);
    } else if (key == LogicalKeyboardKey.digit2 ||
        key == LogicalKeyboardKey.numpad2) {
      _onInputDigit(2);
    } else if (key == LogicalKeyboardKey.digit3 ||
        key == LogicalKeyboardKey.numpad3) {
      _onInputDigit(3);
    } else if (key == LogicalKeyboardKey.digit4 ||
        key == LogicalKeyboardKey.numpad4) {
      _onInputDigit(4);
    } else if (key == LogicalKeyboardKey.digit5 ||
        key == LogicalKeyboardKey.numpad5) {
      _onInputDigit(5);
    } else if (key == LogicalKeyboardKey.digit6 ||
        key == LogicalKeyboardKey.numpad6) {
      _onInputDigit(6);
    } else if (key == LogicalKeyboardKey.digit7 ||
        key == LogicalKeyboardKey.numpad7) {
      _onInputDigit(7);
    } else if (key == LogicalKeyboardKey.digit8 ||
        key == LogicalKeyboardKey.numpad8) {
      _onInputDigit(8);
    } else if (key == LogicalKeyboardKey.digit9 ||
        key == LogicalKeyboardKey.numpad9) {
      _onInputDigit(9);
    } else if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      _onErase();
    } else if (key == LogicalKeyboardKey.keyP) {
      _onTogglePencil();
    } else if (key == LogicalKeyboardKey.keyH) {
      _onGetHint();
    } else if (key == LogicalKeyboardKey.keyZ &&
        (HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
         HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight))) {
      _onUndo();
    } else {
      if (key == LogicalKeyboardKey.arrowUp) {
        _moveSelection(-1, 0);
      } else if (key == LogicalKeyboardKey.arrowDown) {
        _moveSelection(1, 0);
      } else if (key == LogicalKeyboardKey.arrowLeft) {
        _moveSelection(0, -1);
      } else if (key == LogicalKeyboardKey.arrowRight) {
        _moveSelection(0, 1);
      }
    }
  }

  void _moveSelection(int dRow, int dCol) {
    final current = _state.selectedCell ?? const CellPosition(4, 4);
    final nr = (current.row + dRow).clamp(0, 8);
    final nc = (current.col + dCol).clamp(0, 8);
    _onSelectCell(nr, nc);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final digitCounts = _state.board.digitCounts();

    return Theme(
      data: buildGameTheme(Brightness.light),
      child: Scaffold(
        appBar: GameAppBar(
          title: 'Sudoku',
          score: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatDuration(_state.elapsed),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 12),
              if (_state.mistakeMode)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _state.mistakes > 0
                        ? GameTokens.danger.withAlpha(40)
                        : Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_state.mistakes}/${_state.maxMistakes}',
                    style: TextStyle(
                      color: _state.mistakes > 0
                          ? GameTokens.danger
                          : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          onRestart: () => _onNewGame(_state.board.difficulty),
          onSettings: _showDifficultySheet,
        ),
        body: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                return SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWide ? 800 : 480,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            // Difficulty Badge & Info
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _showDifficultySheet,
                                  icon: const Icon(Icons.tune, size: 16),
                                  label: Text(
                                    _state.board.difficulty.name.toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                if (_state.status == SudokuStatus.won)
                                  const Text(
                                    '🎉 SOLVED!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: GameTokens.success,
                                      fontSize: 16,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // 9x9 Sudoku Board
                            AspectRatio(
                              aspectRatio: 1.0,
                              child: _buildBoard(),
                            ),

                            const SizedBox(height: 12),

                            // Action Toolbar (Undo, Erase, Pencil Mode, Hint)
                            _buildActionBar(),

                            const SizedBox(height: 12),

                            // 1-9 Number Keypad
                            _buildKeypad(digitCounts),

                            const SizedBox(height: 8),

                            // Win / Loss Dialog Overlay
                            if (_state.status == SudokuStatus.won)
                              _buildWinBanner(),
                            if (_state.status == SudokuStatus.lost)
                              _buildLossBanner(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoard() {
    final sel = _state.selectedCell;
    final selectedRow = sel?.row;
    final selectedCol = sel?.col;
    final selectedVal = (sel != null) ? _state.board.getValue(sel.row, sel.col) : null;

    return Container(
      decoration: BoxDecoration(
        color: GameTokens.surface,
        border: Border.all(color: Colors.black87, width: 2.0),
        borderRadius: BorderRadius.circular(GameTokens.radiusSm),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int r = 0; r < 9; r++)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: (r % 3 == 2 && r != 8)
                          ? Colors.black87
                          : Colors.black26,
                      width: (r % 3 == 2 && r != 8) ? 2.0 : 1.0,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    for (int c = 0; c < 9; c++)
                      Expanded(
                        child: _buildCell(
                          r,
                          c,
                          selectedRow,
                          selectedCol,
                          selectedVal,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCell(
    int r,
    int c,
    int? selectedRow,
    int? selectedCol,
    int? selectedVal,
  ) {
    final cell = _state.board.getCell(r, c);
    final isSelected = selectedRow == r && selectedCol == c;
    final isSameBox = selectedRow != null &&
        selectedCol != null &&
        (selectedRow ~/ 3 == r ~/ 3) &&
        (selectedCol ~/ 3 == c ~/ 3);
    final isHighlighted = (selectedRow == r || selectedCol == c || isSameBox);
    final isSameNumber = selectedVal != null && cell.value == selectedVal;
    final isHintTarget = _state.activeHint != null &&
        _state.activeHint!.row == r &&
        _state.activeHint!.col == c;

    Color bgColor = Colors.transparent;
    if (isSelected) {
      bgColor = const Color(0xFFFFEB80); // yellow selected
    } else if (isHintTarget) {
      bgColor = const Color(0xFFC8E6C9); // green hint
    } else if (cell.hasError) {
      bgColor = const Color(0xFFFFCDD2); // red error
    } else if (isSameNumber) {
      bgColor = const Color(0xFFD0E1FD); // same number highlight
    } else if (isHighlighted) {
      bgColor = const Color(0xFFF0F4FA); // peer highlight
    } else if (cell.isGiven) {
      bgColor = const Color(0xFFF9F7F2); // given bg
    }

    return InkWell(
      onTap: () => _onSelectCell(r, c),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            right: BorderSide(
              color: (c % 3 == 2 && c != 8)
                  ? Colors.black87
                  : Colors.black26,
              width: (c % 3 == 2 && c != 8) ? 2.0 : 1.0,
            ),
          ),
        ),
        child: Center(
          child: _buildCellContent(cell),
        ),
      ),
    );
  }

  Widget _buildCellContent(Cell cell) {
    if (cell.value != null) {
      Color textColor = Colors.black87;
      if (cell.hasError) {
        textColor = GameTokens.danger;
      } else if (cell.isGiven) {
        textColor = const Color(0xFF1E293B);
      } else {
        textColor = GameTokens.primary;
      }

      return Text(
        '${cell.value}',
        style: TextStyle(
          fontSize: 22,
          fontWeight: cell.isGiven ? FontWeight.w900 : FontWeight.w700,
          color: textColor,
        ),
      );
    }

    if (cell.pencilmarks.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(2.0),
        child: GridView.count(
          crossAxisCount: 3,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (int d = 1; d <= 9; d++)
              Center(
                child: Text(
                  cell.pencilmarks.contains(d) ? '$d' : '',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                    height: 1.0,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActionBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          tooltip: 'Undo',
          icon: const Icon(Icons.undo),
          onPressed: _state.history.isNotEmpty ? _onUndo : null,
        ),
        IconButton(
          tooltip: 'Erase',
          icon: const Icon(Icons.backspace_outlined),
          onPressed: _onErase,
        ),
        FilterChip(
          label: const Text('Pencil (Notes)'),
          avatar: Icon(
            _state.pencilMode ? Icons.edit : Icons.edit_outlined,
            size: 16,
          ),
          selected: _state.pencilMode,
          onSelected: (_) => _onTogglePencil(),
        ),
        IconButton(
          tooltip: 'Hint',
          icon: const Icon(Icons.lightbulb_outline),
          onPressed: _onGetHint,
        ),
      ],
    );
  }

  Widget _buildKeypad(Map<int, int> digitCounts) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (int d = 1; d <= 9; d++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _buildDigitButton(d, digitCounts[d] ?? 0),
            ),
          ),
      ],
    );
  }

  Widget _buildDigitButton(int digit, int currentCount) {
    final remaining = 9 - currentCount;
    final isCompleted = remaining <= 0;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: isCompleted ? Colors.black12 : GameTokens.surface,
      ),
      onPressed: isCompleted ? null : () => _onInputDigit(digit),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$digit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isCompleted ? Colors.grey : Colors.black87,
            ),
          ),
          Text(
            '$remaining',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isCompleted ? Colors.transparent : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GameTokens.success.withAlpha(20),
        borderRadius: BorderRadius.circular(GameTokens.radiusMd),
        border: Border.all(color: GameTokens.success, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PUZZLE SOLVED! 🎉',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: GameTokens.success,
                ),
              ),
              Text(
                'Time: ${_formatDuration(_state.elapsed)} | Mistakes: ${_state.mistakes}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => _onNewGame(_state.board.difficulty),
            style: ElevatedButton.styleFrom(
              backgroundColor: GameTokens.success,
            ),
            child: const Text('NEW GAME'),
          ),
        ],
      ),
    );
  }

  Widget _buildLossBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GameTokens.danger.withAlpha(20),
        borderRadius: BorderRadius.circular(GameTokens.radiusMd),
        border: Border.all(color: GameTokens.danger, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GAME OVER',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: GameTokens.danger,
                ),
              ),
              Text(
                '3/3 mistakes made',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => _onNewGame(_state.board.difficulty),
            style: ElevatedButton.styleFrom(
              backgroundColor: GameTokens.danger,
            ),
            child: const Text('TRY AGAIN'),
          ),
        ],
      ),
    );
  }
}
