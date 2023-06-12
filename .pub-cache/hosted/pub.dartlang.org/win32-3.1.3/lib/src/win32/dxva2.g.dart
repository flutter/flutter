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

final _dxva2 = DynamicLibrary.open('dxva2.dll');

/// Closes a handle to a physical monitor. Call this function to close a
/// monitor handle obtained from the GetPhysicalMonitorsFromHMONITOR or
/// GetPhysicalMonitorsFromIDirect3DDevice9 function.
///
/// ```c
/// _BOOL DestroyPhysicalMonitor(
///   HANDLE hMonitor
/// );
/// ```
/// {@category dxva2}
int DestroyPhysicalMonitor(int hMonitor) => _DestroyPhysicalMonitor(hMonitor);

final _DestroyPhysicalMonitor = _dxva2.lookupFunction<
    Int32 Function(IntPtr hMonitor),
    int Function(int hMonitor)>('DestroyPhysicalMonitor');

/// Closes an array of physical monitor handles. Call this function to close
/// an array of monitor handles obtained from the
/// GetPhysicalMonitorsFromHMONITOR or
/// GetPhysicalMonitorsFromIDirect3DDevice9 function.
///
/// ```c
/// _BOOL DestroyPhysicalMonitors(
///   DWORD              dwPhysicalMonitorArraySize,
///   LPPHYSICAL_MONITOR pPhysicalMonitorArray
/// );
/// ```
/// {@category dxva2}
int DestroyPhysicalMonitors(int dwPhysicalMonitorArraySize,
        Pointer<PHYSICAL_MONITOR> pPhysicalMonitorArray) =>
    _DestroyPhysicalMonitors(dwPhysicalMonitorArraySize, pPhysicalMonitorArray);

final _DestroyPhysicalMonitors = _dxva2.lookupFunction<
        Int32 Function(Uint32 dwPhysicalMonitorArraySize,
            Pointer<PHYSICAL_MONITOR> pPhysicalMonitorArray),
        int Function(int dwPhysicalMonitorArraySize,
            Pointer<PHYSICAL_MONITOR> pPhysicalMonitorArray)>(
    'DestroyPhysicalMonitors');

/// Retrieves a monitor's minimum, maximum, and current brightness settings.
///
/// ```c
/// _BOOL GetMonitorBrightness(
///   HANDLE  hMonitor,
///   LPDWORD pdwMinimumBrightness,
///   LPDWORD pdwCurrentBrightness,
///   LPDWORD pdwMaximumBrightness
/// );
/// ```
/// {@category dxva2}
int GetMonitorBrightness(
        int hMonitor,
        Pointer<Uint32> pdwMinimumBrightness,
        Pointer<Uint32> pdwCurrentBrightness,
        Pointer<Uint32> pdwMaximumBrightness) =>
    _GetMonitorBrightness(hMonitor, pdwMinimumBrightness, pdwCurrentBrightness,
        pdwMaximumBrightness);

final _GetMonitorBrightness = _dxva2.lookupFunction<
    Int32 Function(
        IntPtr hMonitor,
        Pointer<Uint32> pdwMinimumBrightness,
        Pointer<Uint32> pdwCurrentBrightness,
        Pointer<Uint32> pdwMaximumBrightness),
    int Function(
        int hMonitor,
        Pointer<Uint32> pdwMinimumBrightness,
        Pointer<Uint32> pdwCurrentBrightness,
        Pointer<Uint32> pdwMaximumBrightness)>('GetMonitorBrightness');

/// Retrieves the configuration capabilities of a monitor. Call this
/// function to find out which high-level monitor configuration functions
/// are supported by the monitor.
///
/// ```c
/// _BOOL GetMonitorCapabilities(
///   HANDLE  hMonitor,
///   LPDWORD pdwMonitorCapabilities,
///   LPDWORD pdwSupportedColorTemperatures
/// );
/// ```
/// {@category dxva2}
int GetMonitorCapabilities(int hMonitor, Pointer<Uint32> pdwMonitorCapabilities,
        Pointer<Uint32> pdwSupportedColorTemperatures) =>
    _GetMonitorCapabilities(
        hMonitor, pdwMonitorCapabilities, pdwSupportedColorTemperatures);

final _GetMonitorCapabilities = _dxva2.lookupFunction<
        Int32 Function(IntPtr hMonitor, Pointer<Uint32> pdwMonitorCapabilities,
            Pointer<Uint32> pdwSupportedColorTemperatures),
        int Function(int hMonitor, Pointer<Uint32> pdwMonitorCapabilities,
            Pointer<Uint32> pdwSupportedColorTemperatures)>(
    'GetMonitorCapabilities');

