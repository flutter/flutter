// Trivial example showing Win32 common dialog box invocation.

// More sophisticated examples can be found in the `example\` subdirectory
// of this package.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

// Convert from Win32 0x00BBGGRR color layout to a user-friendly string
String toHexColor(int color) => '0x'
    '${GetRValue(color).toRadixString(16).padLeft(2, '0')}'
    '${GetGValue(color).toRadixString(16).padLeft(2, '0')}'
    '${GetBValue(color).toRadixString(16).padLeft(2, '0')}';

void main() {
  // Allocates memory on the native heap for the struct that will be used to
  // configure the dialog box and return values
  final cc = calloc<CHOOSECOLOR>()..ref.lStructSize = sizeOf<CHOOSECOLOR>();
  final custColors = calloc<Uint32>(16);

  // Default color is mid-gray
  cc.ref.rgbResult = RGB(0x80, 0x80, 0x80);

  // Set custom colors to a palette of blues and purples
  // elementAt(x).value dereferences the pointer at addr+x
  for (var i = 0; i < 16; i++) {
    custColors.elementAt(i).value = RGB(i * 16, 0x80, 0xFF);
  }
  cc.ref.lpCustColors = custColors;

  // Set dialog flags:
  //   CC_RGBINIT: use rgbResult for the dialog default value
  //   CC_FULLOPEN: automatically open custom colors section of dialog
  cc.ref.Flags = CC_RGBINIT | CC_FULLOPEN;

  // Call the Win32 API to show dialog, passing pointer to the config struct
  ChooseColor(cc);

  // Print the value returned from the dialog box
  print('Color chosen: ${toHexColor(cc.ref.rgbResult)}');

  // Free the memory allocated on the native heap
  free(custColors);
  free(cc);
}
