// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

// ignore_for_file: public_member_api_docs

import 'dart:js_interop';

import 'dom.dart';

@JS('CapturedMouseEvent')
@staticInterop
class CapturedMouseEvent implements Event {
  external factory CapturedMouseEvent(
    String type, [
    CapturedMouseEventInit eventInitDict,
  ]);
}

extension CapturedMouseEventExtension on CapturedMouseEvent {
  external int get surfaceX;
  external int get surfaceY;
}

@JS()
@staticInterop
@anonymous
class CapturedMouseEventInit implements EventInit {
  external factory CapturedMouseEventInit({
    int surfaceX,
    int surfaceY,
  });
}

extension CapturedMouseEventInitExtension on CapturedMouseEventInit {
  external set surfaceX(int value);
  external int get surfaceX;
  external set surfaceY(int value);
  external int get surfaceY;
}
