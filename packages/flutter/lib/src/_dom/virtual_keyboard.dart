// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'geometry.dart';
import 'html.dart';

@JS('VirtualKeyboard')
@staticInterop
class VirtualKeyboard implements EventTarget {}

extension VirtualKeyboardExtension on VirtualKeyboard {
  external void show();
  external void hide();
  external DOMRect get boundingRect;
  external set overlaysContent(bool value);
  external bool get overlaysContent;
  external set ongeometrychange(EventHandler value);
  external EventHandler get ongeometrychange;
}