/// Retrieves a monitor's current color temperature.
///
/// ```c
/// _BOOL GetMonitorColorTemperature(
///   HANDLE                 hMonitor,
///   LPMC_COLOR_TEMPERATURE pctCurrentColorTemperature
/// );
/// ```
/// {@category dxva2}
int GetMonitorColorTemperature(
        int hMonitor, Pointer<Int32> pctCurrentColorTemperature) =>
    _GetMonitorColorTemperature(hMonitor, pctCurrentColorTemperature);

final _GetMonitorColorTemperature = _dxva2.lookupFunction<
    Int32 Function(IntPtr hMonitor, Pointer<Int32> pctCurrentColorTemperature),
    int Function(
        int hMonitor,
        Pointer<Int32>
            pctCurrentColorTemperature)>('GetMonitorColorTemperature');

/// Retrieves a monitor's minimum, maximum, and current contrast settings.
///
/// ```c
/// _BOOL GetMonitorContrast(
///   HANDLE  hMonitor,
///   LPDWORD pdwMinimumContrast,
///   LPDWORD pdwCurrentContrast,
///   LPDWORD pdwMaximumContrast
/// );
/// ```
/// {@category dxva2}
int GetMonitorContrast(
        int hMonitor,
        Pointer<Uint32> pdwMinimumContrast,
        Pointer<Uint32> pdwCurrentContrast,
        Pointer<Uint32> pdwMaximumContrast) =>
    _GetMonitorContrast(
        hMonitor, pdwMinimumContrast, pdwCurrentContrast, pdwMaximumContrast);

final _GetMonitorContrast = _dxva2.lookupFunction<
    Int32 Function(IntPtr hMonitor, Pointer<Uint32> pdwMinimumContrast,
        Pointer<Uint32> pdwCurrentContrast, Pointer<Uint32> pdwMaximumContrast),
    int Function(
        int hMonitor,
        Pointer<Uint32> pdwMinimumContrast,
        Pointer<Uint32> pdwCurrentContrast,
        Pointer<Uint32> pdwMaximumContrast)>('GetMonitorContrast');

/// Retrieves a monitor's minimum, maximum, and current horizontal or
/// vertical position.
///
/// ```c
/// _BOOL GetMonitorDisplayAreaPosition(
///   HANDLE           hMonitor,
///   MC_POSITION_TYPE ptPositionType,
///   LPDWORD          pdwMinimumPosition,
///   LPDWORD          pdwCurrentPosition,
///   LPDWORD          pdwMaximumPosition
/// );
/// ```
/// {@category dxva2}
int GetMonitorDisplayAreaPosition(
        int hMonitor,
        int ptPositionType,
        Pointer<Uint32> pdwMinimumPosition,
        Pointer<Uint32> pdwCurrentPosition,
        Pointer<Uint32> pdwMaximumPosition) =>
    _GetMonitorDisplayAreaPosition(hMonitor, ptPositionType, pdwMinimumPosition,
        pdwCurrentPosition, pdwMaximumPosition);

final _GetMonitorDisplayAreaPosition = _dxva2.lookupFunction<
    Int32 Function(
        IntPtr hMonitor,
        Int32 ptPositionType,
        Pointer<Uint32> pdwMinimumPosition,
        Pointer<Uint32> pdwCurrentPosition,
        Pointer<Uint32> pdwMaximumPosition),
    int Function(
        int hMonitor,
        int ptPositionType,
        Pointer<Uint32> pdwMinimumPosition,
        Pointer<Uint32> pdwCurrentPosition,
        Pointer<Uint32> pdwMaximumPosition)>('GetMonitorDisplayAreaPosition');

/// Retrieves a monitor's minimum, maximum, and current width or height.
///
/// ```c
/// _BOOL GetMonitorDisplayAreaSize(
///   HANDLE       hMonitor,
///   MC_SIZE_TYPE stSizeType,
///   LPDWORD      pdwMinimumWidthOrHeight,
///   LPDWORD      pdwCurrentWidthOrHeight,
///   LPDWORD      pdwMaximumWidthOrHeight
/// );
/// ```
/// {@category dxva2}
int GetMonitorDisplayAreaSize(
        int hMonitor,
        int stSizeType,
        Pointer<Uint32> pdwMinimumWidthOrHeight,
        Pointer<Uint32> pdwCurrentWidthOrHeight,
        Pointer<Uint32> pdwMaximumWidthOrHeight) =>
    _GetMonitorDisplayAreaSize(hMonitor, stSizeType, pdwMinimumWidthOrHeight,
        pdwCurrentWidthOrHeight, pdwMaximumWidthOrHeight);

