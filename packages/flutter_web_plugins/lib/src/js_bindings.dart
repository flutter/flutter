// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
@JS()
library js_bindings;

import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

import 'package:js/js.dart';

import 'platform_views.dart';

@JS(r'$flutter')
external set flutterObject(FlutterBindings bindings);

/// JavaScript bindings between the Flutter engine and the web platform.
@JS()
@anonymous
class FlutterBindings {
  /// Create a new [FlutterBindings] object.
  external factory FlutterBindings({
    void Function(ByteData, ui.PlatformMessageResponseCallback)
        platformViewHandler,
  });

  /// The handler for platform calls to 'flutter/platform_views'.
  external void Function(ByteData, ui.PlatformMessageResponseCallback)
      get platformViewHandler;
}

/// Initialize the Flutter JavaScript bindings.
void initializeJsBindings() {
  flutterObject = FlutterBindings(platformViewHandler: handlePlatformViewCall);
}
