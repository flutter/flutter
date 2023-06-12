// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Extension to write a string to an existing location of memory.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// Sets the memory starting at the pointer location to the string supplied.
///
/// There should already be sufficient allocated memory at the pointer address
/// to avoid a buffer overrun. Returns the number of bytes written.
extension SetString on Pointer<Utf16> {
  int setString(String string) {
    final ptr = cast<Uint16>();

    final units = string.codeUnits;
    final nativeString = ptr.asTypedList(units.length + 1)..setAll(0, units);
    nativeString[units.length] = 0;
    return (units.length + 1) * 2;
  }
}
