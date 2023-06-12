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

final _bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');

/// Specifies the end of reliable write procedures, and the writes should
/// be aborted.
///
/// ```c
/// HRESULT BluetoothGATTAbortReliableWrite(
///   HANDLE                             hDevice,
///   BTH_LE_GATT_RELIABLE_WRITE_CONTEXT ReliableWriteContext,
///   ULONG                              Flags
/// );
/// ```
/// {@category bluetooth}
int BluetoothGATTAbortReliableWrite(
        int hDevice, int ReliableWriteContext, int Flags) =>
    _BluetoothGATTAbortReliableWrite(hDevice, ReliableWriteContext, Flags);

final _BluetoothGATTAbortReliableWrite = _bluetoothapis.lookupFunction<
    Int32 Function(IntPtr hDevice, Uint64 ReliableWriteContext, Uint32 Flags),
    int Function(int hDevice, int ReliableWriteContext,
        int Flags)>('BluetoothGATTAbortReliableWrite');

/// The BluetoothGATTBeginReliableWrite function specifies that reliable
/// writes are about to begin.
///
/// ```c
/// HRESULT BluetoothGATTBeginReliableWrite(
///   HANDLE                              hDevice,
///   PBTH_LE_GATT_RELIABLE_WRITE_CONTEXT ReliableWriteContext,
///   ULONG                               Flags
/// );
/// ```
/// {@category bluetooth}
int BluetoothGATTBeginReliableWrite(
        int hDevice, Pointer<Uint64> ReliableWriteContext, int Flags) =>
    _BluetoothGATTBeginReliableWrite(hDevice, ReliableWriteContext, Flags);

final _BluetoothGATTBeginReliableWrite = _bluetoothapis.lookupFunction<
    Int32 Function(
        IntPtr hDevice, Pointer<Uint64> ReliableWriteContext, Uint32 Flags),
    int Function(int hDevice, Pointer<Uint64> ReliableWriteContext,
        int Flags)>('BluetoothGATTBeginReliableWrite');

/// Specifies the end of reliable writes, and the writes should be
/// committed.
///
/// ```c
/// HRESULT BluetoothGATTEndReliableWrite(
///   HANDLE                             hDevice,
///   BTH_LE_GATT_RELIABLE_WRITE_CONTEXT ReliableWriteContext,
///   ULONG                              Flags
/// );
/// ```
/// {@category bluetooth}
int BluetoothGATTEndReliableWrite(
        int hDevice, int ReliableWriteContext, int Flags) =>
    _BluetoothGATTEndReliableWrite(hDevice, ReliableWriteContext, Flags);

final _BluetoothGATTEndReliableWrite = _bluetoothapis.lookupFunction<
    Int32 Function(IntPtr hDevice, Uint64 ReliableWriteContext, Uint32 Flags),
    int Function(int hDevice, int ReliableWriteContext,
        int Flags)>('BluetoothGATTEndReliableWrite');

/// Gets all the characteristics available for the specified service.
///
/// ```c
/// HRESULT BluetoothGATTGetCharacteristics(
///   HANDLE                      hDevice,
///   PBTH_LE_GATT_SERVICE        Service,
///   USHORT                      CharacteristicsBufferCount,
///   PBTH_LE_GATT_CHARACTERISTIC CharacteristicsBuffer,
///   USHORT                      *CharacteristicsBufferActual,
///   ULONG                       Flags
/// );
/// ```
/// {@category bluetooth}
int BluetoothGATTGetCharacteristics(
        int hDevice,
        Pointer<BTH_LE_GATT_SERVICE> Service,
        int CharacteristicsBufferCount,
        Pointer<BTH_LE_GATT_CHARACTERISTIC> CharacteristicsBuffer,
        Pointer<Uint16> CharacteristicsBufferActual,
        int Flags) =>
    _BluetoothGATTGetCharacteristics(
        hDevice,
        Service,
        CharacteristicsBufferCount,
        CharacteristicsBuffer,
        CharacteristicsBufferActual,
        Flags);