final _GetMonitorDisplayAreaSize = _dxva2.lookupFunction<
    Int32 Function(
        IntPtr hMonitor,
        Int32 stSizeType,
        Pointer<Uint32> pdwMinimumWidthOrHeight,
        Pointer<Uint32> pdwCurrentWidthOrHeight,
        Pointer<Uint32> pdwMaximumWidthOrHeight),
    int Function(
        int hMonitor,
        int stSizeType,
        Pointer<Uint32> pdwMinimumWidthOrHeight,
        Pointer<Uint32> pdwCurrentWidthOrHeight,
        Pointer<Uint32> pdwMaximumWidthOrHeight)>('GetMonitorDisplayAreaSize');

/// Retrieves a monitor's red, green, or blue drive value.
///
/// ```c
/// _BOOL GetMonitorRedGreenOrBlueDrive(
///   HANDLE        hMonitor,
///   MC_DRIVE_TYPE dtDriveType,
///   LPDWORD       pdwMinimumDrive,
///   LPDWORD       pdwCurrentDrive,
///   LPDWORD       pdwMaximumDrive
/// );
/// ```
/// {@category dxva2}
int GetMonitorRedGreenOrBlueDrive(
        int hMonitor,
        int dtDriveType,
        Pointer<Uint32> pdwMinimumDrive,
        Pointer<Uint32> pdwCurrentDrive,
        Pointer<Uint32> pdwMaximumDrive) =>
    _GetMonitorRedGreenOrBlueDrive(hMonitor, dtDriveType, pdwMinimumDrive,
        pdwCurrentDrive, pdwMaximumDrive);

final _GetMonitorRedGreenOrBlueDrive = _dxva2.lookupFunction<
    Int32 Function(
        IntPtr hMonitor,
        Int32 dtDriveType,
        Pointer<Uint32> pdwMinimumDrive,
        Pointer<Uint32> pdwCurrentDrive,
        Pointer<Uint32> pdwMaximumDrive),
    int Function(
        int hMonitor,
        int dtDriveType,
        Pointer<Uint32> pdwMinimumDrive,
        Pointer<Uint32> pdwCurrentDrive,
        Pointer<Uint32> pdwMaximumDrive)>('GetMonitorRedGreenOrBlueDrive');

/// Retrieves a monitor's red, green, or blue gain value.
///
/// ```c
/// _BOOL GetMonitorRedGreenOrBlueGain(
///   HANDLE       hMonitor,
///   MC_GAIN_TYPE gtGainType,
///   LPDWORD      pdwMinimumGain,
///   LPDWORD      pdwCurrentGain,
///   LPDWORD      pdwMaximumGain
/// );
/// ```
/// {@category dxva2}
int GetMonitorRedGreenOrBlueGain(
        int hMonitor,
        int gtGainType,
        Pointer<Uint32> pdwMinimumGain,
        Pointer<Uint32> pdwCurrentGain,
        Pointer<Uint32> pdwMaximumGain) =>
    _GetMonitorRedGreenOrBlueGain(
        hMonitor, gtGainType, pdwMinimumGain, pdwCurrentGain, pdwMaximumGain);

final _GetMonitorRedGreenOrBlueGain = _dxva2.lookupFunction<
    Int32 Function(
        IntPtr hMonitor,
        Int32 gtGainType,
        Pointer<Uint32> pdwMinimumGain,
        Pointer<Uint32> pdwCurrentGain,
        Pointer<Uint32> pdwMaximumGain),
    int Function(
        int hMonitor,
        int gtGainType,
        Pointer<Uint32> pdwMinimumGain,
        Pointer<Uint32> pdwCurrentGain,
        Pointer<Uint32> pdwMaximumGain)>('GetMonitorRedGreenOrBlueGain');

/// Retrieves the type of technology used by a monitor.
///
/// ```c
/// _BOOL GetMonitorTechnologyType(
///   HANDLE                       hMonitor,
///   LPMC_DISPLAY_TECHNOLOGY_TYPE pdtyDisplayTechnologyType
/// );
/// ```
/// {@category dxva2}
int GetMonitorTechnologyType(
        int hMonitor, Pointer<Int32> pdtyDisplayTechnologyType) =>
    _GetMonitorTechnologyType(hMonitor, pdtyDisplayTechnologyType);

