// ioctl.dart
//
// Dart representations of functions and constants used in ioctl.h

import 'dart:ffi';
import 'dart:io';

final TIOCGWINSZ = Platform.isMacOS ? 0x40087468 : 0x5413;

// struct winsize {
// 	unsigned short  ws_row;         /* rows, in characters */
// 	unsigned short  ws_col;         /* columns, in characters */
// 	unsigned short  ws_xpixel;      /* horizontal size, pixels */
// 	unsigned short  ws_ypixel;      /* vertical size, pixels */
// };
class WinSize extends Struct {
  @Int16()
  external int ws_row;

  @Int16()
  external int ws_col;

  @Int16()
  external int ws_xpixel;

  @Int16()
  external int ws_ypixel;
}

// int ioctl(int, unsigned long, ...);
typedef ioctlNative = Int32 Function(Int32, Int64, Pointer<Void>);
typedef ioctlDart = int Function(int, int, Pointer<Void>);
