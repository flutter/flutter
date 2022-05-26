// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

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
/// NOTE: Currently, optional parameters do not behave as expected.
/// For the time being, avoid passing optional parameters directly to JS.

@JS()
@staticInterop
class DomWindow {}

extension DomWindowExtension on DomWindow {
  external DomConsole get console;
  external num get devicePixelRatio;
  external DomDocument get document;
  external int? get innerHeight;
  external int? get innerWidth;
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
  external DomElement? querySelector(String selectors);
  List<DomElement> querySelectorAll(String selectors) =>
      js_util.callMethod<List<Object?>>(
          this, 'querySelectorAll', <Object>[selectors]).cast<DomElement>();
  DomElement createElement(String name, [Object? options]) =>
      js_util.callMethod(this, 'createElement',
          <Object>[name, if (options != null) options]) as DomElement;
  external DomHTMLScriptElement? get currentScript;
  external DomElement createElementNS(
      String namespaceURI, String qualifiedName);
  external DomText createTextNode(String data);
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
  void addEventListener(String type, DomEventListener? listener,
      [bool? useCapture]) {
    if (listener != null) {
      js_util.callMethod(this, 'addEventListener',
          <Object>[type, listener, if (useCapture != null) useCapture]);
    }
  }

  void removeEventListener(String type, DomEventListener? listener,
      [bool? useCapture]) {
    if (listener != null) {
      js_util.callMethod(this, 'removeEventListener',
          <Object>[type, listener, if (useCapture != null) useCapture]);
    }
  }
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
  external DomNode? get firstChild;
  external String get innerText;
  external DomNode? get lastChild;
  external DomNode appendChild(DomNode node);
  DomElement? get parent => js_util.getProperty(this, 'parentElement');
  String? get text => js_util.getProperty(this, 'textContent');
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
  set text(String? value) =>
      js_util.setProperty<String?>(this, 'textContent', value);
  external DomNode cloneNode(bool? deep);
}

@JS()
@staticInterop
class DomElement extends DomNode {}

DomElement createDomElement(String tag) => domDocument.createElement(tag);

extension DomElementExtension on DomElement {
  List<DomElement> get children =>
      js_util.getProperty<List<Object?>>(this, 'children').cast<DomElement>();
  external String get id;
  external set id(String id);
  external String? get outerHTML;
  external set spellcheck(bool? value);
  external String get tagName;
  external DomCSSStyleDeclaration get style;
  external void append(DomNode node);
  external String? getAttribute(String attributeName);
  external void prepend(DomNode node);
  external DomElement? querySelector(String selectors);
  List<DomElement> querySelectorAll(String selectors) =>
      js_util.callMethod<List<Object?>>(
          this, 'querySelectorAll', <Object>[selectors]).cast<DomElement>();
  external void remove();
  external void setAttribute(String name, Object value);
  void appendText(String text) => append(createDomText(text));
}

@JS()
@staticInterop
class DomCSSStyleDeclaration {}

