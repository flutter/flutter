import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'package:win32/win32.dart';

void main() {
  final outputHandle = GetStdHandle(STD_OUTPUT_HANDLE);
  print('Output handle (DWORD): $outputHandle');

  final pBufferInfo = calloc<CONSOLE_SCREEN_BUFFER_INFO>();
  final bufferInfo = pBufferInfo.ref;
  GetConsoleScreenBufferInfo(outputHandle, pBufferInfo);
  print('Window dimensions LTRB: (${bufferInfo.srWindow.Left}, '
      '${bufferInfo.srWindow.Top}, ${bufferInfo.srWindow.Right}, '
      '${bufferInfo.srWindow.Bottom})');
  print('Cursor position X/Y: (${bufferInfo.dwCursorPosition.X}, '
      '${bufferInfo.dwCursorPosition.Y})');
  print('Window size X/Y: (${bufferInfo.dwSize.X}, ${bufferInfo.dwSize.Y})');
  print('Maximum window size X/Y: (${bufferInfo.dwMaximumWindowSize.X}, '
      '${bufferInfo.dwMaximumWindowSize.Y})');
  final cursorPosition = calloc<COORD>()
    ..ref.X = 15
    ..ref.Y = 3;

  SetConsoleCursorPosition(outputHandle, cursorPosition.ref);
  GetConsoleScreenBufferInfo(outputHandle, pBufferInfo);
  print('Cursor position X/Y: (${bufferInfo.dwCursorPosition.X}, '
      '${bufferInfo.dwCursorPosition.Y})');

  calloc.free(pBufferInfo);
  calloc.free(cursorPosition);
}
