// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
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
  // ignore: non_constant_identifier_names
  external DomURL get URL;
  external bool dispatchEvent(DomEvent event);
  external DomMediaQueryList matchMedia(String? query);
  DomCSSStyleDeclaration getComputedStyle(DomElement elt,
          [String? pseudoElt]) =>
      js_util.callMethod(this, 'getComputedStyle', <Object>[
        elt,
        if (pseudoElt != null) pseudoElt
      ]) as DomCSSStyleDeclaration;
  external DomScreen? get screen;
  external int requestAnimationFrame(DomRequestAnimationFrameCallback callback);
  void postMessage(Object message, String targetOrigin,
          [List<DomMessagePort>? messagePorts]) =>
      js_util.callMethod(this, 'postMessage', <Object>[
        message,
        targetOrigin,
        if (messagePorts != null) js_util.jsify(messagePorts)
      ]);
}

typedef DomRequestAnimationFrameCallback = void Function(num highResTime);

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
  List<String>? get languages =>
      js_util.getProperty<List<Object?>?>(this, 'languages')?.cast<String>();
}

@JS()
@staticInterop
class DomDocument extends DomNode {}

extension DomDocumentExtension on DomDocument {
  external DomElement? get documentElement;
  external DomElement? querySelector(String selectors);
  Iterable<DomElement> querySelectorAll(String selectors) =>
      createDomListWrapper<DomElement>(js_util
          .callMethod<_DomList>(this, 'querySelectorAll', <Object>[selectors]));
  DomElement createElement(String name, [Object? options]) =>
      js_util.callMethod(this, 'createElement',
          <Object>[name, if (options != null) options]) as DomElement;
  external bool execCommand(String commandId);
  external DomHTMLScriptElement? get currentScript;
  external DomElement createElementNS(
      String namespaceURI, String qualifiedName);
  external DomText createTextNode(String data);
  external DomEvent createEvent(String eventType);
  external DomElement? get activeElement;
  external DomElement? elementFromPoint(int x, int y);
}

@JS()
@staticInterop
class DomHTMLDocument extends DomDocument {}

extension DomHTMLDocumentExtension on DomHTMLDocument {
  external DomFontFaceSet? get fonts;
  external DomHTMLHeadElement? get head;
  external DomHTMLBodyElement? get body;
  external set title(String? value);
  external String? get title;
  Iterable<DomElement> getElementsByTagName(String tag) =>
      createDomListWrapper<DomElement>(js_util
          .callMethod<_DomList>(this, 'getElementsByTagName', <Object>[tag]));
  external DomElement? get activeElement;
  external DomElement? getElementById(String id);
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

  external bool dispatchEvent(DomEvent event);
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
  void initEvent(String type, [bool? bubbles, bool? cancelable]) =>
      js_util.callMethod(this, 'initEvent', <Object>[
        type,
        if (bubbles != null) bubbles,
        if (cancelable != null) cancelable
      ]);
  external bool get defaultPrevented;
}

DomEvent createDomEvent(String type, String name) {
  final DomEvent event = domDocument.createEvent(type);
  event.initEvent(name, true, true);
  return event;
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
  external bool contains(DomNode? other);
  external void append(DomNode node);
  Iterable<DomNode> get childNodes => createDomListWrapper<DomElement>(
      js_util.getProperty<_DomList>(this, 'childNodes'));
  external DomDocument? get ownerDocument;
  void clearChildren() {
    while (firstChild != null) {
      removeChild(firstChild!);
    }
  }
}

@JS()
@staticInterop
class DomElement extends DomNode {}

DomElement createDomElement(String tag) => domDocument.createElement(tag);

extension DomElementExtension on DomElement {
  Iterable<DomElement> get children => createDomListWrapper<DomElement>(
      js_util.getProperty<_DomList>(this, 'children'));
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
      createDomListWrapper<DomElement>(js_util
          .callMethod<_DomList>(this, 'querySelectorAll', <Object>[selectors]));
  external void remove();
  external void setAttribute(String name, Object value);
  void appendText(String text) => append(createDomText(text));
  external void removeAttribute(String name);
  external set tabIndex(int? value);
  external int? get tabIndex;
  external void focus();

