// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:meta/meta.dart';

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
/// NOTE: Please avoid typing external JS functions with `int`, as passing ints
/// to and from JS is not supported on all web backends.

@JS()
@staticInterop
class DomWindow extends DomEventTarget {}

extension DomWindowExtension on DomWindow {
  external DomConsole get console;
  external double get devicePixelRatio;
  external DomDocument get document;
  external DomHistory get history;
  external double? get innerHeight;
  external double? get innerWidth;
  external DomLocation get location;
  external DomNavigator get navigator;
  external DomVisualViewport? get visualViewport;
  external DomPerformance get performance;

  @visibleForTesting
  Future<Object?> fetch(String url) {
    // To make sure we have a consistent approach for handling and reporting
    // network errors, all code related to making HTTP calls is consolidated
    // into the `httpFetch` function, and a few convenience wrappers.
    throw UnsupportedError(
      'Do not use window.fetch directly. '
      'Use httpFetch* family of functions instead.',
    );
  }

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
  external double requestAnimationFrame(DomRequestAnimationFrameCallback callback);
  void postMessage(Object message, String targetOrigin,
          [List<DomMessagePort>? messagePorts]) =>
      js_util.callMethod(this, 'postMessage', <Object?>[
        message,
        targetOrigin,
        if (messagePorts != null) js_util.jsify(messagePorts)
      ]);

  /// The Trusted Types API (when available).
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Trusted_Types_API
  external DomTrustedTypePolicyFactory? get trustedTypes;
}

typedef DomRequestAnimationFrameCallback = void Function(num highResTime);

@JS()
@staticInterop
class DomConsole {}

extension DomConsoleExtension on DomConsole {
  external void warn(Object? arg);
  external void error(Object? arg);
  external void debug(Object? arg);
}

@JS('window')
external DomWindow get domWindow;

@JS('Intl')
external DomIntl get domIntl;

@JS()
@staticInterop
class DomNavigator {}

extension DomNavigatorExtension on DomNavigator {
  external DomClipboard? get clipboard;
  external double? get maxTouchPoints;
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
  DomElement? elementFromPoint(int x, int y) =>
      js_util.callMethod<DomElement?>(this, 'elementFromPoint',
          <Object>[x.toDouble(), y.toDouble()]);
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
  external DomEventTarget? get currentTarget;
  external double? get timeStamp;
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

@JS('ProgressEvent')
@staticInterop
class DomProgressEvent extends DomEvent {
  external factory DomProgressEvent(String type);
}

extension DomProgressEventExtension on DomProgressEvent {
  external double? get loaded;
  external double? get total;
}

@JS()
@staticInterop
class DomNode extends DomEventTarget {}

extension DomNodeExtension on DomNode {
  external String? get baseUri;
  external DomNode? get firstChild;
  external String get innerText;
  external set innerText(String text);
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
  external double get clientHeight;
  external double get clientWidth;
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
  external set tabIndex(double? value);
  external double? get tabIndex;
  external void focus();
  external double get scrollTop;
  external set scrollTop(double value);
  external double get scrollLeft;
  external set scrollLeft(double value);
  external DomTokenList get classList;
  external set className(String value);
  external String get className;
  external void blur();
  Iterable<DomNode> getElementsByTagName(String tag) =>
      createDomListWrapper(js_util.callMethod<_DomList>(
          this, 'getElementsByTagName', <Object>[tag]));
  Iterable<DomNode> getElementsByClassName(String className) =>
      createDomListWrapper(js_util.callMethod<_DomList>(
          this, 'getElementsByClassName', <Object>[className]));
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
  set caretColor(String value) => setProperty('caret-color', value);
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
  String get caretColor => getPropertyValue('caret-color');
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
  external double get offsetWidth;
  external double get offsetLeft;
  external double get offsetTop;
  external DomHTMLElement? get offsetParent;
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
  external double get naturalWidth;
  external double get naturalHeight;
  external set width(double? value);
  external set height(double? value);
  Future<dynamic> decode() =>
      js_util.promiseToFuture(js_util.callMethod(this, 'decode', <Object>[]));
}

@JS()
@staticInterop
class DomHTMLScriptElement extends DomHTMLElement {}

extension DomHTMLScriptElementExtension on DomHTMLScriptElement {
  external set src(Object /* String|TrustedScriptURL */ value);
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

@visibleForTesting
int debugCanvasCount = 0;

@visibleForTesting
void debugResetCanvasCount() {
  debugCanvasCount = 0;
}

DomCanvasElement createDomCanvasElement({int? width, int? height}) {
  debugCanvasCount++;
  final DomCanvasElement canvas =
      domWindow.document.createElement('canvas') as DomCanvasElement;
  if (width != null) {
    canvas.width = width.toDouble();
  }
  if (height != null) {
    canvas.height = height.toDouble();
  }
  return canvas;
}

extension DomCanvasElementExtension on DomCanvasElement {
  external double? get width;
  external set width(double? value);
  external double? get height;
  external set height(double? value);
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

