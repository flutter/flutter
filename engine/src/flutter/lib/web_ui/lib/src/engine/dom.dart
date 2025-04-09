// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'browser_detection.dart';

/// This file contains static interop classes for interacting with the DOM and
/// some helpers. All of the classes in this file are named after their
/// counterparts in the DOM. To extend any of these classes, simply add an
/// external method to the appropriate class's extension. To add a new class,
/// simply name the class after it's counterpart in the DOM and prefix the
/// class name with `Dom`.
/// NOTE: Currently, optional parameters do not behave as expected.
/// For the time being, avoid passing optional parameters directly to JS.

// TODO(joshualitt): To make it clearer to users of this shim that this is where
// the boundary between Dart and JS interop exists, we should expose JS types
// directly to the engine.

/// Conversions methods to facilitate migrating to JS types.
///
/// The existing behavior across the JS interop boundary involves many implicit
/// conversions. For efficiency reasons, on JS backends we still want those
/// implicit conversions, but on Wasm backends we need to 'shallowly' convert
/// these types.
///
/// Note: Due to discrepancies between how `null`, `JSNull`, and `JSUndefined`
/// are currently represented across web backends, these extensions should be
/// used carefully and only on types that are known to not contains `JSNull` and
/// `JSUndefined`.
extension ObjectToJSAnyExtension on Object {
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:tryInline')
  JSAny get toJSAnyShallow {
    if (isWasm) {
      return toJSAnyDeep;
    } else {
      return this as JSAny;
    }
  }

  @pragma('wasm:prefer-inline')
  @pragma('dart2js:tryInline')
  JSAny get toJSAnyDeep => jsify()!;
}

extension JSAnyToObjectExtension on JSAny {
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:tryInline')
  Object get toObjectShallow {
    if (isWasm) {
      return toObjectDeep;
    } else {
      return this;
    }
  }

  @pragma('wasm:prefer-inline')
  @pragma('dart2js:tryInline')
  Object get toObjectDeep => dartify()!;
}

@JS('Object')
external DomObjectConstructor get objectConstructor;

extension type DomObjectConstructor._(JSObject _) implements JSObject {
  external JSObject assign(JSAny? target, JSAny? source1, JSAny? source2);
}

@JS('Window')
extension type DomWindow._(JSObject _) implements DomEventTarget {
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

  @JS('fetch')
  external JSPromise<JSAny?> _fetch(String url, [JSAny headers]);

  // ignore: non_constant_identifier_names
  external DomURL get URL;
  external DomMediaQueryList matchMedia(String? query);

  @JS('getComputedStyle')
  external DomCSSStyleDeclaration _getComputedStyle(DomElement elt, [String pseudoElt]);
  DomCSSStyleDeclaration getComputedStyle(DomElement elt, [String? pseudoElt]) {
    if (pseudoElt == null) {
      return _getComputedStyle(elt);
    } else {
      return _getComputedStyle(elt, pseudoElt);
    }
  }

  external DomScreen? get screen;

  JSFunction _makeAnimationFrameCallbackZoned(DomRequestAnimationFrameCallback callback) {
    final ZoneUnaryCallback<void, JSNumber> zonedCallback = Zone.current
        .bindUnaryCallback<void, JSNumber>(callback);
    return zonedCallback.toJS;
  }

  @JS('requestAnimationFrame')
  external double _requestAnimationFrame(JSFunction callback);
  double requestAnimationFrame(DomRequestAnimationFrameCallback callback) =>
      _requestAnimationFrame(_makeAnimationFrameCallbackZoned(callback));

  @JS('postMessage')
  external void _postMessage(JSAny message, String targetOrigin, [JSArray<JSAny?> messagePorts]);
  void postMessage(Object message, String targetOrigin, [List<DomMessagePort>? messagePorts]) {
    if (messagePorts == null) {
      _postMessage(message.toJSAnyShallow, targetOrigin);
    } else {
      _postMessage(
        message.toJSAnyShallow,
        targetOrigin,
        // Cast is necessary so we can call `.toJS` on the right extension.
        (messagePorts as List<JSAny>).toJS,
      );
    }
  }

  /// The Trusted Types API (when available).
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Trusted_Types_API
  external DomTrustedTypePolicyFactory? get trustedTypes;

  @JS('createImageBitmap')
  external JSPromise<JSAny?> _createImageBitmap(DomImageData source);
  Future<DomImageBitmap> createImageBitmap(DomImageData source) {
    return _createImageBitmap(source).toDart.then((JSAny? value) => value! as DomImageBitmap);
  }
}

typedef DomRequestAnimationFrameCallback = void Function(JSNumber highResTime);

extension type DomConsole._(JSObject _) implements JSObject {
  @JS('warn')
  external void _warn(String? arg);
  void warn(Object? arg) => _warn(arg.toString());

  @JS('error')
  external void _error(String? arg);
  void error(Object? arg) => _error(arg.toString());

  @JS('debug')
  external void _debug(String? arg);
  void debug(Object? arg) => _debug(arg.toString());
}

@JS('window')
external DomWindow get domWindow;

@JS('Intl')
external DomIntl get domIntl;

@JS('Symbol')
external DomSymbol get domSymbol;

@JS('createImageBitmap')
external JSPromise<JSAny?> _createImageBitmap(JSAny source, [int x, int y, int width, int height]);
Future<DomImageBitmap> createImageBitmap(
  JSAny source, [
  ({int x, int y, int width, int height})? bounds,
]) {
  JSPromise<JSAny?> jsPromise;
  if (bounds != null) {
    jsPromise = _createImageBitmap(source, bounds.x, bounds.y, bounds.width, bounds.height);
  } else {
    jsPromise = _createImageBitmap(source);
  }
  return jsPromise.toDart.then((JSAny? value) => value! as DomImageBitmap);
}

@JS('Navigator')
extension type DomNavigator._(JSObject _) implements JSObject {
  external DomClipboard? get clipboard;
  external double? get maxTouchPoints;
  external String get vendor;
  external String get language;
  external String? get platform;
  external String get userAgent;

  @JS('languages')
  external JSArray<JSAny?>? get _languages;
  List<String>? get languages =>
      _languages?.toDart.map<String>((JSAny? any) => (any! as JSString).toDart).toList();
}

@JS('Document')
extension type DomDocument._(JSObject _) implements DomNode {
  external DomElement? get documentElement;
  external DomElement? querySelector(String selectors);

  @JS('querySelectorAll')
  external _DomList _querySelectorAll(String selectors);
  Iterable<DomElement> querySelectorAll(String selectors) =>
      _createDomListWrapper<DomElement>(_querySelectorAll(selectors));

  @JS('createElement')
  external DomElement _createElement(String name, [JSAny? options]);
  DomElement createElement(String name, [Object? options]) {
    if (options == null) {
      return _createElement(name);
    } else {
      return _createElement(name, options.toJSAnyDeep);
    }
  }

  external bool execCommand(String commandId);
  external DomHTMLScriptElement? get currentScript;
  external DomElement createElementNS(String namespaceURI, String qualifiedName);
  external DomText createTextNode(String data);
  external DomEvent createEvent(String eventType);
  external DomElement? get activeElement;
  external DomElement? elementFromPoint(int x, int y);
}

@JS('HTMLDocument')
extension type DomHTMLDocument._(JSObject _) implements DomDocument {
  external DomFontFaceSet? get fonts;
  external DomHTMLHeadElement? get head;
  external DomHTMLBodyElement? get body;
  external String? title;

  @JS('getElementsByTagName')
  external _DomList _getElementsByTagName(String tag);
  Iterable<DomElement> getElementsByTagName(String tag) =>
      _createDomListWrapper<DomElement>(_getElementsByTagName(tag));

  external DomElement? getElementById(String id);
  external String get visibilityState;
  external bool hasFocus();
}

@JS('document')
external DomHTMLDocument get domDocument;

