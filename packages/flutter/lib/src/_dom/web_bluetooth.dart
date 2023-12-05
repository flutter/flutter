// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'html.dart';
import 'permissions.dart';
import 'webidl.dart';

typedef UUID = String;
typedef BluetoothServiceUUID = JSAny;
typedef BluetoothCharacteristicUUID = JSAny;
typedef BluetoothDescriptorUUID = JSAny;

@JS()
@staticInterop
@anonymous
class BluetoothDataFilterInit {
  external factory BluetoothDataFilterInit({
    BufferSource dataPrefix,
    BufferSource mask,
  });
}

extension BluetoothDataFilterInitExtension on BluetoothDataFilterInit {
  external set dataPrefix(BufferSource value);
  external BufferSource get dataPrefix;
  external set mask(BufferSource value);
  external BufferSource get mask;
}

@JS()
@staticInterop
@anonymous
class BluetoothManufacturerDataFilterInit implements BluetoothDataFilterInit {
  external factory BluetoothManufacturerDataFilterInit(
      {required int companyIdentifier});
}

extension BluetoothManufacturerDataFilterInitExtension
    on BluetoothManufacturerDataFilterInit {
  external set companyIdentifier(int value);
  external int get companyIdentifier;
}

@JS()
@staticInterop
@anonymous
class BluetoothServiceDataFilterInit implements BluetoothDataFilterInit {
  external factory BluetoothServiceDataFilterInit(
      {required BluetoothServiceUUID service});
}

extension BluetoothServiceDataFilterInitExtension
    on BluetoothServiceDataFilterInit {
  external set service(BluetoothServiceUUID value);
  external BluetoothServiceUUID get service;
}

@JS()
@staticInterop
@anonymous
class BluetoothLEScanFilterInit {
  external factory BluetoothLEScanFilterInit({
    JSArray services,
    String name,
    String namePrefix,
    JSArray manufacturerData,
    JSArray serviceData,
  });
}

extension BluetoothLEScanFilterInitExtension on BluetoothLEScanFilterInit {
  external set services(JSArray value);
  external JSArray get services;
  external set name(String value);
  external String get name;
  external set namePrefix(String value);
  external String get namePrefix;
  external set manufacturerData(JSArray value);
  external JSArray get manufacturerData;
  external set serviceData(JSArray value);
  external JSArray get serviceData;
}

@JS()
@staticInterop
@anonymous
class RequestDeviceOptions {
  external factory RequestDeviceOptions({
    JSArray filters,
    JSArray exclusionFilters,
    JSArray optionalServices,
    JSArray optionalManufacturerData,
    bool acceptAllDevices,
  });
}

extension RequestDeviceOptionsExtension on RequestDeviceOptions {
  external set filters(JSArray value);
  external JSArray get filters;
  external set exclusionFilters(JSArray value);
  external JSArray get exclusionFilters;
  external set optionalServices(JSArray value);
  external JSArray get optionalServices;
  external set optionalManufacturerData(JSArray value);
  external JSArray get optionalManufacturerData;
  external set acceptAllDevices(bool value);
  external bool get acceptAllDevices;
}

@JS('Bluetooth')
@staticInterop
class Bluetooth implements EventTarget {}

extension BluetoothExtension on Bluetooth {
  external JSPromise getAvailability();
  external JSPromise getDevices();
  external JSPromise requestDevice([RequestDeviceOptions options]);
  external set onavailabilitychanged(EventHandler value);
  external EventHandler get onavailabilitychanged;
  external BluetoothDevice? get referringDevice;
  external set onadvertisementreceived(EventHandler value);
  external EventHandler get onadvertisementreceived;
  external set ongattserverdisconnected(EventHandler value);
  external EventHandler get ongattserverdisconnected;
  external set oncharacteristicvaluechanged(EventHandler value);
  external EventHandler get oncharacteristicvaluechanged;
  external set onserviceadded(EventHandler value);
  external EventHandler get onserviceadded;
  external set onservicechanged(EventHandler value);
  external EventHandler get onservicechanged;
  external set onserviceremoved(EventHandler value);
  external EventHandler get onserviceremoved;
}

@JS()
@staticInterop
@anonymous
class BluetoothPermissionDescriptor implements PermissionDescriptor {
  external factory BluetoothPermissionDescriptor({
    String deviceId,
    JSArray filters,
    JSArray optionalServices,
    JSArray optionalManufacturerData,
    bool acceptAllDevices,
  });
}

