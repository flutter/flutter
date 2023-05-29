// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Extension methods to convert integer arrays to List<int>

import 'dart:ffi';
import 'dart:typed_data';

extension Uint8Helper on Pointer<Uint8> {
  /// Creates a [List] from `Pointer<Uint8>` by copying the [List] backed by the
  /// native memory to Dart memory so that it's safe to use even after the
  /// memory allocated on the native side is released.
  ///
  /// [length] must not be greater than the number of elements stored inside the
  /// `Pointer<Uint8>`.
  ///
  /// {@category winrt}
  List<int> toList({int length = 1}) =>
      Uint8List.fromList(this.asTypedList(length));
}

extension Int16Helper on Pointer<Int16> {
  /// Creates a [List] from `Pointer<Int16>` by copying the [List] backed by the
  /// native memory to Dart memory so that it's safe to use even after the
  /// memory allocated on the native side is released.
  ///
  /// [length] must not be greater than the number of elements stored inside the
  /// `Pointer<Int16>`.
  ///
  /// {@category winrt}
  List<int> toList({int length = 1}) =>
      Int16List.fromList(this.asTypedList(length));
}

extension UInt16Helper on Pointer<Uint16> {
  /// Creates a [List] from `Pointer<Uint16>` by copying the [List] backed by
  /// the native memory to Dart memory so that it's safe to use even after the
  /// memory allocated on the native side is released.
  ///
  /// [length] must not be greater than the number of elements stored inside the
  /// `Pointer<Uint16>`.
  ///
  /// {@category winrt}
  List<int> toList({int length = 1}) =>
      Uint16List.fromList(this.asTypedList(length));
}

extension Int32Helper on Pointer<Int32> {
  /// Creates a [List] from `Pointer<Int32>` by copying the [List] backed by the
  /// native memory to Dart memory so that it's safe to use even after the
  /// memory allocated on the native side is released.
  ///
  /// [length] must not be greater than the number of elements stored inside the
  /// `Pointer<Int32>`.
  ///
  /// {@category winrt}
  List<int> toList({int length = 1}) =>
      Int32List.fromList(this.asTypedList(length));
}

extension UInt32Helper on Pointer<Uint32> {
  /// Creates a [List] from `Pointer<Uint32>` by copying the [List] backed by
  /// the native memory to Dart memory so that it's safe to use even after the
  /// memory allocated on the native side is released.
  ///
  /// [length] must not be greater than the number of elements stored inside the
  /// `Pointer<Uint32>`.
  ///
  /// {@category winrt}
  List<int> toList({int length = 1}) =>
      Uint32List.fromList(this.asTypedList(length));
}

extension Int64Helper on Pointer<Int64> {
  /// Creates a [List] from `Pointer<Int64>` by copying the [List] backed by the
  /// native memory to Dart memory so that it's safe to use even after the
  /// memory allocated on the native side is released.
  ///
  /// [length] must not be greater than the number of elements stored inside the
  /// `Pointer<Int64>`.
  ///
  /// {@category winrt}
  List<int> toList({int length = 1}) =>
      Int64List.fromList(this.asTypedList(length));
}

extension UInt64Helper on Pointer<Uint64> {
  /// Creates a [List] from `Pointer<Uint64>` by copying the [List] backed by
  /// the native memory to Dart memory so that it's safe to use even after the
  /// memory allocated on the native side is released.
  ///
  /// [length] must not be greater than the number of elements stored inside the
  /// `Pointer<Uint64>`.
  ///
  /// {@category winrt}
  List<int> toList({int length = 1}) =>
      Uint64List.fromList(this.asTypedList(length));
}