extension DomCSSStyleDeclarationExtension on DomCSSStyleDeclaration {
  set width(String value) => setProperty('width', value, '');
  set height(String value) => setProperty('height', value, '');
  set position(String value) => setProperty('position', value, '');
  set clip(String value) => setProperty('clip', value, '');
  set clipPath(String value) => setProperty('clip-path', value, '');
  set transform(String value) => setProperty('transform', value, '');
  set transformOrigin(String value) =>
      setProperty('transform-origin', value, '');
  set opacity(String value) => setProperty('opacity', value, '');
  set color(String value) => setProperty('color', value, '');
  set top(String value) => setProperty('top', value, '');
  set left(String value) => setProperty('left', value, '');
  set right(String value) => setProperty('right', value, '');
  set bottom(String value) => setProperty('bottom', value, '');
  set backgroundColor(String value) =>
      setProperty('background-color', value, '');
  set pointerEvents(String value) => setProperty('pointer-events', value, '');
  set filter(String value) => setProperty('filter', value, '');
  set zIndex(String value) => setProperty('z-index', value, '');
  set whiteSpace(String value) => setProperty('white-space', value, '');
  set lineHeight(String value) => setProperty('line-height', value, '');
  set textStroke(String value) => setProperty('-webkit-text-stroke', value, '');
  set fontSize(String value) => setProperty('font-size', value, '');
  set fontWeight(String value) => setProperty('font-weight', value, '');
  set fontStyle(String value) => setProperty('font-style', value, '');
  set fontFamily(String value) => setProperty('font-family', value, '');
  set letterSpacing(String value) => setProperty('letter-spacing', value, '');
  set wordSpacing(String value) => setProperty('word-spacing', value, '');
  set textShadow(String value) => setProperty('text-shadow', value, '');
  set textDecoration(String value) => setProperty('text-decoration', value, '');
  set textDecorationColor(String value) =>
      setProperty('text-decoration-color', value, '');
  set fontFeatureSettings(String value) =>
      setProperty('font-feature-settings', value, '');
  set fontVariationSettings(String value) =>
      setProperty('font-variation-settings', value, '');
  set visibility(String value) => setProperty('visibility', value, '');
  set overflow(String value) => setProperty('overflow', value, '');
  set boxShadow(String value) => setProperty('box-shadow', value, '');
  set borderTopLeftRadius(String value) =>
      setProperty('border-top-left-radius', value, '');
  set borderTopRightRadius(String value) =>
      setProperty('border-top-right-radius', value, '');
  set borderBottomLeftRadius(String value) =>
      setProperty('border-bottom-left-radius', value, '');
  set borderBottomRightRadius(String value) =>
      setProperty('border-bottom-right-radius', value, '');
  set borderRadius(String value) => setProperty('border-radius', value, '');
  set perspective(String value) => setProperty('perspective', value, '');
  set padding(String value) => setProperty('padding', value, '');
  set backgroundImage(String value) =>
      setProperty('background-image', value, '');
  set border(String value) => setProperty('border', value, '');
  set mixBlendMode(String value) => setProperty('mix-blend-mode', value, '');
  set backgroundSize(String value) =>
      setProperty('background-size', value, '');
  set backgroundBlendMode(String value) =>
      setProperty('background-blend-mode', value, '');
  set transformStyle(String value) => setProperty('transform-style', value, '');
  String get width => getPropertyValue('width');
  String get height => getPropertyValue('height');
  String get position => getPropertyValue('position');
  String get clip => getPropertyValue('clip');
  String get clipPath => getPropertyValue('clip-path');
  String get transform => getPropertyValue('transform');
  String get transformOrigin => getPropertyValue('transform-origin');
  String get opacity => getPropertyValue('opacity');
  String get color => getPropertyValue('color');
  String get top => getPropertyValue('top');
  String get left => getPropertyValue('left');
  String get right => getPropertyValue('right');
  String get bottom => getPropertyValue('bottom');
  String get backgroundColor => getPropertyValue('background-color');
  String get pointerEvents => getPropertyValue('pointer-events');
  String get filter => getPropertyValue('filter');
  String get zIndex => getPropertyValue('z-index');
  String get whiteSpace => getPropertyValue('white-space');
  String get lineHeight => getPropertyValue('line-height');
  String get textStroke => getPropertyValue('-webkit-text-stroke');
  String get fontSize => getPropertyValue('font-size');
  String get fontWeight => getPropertyValue('font-weight');
  String get fontStyle => getPropertyValue('font-style');
  String get fontFamily => getPropertyValue('font-family');
  String get letterSpacing => getPropertyValue('letter-spacing');
  String get wordSpacing => getPropertyValue('word-spacing');
  String get textShadow => getPropertyValue('text-shadow');
  String get textDecorationColor => getPropertyValue('text-decoration-color');
  String get fontFeatureSettings => getPropertyValue('font-feature-settings');
  String get fontVariationSettings =>
      getPropertyValue('font-variation-settings');
  String get visibility => getPropertyValue('visibility');
  String get overflow => getPropertyValue('overflow');
  String get boxShadow => getPropertyValue('box-shadow');
  String get borderTopLeftRadius => getPropertyValue('border-top-left-radius');
  String get borderTopRightRadius =>
      getPropertyValue('border-top-right-radius');
  String get borderBottomLeftRadius =>
      getPropertyValue('border-bottom-left-radius');
  String get borderBottomRightRadius =>
      getPropertyValue('border-bottom-right-radius');
  String get borderRadius => getPropertyValue('border-radius');
  String get perspective => getPropertyValue('perspective');
  String get padding => getPropertyValue('padding');
  String get backgroundImage => getPropertyValue('background-image');
  String get border => getPropertyValue('border');
  String get mixBlendMode => getPropertyValue('mix-blend-mode');
  String get backgroundSize => getPropertyValue('background-size');
  String get backgroundBlendMode => getPropertyValue('background-blend-mode');
  String get transformStyle => getPropertyValue('transform-style');

