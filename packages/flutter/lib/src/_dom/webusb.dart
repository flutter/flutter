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

typedef USBTransferStatus = String;
typedef USBRequestType = String;
typedef USBRecipient = String;
typedef USBDirection = String;
typedef USBEndpointType = String;

@JS()
@staticInterop
@anonymous
class USBDeviceFilter {
  external factory USBDeviceFilter({
    int vendorId,
    int productId,
    int classCode,
    int subclassCode,
    int protocolCode,
    String serialNumber,
  });
}

extension USBDeviceFilterExtension on USBDeviceFilter {
  external set vendorId(int value);
  external int get vendorId;
  external set productId(int value);
  external int get productId;
  external set classCode(int value);
  external int get classCode;
  external set subclassCode(int value);
  external int get subclassCode;
  external set protocolCode(int value);
  external int get protocolCode;
  external set serialNumber(String value);
  external String get serialNumber;
}

@JS()
@staticInterop
@anonymous
class USBDeviceRequestOptions {
  external factory USBDeviceRequestOptions({
    required JSArray filters,
    JSArray exclusionFilters,
  });
}

extension USBDeviceRequestOptionsExtension on USBDeviceRequestOptions {
  external set filters(JSArray value);
  external JSArray get filters;
  external set exclusionFilters(JSArray value);
  external JSArray get exclusionFilters;
}

@JS('USB')
@staticInterop
class USB implements EventTarget {}

extension USBExtension on USB {
  external JSPromise getDevices();
  external JSPromise requestDevice(USBDeviceRequestOptions options);
  external set onconnect(EventHandler value);
  external EventHandler get onconnect;
  external set ondisconnect(EventHandler value);
  external EventHandler get ondisconnect;
}

@JS()
@staticInterop
@anonymous
class USBConnectionEventInit implements EventInit {
  external factory USBConnectionEventInit({required USBDevice device});
}

extension USBConnectionEventInitExtension on USBConnectionEventInit {
  external set device(USBDevice value);
  external USBDevice get device;
}

@JS('USBConnectionEvent')
@staticInterop
class USBConnectionEvent implements Event {
  external factory USBConnectionEvent(
    String type,
    USBConnectionEventInit eventInitDict,
  );
}

extension USBConnectionEventExtension on USBConnectionEvent {
  external USBDevice get device;
}

@JS('USBInTransferResult')
@staticInterop
class USBInTransferResult {
  external factory USBInTransferResult(
    USBTransferStatus status, [
    JSDataView? data,
  ]);
}

extension USBInTransferResultExtension on USBInTransferResult {
  external JSDataView? get data;
  external USBTransferStatus get status;
}

@JS('USBOutTransferResult')
@staticInterop
class USBOutTransferResult {
  external factory USBOutTransferResult(
    USBTransferStatus status, [
    int bytesWritten,
  ]);
}

extension USBOutTransferResultExtension on USBOutTransferResult {
  external int get bytesWritten;
  external USBTransferStatus get status;
}

@JS('USBIsochronousInTransferPacket')
@staticInterop
class USBIsochronousInTransferPacket {
  external factory USBIsochronousInTransferPacket(
    USBTransferStatus status, [
    JSDataView? data,
  ]);
}

extension USBIsochronousInTransferPacketExtension
    on USBIsochronousInTransferPacket {
  external JSDataView? get data;
  external USBTransferStatus get status;
}

@JS('USBIsochronousInTransferResult')
@staticInterop
class USBIsochronousInTransferResult {
  external factory USBIsochronousInTransferResult(
    JSArray packets, [
    JSDataView? data,
  ]);
}

extension USBIsochronousInTransferResultExtension
    on USBIsochronousInTransferResult {
  external JSDataView? get data;
  external JSArray get packets;
}

@JS('USBIsochronousOutTransferPacket')
@staticInterop
class USBIsochronousOutTransferPacket {
  external factory USBIsochronousOutTransferPacket(
    USBTransferStatus status, [
    int bytesWritten,
  ]);
}

extension USBIsochronousOutTransferPacketExtension
    on USBIsochronousOutTransferPacket {
  external int get bytesWritten;
  external USBTransferStatus get status;
}

@JS('USBIsochronousOutTransferResult')
@staticInterop
class USBIsochronousOutTransferResult {
  external factory USBIsochronousOutTransferResult(JSArray packets);
}

extension USBIsochronousOutTransferResultExtension
    on USBIsochronousOutTransferResult {
  external JSArray get packets;
}

@JS('USBDevice')
@staticInterop
class USBDevice {}

