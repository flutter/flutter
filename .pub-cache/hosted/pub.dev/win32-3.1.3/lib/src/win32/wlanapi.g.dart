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

final _wlanapi = DynamicLibrary.open('wlanapi.dll');

/// The WlanAllocateMemory function allocates memory. Any memory passed to
/// other Native Wifi functions must be allocated with this function.
///
/// ```c
/// PVOID WlanAllocateMemory(
///   DWORD dwMemorySize
/// );
/// ```
/// {@category wlanapi}
Pointer WlanAllocateMemory(int dwMemorySize) =>
    _WlanAllocateMemory(dwMemorySize);

final _WlanAllocateMemory = _wlanapi.lookupFunction<
    Pointer Function(Uint32 dwMemorySize),
    Pointer Function(int dwMemorySize)>('WlanAllocateMemory');

/// The WlanCloseHandle function closes a connection to the server.
///
/// ```c
/// DWORD WlanCloseHandle(
///   HANDLE hClientHandle,
///   PVOID  pReserved
/// );
/// ```
/// {@category wlanapi}
int WlanCloseHandle(int hClientHandle, Pointer pReserved) =>
    _WlanCloseHandle(hClientHandle, pReserved);

final _WlanCloseHandle = _wlanapi.lookupFunction<
    Uint32 Function(IntPtr hClientHandle, Pointer pReserved),
    int Function(int hClientHandle, Pointer pReserved)>('WlanCloseHandle');

/// The WlanConnect function attempts to connect to a specific network.
///
/// ```c
/// DWORD WlanConnect(
///   HANDLE                            hClientHandle,
///   const GUID                        *pInterfaceGuid,
///   const PWLAN_CONNECTION_PARAMETERS pConnectionParameters,
///   PVOID                             pReserved
/// );
/// ```
/// {@category wlanapi}
int WlanConnect(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<WLAN_CONNECTION_PARAMETERS> pConnectionParameters,
        Pointer pReserved) =>
    _WlanConnect(
        hClientHandle, pInterfaceGuid, pConnectionParameters, pReserved);

final _WlanConnect = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<WLAN_CONNECTION_PARAMETERS> pConnectionParameters,
        Pointer pReserved),
    int Function(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<WLAN_CONNECTION_PARAMETERS> pConnectionParameters,
        Pointer pReserved)>('WlanConnect');

/// The WlanDeleteProfile function deletes a wireless profile for a wireless
/// interface on the local computer.
///
/// ```c
/// DWORD WlanDeleteProfile(
///   HANDLE     hClientHandle,
///   const GUID *pInterfaceGuid,
///   LPCWSTR    strProfileName,
///   PVOID      pReserved
/// );
/// ```
/// {@category wlanapi}
int WlanDeleteProfile(int hClientHandle, Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strProfileName, Pointer pReserved) =>
    _WlanDeleteProfile(
        hClientHandle, pInterfaceGuid, strProfileName, pReserved);

final _WlanDeleteProfile = _wlanapi.lookupFunction<
    Uint32 Function(IntPtr hClientHandle, Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strProfileName, Pointer pReserved),
    int Function(int hClientHandle, Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strProfileName, Pointer pReserved)>('WlanDeleteProfile');

/// Allows an original equipment manufacturer (OEM) or independent hardware
/// vendor (IHV) component to communicate with a device service on a
/// particular wireless LAN interface.
///
/// ```c
/// DWORD WlanDeviceServiceCommand(
///   HANDLE     hClientHandle,
///   const GUID *pInterfaceGuid,
///   LPGUID     pDeviceServiceGuid,
///   DWORD      dwOpCode,
///   DWORD      dwInBufferSize,
///   PVOID      pInBuffer,
///   DWORD      dwOutBufferSize,
///   PVOID      pOutBuffer,
///   PDWORD     pdwBytesReturned
/// );
/// ```
/// {@category wlanapi}
int WlanDeviceServiceCommand(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<GUID> pDeviceServiceGuid,
        int dwOpCode,
        int dwInBufferSize,
        Pointer pInBuffer,
        int dwOutBufferSize,
        Pointer pOutBuffer,
        Pointer<Uint32> pdwBytesReturned) =>
    _WlanDeviceServiceCommand(
        hClientHandle,
        pInterfaceGuid,
        pDeviceServiceGuid,
        dwOpCode,
        dwInBufferSize,
        pInBuffer,
        dwOutBufferSize,
        pOutBuffer,
        pdwBytesReturned);

final _WlanDeviceServiceCommand = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<GUID> pDeviceServiceGuid,
        Uint32 dwOpCode,
        Uint32 dwInBufferSize,
        Pointer pInBuffer,
        Uint32 dwOutBufferSize,
        Pointer pOutBuffer,
        Pointer<Uint32> pdwBytesReturned),
    int Function(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<GUID> pDeviceServiceGuid,
        int dwOpCode,
        int dwInBufferSize,
        Pointer pInBuffer,
        int dwOutBufferSize,
        Pointer pOutBuffer,
        Pointer<Uint32> pdwBytesReturned)>('WlanDeviceServiceCommand');

/// The WlanDisconnect function disconnects an interface from its current
/// network.
///
/// ```c
/// DWORD WlanDisconnect(
///   HANDLE     hClientHandle,
///   const GUID *pInterfaceGuid,
///   PVOID      pReserved
/// );
/// ```
/// {@category wlanapi}
int WlanDisconnect(
        int hClientHandle, Pointer<GUID> pInterfaceGuid, Pointer pReserved) =>
    _WlanDisconnect(hClientHandle, pInterfaceGuid, pReserved);

final _WlanDisconnect = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle, Pointer<GUID> pInterfaceGuid, Pointer pReserved),
    int Function(int hClientHandle, Pointer<GUID> pInterfaceGuid,
        Pointer pReserved)>('WlanDisconnect');

/// The WlanEnumInterfaces function enumerates all of the wireless LAN
/// interfaces currently enabled on the local computer.
///
/// ```c
/// DWORD WlanEnumInterfaces(
///   HANDLE                    hClientHandle,
///   PVOID                     pReserved,
///   PWLAN_INTERFACE_INFO_LIST *ppInterfaceList
/// );
/// ```
/// {@category wlanapi}
int WlanEnumInterfaces(int hClientHandle, Pointer pReserved,
        Pointer<Pointer<WLAN_INTERFACE_INFO_LIST>> ppInterfaceList) =>
    _WlanEnumInterfaces(hClientHandle, pReserved, ppInterfaceList);

final _WlanEnumInterfaces = _wlanapi.lookupFunction<
        Uint32 Function(IntPtr hClientHandle, Pointer pReserved,
            Pointer<Pointer<WLAN_INTERFACE_INFO_LIST>> ppInterfaceList),
        int Function(int hClientHandle, Pointer pReserved,
            Pointer<Pointer<WLAN_INTERFACE_INFO_LIST>> ppInterfaceList)>(
    'WlanEnumInterfaces');

/// The WlanExtractPsdIEDataList function extracts the proximity service
/// discovery (PSD) information element (IE) data list from raw IE data
/// included in a beacon.
///
/// ```c
/// DWORD WlanExtractPsdIEDataList(
///   HANDLE              hClientHandle,
///   DWORD               dwIeDataSize,
///   const PBYTE         pRawIeData,
///   LPCWSTR             strFormat,
///   PVOID               pReserved,
///   PWLAN_RAW_DATA_LIST *ppPsdIEDataList
/// );
/// ```
/// {@category wlanapi}
int WlanExtractPsdIEDataList(
        int hClientHandle,
        int dwIeDataSize,
        Pointer<Uint8> pRawIeData,
        Pointer<Utf16> strFormat,
        Pointer pReserved,
        Pointer<Pointer<WLAN_RAW_DATA_LIST>> ppPsdIEDataList) =>
    _WlanExtractPsdIEDataList(hClientHandle, dwIeDataSize, pRawIeData,
        strFormat, pReserved, ppPsdIEDataList);