final _GetMonitorTechnologyType = _dxva2.lookupFunction<
    Int32 Function(IntPtr hMonitor, Pointer<Int32> pdtyDisplayTechnologyType),
    int Function(int hMonitor,
        Pointer<Int32> pdtyDisplayTechnologyType)>('GetMonitorTechnologyType');

/// Retrieves the number of physical monitors associated with an HMONITOR
/// monitor handle. Call this function before calling
/// GetPhysicalMonitorsFromHMONITOR.
///
/// ```c
/// _BOOL GetNumberOfPhysicalMonitorsFromHMONITOR(
///   HMONITOR hMonitor,
///   LPDWORD  pdwNumberOfPhysicalMonitors
/// );
/// ```
/// {@category dxva2}
int GetNumberOfPhysicalMonitorsFromHMONITOR(
        int hMonitor, Pointer<Uint32> pdwNumberOfPhysicalMonitors) =>
    _GetNumberOfPhysicalMonitorsFromHMONITOR(
        hMonitor, pdwNumberOfPhysicalMonitors);

final _GetNumberOfPhysicalMonitorsFromHMONITOR = _dxva2.lookupFunction<
        Int32 Function(
            IntPtr hMonitor, Pointer<Uint32> pdwNumberOfPhysicalMonitors),
        int Function(
            int hMonitor, Pointer<Uint32> pdwNumberOfPhysicalMonitors)>(
    'GetNumberOfPhysicalMonitorsFromHMONITOR');

/// Retrieves the physical monitors associated with an HMONITOR monitor
/// handle.
///
/// ```c
/// _BOOL GetPhysicalMonitorsFromHMONITOR(
///   HMONITOR           hMonitor,
///   DWORD              dwPhysicalMonitorArraySize,
///   LPPHYSICAL_MONITOR pPhysicalMonitorArray
/// );
/// ```
/// {@category dxva2}
int GetPhysicalMonitorsFromHMONITOR(
        int hMonitor,
        int dwPhysicalMonitorArraySize,
        Pointer<PHYSICAL_MONITOR> pPhysicalMonitorArray) =>
    _GetPhysicalMonitorsFromHMONITOR(
        hMonitor, dwPhysicalMonitorArraySize, pPhysicalMonitorArray);

final _GetPhysicalMonitorsFromHMONITOR = _dxva2.lookupFunction<
        Int32 Function(IntPtr hMonitor, Uint32 dwPhysicalMonitorArraySize,
            Pointer<PHYSICAL_MONITOR> pPhysicalMonitorArray),
        int Function(int hMonitor, int dwPhysicalMonitorArraySize,
            Pointer<PHYSICAL_MONITOR> pPhysicalMonitorArray)>(
    'GetPhysicalMonitorsFromHMONITOR');

/// Saves the current monitor settings to the display's nonvolatile storage.
///
/// ```c
/// _BOOL SaveCurrentMonitorSettings(
///   HANDLE hMonitor
/// );
/// ```
/// {@category dxva2}
int SaveCurrentMonitorSettings(int hMonitor) =>
    _SaveCurrentMonitorSettings(hMonitor);

final _SaveCurrentMonitorSettings = _dxva2.lookupFunction<
    Int32 Function(IntPtr hMonitor),
    int Function(int hMonitor)>('SaveCurrentMonitorSettings');

/// Sets a monitor's brightness value. Increasing the brightness value makes
/// the display on the monitor brighter, and decreasing it makes the display
/// dimmer.
///
/// ```c
/// _BOOL SetMonitorBrightness(
///   HANDLE hMonitor,
///   DWORD  dwNewBrightness
/// );
/// ```
/// {@category dxva2}
int SetMonitorBrightness(int hMonitor, int dwNewBrightness) =>
    _SetMonitorBrightness(hMonitor, dwNewBrightness);

final _SetMonitorBrightness = _dxva2.lookupFunction<
    Int32 Function(IntPtr hMonitor, Uint32 dwNewBrightness),
    int Function(int hMonitor, int dwNewBrightness)>('SetMonitorBrightness');

/// Sets a monitor's color temperature.
///
/// ```c
/// _BOOL SetMonitorColorTemperature(
///   HANDLE               hMonitor,
///   MC_COLOR_TEMPERATURE ctCurrentColorTemperature
/// );
/// ```
/// {@category dxva2}
int SetMonitorColorTemperature(int hMonitor, int ctCurrentColorTemperature) =>
    _SetMonitorColorTemperature(hMonitor, ctCurrentColorTemperature);

final _SetMonitorColorTemperature = _dxva2.lookupFunction<
    Int32 Function(IntPtr hMonitor, Int32 ctCurrentColorTemperature),
    int Function(int hMonitor,
        int ctCurrentColorTemperature)>('SetMonitorColorTemperature');

