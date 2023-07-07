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

final _api_ms_win_core_sysinfo_l1_2_3 =
    DynamicLibrary.open('api-ms-win-core-sysinfo-l1-2-3.dll');

/// Retrieves the best estimate of the diagonal size of the built-in screen,
/// in inches.
///
/// ```c
/// HRESULT GetIntegratedDisplaySize(
///   double *sizeInInches
/// );
/// ```
/// {@category kernel32}
int GetIntegratedDisplaySize(Pointer<Double> sizeInInches) =>
    _GetIntegratedDisplaySize(sizeInInches);

final _GetIntegratedDisplaySize =
    _api_ms_win_core_sysinfo_l1_2_3.lookupFunction<
        Int32 Function(Pointer<Double> sizeInInches),
        int Function(Pointer<Double> sizeInInches)>('GetIntegratedDisplaySize');
