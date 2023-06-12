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

final _powrprof = DynamicLibrary.open('powrprof.dll');

/// Sets or retrieves power information.
///
/// ```c
/// NTSTATUS CallNtPowerInformation(
///   POWER_INFORMATION_LEVEL InformationLevel,
///   PVOID                   InputBuffer,
///   ULONG                   InputBufferLength,
///   PVOID                   OutputBuffer,
///   ULONG                   OutputBufferLength
/// );
/// ```
/// {@category powrprof}
int CallNtPowerInformation(int InformationLevel, Pointer InputBuffer,
        int InputBufferLength, Pointer OutputBuffer, int OutputBufferLength) =>
    _CallNtPowerInformation(InformationLevel, InputBuffer, InputBufferLength,
        OutputBuffer, OutputBufferLength);

final _CallNtPowerInformation = _powrprof.lookupFunction<
    Int32 Function(
        Int32 InformationLevel,
        Pointer InputBuffer,
        Uint32 InputBufferLength,
        Pointer OutputBuffer,
        Uint32 OutputBufferLength),
    int Function(
        int InformationLevel,
        Pointer InputBuffer,
        int InputBufferLength,
        Pointer OutputBuffer,
        int OutputBufferLength)>('CallNtPowerInformation');