/// Sets a monitor's contrast value.
///
/// ```c
/// _BOOL SetMonitorContrast(
///   HANDLE hMonitor,
///   DWORD  dwNewContrast
/// );
/// ```
/// {@category dxva2}
int SetMonitorContrast(int hMonitor, int dwNewContrast) =>
    _SetMonitorContrast(hMonitor, dwNewContrast);

final _SetMonitorContrast = _dxva2.lookupFunction<
    Int32 Function(IntPtr hMonitor, Uint32 dwNewContrast),
    int Function(int hMonitor, int dwNewContrast)>('SetMonitorContrast');

/// Sets the horizontal or vertical position of a monitor's display area.
/// Increasing the horizontal position moves the display area toward the
/// right side of the screen; decreasing it moves the display area toward
/// the left. Increasing the vertical position moves the display area toward
/// the top of the screen; decreasing it moves the display area toward the
/// bottom.
///
/// ```c
/// _BOOL SetMonitorDisplayAreaPosition(
///   HANDLE           hMonitor,
///   MC_POSITION_TYPE ptPositionType,
///   DWORD            dwNewPosition
/// );
/// ```
/// {@category dxva2}
int SetMonitorDisplayAreaPosition(
        int hMonitor, int ptPositionType, int dwNewPosition) =>
    _SetMonitorDisplayAreaPosition(hMonitor, ptPositionType, dwNewPosition);

final _SetMonitorDisplayAreaPosition = _dxva2.lookupFunction<
    Int32 Function(IntPtr hMonitor, Int32 ptPositionType, Uint32 dwNewPosition),
    int Function(int hMonitor, int ptPositionType,
        int dwNewPosition)>('SetMonitorDisplayAreaPosition');

/// Sets the width or height of a monitor's display area.
///
/// ```c
/// _BOOL SetMonitorDisplayAreaSize(
///   HANDLE       hMonitor,
///   MC_SIZE_TYPE stSizeType,
///   DWORD        dwNewDisplayAreaWidthOrHeight
/// );
/// ```
/// {@category dxva2}
int SetMonitorDisplayAreaSize(
        int hMonitor, int stSizeType, int dwNewDisplayAreaWidthOrHeight) =>
    _SetMonitorDisplayAreaSize(
        hMonitor, stSizeType, dwNewDisplayAreaWidthOrHeight);

final _SetMonitorDisplayAreaSize = _dxva2.lookupFunction<
    Int32 Function(IntPtr hMonitor, Int32 stSizeType,
        Uint32 dwNewDisplayAreaWidthOrHeight),
    int Function(int hMonitor, int stSizeType,
        int dwNewDisplayAreaWidthOrHeight)>('SetMonitorDisplayAreaSize');

/// Sets a monitor's red, green, or blue drive value.
///
/// ```c
/// _BOOL SetMonitorRedGreenOrBlueDrive(
///   HANDLE        hMonitor,
///   MC_DRIVE_TYPE dtDriveType,
///   DWORD         dwNewDrive
/// );
/// ```
/// {@category dxva2}
int SetMonitorRedGreenOrBlueDrive(
        int hMonitor, int dtDriveType, int dwNewDrive) =>
    _SetMonitorRedGreenOrBlueDrive(hMonitor, dtDriveType, dwNewDrive);

final _SetMonitorRedGreenOrBlueDrive = _dxva2.lookupFunction<
    Int32 Function(IntPtr hMonitor, Int32 dtDriveType, Uint32 dwNewDrive),
    int Function(int hMonitor, int dtDriveType,
        int dwNewDrive)>('SetMonitorRedGreenOrBlueDrive');

/// Sets a monitor's red, green, or blue gain value.
///
/// ```c
/// _BOOL SetMonitorRedGreenOrBlueGain(
///   HANDLE       hMonitor,
///   MC_GAIN_TYPE gtGainType,
///   DWORD        dwNewGain
/// );
/// ```
/// {@category dxva2}
int SetMonitorRedGreenOrBlueGain(int hMonitor, int gtGainType, int dwNewGain) =>
    _SetMonitorRedGreenOrBlueGain(hMonitor, gtGainType, dwNewGain);

final _SetMonitorRedGreenOrBlueGain = _dxva2.lookupFunction<
    Int32 Function(IntPtr hMonitor, Int32 gtGainType, Uint32 dwNewGain),
    int Function(int hMonitor, int gtGainType,
        int dwNewGain)>('SetMonitorRedGreenOrBlueGain');
