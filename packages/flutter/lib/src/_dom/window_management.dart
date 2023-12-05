// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'cssom_view.dart';
import 'dom.dart';
import 'html.dart';

@JS('ScreenDetails')
@staticInterop
class ScreenDetails implements EventTarget {}

extension ScreenDetailsExtension on ScreenDetails {
  external JSArray get screens;
  external ScreenDetailed get currentScreen;
  external set onscreenschange(EventHandler value);
  external EventHandler get onscreenschange;
  external set oncurrentscreenchange(EventHandler value);
  external EventHandler get oncurrentscreenchange;
}

@JS('ScreenDetailed')
@staticInterop
class ScreenDetailed implements Screen {}

extension ScreenDetailedExtension on ScreenDetailed {
  external int get availLeft;
  external int get availTop;
  external int get left;
  external int get top;
  external bool get isPrimary;
  external bool get isInternal;
  external num get devicePixelRatio;
  external String get label;
}
