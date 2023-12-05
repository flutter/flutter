// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

@JS()
@staticInterop
@anonymous
class NavigatorUABrandVersion {
  external factory NavigatorUABrandVersion({
    String brand,
    String version,
  });
}

extension NavigatorUABrandVersionExtension on NavigatorUABrandVersion {
  external set brand(String value);
  external String get brand;
  external set version(String value);
  external String get version;
}

@JS()
@staticInterop
@anonymous
class UADataValues {
  external factory UADataValues({
    String architecture,
    String bitness,
    JSArray brands,
    JSArray formFactor,
    JSArray fullVersionList,
    String model,
    bool mobile,
    String platform,
    String platformVersion,
    String uaFullVersion,
    bool wow64,
  });
}

extension UADataValuesExtension on UADataValues {
  external set architecture(String value);
  external String get architecture;
  external set bitness(String value);
  external String get bitness;
  external set brands(JSArray value);
  external JSArray get brands;
  external set formFactor(JSArray value);
  external JSArray get formFactor;
  external set fullVersionList(JSArray value);
  external JSArray get fullVersionList;
  external set model(String value);
  external String get model;
  external set mobile(bool value);
  external bool get mobile;
  external set platform(String value);
  external String get platform;
  external set platformVersion(String value);
  external String get platformVersion;
  external set uaFullVersion(String value);
  external String get uaFullVersion;
  external set wow64(bool value);
  external bool get wow64;
}

@JS()
@staticInterop
@anonymous
class UALowEntropyJSON {
  external factory UALowEntropyJSON({
    JSArray brands,
    bool mobile,
    String platform,
  });
}

extension UALowEntropyJSONExtension on UALowEntropyJSON {
  external set brands(JSArray value);
  external JSArray get brands;
  external set mobile(bool value);
  external bool get mobile;
  external set platform(String value);
  external String get platform;
}

@JS('NavigatorUAData')
@staticInterop
class NavigatorUAData {}

extension NavigatorUADataExtension on NavigatorUAData {
  external JSPromise getHighEntropyValues(JSArray hints);
  external UALowEntropyJSON toJSON();
  external JSArray get brands;
  external bool get mobile;
  external String get platform;
}
