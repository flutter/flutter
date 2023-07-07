import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'piece.dart';

class DrawEngine {
  /// handle to DC
  int hdc;

  /// handle to window
  int hwnd;

  /// rectangle for drawing
  final rect = calloc<RECT>();

  /// level width
  int width;

  /// level height
  int height;

  /// Initiate the DrawEngine
  DrawEngine(this.hdc, this.hwnd,
      [int pxPerBlock = 25, this.width = 10, this.height = 20]) {
    GetClientRect(hwnd, rect);

    SaveDC(hdc);

    // Set up coordinate system
    SetMapMode(hdc, MM_ISOTROPIC);
    SetViewportExtEx(hdc, pxPerBlock, pxPerBlock, nullptr);
    SetWindowExtEx(hdc, 1, -1, nullptr);
    SetViewportOrgEx(hdc, 0, rect.ref.bottom, nullptr);

    // Set default colors
    SetTextColor(hdc, RGB(255, 255, 255));
    SetBkColor(hdc, RGB(70, 70, 70));
    SetBkMode(hdc, TRANSPARENT);
  }

  void drawBlock(int x, int y, int color) {
    final hBrush = CreateSolidBrush(color);
    rect.ref.left = x;
    rect.ref.right = x + 1;
    rect.ref.top = y;
    rect.ref.bottom = y + 1;

    FillRect(hdc, rect, hBrush);

    // Draw left and bottom black border
    MoveToEx(hdc, x, y + 1, nullptr);
    LineTo(hdc, x, y);
    LineTo(hdc, x + 1, y);
    DeleteObject(hBrush);
  }

  void drawInterface() {
    final hBrush = CreateSolidBrush(RGB(70, 70, 70));
    rect.ref.top = height;
    rect.ref.left = width;
    rect.ref.bottom = 0;
    rect.ref.right = width + 8;
    FillRect(hdc, rect, hBrush);
    DeleteObject(hBrush);
  }

  void drawText(String text, int x, int y) {
    final textPtr = TEXT(text);
    TextOut(hdc, x, y, textPtr, text.length);
    free(textPtr);
  }

  void drawScore(int score, int x, int y) {
    final scoreText = 'Score: $score';
    final scoreTextPtr = TEXT(scoreText);

    SetBkMode(hdc, OPAQUE);
    TextOut(hdc, x, y, scoreTextPtr, scoreText.length);
    SetBkMode(hdc, TRANSPARENT);

    free(scoreTextPtr);
  }

  void drawSpeed(int speed, int x, int y) {
    final speedText = 'Speed: $speed';
    final speedTextPtr = TEXT(speedText);

    SetBkMode(hdc, OPAQUE);
    TextOut(hdc, x, y, speedTextPtr, speedText.length);
    SetBkMode(hdc, TRANSPARENT);

    free(speedTextPtr);
  }

  void drawNextPiece(Piece piece, int x, int y) {
    const nextText = 'Next:';
    final nextTextPtr = TEXT(nextText);

    TextOut(hdc, x, y + 5, nextTextPtr, nextText.length);
    final color = piece.color;

    // Draw the piece in a 4x4 square area
    for (var i = 0; i < 4; i++) {
      for (var j = 0; j < 4; j++) {
        if (piece.isPointExists(i, j)) {
          drawBlock(i + x, j + y, color);
        } else {
          drawBlock(i + x, j + y, RGB(0, 0, 0));
        }
      }
    }

    free(nextTextPtr);
  }
}
