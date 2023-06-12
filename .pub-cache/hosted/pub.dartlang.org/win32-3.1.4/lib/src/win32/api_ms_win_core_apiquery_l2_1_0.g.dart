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

final _api_ms_win_core_apiquery_l2_1_0 =
    DynamicLibrary.open('api-ms-win-core-apiquery-l2-1-0.dll');

/// The IsApiSetImplemented function tests if a specified API set is present
/// on the computer.
///
/// ```c
/// BOOL IsApiSetImplemented(
///   PCSTR Contract
/// );
/// ```
/// {@category onecore}
int IsApiSetImplemented(Pointer<Utf8> Contract) =>
    _IsApiSetImplemented(Contract);

final _IsApiSetImplemented = _api_ms_win_core_apiquery_l2_1_0.lookupFunction<
    Int32 Function(Pointer<Utf8> Contract),
    int Function(Pointer<Utf8> Contract)>('IsApiSetImplemented');