/// Creates a [DomEventListener] that runs in the current [Zone].
// TODO(srujzs): It isn't clear whether we should use this all the time or only
// sometimes. Using this as the wrapped handler in `keyboard_binding.dart` for
// example leads to test failures.
DomEventListener createDomEventListener(DartDomEventListener listener) {
  final ZoneUnaryCallback<void, DomEvent> zonedListener = Zone.current
      .bindUnaryCallback<void, DomEvent>(listener);
  return zonedListener.toJS;
}

@JS('EventTarget')
extension type DomEventTarget._(JSObject _) implements JSObject {
  external void addEventListener(String type, DomEventListener? listener, [JSAny options]);

  external void removeEventListener(String type, DomEventListener? listener, [JSAny options]);

  @JS('dispatchEvent')
  external bool _dispatchEvent(DomEvent event);
  // We need the non-external member for tear-offs.
  bool dispatchEvent(DomEvent event) => _dispatchEvent(event);
}

extension type DomEventListenerOptions._(JSObject _) implements JSObject {
  external DomEventListenerOptions({bool capture, bool passive, bool once});

  external bool capture;
  external bool passive;
  external bool once;
}

typedef DartDomEventListener = void Function(DomEvent event);
typedef DomEventListener = JSFunction;

@JS('Event')
extension type DomEvent._(JSObject _) implements JSObject {
  external DomEventTarget? get target;
  external DomEventTarget? get currentTarget;
  external double? get timeStamp;
  external String get type;

  @JS('cancelable')
  external bool? get _cancelable;
  bool get cancelable => _cancelable ?? true;

  external void preventDefault();
  external void stopPropagation();

  @JS('initEvent')
  external void _initEvent(String type, [bool bubbles, bool cancelable]);
  void initEvent(String type, [bool? bubbles, bool? cancelable]) {
    if (bubbles == null) {
      _initEvent(type);
    } else if (cancelable == null) {
      _initEvent(type, bubbles);
    } else {
      _initEvent(type, bubbles, cancelable);
    }
  }

  external bool get defaultPrevented;
}

DomEvent createDomEvent(String type, String name) {
  final DomEvent event = domDocument.createEvent(type);
  event.initEvent(name, true, true);
  return event;
}

@JS('ProgressEvent')
extension type DomProgressEvent._(JSObject _) implements DomEvent {
  external double? get loaded;
  external double? get total;
}

@JS('Node')
extension type DomNode._(JSObject _) implements DomEventTarget {
  @JS('baseURI')
  external String? get baseUri;
  external DomNode? get firstChild;
  external String innerText;
  external DomNode? get lastChild;
  external DomNode appendChild(DomNode node);

  external DomElement? get parentElement;
  DomElement? get parent => parentElement;

  @JS('textContent')
  external String? text;

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
  external DomNode cloneNode(bool? deep);
  external bool contains(DomNode? other);
  external void append(DomNode node);

  @JS('childNodes')
  external _DomList get _childNodes;
  Iterable<DomNode> get childNodes => _createDomListWrapper<DomElement>(_childNodes);

  external DomDocument? get ownerDocument;
  void clearChildren() {
    while (firstChild != null) {
      removeChild(firstChild!);
    }
  }
}

@JS('Element')
extension type DomElement._(JSObject _) implements DomNode {
  @JS('children')
  external _DomList get _children;
  Iterable<DomElement> get children => _createDomListWrapper<DomElement>(_children);

  external DomElement? get firstElementChild;
  external DomElement? get lastElementChild;
  external DomElement? get nextElementSibling;
  external double get clientHeight;
  external double get clientWidth;
  external double get offsetHeight;
  external double get offsetWidth;
  external String id;
  external set innerHTML(String? html);
  external String? get outerHTML;
  external set spellcheck(bool? value);
  external String get tagName;
  external DomCSSStyleDeclaration get style;
  external String? getAttribute(String attributeName);
  external DomRect getBoundingClientRect();
  external void prepend(DomNode node);
  external DomElement? querySelector(String selectors);
  external DomElement? closest(String selectors);
  external bool matches(String selectors);

  @JS('querySelectorAll')
  external _DomList _querySelectorAll(String selectors);
  Iterable<DomElement> querySelectorAll(String selectors) =>
      _createDomListWrapper<DomElement>(_querySelectorAll(selectors));

  // TODO(srujzs): Adding @redeclare here is leading to some build failures.
  // ignore: annotate_redeclares
  external void remove();

  @JS('setAttribute')
  external void _setAttribute(String name, JSAny value);
  void setAttribute(String name, Object value) => _setAttribute(name, value.toJSAnyDeep);

  void appendText(String text) => append(createDomText(text));
  external void removeAttribute(String name);
  external double? tabIndex;

  /// Consider not exposing this method publicly. It defaults `preventScroll` to
  /// false, which is almost always wrong in Flutter. If you need to expose a
  /// method that focuses and scrolls to the element, give it a more specific
  /// and lengthy name, e.g. `focusAndScrollToElement`. See more details in
  /// [focusWithoutScroll].
  @JS('focus')
  external void _focus(JSAny options);

  static final JSAny _preventScrollOptions = <String, bool>{'preventScroll': true}.toJSAnyDeep;

  /// Calls DOM `Element.focus` with `preventScroll` set to true.
  ///
  /// This method exists because DOM `Element.focus` defaults to `preventScroll`
  /// set to false. This default browser behavior is almost always wrong in the
  /// Flutter context because the Flutter framework is in charge of scrolling
  /// all of the widget content. See, for example, this issue:
  ///
  /// https://github.com/flutter/flutter/issues/130950
  void focusWithoutScroll() {
    _focus(_preventScrollOptions);
  }

  external double scrollTop;
  external double scrollLeft;
  external DomTokenList get classList;
  external String className;

  external void blur();

  @JS('getElementsByTagName')
  external _DomList _getElementsByTagName(String tag);
  Iterable<DomNode> getElementsByTagName(String tag) =>
      _createDomListWrapper(_getElementsByTagName(tag));

  @JS('getElementsByClassName')
  external _DomList _getElementsByClassName(String className);
  Iterable<DomNode> getElementsByClassName(String className) =>
      _createDomListWrapper(_getElementsByClassName(className));

  external void click();
  external bool hasAttribute(String name);

  @JS('attachShadow')
  external DomShadowRoot _attachShadow(JSAny initDict);
  DomShadowRoot attachShadow(Map<Object?, Object?> initDict) => _attachShadow(initDict.toJSAnyDeep);

  external DomShadowRoot? get shadowRoot;

  external void setPointerCapture(num? pointerId);
}

DomElement createDomElement(String tag) => domDocument.createElement(tag);

extension type DomCSS._(JSObject _) implements JSObject {
  external bool supports(String property, String value);
}

@JS('CSS')
external DomCSS get domCSS;

@JS('CSSStyleDeclaration')
extension type DomCSSStyleDeclaration._(JSObject _) implements JSObject {
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
  set textDecorationColor(String value) => setProperty('text-decoration-color', value);
  set fontFeatureSettings(String value) => setProperty('font-feature-settings', value);
  set fontVariationSettings(String value) => setProperty('font-variation-settings', value);
  set visibility(String value) => setProperty('visibility', value);
  set overflow(String value) => setProperty('overflow', value);
  set boxShadow(String value) => setProperty('box-shadow', value);
  set borderTopLeftRadius(String value) => setProperty('border-top-left-radius', value);
  set borderTopRightRadius(String value) => setProperty('border-top-right-radius', value);
  set borderBottomLeftRadius(String value) => setProperty('border-bottom-left-radius', value);
  set borderBottomRightRadius(String value) => setProperty('border-bottom-right-radius', value);
  set borderRadius(String value) => setProperty('border-radius', value);
  set perspective(String value) => setProperty('perspective', value);
  set padding(String value) => setProperty('padding', value);
  set backgroundImage(String value) => setProperty('background-image', value);
  set border(String value) => setProperty('border', value);
  set mixBlendMode(String value) => setProperty('mix-blend-mode', value);
  set backgroundSize(String value) => setProperty('background-size', value);
  set backgroundBlendMode(String value) => setProperty('background-blend-mode', value);
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
  set cursor(String value) => setProperty('cursor', value);
  set scrollbarWidth(String value) => setProperty('scrollbar-width', value);
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
  String get fontVariationSettings => getPropertyValue('font-variation-settings');
  String get visibility => getPropertyValue('visibility');
  String get overflow => getPropertyValue('overflow');
  String get boxShadow => getPropertyValue('box-shadow');
  String get borderTopLeftRadius => getPropertyValue('border-top-left-radius');
  String get borderTopRightRadius => getPropertyValue('border-top-right-radius');
  String get borderBottomLeftRadius => getPropertyValue('border-bottom-left-radius');
  String get borderBottomRightRadius => getPropertyValue('border-bottom-right-radius');
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
  String get cursor => getPropertyValue('cursor');
  String get scrollbarWidth => getPropertyValue('scrollbar-width');