final _WlanExtractPsdIEDataList = _wlanapi.lookupFunction<
        Uint32 Function(
            IntPtr hClientHandle,
            Uint32 dwIeDataSize,
            Pointer<Uint8> pRawIeData,
            Pointer<Utf16> strFormat,
            Pointer pReserved,
            Pointer<Pointer<WLAN_RAW_DATA_LIST>> ppPsdIEDataList),
        int Function(
            int hClientHandle,
            int dwIeDataSize,
            Pointer<Uint8> pRawIeData,
            Pointer<Utf16> strFormat,
            Pointer pReserved,
            Pointer<Pointer<WLAN_RAW_DATA_LIST>> ppPsdIEDataList)>(
    'WlanExtractPsdIEDataList');

/// The WlanFreeMemory function frees memory. Any memory returned from
/// Native Wifi functions must be freed.
///
/// ```c
/// void WlanFreeMemory(
///   PVOID pMemory
/// );
/// ```
/// {@category wlanapi}
void WlanFreeMemory(Pointer pMemory) => _WlanFreeMemory(pMemory);

final _WlanFreeMemory = _wlanapi.lookupFunction<Void Function(Pointer pMemory),
    void Function(Pointer pMemory)>('WlanFreeMemory');

/// The WlanGetAvailableNetworkList function retrieves the list of available
/// networks on a wireless LAN interface.
///
/// ```c
/// DWORD WlanGetAvailableNetworkList(
///   HANDLE                       hClientHandle,
///   const GUID                   *pInterfaceGuid,
///   DWORD                        dwFlags,
///   PVOID                        pReserved,
///   PWLAN_AVAILABLE_NETWORK_LIST *ppAvailableNetworkList
/// );
/// ```
/// {@category wlanapi}
int WlanGetAvailableNetworkList(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        int dwFlags,
        Pointer pReserved,
        Pointer<Pointer<WLAN_AVAILABLE_NETWORK_LIST>> ppAvailableNetworkList) =>
    _WlanGetAvailableNetworkList(hClientHandle, pInterfaceGuid, dwFlags,
        pReserved, ppAvailableNetworkList);

final _WlanGetAvailableNetworkList = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Uint32 dwFlags,
        Pointer pReserved,
        Pointer<Pointer<WLAN_AVAILABLE_NETWORK_LIST>> ppAvailableNetworkList),
    int Function(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        int dwFlags,
        Pointer pReserved,
        Pointer<Pointer<WLAN_AVAILABLE_NETWORK_LIST>>
            ppAvailableNetworkList)>('WlanGetAvailableNetworkList');

/// The WlanGetFilterList function retrieves a group policy or user
/// permission list.
///
/// ```c
/// DWORD WlanGetFilterList(
///   HANDLE                hClientHandle,
///   WLAN_FILTER_LIST_TYPE wlanFilterListType,
///   PVOID                 pReserved,
///   PDOT11_NETWORK_LIST   *ppNetworkList
/// );
/// ```
/// {@category wlanapi}
int WlanGetFilterList(
        int hClientHandle,
        int wlanFilterListType,
        Pointer pReserved,
        Pointer<Pointer<DOT11_NETWORK_LIST>> ppNetworkList) =>
    _WlanGetFilterList(
        hClientHandle, wlanFilterListType, pReserved, ppNetworkList);

final _WlanGetFilterList = _wlanapi.lookupFunction<
    Uint32 Function(IntPtr hClientHandle, Int32 wlanFilterListType,
        Pointer pReserved, Pointer<Pointer<DOT11_NETWORK_LIST>> ppNetworkList),
    int Function(
        int hClientHandle,
        int wlanFilterListType,
        Pointer pReserved,
        Pointer<Pointer<DOT11_NETWORK_LIST>>
            ppNetworkList)>('WlanGetFilterList');

/// The WlanGetInterfaceCapability function retrieves the capabilities of an
/// interface.
///
/// ```c
/// DWORD WlanGetInterfaceCapability(
///   HANDLE                     hClientHandle,
///   const GUID                 *pInterfaceGuid,
///   PVOID                      pReserved,
///   PWLAN_INTERFACE_CAPABILITY *ppCapability
/// );
/// ```
/// {@category wlanapi}
int WlanGetInterfaceCapability(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer pReserved,
        Pointer<Pointer<WLAN_INTERFACE_CAPABILITY>> ppCapability) =>
    _WlanGetInterfaceCapability(
        hClientHandle, pInterfaceGuid, pReserved, ppCapability);

final _WlanGetInterfaceCapability = _wlanapi.lookupFunction<
        Uint32 Function(
            IntPtr hClientHandle,
            Pointer<GUID> pInterfaceGuid,
            Pointer pReserved,
            Pointer<Pointer<WLAN_INTERFACE_CAPABILITY>> ppCapability),
        int Function(
            int hClientHandle,
            Pointer<GUID> pInterfaceGuid,
            Pointer pReserved,
            Pointer<Pointer<WLAN_INTERFACE_CAPABILITY>> ppCapability)>(
    'WlanGetInterfaceCapability');

/// The WlanGetNetworkBssList function retrieves a list of the basic service
/// set (BSS) entries of the wireless network or networks on a given
/// wireless LAN interface.
///
/// ```c
/// DWORD WlanGetNetworkBssList(
///   HANDLE            hClientHandle,
///   const GUID        *pInterfaceGuid,
///   const PDOT11_SSID pDot11Ssid,
///   DOT11_BSS_TYPE    dot11BssType,
///   BOOL              bSecurityEnabled,
///   PVOID             pReserved,
///   PWLAN_BSS_LIST    *ppWlanBssList
/// );
/// ```
/// {@category wlanapi}
int WlanGetNetworkBssList(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<DOT11_SSID> pDot11Ssid,
        int dot11BssType,
        int bSecurityEnabled,
        Pointer pReserved,
        Pointer<Pointer<WLAN_BSS_LIST>> ppWlanBssList) =>
    _WlanGetNetworkBssList(hClientHandle, pInterfaceGuid, pDot11Ssid,
        dot11BssType, bSecurityEnabled, pReserved, ppWlanBssList);

final _WlanGetNetworkBssList = _wlanapi.lookupFunction<
        Uint32 Function(
            IntPtr hClientHandle,
            Pointer<GUID> pInterfaceGuid,
            Pointer<DOT11_SSID> pDot11Ssid,
            Int32 dot11BssType,
            Int32 bSecurityEnabled,
            Pointer pReserved,
            Pointer<Pointer<WLAN_BSS_LIST>> ppWlanBssList),
        int Function(
            int hClientHandle,
            Pointer<GUID> pInterfaceGuid,
            Pointer<DOT11_SSID> pDot11Ssid,
            int dot11BssType,
            int bSecurityEnabled,
            Pointer pReserved,
            Pointer<Pointer<WLAN_BSS_LIST>> ppWlanBssList)>(
    'WlanGetNetworkBssList');

/// The WlanGetProfile function retrieves all information about a specified
/// wireless profile.
///
/// ```c
/// DWORD WlanGetProfile(
///   HANDLE     hClientHandle,
///   const GUID *pInterfaceGuid,
///   LPCWSTR    strProfileName,
///   PVOID      pReserved,
///   LPWSTR     *pstrProfileXml,
///   DWORD      *pdwFlags,
///   DWORD      *pdwGrantedAccess
/// );
/// ```
/// {@category wlanapi}
int WlanGetProfile(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strProfileName,
        Pointer pReserved,
        Pointer<Pointer<Utf16>> pstrProfileXml,
        Pointer<Uint32> pdwFlags,
        Pointer<Uint32> pdwGrantedAccess) =>
    _WlanGetProfile(hClientHandle, pInterfaceGuid, strProfileName, pReserved,
        pstrProfileXml, pdwFlags, pdwGrantedAccess);

