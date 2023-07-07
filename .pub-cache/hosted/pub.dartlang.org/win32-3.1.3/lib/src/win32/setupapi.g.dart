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

final _setupapi = DynamicLibrary.open('setupapi.dll');

/// The SetupDiDestroyDeviceInfoList function deletes a device information
/// set and frees all associated memory.
///
/// ```c
/// BOOL SetupDiDestroyDeviceInfoList(
///   HDEVINFO DeviceInfoSet
/// );
/// ```
/// {@category setupapi}
int SetupDiDestroyDeviceInfoList(int DeviceInfoSet) =>
    _SetupDiDestroyDeviceInfoList(DeviceInfoSet);

final _SetupDiDestroyDeviceInfoList = _setupapi.lookupFunction<
    Int32 Function(IntPtr DeviceInfoSet),
    int Function(int DeviceInfoSet)>('SetupDiDestroyDeviceInfoList');

/// The SetupDiEnumDeviceInfo function returns a SP_DEVINFO_DATA structure
/// that specifies a device information element in a device information set.
///
/// ```c
/// BOOL SetupDiEnumDeviceInfo(
///   HDEVINFO         DeviceInfoSet,
///   DWORD            MemberIndex,
///   PSP_DEVINFO_DATA DeviceInfoData
/// );
/// ```
/// {@category setupapi}
int SetupDiEnumDeviceInfo(int DeviceInfoSet, int MemberIndex,
        Pointer<SP_DEVINFO_DATA> DeviceInfoData) =>
    _SetupDiEnumDeviceInfo(DeviceInfoSet, MemberIndex, DeviceInfoData);

final _SetupDiEnumDeviceInfo = _setupapi.lookupFunction<
    Int32 Function(IntPtr DeviceInfoSet, Uint32 MemberIndex,
        Pointer<SP_DEVINFO_DATA> DeviceInfoData),
    int Function(int DeviceInfoSet, int MemberIndex,
        Pointer<SP_DEVINFO_DATA> DeviceInfoData)>('SetupDiEnumDeviceInfo');

/// The SetupDiEnumDeviceInterfaces function enumerates the device
/// interfaces that are contained in a device information set.
///
/// ```c
/// BOOL SetupDiEnumDeviceInterfaces(
///   [in]           HDEVINFO                  DeviceInfoSet,
///   [in, optional] PSP_DEVINFO_DATA          DeviceInfoData,
///   [in]           const GUID                *InterfaceClassGuid,
///   [in]           DWORD                     MemberIndex,
///   [out]          PSP_DEVICE_INTERFACE_DATA DeviceInterfaceData
/// );
/// ```
/// {@category setupapi}
int SetupDiEnumDeviceInterfaces(
        int DeviceInfoSet,
        Pointer<SP_DEVINFO_DATA> DeviceInfoData,
        Pointer<GUID> InterfaceClassGuid,
        int MemberIndex,
        Pointer<SP_DEVICE_INTERFACE_DATA> DeviceInterfaceData) =>
    _SetupDiEnumDeviceInterfaces(DeviceInfoSet, DeviceInfoData,
        InterfaceClassGuid, MemberIndex, DeviceInterfaceData);

final _SetupDiEnumDeviceInterfaces = _setupapi.lookupFunction<
        Int32 Function(
            IntPtr DeviceInfoSet,
            Pointer<SP_DEVINFO_DATA> DeviceInfoData,
            Pointer<GUID> InterfaceClassGuid,
            Uint32 MemberIndex,
            Pointer<SP_DEVICE_INTERFACE_DATA> DeviceInterfaceData),
        int Function(
            int DeviceInfoSet,
            Pointer<SP_DEVINFO_DATA> DeviceInfoData,
            Pointer<GUID> InterfaceClassGuid,
            int MemberIndex,
            Pointer<SP_DEVICE_INTERFACE_DATA> DeviceInterfaceData)>(
    'SetupDiEnumDeviceInterfaces');

/// The SetupDiGetClassDevs function returns a handle to a device
/// information set that contains requested device information elements for
/// a local computer.
///
/// ```c
/// HDEVINFO SetupDiGetClassDevsW(
///   const GUID *ClassGuid,
///   PCWSTR     Enumerator,
///   HWND       hwndParent,
///   DWORD      Flags
/// );
/// ```
/// {@category setupapi}
int SetupDiGetClassDevs(Pointer<GUID> ClassGuid, Pointer<Utf16> Enumerator,
        int hwndParent, int Flags) =>
    _SetupDiGetClassDevs(ClassGuid, Enumerator, hwndParent, Flags);