  external String getPropertyValue(String property);

  @JS('setProperty')
  external void _setProperty(String propertyName, String value, String priority);
  void setProperty(String propertyName, String value, [String? priority]) {
    priority ??= '';
    _setProperty(propertyName, value, priority);
  }

  external String removeProperty(String property);
}

@JS('HTMLElement')
extension type DomHTMLElement._(JSObject _) implements DomElement {
  external double get offsetLeft;
  external double get offsetTop;
  external DomHTMLElement? get offsetParent;
}

@JS('HTMLMetaElement')
extension type DomHTMLMetaElement._(JSObject _) implements DomHTMLElement {
  external String name;
  external String content;
}

DomHTMLMetaElement createDomHTMLMetaElement() =>
    domDocument.createElement('meta') as DomHTMLMetaElement;

@JS('HTMLHeadElement')
extension type DomHTMLHeadElement._(JSObject _) implements DomHTMLElement {}

@JS('HTMLBodyElement')
extension type DomHTMLBodyElement._(JSObject _) implements DomHTMLElement {}

@JS('HTMLImageElement')
extension type DomHTMLImageElement._(JSObject _) implements DomHTMLElement, DomCanvasImageSource {
  external String? alt;
  external String? src;
  external double get naturalWidth;
  external double get naturalHeight;
  external set width(double? value);
  external set height(double? value);
  external String? crossOrigin;
  external String? decoding;

  @JS('decode')
  external JSPromise<JSAny?> _decode();
  Future<Object?> decode() => _decode().toDart;
}

DomHTMLImageElement createDomHTMLImageElement() =>
    domDocument.createElement('img') as DomHTMLImageElement;

@JS('HTMLScriptElement')
extension type DomHTMLScriptElement._(JSObject _) implements DomHTMLElement {
  @JS('src')
  external set _src(JSAny value);
  set src(Object /* String|TrustedScriptURL */ value) => _src = value.toJSAnyShallow;

  external set nonce(String? value);
}

DomHTMLScriptElement createDomHTMLScriptElement(String? nonce) {
  final DomHTMLScriptElement script = domDocument.createElement('script') as DomHTMLScriptElement;
  if (nonce != null) {
    script.nonce = nonce;
  }
  return script;
}

@JS('HTMLDivElement')
extension type DomHTMLDivElement._(JSObject _) implements DomHTMLElement {}

DomHTMLDivElement createDomHTMLDivElement() =>
    domDocument.createElement('div') as DomHTMLDivElement;

@JS('HTMLSpanElement')
extension type DomHTMLSpanElement._(JSObject _) implements DomHTMLElement {}

DomHTMLSpanElement createDomHTMLSpanElement() =>
    domDocument.createElement('span') as DomHTMLSpanElement;

@JS('HTMLButtonElement')
extension type DomHTMLButtonElement._(JSObject _) implements DomHTMLElement {}

DomHTMLButtonElement createDomHTMLButtonElement() =>
    domDocument.createElement('button') as DomHTMLButtonElement;

@JS('HTMLParagraphElement')
extension type DomHTMLParagraphElement._(JSObject _) implements DomHTMLElement {}

DomHTMLParagraphElement createDomHTMLParagraphElement() =>
    domDocument.createElement('p') as DomHTMLParagraphElement;

@JS('HTMLStyleElement')
extension type DomHTMLStyleElement._(JSObject _) implements DomHTMLElement {
  external set type(String? value);
  external String? nonce;
  external DomStyleSheet? get sheet;
}

DomHTMLStyleElement createDomHTMLStyleElement(String? nonce) {
  final DomHTMLStyleElement style = domDocument.createElement('style') as DomHTMLStyleElement;
  if (nonce != null) {
    style.nonce = nonce;
  }
  return style;
}

@JS('Performance')
extension type DomPerformance._(JSObject _) implements DomEventTarget {
  external DomPerformanceEntry? mark(String markName);
  external DomPerformanceMeasure? measure(String measureName, String? startMark, String? endMark);
  external double now();
}

@JS('PerformanceEntry')
extension type DomPerformanceEntry._(JSObject _) implements JSObject {}

@JS('PerformanceMeasure')
extension type DomPerformanceMeasure._(JSObject _) implements DomPerformanceEntry {}

@JS('HTMLCanvasElement')
extension type DomHTMLCanvasElement._(JSObject _) implements DomHTMLElement {
  external double? width;
  external double? height;

  @JS('toDataURL')
  external JSString _toDataURL(JSString type);
  String toDataURL([String type = 'image/png']) => _toDataURL(type.toJS).toDart;

  @JS('getContext')
  external JSAny? _getContext(String contextType, [JSAny attributes]);
  Object? getContext(String contextType, [Map<dynamic, dynamic>? attributes]) {
    if (attributes == null) {
      return _getContext(contextType);
    } else {
      return _getContext(contextType, attributes.toJSAnyDeep);
    }
  }

  DomCanvasRenderingContext2D get context2D => getContext('2d')! as DomCanvasRenderingContext2D;

  WebGLContext getGlContext(int majorVersion) {
    if (majorVersion == 1) {
      return getContext('webgl')! as WebGLContext;
    }
    return getContext('webgl2')! as WebGLContext;
  }

  DomImageBitmapRenderingContext get contextBitmapRenderer =>
      getContext('bitmaprenderer')! as DomImageBitmapRenderingContext;
}

@visibleForTesting
int debugCanvasCount = 0;

@visibleForTesting
void debugResetCanvasCount() {
  debugCanvasCount = 0;
}

DomHTMLCanvasElement createDomCanvasElement({int? width, int? height}) {
  debugCanvasCount++;
  final DomHTMLCanvasElement canvas =
      domWindow.document.createElement('canvas') as DomHTMLCanvasElement;
  if (width != null) {
    canvas.width = width.toDouble();
  }
  if (height != null) {
    canvas.height = height.toDouble();
  }
  return canvas;
}

extension type WebGLContext._(JSObject _) implements JSObject {
  external int getParameter(int value);

  @JS('SAMPLES')
  external int get samples;

  @JS('STENCIL_BITS')
  external int get stencilBits;
}

extension type DomCanvasImageSource._(JSObject _) implements JSObject {}

@JS('CanvasRenderingContext2D')
extension type DomCanvasRenderingContext2D._(JSObject _) implements JSObject {
  external DomHTMLCanvasElement? get canvas;

  @JS('fillStyle')
  external JSAny? get _fillStyle;
  Object? get fillStyle => _fillStyle?.toObjectShallow;

  @JS('fillStyle')
  external set _fillStyle(JSAny? style);
  set fillStyle(Object? style) => _fillStyle = style?.toJSAnyShallow;

  external String font;
  external String direction;
  external set lineWidth(num? value);

  @JS('strokeStyle')
  external set _strokeStyle(JSAny? value);
  set strokeStyle(Object? value) => _strokeStyle = value?.toJSAnyShallow;

  @JS('strokeStyle')
  external JSAny? get _strokeStyle;
  Object? get strokeStyle => _strokeStyle?.toObjectShallow;

  external void beginPath();
  external void closePath();
  external DomCanvasGradient createLinearGradient(num x0, num y0, num x1, num y1);

  @JS('createPattern')
  external DomCanvasPattern? _createPattern(JSAny image, String reptitionType);
  DomCanvasPattern? createPattern(Object image, String reptitionType) =>
      _createPattern(image.toJSAnyShallow, reptitionType);