final _WlanGetProfile = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strProfileName,
        Pointer pReserved,
        Pointer<Pointer<Utf16>> pstrProfileXml,
        Pointer<Uint32> pdwFlags,
        Pointer<Uint32> pdwGrantedAccess),
    int Function(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strProfileName,
        Pointer pReserved,
        Pointer<Pointer<Utf16>> pstrProfileXml,
        Pointer<Uint32> pdwFlags,
        Pointer<Uint32> pdwGrantedAccess)>('WlanGetProfile');

/// The WlanGetProfileCustomUserData function gets the custom user data
/// associated with a wireless profile.
///
/// ```c
/// DWORD WlanGetProfileCustomUserData(
///   HANDLE     hClientHandle,
///   const GUID *pInterfaceGuid,
///   LPCWSTR    strProfileName,
///   PVOID      pReserved,
///   DWORD      *pdwDataSize,
///   PBYTE      *ppData
/// );
/// ```
/// {@category wlanapi}
int WlanGetProfileCustomUserData(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strProfileName,
        Pointer pReserved,
        Pointer<Uint32> pdwDataSize,
        Pointer<Pointer<Uint8>> ppData) =>
    _WlanGetProfileCustomUserData(hClientHandle, pInterfaceGuid, strProfileName,
        pReserved, pdwDataSize, ppData);

final _WlanGetProfileCustomUserData = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strProfileName,
        Pointer pReserved,
        Pointer<Uint32> pdwDataSize,
        Pointer<Pointer<Uint8>> ppData),
    int Function(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strProfileName,
        Pointer pReserved,
        Pointer<Uint32> pdwDataSize,
        Pointer<Pointer<Uint8>> ppData)>('WlanGetProfileCustomUserData');

/// The WlanGetProfileList function retrieves the list of profiles in
/// preference order.
///
/// ```c
/// DWORD WlanGetProfileList(
///   HANDLE                  hClientHandle,
///   const GUID              *pInterfaceGuid,
///   PVOID                   pReserved,
///   PWLAN_PROFILE_INFO_LIST *ppProfileList
/// );
/// ```
/// {@category wlanapi}
int WlanGetProfileList(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer pReserved,
        Pointer<Pointer<WLAN_PROFILE_INFO_LIST>> ppProfileList) =>
    _WlanGetProfileList(
        hClientHandle, pInterfaceGuid, pReserved, ppProfileList);

final _WlanGetProfileList = _wlanapi.lookupFunction<
        Uint32 Function(
            IntPtr hClientHandle,
            Pointer<GUID> pInterfaceGuid,
            Pointer pReserved,
            Pointer<Pointer<WLAN_PROFILE_INFO_LIST>> ppProfileList),
        int Function(
            int hClientHandle,
            Pointer<GUID> pInterfaceGuid,
            Pointer pReserved,
            Pointer<Pointer<WLAN_PROFILE_INFO_LIST>> ppProfileList)>(
    'WlanGetProfileList');

/// The WlanGetSecuritySettings function gets the security settings
/// associated with a configurable object.
///
/// ```c
/// DWORD WlanGetSecuritySettings(
///   HANDLE                  hClientHandle,
///   WLAN_SECURABLE_OBJECT   SecurableObject,
///   PWLAN_OPCODE_VALUE_TYPE pValueType,
///   LPWSTR                  *pstrCurrentSDDL,
///   PDWORD                  pdwGrantedAccess
/// );
/// ```
/// {@category wlanapi}
int WlanGetSecuritySettings(
        int hClientHandle,
        int SecurableObject,
        Pointer<Int32> pValueType,
        Pointer<Pointer<Utf16>> pstrCurrentSDDL,
        Pointer<Uint32> pdwGrantedAccess) =>
    _WlanGetSecuritySettings(hClientHandle, SecurableObject, pValueType,
        pstrCurrentSDDL, pdwGrantedAccess);

final _WlanGetSecuritySettings = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle,
        Int32 SecurableObject,
        Pointer<Int32> pValueType,
        Pointer<Pointer<Utf16>> pstrCurrentSDDL,
        Pointer<Uint32> pdwGrantedAccess),
    int Function(
        int hClientHandle,
        int SecurableObject,
        Pointer<Int32> pValueType,
        Pointer<Pointer<Utf16>> pstrCurrentSDDL,
        Pointer<Uint32> pdwGrantedAccess)>('WlanGetSecuritySettings');

/// Retrieves a list of the supported device services on a given wireless
/// LAN interface.
///
/// ```c
/// DWORD WlanGetSupportedDeviceServices(
///   HANDLE                         hClientHandle,
///   const GUID                     *pInterfaceGuid,
///   PWLAN_DEVICE_SERVICE_GUID_LIST *ppDevSvcGuidList
/// );
/// ```
/// {@category wlanapi}
int WlanGetSupportedDeviceServices(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<Pointer<WLAN_DEVICE_SERVICE_GUID_LIST>> ppDevSvcGuidList) =>
    _WlanGetSupportedDeviceServices(
        hClientHandle, pInterfaceGuid, ppDevSvcGuidList);

final _WlanGetSupportedDeviceServices = _wlanapi.lookupFunction<
        Uint32 Function(IntPtr hClientHandle, Pointer<GUID> pInterfaceGuid,
            Pointer<Pointer<WLAN_DEVICE_SERVICE_GUID_LIST>> ppDevSvcGuidList),
        int Function(int hClientHandle, Pointer<GUID> pInterfaceGuid,
            Pointer<Pointer<WLAN_DEVICE_SERVICE_GUID_LIST>> ppDevSvcGuidList)>(
    'WlanGetSupportedDeviceServices');

/// The WlanHostedNetworkForceStart function transitions the wireless Hosted
/// Network to the wlan_hosted_network_active state without associating the
/// request with the application's calling handle.
///
/// ```c
/// DWORD WlanHostedNetworkForceStart(
///   HANDLE                      hClientHandle,
///   PWLAN_HOSTED_NETWORK_REASON pFailReason,
///   PVOID                       pvReserved
/// );
/// ```
/// {@category wlanapi}
int WlanHostedNetworkForceStart(
        int hClientHandle, Pointer<Int32> pFailReason, Pointer pvReserved) =>
    _WlanHostedNetworkForceStart(hClientHandle, pFailReason, pvReserved);

final _WlanHostedNetworkForceStart = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle, Pointer<Int32> pFailReason, Pointer pvReserved),
    int Function(int hClientHandle, Pointer<Int32> pFailReason,
        Pointer pvReserved)>('WlanHostedNetworkForceStart');

/// The WlanHostedNetworkForceStop function transitions the wireless Hosted
/// Network to the wlan_hosted_network_idle without associating the request
/// with the application's calling handle.
///
/// ```c
/// DWORD WlanHostedNetworkForceStop(
///   HANDLE                      hClientHandle,
///   PWLAN_HOSTED_NETWORK_REASON pFailReason,
///   PVOID                       pvReserved
/// );
/// ```
/// {@category wlanapi}
int WlanHostedNetworkForceStop(
        int hClientHandle, Pointer<Int32> pFailReason, Pointer pvReserved) =>
    _WlanHostedNetworkForceStop(hClientHandle, pFailReason, pvReserved);

