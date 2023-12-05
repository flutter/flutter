// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

@JS()
@staticInterop
@anonymous
class RelatedApplication {
  external factory RelatedApplication({
    required String platform,
    String url,
    String id,
    String version,
  });
}

extension RelatedApplicationExtension on RelatedApplication {
  external set platform(String value);
  external String get platform;
  external set url(String value);
  external String get url;
  external set id(String value);
  external String get id;
  external set version(String value);
  external String get version;
}
