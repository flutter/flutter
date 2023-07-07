// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Extension method to convert COMObject arrays to List<T>

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../combase.dart';

extension COMObjectPointer on Pointer<COMObject> {
  /// Creates a [List] from `Pointer<COMObject>`.
  ///
  /// [T] must be a `WinRT` type (e.g. `IHostName`, `StorageFile`).
  ///
  /// [creator] must be specified for [T] (e.g. `IHostName.fromRawPointer`,
  /// `StorageFile.fromRawPointer`).
  ///
  /// [length] must not be greater than the number of elements stored inside the
  /// `Pointer<COMObject>`.
  ///
  /// ```dart
  /// final pComObject = ...
  /// final list = pComObject.toList(StorageFile.fromRawPointer, length: 4);
  /// ```
  ///
  /// {@category winrt}
  List<T> toList<T>(T Function(Pointer<COMObject>) creator, {int length = 1}) {
    final list = <T>[];

    for (var i = 0; i < length; i++) {
      final objectPtr = this.elementAt(i);
      if (objectPtr.ref.lpVtbl == nullptr) break;
      // Move each element to a newly allocated pointer so that it can be
      // freed properly.
      final newObjectPtr = calloc<COMObject>()..ref = objectPtr.ref;
      list.add(creator(newObjectPtr));
    }

    return list;
  }
}