final _WlanHostedNetworkForceStop = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle, Pointer<Int32> pFailReason, Pointer pvReserved),
    int Function(int hClientHandle, Pointer<Int32> pFailReason,
        Pointer pvReserved)>('WlanHostedNetworkForceStop');

/// The WlanHostedNetworkInitSettings function configures and persists to
/// storage the network connection settings (SSID and maximum number of
/// peers, for example) on the wireless Hosted Network if these settings are
/// not already configured.
///
/// ```c
/// DWORD WlanHostedNetworkInitSettings(
///   HANDLE                      hClientHandle,
///   PWLAN_HOSTED_NETWORK_REASON pFailReason,
///   PVOID                       pvReserved
/// );
/// ```
/// {@category wlanapi}
int WlanHostedNetworkInitSettings(
        int hClientHandle, Pointer<Int32> pFailReason, Pointer pvReserved) =>
    _WlanHostedNetworkInitSettings(hClientHandle, pFailReason, pvReserved);

final _WlanHostedNetworkInitSettings = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle, Pointer<Int32> pFailReason, Pointer pvReserved),
    int Function(int hClientHandle, Pointer<Int32> pFailReason,
        Pointer pvReserved)>('WlanHostedNetworkInitSettings');

/// The WlanHostedNetworkQueryProperty function queries the current static
/// properties of the wireless Hosted Network.
///
/// ```c
/// DWORD WlanHostedNetworkQueryProperty(
///   HANDLE                     hClientHandle,
///   WLAN_HOSTED_NETWORK_OPCODE OpCode,
///   PDWORD                     pdwDataSize,
///   PVOID                      *ppvData,
///   PWLAN_OPCODE_VALUE_TYPE    pWlanOpcodeValueType,
///   PVOID                      pvReserved
/// );
/// ```
/// {@category wlanapi}
int WlanHostedNetworkQueryProperty(
        int hClientHandle,
        int OpCode,
        Pointer<Uint32> pdwDataSize,
        Pointer<Pointer> ppvData,
        Pointer<Int32> pWlanOpcodeValueType,
        Pointer pvReserved) =>
    _WlanHostedNetworkQueryProperty(hClientHandle, OpCode, pdwDataSize, ppvData,
        pWlanOpcodeValueType, pvReserved);

final _WlanHostedNetworkQueryProperty = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle,
        Int32 OpCode,
        Pointer<Uint32> pdwDataSize,
        Pointer<Pointer> ppvData,
        Pointer<Int32> pWlanOpcodeValueType,
        Pointer pvReserved),
    int Function(
        int hClientHandle,
        int OpCode,
        Pointer<Uint32> pdwDataSize,
        Pointer<Pointer> ppvData,
        Pointer<Int32> pWlanOpcodeValueType,
        Pointer pvReserved)>('WlanHostedNetworkQueryProperty');

/// The WlanHostedNetworkQuerySecondaryKey function queries the secondary
/// security key that is configured to be used by the wireless Hosted
/// Network.
///
/// ```c
/// DWORD WlanHostedNetworkQuerySecondaryKey(
///   HANDLE                      hClientHandle,
///   PDWORD                      pdwKeyLength,
///   PUCHAR                      *ppucKeyData,
///   PBOOL                       pbIsPassPhrase,
///   PBOOL                       pbPersistent,
///   PWLAN_HOSTED_NETWORK_REASON pFailReason,
///   PVOID                       pvReserved
/// );
/// ```
/// {@category wlanapi}
int WlanHostedNetworkQuerySecondaryKey(
        int hClientHandle,
        Pointer<Uint32> pdwKeyLength,
        Pointer<Pointer<Uint8>> ppucKeyData,
        Pointer<Int32> pbIsPassPhrase,
        Pointer<Int32> pbPersistent,
        Pointer<Int32> pFailReason,
        Pointer pvReserved) =>
    _WlanHostedNetworkQuerySecondaryKey(hClientHandle, pdwKeyLength,
        ppucKeyData, pbIsPassPhrase, pbPersistent, pFailReason, pvReserved);

final _WlanHostedNetworkQuerySecondaryKey = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle,
        Pointer<Uint32> pdwKeyLength,
        Pointer<Pointer<Uint8>> ppucKeyData,
        Pointer<Int32> pbIsPassPhrase,
        Pointer<Int32> pbPersistent,
        Pointer<Int32> pFailReason,
        Pointer pvReserved),
    int Function(
        int hClientHandle,
        Pointer<Uint32> pdwKeyLength,
        Pointer<Pointer<Uint8>> ppucKeyData,
        Pointer<Int32> pbIsPassPhrase,
        Pointer<Int32> pbPersistent,
        Pointer<Int32> pFailReason,
        Pointer pvReserved)>('WlanHostedNetworkQuerySecondaryKey');

/// The WlanHostedNetworkQueryStatus function queries the current status of
/// the wireless Hosted Network.
///
/// ```c
/// DWORD WlanHostedNetworkQueryStatus(
///   HANDLE                      hClientHandle,
///   PWLAN_HOSTED_NETWORK_STATUS *ppWlanHostedNetworkStatus,
///   PVOID                       pvReserved
/// );
/// ```
/// {@category wlanapi}
int WlanHostedNetworkQueryStatus(
        int hClientHandle,
        Pointer<Pointer<WLAN_HOSTED_NETWORK_STATUS>> ppWlanHostedNetworkStatus,
        Pointer pvReserved) =>
    _WlanHostedNetworkQueryStatus(
        hClientHandle, ppWlanHostedNetworkStatus, pvReserved);

final _WlanHostedNetworkQueryStatus = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle,
        Pointer<Pointer<WLAN_HOSTED_NETWORK_STATUS>> ppWlanHostedNetworkStatus,
        Pointer pvReserved),
    int Function(
        int hClientHandle,
        Pointer<Pointer<WLAN_HOSTED_NETWORK_STATUS>> ppWlanHostedNetworkStatus,
        Pointer pvReserved)>('WlanHostedNetworkQueryStatus');

/// The WlanHostedNetworkRefreshSecuritySettings function refreshes the
/// configurable and auto-generated parts of the wireless Hosted Network
/// security settings.
///
/// ```c
/// DWORD WlanHostedNetworkRefreshSecuritySettings(
///   HANDLE                      hClientHandle,
///   PWLAN_HOSTED_NETWORK_REASON pFailReason,
///   PVOID                       pvReserved
/// );
/// ```
/// {@category wlanapi}
int WlanHostedNetworkRefreshSecuritySettings(
        int hClientHandle, Pointer<Int32> pFailReason, Pointer pvReserved) =>
    _WlanHostedNetworkRefreshSecuritySettings(
        hClientHandle, pFailReason, pvReserved);

final _WlanHostedNetworkRefreshSecuritySettings = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle, Pointer<Int32> pFailReason, Pointer pvReserved),
    int Function(int hClientHandle, Pointer<Int32> pFailReason,
        Pointer pvReserved)>('WlanHostedNetworkRefreshSecuritySettings');

/// The WlanHostedNetworkSetProperty function sets static properties of the
/// wireless Hosted Network.
///
/// ```c
/// DWORD WlanHostedNetworkSetProperty(
///   HANDLE                      hClientHandle,
///   WLAN_HOSTED_NETWORK_OPCODE  OpCode,
///   DWORD                       dwDataSize,
///   PVOID                       pvData,
///   PWLAN_HOSTED_NETWORK_REASON pFailReason,
///   PVOID                       pvReserved
/// );
/// ```
/// {@category wlanapi}
int WlanHostedNetworkSetProperty(int hClientHandle, int OpCode, int dwDataSize,
        Pointer pvData, Pointer<Int32> pFailReason, Pointer pvReserved) =>
    _WlanHostedNetworkSetProperty(
        hClientHandle, OpCode, dwDataSize, pvData, pFailReason, pvReserved);