  /// [scrollTop] and [scrollLeft] can both return non-integers when using
  /// display scaling.
  ///
  /// The setters have a spurious round just in case the supplied [int] flowed
  /// from the non-static interop JS API. When all of Flutter Web has been
  /// migrated to static interop we can probably remove the rounds.
  int get scrollTop => js_util.getProperty(this, 'scrollTop').round();
  set scrollTop(int value) =>
      js_util.setProperty<num>(this, 'scrollTop', value.round());
  int get scrollLeft => js_util.getProperty(this, 'scrollLeft').round();
  set scrollLeft(int value) =>
      js_util.setProperty<num>(this, 'scrollLeft', value.round());
  external DomTokenList get classList;
  external set className(String value);
  external String get className;
  external void blur();
  List<DomNode> getElementsByTagName(String tag) =>
      js_util.callMethod<List<Object?>>(
          this, 'getElementsByTagName', <Object>[tag]).cast<DomNode>();
  List<DomNode> getElementsByClassName(String className) =>
      js_util.callMethod<List<Object?>>(
          this, 'getElementsByClassName', <Object>[className]).cast<DomNode>();
  external void click();
  external bool hasAttribute(String name);
  Iterable<DomNode> get childNodes => createDomListWrapper<DomElement>(
      js_util.getProperty<_DomList>(this, 'childNodes'));
  DomShadowRoot attachShadow(Map<Object?, Object?> initDict) => js_util
          .callMethod(this, 'attachShadow', <Object?>[js_util.jsify(initDict)])
      as DomShadowRoot;
  external DomShadowRoot? get shadowRoot;
  void clearChildren() {
    while (firstChild != null) {
      removeChild(firstChild!);
    }
  }
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
  set touchAction(String value) => setProperty('touch-action', value);
  set overflowY(String value) => setProperty('overflow-y', value);
  set overflowX(String value) => setProperty('overflow-x', value);
  set outline(String value) => setProperty('outline', value);
  set resize(String value) => setProperty('resize', value);
  set alignContent(String value) => setProperty('align-content', value);
  set textAlign(String value) => setProperty('text-align', value);
  set font(String value) => setProperty('font', value);
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
  String get touchAction => getPropertyValue('touch-action');
  String get overflowY => getPropertyValue('overflow-y');
  String get overflowX => getPropertyValue('overflow-x');
  String get outline => getPropertyValue('outline');
  String get resize => getPropertyValue('resize');
  String get alignContent => getPropertyValue('align-content');
  String get textAlign => getPropertyValue('text-align');
  String get font => getPropertyValue('font');

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
}

@JS()
@staticInterop
class DomHTMLMetaElement extends DomHTMLElement {}

extension DomHTMLMetaElementExtension on DomHTMLMetaElement {
  external String get name;
  external set name(String value);
  external String get content;
  external set content(String value);
}

DomHTMLMetaElement createDomHTMLMetaElement() =>
    domDocument.createElement('meta') as DomHTMLMetaElement;

@JS()
@staticInterop
class DomHTMLHeadElement extends DomHTMLElement {}

@JS()
@staticInterop
class DomHTMLBodyElement extends DomHTMLElement {}

@JS()
@staticInterop
class DomHTMLImageElement extends DomHTMLElement
    implements DomCanvasImageSource {}

DomHTMLImageElement createDomHTMLImageElement() =>
    domDocument.createElement('img') as DomHTMLImageElement;

extension DomHTMLImageElementExtension on DomHTMLImageElement {
  external String? get alt;
  external set alt(String? value);
  external String? get src;
  external set src(String? value);
  external int get naturalWidth;
  external int get naturalHeight;
  external set width(int? value);
  external set height(int? value);
  Future<dynamic> decode() =>
      js_util.promiseToFuture(js_util.callMethod(this, 'decode', <Object>[]));
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
  external DomStyleSheet? get sheet;
}

DomHTMLStyleElement createDomHTMLStyleElement() =>
    domDocument.createElement('style') as DomHTMLStyleElement;

