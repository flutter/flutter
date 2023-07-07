import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../utils.dart';

extension SetStringArray on List<String> {
  /// Packs a List of Dart Strings into a native memory block. Each String is
  /// terminated by a null with a double null to represent the end of the list.
  /// The resulting format is that required to write a list of values to the
  /// registry.
  ///
  /// It is the responsibility of the caller to [free] the returned pointer.
  Pointer<Utf16> toWideCharArray() {
    var size = 0;

    // calculate the amount of memory we need to store
    // all of the strings.
    for (final value in this) {
      size += value.length + 1;
    }

    /// Allow room for a terminating null after last value
    size++;

    final pArray = wsalloc(size);
    final ptr = pArray.cast<Uint16>().asTypedList(size);

    var index = 0;
    for (final value in this) {
      final units = value.codeUnits;

      ptr.setAll(index, units);
      ptr[index + units.length] = 0;

      index += value.length + 1;
    }
    ptr[index] = 0;

    return pArray;
  }
}
