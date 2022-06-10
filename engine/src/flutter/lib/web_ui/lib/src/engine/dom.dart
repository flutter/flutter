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
class DomWindow extends DomEventTarget {}

extension DomWindowExtension on DomWindow {
  external DomConsole get console;
  external num get devicePixelRatio;
  external DomDocument get document;
  external DomHistory get history;
  external int? get innerHeight;
  external int? get innerWidth;
  external DomLocation get location;
  external DomNavigator get navigator;
  external DomVisualViewport? get visualViewport;
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
  external DomClipboard? get clipboard;
  external int? get maxTouchPoints;
  external String get vendor;
  external String get language;
  external String? get platform;
  external String get userAgent;
}

@JS()
@staticInterop
class DomDocument extends DomNode {}

extension DomDocumentExtension on DomDocument {
  external DomElement? get documentElement;
  external DomElement? querySelector(String selectors);
  Iterable<DomElement> querySelectorAll(String selectors) =>
      _DomElementListWrapper.create(js_util.callMethod<_DomElementList>(
          this, 'querySelectorAll', <Object>[selectors]));
  DomElement createElement(String name, [Object? options]) =>
      js_util.callMethod(this, 'createElement',
          <Object>[name, if (options != null) options]) as DomElement;
  external bool execCommand(String commandId);
  external DomHTMLScriptElement? get currentScript;
  external DomElement createElementNS(
      String namespaceURI, String qualifiedName);
  external DomText createTextNode(String data);
}

@JS()
@staticInterop
class DomHTMLDocument extends DomDocument {}

