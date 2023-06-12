// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Establishes whether the context of the running process is running within a
// desktop app container (e.g. a UWP app).

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/winrt.dart';

bool isAppContainer() {
  final phToken = calloc<HANDLE>();
  final tokenInfo = calloc<DWORD>();
  final bytesReturned = calloc<DWORD>();

  try {
    final hProcess = GetCurrentProcess();
    if (OpenProcessToken(hProcess, TOKEN_READ, phToken) == FALSE) {
      print("Error: Couldn't open the process token\n");
    }

    // If the function succeeds, the return value is non-zero.
    if (GetTokenInformation(
            phToken.value,
            TOKEN_INFORMATION_CLASS.TokenIsAppContainer,
            tokenInfo,
            sizeOf<DWORD>(),
            bytesReturned) !=
        FALSE) {
      return tokenInfo.value != 0;
    }
    throw Exception('GetTokenInformation failed.');
  } finally {
    free(phToken);
    free(tokenInfo);
    free(bytesReturned);
  }
}

void main() {
  winrtInitialize();

  print('${!isAppContainer() ? '!' : ''}isAppContainer');

  final userData = UserDataPaths.getDefault();
  final roamingAppData = userData.roamingAppData;
  print('RoamingAppData: $roamingAppData');

  winrtUninitialize();
}
