// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Trivial example showing Win32 common dialog box invocation.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

// Convert from Win32 0x00BBGGRR color layout to a user-friendly string
String toHexColor(int color) => '0x'
    '${GetRValue(color).toRadixString(16).padLeft(2, '0')}'
    '${GetGValue(color).toRadixString(16).padLeft(2, '0')}'
    '${GetBValue(color).toRadixString(16).padLeft(2, '0')}';

void main() {
  // Allocate memory on the native heap for a 16-element array of custom colors,
  // using a palette of blues and purples
  final customColors = calloc<COLORREF>(16);
  for (var i = 0; i < 16; i++) {
    customColors[i] = RGB(i * 16, 0x80, 0xFF);
  }

  // Allocates memory on the native heap for the struct that will be used to
  // configure the dialog box and return values
  final cc = calloc<CHOOSECOLOR>()
    ..ref.lStructSize = sizeOf<CHOOSECOLOR>()

    // Default color is mid-gray
    ..ref.rgbResult = RGB(0x80, 0x80, 0x80)

    // Use custom color palette defined above
    ..ref.lpCustColors = customColors

    // Set dialog flags:
    //   CC_RGBINIT: use rgbResult for the dialog default value
    //   CC_FULLOPEN: automatically open custom colors section of dialog
    ..ref.Flags = CC_RGBINIT | CC_FULLOPEN;

  // Call the Win32 API to show dialog, passing pointer to the config struct
  ChooseColor(cc);

  // Print the value returned from the dialog box
  print('Color chosen was: ${toHexColor(cc.ref.rgbResult)}');

  // Free the memory allocated on the native heap
  free(customColors);
  free(cc);
}
