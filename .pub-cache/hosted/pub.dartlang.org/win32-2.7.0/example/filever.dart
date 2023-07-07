// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// File version information

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

void main() {
  final lpFilename = TEXT('shell32.dll');

  final fviSize = getVersionBlockSize(lpFilename);

  final pBlock = calloc<BYTE>(fviSize);
  final lpFixedFileVersionInfo = calloc<Pointer>();
  final uLen = calloc<UINT>();
  final subBlock = TEXT(r'\');

  try {
    var result = GetFileVersionInfo(lpFilename, 0, fviSize, pBlock);
    if (result == 0) {
      throw Exception('GetFileVersionInfo failed.');
    }

    result = VerQueryValue(pBlock, subBlock, lpFixedFileVersionInfo, uLen);
    if (result == 0) {
      throw Exception('VerQueryValue failed.');
    }

    final fixedFileVersionInfo =
        lpFixedFileVersionInfo.value.cast<VS_FIXEDFILEINFO>();

    print('Version of shell32.dll: '
        '${HIWORD(fixedFileVersionInfo.ref.dwFileVersionMS)}.'
        '${LOWORD(fixedFileVersionInfo.ref.dwFileVersionMS)}.'
        '${HIWORD(fixedFileVersionInfo.ref.dwFileVersionLS)}.'
        '${LOWORD(fixedFileVersionInfo.ref.dwFileVersionLS)}');
  } finally {
    free(lpFilename);
    free(pBlock);
    free(lpFixedFileVersionInfo);
    free(uLen);
    free(subBlock);
  }
}

int getVersionBlockSize(Pointer<Utf16> lpFilename) {
  int fviSize;

  // dwDummy isn't used; it's a historical vestige.
  final dwDummy = calloc<DWORD>();

  try {
    fviSize = GetFileVersionInfoSize(lpFilename, dwDummy);
    if (fviSize == 0) {
      throw Exception('GetFileVersionInfoSize failed.');
    }

    return fviSize;
  } finally {
    free(dwDummy);
  }
}