final _SetupDiGetClassDevs = _setupapi.lookupFunction<
    IntPtr Function(Pointer<GUID> ClassGuid, Pointer<Utf16> Enumerator,
        IntPtr hwndParent, Uint32 Flags),
    int Function(Pointer<GUID> ClassGuid, Pointer<Utf16> Enumerator,
        int hwndParent, int Flags)>('SetupDiGetClassDevsW');

/// The SetupDiGetDeviceInstanceId function retrieves the device instance ID
/// that is associated with a device information element.
///
/// ```c
/// BOOL SetupDiGetDeviceInstanceIdW(
///   [in]            HDEVINFO         DeviceInfoSet,
///   [in]            PSP_DEVINFO_DATA DeviceInfoData,
///   [out, optional] PWSTR            DeviceInstanceId,
///   [in]            DWORD            DeviceInstanceIdSize,
///   [out, optional] PDWORD           RequiredSize
/// );
/// ```
/// {@category setupapi}
int SetupDiGetDeviceInstanceId(
        int DeviceInfoSet,
        Pointer<SP_DEVINFO_DATA> DeviceInfoData,
        Pointer<Utf16> DeviceInstanceId,
        int DeviceInstanceIdSize,
        Pointer<Uint32> RequiredSize) =>
    _SetupDiGetDeviceInstanceId(DeviceInfoSet, DeviceInfoData, DeviceInstanceId,
        DeviceInstanceIdSize, RequiredSize);

final _SetupDiGetDeviceInstanceId = _setupapi.lookupFunction<
    Int32 Function(
        IntPtr DeviceInfoSet,
        Pointer<SP_DEVINFO_DATA> DeviceInfoData,
        Pointer<Utf16> DeviceInstanceId,
        Uint32 DeviceInstanceIdSize,
        Pointer<Uint32> RequiredSize),
    int Function(
        int DeviceInfoSet,
        Pointer<SP_DEVINFO_DATA> DeviceInfoData,
        Pointer<Utf16> DeviceInstanceId,
        int DeviceInstanceIdSize,
        Pointer<Uint32> RequiredSize)>('SetupDiGetDeviceInstanceIdW');

/// The SetupDiGetDeviceInterfaceDetail function returns details about a
/// device interface.
///
/// ```c
/// BOOL SetupDiGetDeviceInterfaceDetailW(
///   [in]            HDEVINFO                           DeviceInfoSet,
///   [in]            PSP_DEVICE_INTERFACE_DATA          DeviceInterfaceData,
///   [out, optional] PSP_DEVICE_INTERFACE_DETAIL_DATA_W DeviceInterfaceDetailData,
///   [in]            DWORD                              DeviceInterfaceDetailDataSize,
///   [out, optional] PDWORD                             RequiredSize,
///   [out, optional] PSP_DEVINFO_DATA                   DeviceInfoData
/// );
/// ```
/// {@category setupapi}
int SetupDiGetDeviceInterfaceDetail(
        int DeviceInfoSet,
        Pointer<SP_DEVICE_INTERFACE_DATA> DeviceInterfaceData,
        Pointer<SP_DEVICE_INTERFACE_DETAIL_DATA_> DeviceInterfaceDetailData,
        int DeviceInterfaceDetailDataSize,
        Pointer<Uint32> RequiredSize,
        Pointer<SP_DEVINFO_DATA> DeviceInfoData) =>
    _SetupDiGetDeviceInterfaceDetail(
        DeviceInfoSet,
        DeviceInterfaceData,
        DeviceInterfaceDetailData,
        DeviceInterfaceDetailDataSize,
        RequiredSize,
        DeviceInfoData);