@JS()
@staticInterop
class DomPerformance extends DomEventTarget {}

extension DomPerformanceExtension on DomPerformance {
  external DomPerformanceEntry? mark(String markName);
  external DomPerformanceMeasure? measure(
      String measureName, String? startMark, String? endMark);
  external double now();
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
  String toDataURL([String type = 'image/png']) =>
      js_util.callMethod(this, 'toDataURL', <Object>[type]);

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
  external Object? get strokeStyle;
  external void beginPath();
  external void closePath();
  external DomCanvasGradient createLinearGradient(
      num x0, num y0, num x1, num y1);
  external DomCanvasPattern? createPattern(Object image, String reptitionType);
  external DomCanvasGradient createRadialGradient(
      num x0, num y0, num r0, num x1, num y1, num r1);
  external void drawImage(DomCanvasImageSource source, num destX, num destY);
  void fill([Object? pathOrWinding]) => js_util.callMethod(
      this, 'fill', <Object?>[if (pathOrWinding != null) pathOrWinding]);
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
  external void setTransform(num a, num b, num c, num d, num e, num f);
  external void transform(num a, num b, num c, num d, num e, num f);
  void clip([Object? pathOrWinding]) => js_util.callMethod(
      this, 'clip', <Object?>[if (pathOrWinding != null) pathOrWinding]);
  external void scale(num x, num y);
  external void clearRect(num x, num y, num width, num height);
  external void translate(num x, num y);
  external void rotate(num angle);
  external void bezierCurveTo(
      num cp1x, num cp1y, num numcp2x, num cp2y, num x, num y);
  external void quadraticCurveTo(num cpx, num cpy, num x, num y);
  external set globalCompositeOperation(String value);
  external set lineCap(String value);
  external set lineJoin(String value);
  external set shadowBlur(num value);
  void arc(num x, num y, num radius, num startAngle, num endAngle,
          [bool antiClockwise = false]) =>
      js_util.callMethod(this, 'arc',
          <Object>[x, y, radius, startAngle, endAngle, antiClockwise]);
  external set filter(String? value);
  external set shadowOffsetX(num? x);
  external set shadowOffsetY(num? y);
  external set shadowColor(String? value);
  external void ellipse(num x, num y, num radiusX, num radiusY, num rotation,
      num startAngle, num endAngle, bool? antiClockwise);
  external void strokeText(String text, num x, num y);
  external set globalAlpha(num? value);
}

@JS()
@staticInterop
class DomImageData {}

DomImageData createDomImageData(Object? data, int sw, int sh) => js_util
    .callConstructor(domGetConstructor('ImageData')!, <Object?>[data, sw, sh]);

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

@JS()
@staticInterop
class DomXMLHttpRequest extends DomXMLHttpRequestEventTarget {}

DomXMLHttpRequest createDomXMLHttpRequest() =>
    domCallConstructorString('XMLHttpRequest', <Object?>[])!
        as DomXMLHttpRequest;

extension DomXMLHttpRequestExtension on DomXMLHttpRequest {
  external dynamic get response;
  external String? get responseText;
  external String get responseType;
  external int? get status;
  external set responseType(String value);
  void open(String method, String url, [bool? async]) => js_util.callMethod(
      this, 'open', <Object>[method, url, if (async != null) async]);
  void send([Object? bodyOrData]) => js_util
      .callMethod(this, 'send', <Object>[if (bodyOrData != null) bodyOrData]);
}