  WebGLContext getGlContext(int majorVersion) {
    if (majorVersion == 1) {
      return getContext('webgl')! as WebGLContext;
    }
    return getContext('webgl2')! as WebGLContext;
  }
}

@JS()
@staticInterop
class WebGLContext {}

extension WebGLContextExtension on WebGLContext {
  external int getParameter(int value);

  @JS('SAMPLES')
  external int get samples;

  @JS('STENCIL_BITS')
  external int get stencilBits;
}

@JS()
@staticInterop
abstract class DomCanvasImageSource {}

@JS()
@staticInterop
class DomCanvasRenderingContext2D {}

extension DomCanvasRenderingContext2DExtension on DomCanvasRenderingContext2D {
  external DomCanvasElement? get canvas;
  external Object? get fillStyle;
  external set fillStyle(Object? style);
  external String get font;
  external set font(String value);
  external String get direction;
  external set direction(String value);
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
  DomImageData getImageData(int x, int y, int sw, int sh) =>
      js_util.callMethod(this, 'getImageData',
          <Object>[x.toDouble(), y.toDouble(), sw.toDouble(), sh.toDouble()]);
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
class DomCanvasRenderingContextWebGl {}

extension DomCanvasRenderingContextWebGlExtension on DomCanvasRenderingContextWebGl {
  external bool isContextLost();
}

@JS()
@staticInterop
class DomImageData {}

DomImageData createDomImageData(Object? data, int sw, int sh) => js_util
    .callConstructor(domGetConstructor('ImageData')!, <Object?>[data,
        sw.toDouble(), sh.toDouble()]);

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

Future<_DomResponse> _rawHttpGet(String url) {
  return js_util.promiseToFuture<_DomResponse>(js_util.callMethod(domWindow, 'fetch', <String>[url]));
}

typedef MockHttpFetchResponseFactory = Future<MockHttpFetchResponse> Function(String url);

MockHttpFetchResponseFactory? mockHttpFetchResponseFactory;

/// Makes an HTTP GET request to the given [url] and returns the response.
///
/// If the request fails, throws [HttpFetchError]. HTTP error statuses, such as
/// 404 and 500 are not treated as request failures. In those cases the HTTP
/// part did succeed and correctly passed the HTTP status down from the server
/// to the client. Those statuses represent application-level errors that need
/// extra interpretation to decide if they are "failures" or not. See
/// [HttpFetchResponse.hasPayload] and [HttpFetchResponse.payload].
///
/// This function is designed to handle the most general cases. If the default
/// payload handling, including error checking, is sufficient, consider using
/// convenience functions [httpFetchByteBuffer], [httpFetchJson], or
/// [httpFetchText] instead.
Future<HttpFetchResponse> httpFetch(String url) async {
  if (mockHttpFetchResponseFactory != null) {
    return mockHttpFetchResponseFactory!(url);
  }
  try {
    final _DomResponse domResponse = await _rawHttpGet(url);
    return HttpFetchResponseImpl._(url, domResponse);
  } catch (requestError) {
    throw HttpFetchError(url, requestError: requestError);
  }
}

Future<_DomResponse> _rawHttpPost(String url, String data) {
  return js_util.promiseToFuture<_DomResponse>(js_util.callMethod(
    domWindow,
    'fetch',
    <Object?>[
      url,
      js_util.jsify(<String, Object?>{
        'method': 'POST',
        'headers': <String, Object?>{
          'Content-Type': 'text/plain',
        },
        'body': data,
      }),
    ],
  ));
}

/// Sends a [data] string as HTTP POST request to [url].
///
/// The web engine does not make POST requests in production code because it is
/// designed to be able to run web apps served from plain file servers, so this
/// is meant for tests only.
@visibleForTesting
Future<HttpFetchResponse> testOnlyHttpPost(String url, String data) async {
  try {
    final _DomResponse domResponse = await _rawHttpPost(url, data);
    return HttpFetchResponseImpl._(url, domResponse);
  } catch (requestError) {
    throw HttpFetchError(url, requestError: requestError);
  }
}

/// Convenience function for making a fetch request and getting the data as a
/// [ByteBuffer], when the default error handling mechanism is sufficient.
Future<ByteBuffer> httpFetchByteBuffer(String url) async {
  final HttpFetchResponse response = await httpFetch(url);
  return response.asByteBuffer();
}

/// Convenience function for making a fetch request and getting the data as a
/// JSON object, when the default error handling mechanism is sufficient.
Future<Object?> httpFetchJson(String url) async {
  final HttpFetchResponse response = await httpFetch(url);
  return response.json();
}

/// Convenience function for making a fetch request and getting the data as a
/// [String], when the default error handling mechanism is sufficient.
Future<String> httpFetchText(String url) async {
  final HttpFetchResponse response = await httpFetch(url);
  return response.text();
}

/// Successful result of [httpFetch].
abstract class HttpFetchResponse {
  /// The URL passed to [httpFetch] that returns this response.
  String get url;

