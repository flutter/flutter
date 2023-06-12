// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: camel_case_types, non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../combase.dart';
import '../../types.dart';
import '../../utils.dart';
import '../../winrt_helpers.dart';
import '../foundation/uri.dart' as winrt_uri;
import 'comobject_pointer.dart';
import 'hstring_array.dart';
import 'int_array.dart';

class VectorHelper<T> {
  const VectorHelper(this.creator, this.enumCreator, this.intType,
      this.getManyCallback, this.length);

  final T Function(Pointer<COMObject>)? creator;
  final T Function(int)? enumCreator;
  final Type? intType;
  final void Function(int, int, Pointer<NativeType>) getManyCallback;
  final int length;

  List<T> toList() {
    // Since the returned list is a fixed-length list, we return it as is.
    if (isSameType<T, int>()) return _toList_int() as List<T>;

    final List<T> list;
    if (isSameType<T, Uri>()) {
      list = _toList_Uri() as List<T>;
    } else if (isSameType<T, String>()) {
      list = _toList_String() as List<T>;
    } else if (isSubtypeOfWinRTEnum<T>()) {
      list = _toList_enum();
    } else {
      list = _toList_COMObject();
    }

    return List.unmodifiable(list);
  }

  List<Uri> _toList_Uri() {
    final pArray = calloc<COMObject>(length);

    try {
      getManyCallback(0, length, pArray);
      return pArray
          .toList(winrt_uri.Uri.fromRawPointer, length: length)
          .map((e) => Uri.parse(e.toString()))
          .toList();
    } finally {
      free(pArray);
    }
  }

  List<String> _toList_String() {
    final pArray = calloc<HSTRING>(length);

    try {
      getManyCallback(0, length, pArray);
      return pArray.toList(length: length);
    } finally {
      free(pArray);
    }
  }

  List<T> _toList_COMObject() {
    final pArray = calloc<COMObject>(length);
    getManyCallback(0, length, pArray);
    return pArray.toList(creator!, length: length);
  }

  List<T> _toList_enum() {
    // The only valid WinRT types for enums are Int32 or UInt32.
    // See https://docs.microsoft.com/en-us/uwp/winrt-cref/winrt-type-system#enums
    switch (intType) {
      case Uint32:
        return _toList_enum_Uint32();
      default:
        return _toList_enum_Int32();
    }
  }

  List<T> _toList_enum_Int32() {
    final pArray = calloc<Int32>(length);

    try {
      getManyCallback(0, length, pArray);
      return pArray.toList(length: length).map((e) => enumCreator!(e)).toList();
    } finally {
      free(pArray);
    }
  }

  List<T> _toList_enum_Uint32() {
    final pArray = calloc<Uint32>(length);

    try {
      getManyCallback(0, length, pArray);
      return pArray.toList(length: length).map((e) => enumCreator!(e)).toList();
    } finally {
      free(pArray);
    }
  }

  List<int> _toList_int() {
    switch (intType) {
      case Int16:
        return _toList_int_Int16();
      case Int64:
        return _toList_int_Int64();
      case Uint8:
        return _toList_int_Uint8();
      case Uint16:
        return _toList_int_Uint16();
      case Uint32:
        return _toList_int_Uint32();
      case Uint64:
        return _toList_int_Uint64();
      default:
        return _toList_int_Int32();
    }
  }

  List<int> _toList_int_Int16() {
    final pArray = calloc<Int16>(length);

    try {
      getManyCallback(0, length, pArray);
      return pArray.toList(length: length);
    } finally {
      free(pArray);
    }
  }

  List<int> _toList_int_Int32() {
    final pArray = calloc<Int32>(length);

    try {
      getManyCallback(0, length, pArray);
      return pArray.toList(length: length);
    } finally {
      free(pArray);
    }
  }

  List<int> _toList_int_Int64() {
    final pArray = calloc<Int64>(length);

    try {
      getManyCallback(0, length, pArray);
      return pArray.toList(length: length);
    } finally {
      free(pArray);
    }
  }

  List<int> _toList_int_Uint8() {
    final pArray = calloc<Uint8>(length);

    try {
      getManyCallback(0, length, pArray);
      return pArray.toList(length: length);
    } finally {
      free(pArray);
    }
  }

  List<int> _toList_int_Uint16() {
    final pArray = calloc<Uint16>(length);

    try {
      getManyCallback(0, length, pArray);
      return pArray.toList(length: length);
    } finally {
      free(pArray);
    }
  }

  List<int> _toList_int_Uint32() {
    final pArray = calloc<Uint32>(length);

    try {
      getManyCallback(0, length, pArray);
      return pArray.toList(length: length);
    } finally {
      free(pArray);
    }
  }

  List<int> _toList_int_Uint64() {
    final pArray = calloc<Uint64>(length);

    try {
      getManyCallback(0, length, pArray);
      return pArray.toList(length: length);
    } finally {
      free(pArray);
    }
  }
}

// WinRT Type system does not support Int8 types.
// See https://docs.microsoft.com/en-us/uwp/winrt-cref/winrt-type-system#fundamental-types
const supportedIntTypes = [Int16, Int32, Int64, Uint8, Uint16, Uint32, Uint64];
