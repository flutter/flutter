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
  external DomConsole get console;
  external DomDocument get document;
  external DomNavigator get navigator;
  external DomPerformance get performance;
  Future<Object?> fetch(String url) =>
      js_util.promiseToFuture(js_util.callMethod(this, 'fetch', <String>[url]));
}

@JS()
@staticInterop
class DomConsole {}

extension DomConsoleExtension on DomConsole {
  external void warn(Object? arg);
}

@JS('window')
external DomWindow get domWindow;

@JS()
@staticInterop
class DomNavigator {}

extension DomNavigatorExtension on DomNavigator {
  external int? get maxTouchPoints;
  external String get vendor;
  external String get language;
  external String? get platform;
  external String get userAgent;
}

@JS()
@staticInterop
class DomDocument {}

extension DomDocumentExtension on DomDocument {
  external /* List<Node> */ List<Object?> querySelectorAll(String selectors);
  external DomElement createElement(String name, [dynamic options]);
  external DomHTMLScriptElement? get currentScript;
  external DomElement createElementNS(
      String namespaceURI, String qualifiedName);
}

@JS()
@staticInterop
class DomHTMLDocument extends DomDocument {}

extension DomHTMLDocumentExtension on DomHTMLDocument {
  external DomHTMLHeadElement? get head;
  external DomHTMLBodyElement? get body;
}

@JS('document')
external DomHTMLDocument get domDocument;

@JS()
@staticInterop
class DomEventTarget {}

extension DomEventTargetExtension on DomEventTarget {
  external void addEventListener(String type, DomEventListener? listener,
      [bool? useCapture]);
  external void removeEventListener(String type, DomEventListener? listener,
      [bool? useCapture]);
}

typedef DomEventListener = void Function(DomEvent event);

@JS()
@staticInterop
class DomEvent {}

extension DomEventExtension on DomEvent {
  external DomEventTarget? get target;
  external void preventDefault();
  external void stopPropagation();
}

@JS()
@staticInterop
class DomProgressEvent extends DomEvent {}

extension DomProgressEventExtension on DomProgressEvent {
  external int? get loaded;
  external int? get total;
}

@JS()
@staticInterop
class DomNode extends DomEventTarget {}

extension DomNodeExtension on DomNode {
  external DomNode appendChild(DomNode node);
  external DomElement? get parentElement;
  external DomNode? get parentNode;
  external DomNode insertBefore(DomNode newNode, DomNode? referenceNode);
  void remove() {
    if (parentNode != null) {
      final DomNode parent = parentNode!;
      parent.removeChild(this);
    }
  }

  external DomNode removeChild(DomNode child);
  external bool? get isConnected;
}

@JS()
@staticInterop
class DomElement extends DomNode {}

DomElement createDomElement(String tag) => domDocument.createElement(tag);

extension DomElementExtension on DomElement {
  external /* List<DomElement> */ List<Object?> get children;
  external String get id;
  external set id(String id);
  external DomCSSStyleDeclaration get style;
  external void append(DomNode node);
  external String? getAttribute(String attributeName);
  external void prepend(DomNode node);
  external DomElement? querySelector(String selectors);
  external void setAttribute(String name, Object value);
}

@JS()
@staticInterop
class DomCSSStyleDeclaration {}

extension DomCSSStyleDeclarationExtension on DomCSSStyleDeclaration {
  set width(String value) => setProperty('width', value);
  set height(String value) => setProperty('height', value);
  set position(String value) => setProperty('position', value);
  set clip(String value) => setProperty('clip', value);
  set clipPath(String value) => setProperty('clip-path', value);
  set transform(String value) => setProperty('transform', value);
  set transformOrigin(String value) => setProperty('transform-origin', value);
  set opacity(String value) => setProperty('opacity', value);
  String get width => getPropertyValue('width');
  String get height => getPropertyValue('height');
  String get position => getPropertyValue('position');
  String get clip => getPropertyValue('clip');
  String get clipPath => getPropertyValue('clip-path');
  String get transform => getPropertyValue('transform');
  String get transformOrigin => getPropertyValue('transform-origin');
  String get opacity => getPropertyValue('opacity');

  external String getPropertyValue(String property);
  external void setProperty(String propertyName, String value,
      [String priority]);
}

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
class DomHTMLHeadElement extends DomHTMLElement {}

@JS()
@staticInterop
class DomHTMLBodyElement extends DomHTMLElement {}

@JS()
@staticInterop
class DomHTMLScriptElement extends DomHTMLElement {}

extension DomHTMLScriptElementExtension on DomHTMLScriptElement {
  external set src(String value);
}

DomHTMLScriptElement createDomHTMLScriptElement() =>
    domDocument.createElement('script') as DomHTMLScriptElement;

@JS()
@staticInterop
class DomPerformance extends DomEventTarget {}

extension DomPerformanceExtension on DomPerformance {
  external DomPerformanceEntry? mark(String markName);
  external DomPerformanceMeasure? measure(
      String measureName, String? startMark, String? endMark);
}

@JS()
@staticInterop
class DomPerformanceEntry {}

@JS()
@staticInterop
class DomPerformanceMeasure extends DomPerformanceEntry {}

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
  external String toDataURL([String? type]);

  Object? getContext(String contextType, [Map<dynamic, dynamic>? attributes]) {
    return js_util.callMethod(this, 'getContext', <Object?>[
      contextType,
      if (attributes != null) js_util.jsify(attributes)
    ]);
  }

  DomCanvasRenderingContext2D get getContext2D =>
      getContext('2d')! as DomCanvasRenderingContext2D;
}

@JS()
@staticInterop
abstract class DomCanvasImageSource {}

@JS()
@staticInterop
class DomCanvasRenderingContext2D {}

extension DomCanvasRenderingContext2DExtension on DomCanvasRenderingContext2D {
  external void drawImage(DomCanvasImageSource source, num destX, num destY);
}

@JS()
@staticInterop
class DomXMLHttpRequestEventTarget extends DomEventTarget {}

@JS('XMLHttpRequest')
@staticInterop
class DomXMLHttpRequest extends DomXMLHttpRequestEventTarget {}

DomXMLHttpRequest createDomXMLHttpRequest() =>
    domCallConstructorString('XMLHttpRequest', <Object?>[])!
        as DomXMLHttpRequest;

extension DomXMLHttpRequestExtension on DomXMLHttpRequest {
  external dynamic get response;
  external String get responseType;
  external int? get status;
  external set responseType(String value);
  external void open(String method, String url, [bool? async]);
  external void send();
}

@JS()
@staticInterop
class DomResponse {}

@JS()
@staticInterop
class DomException {
  static const String notSupported = 'NotSupportedError';
}

extension DomExceptionExtension on DomException {
  external String get name;
}

extension DomResponseExtension on DomResponse {
  Future<dynamic> arrayBuffer() => js_util
      .promiseToFuture(js_util.callMethod(this, 'arrayBuffer', <Object>[]));

  Future<dynamic> json() =>
      js_util.promiseToFuture(js_util.callMethod(this, 'json', <Object>[]));

  Future<String> text() =>
      js_util.promiseToFuture(js_util.callMethod(this, 'text', <Object>[]));
}

Object? domGetConstructor(String constructorName) =>
    js_util.getProperty(domWindow, constructorName);

Object? domCallConstructorString(String constructorName, List<Object?> args) {
  final Object? constructor = domGetConstructor(constructorName);
  if (constructor == null) {
    return null;
  }
  return js_util.callConstructor(constructor, args);
}

bool domInstanceOfString(Object? element, String objectType) =>
    js_util.instanceof(element, domGetConstructor(objectType)!);
