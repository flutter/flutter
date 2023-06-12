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

final _api_ms_win_shcore_scaling_l1_1_1 =
    DynamicLibrary.open('api-ms-win-shcore-scaling-l1-1-1.dll');

/// Queries the dots per inch (dpi) of a display.
///
/// ```c
/// HRESULT GetDpiForMonitor(
///   HMONITOR         hmonitor,
///   MONITOR_DPI_TYPE dpiType,
///   UINT             *dpiX,
///   UINT             *dpiY
///   );
/// ```
/// {@category user32}
int GetDpiForMonitor(int hmonitor, int dpiType, Pointer<Uint32> dpiX,
        Pointer<Uint32> dpiY) =>
    _GetDpiForMonitor(hmonitor, dpiType, dpiX, dpiY);

final _GetDpiForMonitor = _api_ms_win_shcore_scaling_l1_1_1.lookupFunction<
    Int32 Function(IntPtr hmonitor, Int32 dpiType, Pointer<Uint32> dpiX,
        Pointer<Uint32> dpiY),
    int Function(int hmonitor, int dpiType, Pointer<Uint32> dpiX,
        Pointer<Uint32> dpiY)>('GetDpiForMonitor');

/// Retrieves the dots per inch (dpi) awareness of the specified process.
///
/// ```c
/// HRESULT GetProcessDpiAwareness(
///   HANDLE                hprocess,
///   PROCESS_DPI_AWARENESS *value
/// );
/// ```
/// {@category user32}
int GetProcessDpiAwareness(int hprocess, Pointer<Int32> value) =>
    _GetProcessDpiAwareness(hprocess, value);

final _GetProcessDpiAwareness =
    _api_ms_win_shcore_scaling_l1_1_1.lookupFunction<
        Int32 Function(IntPtr hprocess, Pointer<Int32> value),
        int Function(
            int hprocess, Pointer<Int32> value)>('GetProcessDpiAwareness');

/// Gets the scale factor of a specific monitor.
///
/// ```c
/// HRESULT GetScaleFactorForMonitor(
///   HMONITOR            hMon,
///   DEVICE_SCALE_FACTOR *pScale
/// );
/// ```
/// {@category user32}
int GetScaleFactorForMonitor(int hMon, Pointer<Int32> pScale) =>
    _GetScaleFactorForMonitor(hMon, pScale);

final _GetScaleFactorForMonitor =
    _api_ms_win_shcore_scaling_l1_1_1.lookupFunction<
        Int32 Function(IntPtr hMon, Pointer<Int32> pScale),
        int Function(
            int hMon, Pointer<Int32> pScale)>('GetScaleFactorForMonitor');

/// Sets the process-default DPI awareness level. This is equivalent to
/// calling SetProcessDpiAwarenessContext with the corresponding
/// DPI_AWARENESS_CONTEXT value.
///
/// ```c
/// HRESULT SetProcessDpiAwareness(
///   PROCESS_DPI_AWARENESS value
/// );
/// ```
/// {@category user32}
int SetProcessDpiAwareness(int value) => _SetProcessDpiAwareness(value);

final _SetProcessDpiAwareness = _api_ms_win_shcore_scaling_l1_1_1
    .lookupFunction<Int32 Function(Int32 value), int Function(int value)>(
        'SetProcessDpiAwareness');
