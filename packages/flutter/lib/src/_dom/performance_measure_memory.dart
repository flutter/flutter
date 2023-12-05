// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

@JS()
@staticInterop
@anonymous
class MemoryMeasurement {
  external factory MemoryMeasurement({
    int bytes,
    JSArray breakdown,
  });
}

extension MemoryMeasurementExtension on MemoryMeasurement {
  external set bytes(int value);
  external int get bytes;
  external set breakdown(JSArray value);
  external JSArray get breakdown;
}

@JS()
@staticInterop
@anonymous
class MemoryBreakdownEntry {
  external factory MemoryBreakdownEntry({
    int bytes,
    JSArray attribution,
    JSArray types,
  });
}

extension MemoryBreakdownEntryExtension on MemoryBreakdownEntry {
  external set bytes(int value);
  external int get bytes;
  external set attribution(JSArray value);
  external JSArray get attribution;
  external set types(JSArray value);
  external JSArray get types;
}

@JS()
@staticInterop
@anonymous
class MemoryAttribution {
  external factory MemoryAttribution({
    String url,
    MemoryAttributionContainer container,
    String scope,
  });
}

extension MemoryAttributionExtension on MemoryAttribution {
  external set url(String value);
  external String get url;
  external set container(MemoryAttributionContainer value);
  external MemoryAttributionContainer get container;
  external set scope(String value);
  external String get scope;
}

@JS()
@staticInterop
@anonymous
class MemoryAttributionContainer {
  external factory MemoryAttributionContainer({
    String id,
    String src,
  });
}

extension MemoryAttributionContainerExtension on MemoryAttributionContainer {
  external set id(String value);
  external String get id;
  external set src(String value);
  external String get src;
}
