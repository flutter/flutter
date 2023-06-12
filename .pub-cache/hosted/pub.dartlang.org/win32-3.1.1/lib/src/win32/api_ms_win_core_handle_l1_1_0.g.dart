// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Maps FFI prototypes onto the corresponding Win32 API function calls

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, non_constant_identifier_names
// ignore_for_file: constant_identifier_names, camel_case_types

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../callbacks.dart';
import '../combase.dart';
import '../guid.dart';
import '../structs.g.dart';
import '../variant.dart';

final _api_ms_win_core_handle_l1_1_0 =
    DynamicLibrary.open('api-ms-win-core-handle-l1-1-0.dll');

/// Compares two object handles to determine if they refer to the same
/// underlying kernel object.
///
/// ```c
/// BOOL CompareObjectHandles(
///   HANDLE hFirstObjectHandle,
///   HANDLE hSecondObjectHandle
/// );
/// ```
/// {@category kernel32}
int CompareObjectHandles(int hFirstObjectHandle, int hSecondObjectHandle) =>
    _CompareObjectHandles(hFirstObjectHandle, hSecondObjectHandle);

final _CompareObjectHandles = _api_ms_win_core_handle_l1_1_0.lookupFunction<
    Int32 Function(IntPtr hFirstObjectHandle, IntPtr hSecondObjectHandle),
    int Function(int hFirstObjectHandle,
        int hSecondObjectHandle)>('CompareObjectHandles');
