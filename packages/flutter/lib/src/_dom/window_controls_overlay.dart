// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'geometry.dart';
import 'html.dart';

@JS('WindowControlsOverlay')
@staticInterop
class WindowControlsOverlay implements EventTarget {}

extension WindowControlsOverlayExtension on WindowControlsOverlay {
  external DOMRect getTitlebarAreaRect();
  external bool get visible;
  external set ongeometrychange(EventHandler value);
  external EventHandler get ongeometrychange;
}

@JS('WindowControlsOverlayGeometryChangeEvent')
@staticInterop
class WindowControlsOverlayGeometryChangeEvent implements Event {
  external factory WindowControlsOverlayGeometryChangeEvent(
    String type,
    WindowControlsOverlayGeometryChangeEventInit eventInitDict,
  );
}

extension WindowControlsOverlayGeometryChangeEventExtension
    on WindowControlsOverlayGeometryChangeEvent {
  external DOMRect get titlebarAreaRect;
  external bool get visible;
}

@JS()
@staticInterop
@anonymous
class WindowControlsOverlayGeometryChangeEventInit implements EventInit {
  external factory WindowControlsOverlayGeometryChangeEventInit({
    required DOMRect titlebarAreaRect,
    bool visible,
  });
}

extension WindowControlsOverlayGeometryChangeEventInitExtension
    on WindowControlsOverlayGeometryChangeEventInit {
  external set titlebarAreaRect(DOMRect value);
  external DOMRect get titlebarAreaRect;
  external set visible(bool value);
  external bool get visible;
}
