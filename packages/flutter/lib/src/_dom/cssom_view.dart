// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'geometry.dart';
import 'html.dart';
import 'screen_orientation.dart';

typedef GeometryNode = JSObject;
typedef ScrollBehavior = String;
typedef ScrollLogicalPosition = String;
typedef CSSBoxType = String;

@JS()
@staticInterop
@anonymous
class ScrollOptions {
  external factory ScrollOptions({ScrollBehavior behavior});
}

extension ScrollOptionsExtension on ScrollOptions {
  external set behavior(ScrollBehavior value);
  external ScrollBehavior get behavior;
}

@JS()
@staticInterop
@anonymous
class ScrollToOptions implements ScrollOptions {
  external factory ScrollToOptions({
    num left,
    num top,
  });
}

extension ScrollToOptionsExtension on ScrollToOptions {
  external set left(num value);
  external num get left;
  external set top(num value);
  external num get top;
}

@JS('MediaQueryList')
@staticInterop
class MediaQueryList implements EventTarget {}

extension MediaQueryListExtension on MediaQueryList {
  external void addListener(EventListener? callback);
  external void removeListener(EventListener? callback);
  external String get media;
  external bool get matches;
  external set onchange(EventHandler value);
  external EventHandler get onchange;
}

@JS('MediaQueryListEvent')
@staticInterop
class MediaQueryListEvent implements Event {
  external factory MediaQueryListEvent(
    String type, [
    MediaQueryListEventInit eventInitDict,
  ]);
}

extension MediaQueryListEventExtension on MediaQueryListEvent {
  external String get media;
  external bool get matches;
}

@JS()
@staticInterop
@anonymous
class MediaQueryListEventInit implements EventInit {
  external factory MediaQueryListEventInit({
    String media,
    bool matches,
  });
}

extension MediaQueryListEventInitExtension on MediaQueryListEventInit {
  external set media(String value);
  external String get media;
  external set matches(bool value);
  external bool get matches;
}

@JS('Screen')
@staticInterop
class Screen {}

extension ScreenExtension on Screen {
  external int get availWidth;
  external int get availHeight;
  external int get width;
  external int get height;
  external int get colorDepth;
  external int get pixelDepth;
  external ScreenOrientation get orientation;
  external bool get isExtended;
  external set onchange(EventHandler value);
  external EventHandler get onchange;
}

@JS('CaretPosition')
@staticInterop
class CaretPosition {}

extension CaretPositionExtension on CaretPosition {
  external DOMRect? getClientRect();
  external Node get offsetNode;
  external int get offset;
}

@JS()
@staticInterop
@anonymous
class ScrollIntoViewOptions implements ScrollOptions {
  external factory ScrollIntoViewOptions({
    ScrollLogicalPosition block,
    ScrollLogicalPosition inline,
  });
}

extension ScrollIntoViewOptionsExtension on ScrollIntoViewOptions {
  external set block(ScrollLogicalPosition value);
  external ScrollLogicalPosition get block;
  external set inline(ScrollLogicalPosition value);
  external ScrollLogicalPosition get inline;
}

@JS()
@staticInterop
@anonymous
class CheckVisibilityOptions {
  external factory CheckVisibilityOptions({
    bool checkOpacity,
    bool checkVisibilityCSS,
  });
}

extension CheckVisibilityOptionsExtension on CheckVisibilityOptions {
  external set checkOpacity(bool value);
  external bool get checkOpacity;
  external set checkVisibilityCSS(bool value);
  external bool get checkVisibilityCSS;
}

@JS()
@staticInterop
@anonymous
class BoxQuadOptions {
  external factory BoxQuadOptions({
    CSSBoxType box,
    GeometryNode relativeTo,
  });
}

extension BoxQuadOptionsExtension on BoxQuadOptions {
  external set box(CSSBoxType value);
  external CSSBoxType get box;
  external set relativeTo(GeometryNode value);
  external GeometryNode get relativeTo;
}

@JS()
@staticInterop
@anonymous
class ConvertCoordinateOptions {
  external factory ConvertCoordinateOptions({
    CSSBoxType fromBox,
    CSSBoxType toBox,
  });
}

extension ConvertCoordinateOptionsExtension on ConvertCoordinateOptions {
  external set fromBox(CSSBoxType value);
  external CSSBoxType get fromBox;
  external set toBox(CSSBoxType value);
  external CSSBoxType get toBox;
}

@JS('VisualViewport')
@staticInterop
class VisualViewport implements EventTarget {}

extension VisualViewportExtension on VisualViewport {
  external num get offsetLeft;
  external num get offsetTop;
  external num get pageLeft;
  external num get pageTop;
  external num get width;
  external num get height;
  external num get scale;
  external set onresize(EventHandler value);
  external EventHandler get onresize;
  external set onscroll(EventHandler value);
  external EventHandler get onscroll;
  external set onscrollend(EventHandler value);
  external EventHandler get onscrollend;
}
