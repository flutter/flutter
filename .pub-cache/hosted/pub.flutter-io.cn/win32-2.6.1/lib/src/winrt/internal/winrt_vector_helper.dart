// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../combase.dart';
import '../../extensions/comobject_pointer.dart';
import '../../extensions/hstring_array.dart';
import '../../types.dart';
import '../../utils.dart';

class VectorHelper<T> {
  const VectorHelper(this.creator, this.getManyCallback, this.length,
      {this.allocator = calloc});

  final Allocator allocator;
  final T Function(Pointer<COMObject>)? creator;
  final void Function(int, Pointer<NativeType>) getManyCallback;
  final int length;

  List<T> toList() {
    switch (T) {
      // TODO: Need to update this once we add support for types like `int`,
      // `bool`, `double`, `GUID`, `DateTime`, `Point`, `Size` etc.
      case String:
        return _toList_String() as List<T>;
      // Handle WinRT types
      default:
        return _toList_COMObject();
    }
  }

  List<String> _toList_String() {
    final pArray = calloc<HSTRING>(length);

    try {
      getManyCallback(0, pArray);

      return pArray.toList(length: length);
    } finally {
      free(pArray);
    }
  }

  List<T> _toList_COMObject() {
    final pArray = allocator<COMObject>(length);
    getManyCallback(0, pArray);

    return pArray.toList(creator!, length: length);
  }
}
