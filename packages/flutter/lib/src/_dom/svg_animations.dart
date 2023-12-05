// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'html.dart';
import 'svg.dart';

@JS('TimeEvent')
@staticInterop
class TimeEvent implements Event {}

extension TimeEventExtension on TimeEvent {
  external void initTimeEvent(
    String typeArg,
    Window? viewArg,
    int detailArg,
  );
  external Window? get view;
  external int get detail;
}

@JS('SVGAnimationElement')
@staticInterop
class SVGAnimationElement implements SVGElement {}

extension SVGAnimationElementExtension on SVGAnimationElement {
  external num getStartTime();
  external num getCurrentTime();
  external num getSimpleDuration();
  external void beginElement();
  external void beginElementAt(num offset);
  external void endElement();
  external void endElementAt(num offset);
  external SVGElement? get targetElement;
  external set onbegin(EventHandler value);
  external EventHandler get onbegin;
  external set onend(EventHandler value);
  external EventHandler get onend;
  external set onrepeat(EventHandler value);
  external EventHandler get onrepeat;
  external SVGStringList get requiredExtensions;
  external SVGStringList get systemLanguage;
}

@JS('SVGAnimateElement')
@staticInterop
class SVGAnimateElement implements SVGAnimationElement {}

@JS('SVGSetElement')
@staticInterop
class SVGSetElement implements SVGAnimationElement {}

@JS('SVGAnimateMotionElement')
@staticInterop
class SVGAnimateMotionElement implements SVGAnimationElement {}

@JS('SVGMPathElement')
@staticInterop
class SVGMPathElement implements SVGElement {}

extension SVGMPathElementExtension on SVGMPathElement {
  external SVGAnimatedString get href;
}

@JS('SVGAnimateTransformElement')
@staticInterop
class SVGAnimateTransformElement implements SVGAnimationElement {}

@JS('SVGDiscardElement')
@staticInterop
class SVGDiscardElement implements SVGAnimationElement {}