extension DomHTMLDocumentExtension on DomHTMLDocument {
  external DomFontFaceSet? get fonts;
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
  external num? get timeStamp;
  external String get type;
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
  external String? get baseUri;
  external DomNode? get firstChild;
  external String get innerText;
  external DomNode? get lastChild;
  external DomNode appendChild(DomNode node);
  DomElement? get parent => js_util.getProperty(this, 'parentElement');
  String? get text => js_util.getProperty(this, 'textContent');
  external DomNode? get parentNode;
  external DomNode? get nextSibling;
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
  Iterable<DomElement> get children => _DomElementListWrapper.create(
      js_util.getProperty<_DomElementList>(this, 'children'));
  external int get clientHeight;
  external int get clientWidth;
  external String get id;
  external set id(String id);
  external set innerHtml(String? html);
  external String? get outerHTML;
  external set spellcheck(bool? value);
  external String get tagName;
  external DomCSSStyleDeclaration get style;
  external void append(DomNode node);
  external String? getAttribute(String attributeName);
  external DomRect getBoundingClientRect();
  external void prepend(DomNode node);
  external DomElement? querySelector(String selectors);
  Iterable<DomElement> querySelectorAll(String selectors) =>
      _DomElementListWrapper.create(js_util.callMethod<_DomElementList>(
          this, 'querySelectorAll', <Object>[selectors]));
  external void remove();
  external void setAttribute(String name, Object value);
  void appendText(String text) => append(createDomText(text));
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
  set color(String value) => setProperty('color', value);
  set top(String value) => setProperty('top', value);
  set left(String value) => setProperty('left', value);
  set right(String value) => setProperty('right', value);
  set bottom(String value) => setProperty('bottom', value);
  set backgroundColor(String value) => setProperty('background-color', value);
  set pointerEvents(String value) => setProperty('pointer-events', value);
  set filter(String value) => setProperty('filter', value);
  set zIndex(String value) => setProperty('z-index', value);
  set whiteSpace(String value) => setProperty('white-space', value);
  set lineHeight(String value) => setProperty('line-height', value);
  set textStroke(String value) => setProperty('-webkit-text-stroke', value);
  set fontSize(String value) => setProperty('font-size', value);
  set fontWeight(String value) => setProperty('font-weight', value);
  set fontStyle(String value) => setProperty('font-style', value);
  set fontFamily(String value) => setProperty('font-family', value);
  set letterSpacing(String value) => setProperty('letter-spacing', value);
  set wordSpacing(String value) => setProperty('word-spacing', value);
  set textShadow(String value) => setProperty('text-shadow', value);
  set textDecoration(String value) => setProperty('text-decoration', value);
  set textDecorationColor(String value) =>
      setProperty('text-decoration-color', value);
  set fontFeatureSettings(String value) =>
      setProperty('font-feature-settings', value);
  set fontVariationSettings(String value) =>
      setProperty('font-variation-settings', value);
  set visibility(String value) => setProperty('visibility', value);
  set overflow(String value) => setProperty('overflow', value);
  set boxShadow(String value) => setProperty('box-shadow', value);
  set borderTopLeftRadius(String value) =>
      setProperty('border-top-left-radius', value);
  set borderTopRightRadius(String value) =>
      setProperty('border-top-right-radius', value);
  set borderBottomLeftRadius(String value) =>
      setProperty('border-bottom-left-radius', value);
  set borderBottomRightRadius(String value) =>
      setProperty('border-bottom-right-radius', value);
  set borderRadius(String value) => setProperty('border-radius', value);
  set perspective(String value) => setProperty('perspective', value);
  set padding(String value) => setProperty('padding', value);
  set backgroundImage(String value) => setProperty('background-image', value);
  set border(String value) => setProperty('border', value);
  set mixBlendMode(String value) => setProperty('mix-blend-mode', value);
  set backgroundSize(String value) => setProperty('background-size', value);
  set backgroundBlendMode(String value) =>
      setProperty('background-blend-mode', value);
  set transformStyle(String value) => setProperty('transform-style', value);
  set display(String value) => setProperty('display', value);
  set flexDirection(String value) => setProperty('flex-direction', value);
  set alignItems(String value) => setProperty('align-items', value);
  set margin(String value) => setProperty('margin', value);
  set background(String value) => setProperty('background', value);
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
  String get display => getPropertyValue('display');
  String get flexDirection => getPropertyValue('flex-direction');
  String get alignItems => getPropertyValue('align-items');
  String get margin => getPropertyValue('margin');
  String get background => getPropertyValue('background');

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

extension DomHTMLElementExtension on DomHTMLElement {
  int get offsetWidth => js_util.getProperty<num>(this, 'offsetWidth') as int;
  external void focus();
}

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
class DomHTMLSpanElement extends DomHTMLElement {}

DomHTMLSpanElement createDomHTMLSpanElement() =>
    domDocument.createElement('span') as DomHTMLSpanElement;

@JS()
@staticInterop
class DomHTMLButtonElement extends DomHTMLElement {}

DomHTMLButtonElement createDomHTMLButtonElement() =>
    domDocument.createElement('button') as DomHTMLButtonElement;

@JS()
@staticInterop
class DomHTMLParagraphElement extends DomHTMLElement {}

DomHTMLParagraphElement createDomHTMLParagraphElement() =>
    domDocument.createElement('p') as DomHTMLParagraphElement;

@JS()
@staticInterop
class DomHTMLStyleElement extends DomHTMLElement {}

extension DomHTMLStyleElementExtension on DomHTMLStyleElement {
  external set type(String? value);
}

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
  external String get font;
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
  external DomTextMetrics measureText(String text);
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
class DomTextMetrics {}

extension DomTextMetricsExtension on DomTextMetrics {
  external num? get width;
}

@JS()
@staticInterop
class DomException {
  static const String notSupported = 'NotSupportedError';
}

extension DomExceptionExtension on DomException {
  external String get name;
}

@JS()
@staticInterop
class DomRectReadOnly {}

extension DomRectReadOnlyExtension on DomRectReadOnly {
  external num get x;
  external num get y;
  external num get width;
  external num get height;
  external num get top;
  external num get right;
  external num get bottom;
  external num get left;
}

@JS()
@staticInterop
class DomRect extends DomRectReadOnly {}

@JS()
@staticInterop
class DomFontFace {}

DomFontFace createDomFontFace(String family, Object source,
        [Map<Object?, Object?>? descriptors]) =>
    domCallConstructorString('FontFace', <Object>[
      family,
      source,
      if (descriptors != null) js_util.jsify(descriptors)
    ])! as DomFontFace;

extension DomFontFaceExtension on DomFontFace {
  Future<DomFontFace> load() =>
      js_util.promiseToFuture(js_util.callMethod(this, 'load', <Object>[]));
}

@JS()
@staticInterop
class DomFontFaceSet extends DomEventTarget {}

extension DomFontFaceSetExtension on DomFontFaceSet {
  external DomFontFaceSet? add(DomFontFace font);
  external void clear();
}

@JS()
@staticInterop
class DomVisualViewport extends DomEventTarget {}

extension DomVisualViewportExtension on DomVisualViewport {
  external num? get height;
  external num? get width;
}

@JS()
@staticInterop
class DomHTMLTextAreaElement extends DomHTMLElement {}

DomHTMLTextAreaElement createDomHTMLTextAreaElement() =>
    domDocument.createElement('textarea') as DomHTMLTextAreaElement;

extension DomHTMLTextAreaElementExtension on DomHTMLTextAreaElement {
  external set value(String? value);
  external void select();
}

@JS()
@staticInterop
class DomClipboard extends DomEventTarget {}

extension DomClipboardExtension on DomClipboard {
  Future<String> readText() => js_util.promiseToFuture<String>(
      js_util.callMethod(this, 'readText', <Object>[]));