final _WlanHostedNetworkSetProperty = _wlanapi.lookupFunction<
    Uint32 Function(IntPtr hClientHandle, Int32 OpCode, Uint32 dwDataSize,
        Pointer pvData, Pointer<Int32> pFailReason, Pointer pvReserved),
    int Function(
        int hClientHandle,
        int OpCode,
        int dwDataSize,
        Pointer pvData,
        Pointer<Int32> pFailReason,
        Pointer pvReserved)>('WlanHostedNetworkSetProperty');

/// The WlanHostedNetworkSetSecondaryKey function configures the secondary
/// security key that will be used by the wireless Hosted Network.
///
/// ```c
/// DWORD WlanHostedNetworkSetSecondaryKey(
///   HANDLE                      hClientHandle,
///   DWORD                       dwKeyLength,
///   PUCHAR                      pucKeyData,
///   BOOL                        bIsPassPhrase,
///   BOOL                        bPersistent,
///   PWLAN_HOSTED_NETWORK_REASON pFailReason,
///   PVOID                       pvReserved
/// );
/// ```
/// {@category wlanapi}
int WlanHostedNetworkSetSecondaryKey(
        int hClientHandle,
        int dwKeyLength,
        Pointer<Uint8> pucKeyData,
        int bIsPassPhrase,
        int bPersistent,
        Pointer<Int32> pFailReason,
        Pointer pvReserved) =>
    _WlanHostedNetworkSetSecondaryKey(hClientHandle, dwKeyLength, pucKeyData,
        bIsPassPhrase, bPersistent, pFailReason, pvReserved);

final _WlanHostedNetworkSetSecondaryKey = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle,
        Uint32 dwKeyLength,
        Pointer<Uint8> pucKeyData,
        Int32 bIsPassPhrase,
        Int32 bPersistent,
        Pointer<Int32> pFailReason,
        Pointer pvReserved),
    int Function(
        int hClientHandle,
        int dwKeyLength,
        Pointer<Uint8> pucKeyData,
        int bIsPassPhrase,
        int bPersistent,
        Pointer<Int32> pFailReason,
        Pointer pvReserved)>('WlanHostedNetworkSetSecondaryKey');

/// The WlanHostedNetworkStartUsing function starts the wireless Hosted
/// Network.
///
/// ```c
/// DWORD WlanHostedNetworkStartUsing(
///   HANDLE                      hClientHandle,
///   PWLAN_HOSTED_NETWORK_REASON pFailReason,
///   PVOID                       pvReserved
/// );
/// ```
/// {@category wlanapi}
int WlanHostedNetworkStartUsing(
        int hClientHandle, Pointer<Int32> pFailReason, Pointer pvReserved) =>
    _WlanHostedNetworkStartUsing(hClientHandle, pFailReason, pvReserved);

final _WlanHostedNetworkStartUsing = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle, Pointer<Int32> pFailReason, Pointer pvReserved),
    int Function(int hClientHandle, Pointer<Int32> pFailReason,
        Pointer pvReserved)>('WlanHostedNetworkStartUsing');

/// The WlanHostedNetworkStopUsing function stops the wireless Hosted
/// Network.
///
/// ```c
/// DWORD WlanHostedNetworkStopUsing(
///   HANDLE                      hClientHandle,
///   PWLAN_HOSTED_NETWORK_REASON pFailReason,
///   PVOID                       pvReserved
/// );
/// ```
/// {@category wlanapi}
int WlanHostedNetworkStopUsing(
        int hClientHandle, Pointer<Int32> pFailReason, Pointer pvReserved) =>
    _WlanHostedNetworkStopUsing(hClientHandle, pFailReason, pvReserved);

final _WlanHostedNetworkStopUsing = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle, Pointer<Int32> pFailReason, Pointer pvReserved),
    int Function(int hClientHandle, Pointer<Int32> pFailReason,
        Pointer pvReserved)>('WlanHostedNetworkStopUsing');

/// The WlanIhvControl function provides a mechanism for independent
/// hardware vendor (IHV) control of WLAN drivers or services.
///
/// ```c
/// DWORD WlanIhvControl(
///   HANDLE                hClientHandle,
///   const GUID            *pInterfaceGuid,
///   WLAN_IHV_CONTROL_TYPE Type,
///   DWORD                 dwInBufferSize,
///   PVOID                 pInBuffer,
///   DWORD                 dwOutBufferSize,
///   PVOID                 pOutBuffer,
///   PDWORD                pdwBytesReturned
/// );
/// ```
/// {@category wlanapi}
int WlanIhvControl(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        int Type,
        int dwInBufferSize,
        Pointer pInBuffer,
        int dwOutBufferSize,
        Pointer pOutBuffer,
        Pointer<Uint32> pdwBytesReturned) =>
    _WlanIhvControl(hClientHandle, pInterfaceGuid, Type, dwInBufferSize,
        pInBuffer, dwOutBufferSize, pOutBuffer, pdwBytesReturned);

final _WlanIhvControl = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Int32 Type,
        Uint32 dwInBufferSize,
        Pointer pInBuffer,
        Uint32 dwOutBufferSize,
        Pointer pOutBuffer,
        Pointer<Uint32> pdwBytesReturned),
    int Function(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        int Type,
        int dwInBufferSize,
        Pointer pInBuffer,
        int dwOutBufferSize,
        Pointer pOutBuffer,
        Pointer<Uint32> pdwBytesReturned)>('WlanIhvControl');

/// The WlanOpenHandle function opens a connection to the server.
///
/// ```c
/// DWORD WlanOpenHandle(
///   DWORD   dwClientVersion,
///   PVOID   pReserved,
///   PDWORD  pdwNegotiatedVersion,
///   PHANDLE phClientHandle
/// );
/// ```
/// {@category wlanapi}
int WlanOpenHandle(int dwClientVersion, Pointer pReserved,
        Pointer<Uint32> pdwNegotiatedVersion, Pointer<IntPtr> phClientHandle) =>
    _WlanOpenHandle(
        dwClientVersion, pReserved, pdwNegotiatedVersion, phClientHandle);

final _WlanOpenHandle = _wlanapi.lookupFunction<
    Uint32 Function(Uint32 dwClientVersion, Pointer pReserved,
        Pointer<Uint32> pdwNegotiatedVersion, Pointer<IntPtr> phClientHandle),
    int Function(
        int dwClientVersion,
        Pointer pReserved,
        Pointer<Uint32> pdwNegotiatedVersion,
        Pointer<IntPtr> phClientHandle)>('WlanOpenHandle');

/// The WlanQueryAutoConfigParameter function queries for the parameters of
/// the auto configuration service.
///
/// ```c
/// DWORD WlanQueryAutoConfigParameter(
///   HANDLE                  hClientHandle,
///   WLAN_AUTOCONF_OPCODE    OpCode,
///   PVOID                   pReserved,
///   PDWORD                  pdwDataSize,
///   PVOID                   *ppData,
///   PWLAN_OPCODE_VALUE_TYPE pWlanOpcodeValueType
/// );
/// ```
/// {@category wlanapi}
int WlanQueryAutoConfigParameter(
        int hClientHandle,
        int OpCode,
        Pointer pReserved,
        Pointer<Uint32> pdwDataSize,
        Pointer<Pointer> ppData,
        Pointer<Int32> pWlanOpcodeValueType) =>
    _WlanQueryAutoConfigParameter(hClientHandle, OpCode, pReserved, pdwDataSize,
        ppData, pWlanOpcodeValueType);

