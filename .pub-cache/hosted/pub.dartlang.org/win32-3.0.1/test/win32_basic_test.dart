@TestOn('windows')

import 'package:test/test.dart';

import 'package:win32/win32.dart';

void main() {
  test('Successful GetModuleHandle', () {
    final hModule = GetModuleHandle(TEXT('kernel32.dll'));
    expect(hModule, isNot(NULL));
  });

  test('Failed GetModuleHandle', () {
    final hModule = GetModuleHandle(TEXT('kernel33_fake_not_a_real.dll'));
    expect(hModule, equals(NULL));
  });

  test('Successful GetProcAddress', () {
    final hModule = GetModuleHandle(TEXT('kernel32.dll'));

    final ansi = 'Beep'.toANSI();
    final pGetNativeSystemInfo = GetProcAddress(hModule, ansi);
    expect(pGetNativeSystemInfo.address, isNonZero);
    free(ansi);
  });

  test('Successful GetCurrentProcess', () {
    // In all current versions of Windows, this returns -1. In theory, a future
    // version of Windows could change this value. This is a pseudo-handle, and
    // so CloseHandle is not required.
    final hProcess = GetCurrentProcess();

    expect(hProcess, equals(-1));
  });
}