extension USBDeviceExtension on USBDevice {
  external JSPromise open();
  external JSPromise close();
  external JSPromise forget();
  external JSPromise selectConfiguration(int configurationValue);
  external JSPromise claimInterface(int interfaceNumber);
  external JSPromise releaseInterface(int interfaceNumber);
  external JSPromise selectAlternateInterface(
    int interfaceNumber,
    int alternateSetting,
  );
  external JSPromise controlTransferIn(
    USBControlTransferParameters setup,
    int length,
  );
  external JSPromise controlTransferOut(
    USBControlTransferParameters setup, [
    BufferSource data,
  ]);
  external JSPromise clearHalt(
    USBDirection direction,
    int endpointNumber,
  );
  external JSPromise transferIn(
    int endpointNumber,
    int length,
  );
  external JSPromise transferOut(
    int endpointNumber,
    BufferSource data,
  );
  external JSPromise isochronousTransferIn(
    int endpointNumber,
    JSArray packetLengths,
  );
  external JSPromise isochronousTransferOut(
    int endpointNumber,
    BufferSource data,
    JSArray packetLengths,
  );
  external JSPromise reset();
  external int get usbVersionMajor;
  external int get usbVersionMinor;
  external int get usbVersionSubminor;
  external int get deviceClass;
  external int get deviceSubclass;
  external int get deviceProtocol;
  external int get vendorId;
  external int get productId;
  external int get deviceVersionMajor;
  external int get deviceVersionMinor;
  external int get deviceVersionSubminor;
  external String? get manufacturerName;
  external String? get productName;
  external String? get serialNumber;
  external USBConfiguration? get configuration;
  external JSArray get configurations;
  external bool get opened;
}

@JS()
@staticInterop
@anonymous
class USBControlTransferParameters {
  external factory USBControlTransferParameters({
    required USBRequestType requestType,
    required USBRecipient recipient,
    required int request,
    required int value,
    required int index,
  });
}

extension USBControlTransferParametersExtension
    on USBControlTransferParameters {
  external set requestType(USBRequestType value);
  external USBRequestType get requestType;
  external set recipient(USBRecipient value);
  external USBRecipient get recipient;
  external set request(int value);
  external int get request;
  external set value(int value);
  external int get value;
  external set index(int value);
  external int get index;
}

@JS('USBConfiguration')
@staticInterop
class USBConfiguration {
  external factory USBConfiguration(
    USBDevice device,
    int configurationValue,
  );
}

extension USBConfigurationExtension on USBConfiguration {
  external int get configurationValue;
  external String? get configurationName;
  external JSArray get interfaces;
}

@JS('USBInterface')
@staticInterop
class USBInterface {
  external factory USBInterface(
    USBConfiguration configuration,
    int interfaceNumber,
  );
}

extension USBInterfaceExtension on USBInterface {
  external int get interfaceNumber;
  external USBAlternateInterface get alternate;
  external JSArray get alternates;
  external bool get claimed;
}

@JS('USBAlternateInterface')
@staticInterop
class USBAlternateInterface {
  external factory USBAlternateInterface(
    USBInterface deviceInterface,
    int alternateSetting,
  );
}

extension USBAlternateInterfaceExtension on USBAlternateInterface {
  external int get alternateSetting;
  external int get interfaceClass;
  external int get interfaceSubclass;
  external int get interfaceProtocol;
  external String? get interfaceName;
  external JSArray get endpoints;
}

@JS('USBEndpoint')
@staticInterop
class USBEndpoint {
  external factory USBEndpoint(
    USBAlternateInterface alternate,
    int endpointNumber,
    USBDirection direction,
  );
}

extension USBEndpointExtension on USBEndpoint {
  external int get endpointNumber;
  external USBDirection get direction;
  external USBEndpointType get type;
  external int get packetSize;
}

@JS()
@staticInterop
@anonymous
class USBPermissionDescriptor implements PermissionDescriptor {
  external factory USBPermissionDescriptor({
    JSArray filters,
    JSArray exclusionFilters,
  });
}

extension USBPermissionDescriptorExtension on USBPermissionDescriptor {
  external set filters(JSArray value);
  external JSArray get filters;
  external set exclusionFilters(JSArray value);
  external JSArray get exclusionFilters;
}

@JS()
@staticInterop
@anonymous
class AllowedUSBDevice {
  external factory AllowedUSBDevice({
    required int vendorId,
    required int productId,
    String serialNumber,
  });
}

extension AllowedUSBDeviceExtension on AllowedUSBDevice {
  external set vendorId(int value);
  external int get vendorId;
  external set productId(int value);
  external int get productId;
  external set serialNumber(String value);
  external String get serialNumber;
}

@JS()
@staticInterop
@anonymous
class USBPermissionStorage {
  external factory USBPermissionStorage({JSArray allowedDevices});
}

extension USBPermissionStorageExtension on USBPermissionStorage {
  external set allowedDevices(JSArray value);
  external JSArray get allowedDevices;
}

@JS('USBPermissionResult')
@staticInterop
class USBPermissionResult implements PermissionStatus {}

extension USBPermissionResultExtension on USBPermissionResult {
  external set devices(JSArray value);
  external JSArray get devices;
}
