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

final _iphlpapi = DynamicLibrary.open('iphlpapi.dll');

/// The AddIPAddress function adds the specified IPv4 address to the
/// specified adapter.
///
/// ```c
/// DWORD AddIPAddress(
///   IPAddr Address,
///   IPMask IpMask,
///   DWORD  IfIndex,
///   PULONG NTEContext,
///   PULONG NTEInstance
/// );
/// ```
/// {@category iphlpapi}
int AddIPAddress(int Address, int IpMask, int IfIndex,
        Pointer<Uint32> NTEContext, Pointer<Uint32> NTEInstance) =>
    _AddIPAddress(Address, IpMask, IfIndex, NTEContext, NTEInstance);

final _AddIPAddress = _iphlpapi.lookupFunction<
    Uint32 Function(Uint32 Address, Uint32 IpMask, Uint32 IfIndex,
        Pointer<Uint32> NTEContext, Pointer<Uint32> NTEInstance),
    int Function(
        int Address,
        int IpMask,
        int IfIndex,
        Pointer<Uint32> NTEContext,
        Pointer<Uint32> NTEInstance)>('AddIPAddress');

/// The DeleteIPAddress function deletes an IP address previously added
/// using AddIPAddress.
///
/// ```c
/// DWORD DeleteIPAddress(
///   ULONG NTEContext
/// );
/// ```
/// {@category iphlpapi}
int DeleteIPAddress(int NTEContext) => _DeleteIPAddress(NTEContext);

final _DeleteIPAddress = _iphlpapi.lookupFunction<
    Uint32 Function(Uint32 NTEContext),
    int Function(int NTEContext)>('DeleteIPAddress');

/// The GetAdapterIndex function obtains the index of an adapter, given its
/// name.
///
/// ```c
/// DWORD GetAdapterIndex(
///   LPWSTR AdapterName,
///   PULONG IfIndex
/// );
/// ```
/// {@category iphlpapi}
int GetAdapterIndex(Pointer<Utf16> AdapterName, Pointer<Uint32> IfIndex) =>
    _GetAdapterIndex(AdapterName, IfIndex);

final _GetAdapterIndex = _iphlpapi.lookupFunction<
    Uint32 Function(Pointer<Utf16> AdapterName, Pointer<Uint32> IfIndex),
    int Function(Pointer<Utf16> AdapterName,
        Pointer<Uint32> IfIndex)>('GetAdapterIndex');

/// The GetAdaptersAddresses function retrieves the addresses associated
/// with the adapters on the local computer.
///
/// ```c
/// ULONG GetAdaptersAddresses(
///   ULONG                 Family,
///   ULONG                 Flags,
///   PVOID                 Reserved,
///   PIP_ADAPTER_ADDRESSES AdapterAddresses,
///   PULONG                SizePointer
/// );
/// ```
/// {@category iphlpapi}
int GetAdaptersAddresses(
        int Family,
        int Flags,
        Pointer Reserved,
        Pointer<IP_ADAPTER_ADDRESSES_LH> AdapterAddresses,
        Pointer<Uint32> SizePointer) =>
    _GetAdaptersAddresses(
        Family, Flags, Reserved, AdapterAddresses, SizePointer);

final _GetAdaptersAddresses = _iphlpapi.lookupFunction<
    Uint32 Function(
        Uint32 Family,
        Uint32 Flags,
        Pointer Reserved,
        Pointer<IP_ADAPTER_ADDRESSES_LH> AdapterAddresses,
        Pointer<Uint32> SizePointer),
    int Function(
        int Family,
        int Flags,
        Pointer Reserved,
        Pointer<IP_ADAPTER_ADDRESSES_LH> AdapterAddresses,
        Pointer<Uint32> SizePointer)>('GetAdaptersAddresses');

/// The GetInterfaceInfo function obtains the list of the network interface
/// adapters with IPv4 enabled on the local system.
///
/// ```c
/// DWORD GetInterfaceInfo(
///   PIP_INTERFACE_INFO pIfTable,
///   PULONG             dwOutBufLen
/// );
/// ```
/// {@category iphlpapi}
int GetInterfaceInfo(
        Pointer<IP_INTERFACE_INFO> pIfTable, Pointer<Uint32> dwOutBufLen) =>
    _GetInterfaceInfo(pIfTable, dwOutBufLen);

final _GetInterfaceInfo = _iphlpapi.lookupFunction<
    Uint32 Function(
        Pointer<IP_INTERFACE_INFO> pIfTable, Pointer<Uint32> dwOutBufLen),
    int Function(Pointer<IP_INTERFACE_INFO> pIfTable,
        Pointer<Uint32> dwOutBufLen)>('GetInterfaceInfo');

/// The GetPerAdapterInfo function retrieves information about the adapter
/// corresponding to the specified interface.
///
/// ```c
/// DWORD GetPerAdapterInfo(
///   ULONG                IfIndex,
///   PIP_PER_ADAPTER_INFO pPerAdapterInfo,
///   PULONG               pOutBufLen
/// );
/// ```
/// {@category iphlpapi}
int GetPerAdapterInfo(
        int IfIndex,
        Pointer<IP_PER_ADAPTER_INFO_W2KSP1> pPerAdapterInfo,
        Pointer<Uint32> pOutBufLen) =>
    _GetPerAdapterInfo(IfIndex, pPerAdapterInfo, pOutBufLen);

final _GetPerAdapterInfo = _iphlpapi.lookupFunction<
    Uint32 Function(
        Uint32 IfIndex,
        Pointer<IP_PER_ADAPTER_INFO_W2KSP1> pPerAdapterInfo,
        Pointer<Uint32> pOutBufLen),
    int Function(
        int IfIndex,
        Pointer<IP_PER_ADAPTER_INFO_W2KSP1> pPerAdapterInfo,
        Pointer<Uint32> pOutBufLen)>('GetPerAdapterInfo');

/// The IpReleaseAddress function releases an IPv4 address previously
/// obtained through the Dynamic Host Configuration Protocol (DHCP).
///
/// ```c
/// DWORD IpReleaseAddress(
///   PIP_ADAPTER_INDEX_MAP AdapterInfo
/// );
/// ```
/// {@category iphlpapi}
int IpReleaseAddress(Pointer<IP_ADAPTER_INDEX_MAP> AdapterInfo) =>
    _IpReleaseAddress(AdapterInfo);

final _IpReleaseAddress = _iphlpapi.lookupFunction<
    Uint32 Function(Pointer<IP_ADAPTER_INDEX_MAP> AdapterInfo),
    int Function(
        Pointer<IP_ADAPTER_INDEX_MAP> AdapterInfo)>('IpReleaseAddress');

/// The IpRenewAddress function renews a lease on an IPv4 address previously
/// obtained through Dynamic Host Configuration Protocol (DHCP).
///
/// ```c
/// DWORD IpRenewAddress(
///   PIP_ADAPTER_INDEX_MAP AdapterInfo
/// );
/// ```
/// {@category iphlpapi}
int IpRenewAddress(Pointer<IP_ADAPTER_INDEX_MAP> AdapterInfo) =>
    _IpRenewAddress(AdapterInfo);

final _IpRenewAddress = _iphlpapi.lookupFunction<
    Uint32 Function(Pointer<IP_ADAPTER_INDEX_MAP> AdapterInfo),
    int Function(Pointer<IP_ADAPTER_INDEX_MAP> AdapterInfo)>('IpRenewAddress');