final _WlanQueryAutoConfigParameter = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle,
        Int32 OpCode,
        Pointer pReserved,
        Pointer<Uint32> pdwDataSize,
        Pointer<Pointer> ppData,
        Pointer<Int32> pWlanOpcodeValueType),
    int Function(
        int hClientHandle,
        int OpCode,
        Pointer pReserved,
        Pointer<Uint32> pdwDataSize,
        Pointer<Pointer> ppData,
        Pointer<Int32> pWlanOpcodeValueType)>('WlanQueryAutoConfigParameter');

/// The WlanQueryInterface function queries various parameters of a
/// specified interface.
///
/// ```c
/// DWORD WlanQueryInterface(
///   HANDLE                  hClientHandle,
///   const GUID              *pInterfaceGuid,
///   WLAN_INTF_OPCODE        OpCode,
///   PVOID                   pReserved,
///   PDWORD                  pdwDataSize,
///   PVOID                   *ppData,
///   PWLAN_OPCODE_VALUE_TYPE pWlanOpcodeValueType
/// );
/// ```
/// {@category wlanapi}
int WlanQueryInterface(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        int OpCode,
        Pointer pReserved,
        Pointer<Uint32> pdwDataSize,
        Pointer<Pointer> ppData,
        Pointer<Int32> pWlanOpcodeValueType) =>
    _WlanQueryInterface(hClientHandle, pInterfaceGuid, OpCode, pReserved,
        pdwDataSize, ppData, pWlanOpcodeValueType);

final _WlanQueryInterface = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Int32 OpCode,
        Pointer pReserved,
        Pointer<Uint32> pdwDataSize,
        Pointer<Pointer> ppData,
        Pointer<Int32> pWlanOpcodeValueType),
    int Function(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        int OpCode,
        Pointer pReserved,
        Pointer<Uint32> pdwDataSize,
        Pointer<Pointer> ppData,
        Pointer<Int32> pWlanOpcodeValueType)>('WlanQueryInterface');

/// The WlanReasonCodeToString function retrieves a string that describes a
/// specified reason code.
///
/// ```c
/// DWORD WlanReasonCodeToString(
///   DWORD  dwReasonCode,
///   DWORD  dwBufferSize,
///   PWCHAR pStringBuffer,
///   PVOID  pReserved
/// );
/// ```
/// {@category wlanapi}
int WlanReasonCodeToString(int dwReasonCode, int dwBufferSize,
        Pointer<Utf16> pStringBuffer, Pointer pReserved) =>
    _WlanReasonCodeToString(
        dwReasonCode, dwBufferSize, pStringBuffer, pReserved);

final _WlanReasonCodeToString = _wlanapi.lookupFunction<
    Uint32 Function(Uint32 dwReasonCode, Uint32 dwBufferSize,
        Pointer<Utf16> pStringBuffer, Pointer pReserved),
    int Function(
        int dwReasonCode,
        int dwBufferSize,
        Pointer<Utf16> pStringBuffer,
        Pointer pReserved)>('WlanReasonCodeToString');

/// Allows user mode clients with admin privileges, or User-Mode Driver
/// Framework (UMDF) drivers, to register for unsolicited notifications
/// corresponding to device services that they're interested in.
///
/// ```c
/// DWORD WlanRegisterDeviceServiceNotification(
///   HANDLE                               hClientHandle,
///   const PWLAN_DEVICE_SERVICE_GUID_LIST pDevSvcGuidList
/// );
/// ```
/// {@category wlanapi}
int WlanRegisterDeviceServiceNotification(int hClientHandle,
        Pointer<WLAN_DEVICE_SERVICE_GUID_LIST> pDevSvcGuidList) =>
    _WlanRegisterDeviceServiceNotification(hClientHandle, pDevSvcGuidList);

final _WlanRegisterDeviceServiceNotification = _wlanapi.lookupFunction<
        Uint32 Function(IntPtr hClientHandle,
            Pointer<WLAN_DEVICE_SERVICE_GUID_LIST> pDevSvcGuidList),
        int Function(int hClientHandle,
            Pointer<WLAN_DEVICE_SERVICE_GUID_LIST> pDevSvcGuidList)>(
    'WlanRegisterDeviceServiceNotification');

/// The WlanRegisterNotification function is used to register and unregister
/// notifications on all wireless interfaces.
///
/// ```c
/// DWORD WlanRegisterNotification(
///   HANDLE                     hClientHandle,
///   DWORD                      dwNotifSource,
///   BOOL                       bIgnoreDuplicate,
///   WLAN_NOTIFICATION_CALLBACK funcCallback,
///   PVOID                      pCallbackContext,
///   PVOID                      pReserved,
///   PDWORD                     pdwPrevNotifSource
/// );
/// ```
/// {@category wlanapi}
int WlanRegisterNotification(
        int hClientHandle,
        int dwNotifSource,
        int bIgnoreDuplicate,
        Pointer<NativeFunction<WlanNotificationCallback>> funcCallback,
        Pointer pCallbackContext,
        Pointer pReserved,
        Pointer<Uint32> pdwPrevNotifSource) =>
    _WlanRegisterNotification(hClientHandle, dwNotifSource, bIgnoreDuplicate,
        funcCallback, pCallbackContext, pReserved, pdwPrevNotifSource);

final _WlanRegisterNotification = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle,
        Uint32 dwNotifSource,
        Int32 bIgnoreDuplicate,
        Pointer<NativeFunction<WlanNotificationCallback>> funcCallback,
        Pointer pCallbackContext,
        Pointer pReserved,
        Pointer<Uint32> pdwPrevNotifSource),
    int Function(
        int hClientHandle,
        int dwNotifSource,
        int bIgnoreDuplicate,
        Pointer<NativeFunction<WlanNotificationCallback>> funcCallback,
        Pointer pCallbackContext,
        Pointer pReserved,
        Pointer<Uint32> pdwPrevNotifSource)>('WlanRegisterNotification');

/// The WlanRegisterVirtualStationNotification function is used to register
/// and unregister notifications on a virtual station.
///
/// ```c
/// DWORD WlanRegisterVirtualStationNotification(
///   HANDLE hClientHandle,
///   BOOL   bRegister,
///   PVOID  pReserved
/// );
/// ```
/// {@category wlanapi}
int WlanRegisterVirtualStationNotification(
        int hClientHandle, int bRegister, Pointer pReserved) =>
    _WlanRegisterVirtualStationNotification(
        hClientHandle, bRegister, pReserved);

final _WlanRegisterVirtualStationNotification = _wlanapi.lookupFunction<
    Uint32 Function(IntPtr hClientHandle, Int32 bRegister, Pointer pReserved),
    int Function(int hClientHandle, int bRegister,
        Pointer pReserved)>('WlanRegisterVirtualStationNotification');

/// The WlanRenameProfile function renames the specified profile.
///
/// ```c
/// DWORD WlanRenameProfile(
///   HANDLE     hClientHandle,
///   const GUID *pInterfaceGuid,
///   LPCWSTR    strOldProfileName,
///   LPCWSTR    strNewProfileName,
///   PVOID      pReserved
/// );
/// ```
/// {@category wlanapi}
int WlanRenameProfile(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strOldProfileName,
        Pointer<Utf16> strNewProfileName,
        Pointer pReserved) =>
    _WlanRenameProfile(hClientHandle, pInterfaceGuid, strOldProfileName,
        strNewProfileName, pReserved);

final _WlanRenameProfile = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strOldProfileName,
        Pointer<Utf16> strNewProfileName,
        Pointer pReserved),
    int Function(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strOldProfileName,
        Pointer<Utf16> strNewProfileName,
        Pointer pReserved)>('WlanRenameProfile');

