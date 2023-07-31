// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Maps FFI prototypes onto the corresponding Win32 API function calls

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, non_constant_identifier_names
// ignore_for_file: constant_identifier_names, camel_case_types

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'callbacks.dart';
import 'combase.dart';
import 'guid.dart';
import 'structs.dart';
import 'structs.g.dart';

final _kernelbase = DynamicLibrary.open('kernelbase.dll');

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

final _CompareObjectHandles = _kernelbase.lookupFunction<
    Int32 Function(IntPtr hFirstObjectHandle, IntPtr hSecondObjectHandle),
    int Function(int hFirstObjectHandle,
        int hSecondObjectHandle)>('CompareObjectHandles');

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

final _GetCommPorts = _kernelbase.lookupFunction<
    Uint32 Function(Pointer<Uint32> lpPortNumbers, Uint32 uPortNumbersCount,
        Pointer<Uint32> puPortNumbersFound),
    int Function(Pointer<Uint32> lpPortNumbers, int uPortNumbersCount,
        Pointer<Uint32> puPortNumbersFound)>('GetCommPorts');

/// Retrieves the best estimate of the diagonal size of the built-in
/// screen, in inches.
///
/// ```c
/// HRESULT GetIntegratedDisplaySize(
///   double *sizeInInches
/// );
/// ```
/// {@category kernel32}
int GetIntegratedDisplaySize(Pointer<Double> sizeInInches) =>
    _GetIntegratedDisplaySize(sizeInInches);

final _GetIntegratedDisplaySize = _kernelbase.lookupFunction<
    Int32 Function(Pointer<Double> sizeInInches),
    int Function(Pointer<Double> sizeInInches)>('GetIntegratedDisplaySize');

/// Attempts to open a communication device.
///
/// ```c
/// HANDLE OpenCommPort(
///   ULONG uPortNumber,
///   DWORD dwDesiredAccess,
///   DWORD dwFlagsAndAttributes
/// );
/// ```
/// {@category kernel32}
int OpenCommPort(
        int uPortNumber, int dwDesiredAccess, int dwFlagsAndAttributes) =>
    _OpenCommPort(uPortNumber, dwDesiredAccess, dwFlagsAndAttributes);

final _OpenCommPort = _kernelbase.lookupFunction<
    IntPtr Function(Uint32 uPortNumber, Uint32 dwDesiredAccess,
        Uint32 dwFlagsAndAttributes),
    int Function(int uPortNumber, int dwDesiredAccess,
        int dwFlagsAndAttributes)>('OpenCommPort');
