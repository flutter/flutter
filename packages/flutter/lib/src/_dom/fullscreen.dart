// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'window_management.dart';

typedef FullscreenNavigationUI = String;

@JS()
@staticInterop
@anonymous
class FullscreenOptions {
  external factory FullscreenOptions({
    FullscreenNavigationUI navigationUI,
    ScreenDetailed screen,
  });
}

extension FullscreenOptionsExtension on FullscreenOptions {
  external set navigationUI(FullscreenNavigationUI value);
  external FullscreenNavigationUI get navigationUI;
  external set screen(ScreenDetailed value);
  external ScreenDetailed get screen;
}
