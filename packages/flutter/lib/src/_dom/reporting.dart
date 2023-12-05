// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

typedef ReportList = JSArray;
typedef ReportingObserverCallback = JSFunction;

@JS('ReportBody')
@staticInterop
class ReportBody {}

extension ReportBodyExtension on ReportBody {
  external JSObject toJSON();
}

@JS('Report')
@staticInterop
class Report {}

extension ReportExtension on Report {
  external JSObject toJSON();
  external String get type;
  external String get url;
  external ReportBody? get body;
}

@JS('ReportingObserver')
@staticInterop
class ReportingObserver {
  external factory ReportingObserver(
    ReportingObserverCallback callback, [
    ReportingObserverOptions options,
  ]);
}

extension ReportingObserverExtension on ReportingObserver {
  external void observe();
  external void disconnect();
  external ReportList takeRecords();
}

@JS()
@staticInterop
@anonymous
class ReportingObserverOptions {
  external factory ReportingObserverOptions({
    JSArray types,
    bool buffered,
  });
}

extension ReportingObserverOptionsExtension on ReportingObserverOptions {
  external set types(JSArray value);
  external JSArray get types;
  external set buffered(bool value);
  external bool get buffered;
}

@JS()
@staticInterop
@anonymous
class GenerateTestReportParameters {
  external factory GenerateTestReportParameters({
    required String message,
    String group,
  });
}

extension GenerateTestReportParametersExtension
    on GenerateTestReportParameters {
  external set message(String value);
  external String get message;
  external set group(String value);
  external String get group;
}