  external String getPropertyValue(String property);
  void setProperty(String propertyName, String value, [String? priority]) {
    priority ??= '';
    js_util.callMethod(
        this, 'setProperty', <Object>[propertyName, value, priority]);
  }

  external String removeProperty(String property);
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
class DomHTMLImageElement extends DomHTMLElement {}

DomHTMLImageElement createDomHTMLImageElement() =>
    domDocument.createElement('img') as DomHTMLImageElement;

extension DomHTMLImageElemenExtension on DomHTMLImageElement {
  external String? get alt;
  external set alt(String? value);
  external set src(String value);
}

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
class DomHTMLDivElement extends DomHTMLElement {}

DomHTMLDivElement createDomHTMLDivElement() =>
    domDocument.createElement('div') as DomHTMLDivElement;

@JS()
@staticInterop
class DomHTMLButtonElement extends DomHTMLElement {}

DomHTMLButtonElement createDomHTMLButtonElement() =>
    domDocument.createElement('button') as DomHTMLButtonElement;

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
  external bool? get isConnected;
  String toDataURL([String? type]) =>
      js_util.callMethod(this, 'toDataURL', <Object>[if (type != null) type]);

  Object? getContext(String contextType, [Map<dynamic, dynamic>? attributes]) {
    return js_util.callMethod(this, 'getContext', <Object?>[
      contextType,
      if (attributes != null) js_util.jsify(attributes)
    ]);
  }

  DomCanvasRenderingContext2D get context2D =>
      getContext('2d')! as DomCanvasRenderingContext2D;
}

@JS()
@staticInterop
abstract class DomCanvasImageSource {}

@JS()
@staticInterop
class DomCanvasRenderingContext2D {}

extension DomCanvasRenderingContext2DExtension on DomCanvasRenderingContext2D {
  external Object? get fillStyle;
  external set fillStyle(Object? style);
  external set font(String value);
  external set lineWidth(num? value);
  external set strokeStyle(Object? value);
  external void beginPath();
  external void closePath();
  external DomCanvasGradient createLinearGradient(
      num x0, num y0, num x1, num y1);
  external DomCanvasPattern? createPattern(Object image, String reptitionType);
  external DomCanvasGradient createRadialGradient(
      num x0, num y0, num r0, num x1, num y1, num r1);
  external void drawImage(DomCanvasImageSource source, num destX, num destY);
  external void fill();
  external void fillRect(num x, num y, num width, num height);
  void fillText(String text, num x, num y, [num? maxWidth]) =>
      js_util.callMethod(this, 'fillText',
          <Object>[text, x, y, if (maxWidth != null) maxWidth]);
  external DomImageData getImageData(int x, int y, int sw, int sh);
  external void lineTo(num x, num y);
  external void moveTo(num x, num y);
  external void save();
  external void stroke();
  external void rect(num x, num y, num width, num height);
  external void resetTransform();
  external void restore();
}

@JS()
@staticInterop
class DomImageData {}

extension DomImageDataExtension on DomImageData {
  external Uint8ClampedList get data;
}

@JS()
@staticInterop
class DomCanvasPattern {}

@JS()
@staticInterop
class DomCanvasGradient {}

extension DomCanvasGradientExtension on DomCanvasGradient {
  external void addColorStop(num offset, String color);
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
  void open(String method, String url, [bool? async]) => js_util.callMethod(
      this, 'open', <Object>[method, url, if (async != null) async]);
  external void send();
}

@JS()
@staticInterop
class DomResponse {}

@JS()
@staticInterop
class DomCharacterData extends DomNode {}

@JS()
@staticInterop
class DomText extends DomCharacterData {}

DomText createDomText(String data) => domDocument.createTextNode(data);

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
