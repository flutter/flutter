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

final _api_ms_win_core_comm_l1_1_2 =
    DynamicLibrary.open('api-ms-win-core-comm-l1-1-2.dll');

/// Gets an array that contains the well-formed COM ports.
///
/// ```c
/// ULONG GetCommPorts(
///   PULONG lpPortNumbers,
///   ULONG  uPortNumbersCount,
///   PULONG puPortNumbersFound
/// );
/// ```
/// {@category kernel32}
int GetCommPorts(Pointer<Uint32> lpPortNumbers, int uPortNumbersCount,
        Pointer<Uint32> puPortNumbersFound) =>
    _GetCommPorts(lpPortNumbers, uPortNumbersCount, puPortNumbersFound);

final _GetCommPorts = _api_ms_win_core_comm_l1_1_2.lookupFunction<
    Uint32 Function(Pointer<Uint32> lpPortNumbers, Uint32 uPortNumbersCount,
        Pointer<Uint32> puPortNumbersFound),
    int Function(Pointer<Uint32> lpPortNumbers, int uPortNumbersCount,
        Pointer<Uint32> puPortNumbersFound)>('GetCommPorts');