  external DomCanvasGradient createRadialGradient(num x0, num y0, num r0, num x1, num y1, num r1);

  @JS('drawImage')
  external void _drawImage(
    DomCanvasImageSource source,
    num sxOrDx,
    num syOrDy, [
    num sWidth,
    num sHeight,
    num dx,
    num dy,
    num dWidth,
    num dHeight,
  ]);
  void drawImage(
    DomCanvasImageSource source,
    num srcxOrDstX,
    num srcyOrDstY, [
    num? srcWidth,
    num? srcHeight,
    num? dstX,
    num? dstY,
    num? dstWidth,
    num? dstHeight,
  ]) {
    if (srcWidth == null) {
      // In this case the numbers provided are the destination x and y offset.
      return _drawImage(source, srcxOrDstX, srcyOrDstY);
    } else {
      assert(
        srcHeight != null && dstX != null && dstY != null && dstWidth != null && dstHeight != null,
      );
      return _drawImage(
        source,
        srcxOrDstX,
        srcyOrDstY,
        srcWidth,
        srcHeight!,
        dstX!,
        dstY!,
        dstWidth!,
        dstHeight!,
      );
    }
  }

  @JS('fill')
  external void _fill([JSAny pathOrWinding]);
  void fill([Object? pathOrWinding]) {
    if (pathOrWinding == null) {
      _fill();
    } else {
      _fill(pathOrWinding.toJSAnyShallow);
    }
  }

  external void fillRect(num x, num y, num width, num height);

  @JS('fillText')
  external void _fillText(String text, num x, num y, [num maxWidth]);
  void fillText(String text, num x, num y, [num? maxWidth]) {
    if (maxWidth == null) {
      _fillText(text, x, y);
    } else {
      _fillText(text, x, y, maxWidth);
    }
  }

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

  @JS('clip')
  external void _clip([JSAny pathOrWinding]);
  void clip([Object? pathOrWinding]) {
    if (pathOrWinding == null) {
      _clip();
    } else {
      _clip(pathOrWinding.toJSAnyShallow);
    }
  }

  external void scale(num x, num y);
  external void clearRect(num x, num y, num width, num height);
  external void translate(num x, num y);
  external void rotate(num angle);
  external void bezierCurveTo(num cp1x, num cp1y, num cp2x, num cp2y, num x, num y);
  external void quadraticCurveTo(num cpx, num cpy, num x, num y);
  external set globalCompositeOperation(String value);
  external set lineCap(String value);
  external set lineJoin(String value);
  external set shadowBlur(num value);

  @JS('arc')
  external void _arc(num x, num y, num radius, num startAngle, num endAngle, bool antiClockwise);
  void arc(num x, num y, num radius, num startAngle, num endAngle, [bool antiClockwise = false]) =>
      _arc(x, y, radius, startAngle, endAngle, antiClockwise);

  external set filter(String? value);
  external set shadowOffsetX(num? x);
  external set shadowOffsetY(num? y);
  external set shadowColor(String? value);
  external void ellipse(
    num x,
    num y,
    num radiusX,
    num radiusY,
    num rotation,
    num startAngle,
    num endAngle,
    bool? antiClockwise,
  );
  external void strokeText(String text, num x, num y);
  external set globalAlpha(num? value);
}

@JS('WebGLRenderingContext')
extension type DomWebGLRenderingContext._(JSObject _) implements JSObject {
  external bool isContextLost();
}

@JS('ImageBitmapRenderingContext')
extension type DomImageBitmapRenderingContext._(JSObject _) implements JSObject {
  external void transferFromImageBitmap(DomImageBitmap? bitmap);
}

@JS('ImageData')
extension type DomImageData._(JSObject _) implements JSObject {
  external DomImageData(JSAny? data, int sw, int sh);
  external DomImageData._empty(int sw, int sh);

  @JS('data')
  external JSUint8ClampedArray get _data;
  Uint8ClampedList get data => _data.toDart;
}

DomImageData createDomImageData(Object data, int sw, int sh) =>
    DomImageData(data.toJSAnyShallow, sw, sh);
DomImageData createBlankDomImageData(int sw, int sh) => DomImageData._empty(sw, sh);

@JS('ImageBitmap')
extension type DomImageBitmap._(JSObject _) implements DomCanvasImageSource {
  external int get width;
  external int get height;
  external void close();
}

@JS('CanvasPattern')
extension type DomCanvasPattern._(JSObject _) implements JSObject {}

@JS('CanvasGradient')
extension type DomCanvasGradient._(JSObject _) implements JSObject {
  external void addColorStop(num offset, String color);
}

@JS('XMLHttpRequestEventTarget')
extension type DomXMLHttpRequestEventTarget._(JSObject _) implements DomEventTarget {}

Future<DomResponse> rawHttpGet(String url) =>
    domWindow._fetch(url).toDart.then((JSAny? value) => value! as DomResponse);

typedef MockHttpFetchResponseFactory = Future<MockHttpFetchResponse?> Function(String url);

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
    final MockHttpFetchResponse? response = await mockHttpFetchResponseFactory!(url);
    if (response != null) {
      return response;
    }
  }
  try {
    final DomResponse domResponse = await rawHttpGet(url);
    return HttpFetchResponseImpl._(url, domResponse);
  } catch (requestError) {
    throw HttpFetchError(url, requestError: requestError);
  }
}

Future<DomResponse> _rawHttpPost(String url, String data) => domWindow
    ._fetch(
      url,
      <String, Object?>{
        'method': 'POST',
        'headers': <String, Object?>{'Content-Type': 'text/plain'},
        'body': data,
      }.toJSAnyDeep,
    )
    .toDart
    .then((JSAny? value) => value! as DomResponse);