final _SetupDiGetDeviceInterfaceDetail = _setupapi.lookupFunction<
        Int32 Function(
            IntPtr DeviceInfoSet,
            Pointer<SP_DEVICE_INTERFACE_DATA> DeviceInterfaceData,
            Pointer<SP_DEVICE_INTERFACE_DETAIL_DATA_> DeviceInterfaceDetailData,
            Uint32 DeviceInterfaceDetailDataSize,
            Pointer<Uint32> RequiredSize,
            Pointer<SP_DEVINFO_DATA> DeviceInfoData),
        int Function(
            int DeviceInfoSet,
            Pointer<SP_DEVICE_INTERFACE_DATA> DeviceInterfaceData,
            Pointer<SP_DEVICE_INTERFACE_DETAIL_DATA_> DeviceInterfaceDetailData,
            int DeviceInterfaceDetailDataSize,
            Pointer<Uint32> RequiredSize,
            Pointer<SP_DEVINFO_DATA> DeviceInfoData)>(
    'SetupDiGetDeviceInterfaceDetailW');

/// The SetupDiGetDeviceRegistryProperty function retrieves a specified Plug
/// and Play device property.
///
/// ```c
/// BOOL SetupDiGetDeviceRegistryPropertyW(
///   [in]            HDEVINFO         DeviceInfoSet,
///   [in]            PSP_DEVINFO_DATA DeviceInfoData,
///   [in]            DWORD            Property,
///   [out, optional] PDWORD           PropertyRegDataType,
///   [out, optional] PBYTE            PropertyBuffer,
///   [in]            DWORD            PropertyBufferSize,
///  [out, optional] PDWORD           RequiredSize
/// );
/// ```
/// {@category setupapi}
int SetupDiGetDeviceRegistryProperty(
        int DeviceInfoSet,
        Pointer<SP_DEVINFO_DATA> DeviceInfoData,
        int Property,
        Pointer<Uint32> PropertyRegDataType,
        Pointer<Uint8> PropertyBuffer,
        int PropertyBufferSize,
        Pointer<Uint32> RequiredSize) =>
    _SetupDiGetDeviceRegistryProperty(DeviceInfoSet, DeviceInfoData, Property,
        PropertyRegDataType, PropertyBuffer, PropertyBufferSize, RequiredSize);

final _SetupDiGetDeviceRegistryProperty = _setupapi.lookupFunction<
    Int32 Function(
        IntPtr DeviceInfoSet,
        Pointer<SP_DEVINFO_DATA> DeviceInfoData,
        Uint32 Property,
        Pointer<Uint32> PropertyRegDataType,
        Pointer<Uint8> PropertyBuffer,
        Uint32 PropertyBufferSize,
        Pointer<Uint32> RequiredSize),
    int Function(
        int DeviceInfoSet,
        Pointer<SP_DEVINFO_DATA> DeviceInfoData,
        int Property,
        Pointer<Uint32> PropertyRegDataType,
        Pointer<Uint8> PropertyBuffer,
        int PropertyBufferSize,
        Pointer<Uint32> RequiredSize)>('SetupDiGetDeviceRegistryPropertyW');

/// The SetupDiOpenDevRegKey function opens a registry key for
/// device-specific configuration information.
///
/// ```c
/// HKEY SetupDiOpenDevRegKey(
///   HDEVINFO         DeviceInfoSet,
///   PSP_DEVINFO_DATA DeviceInfoData,
///   DWORD            Scope,
///   DWORD            HwProfile,
///   DWORD            KeyType,
///   REGSAM           samDesired
/// );
/// ```
/// {@category setupapi}
int SetupDiOpenDevRegKey(
        int DeviceInfoSet,
        Pointer<SP_DEVINFO_DATA> DeviceInfoData,
        int Scope,
        int HwProfile,
        int KeyType,
        int samDesired) =>
    _SetupDiOpenDevRegKey(
        DeviceInfoSet, DeviceInfoData, Scope, HwProfile, KeyType, samDesired);

final _SetupDiOpenDevRegKey = _setupapi.lookupFunction<
    IntPtr Function(
        IntPtr DeviceInfoSet,
        Pointer<SP_DEVINFO_DATA> DeviceInfoData,
        Uint32 Scope,
        Uint32 HwProfile,
        Uint32 KeyType,
        Uint32 samDesired),
    int Function(
        int DeviceInfoSet,
        Pointer<SP_DEVINFO_DATA> DeviceInfoData,
        int Scope,
        int HwProfile,
        int KeyType,
        int samDesired)>('SetupDiOpenDevRegKey');