  /// The HTTP response status, such as 200 or 404.
  int get status;

  /// The payload length of this response parsed from the "Content-Length" HTTP
  /// header.
  ///
  /// Returns null if "Content-Length" is missing.
  int? get contentLength;

  /// Return true if this response has a [payload].
  ///
  /// Returns false if this response does not have a payload and therefore it is
  /// unsafe to call the [payload] getter.
  bool get hasPayload;

  /// Returns the payload of this response.
  ///
  /// It is only safe to call this getter if [hasPayload] is true. If
  /// [hasPayload] is false, throws [HttpFetchNoPayloadError].
  HttpFetchPayload get payload;
}

/// Convenience methods for simple cases when the default error checking
/// mechanisms are sufficient.
extension HttpFetchResponseExtension on HttpFetchResponse {
  /// Reads the payload a chunk at a time.
  ///
  /// Combined with [HttpFetchResponse.contentLength], this can be used to
  /// implement various "progress bar" functionality.
  Future<void> read<T>(HttpFetchReader<T> reader) {
    return payload.read(reader);
  }

  /// Returns the data as a [ByteBuffer].
  Future<ByteBuffer> asByteBuffer() {
    return payload.asByteBuffer();
  }

  /// Returns the data as a [Uint8List].
  Future<Uint8List> asUint8List() async {
    return (await payload.asByteBuffer()).asUint8List();
  }

  /// Returns the data parsed as JSON.
  Future<dynamic> json() {
    return payload.json();
  }

  /// Return the data as a string.
  Future<String> text() {
    return payload.text();
  }
}

class HttpFetchResponseImpl implements HttpFetchResponse {
  HttpFetchResponseImpl._(this.url, this._domResponse);

  @override
  final String url;

  final _DomResponse _domResponse;

  @override
  int get status => _domResponse.status.toInt();

  @override
  int? get contentLength {
    final String? header = _domResponse.headers.get('Content-Length');
    if (header == null) {
      return null;
    }
    return int.tryParse(header);
  }

  @override
  bool get hasPayload {
    final bool accepted = status >= 200 && status < 300;
    final bool fileUri = status == 0;
    final bool notModified = status == 304;
    final bool unknownRedirect = status > 307 && status < 400;
    return accepted || fileUri || notModified || unknownRedirect;
  }

  @override
  HttpFetchPayload get payload {
    if (!hasPayload) {
      throw HttpFetchNoPayloadError(url, status: status);
    }
    return HttpFetchPayloadImpl._(_domResponse);
  }
}

/// A fake implementation of [HttpFetchResponse] for testing.
class MockHttpFetchResponse implements HttpFetchResponse {
  MockHttpFetchResponse({
    required this.url,
    required this.status,
    this.contentLength,
    HttpFetchPayload? payload,
  }) : _payload = payload;

  final HttpFetchPayload? _payload;

  @override
  final String url;

  @override
  final int status;

  @override
  final int? contentLength;

  @override
  bool get hasPayload => _payload != null;

  @override
  HttpFetchPayload get payload => _payload!;
}

typedef HttpFetchReader<T> = void Function(T chunk);

/// Data returned with a [HttpFetchResponse].
abstract class HttpFetchPayload {
  /// Reads the payload a chunk at a time.
  ///
  /// Combined with [HttpFetchResponse.contentLength], this can be used to
  /// implement various "progress bar" functionality.
  Future<void> read<T>(HttpFetchReader<T> reader);

  /// Returns the data as a [ByteBuffer].
  Future<ByteBuffer> asByteBuffer();

  /// Returns the data parsed as JSON.
  Future<dynamic> json();

  /// Return the data as a string.
  Future<String> text();
}

class HttpFetchPayloadImpl implements HttpFetchPayload {
  HttpFetchPayloadImpl._(this._domResponse);

  final _DomResponse _domResponse;

