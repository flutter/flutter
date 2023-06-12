// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Demonstrates how to use GetProcAddress to retrieve a raw function pointer and
// call it.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

typedef GetNativeSystemInfoNative = Void Function(
    Pointer<SYSTEM_INFO> lpSystemInfo);
typedef GetNativeSystemInfoDart = void Function(
    Pointer<SYSTEM_INFO> lpSystemInfo);

void main() {
  final systemInfo = calloc<SYSTEM_INFO>();

  final kernel32 = 'kernel32.dll'.toNativeUtf16();
  final hModule = GetModuleHandle(kernel32);
  if (hModule == NULL) throw Exception('Could not load kernel32.dll');
  free(kernel32);

  final ansi = 'GetNativeSystemInfo'.toANSI();
  final pGetNativeSystemInfo = GetProcAddress(hModule, ansi);
  free(ansi);

  if (pGetNativeSystemInfo != nullptr) {
    print('GetNativeSystemInfo() is available on this system.');
    final funcGetNativeSystemInfo = pGetNativeSystemInfo
        .cast<NativeFunction<GetNativeSystemInfoNative>>()
        .asFunction<GetNativeSystemInfoDart>();

    funcGetNativeSystemInfo(systemInfo);
  } else {
    print('GetNativeSystemInfo() not available on this system. '
        'Falling back to GetSystemInfo().');

    GetSystemInfo(systemInfo);
  }

  print('This system has ${systemInfo.ref.dwNumberOfProcessors} processors.');
}