  Future<dynamic> writeText(String data) => js_util
      .promiseToFuture(js_util.callMethod(this, 'writeText', <Object>[data]));
}

extension DomResponseExtension on DomResponse {
  Future<dynamic> arrayBuffer() => js_util
      .promiseToFuture(js_util.callMethod(this, 'arrayBuffer', <Object>[]));

  Future<dynamic> json() =>
      js_util.promiseToFuture(js_util.callMethod(this, 'json', <Object>[]));

  Future<String> text() =>
      js_util.promiseToFuture(js_util.callMethod(this, 'text', <Object>[]));
}

@JS()
@staticInterop
class DomUIEvent extends DomEvent {}

@JS()
@staticInterop
class DomKeyboardEvent extends DomUIEvent {}

extension DomKeyboardEventExtension on DomKeyboardEvent {
  external bool get altKey;
  external String? get code;
  external bool get ctrlKey;
  external String? get key;
  external int get keyCode;
  external int get location;
  external bool get metaKey;
  external bool? get repeat;
  external bool get shiftKey;
  external bool getModifierState(String keyArg);
}

@JS()
@staticInterop
class DomHistory {}

extension DomHistoryExtension on DomHistory {
  dynamic get state => js_util.dartify(js_util.getProperty(this, 'state'));
  external void go([int? delta]);
  void pushState(dynamic data, String title, String? url) =>
      js_util.callMethod(this, 'pushState', <Object?>[
        if (data is Map || data is Iterable) js_util.jsify(data) else data,
        title,
        url
      ]);
  void replaceState(dynamic data, String title, String? url) =>
      js_util.callMethod(this, 'replaceState', <Object?>[
        if (data is Map || data is Iterable) js_util.jsify(data) else data,
        title,
        url
      ]);
}

@JS()
@staticInterop
class DomLocation {}

extension DomLocationExtension on DomLocation {
  external String? get pathname;
  external String? get search;
  // We have to change the name here because 'hash' is inherited from [Object].
  String get locationHash => js_util.getProperty(this, 'hash');
}

@JS()
@staticInterop
class DomPopStateEvent extends DomEvent {}

DomPopStateEvent createDomPopStateEvent(
        String type, Map<Object?, Object?>? eventInitDict) =>
    domCallConstructorString('PopStateEvent', <Object>[
      type,
      if (eventInitDict != null) js_util.jsify(eventInitDict)
    ])! as DomPopStateEvent;

extension DomPopStateEventExtension on DomPopStateEvent {
  dynamic get state => js_util.dartify(js_util.getProperty(this, 'state'));
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

/// [_DomElementList] is the shared interface for APIs that return either
/// `NodeList` or `HTMLCollection`. Do *not* add any API to this class that
/// isn't support by both JS objects. Furthermore, this is an internal class and
/// should only be returned as a wrapped object to Dart.
@JS()
@staticInterop
class _DomElementList {}

extension DomElementListExtension on _DomElementList {
  external int get length;
  DomElement item(int index) =>
      js_util.callMethod<DomElement>(this, 'item', <Object>[index]);
}

class _DomElementListIterator extends Iterator<DomElement> {
  final _DomElementList elementList;
  int index = -1;

  _DomElementListIterator(this.elementList);

  @override
  bool moveNext() {
    index++;
    if (index > elementList.length) {
      throw 'Iterator out of bounds';
    }
    return index < elementList.length;
  }

  @override
  DomElement get current => elementList.item(index);
}

class _DomElementListWrapper extends Iterable<DomElement> {
  final _DomElementList elementList;

  _DomElementListWrapper._(this.elementList);

  /// This is a work around for a `TypeError` which can be triggered by calling
  /// `toList` on the `Iterable`.
  static Iterable<DomElement> create(_DomElementList elementList) =>
      _DomElementListWrapper._(elementList).cast<DomElement>();

  @override
  Iterator<DomElement> get iterator => _DomElementListIterator(elementList);

  /// Override the length to avoid iterating through the whole collection.
  @override
  int get length => elementList.length;
}