/// The WlanSaveTemporaryProfile function saves a temporary profile to the
/// profile store.
///
/// ```c
/// DWORD WlanSaveTemporaryProfile(
///   HANDLE     hClientHandle,
///   const GUID *pInterfaceGuid,
///   LPCWSTR    strProfileName,
///   LPCWSTR    strAllUserProfileSecurity,
///   DWORD      dwFlags,
///   BOOL       bOverWrite,
///   PVOID      pReserved
/// );
/// ```
/// {@category wlanapi}
int WlanSaveTemporaryProfile(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strProfileName,
        Pointer<Utf16> strAllUserProfileSecurity,
        int dwFlags,
        int bOverWrite,
        Pointer pReserved) =>
    _WlanSaveTemporaryProfile(hClientHandle, pInterfaceGuid, strProfileName,
        strAllUserProfileSecurity, dwFlags, bOverWrite, pReserved);

final _WlanSaveTemporaryProfile = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strProfileName,
        Pointer<Utf16> strAllUserProfileSecurity,
        Uint32 dwFlags,
        Int32 bOverWrite,
        Pointer pReserved),
    int Function(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strProfileName,
        Pointer<Utf16> strAllUserProfileSecurity,
        int dwFlags,
        int bOverWrite,
        Pointer pReserved)>('WlanSaveTemporaryProfile');

/// The WlanScan function requests a scan for available networks on the
/// indicated interface.
///
/// ```c
/// DWORD WlanScan(
///   HANDLE               hClientHandle,
///   const GUID           *pInterfaceGuid,
///   const PDOT11_SSID    pDot11Ssid,
///   const PWLAN_RAW_DATA pIeData,
///   PVOID                pReserved
/// );
/// ```
/// {@category wlanapi}
int WlanScan(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<DOT11_SSID> pDot11Ssid,
        Pointer<WLAN_RAW_DATA> pIeData,
        Pointer pReserved) =>
    _WlanScan(hClientHandle, pInterfaceGuid, pDot11Ssid, pIeData, pReserved);

final _WlanScan = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<DOT11_SSID> pDot11Ssid,
        Pointer<WLAN_RAW_DATA> pIeData,
        Pointer pReserved),
    int Function(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<DOT11_SSID> pDot11Ssid,
        Pointer<WLAN_RAW_DATA> pIeData,
        Pointer pReserved)>('WlanScan');

/// The WlanSetAutoConfigParameter function sets parameters for the
/// automatic configuration service.
///
/// ```c
/// DWORD WlanSetAutoConfigParameter(
///   HANDLE               hClientHandle,
///   WLAN_AUTOCONF_OPCODE OpCode,
///   DWORD                dwDataSize,
///   const PVOID          pData,
///   PVOID                pReserved
/// );
/// ```
/// {@category wlanapi}
int WlanSetAutoConfigParameter(int hClientHandle, int OpCode, int dwDataSize,
        Pointer pData, Pointer pReserved) =>
    _WlanSetAutoConfigParameter(
        hClientHandle, OpCode, dwDataSize, pData, pReserved);

final _WlanSetAutoConfigParameter = _wlanapi.lookupFunction<
    Uint32 Function(IntPtr hClientHandle, Int32 OpCode, Uint32 dwDataSize,
        Pointer pData, Pointer pReserved),
    int Function(int hClientHandle, int OpCode, int dwDataSize, Pointer pData,
        Pointer pReserved)>('WlanSetAutoConfigParameter');

/// The WlanSetFilterList function sets the permit/deny list.
///
/// ```c
/// DWORD WlanSetFilterList(
///   HANDLE                    hClientHandle,
///   WLAN_FILTER_LIST_TYPE     wlanFilterListType,
///   const PDOT11_NETWORK_LIST pNetworkList,
///   PVOID                     pReserved
/// );
/// ```
/// {@category wlanapi}
int WlanSetFilterList(int hClientHandle, int wlanFilterListType,
        Pointer<DOT11_NETWORK_LIST> pNetworkList, Pointer pReserved) =>
    _WlanSetFilterList(
        hClientHandle, wlanFilterListType, pNetworkList, pReserved);

final _WlanSetFilterList = _wlanapi.lookupFunction<
    Uint32 Function(IntPtr hClientHandle, Int32 wlanFilterListType,
        Pointer<DOT11_NETWORK_LIST> pNetworkList, Pointer pReserved),
    int Function(
        int hClientHandle,
        int wlanFilterListType,
        Pointer<DOT11_NETWORK_LIST> pNetworkList,
        Pointer pReserved)>('WlanSetFilterList');

/// The WlanSetInterface function sets user-configurable parameters for a
/// specified interface.
///
/// ```c
/// DWORD WlanSetInterface(
///   HANDLE           hClientHandle,
///   const GUID       *pInterfaceGuid,
///   WLAN_INTF_OPCODE OpCode,
///   DWORD            dwDataSize,
///   const PVOID      pData,
///   PVOID            pReserved
/// );
/// ```
/// {@category wlanapi}
int WlanSetInterface(int hClientHandle, Pointer<GUID> pInterfaceGuid,
        int OpCode, int dwDataSize, Pointer pData, Pointer pReserved) =>
    _WlanSetInterface(
        hClientHandle, pInterfaceGuid, OpCode, dwDataSize, pData, pReserved);

final _WlanSetInterface = _wlanapi.lookupFunction<
    Uint32 Function(IntPtr hClientHandle, Pointer<GUID> pInterfaceGuid,
        Int32 OpCode, Uint32 dwDataSize, Pointer pData, Pointer pReserved),
    int Function(int hClientHandle, Pointer<GUID> pInterfaceGuid, int OpCode,
        int dwDataSize, Pointer pData, Pointer pReserved)>('WlanSetInterface');

/// The WlanSetProfile function sets the content of a specific profile.
///
/// ```c
/// DWORD WlanSetProfile(
///   HANDLE     hClientHandle,
///   const GUID *pInterfaceGuid,
///   DWORD      dwFlags,
///   LPCWSTR    strProfileXml,
///   LPCWSTR    strAllUserProfileSecurity,
///   BOOL       bOverwrite,
///   PVOID      pReserved,
///   DWORD      *pdwReasonCode
/// );
/// ```
/// {@category wlanapi}
int WlanSetProfile(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        int dwFlags,
        Pointer<Utf16> strProfileXml,
        Pointer<Utf16> strAllUserProfileSecurity,
        int bOverwrite,
        Pointer pReserved,
        Pointer<Uint32> pdwReasonCode) =>
    _WlanSetProfile(hClientHandle, pInterfaceGuid, dwFlags, strProfileXml,
        strAllUserProfileSecurity, bOverwrite, pReserved, pdwReasonCode);

final _WlanSetProfile = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Uint32 dwFlags,
        Pointer<Utf16> strProfileXml,
        Pointer<Utf16> strAllUserProfileSecurity,
        Int32 bOverwrite,
        Pointer pReserved,
        Pointer<Uint32> pdwReasonCode),
    int Function(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        int dwFlags,
        Pointer<Utf16> strProfileXml,
        Pointer<Utf16> strAllUserProfileSecurity,
        int bOverwrite,
        Pointer pReserved,
        Pointer<Uint32> pdwReasonCode)>('WlanSetProfile');

/// The WlanSetProfileCustomUserData function sets the custom user data
/// associated with a profile.
///
/// ```c
/// DWORD WlanSetProfileCustomUserData(
///   HANDLE      hClientHandle,
///   const GUID  *pInterfaceGuid,
///   LPCWSTR     strProfileName,
///   DWORD       dwDataSize,
///   const PBYTE pData,
///   PVOID       pReserved
/// );
/// ```
/// {@category wlanapi}
int WlanSetProfileCustomUserData(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strProfileName,
        int dwDataSize,
        Pointer<Uint8> pData,
        Pointer pReserved) =>
    _WlanSetProfileCustomUserData(hClientHandle, pInterfaceGuid, strProfileName,
        dwDataSize, pData, pReserved);

