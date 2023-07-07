// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Maps FFI prototypes onto the corresponding Win32 API function calls

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'callbacks.dart';
import 'combase.dart';
import 'structs.dart';

final _api_ms_win_ro_typeresolution_l1_1_0 =
    DynamicLibrary.open('api-ms-win-ro-typeresolution-l1-1-0.dll');

/// Locates and retrieves the metadata file that describes the Application
/// Binary Interface (ABI) for the specified typename.
///
/// ```c
/// HRESULT RoGetMetaDataFile(
///   const HSTRING        name,
///   IMetaDataDispenserEx *metaDataDispenser,
///   HSTRING              *metaDataFilePath,
///   IMetaDataImport2     **metaDataImport,
///   mdTypeDef            *typeDefToken
/// );
/// ```
/// {@category winrt}
int RoGetMetaDataFile(
        int name,
        Pointer<IntPtr> metaDataDispenser,
        Pointer<IntPtr> metaDataFilePath,
        Pointer<Pointer> metaDataImport,
        Pointer<Uint32> typeDefToken) =>
    _RoGetMetaDataFile(name, metaDataDispenser, metaDataFilePath,
        metaDataImport, typeDefToken);

final _RoGetMetaDataFile = _api_ms_win_ro_typeresolution_l1_1_0.lookupFunction<
    Int32 Function(
        IntPtr name,
        Pointer<IntPtr> metaDataDispenser,
        Pointer<IntPtr> metaDataFilePath,
        Pointer<Pointer> metaDataImport,
        Pointer<Uint32> typeDefToken),
    int Function(
        int name,
        Pointer<IntPtr> metaDataDispenser,
        Pointer<IntPtr> metaDataFilePath,
        Pointer<Pointer> metaDataImport,
        Pointer<Uint32> typeDefToken)>('RoGetMetaDataFile');
