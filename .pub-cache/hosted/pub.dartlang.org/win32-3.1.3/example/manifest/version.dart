import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

void main() {
  final osVersionInfo = calloc<OSVERSIONINFO>()
    ..ref.dwOSVersionInfoSize = sizeOf<OSVERSIONINFO>();

  final result = GetVersionEx(osVersionInfo);
  if (result != 0) {
    print('Windows '
        '${osVersionInfo.ref.dwMajorVersion}.'
        '${osVersionInfo.ref.dwMinorVersion}');
  }

  final isWindows10OrGreater = IsWindows10OrGreater();
  print('IsWindows10OrGreater() reports ${isWindows10OrGreater == TRUE}');

  final isWindowsServer = IsWindowsServer();
  print('IsWindowsServer() reports ${isWindowsServer == TRUE}');
}