final _BluetoothGATTGetCharacteristics = _bluetoothapis.lookupFunction<
    Int32 Function(
        IntPtr hDevice,
        Pointer<BTH_LE_GATT_SERVICE> Service,
        Uint16 CharacteristicsBufferCount,
        Pointer<BTH_LE_GATT_CHARACTERISTIC> CharacteristicsBuffer,
        Pointer<Uint16> CharacteristicsBufferActual,
        Uint32 Flags),
    int Function(
        int hDevice,
        Pointer<BTH_LE_GATT_SERVICE> Service,
        int CharacteristicsBufferCount,
        Pointer<BTH_LE_GATT_CHARACTERISTIC> CharacteristicsBuffer,
        Pointer<Uint16> CharacteristicsBufferActual,
        int Flags)>('BluetoothGATTGetCharacteristics');

/// Gets the value of the specified characteristic.
///
/// ```c
/// HRESULT BluetoothGATTGetCharacteristicValue(
///   HANDLE                            hDevice,
///   PBTH_LE_GATT_CHARACTERISTIC       Characteristic,
///   ULONG                             CharacteristicValueDataSize,
///   PBTH_LE_GATT_CHARACTERISTIC_VALUE CharacteristicValue,
///   USHORT                            *CharacteristicValueSizeRequired,
///   ULONG                             Flags
/// );
/// ```
/// {@category bluetooth}
int BluetoothGATTGetCharacteristicValue(
        int hDevice,
        Pointer<BTH_LE_GATT_CHARACTERISTIC> Characteristic,
        int CharacteristicValueDataSize,
        Pointer<BTH_LE_GATT_CHARACTERISTIC_VALUE> CharacteristicValue,
        Pointer<Uint16> CharacteristicValueSizeRequired,
        int Flags) =>
    _BluetoothGATTGetCharacteristicValue(
        hDevice,
        Characteristic,
        CharacteristicValueDataSize,
        CharacteristicValue,
        CharacteristicValueSizeRequired,
        Flags);

final _BluetoothGATTGetCharacteristicValue = _bluetoothapis.lookupFunction<
    Int32 Function(
        IntPtr hDevice,
        Pointer<BTH_LE_GATT_CHARACTERISTIC> Characteristic,
        Uint32 CharacteristicValueDataSize,
        Pointer<BTH_LE_GATT_CHARACTERISTIC_VALUE> CharacteristicValue,
        Pointer<Uint16> CharacteristicValueSizeRequired,
        Uint32 Flags),
    int Function(
        int hDevice,
        Pointer<BTH_LE_GATT_CHARACTERISTIC> Characteristic,
        int CharacteristicValueDataSize,
        Pointer<BTH_LE_GATT_CHARACTERISTIC_VALUE> CharacteristicValue,
        Pointer<Uint16> CharacteristicValueSizeRequired,
        int Flags)>('BluetoothGATTGetCharacteristicValue');

/// Gets all the descriptors available for the specified characteristic.
///
/// ```c
/// HRESULT BluetoothGATTGetDescriptors(
///   HANDLE                      hDevice,
///   PBTH_LE_GATT_CHARACTERISTIC Characteristic,
///   USHORT                      DescriptorsBufferCount,
///   PBTH_LE_GATT_DESCRIPTOR     DescriptorsBuffer,
///   USHORT                      *DescriptorsBufferActual,
///   ULONG                       Flags
/// );
/// ```
/// {@category bluetooth}
int BluetoothGATTGetDescriptors(
        int hDevice,
        Pointer<BTH_LE_GATT_CHARACTERISTIC> Characteristic,
        int DescriptorsBufferCount,
        Pointer<BTH_LE_GATT_DESCRIPTOR> DescriptorsBuffer,
        Pointer<Uint16> DescriptorsBufferActual,
        int Flags) =>
    _BluetoothGATTGetDescriptors(
        hDevice,
        Characteristic,
        DescriptorsBufferCount,
        DescriptorsBuffer,
        DescriptorsBufferActual,
        Flags);

