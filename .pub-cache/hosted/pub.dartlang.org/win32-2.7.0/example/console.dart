// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Shows usage of console APIs. For more console examples and a high-level API
// to the underlying Win32 console API, see
// https://pub.dev/packages/dart_console, which provides a platform-independent
// API to the console across Windows, Linux and macOS.

// Sample is an adaptation of:
//   https://docs.microsoft.com/en-us/windows/console/using-the-high-level-input-and-output-functions

import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

const normalPrompt = 'Type a line and press Enter, or q to quit: ';
const echoOffPrompt = 'Type any key, or q to quit: ';

final stdin = GetStdHandle(STD_INPUT_HANDLE);
final stdout = GetStdHandle(STD_OUTPUT_HANDLE);

late Pointer<CONSOLE_SCREEN_BUFFER_INFO> bufferInfo;

/// Convert a byte array pointer into a Dart string
String fromCString(Pointer<Uint8> buffer, int maxLength) =>
    String.fromCharCodes(buffer.asTypedList(maxLength), 0, maxLength);

/// Convert a Dart string to a heap stored byte array that can be passed through
/// FFI to an unmanaged API.
///
/// The returned string is _not_ null-terminated.
Pointer<Uint8> toCString(String buffer) {
  final units = utf8.encode(buffer);
  final result = calloc<Uint8>(units.length);
  result.asTypedList(units.length).setAll(0, units);
  return result;
}

/// The newLine function handles carriage returns when the processed input mode
/// is disabled. It gets the current cursor position and resets it to the first
/// cell of the next row.
void newLine() {
  GetConsoleScreenBufferInfo(stdout, bufferInfo);

  bufferInfo.ref.dwCursorPosition.X = 0;
  if (bufferInfo.ref.dwSize.Y - 1 == bufferInfo.ref.dwCursorPosition.Y) {
    scrollScreenBuffer(stdout, 1);
  } else {
    bufferInfo.ref.dwCursorPosition.Y += 1;
  }

  SetConsoleCursorPosition(stdout, bufferInfo.ref.dwCursorPosition);
}

void scrollScreenBuffer(int handle, int x) {
  final scrollRect = calloc<SMALL_RECT>()
    ..ref.Left = 0
    ..ref.Top = 1
    ..ref.Right = bufferInfo.ref.dwSize.X - x
    ..ref.Bottom = bufferInfo.ref.dwSize.Y - x;

  // The destination for the scroll rectangle is one row up.
  final coordDest = calloc<COORD>()
    ..ref.X = 0
    ..ref.Y = 0;

  final clipRect = scrollRect;

  final fillChar = calloc<CHAR_INFO>()
    ..ref.Attributes = FOREGROUND_RED | FOREGROUND_INTENSITY
    ..ref.UnicodeChar = ' '.codeUnits.first;

  ScrollConsoleScreenBuffer(
      handle, scrollRect, clipRect, coordDest.ref, fillChar);

  free(scrollRect);
  free(coordDest);
  free(fillChar);
}

void main() {
  bufferInfo = calloc<CONSOLE_SCREEN_BUFFER_INFO>();
  GetConsoleScreenBufferInfo(stdout, bufferInfo);

  print('Some console metrics:');
  print('  Window dimensions LTRB: (${bufferInfo.ref.srWindow.Left}, '
      '${bufferInfo.ref.srWindow.Top}, ${bufferInfo.ref.srWindow.Right}, '
      '${bufferInfo.ref.srWindow.Bottom})');
  print('  Cursor position X/Y: (${bufferInfo.ref.dwCursorPosition.X}, '
      '${bufferInfo.ref.dwCursorPosition.Y})');
  print(
      '  Window size X/Y: (${bufferInfo.ref.dwSize.Y}, ${bufferInfo.ref.dwSize.Y})');
  print('  Maximum window size X/Y: (${bufferInfo.ref.dwMaximumWindowSize.X}, '
      '${bufferInfo.ref.dwMaximumWindowSize.Y})\n');

  // Set the text attributes to draw red text on black background.
  final originalAttributes = bufferInfo.ref.wAttributes;
  SetConsoleTextAttribute(stdout, FOREGROUND_RED | FOREGROUND_INTENSITY);

  final cWritten = calloc<DWORD>();
  final buffer = calloc<Uint8>(256);
  final lpNumberOfBytesRead = calloc<DWORD>();

  // Write to STDOUT and read from STDIN by using the default
  // modes. Input is echoed automatically, and ReadFile
  // does not return until a carriage return is typed.
  //
  // The default input modes are line, processed, and echo.
  // The default output modes are processed and wrap at EOL.

  while (true) {
    WriteFile(
        stdout, // output handle
        toCString(normalPrompt), // prompt string
        normalPrompt.length, // string length
        cWritten, // bytes written
        nullptr); // not overlapped
    ReadFile(stdin, buffer, 255, lpNumberOfBytesRead, nullptr);
    final inputString = fromCString(buffer, lpNumberOfBytesRead.value);
    if (inputString.startsWith('q')) {
      break;
    }
  }

  // Turn off the line input and echo input modes
  final originalConsoleMode = calloc<DWORD>();
  GetConsoleMode(stdin, originalConsoleMode);
  final mode =
      originalConsoleMode.value & ~(ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT);
  SetConsoleMode(stdin, mode);

  newLine();

  while (true) {
    WriteFile(stdout, toCString(echoOffPrompt), echoOffPrompt.length, cWritten,
        nullptr);

    // ReadFile returns when any input is available.
    // WriteFile is used to echo input.
    if (ReadFile(stdin, buffer, 1, lpNumberOfBytesRead, nullptr) == 0) break;

    if (String.fromCharCode(buffer.value) == '\r') {
      newLine();
    } else if (WriteFile(
            stdout, buffer, lpNumberOfBytesRead.value, cWritten, nullptr) ==
        0) {
      break;
    } else {
      newLine();
    }

    if (String.fromCharCode(buffer.value) == 'q') {
      break;
    }
  }

  SetConsoleMode(stdin, originalConsoleMode.value);
  SetConsoleTextAttribute(stdout, originalAttributes);

  free(bufferInfo);
  free(cWritten);
  free(buffer);
  free(lpNumberOfBytesRead);
  free(originalConsoleMode);
}