extension BluetoothPermissionDescriptorExtension
    on BluetoothPermissionDescriptor {
  external set deviceId(String value);
  external String get deviceId;
  external set filters(JSArray value);
  external JSArray get filters;
  external set optionalServices(JSArray value);
  external JSArray get optionalServices;
  external set optionalManufacturerData(JSArray value);
  external JSArray get optionalManufacturerData;
  external set acceptAllDevices(bool value);
  external bool get acceptAllDevices;
}

@JS()
@staticInterop
@anonymous
class AllowedBluetoothDevice {
  external factory AllowedBluetoothDevice({
    required String deviceId,
    required bool mayUseGATT,
    required JSAny allowedServices,
    required JSArray allowedManufacturerData,
  });
}

extension AllowedBluetoothDeviceExtension on AllowedBluetoothDevice {
  external set deviceId(String value);
  external String get deviceId;
  external set mayUseGATT(bool value);
  external bool get mayUseGATT;
  external set allowedServices(JSAny value);
  external JSAny get allowedServices;
  external set allowedManufacturerData(JSArray value);
  external JSArray get allowedManufacturerData;
}

@JS()
@staticInterop
@anonymous
class BluetoothPermissionStorage {
  external factory BluetoothPermissionStorage(
      {required JSArray allowedDevices});
}

extension BluetoothPermissionStorageExtension on BluetoothPermissionStorage {
  external set allowedDevices(JSArray value);
  external JSArray get allowedDevices;
}

@JS('BluetoothPermissionResult')
@staticInterop
class BluetoothPermissionResult implements PermissionStatus {}

extension BluetoothPermissionResultExtension on BluetoothPermissionResult {
  external set devices(JSArray value);
  external JSArray get devices;
}

@JS('ValueEvent')
@staticInterop
class ValueEvent implements Event {
  external factory ValueEvent(
    String type, [
    ValueEventInit initDict,
  ]);
}

extension ValueEventExtension on ValueEvent {
  external JSAny? get value;
}

@JS()
@staticInterop
@anonymous
class ValueEventInit implements EventInit {
  external factory ValueEventInit({JSAny? value});
}

extension ValueEventInitExtension on ValueEventInit {
  external set value(JSAny? value);
  external JSAny? get value;
}

@JS('BluetoothDevice')
@staticInterop
class BluetoothDevice implements EventTarget {}

extension BluetoothDeviceExtension on BluetoothDevice {
  external JSPromise forget();
  external JSPromise watchAdvertisements([WatchAdvertisementsOptions options]);
  external String get id;
  external String? get name;
  external BluetoothRemoteGATTServer? get gatt;
  external bool get watchingAdvertisements;
  external set onadvertisementreceived(EventHandler value);
  external EventHandler get onadvertisementreceived;
  external set ongattserverdisconnected(EventHandler value);
  external EventHandler get ongattserverdisconnected;
  external set oncharacteristicvaluechanged(EventHandler value);
  external EventHandler get oncharacteristicvaluechanged;
  external set onserviceadded(EventHandler value);
  external EventHandler get onserviceadded;
  external set onservicechanged(EventHandler value);
  external EventHandler get onservicechanged;
  external set onserviceremoved(EventHandler value);
  external EventHandler get onserviceremoved;
}

@JS()
@staticInterop
@anonymous
class WatchAdvertisementsOptions {
  external factory WatchAdvertisementsOptions({AbortSignal signal});
}

extension WatchAdvertisementsOptionsExtension on WatchAdvertisementsOptions {
  external set signal(AbortSignal value);
  external AbortSignal get signal;
}

@JS('BluetoothManufacturerDataMap')
@staticInterop
class BluetoothManufacturerDataMap {}

extension BluetoothManufacturerDataMapExtension
    on BluetoothManufacturerDataMap {}

@JS('BluetoothServiceDataMap')
@staticInterop
class BluetoothServiceDataMap {}

extension BluetoothServiceDataMapExtension on BluetoothServiceDataMap {}

@JS('BluetoothAdvertisingEvent')
@staticInterop
class BluetoothAdvertisingEvent implements Event {
  external factory BluetoothAdvertisingEvent(
    String type,
    BluetoothAdvertisingEventInit init,
  );
}

extension BluetoothAdvertisingEventExtension on BluetoothAdvertisingEvent {
  external BluetoothDevice get device;
  external JSArray get uuids;
  external String? get name;
  external int? get appearance;
  external int? get txPower;
  external int? get rssi;
  external BluetoothManufacturerDataMap get manufacturerData;
  external BluetoothServiceDataMap get serviceData;
}