final _BluetoothGATTGetDescriptors = _bluetoothapis.lookupFunction<
    Int32 Function(
        IntPtr hDevice,
        Pointer<BTH_LE_GATT_CHARACTERISTIC> Characteristic,
        Uint16 DescriptorsBufferCount,
        Pointer<BTH_LE_GATT_DESCRIPTOR> DescriptorsBuffer,
        Pointer<Uint16> DescriptorsBufferActual,
        Uint32 Flags),
    int Function(
        int hDevice,
        Pointer<BTH_LE_GATT_CHARACTERISTIC> Characteristic,
        int DescriptorsBufferCount,
        Pointer<BTH_LE_GATT_DESCRIPTOR> DescriptorsBuffer,
        Pointer<Uint16> DescriptorsBufferActual,
        int Flags)>('BluetoothGATTGetDescriptors');

/// Gets the value of the specified descriptor.
///
/// ```c
/// HRESULT BluetoothGATTGetDescriptorValue(
///   HANDLE                        hDevice,
///   PBTH_LE_GATT_DESCRIPTOR       Descriptor,
///   ULONG                         DescriptorValueDataSize,
///   PBTH_LE_GATT_DESCRIPTOR_VALUE DescriptorValue,
///   USHORT                        *DescriptorValueSizeRequired,
///   ULONG                         Flags
/// );
/// ```
/// {@category bluetooth}
int BluetoothGATTGetDescriptorValue(
        int hDevice,
        Pointer<BTH_LE_GATT_DESCRIPTOR> Descriptor,
        int DescriptorValueDataSize,
        Pointer<BTH_LE_GATT_DESCRIPTOR_VALUE> DescriptorValue,
        Pointer<Uint16> DescriptorValueSizeRequired,
        int Flags) =>
    _BluetoothGATTGetDescriptorValue(
        hDevice,
        Descriptor,
        DescriptorValueDataSize,
        DescriptorValue,
        DescriptorValueSizeRequired,
        Flags);

final _BluetoothGATTGetDescriptorValue = _bluetoothapis.lookupFunction<
    Int32 Function(
        IntPtr hDevice,
        Pointer<BTH_LE_GATT_DESCRIPTOR> Descriptor,
        Uint32 DescriptorValueDataSize,
        Pointer<BTH_LE_GATT_DESCRIPTOR_VALUE> DescriptorValue,
        Pointer<Uint16> DescriptorValueSizeRequired,
        Uint32 Flags),
    int Function(
        int hDevice,
        Pointer<BTH_LE_GATT_DESCRIPTOR> Descriptor,
        int DescriptorValueDataSize,
        Pointer<BTH_LE_GATT_DESCRIPTOR_VALUE> DescriptorValue,
        Pointer<Uint16> DescriptorValueSizeRequired,
        int Flags)>('BluetoothGATTGetDescriptorValue');

/// Gets all the included services available for a given service.
///
/// ```c
/// HRESULT BluetoothGATTGetIncludedServices(
///   HANDLE               hDevice,
///   PBTH_LE_GATT_SERVICE ParentService,
///   USHORT               IncludedServicesBufferCount,
///   PBTH_LE_GATT_SERVICE IncludedServicesBuffer,
///   USHORT               *IncludedServicesBufferActual,
///   ULONG                Flags
/// );
/// ```
/// {@category bluetooth}
int BluetoothGATTGetIncludedServices(
        int hDevice,
        Pointer<BTH_LE_GATT_SERVICE> ParentService,
        int IncludedServicesBufferCount,
        Pointer<BTH_LE_GATT_SERVICE> IncludedServicesBuffer,
        Pointer<Uint16> IncludedServicesBufferActual,
        int Flags) =>
    _BluetoothGATTGetIncludedServices(
        hDevice,
        ParentService,
        IncludedServicesBufferCount,
        IncludedServicesBuffer,
        IncludedServicesBufferActual,
        Flags);

