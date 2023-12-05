// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'html.dart';
import 'webidl.dart';

typedef HIDUnitSystem = String;

@JS('HID')
@staticInterop
class HID implements EventTarget {}

extension HIDExtension on HID {
  external JSPromise getDevices();
  external JSPromise requestDevice(HIDDeviceRequestOptions options);
  external set onconnect(EventHandler value);
  external EventHandler get onconnect;
  external set ondisconnect(EventHandler value);
  external EventHandler get ondisconnect;
}

@JS()
@staticInterop
@anonymous
class HIDDeviceRequestOptions {
  external factory HIDDeviceRequestOptions({
    required JSArray filters,
    JSArray exclusionFilters,
  });
}

extension HIDDeviceRequestOptionsExtension on HIDDeviceRequestOptions {
  external set filters(JSArray value);
  external JSArray get filters;
  external set exclusionFilters(JSArray value);
  external JSArray get exclusionFilters;
}

@JS()
@staticInterop
@anonymous
class HIDDeviceFilter {
  external factory HIDDeviceFilter({
    int vendorId,
    int productId,
    int usagePage,
    int usage,
  });
}

extension HIDDeviceFilterExtension on HIDDeviceFilter {
  external set vendorId(int value);
  external int get vendorId;
  external set productId(int value);
  external int get productId;
  external set usagePage(int value);
  external int get usagePage;
  external set usage(int value);
  external int get usage;
}

@JS('HIDDevice')
@staticInterop
class HIDDevice implements EventTarget {}

extension HIDDeviceExtension on HIDDevice {
  external JSPromise open();
  external JSPromise close();
  external JSPromise forget();
  external JSPromise sendReport(
    int reportId,
    BufferSource data,
  );
  external JSPromise sendFeatureReport(
    int reportId,
    BufferSource data,
  );
  external JSPromise receiveFeatureReport(int reportId);
  external set oninputreport(EventHandler value);
  external EventHandler get oninputreport;
  external bool get opened;
  external int get vendorId;
  external int get productId;
  external String get productName;
  external JSArray get collections;
}

@JS('HIDConnectionEvent')
@staticInterop
class HIDConnectionEvent implements Event {
  external factory HIDConnectionEvent(
    String type,
    HIDConnectionEventInit eventInitDict,
  );
}

extension HIDConnectionEventExtension on HIDConnectionEvent {
  external HIDDevice get device;
}

@JS()
@staticInterop
@anonymous
class HIDConnectionEventInit implements EventInit {
  external factory HIDConnectionEventInit({required HIDDevice device});
}

extension HIDConnectionEventInitExtension on HIDConnectionEventInit {
  external set device(HIDDevice value);
  external HIDDevice get device;
}

@JS('HIDInputReportEvent')
@staticInterop
class HIDInputReportEvent implements Event {
  external factory HIDInputReportEvent(
    String type,
    HIDInputReportEventInit eventInitDict,
  );
}

extension HIDInputReportEventExtension on HIDInputReportEvent {
  external HIDDevice get device;
  external int get reportId;
  external JSDataView get data;
}

@JS()
@staticInterop
@anonymous
class HIDInputReportEventInit implements EventInit {
  external factory HIDInputReportEventInit({
    required HIDDevice device,
    required int reportId,
    required JSDataView data,
  });
}

extension HIDInputReportEventInitExtension on HIDInputReportEventInit {
  external set device(HIDDevice value);
  external HIDDevice get device;
  external set reportId(int value);
  external int get reportId;
  external set data(JSDataView value);
  external JSDataView get data;
}

@JS()
@staticInterop
@anonymous
class HIDCollectionInfo {
  external factory HIDCollectionInfo({
    int usagePage,
    int usage,
    int type,
    JSArray children,
    JSArray inputReports,
    JSArray outputReports,
    JSArray featureReports,
  });
}

extension HIDCollectionInfoExtension on HIDCollectionInfo {
  external set usagePage(int value);
  external int get usagePage;
  external set usage(int value);
  external int get usage;
  external set type(int value);
  external int get type;
  external set children(JSArray value);
  external JSArray get children;
  external set inputReports(JSArray value);
  external JSArray get inputReports;
  external set outputReports(JSArray value);
  external JSArray get outputReports;
  external set featureReports(JSArray value);
  external JSArray get featureReports;
}

@JS()
@staticInterop
@anonymous
class HIDReportInfo {
  external factory HIDReportInfo({
    int reportId,
    JSArray items,
  });
}

extension HIDReportInfoExtension on HIDReportInfo {
  external set reportId(int value);
  external int get reportId;
  external set items(JSArray value);
  external JSArray get items;
}

@JS()
@staticInterop
@anonymous
class HIDReportItem {
  external factory HIDReportItem({
    bool isAbsolute,
    bool isArray,
    bool isBufferedBytes,
    bool isConstant,
    bool isLinear,
    bool isRange,
    bool isVolatile,
    bool hasNull,
    bool hasPreferredState,
    bool wrap,
    JSArray usages,
    int usageMinimum,
    int usageMaximum,
    int reportSize,
    int reportCount,
    int unitExponent,
    HIDUnitSystem unitSystem,
    int unitFactorLengthExponent,
    int unitFactorMassExponent,
    int unitFactorTimeExponent,
    int unitFactorTemperatureExponent,
    int unitFactorCurrentExponent,
    int unitFactorLuminousIntensityExponent,
    int logicalMinimum,
    int logicalMaximum,
    int physicalMinimum,
    int physicalMaximum,
    JSArray strings,
  });
}

extension HIDReportItemExtension on HIDReportItem {
  external set isAbsolute(bool value);
  external bool get isAbsolute;
  external set isArray(bool value);
  external bool get isArray;
  external set isBufferedBytes(bool value);
  external bool get isBufferedBytes;
  external set isConstant(bool value);
  external bool get isConstant;
  external set isLinear(bool value);
  external bool get isLinear;
  external set isRange(bool value);
  external bool get isRange;
  external set isVolatile(bool value);
  external bool get isVolatile;
  external set hasNull(bool value);
  external bool get hasNull;
  external set hasPreferredState(bool value);
  external bool get hasPreferredState;
  external set wrap(bool value);
  external bool get wrap;
  external set usages(JSArray value);
  external JSArray get usages;
  external set usageMinimum(int value);
  external int get usageMinimum;
  external set usageMaximum(int value);
  external int get usageMaximum;
  external set reportSize(int value);
  external int get reportSize;
  external set reportCount(int value);
  external int get reportCount;
  external set unitExponent(int value);
  external int get unitExponent;
  external set unitSystem(HIDUnitSystem value);
  external HIDUnitSystem get unitSystem;
  external set unitFactorLengthExponent(int value);
  external int get unitFactorLengthExponent;
  external set unitFactorMassExponent(int value);
  external int get unitFactorMassExponent;
  external set unitFactorTimeExponent(int value);
  external int get unitFactorTimeExponent;
  external set unitFactorTemperatureExponent(int value);
  external int get unitFactorTemperatureExponent;
  external set unitFactorCurrentExponent(int value);
  external int get unitFactorCurrentExponent;
  external set unitFactorLuminousIntensityExponent(int value);
  external int get unitFactorLuminousIntensityExponent;
  external set logicalMinimum(int value);
  external int get logicalMinimum;
  external set logicalMaximum(int value);
  external int get logicalMaximum;
  external set physicalMinimum(int value);
  external int get physicalMinimum;
  external set physicalMaximum(int value);
  external int get physicalMaximum;
  external set strings(JSArray value);
  external JSArray get strings;
}
