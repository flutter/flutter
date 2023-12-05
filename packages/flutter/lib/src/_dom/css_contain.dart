// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';

@JS('ContentVisibilityAutoStateChangeEvent')
@staticInterop
class ContentVisibilityAutoStateChangeEvent implements Event {
  external factory ContentVisibilityAutoStateChangeEvent(
    String type, [
    ContentVisibilityAutoStateChangeEventInit eventInitDict,
  ]);
}

extension ContentVisibilityAutoStateChangeEventExtension
    on ContentVisibilityAutoStateChangeEvent {
  external bool get skipped;
}

@JS()
@staticInterop
@anonymous
class ContentVisibilityAutoStateChangeEventInit implements EventInit {
  external factory ContentVisibilityAutoStateChangeEventInit({bool skipped});
}

extension ContentVisibilityAutoStateChangeEventInitExtension
    on ContentVisibilityAutoStateChangeEventInit {
  external set skipped(bool value);
  external bool get skipped;
}