@JS()
@staticInterop
@anonymous
class BluetoothAdvertisingEventInit implements EventInit {
  external factory BluetoothAdvertisingEventInit({
    required BluetoothDevice device,
    JSArray uuids,
    String name,
    int appearance,
    int txPower,
    int rssi,
    BluetoothManufacturerDataMap manufacturerData,
    BluetoothServiceDataMap serviceData,
  });
}

extension BluetoothAdvertisingEventInitExtension
    on BluetoothAdvertisingEventInit {
  external set device(BluetoothDevice value);
  external BluetoothDevice get device;
  external set uuids(JSArray value);
  external JSArray get uuids;
  external set name(String value);
  external String get name;
  external set appearance(int value);
  external int get appearance;
  external set txPower(int value);
  external int get txPower;
  external set rssi(int value);
  external int get rssi;
  external set manufacturerData(BluetoothManufacturerDataMap value);
  external BluetoothManufacturerDataMap get manufacturerData;
  external set serviceData(BluetoothServiceDataMap value);
  external BluetoothServiceDataMap get serviceData;
}

@JS('BluetoothRemoteGATTServer')
@staticInterop
class BluetoothRemoteGATTServer {}

extension BluetoothRemoteGATTServerExtension on BluetoothRemoteGATTServer {
  external JSPromise connect();
  external void disconnect();
  external JSPromise getPrimaryService(BluetoothServiceUUID service);
  external JSPromise getPrimaryServices([BluetoothServiceUUID service]);
  external BluetoothDevice get device;
  external bool get connected;
}

@JS('BluetoothRemoteGATTService')
@staticInterop
class BluetoothRemoteGATTService implements EventTarget {}

extension BluetoothRemoteGATTServiceExtension on BluetoothRemoteGATTService {
  external JSPromise getCharacteristic(
      BluetoothCharacteristicUUID characteristic);
  external JSPromise getCharacteristics(
      [BluetoothCharacteristicUUID characteristic]);
  external JSPromise getIncludedService(BluetoothServiceUUID service);
  external JSPromise getIncludedServices([BluetoothServiceUUID service]);
  external BluetoothDevice get device;
  external UUID get uuid;
  external bool get isPrimary;
  external set oncharacteristicvaluechanged(EventHandler value);
  external EventHandler get oncharacteristicvaluechanged;
  external set onserviceadded(EventHandler value);
  external EventHandler get onserviceadded;
  external set onservicechanged(EventHandler value);
  external EventHandler get onservicechanged;
  external set onserviceremoved(EventHandler value);
  external EventHandler get onserviceremoved;
}

@JS('BluetoothRemoteGATTCharacteristic')
@staticInterop
class BluetoothRemoteGATTCharacteristic implements EventTarget {}

extension BluetoothRemoteGATTCharacteristicExtension
    on BluetoothRemoteGATTCharacteristic {
  external JSPromise getDescriptor(BluetoothDescriptorUUID descriptor);
  external JSPromise getDescriptors([BluetoothDescriptorUUID descriptor]);
  external JSPromise readValue();
  external JSPromise writeValue(BufferSource value);
  external JSPromise writeValueWithResponse(BufferSource value);
  external JSPromise writeValueWithoutResponse(BufferSource value);
  external JSPromise startNotifications();
  external JSPromise stopNotifications();
  external BluetoothRemoteGATTService get service;
  external UUID get uuid;
  external BluetoothCharacteristicProperties get properties;
  external JSDataView? get value;
  external set oncharacteristicvaluechanged(EventHandler value);
  external EventHandler get oncharacteristicvaluechanged;
}

@JS('BluetoothCharacteristicProperties')
@staticInterop
class BluetoothCharacteristicProperties {}

extension BluetoothCharacteristicPropertiesExtension
    on BluetoothCharacteristicProperties {
  external bool get broadcast;
  external bool get read;
  external bool get writeWithoutResponse;
  external bool get write;
  external bool get notify;
  external bool get indicate;
  external bool get authenticatedSignedWrites;
  external bool get reliableWrite;
  external bool get writableAuxiliaries;
}

@JS('BluetoothRemoteGATTDescriptor')
@staticInterop
class BluetoothRemoteGATTDescriptor {}

extension BluetoothRemoteGATTDescriptorExtension
    on BluetoothRemoteGATTDescriptor {
  external JSPromise readValue();
  external JSPromise writeValue(BufferSource value);
  external BluetoothRemoteGATTCharacteristic get characteristic;
  external UUID get uuid;
  external JSDataView? get value;
}

@JS('BluetoothUUID')
@staticInterop
class BluetoothUUID {
  external static UUID getService(JSAny name);
  external static UUID getCharacteristic(JSAny name);
  external static UUID getDescriptor(JSAny name);
  external static UUID canonicalUUID(int alias);
}
