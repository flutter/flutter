// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'html.dart';

@JS('Keyboard')
@staticInterop
class Keyboard implements EventTarget {}

extension KeyboardExtension on Keyboard {
  external JSPromise lock([JSArray keyCodes]);
  external void unlock();
  external JSPromise getLayoutMap();
  external set onlayoutchange(EventHandler value);
  external EventHandler get onlayoutchange;
}
