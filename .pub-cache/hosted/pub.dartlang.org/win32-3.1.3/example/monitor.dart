// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Shows retrieval of various information from the high-level monitor
// configuration API.

// Some examples of output:
//
// 1) two physical monitors connected in extended mode
// ```
// C:\src\win32> dart example\monitor.dart
// Number of monitors: 2
// Primary monitor handle: 132205
// Number of physical monitors: 1
// Physical monitor handle: 0
// Physical monitor description: Generic PnP Monitor
// Capabilities:
//  - Supports technology type functions
//  - Supports brightness functions
//  - Supports contrast functions
// Brightness: minimum(0), current(75), maximum(100)
// ```
//
// 2) a single LCD monitor that does not support DDC
// ```
// C:\src\win32> dart example\monitor.dart
// Number of monitors: 1
// Primary monitor handle: 1312117
// Number of physical monitors: 1
// Physical monitor handle: 0
// Physical monitor description: LCD 1366x768
// Monitor does not support DDC/CI.
// ```
//
// 3) connected via SSH to a remote machine
// ```
// C:\src\win32> dart example\monitor.dart
// Number of monitors: 1
// Primary monitor handle: 65537
// No physical monitors attached.
// ```

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

final monitors = <int>[];

int enumMonitorCallback(int hMonitor, int hDC, Pointer lpRect, int lParam) {
  monitors.add(hMonitor);
  return TRUE;
}

bool testBitmask(int bitmask, int value) => bitmask & value == value;

int findPrimaryMonitor(List<int> monitors) {
  final monitorInfo = calloc<MONITORINFO>()..ref.cbSize = sizeOf<MONITORINFO>();

  for (final monitor in monitors) {
    final result = GetMonitorInfo(monitor, monitorInfo);
    if (result == TRUE) {
      if (testBitmask(monitorInfo.ref.dwFlags, MONITORINFOF_PRIMARY)) {
        free(monitorInfo);
        return monitor;
      }
    }
  }

  free(monitorInfo);
  return 0;
}

void printMonitorCapabilities(int capabilitiesBitmask) {
  if (capabilitiesBitmask == MC_CAPS_NONE) {
    print(' - No capabilities supported');
  }
  if (testBitmask(capabilitiesBitmask, MC_CAPS_MONITOR_TECHNOLOGY_TYPE)) {
    print(' - Supports technology type functions');
  }
  if (testBitmask(capabilitiesBitmask, MC_CAPS_BRIGHTNESS)) {
    print(' - Supports brightness functions');
  }
  if (testBitmask(capabilitiesBitmask, MC_CAPS_CONTRAST)) {
    print(' - Supports contrast functions');
  }
  if (testBitmask(capabilitiesBitmask, MC_CAPS_COLOR_TEMPERATURE)) {
    print(' - Supports color temperature functions');
  }
}

void main() {
  var result = FALSE;

  result = EnumDisplayMonitors(
      NULL, // all displays
      nullptr, // no clipping region
      Pointer.fromFunction<MonitorEnumProc>(
          enumMonitorCallback, // dwData
          0),
      NULL);
  if (result == FALSE) {
    throw WindowsException(result);
  }

  print('Number of monitors: ${monitors.length}');

  final primaryMonitorHandle = findPrimaryMonitor(monitors);
  print('Primary monitor handle: $primaryMonitorHandle');

  final physicalMonitorCountPtr = calloc<DWORD>();
  result = GetNumberOfPhysicalMonitorsFromHMONITOR(
      primaryMonitorHandle, physicalMonitorCountPtr);
  if (result == FALSE) {
    print('No physical monitors attached.');
    free(physicalMonitorCountPtr);
    return;
  }

  print('Number of physical monitors: ${physicalMonitorCountPtr.value}');

  // We need to allocate space for a PHYSICAL_MONITOR struct for each physical
  // monitor. Each struct comprises a HANDLE and a 128-character UTF-16 array.
  // Since fixed-size arrays are difficult to allocate with Dart FFI at present,
  // and since we only need the first entry, we can manually allocate space of
  // the right size.
  final physicalMonitorArray =
      calloc<PHYSICAL_MONITOR>(physicalMonitorCountPtr.value);

  result = GetPhysicalMonitorsFromHMONITOR(primaryMonitorHandle,
      physicalMonitorCountPtr.value, physicalMonitorArray);
  if (result == FALSE) {
    throw WindowsException(result);
  }
  // Retrieve the monitor handle for the first physical monitor in the returned
  // array.
  final physicalMonitorHandle = physicalMonitorArray.cast<IntPtr>().value;
  print('Physical monitor handle: $physicalMonitorHandle');
  final physicalMonitorDescription = physicalMonitorArray
      .elementAt(sizeOf<IntPtr>())
      .cast<Utf16>()
      .toDartString();
  print('Physical monitor description: $physicalMonitorDescription');

  final monitorCapabilitiesPtr = calloc<DWORD>();
  final monitorColorTemperaturesPtr = calloc<DWORD>();

  result = GetMonitorCapabilities(physicalMonitorHandle, monitorCapabilitiesPtr,
      monitorColorTemperaturesPtr);
  if (result == TRUE) {
    print('Capabilities: ');
    printMonitorCapabilities(monitorCapabilitiesPtr.value);
  } else {
    print('Monitor does not support DDC/CI.');
  }

  final minimumBrightnessPtr = calloc<DWORD>();
  final currentBrightnessPtr = calloc<DWORD>();
  final maximumBrightnessPtr = calloc<DWORD>();
  result = GetMonitorBrightness(physicalMonitorHandle, minimumBrightnessPtr,
      currentBrightnessPtr, maximumBrightnessPtr);
  if (result == TRUE) {
    print('Brightness: minimum(${minimumBrightnessPtr.value}), '
        'current(${currentBrightnessPtr.value}), '
        'maximum(${maximumBrightnessPtr.value})');
  }

  DestroyPhysicalMonitors(physicalMonitorCountPtr.value, physicalMonitorArray);

  // free all the heap-allocated variables
  free(physicalMonitorArray);
  free(physicalMonitorCountPtr);
  free(monitorCapabilitiesPtr);
  free(monitorColorTemperaturesPtr);
  free(minimumBrightnessPtr);
  free(currentBrightnessPtr);
  free(maximumBrightnessPtr);
}
