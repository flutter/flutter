@TestOn('windows')

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:test/test.dart';
import 'package:win32/win32.dart';

import '../example/knownfolder.dart';

void main() {
  test('GetStdHandle()', () {
    final outputHandle = GetStdHandle(STD_OUTPUT_HANDLE);
    expect(outputHandle, isNot(INVALID_HANDLE_VALUE));
  });

  test('GetStdHandle() with invalid handle', () {
    final outputHandle = GetStdHandle(0xFFFF);
    expect(outputHandle, equals(INVALID_HANDLE_VALUE));
  });

  test('GetConsoleScreenBufferInfo', () {
    final outputHandle = GetStdHandle(STD_OUTPUT_HANDLE);

    final bufferInfo = calloc<CONSOLE_SCREEN_BUFFER_INFO>();
    final result = GetConsoleScreenBufferInfo(outputHandle, bufferInfo);

    // This will not be supported on a non-interactive console; skip the test if
    // so.
    if (result != FALSE) {
      expect(bufferInfo.ref.dwCursorPosition.X,
          lessThanOrEqualTo(bufferInfo.ref.dwSize.X));
      expect(bufferInfo.ref.dwCursorPosition.Y,
          lessThanOrEqualTo(bufferInfo.ref.dwSize.Y));
    }

    free(bufferInfo);
  });

  test('SHGetKnownFolderPath', () {
    final legacyAPI = getDesktopPath1();
    final win32API = getDesktopPath2();
    final comAPI = getDesktopPath3();

    expect(
      comAPI,
      allOf(
        [
          equals(legacyAPI),
          equals(win32API),
          isNot(contains('error')),
        ],
      ),
    );
  });
}
