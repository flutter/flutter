import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'piece.dart';

class Canvas {
  /// Handle to DC
  final int hdc;

  /// Handle to window
  final int hwnd;

  /// Rectangle for drawing. This will last for the lifetime of the app and
  /// memory will be released at app termination.
  final rect = calloc<RECT>();

  /// Level width
  final int width;

  /// Level height
  final int height;

  /// Initiate the drawing canvas
  Canvas(this.hdc, this.hwnd,
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
    rect.ref
      ..left = x
      ..right = x + 1
      ..top = y
      ..bottom = y + 1;

    FillRect(hdc, rect, hBrush);

    // Draw left and bottom black border
    MoveToEx(hdc, x, y + 1, nullptr);
    LineTo(hdc, x, y);
    LineTo(hdc, x + 1, y);
    DeleteObject(hBrush);
  }

  void drawInterface() {
    final hBrush = CreateSolidBrush(RGB(70, 70, 70));
    rect.ref
      ..top = height
      ..left = width
      ..bottom = 0
      ..right = width + 8;
    FillRect(hdc, rect, hBrush);
    DeleteObject(hBrush);
  }

  void drawText(String text, int x, int y) {
    final lpString = text.toNativeUtf16();
    TextOut(hdc, x, y, lpString, text.length);
    free(lpString);
  }

  void drawTextOpaque(String text, int x, int y) {
    SetBkMode(hdc, OPAQUE);
    drawText(text, x, y);
    SetBkMode(hdc, TRANSPARENT);
  }

  void drawScore(int score, int x, int y) =>
      drawTextOpaque('Score: $score', x, y);

  void drawSpeed(int speed, int x, int y) =>
      drawTextOpaque('Speed: $speed', x, y);

  void drawNextPiece(Piece piece, int x, int y) {
    const nextText = 'Next:';

    drawText(nextText, x, y + 5);
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
  }
}
