// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Demonstrates usage of various shell APIs to retrieve known folder locations

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

// Get the path of the temporary directory (typically %TEMP%)
String getTemporaryPath() {
  final buffer = wsalloc(MAX_PATH + 1);
  final length = GetTempPath(MAX_PATH, buffer);

  try {
    if (length == 0) {
      final error = GetLastError();
      throw WindowsException(error);
    } else {
      var path = buffer.toDartString();

      // GetTempPath adds a trailing backslash, but SHGetKnownFolderPath does
      // not. Strip off trailing backslash for consistency with other methods
      // here.
      if (path.endsWith('\\')) {
        path = path.substring(0, path.length - 1);
      }
      return path;
    }
  } finally {
    free(buffer);
  }
}

/// Get the path for a known Windows folder, using the classic (deprecated) API
String getDesktopPath1() {
  final path = wsalloc(MAX_PATH);

  try {
    final result = SHGetFolderPath(NULL, CSIDL_DESKTOP, NULL, 0, path);

    if (SUCCEEDED(result)) {
      return path.toDartString();
    } else {
      return 'error code 0x${result.toUnsigned(32).toRadixString(16)}';
    }
  } finally {
    free(path);
  }
}

/// Get the path for a known Windows folder, using the more modern Win32 API
String getDesktopPath2() {
  final appsFolder = GUIDFromString(FOLDERID_Desktop);
  final ppszPath = calloc<PWSTR>();

  try {
    final hr =
        SHGetKnownFolderPath(appsFolder, KF_FLAG_DEFAULT, NULL, ppszPath);

    if (FAILED(hr)) {
      throw WindowsException(hr);
    }

    final path = ppszPath.value.toDartString();
    return path;
  } finally {
    free(appsFolder);
    free(ppszPath);
  }
}

/// Get the path for a known Winodws folder, using the COM API
String getDesktopPath3() {
  final appsFolder = GUIDFromString(FOLDERID_Desktop);
  final ppkf = calloc<COMObject>();
  final ppszPath = calloc<LPWSTR>();

  CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  try {
    final knownFolderManager = KnownFolderManager.createInstance();
    var hr = knownFolderManager.getFolder(appsFolder, ppkf.cast());
    if (FAILED(hr)) {
      throw WindowsException(hr);
    }

    final knownFolder = IKnownFolder(ppkf);
    hr = knownFolder.getPath(0, ppszPath);
    if (FAILED(hr)) {
      throw WindowsException(hr);
    }

    final path = ppszPath.value.toDartString();
    CoUninitialize();
    return path;
  } finally {
    free(appsFolder);
    free(ppkf);
    free(ppszPath);
  }
}

void main() {
  print('Temporary path is ${getTemporaryPath()}\n');
  print('SHGetFolderPath returned ${getDesktopPath1()}');
  print('SHGetKnownFolderPath returned ${getDesktopPath2()}');
  print('IKnownFolder returned ${getDesktopPath3()}');
}