final _BluetoothGATTGetIncludedServices = _bluetoothapis.lookupFunction<
    Int32 Function(
        IntPtr hDevice,
        Pointer<BTH_LE_GATT_SERVICE> ParentService,
        Uint16 IncludedServicesBufferCount,
        Pointer<BTH_LE_GATT_SERVICE> IncludedServicesBuffer,
        Pointer<Uint16> IncludedServicesBufferActual,
        Uint32 Flags),
    int Function(
        int hDevice,
        Pointer<BTH_LE_GATT_SERVICE> ParentService,
        int IncludedServicesBufferCount,
        Pointer<BTH_LE_GATT_SERVICE> IncludedServicesBuffer,
        Pointer<Uint16> IncludedServicesBufferActual,
        int Flags)>('BluetoothGATTGetIncludedServices');

/// The BluetoothGATTGetServices function gets all the primary services
/// available for a server.
///
/// ```c
/// HRESULT BluetoothGATTGetServices(
///   HANDLE               hDevice,
///   USHORT               ServicesBufferCount,
///   PBTH_LE_GATT_SERVICE ServicesBuffer,
///   USHORT               *ServicesBufferActual,
///   ULONG                Flags
/// );
/// ```
/// {@category bluetooth}
int BluetoothGATTGetServices(
        int hDevice,
        int ServicesBufferCount,
        Pointer<BTH_LE_GATT_SERVICE> ServicesBuffer,
        Pointer<Uint16> ServicesBufferActual,
        int Flags) =>
    _BluetoothGATTGetServices(hDevice, ServicesBufferCount, ServicesBuffer,
        ServicesBufferActual, Flags);

final _BluetoothGATTGetServices = _bluetoothapis.lookupFunction<
    Int32 Function(
        IntPtr hDevice,
        Uint16 ServicesBufferCount,
        Pointer<BTH_LE_GATT_SERVICE> ServicesBuffer,
        Pointer<Uint16> ServicesBufferActual,
        Uint32 Flags),
    int Function(
        int hDevice,
        int ServicesBufferCount,
        Pointer<BTH_LE_GATT_SERVICE> ServicesBuffer,
        Pointer<Uint16> ServicesBufferActual,
        int Flags)>('BluetoothGATTGetServices');

/// Registers a routine to be called back during a characteristic value
/// change event on the given characteristic identified by its
/// characteristic handle.
///
/// ```c
/// HRESULT BluetoothGATTRegisterEvent(
///   HANDLE                           hService,
///   BTH_LE_GATT_EVENT_TYPE           EventType,
///   PVOID                            EventParameterIn,
///   PFNBLUETOOTH_GATT_EVENT_CALLBACK Callback,
///   PVOID                            CallbackContext,
///   BLUETOOTH_GATT_EVENT_HANDLE      *pEventHandle,
///   ULONG                            Flags
/// );
/// ```
/// {@category bluetooth}
int BluetoothGATTRegisterEvent(
        int hService,
        int EventType,
        Pointer EventParameterIn,
        Pointer<NativeFunction<PfnbluetoothGattEventCallback>> Callback,
        Pointer CallbackContext,
        Pointer<IntPtr> pEventHandle,
        int Flags) =>
    _BluetoothGATTRegisterEvent(hService, EventType, EventParameterIn, Callback,
        CallbackContext, pEventHandle, Flags);

final _BluetoothGATTRegisterEvent = _bluetoothapis.lookupFunction<
    Int32 Function(
        IntPtr hService,
        Int32 EventType,
        Pointer EventParameterIn,
        Pointer<NativeFunction<PfnbluetoothGattEventCallback>> Callback,
        Pointer CallbackContext,
        Pointer<IntPtr> pEventHandle,
        Uint32 Flags),
    int Function(
        int hService,
        int EventType,
        Pointer EventParameterIn,
        Pointer<NativeFunction<PfnbluetoothGattEventCallback>> Callback,
        Pointer CallbackContext,
        Pointer<IntPtr> pEventHandle,
        int Flags)>('BluetoothGATTRegisterEvent');

