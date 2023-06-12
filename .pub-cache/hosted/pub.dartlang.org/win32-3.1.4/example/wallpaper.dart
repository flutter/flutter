// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Shows retrieval of various information from the IDesktopWallpaper interface.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

late DesktopWallpaper wallpaper;

void printWallpaper() {
  final pathPtr = calloc<Pointer<Utf16>>();

  try {
    final hr = wallpaper.getWallpaper(nullptr, pathPtr);

    switch (hr) {
      case S_OK:
        final path = pathPtr.value.toDartString();
        print(
            path.isEmpty ? 'No wallpaper is set.' : 'Wallpaper path is: $path');
        break;

      case S_FALSE:
        print('Different monitors are displaying different wallpapers, or a '
            'slideshow is running.');
        break;

      default:
        throw WindowsException(hr);
    }
  } finally {
    free(pathPtr);
  }
}

void printBackgroundColor() {
  final colorPtr = calloc<COLORREF>();

  try {
    final hr = wallpaper.getBackgroundColor(colorPtr);

    if (SUCCEEDED(hr)) {
      final color = colorPtr.value;
      print('Background color is: RGB(${GetRValue(color)}, '
          '${GetGValue(color)}, ${GetBValue(color)})');
    } else {
      throw WindowsException(hr);
    }
  } finally {
    free(colorPtr);
  }
}

void main() {
  final hr = CoInitializeEx(
      nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);

  if (FAILED(hr)) {
    throw WindowsException(hr);
  }

  wallpaper = DesktopWallpaper.createInstance();

  try {
    printWallpaper();
    printBackgroundColor();
  } finally {
    free(wallpaper.ptr);
    CoUninitialize();
  }
}
