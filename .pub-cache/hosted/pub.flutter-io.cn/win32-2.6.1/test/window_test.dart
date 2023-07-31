// ignore_for_file: non_constant_identifier_names

@TestOn('windows')

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:test/test.dart';
import 'package:win32/win32.dart';

int MainWindowProc(int hwnd, int uMsg, int wParam, int lParam) =>
    DefWindowProc(hwnd, uMsg, wParam, lParam);

void main() {
  test('GetModuleHandle()', () {
    final outputHandle = GetModuleHandle(nullptr);
    expect(outputHandle, isNot(0));
  });

  test('RegisterClass()', () {
    final hInstance = GetModuleHandle(nullptr);

    final pClassName = 'CLASS_NAME'.toNativeUtf16();

    final wc = calloc<WNDCLASS>()
      ..ref.style = CS_HREDRAW | CS_VREDRAW
      ..ref.lpfnWndProc = Pointer.fromFunction<WindowProc>(MainWindowProc, 0)
      ..ref.hInstance = hInstance
      ..ref.lpszClassName = pClassName
      ..ref.hCursor = LoadCursor(NULL, IDC_ARROW)
      ..ref.hbrBackground = GetStockObject(WHITE_BRUSH);

    try {
      final result = RegisterClass(wc);
      expect(result, isNot(0));
    } finally {
      free(pClassName);
      free(wc);
    }
  });
}