/// Writes the specified characteristic value to the Bluetooth device.
///
/// ```c
/// HRESULT BluetoothGATTSetCharacteristicValue(
///   HANDLE                             hDevice,
///   PBTH_LE_GATT_CHARACTERISTIC        Characteristic,
///   PBTH_LE_GATT_CHARACTERISTIC_VALUE  CharacteristicValue,
///   BTH_LE_GATT_RELIABLE_WRITE_CONTEXT ReliableWriteContext,
///   ULONG                              Flags
/// );
/// ```
/// {@category bluetooth}
int BluetoothGATTSetCharacteristicValue(
        int hDevice,
        Pointer<BTH_LE_GATT_CHARACTERISTIC> Characteristic,
        Pointer<BTH_LE_GATT_CHARACTERISTIC_VALUE> CharacteristicValue,
        int ReliableWriteContext,
        int Flags) =>
    _BluetoothGATTSetCharacteristicValue(hDevice, Characteristic,
        CharacteristicValue, ReliableWriteContext, Flags);

final _BluetoothGATTSetCharacteristicValue = _bluetoothapis.lookupFunction<
    Int32 Function(
        IntPtr hDevice,
        Pointer<BTH_LE_GATT_CHARACTERISTIC> Characteristic,
        Pointer<BTH_LE_GATT_CHARACTERISTIC_VALUE> CharacteristicValue,
        Uint64 ReliableWriteContext,
        Uint32 Flags),
    int Function(
        int hDevice,
        Pointer<BTH_LE_GATT_CHARACTERISTIC> Characteristic,
        Pointer<BTH_LE_GATT_CHARACTERISTIC_VALUE> CharacteristicValue,
        int ReliableWriteContext,
        int Flags)>('BluetoothGATTSetCharacteristicValue');

/// Writes the specified descriptor value to the Bluetooth device.
///
/// ```c
/// HRESULT BluetoothGATTSetDescriptorValue(
///   HANDLE                        hDevice,
///   PBTH_LE_GATT_DESCRIPTOR       Descriptor,
///   PBTH_LE_GATT_DESCRIPTOR_VALUE DescriptorValue,
///   ULONG                         Flags
/// );
/// ```
/// {@category bluetooth}
int BluetoothGATTSetDescriptorValue(
        int hDevice,
        Pointer<BTH_LE_GATT_DESCRIPTOR> Descriptor,
        Pointer<BTH_LE_GATT_DESCRIPTOR_VALUE> DescriptorValue,
        int Flags) =>
    _BluetoothGATTSetDescriptorValue(
        hDevice, Descriptor, DescriptorValue, Flags);

final _BluetoothGATTSetDescriptorValue = _bluetoothapis.lookupFunction<
    Int32 Function(IntPtr hDevice, Pointer<BTH_LE_GATT_DESCRIPTOR> Descriptor,
        Pointer<BTH_LE_GATT_DESCRIPTOR_VALUE> DescriptorValue, Uint32 Flags),
    int Function(
        int hDevice,
        Pointer<BTH_LE_GATT_DESCRIPTOR> Descriptor,
        Pointer<BTH_LE_GATT_DESCRIPTOR_VALUE> DescriptorValue,
        int Flags)>('BluetoothGATTSetDescriptorValue');

/// Unregisters the given characteristic value change event.
///
/// ```c
/// HRESULT BluetoothGATTUnregisterEvent(
///   BLUETOOTH_GATT_EVENT_HANDLE EventHandle,
///   ULONG                       Flags
/// );
/// ```
/// {@category bluetooth}
int BluetoothGATTUnregisterEvent(int EventHandle, int Flags) =>
    _BluetoothGATTUnregisterEvent(EventHandle, Flags);

final _BluetoothGATTUnregisterEvent = _bluetoothapis.lookupFunction<
    Int32 Function(IntPtr EventHandle, Uint32 Flags),
    int Function(int EventHandle, int Flags)>('BluetoothGATTUnregisterEvent');