  @override
  Future<void> read<T>(HttpFetchReader<T> callback) async {
    final _DomReadableStream stream = _domResponse.body;
    final _DomStreamReader reader = stream.getReader();

    while (true) {
      final _DomStreamChunk chunk = await reader.read();
      if (chunk.done) {
        break;
      }
      callback(chunk.value as T);
    }
  }

  /// Returns the data as a [ByteBuffer].
  @override
  Future<ByteBuffer> asByteBuffer() async {
    return (await _domResponse.arrayBuffer()) as ByteBuffer;
  }

  /// Returns the data parsed as JSON.
  @override
  Future<dynamic> json() => _domResponse.json();

  /// Return the data as a string.
  @override
  Future<String> text() => _domResponse.text();
}

typedef MockOnRead = Future<void> Function<T>(HttpFetchReader<T> callback);

class MockHttpFetchPayload implements HttpFetchPayload {
  MockHttpFetchPayload({
    ByteBuffer? byteBuffer,
    Object? json,
    String? text,
    MockOnRead? onRead,
  }) : _byteBuffer = byteBuffer, _json = json, _text = text, _onRead = onRead;

  final ByteBuffer? _byteBuffer;
  final Object? _json;
  final String? _text;
  final MockOnRead? _onRead;

  @override
  Future<void> read<T>(HttpFetchReader<T> callback) => _onRead!(callback);

  @override
  Future<ByteBuffer> asByteBuffer() async => _byteBuffer!;

  @override
  Future<dynamic> json() async => _json!;

  @override
  Future<String> text() async => _text!;
}

/// Indicates a missing HTTP payload when one was expected, such as when
/// [HttpFetchResponse.payload] was called.
///
/// Unlike [HttpFetchError], this error happens when the HTTP request/response
/// succeeded, but the response type is not the kind that provides useful
/// payload, such as 404, or 500.
class HttpFetchNoPayloadError implements Exception {
  /// Creates an exception from a successful HTTP request, but an unsuccessful
  /// HTTP response code, such as 404 or 500.
  HttpFetchNoPayloadError(this.url, { required this.status });

  /// HTTP request URL for asset.
  final String url;

  /// If the HTTP request succeeded, the HTTP response status.
  ///
  /// Null if the HTTP request failed.
  final int status;

  @override
  String toString() {
    return 'Flutter Web engine failed to fetch "$url". HTTP request succeeded, '
           'but the server responded with HTTP status $status.';
  }
}

/// Indicates a failure trying to fetch a [url].
///
/// Unlike [HttpFetchNoPayloadError] this error indicates that there was no HTTP
/// response and the roundtrip what interrupted by something else, like a loss
/// of network connectivity, or request being interrupted by the OS, a browser
/// CORS policy, etc. In particular, there's not even a HTTP status code to
/// report, such as 200, 404, or 500.
class HttpFetchError implements Exception {
  /// Creates an exception from a failed HTTP request.
  HttpFetchError(this.url, { required this.requestError });

  /// HTTP request URL for asset.
  final String url;

  /// The underlying network error that prevented [httpFetch] from succeeding.
  final Object requestError;

  @override
  String toString() {
    return 'Flutter Web engine failed to complete HTTP request to fetch '
           '"$url": $requestError';
  }
}

@JS()
@staticInterop
class _DomResponse {}

extension _DomResponseExtension on _DomResponse {
  external double get status;

  external _DomHeaders get headers;

  external _DomReadableStream get body;

  Future<dynamic> arrayBuffer() => js_util
      .promiseToFuture(js_util.callMethod(this, 'arrayBuffer', <Object>[]));

  Future<dynamic> json() =>
      js_util.promiseToFuture(js_util.callMethod(this, 'json', <Object>[]));

