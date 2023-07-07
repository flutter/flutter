// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Explores the Windows Recycle Bin.

// ignore_for_file: constant_identifier_names

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class RecycleBinInfo {
  final int itemCount;
  final int totalSizeInBytes;

  const RecycleBinInfo(this.itemCount, this.totalSizeInBytes);
}

RecycleBinInfo queryRecycleBin(String rootPath) {
  final pszRootPath = rootPath.toNativeUtf16();
  final pSHQueryRBInfo = calloc<SHQUERYRBINFO>()
    ..ref.cbSize = sizeOf<SHQUERYRBINFO>();

  try {
    final hr = SHQueryRecycleBin(pszRootPath, pSHQueryRBInfo);
    if (hr != S_OK) throw WindowsException(hr);

    return RecycleBinInfo(
        pSHQueryRBInfo.ref.i64NumItems, pSHQueryRBInfo.ref.i64Size);
  } finally {
    free(pszRootPath);
    free(pSHQueryRBInfo);
  }
}

String getTempFileName() {
  final lpPathName = '.'.toNativeUtf16();
  final lpPrefixString = 'dart'.toNativeUtf16();
  final lpTempFileName = wsalloc(MAX_PATH);

  try {
    final result =
        GetTempFileName(lpPathName, lpPrefixString, 0, lpTempFileName);
    if (result == 0) throw 'Unable to create filename';

    return lpTempFileName.toDartString();
  } finally {
    free(lpPathName);
    free(lpPrefixString);
    free(lpTempFileName);
  }
}

bool recycleFile(String file) {
  final hwnd = GetActiveWindow();
  final pFrom = [file].toWideCharArray();
  final lpFileOp = calloc<SHFILEOPSTRUCT>()
    ..ref.hwnd = hwnd
    ..ref.wFunc = FO_DELETE
    ..ref.pFrom = pFrom
    ..ref.pTo = nullptr
    ..ref.fFlags = FOF_ALLOWUNDO;

  try {
    final result = SHFileOperation(lpFileOp);
    return result == 0;
  } finally {
    free(pFrom);
    free(lpFileOp);
  }
}

void main(List<String> args) {
  final info = queryRecycleBin('c:\\');
  print('There are ${info.itemCount} items in the '
      'Recycle Bin on the C: drive.');

  final tempFile = getTempFileName();
  print('Creating temporary file $tempFile');
  File(tempFile)
      .writeAsStringSync('With time involved, everything is temporary.');

  print('Sending temporary file $tempFile to the Recycle Bin.');
  recycleFile(tempFile);

  final newInfo = queryRecycleBin('c:\\');
  print('There now are ${newInfo.itemCount} items in the '
      'Recycle Bin on the C: drive.');
}
