// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'html.dart';

typedef UserIdleState = String;
typedef ScreenIdleState = String;

@JS()
@staticInterop
@anonymous
class IdleOptions {
  external factory IdleOptions({
    int threshold,
    AbortSignal signal,
  });
}

extension IdleOptionsExtension on IdleOptions {
  external set threshold(int value);
  external int get threshold;
  external set signal(AbortSignal value);
  external AbortSignal get signal;
}

@JS('IdleDetector')
@staticInterop
class IdleDetector implements EventTarget {
  external factory IdleDetector();

  external static JSPromise requestPermission();
}

extension IdleDetectorExtension on IdleDetector {
  external JSPromise start([IdleOptions options]);
  external UserIdleState? get userState;
  external ScreenIdleState? get screenState;
  external set onchange(EventHandler value);
  external EventHandler get onchange;
}
