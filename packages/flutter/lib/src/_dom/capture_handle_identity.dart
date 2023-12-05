// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

@JS()
@staticInterop
@anonymous
class CaptureHandleConfig {
  external factory CaptureHandleConfig({
    bool exposeOrigin,
    String handle,
    JSArray permittedOrigins,
  });
}

extension CaptureHandleConfigExtension on CaptureHandleConfig {
  external set exposeOrigin(bool value);
  external bool get exposeOrigin;
  external set handle(String value);
  external String get handle;
  external set permittedOrigins(JSArray value);
  external JSArray get permittedOrigins;
}

@JS()
@staticInterop
@anonymous
class CaptureHandle {
  external factory CaptureHandle({
    String origin,
    String handle,
  });
}

extension CaptureHandleExtension on CaptureHandle {
  external set origin(String value);
  external String get origin;
  external set handle(String value);
  external String get handle;
}