  Future<String> text() =>
      js_util.promiseToFuture(js_util.callMethod(this, 'text', <Object>[]));
}

@JS()
@staticInterop
class _DomHeaders {}

extension _DomHeadersExtension on _DomHeaders {
  external String? get(String? headerName);
}

@JS()
@staticInterop
class _DomReadableStream {}
extension _DomReadableStreamExtension on _DomReadableStream {
  external _DomStreamReader getReader();
}

@JS()
@staticInterop
class _DomStreamReader {}
extension _DomStreamReaderExtension on _DomStreamReader {
  Future<_DomStreamChunk> read() {
    return js_util.promiseToFuture<_DomStreamChunk>(js_util.callMethod(this, 'read', <Object>[]));
  }
}

@JS()
@staticInterop
class _DomStreamChunk {}
extension _DomStreamChunkExtension on _DomStreamChunk {
  external Object? get value;
  external bool get done;
}

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
  external double? get width;
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
  external double get x;
  external double get y;
  external double get width;
  external double get height;
  external double get top;
  external double get right;
  external double get bottom;
  external double get left;
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
    domCallConstructorString('FontFace', <Object?>[
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
  external double? get height;
  external double? get width;
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
  external double? get selectionStart;
  external double? get selectionEnd;
  external set selectionStart(double? value);
  external set selectionEnd(double? value);
  external String? get value;
  void setSelectionRange(int start, int end, [String? direction]) =>
      js_util.callMethod(this, 'setSelectionRange',
          <Object>[start.toDouble(), end.toDouble(),
                   if (direction != null) direction]);
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
  external double get keyCode;
  external double get location;
  external bool get metaKey;
  external bool? get repeat;
  external bool get shiftKey;
  external bool get isComposing;
  external bool getModifierState(String keyArg);
}

DomKeyboardEvent createDomKeyboardEvent(String type,
        [Map<dynamic, dynamic>? init]) =>
    js_util.callConstructor(domGetConstructor('KeyboardEvent')!,
        <Object?>[type, if (init != null) js_util.jsify(init)]);

@JS()
@staticInterop
class DomHistory {}

extension DomHistoryExtension on DomHistory {
  dynamic get state => js_util.dartify(js_util.getProperty(this, 'state'));
  void go([double? delta]) =>
      js_util.callMethod(this, 'go',
          <Object>[if (delta != null) delta]);
  void pushState(dynamic data, String title, String? url) =>
      js_util.callMethod(this, 'pushState', <Object?>[
        if (data is Map || data is Iterable) js_util.jsify(data as Object) else data,
        title,
        url
      ]);
  void replaceState(dynamic data, String title, String? url) =>
      js_util.callMethod(this, 'replaceState', <Object?>[
        if (data is Map || data is Iterable) js_util.jsify(data as Object) else data,
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
    domCallConstructorString('PopStateEvent', <Object?>[
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
        .callMethod(this, 'observe', <Object?>[target, js_util.jsify(options)]);
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
  external double get clientX;
  external double get clientY;
  external double get offsetX;
  external double get offsetY;
  external double get pageX;
  external double get pageY;
  DomPoint get client => DomPoint(clientX, clientY);
  DomPoint get offset => DomPoint(offsetX, offsetY);
  external double get button;
  external double? get buttons;
  external bool getModifierState(String keyArg);
}

DomMouseEvent createDomMouseEvent(String type, [Map<dynamic, dynamic>? init]) =>
    js_util.callConstructor(domGetConstructor('MouseEvent')!,
        <Object?>[type, if (init != null) js_util.jsify(init)]);

@JS()
@staticInterop
class DomPointerEvent extends DomMouseEvent {}

extension DomPointerEventExtension on DomPointerEvent {
  external double? get pointerId;
  external String? get pointerType;
  external double? get pressure;
  external double? get tiltX;
  external double? get tiltY;
  List<DomPointerEvent> getCoalescedEvents() =>
      js_util.callMethod<List<Object?>>(
          this, 'getCoalescedEvents', <Object>[]).cast<DomPointerEvent>();
}

DomPointerEvent createDomPointerEvent(String type,
        [Map<dynamic, dynamic>? init]) =>
    js_util.callConstructor(domGetConstructor('PointerEvent')!,
        <Object?>[type, if (init != null) js_util.jsify(init)]);

@JS()
@staticInterop
class DomWheelEvent extends DomMouseEvent {}

extension DomWheelEventExtension on DomWheelEvent {
  external double get deltaX;
  external double get deltaY;
  external double? get wheelDeltaX;
  external double? get wheelDeltaY;
  external double get deltaMode;
}

DomWheelEvent createDomWheelEvent(String type,
        [Map<dynamic, dynamic>? init]) =>
    js_util.callConstructor(domGetConstructor('WheelEvent')!,
        <Object?>[type, if (init != null) js_util.jsify(init)]);

@JS()
@staticInterop
class DomTouchEvent extends DomUIEvent {}

extension DomTouchEventExtension on DomTouchEvent {
  external bool get altKey;
  external bool get ctrlKey;
  external bool get metaKey;
  external bool get shiftKey;
  Iterable<DomTouch> get changedTouches =>
      createDomTouchListWrapper<DomTouch>(
        js_util.getProperty<_DomTouchList>(this, 'changedTouches'));
}

@JS()
@staticInterop
class DomTouch {}

extension DomTouchExtension on DomTouch {
  external double? get identifier;
  external double get clientX;
  external double get clientY;
  DomPoint get client => DomPoint(clientX, clientY);
}

DomTouch createDomTouch([Map<dynamic, dynamic>? init]) =>
    js_util.callConstructor(domGetConstructor('Touch')!,
        <Object?>[if (init != null) js_util.jsify(init)]) as DomTouch;

DomTouchEvent createDomTouchEvent(String type, [Map<dynamic, dynamic>? init]) =>
    js_util.callConstructor(domGetConstructor('TouchEvent')!,
        <Object?>[type, if (init != null) js_util.jsify(init)]);

@JS()
@staticInterop
class DomCompositionEvent extends DomUIEvent {}

extension DomCompositionEventExtension on DomCompositionEvent {
  external String? get data;
}

DomCompositionEvent createDomCompositionEvent(String type,
        [Map<dynamic, dynamic>? options]) =>
    js_util.callConstructor(domGetConstructor('CompositionEvent')!,
        <Object?>[type, if (options != null) js_util.jsify(options)]);

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
  external double? get selectionStart;
  external double? get selectionEnd;
  external set selectionStart(double? value);
  external set selectionEnd(double? value);
  void setSelectionRange(int start, int end, [String? direction]) =>
      js_util.callMethod(this, 'setSelectionRange',
          <Object>[start.toDouble(), end.toDouble(),
                   if (direction != null) direction]);
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
  external double? get height;
  external double? get width;
  external set height(double? value);
  external set width(double? value);
  Object? getContext(String contextType, [Map<dynamic, dynamic>? attributes]) {
    return js_util.callMethod(this, 'getContext', <Object?>[
      contextType,
      if (attributes != null) js_util.jsify(attributes)
    ]);
  }

  Future<DomBlob> convertToBlob([Map<Object?, Object?>? options]) =>
      js_util.promiseToFuture(js_util.callMethod(this, 'convertToBlob',
          <Object?>[if (options != null) js_util.jsify(options)]));
}

DomOffscreenCanvas createDomOffscreenCanvas(int width, int height) =>
    js_util.callConstructor(
        domGetConstructor('OffscreenCanvas')!,
        <Object>[width.toDouble(), height.toDouble()]);

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
  DomElement? elementFromPoint(int x, int y) =>
      js_util.callMethod<DomElement?>(this, 'elementFromPoint',
          <Object>[x.toDouble(), y.toDouble()]);
}

@JS()
@staticInterop
class DomStyleSheet {}

@JS()
@staticInterop
class DomCSSStyleSheet extends DomStyleSheet {}

extension DomCSSStyleSheetExtension on DomCSSStyleSheet {
  Iterable<DomCSSRule> get cssRules =>
      createDomListWrapper<DomCSSRule>(js_util
          .getProperty<_DomList>(this, 'cssRules'));

  double insertRule(String rule, [int? index]) => js_util
      .callMethod<double>(
          this, 'insertRule',
          <Object>[rule, if (index != null) index.toDouble()]);
}

@JS()
@staticInterop
class DomCSSRule {}

@JS()
@staticInterop
extension DomCSSRuleExtension on DomCSSRule {
  external String get cssText;
}

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
  Future<dynamic> lock(String orientation) {
    final Object jsResult = js_util.callMethod<Object>(this, 'lock', <String>[orientation]);
    return js_util.promiseToFuture(jsResult);
  }
  external void unlock();
}

// A helper class for managing a subscription. On construction it will add an
// event listener of the requested type to the target. Calling [cancel] will
// remove the listener. Caller is still responsible for calling [allowInterop]
// on the listener before creating the subscription.
class DomSubscription {
  DomSubscription(this.target, this.type, this.listener) {
    target.addEventListener(type, listener);
  }

  final String type;
  final DomEventTarget target;
  final DomEventListener listener;

  void cancel() => target.removeEventListener(type, listener);
}

class DomPoint {
  DomPoint(this.x, this.y);

  final num x;
  final num y;
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
      <Object?>[if (message != null) js_util.jsify(message)]);
  external void start();
}

@JS()
@staticInterop
class DomMessageChannel {}

extension DomMessageChannelExtension on DomMessageChannel {
  external DomMessagePort get port1;
  external DomMessagePort get port2;
}

/// ResizeObserver JS binding.
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/ResizeObserver
@JS()
@staticInterop
abstract class DomResizeObserver {}

/// Creates a DomResizeObserver with a callback.
///
/// Internally converts the `List<dynamic>` of entries into the expected
/// `List<DomResizeObserverEntry>`
DomResizeObserver? createDomResizeObserver(DomResizeObserverCallbackFn fn) {
  return domCallConstructorString('ResizeObserver', <Object?>[
    allowInterop(
      (List<dynamic> entries, DomResizeObserver observer) {
        fn(entries.cast<DomResizeObserverEntry>(), observer);
      }
    ),
  ]) as DomResizeObserver?;
}

/// ResizeObserver instance methods.
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/ResizeObserver#instance_methods
extension DomResizeObserverExtension on DomResizeObserver {
  external void disconnect();
  external void observe(DomElement target, [DomResizeObserverObserveOptions options]);
  external void unobserve(DomElement target);
}

/// Options object passed to the `observe` method of a [DomResizeObserver].
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/ResizeObserver/observe#parameters
@JS()
@staticInterop
@anonymous
abstract class DomResizeObserverObserveOptions {
  external factory DomResizeObserverObserveOptions({
    String box,
  });
}

/// Type of the function used to create a Resize Observer.
typedef DomResizeObserverCallbackFn = void Function(List<DomResizeObserverEntry> entries, DomResizeObserver observer);

/// The object passed to the [DomResizeObserverCallbackFn], which allows access to the new dimensions of the observed element.
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/ResizeObserverEntry
@JS()
@staticInterop
abstract class DomResizeObserverEntry {}

/// ResizeObserverEntry instance properties.
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/ResizeObserverEntry#instance_properties
extension DomResizeObserverEntryExtension on DomResizeObserverEntry {
  /// A DOMRectReadOnly object containing the new size of the observed element when the callback is run.
  ///
  /// Note that this is better supported than the above two properties, but it
  /// is left over from an earlier implementation of the Resize Observer API, is
  /// still included in the spec for web compat reasons, and may be deprecated
  /// in future versions.
  external DomRectReadOnly get contentRect;
  external DomElement get target;
  // Some more future getters:
  //
  // borderBoxSize
  // contentBoxSize
  // devicePixelContentBoxSize
}

/// A factory to create `TrustedTypePolicy` objects.
/// See: https://developer.mozilla.org/en-US/docs/Web/API/TrustedTypePolicyFactory
@JS()
@staticInterop
abstract class DomTrustedTypePolicyFactory {}

/// A subset of TrustedTypePolicyFactory methods.
extension DomTrustedTypePolicyFactoryExtension on DomTrustedTypePolicyFactory {
  /// Creates a TrustedTypePolicy object named `policyName` that implements the
  /// rules passed as `policyOptions`.
  external DomTrustedTypePolicy createPolicy(
    String policyName,
    DomTrustedTypePolicyOptions? policyOptions,
  );
}

/// Options to create a trusted type policy.
///
/// The options are user-defined functions for converting strings into trusted
/// values.
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/TrustedTypePolicyFactory/createPolicy#policyoptions
@JS()
@staticInterop
@anonymous
abstract class DomTrustedTypePolicyOptions {
  /// Constructs a TrustedTypePolicyOptions object in JavaScript.
  ///
  /// `createScriptURL` is a callback function that contains code to run when
  /// creating a TrustedScriptURL object.
  ///
  /// The following properties need to be manually wrapped in [allowInterop]
  /// before being passed to this constructor: [createScriptURL].
  external factory DomTrustedTypePolicyOptions({
    DomCreateScriptUrlOptionFn? createScriptURL,
  });
}

/// Type of the function used to configure createScriptURL.
typedef DomCreateScriptUrlOptionFn = String? Function(String input);

/// A TrustedTypePolicy defines a group of functions which create TrustedType
/// objects.
///
/// TrustedTypePolicy objects are created by `TrustedTypePolicyFactory.createPolicy`,
/// therefore this class has no constructor.
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/TrustedTypePolicy
@JS()
@staticInterop
abstract class DomTrustedTypePolicy {}

/// A subset of TrustedTypePolicy methods.
extension DomTrustedTypePolicyExtension on DomTrustedTypePolicy {
  /// Creates a `TrustedScriptURL` for the given [input].
  ///
  /// `input` is a string containing the data to be _sanitized_ by the policy.
  external DomTrustedScriptURL createScriptURL(String input);
}

/// Represents a string that a developer can insert into an _injection sink_
/// that will parse it as an external script.
///
/// These objects are created via `createScriptURL` and therefore have no
/// constructor.
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/TrustedScriptURL
@JS()
@staticInterop
abstract class DomTrustedScriptURL {}

/// A subset of TrustedScriptURL methods.
extension DomTrustedScriptUrlExtension on DomTrustedScriptURL {
  /// Exposes the `toString` JS method of TrustedScriptURL.
  String get url => js_util.callMethod<String>(this, 'toString', <String>[]);
}

// The expected set of files that the flutter-engine TrustedType policy is going
// to accept as valid.
const Set<String> _expectedFilesForTT = <String>{
  'canvaskit.js',
};

// The definition of the `flutter-engine` TrustedType policy.
// Only accessible if the Trusted Types API is available.
final DomTrustedTypePolicy _ttPolicy = domWindow.trustedTypes!.createPolicy(
  'flutter-engine',
  DomTrustedTypePolicyOptions(
    // Validates the given [url].
    createScriptURL: allowInterop(
      (String url) {
        final Uri uri = Uri.parse(url);
        if (_expectedFilesForTT.contains(uri.pathSegments.last)) {
          return uri.toString();
        }
        domWindow.console
            .error('URL rejected by TrustedTypes policy flutter-engine: $url'
                '(download prevented)');

        return null;
      },
    ),
  ),
);

/// Converts a String `url` into a [DomTrustedScriptURL] object when the
/// Trusted Types API is available, else returns the unmodified `url`.
Object createTrustedScriptUrl(String url) {
  if (domWindow.trustedTypes != null) {
    // Pass `url` through Flutter Engine's TrustedType policy.
    final DomTrustedScriptURL trustedUrl = _ttPolicy.createScriptURL(url);

    assert(trustedUrl.url != '', 'URL: $url rejected by TrustedTypePolicy');

    return trustedUrl;
  }
  return url;
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
  external double get length;
  DomNode item(int index) =>
      js_util.callMethod<DomNode>(this, 'item', <Object>[index.toDouble()]);
}

class _DomListIterator<T> extends Iterator<T> {
  _DomListIterator(this.list);

  final _DomList list;
  int index = -1;

  @override
  bool moveNext() {
    index++;
    if (index > list.length) {
      throw StateError('Iterator out of bounds');
    }
    return index < list.length;
  }

  @override
  T get current => list.item(index) as T;
}

class _DomListWrapper<T> extends Iterable<T> {
  _DomListWrapper._(this.list);

  final _DomList list;

  @override
  Iterator<T> get iterator => _DomListIterator<T>(list);

  /// Override the length to avoid iterating through the whole collection.
  @override
  int get length => list.length.toInt();
}

/// This is a work around for a `TypeError` which can be triggered by calling
/// `toList` on the `Iterable`.
Iterable<T> createDomListWrapper<T>(_DomList list) =>
    _DomListWrapper<T>._(list).cast<T>();

// https://developer.mozilla.org/en-US/docs/Web/API/TouchList
@JS()
@staticInterop
class _DomTouchList {}

extension DomTouchListExtension on _DomTouchList {
  external double get length;
  DomTouch item(int index) =>
      js_util.callMethod<DomTouch>(this, 'item', <Object>[index.toDouble()]);
}

class _DomTouchListIterator<T> extends Iterator<T> {
  _DomTouchListIterator(this.list);

  final _DomTouchList list;
  int index = -1;

  @override
  bool moveNext() {
    index++;
    if (index > list.length) {
      throw StateError('Iterator out of bounds');
    }
    return index < list.length;
  }

  @override
  T get current => list.item(index) as T;
}

class _DomTouchListWrapper<T> extends Iterable<T> {
  _DomTouchListWrapper._(this.list);

  final _DomTouchList list;

  @override
  Iterator<T> get iterator => _DomTouchListIterator<T>(list);

  /// Override the length to avoid iterating through the whole collection.
  @override
  int get length => list.length.toInt();
}

Iterable<T> createDomTouchListWrapper<T>(_DomTouchList list) =>
    _DomTouchListWrapper<T>._(list).cast<T>();

@JS()
@staticInterop
class DomIntl {}

extension DomIntlExtension on DomIntl {
  /// This is a V8-only API for segmenting text.
  ///
  /// See: https://code.google.com/archive/p/v8-i18n/wikis/BreakIterator.wiki
  external Object? get v8BreakIterator;
}


@JS()
@staticInterop
class DomV8BreakIterator {}

extension DomV8BreakIteratorExtension on DomV8BreakIterator {
  external void adoptText(String text);
  external double first();
  external double next();
  external double current();
  external String breakType();
}

DomV8BreakIterator createV8BreakIterator() {
  final Object? v8BreakIterator = domIntl.v8BreakIterator;
  if (v8BreakIterator == null) {
    throw UnimplementedError('v8BreakIterator is not supported.');
  }

  return js_util.callConstructor<DomV8BreakIterator>(
    v8BreakIterator,
    <Object?>[
      <String>[],
      js_util.jsify(const <String, String>{'type': 'line'}),
    ],
  );
}