final _WlanSetProfileCustomUserData = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strProfileName,
        Uint32 dwDataSize,
        Pointer<Uint8> pData,
        Pointer pReserved),
    int Function(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strProfileName,
        int dwDataSize,
        Pointer<Uint8> pData,
        Pointer pReserved)>('WlanSetProfileCustomUserData');

/// The WlanSetProfileEapUserData function sets the Extensible
/// Authentication Protocol (EAP) user credentials as specified by raw EAP
/// data. The user credentials apply to a profile on an interface.
///
/// ```c
/// DWORD WlanSetProfileEapUserData(
///   HANDLE          hClientHandle,
///   const GUID      *pInterfaceGuid,
///   LPCWSTR         strProfileName,
///   EAP_METHOD_TYPE eapType,
///   DWORD           dwFlags,
///   DWORD           dwEapUserDataSize,
///   const LPBYTE    pbEapUserData,
///   PVOID           pReserved
/// );
/// ```
/// {@category wlanapi}
int WlanSetProfileEapUserData(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strProfileName,
        EAP_METHOD_TYPE eapType,
        int dwFlags,
        int dwEapUserDataSize,
        Pointer<Uint8> pbEapUserData,
        Pointer pReserved) =>
    _WlanSetProfileEapUserData(hClientHandle, pInterfaceGuid, strProfileName,
        eapType, dwFlags, dwEapUserDataSize, pbEapUserData, pReserved);

final _WlanSetProfileEapUserData = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strProfileName,
        EAP_METHOD_TYPE eapType,
        Uint32 dwFlags,
        Uint32 dwEapUserDataSize,
        Pointer<Uint8> pbEapUserData,
        Pointer pReserved),
    int Function(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strProfileName,
        EAP_METHOD_TYPE eapType,
        int dwFlags,
        int dwEapUserDataSize,
        Pointer<Uint8> pbEapUserData,
        Pointer pReserved)>('WlanSetProfileEapUserData');

/// The WlanSetProfileEapXmlUserData function sets the Extensible
/// Authentication Protocol (EAP) user credentials as specified by an XML
/// string. The user credentials apply to a profile on an adapter. These
/// credentials can be used only by the caller.
///
/// ```c
/// DWORD WlanSetProfileEapXmlUserData(
///   HANDLE     hClientHandle,
///   const GUID *pInterfaceGuid,
///   LPCWSTR    strProfileName,
///   DWORD      dwFlags,
///   LPCWSTR    strEapXmlUserData,
///   PVOID      pReserved
/// );
/// ```
/// {@category wlanapi}
int WlanSetProfileEapXmlUserData(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strProfileName,
        int dwFlags,
        Pointer<Utf16> strEapXmlUserData,
        Pointer pReserved) =>
    _WlanSetProfileEapXmlUserData(hClientHandle, pInterfaceGuid, strProfileName,
        dwFlags, strEapXmlUserData, pReserved);

final _WlanSetProfileEapXmlUserData = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strProfileName,
        Uint32 dwFlags,
        Pointer<Utf16> strEapXmlUserData,
        Pointer pReserved),
    int Function(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strProfileName,
        int dwFlags,
        Pointer<Utf16> strEapXmlUserData,
        Pointer pReserved)>('WlanSetProfileEapXmlUserData');

/// The WlanSetProfileList function sets the preference order of profiles
/// for a given interface.
///
/// ```c
/// DWORD WlanSetProfileList(
///   HANDLE     hClientHandle,
///   const GUID *pInterfaceGuid,
///   DWORD      dwItems,
///   LPCWSTR    *strProfileNames,
///   PVOID      pReserved
/// );
/// ```
/// {@category wlanapi}
int WlanSetProfileList(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        int dwItems,
        Pointer<Pointer<Utf16>> strProfileNames,
        Pointer pReserved) =>
    _WlanSetProfileList(
        hClientHandle, pInterfaceGuid, dwItems, strProfileNames, pReserved);

final _WlanSetProfileList = _wlanapi.lookupFunction<
    Uint32 Function(
        IntPtr hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Uint32 dwItems,
        Pointer<Pointer<Utf16>> strProfileNames,
        Pointer pReserved),
    int Function(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        int dwItems,
        Pointer<Pointer<Utf16>> strProfileNames,
        Pointer pReserved)>('WlanSetProfileList');

/// The WlanSetProfilePosition function sets the position of a single,
/// specified profile in the preference list.
///
/// ```c
/// DWORD WlanSetProfilePosition(
///   HANDLE     hClientHandle,
///   const GUID *pInterfaceGuid,
///   LPCWSTR    strProfileName,
///   DWORD      dwPosition,
///   PVOID      pReserved
/// );
/// ```
/// {@category wlanapi}
int WlanSetProfilePosition(int hClientHandle, Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strProfileName, int dwPosition, Pointer pReserved) =>
    _WlanSetProfilePosition(
        hClientHandle, pInterfaceGuid, strProfileName, dwPosition, pReserved);

final _WlanSetProfilePosition = _wlanapi.lookupFunction<
    Uint32 Function(IntPtr hClientHandle, Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strProfileName, Uint32 dwPosition, Pointer pReserved),
    int Function(
        int hClientHandle,
        Pointer<GUID> pInterfaceGuid,
        Pointer<Utf16> strProfileName,
        int dwPosition,
        Pointer pReserved)>('WlanSetProfilePosition');

/// The WlanSetPsdIeDataList function sets the proximity service discovery
/// (PSD) information element (IE) data list.
///
/// ```c
/// DWORD WlanSetPsdIEDataList(
///   HANDLE                    hClientHandle,
///   LPCWSTR                   strFormat,
///   const PWLAN_RAW_DATA_LIST pPsdIEDataList,
///   PVOID                     pReserved
/// );
/// ```
/// {@category wlanapi}
int WlanSetPsdIEDataList(int hClientHandle, Pointer<Utf16> strFormat,
        Pointer<WLAN_RAW_DATA_LIST> pPsdIEDataList, Pointer pReserved) =>
    _WlanSetPsdIEDataList(hClientHandle, strFormat, pPsdIEDataList, pReserved);

final _WlanSetPsdIEDataList = _wlanapi.lookupFunction<
    Uint32 Function(IntPtr hClientHandle, Pointer<Utf16> strFormat,
        Pointer<WLAN_RAW_DATA_LIST> pPsdIEDataList, Pointer pReserved),
    int Function(
        int hClientHandle,
        Pointer<Utf16> strFormat,
        Pointer<WLAN_RAW_DATA_LIST> pPsdIEDataList,
        Pointer pReserved)>('WlanSetPsdIEDataList');

/// The WlanGetProfileList function sets the security settings for a
/// configurable object.
///
/// ```c
/// DWORD WlanSetSecuritySettings(
///   HANDLE                hClientHandle,
///   WLAN_SECURABLE_OBJECT SecurableObject,
///   LPCWSTR               strModifiedSDDL
/// );
/// ```
/// {@category wlanapi}
int WlanSetSecuritySettings(int hClientHandle, int SecurableObject,
        Pointer<Utf16> strModifiedSDDL) =>
    _WlanSetSecuritySettings(hClientHandle, SecurableObject, strModifiedSDDL);

final _WlanSetSecuritySettings = _wlanapi.lookupFunction<
    Uint32 Function(IntPtr hClientHandle, Int32 SecurableObject,
        Pointer<Utf16> strModifiedSDDL),
    int Function(int hClientHandle, int SecurableObject,
        Pointer<Utf16> strModifiedSDDL)>('WlanSetSecuritySettings');