Future<DomXMLHttpRequest> domHttpRequest(String url,
    {String? responseType, String method = 'GET', dynamic sendData}) {
  final Completer<DomXMLHttpRequest> completer = Completer<DomXMLHttpRequest>();
  final DomXMLHttpRequest xhr = createDomXMLHttpRequest();
  xhr.open(method, url, /* async */ true);
  if (responseType != null) {
    xhr.responseType = responseType;
  }

  xhr.addEventListener('load', allowInterop((DomEvent e) {
    final int status = xhr.status!;
    final bool accepted = status >= 200 && status < 300;
    final bool fileUri = status == 0;
    final bool notModified = status == 304;
    final bool unknownRedirect = status > 307 && status < 400;
    if (accepted || fileUri || notModified || unknownRedirect) {
      completer.complete(xhr);
    } else {
      completer.completeError(e);
    }
  }));

  xhr.addEventListener('error', allowInterop(completer.completeError));
  xhr.send(sendData);
  return completer.future;
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

DomRect createDomRectFromPoints(DomPoint a, DomPoint b) {
  final num left = math.min(a.x, b.x);
  final num width = math.max(a.x, b.x) - left;
  final num top = math.min(a.y, b.y);
  final num height = math.max(a.y, b.y) - top;
  return domCallConstructorString(
      'DOMRect', <Object>[left, top, width, height])! as DomRect;
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
  external String? get family;
}

@JS()
@staticInterop
class DomFontFaceSet extends DomEventTarget {}

extension DomFontFaceSetExtension on DomFontFaceSet {
  external DomFontFaceSet? add(DomFontFace font);
  external void clear();
  external void forEach(DomFontFaceSetForEachCallback callback);
}

typedef DomFontFaceSetForEachCallback = void Function(
    DomFontFace fontFace, DomFontFace fontFaceAgain, DomFontFaceSet set);

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
  external set placeholder(String? value);
  external set name(String value);
  external int? get selectionStart;
  external int? get selectionEnd;
  external set selectionStart(int? value);
  external set selectionEnd(int? value);
  external String? get value;
  void setSelectionRange(int start, int end, [String? direction]) =>
      js_util.callMethod(this, 'setSelectionRange',
          <Object>[start, end, if (direction != null) direction]);
  external String get name;
  external String get placeholder;
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
  external String get origin;
  external String get href;
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

@JS()
@staticInterop
class DomURL {}

extension DomURLExtension on DomURL {
  external String createObjectURL(Object object);
  external void revokeObjectURL(String url);
}

@JS()
@staticInterop
class DomBlob {}

DomBlob createDomBlob(List<Object?> parts) =>
    domCallConstructorString('Blob', <Object>[parts])! as DomBlob;

typedef DomMutationCallback = void Function(
    List<dynamic> mutation, DomMutationObserver observer);

@JS()
@staticInterop
class DomMutationObserver {}

DomMutationObserver createDomMutationObserver(DomMutationCallback callback) =>
    domCallConstructorString('MutationObserver', <Object>[callback])!
        as DomMutationObserver;

extension DomMutationObserverExtension on DomMutationObserver {
  external void disconnect();
  void observe(DomNode target,
      {bool? childList, bool? attributes, List<String>? attributeFilter}) {
    final Map<String, dynamic> options = <String, dynamic>{
      if (childList != null) 'childList': childList,
      if (attributes != null) 'attributes': attributes,
      if (attributeFilter != null) 'attributeFilter': attributeFilter
    };
    return js_util
        .callMethod(this, 'observe', <Object>[target, js_util.jsify(options)]);
  }
}

@JS()
@staticInterop
class DomMutationRecord {}

extension DomMutationRecordExtension on DomMutationRecord {
  Iterable<DomNode>? get addedNodes {
    final _DomList? list = js_util.getProperty<_DomList?>(this, 'addedNodes');
    if (list == null) {
      return null;
    }
    return createDomListWrapper<DomNode>(list);
  }

  Iterable<DomNode>? get removedNodes {
    final _DomList? list = js_util.getProperty<_DomList?>(this, 'removedNodes');
    if (list == null) {
      return null;
    }
    return createDomListWrapper<DomNode>(list);
  }

  external String? get attributeName;
  external String? get type;
}

@JS()
@staticInterop
class DomMediaQueryList extends DomEventTarget {}

extension DomMediaQueryListExtension on DomMediaQueryList {
  external bool get matches;
  external void addListener(DomEventListener? listener);
  external void removeListener(DomEventListener? listener);
}

@JS()
@staticInterop
class DomMediaQueryListEvent extends DomEvent {}

extension DomMediaQueryListEventExtension on DomMediaQueryListEvent {
  external bool? get matches;
}

@JS()
@staticInterop
class DomPath2D {}

DomPath2D createDomPath2D([Object? path]) =>
    domCallConstructorString('Path2D', <Object>[if (path != null) path])!
        as DomPath2D;

@JS()
@staticInterop
class DomMouseEvent extends DomUIEvent {}

extension DomMouseEventExtension on DomMouseEvent {
  external num get clientX;
  external num get clientY;
  external num get offsetX;
  external num get offsetY;
  DomPoint get client => DomPoint(clientX, clientY);
  DomPoint get offset => DomPoint(offsetX, offsetY);
  external int get button;
  external int? get buttons;
  external bool getModifierState(String keyArg);
}

DomMouseEvent createDomMouseEvent(String type, [Map<dynamic, dynamic>? init]) =>
    js_util.callConstructor(domGetConstructor('MouseEvent')!,
        <Object>[type, if (init != null) js_util.jsify(init)]);

@JS()
@staticInterop
class DomPointerEvent extends DomMouseEvent {}

extension DomPointerEventExtension on DomPointerEvent {
  external int? get pointerId;
  external String? get pointerType;
  external num? get pressure;
  external int? get tiltX;
  external int? get tiltY;
  List<DomPointerEvent> getCoalescedEvents() =>
      js_util.callMethod<List<Object?>>(
          this, 'getCoalescedEvents', <Object>[]).cast<DomPointerEvent>();
}

DomPointerEvent createDomPointerEvent(String type,
        [Map<dynamic, dynamic>? init]) =>
    js_util.callConstructor(domGetConstructor('PointerEvent')!,
        <Object>[type, if (init != null) js_util.jsify(init)]);

@JS()
@staticInterop
class DomWheelEvent extends DomMouseEvent {}

extension DomWheelEventExtension on DomWheelEvent {
  external num get deltaX;
  external num get deltaY;
  external int get deltaMode;
}

@JS()
@staticInterop
class DomTouchEvent extends DomUIEvent {}

extension DomTouchEventExtension on DomTouchEvent {
  List<DomTouch>? get changedTouches => js_util
      .getProperty<List<Object?>?>(this, 'changedTouches')
      ?.cast<DomTouch>();
}

@JS()
@staticInterop
class DomTouch {}

extension DomTouchExtension on DomTouch {
  external int? get identifier;
  external num get clientX;
  external num get clientY;
  DomPoint get client => DomPoint(clientX, clientY);
}

DomTouch createDomTouch([Map<dynamic, dynamic>? init]) =>
    js_util.callConstructor(domGetConstructor('Touch')!,
        <Object>[if (init != null) js_util.jsify(init)]) as DomTouch;

DomTouchEvent createDomTouchEvent(String type, [Map<dynamic, dynamic>? init]) =>
    js_util.callConstructor(domGetConstructor('TouchEvent')!,
        <Object>[type, if (init != null) js_util.jsify(init)]);

@JS()
@staticInterop
class DomCompositionEvent extends DomUIEvent {}

extension DomCompositionEventExtension on DomCompositionEvent {
  external String? get data;
}

DomCompositionEvent createDomCompositionEvent(String type,
        [Map<dynamic, dynamic>? options]) =>
    js_util.callConstructor(domGetConstructor('CompositionEvent')!,
        <Object>[type, if (options != null) js_util.jsify(options)]);

@JS()
@staticInterop
class DomHTMLInputElement extends DomHTMLElement {}

extension DomHTMLInputElementExtension on DomHTMLInputElement {
  external set type(String? value);
  external set max(String? value);
  external set min(String value);
  external set value(String? value);
  external String? get value;
  external bool? get disabled;
  external set disabled(bool? value);
  external set placeholder(String? value);
  external set name(String? value);
  external set autocomplete(String value);
  external int? get selectionStart;
  external int? get selectionEnd;
  external set selectionStart(int? value);
  external set selectionEnd(int? value);
  void setSelectionRange(int start, int end, [String? direction]) =>
      js_util.callMethod(this, 'setSelectionRange',
          <Object>[start, end, if (direction != null) direction]);
  external String get autocomplete;
  external String? get name;
  external String? get type;
  external String get placeholder;
}

DomHTMLInputElement createDomHTMLInputElement() =>
    domDocument.createElement('input') as DomHTMLInputElement;

@JS()
@staticInterop
class DomTokenList {}

extension DomTokenListExtension on DomTokenList {
  external void add(String value);
  external void remove(String value);
  external bool contains(String token);
}

@JS()
@staticInterop
class DomHTMLFormElement extends DomHTMLElement {}

extension DomHTMLFormElementExtension on DomHTMLFormElement {
  external set noValidate(bool? value);
  external set method(String? value);
  external set action(String? value);
}

DomHTMLFormElement createDomHTMLFormElement() =>
    domDocument.createElement('form') as DomHTMLFormElement;

@JS()
@staticInterop
class DomHTMLLabelElement extends DomHTMLElement {}

DomHTMLLabelElement createDomHTMLLabelElement() =>
    domDocument.createElement('label') as DomHTMLLabelElement;

@JS()
@staticInterop
class DomOffscreenCanvas extends DomEventTarget {}

extension DomOffscreenCanvasExtension on DomOffscreenCanvas {
  external int? get height;
  external int? get width;
  external set height(int? value);
  external set width(int? value);
  Object? getContext(String contextType, [Map<dynamic, dynamic>? attributes]) {
    return js_util.callMethod(this, 'getContext', <Object?>[
      contextType,
      if (attributes != null) js_util.jsify(attributes)
    ]);
  }

  Future<DomBlob> convertToBlob([Map<Object?, Object?>? options]) =>
      js_util.promiseToFuture(js_util.callMethod(this, 'convertToBlob',
          <Object>[if (options != null) js_util.jsify(options)]));
}

DomOffscreenCanvas createDomOffscreenCanvas(int width, int height) =>
    js_util.callConstructor(
        domGetConstructor('OffscreenCanvas')!, <Object>[width, height]);

@JS()
@staticInterop
class DomFileReader extends DomEventTarget {}

extension DomFileReaderExtension on DomFileReader {
  external void readAsDataURL(DomBlob blob);
}

DomFileReader createDomFileReader() =>
    js_util.callConstructor(domGetConstructor('FileReader')!, <Object>[])
        as DomFileReader;

@JS()
@staticInterop
class DomDocumentFragment extends DomNode {}

extension DomDocumentFragmentExtension on DomDocumentFragment {
  external DomElement? querySelector(String selectors);
  Iterable<DomElement> querySelectorAll(String selectors) =>
      createDomListWrapper<DomElement>(js_util
          .callMethod<_DomList>(this, 'querySelectorAll', <Object>[selectors]));
}

@JS()
@staticInterop
class DomShadowRoot extends DomDocumentFragment {}

extension DomShadowRootExtension on DomShadowRoot {
  external DomElement? get activeElement;
  external DomElement? get host;
  external String? get mode;
  external bool? get delegatesFocus;
  external DomElement? elementFromPoint(int x, int y);
}

@JS()
@staticInterop
class DomStyleSheet {}

@JS()
@staticInterop
class DomCSSStyleSheet extends DomStyleSheet {}

extension DomCSSStyleSheetExtension on DomCSSStyleSheet {
  List<DomCSSRule> get cssRules =>
      js_util.getProperty<List<Object?>>(this, 'cssRules').cast<DomCSSRule>();
  int insertRule(String rule, [int? index]) => js_util
      .callMethod(this, 'insertRule', <Object>[rule, if (index != null) index]);
}

@JS()
@staticInterop
class DomCSSRule {}

@JS()
@staticInterop
class DomScreen {}

extension DomScreenExtension on DomScreen {
  external DomScreenOrientation? get orientation;
}

@JS()
@staticInterop
class DomScreenOrientation extends DomEventTarget {}

extension DomScreenOrientationExtension on DomScreenOrientation {
  Future<dynamic> lock(String orientation) => js_util
      .promiseToFuture(js_util.callMethod(this, 'lock', <String>[orientation]));
  external void unlock();
}

// A helper class for managing a subscription. On construction it will add an
// event listener of the requested type to the target. Calling [cancel] will
// remove the listener. Caller is still responsible for calling [allowInterop]
// on the listener before creating the subscription.
class DomSubscription {
  final String type;
  final DomEventTarget target;
  final DomEventListener listener;

  DomSubscription(this.target, this.type, this.listener) {
    target.addEventListener(type, listener);
  }

  void cancel() => target.removeEventListener(type, listener);
}

class DomPoint {
  final num x;
  final num y;

  DomPoint(this.x, this.y);
}

@JS()
@staticInterop
class DomWebSocket extends DomEventTarget {}

extension DomWebSocketExtension on DomWebSocket {
  external void send(Object? data);
}

DomWebSocket createDomWebSocket(String url) =>
    domCallConstructorString('WebSocket', <Object>[url])! as DomWebSocket;

@JS()
@staticInterop
class DomMessageEvent extends DomEvent {}

extension DomMessageEventExtension on DomMessageEvent {
  dynamic get data => js_util.dartify(js_util.getProperty(this, 'data'));
  external String get origin;
}

@JS()
@staticInterop
class DomHTMLIFrameElement extends DomHTMLElement {}

extension DomHTMLIFrameElementExtension on DomHTMLIFrameElement {
  external set src(String? value);
  external String? get src;
  external set height(String? value);
  external set width(String? value);
  external DomWindow get contentWindow;
}

DomHTMLIFrameElement createDomHTMLIFrameElement() =>
    domDocument.createElement('iframe') as DomHTMLIFrameElement;

@JS()
@staticInterop
class DomMessagePort extends DomEventTarget {}

extension DomMessagePortExtension on DomMessagePort {
  void postMessage(Object? message) => js_util.callMethod(this, 'postMessage',
      <Object>[if (message != null) js_util.jsify(message)]);
  external void start();
}

@JS()
@staticInterop
class DomMessageChannel {}

extension DomMessageChannelExtension on DomMessageChannel {
  external DomMessagePort get port1;
  external DomMessagePort get port2;
}

DomMessageChannel createDomMessageChannel() =>
    domCallConstructorString('MessageChannel', <Object>[])!
        as DomMessageChannel;

Object? domGetConstructor(String constructorName) =>
    js_util.getProperty(domWindow, constructorName);

Object? domCallConstructorString(String constructorName, List<Object?> args) {
  final Object? constructor = domGetConstructor(constructorName);
  if (constructor == null) {
    return null;
  }
  return js_util.callConstructor(constructor, args);
}

String? domGetConstructorName(Object o) {
  final Object? constructor = js_util.getProperty(o, 'constructor');
  if (constructor == null) {
    return '';
  }
  return js_util.getProperty(constructor, 'name')?.toString();
}

bool domInstanceOfString(Object? element, String objectType) =>
    js_util.instanceof(element, domGetConstructor(objectType)!);

/// [_DomElementList] is the shared interface for APIs that return either
/// `NodeList` or `HTMLCollection`. Do *not* add any API to this class that
/// isn't support by both JS objects. Furthermore, this is an internal class and
/// should only be returned as a wrapped object to Dart.
@JS()
@staticInterop
class _DomList {}

extension DomListExtension on _DomList {
  external int get length;
  DomNode item(int index) =>
      js_util.callMethod<DomNode>(this, 'item', <Object>[index]);
}

class _DomListIterator<T> extends Iterator<T> {
  final _DomList list;
  int index = -1;

  _DomListIterator(this.list);

  @override
  bool moveNext() {
    index++;
    if (index > list.length) {
      throw 'Iterator out of bounds';
    }
    return index < list.length;
  }

  @override
  T get current => list.item(index) as T;
}

class _DomListWrapper<T> extends Iterable<T> {
  final _DomList list;

  _DomListWrapper._(this.list);

  @override
  Iterator<T> get iterator => _DomListIterator<T>(list);

  /// Override the length to avoid iterating through the whole collection.
  @override
  int get length => list.length;
}

/// This is a work around for a `TypeError` which can be triggered by calling
/// `toList` on the `Iterable`.
Iterable<T> createDomListWrapper<T>(_DomList list) =>
    _DomListWrapper<T>._(list).cast<T>();
