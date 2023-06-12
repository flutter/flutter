import 'dart:ffi';

import 'package:ffi/ffi.dart';

extension StringUtf8Pointer on String {
  /// Creates a zero-terminated ANSI string pointer from this String. Unlike the
  /// FFI-provided `toNativeUtf8` method, this will always return a single byte
  /// for every character in the original string.
  ///
  /// As a result, this method will not deal with characters that are not in the
  /// Windows codepage, but it will also not give unexpected results when
  /// calling Windows APIs that expect ANSI strings.
  ///
  /// You can use the `toDartString` extension method on `Pointer<Utf8>` to
  /// convert a string created with this function (or returned from a Windows
  /// ANSI function) back to a Dart string.
  ///
  /// Returns an [allocator]-allocated pointer to the result.
  Pointer<Utf8> toANSI({Allocator allocator = malloc}) {
    final pStr = calloc<Uint8>(length + 1);
    for (var i = 0; i < length; i++) {
      pStr[i] = codeUnitAt(i) & 0xFF;
    }
    pStr[length] = 0;
    return pStr.cast();
  }
}