/// Sends a [data] string as HTTP POST request to [url].
///
/// The web engine does not make POST requests in production code because it is
/// designed to be able to run web apps served from plain file servers, so this
/// is meant for tests only.
@visibleForTesting
Future<HttpFetchResponse> testOnlyHttpPost(String url, String data) async {
  try {
    final DomResponse domResponse = await _rawHttpPost(url, data);
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
  Future<void> read(HttpFetchReader<JSUint8Array> reader) {
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

  final DomResponse _domResponse;

  @override
  int get status => _domResponse.status;

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
  Future<void> read(HttpFetchReader<JSUint8Array> reader);

  /// Returns the data as a [ByteBuffer].
  Future<ByteBuffer> asByteBuffer();

  /// Returns the data parsed as JSON.
  Future<dynamic> json();

  /// Return the data as a string.
  Future<String> text();
}

class HttpFetchPayloadImpl implements HttpFetchPayload {
  HttpFetchPayloadImpl._(this._domResponse);

  final DomResponse _domResponse;

  @override
  Future<void> read(HttpFetchReader<JSUint8Array> callback) async {
    final DomReadableStream stream = _domResponse.body;
    final _DomStreamReader reader = stream._getReader();

    while (true) {
      final _DomStreamChunk chunk = await reader.read();
      if (chunk.done) {
        break;
      }
      callback(chunk.value! as JSUint8Array);
    }
  }

  /// Returns the data as a [ByteBuffer].
  @override
  Future<ByteBuffer> asByteBuffer() => _domResponse.arrayBuffer();

  /// Returns the data parsed as JSON.
  @override
  Future<dynamic> json() => _domResponse.json();

  /// Return the data as a string.
  @override
  Future<String> text() => _domResponse.text();
}

typedef MockOnRead = Future<void> Function<T>(HttpFetchReader<T> callback);

class MockHttpFetchPayload implements HttpFetchPayload {
  MockHttpFetchPayload({required ByteBuffer byteBuffer, int? chunkSize})
    : _byteBuffer = byteBuffer,
      _chunkSize = chunkSize ?? 64;

  final ByteBuffer _byteBuffer;
  final int _chunkSize;

  @override
  Future<void> read(HttpFetchReader<JSUint8Array> callback) async {
    final int totalLength = _byteBuffer.lengthInBytes;
    int currentIndex = 0;
    while (currentIndex < totalLength) {
      final int chunkSize = math.min(_chunkSize, totalLength - currentIndex);
      final Uint8List chunk = Uint8List.sublistView(
        _byteBuffer.asByteData(),
        currentIndex,
        currentIndex + chunkSize,
      );
      callback(chunk.toJS);
      currentIndex += chunkSize;
    }
  }

  @override
  Future<ByteBuffer> asByteBuffer() async => _byteBuffer;

  @override
  Future<dynamic> json() async => throw AssertionError('json not supported by mock');

  @override
  Future<String> text() async => throw AssertionError('text not supported by mock');
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
  HttpFetchNoPayloadError(this.url, {required this.status});

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
  HttpFetchError(this.url, {required this.requestError});

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

@JS('Response')
extension type DomResponse._(JSObject _) implements JSObject {
  external int get status;

  external DomHeaders get headers;

  external DomReadableStream get body;

  @JS('arrayBuffer')
  external JSPromise<JSAny?> _arrayBuffer();
  Future<ByteBuffer> arrayBuffer() =>
      _arrayBuffer().toDart.then((JSAny? value) => (value! as JSArrayBuffer).toDart);

  @JS('json')
  external JSPromise<JSAny?> _json();
  Future<Object?> json() => _json().toDart;

  @JS('text')
  external JSPromise<JSAny?> _text();
  Future<String> text() => _text().toDart.then((JSAny? value) => (value! as JSString).toDart);
}

@JS('Headers')
extension type DomHeaders._(JSObject _) implements JSObject {
  external String? get(String? headerName);
}

extension type DomReadableStream._(JSObject _) implements JSObject {
  @JS('getReader')
  external _DomStreamReader _getReader();
}

extension type _DomStreamReader._(JSObject _) implements JSObject {
  @JS('read')
  external JSPromise<JSAny?> _read();
  Future<_DomStreamChunk> read() =>
      _read().toDart.then((JSAny? value) => value! as _DomStreamChunk);
}

extension type _DomStreamChunk._(JSObject _) implements JSObject {
  external JSAny? get value;
  external bool get done;
}

@JS('CharacterData')
extension type DomCharacterData._(JSObject _) implements DomNode {}

@JS('Text')
extension type DomText._(JSObject _) implements DomCharacterData {}

DomText createDomText(String data) => domDocument.createTextNode(data);

@JS('TextMetrics')
extension type DomTextMetrics._(JSObject _) implements JSObject {
  external double? get width;
}

@JS('DOMException')
extension type DomException._(JSObject _) implements JSObject {
  static const String notSupported = 'NotSupportedError';

  external String get name;
}

@JS('DOMRectReadOnly')
extension type DomRectReadOnly._(JSObject _) implements JSObject {
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
  return DomRect(left, top, width, height);
}

@JS('DOMRect')
extension type DomRect._(JSObject _) implements DomRectReadOnly {
  external DomRect(num left, num top, num width, num height);
}

@JS('FontFace')
extension type DomFontFace._primary(JSObject _) implements JSObject {
  external DomFontFace._(String family, JSAny source, [JSAny descriptors]);

  @JS('load')
  external JSPromise<JSAny?> _load();
  Future<DomFontFace> load() => _load().toDart.then((JSAny? value) => value! as DomFontFace);

  external String? get family;
  external String? get weight;
  external String? get status;
}

DomFontFace createDomFontFace(String family, Object source, [Map<Object?, Object?>? descriptors]) {
  if (descriptors == null) {
    return DomFontFace._(family, source.toJSAnyShallow);
  } else {
    return DomFontFace._(family, source.toJSAnyShallow, descriptors.toJSAnyDeep);
  }
}

@JS('FontFaceSet')
extension type DomFontFaceSet._(JSObject _) implements DomEventTarget {
  external DomFontFaceSet? add(DomFontFace font);
  external void clear();

  @JS('forEach')
  external void _forEach(JSFunction callback);
  void forEach(DomFontFaceSetForEachCallback callback) => _forEach(callback.toJS);
}

typedef DomFontFaceSetForEachCallback =
    void Function(DomFontFace fontFace, DomFontFace fontFaceAgain, DomFontFaceSet set);

@JS('VisualViewport')
extension type DomVisualViewport._(JSObject _) implements DomEventTarget {
  external double? get height;
  external double? get width;
  external double? get scale;
}

@JS('HTMLTextAreaElement')
extension type DomHTMLTextAreaElement._(JSObject _) implements DomHTMLElement {
  external set value(String? value);
  external void select();
  external String get placeholder;
  external set placeholder(String? value);
  external String name;
  external String? get selectionDirection;
  external double? get selectionStart;
  external double? get selectionEnd;
  external set selectionStart(double? value);
  external set selectionEnd(double? value);
  external String? get value;

  @JS('setSelectionRange')
  external void _setSelectionRange(int start, int end, [String direction]);
  void setSelectionRange(int start, int end, [String? direction]) {
    if (direction == null) {
      _setSelectionRange(start, end);
    } else {
      _setSelectionRange(start, end, direction);
    }
  }
}

DomHTMLTextAreaElement createDomHTMLTextAreaElement() =>
    domDocument.createElement('textarea') as DomHTMLTextAreaElement;

@JS('Clipboard')
extension type DomClipboard._(JSObject _) implements DomEventTarget {
  @JS('readText')
  external JSPromise<JSAny?> _readText();
  Future<String> readText() =>
      _readText().toDart.then((JSAny? value) => (value! as JSString).toDart);

  @JS('writeText')
  external JSPromise<JSAny?> _writeText(String data);
  Future<dynamic> writeText(String data) => _writeText(data).toDart;
}

@JS('UIEvent')
extension type DomUIEvent._(JSObject _) implements DomEvent {}

@JS('KeyboardEvent')
extension type DomKeyboardEvent._(JSObject _) implements DomUIEvent {
  external DomKeyboardEvent(String type, [JSAny initDict]);

  external bool get altKey;
  external String? get code;
  external bool get ctrlKey;
  external String? get key;
  external double get keyCode;
  external double get location;
  external bool get metaKey;
  external bool? get repeat;

  // Safari injects synthetic keyboard events after auto-complete that don't
  // have a `shiftKey` attribute, so this property must be nullable.
  external bool? get shiftKey;
  external bool get isComposing;
  external bool getModifierState(String keyArg);
}

DomKeyboardEvent createDomKeyboardEvent(String type, [Map<dynamic, dynamic>? init]) {
  if (init == null) {
    return DomKeyboardEvent(type);
  } else {
    return DomKeyboardEvent(type, init.toJSAnyDeep);
  }
}

@JS('History')
extension type DomHistory._(JSObject _) implements JSObject {
  @JS('state')
  external JSAny? get _state;
  dynamic get state => _state?.toObjectDeep;

  @JS('go')
  external void _go([int delta]);
  void go([int? delta]) {
    if (delta == null) {
      _go();
    } else {
      _go(delta);
    }
  }

  @JS('pushState')
  external void _pushState(JSAny? data, String title, String? url);
  void pushState(Object? data, String title, String? url) =>
      _pushState(data?.toJSAnyDeep, title, url);

  @JS('replaceState')
  external void _replaceState(JSAny? data, String title, String? url);
  void replaceState(Object? data, String title, String? url) =>
      _replaceState(data?.toJSAnyDeep, title, url);
}

@JS('Location')
extension type DomLocation._(JSObject _) implements JSObject {
  external String? get pathname;
  external String? get search;
  external String get hash;
  external String get origin;
  external String get href;
}

@JS('PopStateEvent')
extension type DomPopStateEvent._(JSObject _) implements DomEvent {
  external DomPopStateEvent(String type, [JSAny initDict]);

  @JS('state')
  external JSAny? get _state;
  dynamic get state => _state?.toObjectDeep;
}

DomPopStateEvent createDomPopStateEvent(String type, Map<Object?, Object?>? eventInitDict) {
  if (eventInitDict == null) {
    return DomPopStateEvent(type);
  } else {
    return DomPopStateEvent(type, eventInitDict.toJSAnyDeep);
  }
}

@JS('URL')
extension type DomURL._(JSObject _) implements JSObject {
  external DomURL(String url, [String? base]);

  @JS('createObjectURL')
  external String _createObjectURL(JSAny object);
  String createObjectURL(Object object) => _createObjectURL(object.toJSAnyShallow);

  external void revokeObjectURL(String url);

  @JS('toString')
  external String toJSString();
}

DomURL createDomURL(String url, [String? base]) => base == null ? DomURL(url) : DomURL(url, base);

@JS('Blob')
extension type DomBlob._(JSObject _) implements JSObject {
  external DomBlob(JSArray<JSAny?> parts);

  external DomBlob.withOptions(JSArray<JSAny?> parts, JSAny options);

  external JSPromise<JSAny?> arrayBuffer();
}

DomBlob createDomBlob(List<Object?> parts, [Map<String, dynamic>? options]) {
  if (options == null) {
    return DomBlob(parts.toJSAnyShallow as JSArray<JSAny?>);
  } else {
    return DomBlob.withOptions(parts.toJSAnyShallow as JSArray<JSAny?>, options.toJSAnyDeep);
  }
}

typedef DomMutationCallback = void Function(JSArray<JSAny?> mutation, DomMutationObserver observer);

@JS('MutationObserver')
extension type DomMutationObserver._(JSObject _) implements JSObject {
  external DomMutationObserver(JSFunction callback);

  external void disconnect();

  @JS('observe')
  external void _observe(DomNode target, JSAny options);
  void observe(DomNode target, {bool? childList, bool? attributes, List<String>? attributeFilter}) {
    final Map<String, dynamic> options = <String, dynamic>{
      if (childList != null) 'childList': childList,
      if (attributes != null) 'attributes': attributes,
      if (attributeFilter != null) 'attributeFilter': attributeFilter,
    };
    return _observe(target, options.toJSAnyDeep);
  }
}

DomMutationObserver createDomMutationObserver(DomMutationCallback callback) =>
    DomMutationObserver(callback.toJS);

@JS()
extension type DomMutationRecord._(JSObject _) implements JSObject {
  @JS('addedNodes')
  external _DomList? get _addedNodes;
  Iterable<DomNode>? get addedNodes {
    final _DomList? list = _addedNodes;
    if (list == null) {
      return null;
    }
    return _createDomListWrapper<DomNode>(list);
  }

  @JS('removedNodes')
  external _DomList? get _removedNodes;
  Iterable<DomNode>? get removedNodes {
    final _DomList? list = _removedNodes;
    if (list == null) {
      return null;
    }
    return _createDomListWrapper<DomNode>(list);
  }

  external String? get attributeName;
  external String? get type;
}

@JS('MediaQueryList')
extension type DomMediaQueryList._(JSObject _) implements DomEventTarget {
  external bool get matches;
  external void addListener(DomEventListener? listener);
  external void removeListener(DomEventListener? listener);
}

@JS('MediaQueryListEvent')
extension type DomMediaQueryListEvent._(JSObject _) implements DomEvent {
  external bool? get matches;
}

@JS('Path2D')
extension type DomPath2D._(JSObject _) implements JSObject {
  external DomPath2D([JSAny path]);
}

DomPath2D createDomPath2D([Object? path]) {
  if (path == null) {
    return DomPath2D();
  } else {
    return DomPath2D(path.toJSAnyShallow);
  }
}

@JS('InputEvent')
extension type DomInputEvent._(JSObject _) implements DomUIEvent {
  external DomInputEvent(String type, [JSAny initDict]);
}

@JS('FocusEvent')
extension type DomFocusEvent._(JSObject _) implements DomUIEvent {
  external DomEventTarget? get relatedTarget;
}

@JS('MouseEvent')
extension type DomMouseEvent._(JSObject _) implements DomUIEvent {
  external DomMouseEvent(String type, [JSAny initDict]);

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
  external bool get ctrlKey;
  external bool getModifierState(String keyArg);
}

DomMouseEvent createDomMouseEvent(String type, [Map<dynamic, dynamic>? init]) {
  if (init == null) {
    return DomMouseEvent(type);
  } else {
    return DomMouseEvent(type, init.toJSAnyDeep);
  }
}

DomInputEvent createDomInputEvent(String type, [Map<dynamic, dynamic>? init]) {
  if (init == null) {
    return DomInputEvent(type);
  } else {
    return DomInputEvent(type, init.toJSAnyDeep);
  }
}

@JS('PointerEvent')
extension type DomPointerEvent._(JSObject _) implements DomMouseEvent {
  external DomPointerEvent(String type, [JSAny initDict]);

  external double? get pointerId;
  external String? get pointerType;
  external double? get pressure;
  external double? get tiltX;
  external double? get tiltY;

  @JS('getCoalescedEvents')
  external JSArray<JSAny?> _getCoalescedEvents();
  List<DomPointerEvent> getCoalescedEvents() =>
      _getCoalescedEvents().toDart.cast<DomPointerEvent>();
}

DomPointerEvent createDomPointerEvent(String type, [Map<dynamic, dynamic>? init]) {
  if (init == null) {
    return DomPointerEvent(type);
  } else {
    return DomPointerEvent(type, init.toJSAnyDeep);
  }
}

@JS('WheelEvent')
extension type DomWheelEvent._(JSObject _) implements DomMouseEvent {
  external DomWheelEvent(String type, [JSAny initDict]);

  external double get deltaX;
  external double get deltaY;
  external double? get wheelDeltaX;
  external double? get wheelDeltaY;
  external double get deltaMode;
}

DomWheelEvent createDomWheelEvent(String type, [Map<dynamic, dynamic>? init]) {
  if (init == null) {
    return DomWheelEvent(type);
  } else {
    return DomWheelEvent(type, init.toJSAnyDeep);
  }
}

@JS('TouchEvent')
extension type DomTouchEvent._(JSObject _) implements DomUIEvent {
  external DomTouchEvent(String type, [JSAny initDict]);

  external bool get altKey;
  external bool get ctrlKey;
  external bool get metaKey;
  external bool get shiftKey;

  @JS('changedTouches')
  external _DomList get _changedTouches;
  Iterable<DomTouch> get changedTouches => _createDomListWrapper<DomTouch>(_changedTouches);
}

@JS('Touch')
extension type DomTouch._(JSObject _) implements JSObject {
  external DomTouch([JSAny initDict]);

  external double? get identifier;
  external double get clientX;
  external double get clientY;

  DomPoint get client => DomPoint(clientX, clientY);
}

DomTouch createDomTouch([Map<dynamic, dynamic>? init]) {
  if (init == null) {
    return DomTouch();
  } else {
    return DomTouch(init.toJSAnyDeep);
  }
}

@JS('CompositionEvent')
extension type DomCompositionEvent._(JSObject _) implements DomUIEvent {
  external DomCompositionEvent(String type, [JSAny initDict]);

  external String? get data;
}

DomCompositionEvent createDomCompositionEvent(String type, [Map<dynamic, dynamic>? options]) {
  if (options == null) {
    return DomCompositionEvent(type);
  } else {
    return DomCompositionEvent(type, options.toJSAnyDeep);
  }
}

/// This is a pseudo-type for DOM elements that have the boolean `disabled`
/// property.
///
/// This type cannot be part of the actual type hierarchy because each DOM type
/// defines its `disabled` property ad hoc, without inheriting it from a common
/// type, e.g. [DomHTMLInputElement] and [DomHTMLTextAreaElement].
///
/// To use, simply cast any element known to have the `disabled` property to
/// this type using `as DomElementWithDisabledProperty`, then read and write
/// this property as normal.
extension type DomElementWithDisabledProperty._(JSObject _) implements DomHTMLElement {
  external bool? disabled;
}

@JS('HTMLInputElement')
extension type DomHTMLInputElement._(JSObject _) implements DomHTMLElement {
  external String? type;
  external set max(String? value);
  external set min(String value);
  external String? value;
  external bool? disabled;
  external String placeholder;
  external String? name;
  external String autocomplete;
  external String? get selectionDirection;
  external double? selectionStart;
  external double? selectionEnd;

  @JS('setSelectionRange')
  external void _setSelectionRange(int start, int end, [String direction]);
  void setSelectionRange(int start, int end, [String? direction]) {
    if (direction == null) {
      _setSelectionRange(start, end);
    } else {
      _setSelectionRange(start, end, direction);
    }
  }
}

DomHTMLInputElement createDomHTMLInputElement() =>
    domDocument.createElement('input') as DomHTMLInputElement;

@JS('DOMTokenList')
extension type DomTokenList._(JSObject _) implements JSObject {
  external void add(String value);
  external void remove(String value);
  external bool contains(String token);
}

@JS('HTMLFormElement')
extension type DomHTMLFormElement._(JSObject _) implements DomHTMLElement {
  external set noValidate(bool? value);
  external set method(String? value);
  external set action(String? value);
}

DomHTMLFormElement createDomHTMLFormElement() =>
    domDocument.createElement('form') as DomHTMLFormElement;

@JS('HTMLLabelElement')
extension type DomHTMLLabelElement._(JSObject _) implements DomHTMLElement {}

DomHTMLLabelElement createDomHTMLLabelElement() =>
    domDocument.createElement('label') as DomHTMLLabelElement;

@JS('OffscreenCanvas')
extension type DomOffscreenCanvas._(JSObject _) implements DomEventTarget {
  external DomOffscreenCanvas(int width, int height);

  external double? height;
  external double? width;

  @JS('getContext')
  external JSAny? _getContext(String contextType, [JSAny attributes]);
  Object? getContext(String contextType, [Map<dynamic, dynamic>? attributes]) {
    if (attributes == null) {
      return _getContext(contextType);
    } else {
      return _getContext(contextType, attributes.toJSAnyDeep);
    }
  }

  WebGLContext getGlContext(int majorVersion) {
    if (majorVersion == 1) {
      return getContext('webgl')! as WebGLContext;
    }
    return getContext('webgl2')! as WebGLContext;
  }

  @JS('convertToBlob')
  external JSPromise<JSAny?> _convertToBlob([JSAny options]);
  Future<DomBlob> convertToBlob([Map<Object?, Object?>? options]) {
    final JSPromise<JSAny?> blob;
    if (options == null) {
      blob = _convertToBlob();
    } else {
      blob = _convertToBlob(options.toJSAnyDeep);
    }
    return blob.toDart.then((JSAny? value) => value! as DomBlob);
  }

  external DomImageBitmap transferToImageBitmap();
}

DomOffscreenCanvas createDomOffscreenCanvas(int width, int height) =>
    DomOffscreenCanvas(width, height);

@JS('FileReader')
extension type DomFileReader._(JSObject _) implements DomEventTarget {
  external DomFileReader();

  external void readAsDataURL(DomBlob blob);
}

DomFileReader createDomFileReader() => DomFileReader();

@JS('DocumentFragment')
extension type DomDocumentFragment._(JSObject _) implements DomNode {
  external DomElement? get firstElementChild;
  external DomElement? get lastElementChild;

  external void prepend(DomNode node);
  external DomElement? querySelector(String selectors);

  @JS('querySelectorAll')
  external _DomList _querySelectorAll(String selectors);
  Iterable<DomElement> querySelectorAll(String selectors) =>
      _createDomListWrapper<DomElement>(_querySelectorAll(selectors));
}

@JS('ShadowRoot')
extension type DomShadowRoot._(JSObject _) implements DomDocumentFragment {
  external DomElement? get activeElement;
  external DomElement? get host;
  external String? get mode;
  external bool? get delegatesFocus;
  external DomElement? elementFromPoint(int x, int y);
}

@JS('StyleSheet')
extension type DomStyleSheet._(JSObject _) implements JSObject {}

@JS('CSSStyleSheet')
extension type DomCSSStyleSheet._(JSObject _) implements DomStyleSheet {
  @JS('cssRules')
  external _DomList get _cssRules;
  Iterable<DomCSSRule> get cssRules => _createDomListWrapper<DomCSSRule>(_cssRules);

  @JS('insertRule')
  external double _insertRule(String rule, [int index]);
  double insertRule(String rule, [int? index]) {
    if (index == null) {
      return _insertRule(rule);
    } else {
      return _insertRule(rule, index);
    }
  }
}

@JS('CSSRule')
extension type DomCSSRule._(JSObject _) implements JSObject {
  external String get cssText;
}

@JS('Screen')
extension type DomScreen._(JSObject _) implements JSObject {
  external DomScreenOrientation? get orientation;

  external double get width;
  external double get height;
}

@JS('ScreenOrientation')
extension type DomScreenOrientation._(JSObject _) implements DomEventTarget {
  @JS('lock')
  external JSPromise<JSAny?> _lock(String orientation);
  Future<dynamic> lock(String orientation) => _lock(orientation).toDart;

  external void unlock();
}

// A helper class for managing a subscription. On construction it will add an
// event listener of the requested type to the target. Calling [cancel] will
// remove the listener.
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

@JS('WebSocket')
extension type DomWebSocket._(JSObject _) implements DomEventTarget {
  external DomWebSocket(String url);

  @JS('send')
  external void _send(JSAny? data);
  void send(Object? data) => _send(data?.toJSAnyShallow);
}

DomWebSocket createDomWebSocket(String url) => DomWebSocket(url);

@JS('MessageEvent')
extension type DomMessageEvent._(JSObject _) implements DomEvent {
  @JS('data')
  external JSAny? get _data;
  dynamic get data => _data?.toObjectDeep;

  external String get origin;

  /// The source may be a `WindowProxy`, a `MessagePort`, or a `ServiceWorker`.
  ///
  /// When a message is sent from an iframe through `window.parent.postMessage`
  /// the source will be a `WindowProxy` which has the same methods as [Window].
  external JSAny? get source;

  external JSArray<DomMessagePort> get ports;
}

// This is typed as JSAny? since it may come from a cross-origin iframe.
extension type DomMessageEventSource._(JSAny? _) {
  external JSAny? get location;
}

// This is typed as JSAny? since it may come from a cross-origin iframe.
extension type DomMessageEventLocation._(JSAny? _) {
  external String? get href;
}

@JS('HTMLIFrameElement')
extension type DomHTMLIFrameElement._(JSObject _) implements DomHTMLElement {
  external String? src;
  external set height(String? value);
  external set width(String? value);
  external DomWindow get contentWindow;
}

DomHTMLIFrameElement createDomHTMLIFrameElement() =>
    domDocument.createElement('iframe') as DomHTMLIFrameElement;

@JS('MessagePort')
extension type DomMessagePort._(JSObject _) implements DomEventTarget {
  @JS('postMessage')
  external void _postMessage(JSAny? message);
  void postMessage(Object? message) => _postMessage(message?.toJSAnyDeep);

  external void start();
}

@JS('MessageChannel')
extension type DomMessageChannel._(JSObject _) implements JSObject {
  external DomMessageChannel();

  external DomMessagePort get port1;
  external DomMessagePort get port2;
}

/// ResizeObserver JS binding.
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/ResizeObserver
@JS('ResizeObserver')
extension type DomResizeObserver._(JSObject _) implements JSObject {
  external DomResizeObserver(JSFunction observer);

  external void disconnect();
  external void observe(DomElement target, [DomResizeObserverObserveOptions options]);
  external void unobserve(DomElement target);
}

/// Creates a DomResizeObserver with a callback.
///
/// Internally converts the `List<dynamic>` of entries into the expected
/// `List<DomResizeObserverEntry>`
DomResizeObserver? createDomResizeObserver(DomResizeObserverCallbackFn fn) => DomResizeObserver(
  (JSArray<JSAny?> entries, DomResizeObserver observer) {
    fn(entries.toDart.cast<DomResizeObserverEntry>(), observer);
  }.toJS,
);

/// Options object passed to the `observe` method of a [DomResizeObserver].
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/ResizeObserver/observe#parameters
extension type DomResizeObserverObserveOptions._(JSObject _) implements JSObject {
  external DomResizeObserverObserveOptions({String box});
}

/// Type of the function used to create a Resize Observer.
typedef DomResizeObserverCallbackFn =
    void Function(List<DomResizeObserverEntry> entries, DomResizeObserver observer);

/// The object passed to the [DomResizeObserverCallbackFn], which allows access to the new dimensions of the observed element.
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/ResizeObserverEntry
@JS('ResizeObserverEntry')
extension type DomResizeObserverEntry._(JSObject _) implements JSObject {
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
@JS('TrustedTypePolicyFactory')
extension type DomTrustedTypePolicyFactory._(JSObject _) implements JSObject {
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
extension type DomTrustedTypePolicyOptions._(JSObject _) implements JSObject {
  /// Constructs a TrustedTypePolicyOptions object in JavaScript.
  ///
  /// `createScriptURL` is a callback function that contains code to run when
  /// creating a TrustedScriptURL object.
  external DomTrustedTypePolicyOptions({JSFunction? createScriptURL});
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
@JS('TrustedTypePolicy')
extension type DomTrustedTypePolicy._(JSObject _) implements JSObject {
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
@JS('TrustedScriptURL')
extension type DomTrustedScriptURL._(JSObject _) implements JSObject {
  /// Exposes the `toString` JS method of TrustedScriptURL.
  @JS('toString')
  external String _toString();
  String get url => _toString();
}

// The expected set of files that the flutter-engine TrustedType policy is going
// to accept as valid.
const Set<String> _expectedFilesForTT = <String>{'canvaskit.js'};

// The definition of the `flutter-engine` TrustedType policy.
// Only accessible if the Trusted Types API is available.
final DomTrustedTypePolicy _ttPolicy = domWindow.trustedTypes!.createPolicy(
  'flutter-engine',
  DomTrustedTypePolicyOptions(
    // Validates the given [url].
    createScriptURL:
        (String url) {
          final Uri uri = Uri.parse(url);
          if (_expectedFilesForTT.contains(uri.pathSegments.last)) {
            return uri.toString().toJS;
          }
          domWindow.console.error(
            'URL rejected by TrustedTypes policy flutter-engine: $url'
            '(download prevented)',
          );

          return null;
        }.toJS,
  ),
);

/// Converts a String `url` into a [DomTrustedScriptURL] object when the
/// Trusted Types API is available, else returns the unmodified `url`.
JSAny createTrustedScriptUrl(String url) {
  if (domWindow.trustedTypes != null) {
    // Pass `url` through Flutter Engine's TrustedType policy.
    final DomTrustedScriptURL trustedUrl = _ttPolicy.createScriptURL(url);

    assert(trustedUrl.url != '', 'URL: $url rejected by TrustedTypePolicy');

    return trustedUrl as JSAny;
  }
  return url.toJS;
}

DomMessageChannel createDomMessageChannel() => DomMessageChannel();

bool domInstanceOfString(JSAny element, String objectType) => element.instanceOfString(objectType);

/// This is the shared interface for APIs that return either
/// `NodeList` or `HTMLCollection`. Do *not* add any API to this class that
/// isn't support by both JS objects. Furthermore, this is an internal class and
/// should only be returned as a wrapped object to Dart.
extension type _DomList._(JSObject _) implements JSObject {
  external double get length;
  external JSObject item(int index);
}

class _DomListIterator<T extends JSObject> implements Iterator<T> {
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

class _DomListWrapper<T extends JSObject> extends Iterable<T> {
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
Iterable<T> _createDomListWrapper<T extends JSObject>(_DomList list) => _DomListWrapper<T>._(list);

@JS('Symbol')
extension type DomSymbol._(JSObject _) implements JSObject {
  external JSAny get iterator;
}

@JS('Intl')
extension type DomIntl._(JSObject _) implements JSObject {
  // ignore: non_constant_identifier_names
  external JSAny? get Segmenter;

  /// This is a V8-only API for segmenting text.
  ///
  /// See: https://code.google.com/archive/p/v8-i18n/wikis/BreakIterator.wiki
  external JSAny? get v8BreakIterator;
}

@JS('Intl.Segmenter')
// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Segmenter
extension type DomSegmenter._(JSObject _) implements JSObject {
  // TODO(joshualitt): `locales` should really be typed as `JSAny?`, and we
  // should pass `JSUndefined`.  Revisit this after we reify `JSUndefined` on
  // Dart2Wasm.
  external DomSegmenter(JSArray<JSAny?> locales, JSAny options);

  @JS('segment')
  external DomSegments segmentRaw(JSString text);
  external DomSegments segment(String text);
}

// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Segmenter/segment/Segments
@JS('Segments')
extension type DomSegments._(JSObject _) implements JSObject {
  DomIteratorWrapper<DomSegment> iterator() {
    final DomIterator segmentIterator = callMethod(domSymbol.iterator)! as DomIterator;
    return DomIteratorWrapper<DomSegment>(segmentIterator);
  }
}

// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Iteration_protocols
@JS('Iterator')
extension type DomIterator._(JSObject _) implements JSObject {
  external DomIteratorResult next();
}

extension type DomIteratorResult._(JSObject _) implements JSObject {
  external bool get done;
  external JSAny get value;
}

/// Wraps a native JS iterator to provide a Dart [Iterator].
class DomIteratorWrapper<T extends JSAny> implements Iterator<T> {
  DomIteratorWrapper(this._iterator);

  final DomIterator _iterator;
  late T _current;

  @override
  T get current => _current;

  @override
  bool moveNext() {
    final DomIteratorResult result = _iterator.next();
    if (result.done) {
      return false;
    }
    _current = result.value as T;
    return true;
  }
}

extension type DomSegment._(JSObject _) implements JSObject {
  external int get index;
  external bool get isWordLike;
  external String get segment;
  external String get breakType;
}

DomSegmenter createIntlSegmenter({required String granularity}) {
  if (domIntl.Segmenter == null) {
    throw UnimplementedError('Intl.Segmenter() is not supported.');
  }

  return DomSegmenter(<JSAny?>[].toJS, <String, String>{'granularity': granularity}.toJSAnyDeep);
}

@JS('Intl.v8BreakIterator')
extension type DomV8BreakIterator._(JSObject _) implements JSObject {
  external DomV8BreakIterator(JSArray<JSAny?> locales, JSAny options);

  external void adoptText(JSString text);
  external double first();
  external double next();
  external double current();
  external String breakType();
}

DomV8BreakIterator createV8BreakIterator() {
  if (domIntl.v8BreakIterator == null) {
    throw UnimplementedError('v8BreakIterator is not supported.');
  }

  return DomV8BreakIterator(<JSAny?>[].toJS, const <String, String>{'type': 'line'}.toJSAnyDeep);
}

@JS('TextDecoder')
extension type DomTextDecoder._(JSObject _) implements JSObject {
  external DomTextDecoder();

  external JSString decode(JSTypedArray buffer);
}

@JS('window.FinalizationRegistry')
extension type DomFinalizationRegistry._(JSObject _) implements JSObject {
  external DomFinalizationRegistry(JSFunction cleanup);

  external void register(ExternalDartReference target, ExternalDartReference value);

  @JS('register')
  external void registerWithToken(
    ExternalDartReference target,
    ExternalDartReference value,
    ExternalDartReference token,
  );

  external void unregister(ExternalDartReference token);
}

@JS('window.FinalizationRegistry')
external JSAny? get _finalizationRegistryConstructor;

/// Whether the current browser supports `FinalizationRegistry`.
bool browserSupportsFinalizationRegistry = _finalizationRegistryConstructor != null;

@JS('window.OffscreenCanvas')
external JSAny? get _offscreenCanvasConstructor;

bool browserSupportsOffscreenCanvas = _offscreenCanvasConstructor != null;

@JS('window.createImageBitmap')
external JSAny? get _createImageBitmapFunction;

/// Set to `true` to disable `createImageBitmap` support. Used in tests.
bool debugDisableCreateImageBitmapSupport = false;

bool get browserSupportsCreateImageBitmap =>
    _createImageBitmapFunction != null &&
    !isChrome110OrOlder &&
    !debugDisableCreateImageBitmapSupport;

extension JSArrayExtension on JSArray<JSAny?> {
  external void push(JSAny value);
  // TODO(srujzs): Delete this when we add `JSArray.length` in the SDK.
  external int get length;
}
