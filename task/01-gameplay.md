# 01 — Gameplay

## Rules summary

Fill the 9×9 grid with digits 1–9.

> Full rules: https://en.wikipedia.org/wiki/Sudoku

## Controls

Tap a cell to select. Use the on-screen numpad or keyboard to enter a digit. Long-press toggles pencilmark mode.

## Screen flow

1. Difficulty select
2. Game (board + numpad + pencil toggle + hint + undo)
3. Win (time, mistakes, 'New game')

## Difficulty

Easy 36–40 givens, Medium 30–35, Hard 25–29, Expert 22–24.

## Scoring

Best time per difficulty. Optional mistake count (max 3 in mistake mode).

## State machine

The game moves through these states: **playing, won, lost (in mistake mode)**.

```
      ┌──────────────┐
      │   playing    │
      └──┬───┬───┬───┘
         │   │   │
         │   │   └──► won
```
