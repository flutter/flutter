// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;

/// This file contains static interop classes for interacting with the DOM and
/// some helpers. All of the classes in this file are named after their
/// counterparts in the DOM. To extend any of these classes, simply add an
/// external method to the appropriate class's extension. To add a new class,
/// simply name the class after it's counterpart in the DOM and prefix the
/// class name with `Dom`.
/// NOTE: After the new static interop DOM API is released in the Dart SDK,
/// these classes will be replaced by typedefs.

@JS()
@staticInterop
class DomWindow {}

extension DomWindowExtension on DomWindow {
  external DomDocument get document;
  external DomNavigator get navigator;
}

@JS('window')
external DomWindow get domWindow;

@JS()
@staticInterop
class DomNavigator {}

extension DomNavigatorExtension on DomNavigator {
  external int? get maxTouchPoints;
  external String get vendor;
  external String? get platform;
  external String get userAgent;
}

@JS()
@staticInterop
class DomDocument {}

extension DomDocumentExtension on DomDocument {
  external /* List<Node> */ List<Object?> querySelectorAll(String selectors);
  external DomElement createElement(String name, [dynamic options]);
}

@JS()
@staticInterop
class DomEventTarget {}

@JS()
@staticInterop
class DomNode extends DomEventTarget {}

@JS()
@staticInterop
class DomElement extends DomNode {}

@JS()
@staticInterop
class DomHTMLElement extends DomElement {}

@JS()
@staticInterop
class DomHTMLMetaElement extends DomHTMLElement {}

extension DomHTMLMetaElementExtension on DomHTMLMetaElement {
  external String get name;
  external set name(String value);
  external String get content;
}

@JS()
@staticInterop
class DomCanvasElement extends DomHTMLElement {}

DomCanvasElement createDomCanvasElement({int? width, int? height}) {
  final DomCanvasElement canvas =
      domWindow.document.createElement('canvas') as DomCanvasElement;
  if (width != null) {
    canvas.width = width;
  }
  if (height != null) {
    canvas.height = height;
  }
  return canvas;
}

extension DomCanvasElementExtension on DomCanvasElement {
  external int? get width;
  external set width(int? value);
  external int? get height;
  external set height(int? value);

  Object? getContext(String contextType, [Map<dynamic, dynamic>? attributes]) {
    return js_util.callMethod(this, 'getContext', <Object?>[
      contextType,
      if (attributes != null) js_util.jsify(attributes)
    ]);
  }
}

Object? domGetConstructor(String constructorName) =>
    js_util.getProperty(domWindow, constructorName);

bool domInstanceOfString(Object? element, String objectType) =>
    js_util.instanceof(element, domGetConstructor(objectType)!);
