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

extension type DomWindow._(JSObject _) implements DomEventTarget, JSObject {
  external DomConsole get console;

  @JS('devicePixelRatio')
  external JSNumber get _devicePixelRatio;
  double get devicePixelRatio => _devicePixelRatio.toDartDouble;

  external DomDocument get document;
  external DomHistory get history;

  @JS('innerHeight')
  external JSNumber? get _innerHeight;
  double? get innerHeight => _innerHeight?.toDartDouble;

  @JS('innerWidth')
  external JSNumber? get _innerWidth;
  double? get innerWidth => _innerWidth?.toDartDouble;

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
  external JSPromise<JSAny?> _fetch(JSString url, [JSAny headers]);

  // ignore: non_constant_identifier_names
  external DomURL get URL;

  @JS('dispatchEvent')
  @redeclare
  external JSBoolean _dispatchEvent(DomEvent event);
  @redeclare
  bool dispatchEvent(DomEvent event) => _dispatchEvent(event).toDart;

  @JS('matchMedia')
  external DomMediaQueryList _matchMedia(JSString? query);
  DomMediaQueryList matchMedia(String? query) => _matchMedia(query?.toJS);

  @JS('getComputedStyle')
  external DomCSSStyleDeclaration _getComputedStyle(DomElement elt, [JSString pseudoElt]);
  DomCSSStyleDeclaration getComputedStyle(DomElement elt, [String? pseudoElt]) {
    if (pseudoElt == null) {
      return _getComputedStyle(elt);
    } else {
      return _getComputedStyle(elt, pseudoElt.toJS);
    }
  }

  external DomScreen? get screen;

  JSFunction _makeAnimationFrameCallbackZoned(DomRequestAnimationFrameCallback callback) {
    final ZoneUnaryCallback<void, JSNumber> zonedCallback = Zone.current
        .bindUnaryCallback<void, JSNumber>(callback);
    return zonedCallback.toJS;
  }

  @JS('requestAnimationFrame')
  external JSNumber _requestAnimationFrame(JSFunction callback);
  double requestAnimationFrame(DomRequestAnimationFrameCallback callback) =>
      _requestAnimationFrame(_makeAnimationFrameCallbackZoned(callback)).toDartDouble;

  @JS('postMessage')
  external void _postMessage(JSAny message, JSString targetOrigin, [JSArray<JSAny?> messagePorts]);
  void postMessage(Object message, String targetOrigin, [List<DomMessagePort>? messagePorts]) {
    if (messagePorts == null) {
      _postMessage(message.toJSAnyShallow, targetOrigin.toJS);
    } else {
      _postMessage(
        message.toJSAnyShallow,
        targetOrigin.toJS,
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
  external void _warn(JSString? arg);
  void warn(Object? arg) => _warn(arg.toString().toJS);

  @JS('error')
  external void _error(JSString? arg);
  void error(Object? arg) => _error(arg.toString().toJS);

  @JS('debug')
  external void _debug(JSString? arg);
  void debug(Object? arg) => _debug(arg.toString().toJS);
}

@JS('window')
external DomWindow get domWindow;

@JS('Intl')
external DomIntl get domIntl;

@JS('Symbol')
external DomSymbol get domSymbol;

@JS('createImageBitmap')
external JSPromise<JSAny?> _createImageBitmap(
  JSAny source, [
  JSNumber x,
  JSNumber y,
  JSNumber width,
  JSNumber height,
]);
Future<DomImageBitmap> createImageBitmap(
  JSAny source, [
  ({int x, int y, int width, int height})? bounds,
]) {
  JSPromise<JSAny?> jsPromise;
  if (bounds != null) {
    jsPromise = _createImageBitmap(
      source,
      bounds.x.toJS,
      bounds.y.toJS,
      bounds.width.toJS,
      bounds.height.toJS,
    );
  } else {
    jsPromise = _createImageBitmap(source);
  }
  return jsPromise.toDart.then((JSAny? value) => value! as DomImageBitmap);
}

extension type DomNavigator._(JSObject _) implements JSObject {
  external DomClipboard? get clipboard;

  @JS('maxTouchPoints')
  external JSNumber? get _maxTouchPoints;
  double? get maxTouchPoints => _maxTouchPoints?.toDartDouble;

  @JS('vendor')
  external JSString get _vendor;
  String get vendor => _vendor.toDart;

  @JS('language')
  external JSString get _language;
  String get language => _language.toDart;

  @JS('platform')
  external JSString? get _platform;
  String? get platform => _platform?.toDart;

  @JS('userAgent')
  external JSString get _userAgent;
  String get userAgent => _userAgent.toDart;

  @JS('languages')
  external JSArray<JSAny?>? get _languages;
  List<String>? get languages =>
      _languages?.toDart.map<String>((JSAny? any) => (any! as JSString).toDart).toList();
}

extension type DomDocument._(JSObject _) implements JSObject, DomNode {
  external DomElement? get documentElement;

  @JS('querySelector')
  external DomElement? _querySelector(JSString selectors);
  DomElement? querySelector(String selectors) => _querySelector(selectors.toJS);

  @JS('querySelectorAll')
  external _DomList _querySelectorAll(JSString selectors);
  Iterable<DomElement> querySelectorAll(String selectors) =>
      createDomListWrapper<DomElement>(_querySelectorAll(selectors.toJS));

  @JS('createElement')
  external DomElement _createElement(JSString name, [JSAny? options]);
  DomElement createElement(String name, [Object? options]) {
    if (options == null) {
      return _createElement(name.toJS);
    } else {
      return _createElement(name.toJS, options.toJSAnyDeep);
    }
  }

  @JS('execCommand')
  external JSBoolean _execCommand(JSString commandId);
  bool execCommand(String commandId) => _execCommand(commandId.toJS).toDart;

  external DomHTMLScriptElement? get currentScript;

  @JS('createElementNS')
  external DomElement _createElementNS(JSString namespaceURI, JSString qualifiedName);
  DomElement createElementNS(String namespaceURI, String qualifiedName) =>
      _createElementNS(namespaceURI.toJS, qualifiedName.toJS);

  @JS('createTextNode')
  external DomText _createTextNode(JSString data);
  DomText createTextNode(String data) => _createTextNode(data.toJS);

  @JS('createEvent')
  external DomEvent _createEvent(JSString eventType);
  DomEvent createEvent(String eventType) => _createEvent(eventType.toJS);

  external DomElement? get activeElement;

  @JS('elementFromPoint')
  external DomElement? _elementFromPoint(JSNumber x, JSNumber y);
  DomElement? elementFromPoint(int x, int y) => _elementFromPoint(x.toJS, y.toJS);
}

extension type DomHTMLDocument._(JSObject _) implements JSObject, DomDocument {
  external DomFontFaceSet? get fonts;
  external DomHTMLHeadElement? get head;
  external DomHTMLBodyElement? get body;

  @JS('title')
  external set _title(JSString? value);
  set title(String? value) => _title = value?.toJS;

  @JS('title')
  external JSString? get _title;
  String? get title => _title?.toDart;

  @JS('getElementsByTagName')
  external _DomList _getElementsByTagName(JSString tag);
  Iterable<DomElement> getElementsByTagName(String tag) =>
      createDomListWrapper<DomElement>(_getElementsByTagName(tag.toJS));

  @redeclare
  external DomElement? get activeElement;

  @JS('getElementById')
  external DomElement? _getElementById(JSString id);
  DomElement? getElementById(String id) => _getElementById(id.toJS);

  @JS('visibilityState')
  external JSString get _visibilityState;
  String get visibilityState => _visibilityState.toDart;

  @JS('hasFocus')
  external JSBoolean _hasFocus();
  bool hasFocus() => _hasFocus().toDart;
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

  external bool get capture;
  external set capture(bool value);

  external bool get passive;
  external set passive(bool value);

  external bool get once;
  external set once(bool value);
}

typedef DartDomEventListener = void Function(DomEvent event);
typedef DomEventListener = JSFunction;

extension type DomEvent._(JSObject _) implements JSObject {
  external DomEventTarget? get target;
  external DomEventTarget? get currentTarget;

  @JS('timeStamp')
  external JSNumber? get _timeStamp;
  double? get timeStamp => _timeStamp?.toDartDouble;

  @JS('type')
  external JSString get _type;
  String get type => _type.toDart;

  external JSBoolean? get _cancelable;
  bool get cancelable => _cancelable?.toDart ?? true;

  external void preventDefault();
  external void stopPropagation();

  @JS('initEvent')
  external void _initEvent(JSString type, [JSBoolean bubbles, JSBoolean cancelable]);
  void initEvent(String type, [bool? bubbles, bool? cancelable]) {
    if (bubbles == null) {
      _initEvent(type.toJS);
    } else if (cancelable == null) {
      _initEvent(type.toJS, bubbles.toJS);
    } else {
      _initEvent(type.toJS, bubbles.toJS, cancelable.toJS);
    }
  }

  @JS('defaultPrevented')
  external JSBoolean get _defaultPrevented;
  bool get defaultPrevented => _defaultPrevented.toDart;
}

DomEvent createDomEvent(String type, String name) {
  final DomEvent event = domDocument.createEvent(type);
  event.initEvent(name, true, true);
  return event;
}

@JS('ProgressEvent')
extension type DomProgressEvent._(JSObject _) implements JSObject, DomEvent {
  @JS('loaded')
  external JSNumber? get _loaded;
  double? get loaded => _loaded?.toDartDouble;

  @JS('total')
  external JSNumber? get _total;
  double? get total => _total?.toDartDouble;
}

extension type DomNode._(JSObject _) implements DomEventTarget, JSObject {
  @JS('baseURI')
  external JSString? get _baseUri;
  String? get baseUri => _baseUri?.toDart;

  external DomNode? get firstChild;

  @JS('innerText')
  external JSString get _innerText;
  String get innerText => _innerText.toDart;

  @JS('innerText')
  external set _innerText(JSString text);
  set innerText(String text) => _innerText = text.toJS;

  external DomNode? get lastChild;
  external DomNode appendChild(DomNode node);

  @JS('parentElement')
  external DomElement? get parentElement;
  DomElement? get parent => parentElement;

  @JS('textContent')
  external JSString? get _textContent;
  String? get text => _textContent?.toDart;

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

  @JS('isConnected')
  external JSBoolean? get _isConnected;
  bool? get isConnected => _isConnected?.toDart;

  @JS('textContent')
  external set _textContent(JSString? value);
  set text(String? value) => _textContent = value?.toJS;

  @JS('cloneNode')
  external DomNode _cloneNode(JSBoolean? deep);
  DomNode cloneNode(bool? deep) => _cloneNode(deep?.toJS);

  @JS('contains')
  external JSBoolean _contains(DomNode? other);
  bool contains(DomNode? other) => _contains(other).toDart;

  external void append(DomNode node);

  @JS('childNodes')
  external _DomList get _childNodes;
  Iterable<DomNode> get childNodes => createDomListWrapper<DomElement>(_childNodes);

  external DomDocument? get ownerDocument;
  void clearChildren() {
    while (firstChild != null) {
      removeChild(firstChild!);
    }
  }
}

extension type DomElement._(JSObject _) implements JSObject, DomNode {
  @JS('children')
  external _DomList get _children;
  Iterable<DomElement> get children => createDomListWrapper<DomElement>(_children);

  external DomElement? get firstElementChild;
  external DomElement? get lastElementChild;

  external DomElement? get nextElementSibling;

  @JS('clientHeight')
  external JSNumber get _clientHeight;
  double get clientHeight => _clientHeight.toDartDouble;

  @JS('clientWidth')
  external JSNumber get _clientWidth;
  double get clientWidth => _clientWidth.toDartDouble;

  @JS('offsetHeight')
  external JSNumber get _offsetHeight;
  double get offsetHeight => _offsetHeight.toDartDouble;

  @JS('offsetWidth')
  external JSNumber get _offsetWidth;
  double get offsetWidth => _offsetWidth.toDartDouble;

  @JS('id')
  external JSString get _id;
  String get id => _id.toDart;

  @JS('id')
  external set _id(JSString id);
  set id(String id) => _id = id.toJS;

  @JS('innerHTML')
  external set _innerHTML(JSString? html);
  set innerHTML(String? html) => _innerHTML = html?.toJS;

  @JS('outerHTML')
  external JSString? get _outerHTML;
  String? get outerHTML => _outerHTML?.toDart;

  @JS('spellcheck')
  external set _spellcheck(JSBoolean? value);
  set spellcheck(bool? value) => _spellcheck = value?.toJS;

  @JS('tagName')
  external JSString get _tagName;
  String get tagName => _tagName.toDart;

  external DomCSSStyleDeclaration get style;
  @redeclare
  external void append(DomNode node);

  @JS('getAttribute')
  external JSString? _getAttribute(JSString attributeName);
  String? getAttribute(String attributeName) => _getAttribute(attributeName.toJS)?.toDart;

  external DomRect getBoundingClientRect();
  external void prepend(DomNode node);

  @JS('querySelector')
  external DomElement? _querySelector(JSString selectors);
  DomElement? querySelector(String selectors) => _querySelector(selectors.toJS);

  @JS('closest')
  external DomElement? _closest(JSString selectors);
  DomElement? closest(String selectors) => _closest(selectors.toJS);

  @JS('matches')
  external JSBoolean _matches(JSString selectors);
  bool matches(String selectors) => _matches(selectors.toJS).toDart;

  @JS('querySelectorAll')
  external _DomList _querySelectorAll(JSString selectors);
  Iterable<DomElement> querySelectorAll(String selectors) =>
      createDomListWrapper<DomElement>(_querySelectorAll(selectors.toJS));

  @redeclare
  external void remove();

  @JS('setAttribute')
  external void _setAttribute(JSString name, JSAny value);
  void setAttribute(String name, Object value) => _setAttribute(name.toJS, value.toJSAnyDeep);

  void appendText(String text) => append(createDomText(text));

  @JS('removeAttribute')
  external void _removeAttribute(JSString name);
  void removeAttribute(String name) => _removeAttribute(name.toJS);

  @JS('tabIndex')
  external set _tabIndex(JSNumber? value);
  set tabIndex(double? value) => _tabIndex = value?.toJS;

  @JS('tabIndex')
  external JSNumber? get _tabIndex;
  double? get tabIndex => _tabIndex?.toDartDouble;

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

  @JS('scrollTop')
  external JSNumber get _scrollTop;
  double get scrollTop => _scrollTop.toDartDouble;

  @JS('scrollTop')
  external set _scrollTop(JSNumber value);
  set scrollTop(double value) => _scrollTop = value.toJS;

  @JS('scrollLeft')
  external JSNumber get _scrollLeft;
  double get scrollLeft => _scrollLeft.toDartDouble;

  @JS('scrollLeft')
  external set _scrollLeft(JSNumber value);
  set scrollLeft(double value) => _scrollLeft = value.toJS;

  external DomTokenList get classList;

  @JS('className')
  external set _className(JSString value);
  set className(String value) => _className = value.toJS;

  @JS('className')
  external JSString get _className;
  String get className => _className.toDart;

  external void blur();

  @JS('getElementsByTagName')
  external _DomList _getElementsByTagName(JSString tag);
  Iterable<DomNode> getElementsByTagName(String tag) =>
      createDomListWrapper(_getElementsByTagName(tag.toJS));

  @JS('getElementsByClassName')
  external _DomList _getElementsByClassName(JSString className);
  Iterable<DomNode> getElementsByClassName(String className) =>
      createDomListWrapper(_getElementsByClassName(className.toJS));

  external void click();

  @JS('hasAttribute')
  external JSBoolean _hasAttribute(JSString name);
  bool hasAttribute(String name) => _hasAttribute(name.toJS).toDart;

  @JS('childNodes')
  @redeclare
  external _DomList get _childNodes;
  @redeclare
  Iterable<DomNode> get childNodes => createDomListWrapper<DomElement>(_childNodes);

  @JS('attachShadow')
  external DomShadowRoot _attachShadow(JSAny initDict);
  DomShadowRoot attachShadow(Map<Object?, Object?> initDict) => _attachShadow(initDict.toJSAnyDeep);

  external DomShadowRoot? get shadowRoot;

  @redeclare
  void clearChildren() {
    while (firstChild != null) {
      removeChild(firstChild!);
    }
  }

  external void setPointerCapture(num? pointerId);
}

DomElement createDomElement(String tag) => domDocument.createElement(tag);

extension type DomCSS._(JSObject _) implements JSObject {
  external bool supports(String proeprty, String value);
}

@JS('CSS')
external DomCSS get domCSS;

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

  @JS('getPropertyValue')
  external JSString _getPropertyValue(JSString property);
  String getPropertyValue(String property) => _getPropertyValue(property.toJS).toDart;

  @JS('setProperty')
  external void _setProperty(JSString propertyName, JSString value, JSString priority);
  void setProperty(String propertyName, String value, [String? priority]) {
    priority ??= '';
    _setProperty(propertyName.toJS, value.toJS, priority.toJS);
  }

  @JS('removeProperty')
  external JSString _removeProperty(JSString property);
  String removeProperty(String property) => _removeProperty(property.toJS).toDart;
}

extension type DomHTMLElement._(JSObject _) implements JSObject, DomElement {
  @JS('offsetWidth')
  @redeclare
  external JSNumber get _offsetWidth;
  @redeclare
  double get offsetWidth => _offsetWidth.toDartDouble;

  @JS('offsetLeft')
  external JSNumber get _offsetLeft;
  double get offsetLeft => _offsetLeft.toDartDouble;

  @JS('offsetTop')
  external JSNumber get _offsetTop;
  double get offsetTop => _offsetTop.toDartDouble;

  external DomHTMLElement? get offsetParent;
}

extension type DomHTMLMetaElement._(JSObject _) implements JSObject, DomHTMLElement {
  @JS('name')
  external JSString get _name;
  String get name => _name.toDart;

  @JS('name')
  external set _name(JSString value);
  set name(String value) => _name = value.toJS;

  @JS('content')
  external JSString get _content;
  String get content => _content.toDart;

  @JS('content')
  external set _content(JSString value);
  set content(String value) => _content = value.toJS;
}

DomHTMLMetaElement createDomHTMLMetaElement() =>
    domDocument.createElement('meta') as DomHTMLMetaElement;

extension type DomHTMLHeadElement._(JSObject _) implements JSObject, DomHTMLElement {}

extension type DomHTMLBodyElement._(JSObject _) implements JSObject, DomHTMLElement {}

extension type DomHTMLImageElement._(JSObject _)
    implements JSObject, DomHTMLElement, DomCanvasImageSource {
  @JS('alt')
  external JSString? get _alt;
  String? get alt => _alt?.toDart;

  @JS('alt')
  external set _alt(JSString? value);
  set alt(String? value) => _alt = value?.toJS;

  @JS('src')
  external JSString? get _src;
  String? get src => _src?.toDart;

  @JS('src')
  external set _src(JSString? value);
  set src(String? value) => _src = value?.toJS;

  @JS('naturalWidth')
  external JSNumber get _naturalWidth;
  double get naturalWidth => _naturalWidth.toDartDouble;

  @JS('naturalHeight')
  external JSNumber get _naturalHeight;
  double get naturalHeight => _naturalHeight.toDartDouble;

  @JS('width')
  external set _width(JSNumber? value);
  set width(double? value) => _width = value?.toJS;

  @JS('height')
  external set _height(JSNumber? value);
  set height(double? value) => _height = value?.toJS;

  @JS('crossOrigin')
  external JSString? get _crossOrigin;
  String? get crossOrigin => _crossOrigin?.toDart;

  @JS('crossOrigin')
  external set _crossOrigin(JSString? value);
  set crossOrigin(String? value) => _crossOrigin = value?.toJS;

  @JS('decoding')
  external JSString? get _decoding;
  String? get decoding => _decoding?.toDart;

  @JS('decoding')
  external set _decoding(JSString? value);
  set decoding(String? value) => _decoding = value?.toJS;

  @JS('decode')
  external JSPromise<JSAny?> _decode();
  Future<Object?> decode() => _decode().toDart;
}

DomHTMLImageElement createDomHTMLImageElement() =>
    domDocument.createElement('img') as DomHTMLImageElement;

extension type DomHTMLScriptElement._(JSObject _) implements JSObject, DomHTMLElement {
  @JS('src')
  external set _src(JSAny value);
  set src(Object /* String|TrustedScriptURL */ value) => _src = value.toJSAnyShallow;

  @JS('nonce')
  external set _nonce(JSString? value);
  set nonce(String? value) => _nonce = value?.toJS;
}

DomHTMLScriptElement createDomHTMLScriptElement(String? nonce) {
  final DomHTMLScriptElement script = domDocument.createElement('script') as DomHTMLScriptElement;
  if (nonce != null) {
    script.nonce = nonce;
  }
  return script;
}

extension type DomHTMLDivElement._(JSObject _) implements JSObject, DomHTMLElement {}

DomHTMLDivElement createDomHTMLDivElement() =>
    domDocument.createElement('div') as DomHTMLDivElement;

extension type DomHTMLSpanElement._(JSObject _) implements JSObject, DomHTMLElement {}

DomHTMLSpanElement createDomHTMLSpanElement() =>
    domDocument.createElement('span') as DomHTMLSpanElement;

extension type DomHTMLButtonElement._(JSObject _) implements JSObject, DomHTMLElement {}

DomHTMLButtonElement createDomHTMLButtonElement() =>
    domDocument.createElement('button') as DomHTMLButtonElement;

extension type DomHTMLParagraphElement._(JSObject _) implements JSObject, DomHTMLElement {}

DomHTMLParagraphElement createDomHTMLParagraphElement() =>
    domDocument.createElement('p') as DomHTMLParagraphElement;

extension type DomHTMLStyleElement._(JSObject _) implements JSObject, DomHTMLElement {
  @JS('type')
  external set _type(JSString? value);
  set type(String? value) => _type = value?.toJS;

  @JS('nonce')
  external set _nonce(JSString? value);
  set nonce(String? value) => _nonce = value?.toJS;

  @JS('nonce')
  external JSString? get _nonce;
  String? get nonce => _nonce?.toDart;

  external DomStyleSheet? get sheet;
}

DomHTMLStyleElement createDomHTMLStyleElement(String? nonce) {
  final DomHTMLStyleElement style = domDocument.createElement('style') as DomHTMLStyleElement;
  if (nonce != null) {
    style.nonce = nonce;
  }
  return style;
}

extension type DomPerformance._(JSObject _) implements JSObject, DomEventTarget {
  @JS('mark')
  external DomPerformanceEntry? _mark(JSString markName);
  DomPerformanceEntry? mark(String markName) => _mark(markName.toJS);

  @JS('measure')
  external DomPerformanceMeasure? _measure(
    JSString measureName,
    JSString? startMark,
    JSString? endMark,
  );
  DomPerformanceMeasure? measure(String measureName, String? startMark, String? endMark) =>
      _measure(measureName.toJS, startMark?.toJS, endMark?.toJS);

  @JS('now')
  external JSNumber _now();
  double now() => _now().toDartDouble;
}

extension type DomPerformanceEntry._(JSObject _) implements JSObject {}

extension type DomPerformanceMeasure._(JSObject _) implements JSObject, DomPerformanceEntry {}

extension type DomCanvasElement._(JSObject _) implements JSObject, DomHTMLElement {
  @JS('width')
  external JSNumber? get _width;
  double? get width => _width?.toDartDouble;

  @JS('width')
  external set _width(JSNumber? value);
  set width(double? value) => _width = value?.toJS;

  @JS('height')
  external JSNumber? get _height;
  double? get height => _height?.toDartDouble;

  @JS('height')
  external set _height(JSNumber? value);
  set height(double? value) => _height = value?.toJS;

  @JS('isConnected')
  @redeclare
  external JSBoolean? get _isConnected;
  @redeclare
  bool? get isConnected => _isConnected?.toDart;

  @JS('toDataURL')
  external JSString _toDataURL(JSString type);
  String toDataURL([String type = 'image/png']) => _toDataURL(type.toJS).toDart;

  @JS('getContext')
  external JSAny? _getContext(JSString contextType, [JSAny attributes]);
  Object? getContext(String contextType, [Map<dynamic, dynamic>? attributes]) {
    if (attributes == null) {
      return _getContext(contextType.toJS);
    } else {
      return _getContext(contextType.toJS, attributes.toJSAnyDeep);
    }
  }

  DomCanvasRenderingContext2D get context2D => getContext('2d')! as DomCanvasRenderingContext2D;

  WebGLContext getGlContext(int majorVersion) {
    if (majorVersion == 1) {
      return getContext('webgl')! as WebGLContext;
    }
    return getContext('webgl2')! as WebGLContext;
  }

  DomCanvasRenderingContextBitmapRenderer get contextBitmapRenderer =>
      getContext('bitmaprenderer')! as DomCanvasRenderingContextBitmapRenderer;
}

@visibleForTesting
int debugCanvasCount = 0;

@visibleForTesting
void debugResetCanvasCount() {
  debugCanvasCount = 0;
}

DomCanvasElement createDomCanvasElement({int? width, int? height}) {
  debugCanvasCount++;
  final DomCanvasElement canvas = domWindow.document.createElement('canvas') as DomCanvasElement;
  if (width != null) {
    canvas.width = width.toDouble();
  }
  if (height != null) {
    canvas.height = height.toDouble();
  }
  return canvas;
}

extension type WebGLContext._(JSObject _) implements JSObject {
  @JS('getParameter')
  external JSNumber _getParameter(JSNumber value);
  int getParameter(int value) => _getParameter(value.toJS).toDartDouble.toInt();

  @JS('SAMPLES')
  external JSNumber get _samples;
  int get samples => _samples.toDartDouble.toInt();

  @JS('STENCIL_BITS')
  external JSNumber get _stencilBits;
  int get stencilBits => _stencilBits.toDartDouble.toInt();
}

extension type DomCanvasImageSource._(JSObject _) implements JSObject {}

extension type DomCanvasRenderingContext2D._(JSObject _) implements JSObject {
  external DomCanvasElement? get canvas;

  @JS('fillStyle')
  external JSAny? get _fillStyle;
  Object? get fillStyle => _fillStyle?.toObjectShallow;

  @JS('fillStyle')
  external set _fillStyle(JSAny? style);
  set fillStyle(Object? style) => _fillStyle = style?.toJSAnyShallow;

  @JS('font')
  external JSString get _font;
  String get font => _font.toDart;

  @JS('font')
  external set _font(JSString value);
  set font(String value) => _font = value.toJS;

  @JS('direction')
  external JSString get _direction;
  String get direction => _direction.toDart;

  @JS('direction')
  external set _direction(JSString value);
  set direction(String value) => _direction = value.toJS;

  @JS('lineWidth')
  external set _lineWidth(JSNumber? value);
  set lineWidth(num? value) => _lineWidth = value?.toJS;

  @JS('strokeStyle')
  external set _strokeStyle(JSAny? value);
  set strokeStyle(Object? value) => _strokeStyle = value?.toJSAnyShallow;

  @JS('strokeStyle')
  external JSAny? get _strokeStyle;
  Object? get strokeStyle => _strokeStyle?.toObjectShallow;

  external void beginPath();
  external void closePath();

  @JS('createLinearGradient')
  external DomCanvasGradient _createLinearGradient(
    JSNumber x0,
    JSNumber y0,
    JSNumber x1,
    JSNumber y1,
  );
  DomCanvasGradient createLinearGradient(num x0, num y0, num x1, num y1) =>
      _createLinearGradient(x0.toJS, y0.toJS, x1.toJS, y1.toJS);

  @JS('createPattern')
  external DomCanvasPattern? _createPattern(JSAny image, JSString reptitionType);
  DomCanvasPattern? createPattern(Object image, String reptitionType) =>
      _createPattern(image.toJSAnyShallow, reptitionType.toJS);

  @JS('createRadialGradient')
  external DomCanvasGradient _createRadialGradient(
    JSNumber x0,
    JSNumber y0,
    JSNumber r0,
    JSNumber x1,
    JSNumber y1,
    JSNumber r1,
  );
  DomCanvasGradient createRadialGradient(num x0, num y0, num r0, num x1, num y1, num r1) =>
      _createRadialGradient(x0.toJS, y0.toJS, r0.toJS, x1.toJS, y1.toJS, r1.toJS);

  @JS('drawImage')
  external void _drawImage(
    DomCanvasImageSource source,
    JSNumber sxOrDx,
    JSNumber syOrDy, [
    JSNumber sWidth,
    JSNumber sHeight,
    JSNumber dx,
    JSNumber dy,
    JSNumber dWidth,
    JSNumber dHeight,
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
      return _drawImage(source, srcxOrDstX.toJS, srcyOrDstY.toJS);
    } else {
      assert(
        srcHeight != null && dstX != null && dstY != null && dstWidth != null && dstHeight != null,
      );
      return _drawImage(
        source,
        srcxOrDstX.toJS,
        srcyOrDstY.toJS,
        srcWidth.toJS,
        srcHeight!.toJS,
        dstX!.toJS,
        dstY!.toJS,
        dstWidth!.toJS,
        dstHeight!.toJS,
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

  @JS('fillRect')
  external void _fillRect(JSNumber x, JSNumber y, JSNumber width, JSNumber height);
  void fillRect(num x, num y, num width, num height) =>
      _fillRect(x.toJS, y.toJS, width.toJS, height.toJS);

  @JS('fillText')
  external void _fillText(JSString text, JSNumber x, JSNumber y, [JSNumber maxWidth]);
  void fillText(String text, num x, num y, [num? maxWidth]) {
    if (maxWidth == null) {
      _fillText(text.toJS, x.toJS, y.toJS);
    } else {
      _fillText(text.toJS, x.toJS, y.toJS, maxWidth.toJS);
    }
  }

  @JS('getImageData')
  external DomImageData _getImageData(JSNumber x, JSNumber y, JSNumber sw, JSNumber sh);
  DomImageData getImageData(int x, int y, int sw, int sh) =>
      _getImageData(x.toJS, y.toJS, sw.toJS, sh.toJS);

  @JS('lineTo')
  external void _lineTo(JSNumber x, JSNumber y);
  void lineTo(num x, num y) => _lineTo(x.toJS, y.toJS);

  @JS('measureText')
  external DomTextMetrics _measureText(JSString text);
  DomTextMetrics measureText(String text) => _measureText(text.toJS);

  @JS('moveTo')
  external void _moveTo(JSNumber x, JSNumber y);
  void moveTo(num x, num y) => _moveTo(x.toJS, y.toJS);

  external void save();
  external void stroke();

  @JS('rect')
  external void _rect(JSNumber x, JSNumber y, JSNumber width, JSNumber height);
  void rect(num x, num y, num width, num height) => _rect(x.toJS, y.toJS, width.toJS, height.toJS);

  external void resetTransform();
  external void restore();

  @JS('setTransform')
  external void _setTransform(
    JSNumber a,
    JSNumber b,
    JSNumber c,
    JSNumber d,
    JSNumber e,
    JSNumber f,
  );
  void setTransform(num a, num b, num c, num d, num e, num f) =>
      _setTransform(a.toJS, b.toJS, c.toJS, d.toJS, e.toJS, f.toJS);

  @JS('transform')
  external void _transform(JSNumber a, JSNumber b, JSNumber c, JSNumber d, JSNumber e, JSNumber f);
  void transform(num a, num b, num c, num d, num e, num f) =>
      _transform(a.toJS, b.toJS, c.toJS, d.toJS, e.toJS, f.toJS);

  @JS('clip')
  external void _clip([JSAny pathOrWinding]);
  void clip([Object? pathOrWinding]) {
    if (pathOrWinding == null) {
      _clip();
    } else {
      _clip(pathOrWinding.toJSAnyShallow);
    }
  }

  @JS('scale')
  external void _scale(JSNumber x, JSNumber y);
  void scale(num x, num y) => _scale(x.toJS, y.toJS);

  @JS('clearRect')
  external void _clearRect(JSNumber x, JSNumber y, JSNumber width, JSNumber height);
  void clearRect(num x, num y, num width, num height) =>
      _clearRect(x.toJS, y.toJS, width.toJS, height.toJS);

  @JS('translate')
  external void _translate(JSNumber x, JSNumber y);
  void translate(num x, num y) => _translate(x.toJS, y.toJS);

  @JS('rotate')
  external void _rotate(JSNumber angle);
  void rotate(num angle) => _rotate(angle.toJS);

  @JS('bezierCurveTo')
  external void _bezierCurveTo(
    JSNumber cp1x,
    JSNumber cp1y,
    JSNumber cp2x,
    JSNumber cp2y,
    JSNumber x,
    JSNumber y,
  );
  void bezierCurveTo(num cp1x, num cp1y, num cp2x, num cp2y, num x, num y) =>
      _bezierCurveTo(cp1x.toJS, cp1y.toJS, cp2x.toJS, cp2y.toJS, x.toJS, y.toJS);

  @JS('quadraticCurveTo')
  external void _quadraticCurveTo(JSNumber cpx, JSNumber cpy, JSNumber x, JSNumber y);
  void quadraticCurveTo(num cpx, num cpy, num x, num y) =>
      _quadraticCurveTo(cpx.toJS, cpy.toJS, x.toJS, y.toJS);

  @JS('globalCompositeOperation')
  external set _globalCompositeOperation(JSString value);
  set globalCompositeOperation(String value) => _globalCompositeOperation = value.toJS;

  @JS('lineCap')
  external set _lineCap(JSString value);
  set lineCap(String value) => _lineCap = value.toJS;

  @JS('lineJoin')
  external set _lineJoin(JSString value);
  set lineJoin(String value) => _lineJoin = value.toJS;

  @JS('shadowBlur')
  external set _shadowBlur(JSNumber value);
  set shadowBlur(num value) => _shadowBlur = value.toJS;

  @JS('arc')
  external void _arc(
    JSNumber x,
    JSNumber y,
    JSNumber radius,
    JSNumber startAngle,
    JSNumber endAngle,
    JSBoolean antiClockwise,
  );
  void arc(num x, num y, num radius, num startAngle, num endAngle, [bool antiClockwise = false]) =>
      _arc(x.toJS, y.toJS, radius.toJS, startAngle.toJS, endAngle.toJS, antiClockwise.toJS);

  @JS('filter')
  external set _filter(JSString? value);
  set filter(String? value) => _filter = value?.toJS;

  @JS('shadowOffsetX')
  external set _shadowOffsetX(JSNumber? x);
  set shadowOffsetX(num? x) => _shadowOffsetX = x?.toJS;

  @JS('shadowOffsetY')
  external set _shadowOffsetY(JSNumber? y);
  set shadowOffsetY(num? y) => _shadowOffsetY = y?.toJS;

  @JS('shadowColor')
  external set _shadowColor(JSString? value);
  set shadowColor(String? value) => _shadowColor = value?.toJS;

  @JS('ellipse')
  external void _ellipse(
    JSNumber x,
    JSNumber y,
    JSNumber radiusX,
    JSNumber radiusY,
    JSNumber rotation,
    JSNumber startAngle,
    JSNumber endAngle,
    JSBoolean? antiClockwise,
  );
  void ellipse(
    num x,
    num y,
    num radiusX,
    num radiusY,
    num rotation,
    num startAngle,
    num endAngle,
    bool? antiClockwise,
  ) => _ellipse(
    x.toJS,
    y.toJS,
    radiusX.toJS,
    radiusY.toJS,
    rotation.toJS,
    startAngle.toJS,
    endAngle.toJS,
    antiClockwise?.toJS,
  );

  @JS('strokeText')
  external void _strokeText(JSString text, JSNumber x, JSNumber y);
  void strokeText(String text, num x, num y) => _strokeText(text.toJS, x.toJS, y.toJS);

  @JS('globalAlpha')
  external set _globalAlpha(JSNumber? value);
  set globalAlpha(num? value) => _globalAlpha = value?.toJS;
}

extension type DomCanvasRenderingContextWebGl._(JSObject _) implements JSObject {
  @JS('isContextLost')
  external JSBoolean _isContextLost();
  bool isContextLost() => _isContextLost().toDart;
}

extension type DomCanvasRenderingContextBitmapRenderer._(JSObject _) implements JSObject {
  external void transferFromImageBitmap(DomImageBitmap? bitmap);
}

@JS('ImageData')
extension type DomImageData._(JSObject _) implements JSObject {
  external DomImageData(JSAny? data, JSNumber sw, JSNumber sh);
  external DomImageData._empty(JSNumber sw, JSNumber sh);

  @JS('data')
  external JSUint8ClampedArray get _data;
  Uint8ClampedList get data => _data.toDart;
}

DomImageData createDomImageData(Object data, int sw, int sh) =>
    DomImageData(data.toJSAnyShallow, sw.toJS, sh.toJS);
DomImageData createBlankDomImageData(int sw, int sh) => DomImageData._empty(sw.toJS, sh.toJS);

@JS('ImageBitmap')
extension type DomImageBitmap._(JSObject _) implements JSObject, DomCanvasImageSource {
  external JSNumber get width;
  external JSNumber get height;
  external void close();
}

extension type DomCanvasPattern._(JSObject _) implements JSObject {}

extension type DomCanvasGradient._(JSObject _) implements JSObject {
  @JS('addColorStop')
  external void _addColorStop(JSNumber offset, JSString color);
  void addColorStop(num offset, String color) => _addColorStop(offset.toJS, color.toJS);
}

extension type DomXMLHttpRequestEventTarget._(JSObject _) implements JSObject, DomEventTarget {}

Future<DomResponse> rawHttpGet(String url) =>
    domWindow._fetch(url.toJS).toDart.then((JSAny? value) => value! as DomResponse);

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
      url.toJS,
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

  final DomResponse _domResponse;

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
  Future<void> read<T>(HttpFetchReader<T> callback) async {
    final int totalLength = _byteBuffer.lengthInBytes;
    int currentIndex = 0;
    while (currentIndex < totalLength) {
      final int chunkSize = math.min(_chunkSize, totalLength - currentIndex);
      final Uint8List chunk = Uint8List.sublistView(
        _byteBuffer.asByteData(),
        currentIndex,
        currentIndex + chunkSize,
      );
      callback(chunk.toJS as T);
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

extension type DomResponse._(JSObject _) implements JSObject {
  @JS('status')
  external JSNumber get _status;
  int get status => _status.toDartInt;

  external DomHeaders get headers;

  external _DomReadableStream get body;

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

extension type DomHeaders._(JSObject _) implements JSObject {
  @JS('get')
  external JSString? _get(JSString? headerName);
  String? get(String? headerName) => _get(headerName?.toJS)?.toDart;
}

extension type _DomReadableStream._(JSObject _) implements JSObject {
  external _DomStreamReader getReader();
}

extension type _DomStreamReader._(JSObject _) implements JSObject {
  @JS('read')
  external JSPromise<JSAny?> _read();
  Future<_DomStreamChunk> read() =>
      _read().toDart.then((JSAny? value) => value! as _DomStreamChunk);
}

extension type _DomStreamChunk._(JSObject _) implements JSObject {
  external JSAny? get value;

  @JS('done')
  external JSBoolean get _done;
  bool get done => _done.toDart;
}

extension type DomCharacterData._(JSObject _) implements JSObject, DomNode {}

extension type DomText._(JSObject _) implements JSObject, DomCharacterData {}

DomText createDomText(String data) => domDocument.createTextNode(data);

extension type DomTextMetrics._(JSObject _) implements JSObject {
  @JS('width')
  external JSNumber? get _width;
  double? get width => _width?.toDartDouble;
}

extension type DomException._(JSObject _) implements JSObject {
  static const String notSupported = 'NotSupportedError';

  @JS('name')
  external JSString get _name;
  String get name => _name.toDart;
}

extension type DomRectReadOnly._(JSObject _) implements JSObject {
  @JS('x')
  external JSNumber get _x;
  double get x => _x.toDartDouble;

  @JS('y')
  external JSNumber get _y;
  double get y => _y.toDartDouble;

  @JS('width')
  external JSNumber get _width;
  double get width => _width.toDartDouble;

  @JS('height')
  external JSNumber get _height;
  double get height => _height.toDartDouble;

  @JS('top')
  external JSNumber get _top;
  double get top => _top.toDartDouble;

  @JS('right')
  external JSNumber get _right;
  double get right => _right.toDartDouble;

  @JS('bottom')
  external JSNumber get _bottom;
  double get bottom => _bottom.toDartDouble;

  @JS('left')
  external JSNumber get _left;
  double get left => _left.toDartDouble;
}

DomRect createDomRectFromPoints(DomPoint a, DomPoint b) {
  final num left = math.min(a.x, b.x);
  final num width = math.max(a.x, b.x) - left;
  final num top = math.min(a.y, b.y);
  final num height = math.max(a.y, b.y) - top;
  return DomRect(left.toJS, top.toJS, width.toJS, height.toJS);
}

@JS('DOMRect')
extension type DomRect._(JSObject _) implements JSObject, DomRectReadOnly {
  external DomRect(JSNumber left, JSNumber top, JSNumber width, JSNumber height);
}

@JS('FontFace')
extension type DomFontFace._(JSObject _) implements JSObject {
  external DomFontFace._args2(JSString family, JSAny source);
  external DomFontFace._args3(JSString family, JSAny source, JSAny descriptors);

  @JS('load')
  external JSPromise<JSAny?> _load();
  Future<DomFontFace> load() => _load().toDart.then((JSAny? value) => value! as DomFontFace);

  @JS('family')
  external JSString? get _family;
  String? get family => _family?.toDart;

  @JS('weight')
  external JSString? get _weight;
  String? get weight => _weight?.toDart;

  @JS('status')
  external JSString? get _status;
  String? get status => _status?.toDart;
}

DomFontFace createDomFontFace(String family, Object source, [Map<Object?, Object?>? descriptors]) {
  if (descriptors == null) {
    return DomFontFace._args2(family.toJS, source.toJSAnyShallow);
  } else {
    return DomFontFace._args3(family.toJS, source.toJSAnyShallow, descriptors.toJSAnyDeep);
  }
}

extension type DomFontFaceSet._(JSObject _) implements JSObject, DomEventTarget {
  external DomFontFaceSet? add(DomFontFace font);
  external void clear();

  @JS('forEach')
  external void _forEach(JSFunction callback);
  void forEach(DomFontFaceSetForEachCallback callback) => _forEach(callback.toJS);
}

typedef DomFontFaceSetForEachCallback =
    void Function(DomFontFace fontFace, DomFontFace fontFaceAgain, DomFontFaceSet set);

extension type DomVisualViewport._(JSObject _) implements JSObject, DomEventTarget {
  @JS('height')
  external JSNumber? get _height;
  double? get height => _height?.toDartDouble;

  @JS('width')
  external JSNumber? get _width;
  double? get width => _width?.toDartDouble;

  @JS('scale')
  external JSNumber? get _scale;
  double? get scale => _scale?.toDartDouble;
}

extension type DomHTMLTextAreaElement._(JSObject _) implements JSObject, DomHTMLElement {
  @JS('value')
  external set _value(JSString? value);
  set value(String? value) => _value = value?.toJS;

  external void select();

  @JS('placeholder')
  external set _placeholder(JSString? value);
  set placeholder(String? value) => _placeholder = value?.toJS;

  @JS('name')
  external set _name(JSString value);
  set name(String value) => _name = value.toJS;

  @JS('selectionDirection')
  external JSString? get _selectionDirection;
  String? get selectionDirection => _selectionDirection?.toDart;

  @JS('selectionStart')
  external JSNumber? get _selectionStart;
  double? get selectionStart => _selectionStart?.toDartDouble;

  @JS('selectionEnd')
  external JSNumber? get _selectionEnd;
  double? get selectionEnd => _selectionEnd?.toDartDouble;

  @JS('selectionStart')
  external set _selectionStart(JSNumber? value);
  set selectionStart(double? value) => _selectionStart = value?.toJS;

  @JS('selectionEnd')
  external set _selectionEnd(JSNumber? value);
  set selectionEnd(double? value) => _selectionEnd = value?.toJS;

  @JS('value')
  external JSString? get _value;
  String? get value => _value?.toDart;

  @JS('setSelectionRange')
  external void _setSelectionRange(JSNumber start, JSNumber end, [JSString direction]);
  void setSelectionRange(int start, int end, [String? direction]) {
    if (direction == null) {
      _setSelectionRange(start.toJS, end.toJS);
    } else {
      _setSelectionRange(start.toJS, end.toJS, direction.toJS);
    }
  }

  @JS('name')
  external JSString get _name;
  String get name => _name.toDart;

  @JS('placeholder')
  external JSString get _placeholder;
  String get placeholder => _placeholder.toDart;
}

DomHTMLTextAreaElement createDomHTMLTextAreaElement() =>
    domDocument.createElement('textarea') as DomHTMLTextAreaElement;

extension type DomClipboard._(JSObject _) implements JSObject, DomEventTarget {
  @JS('readText')
  external JSPromise<JSAny?> _readText();
  Future<String> readText() =>
      _readText().toDart.then((JSAny? value) => (value! as JSString).toDart);

  @JS('writeText')
  external JSPromise<JSAny?> _writeText(JSString data);
  Future<dynamic> writeText(String data) => _writeText(data.toJS).toDart;
}

extension type DomUIEvent._(JSObject _) implements JSObject, DomEvent {}

@JS('KeyboardEvent')
extension type DomKeyboardEvent._(JSObject _) implements JSObject, DomUIEvent {
  external DomKeyboardEvent(JSString type, [JSAny initDict]);

  @JS('altKey')
  external JSBoolean get _altKey;
  bool get altKey => _altKey.toDart;

  @JS('code')
  external JSString? get _code;
  String? get code => _code?.toDart;

  @JS('ctrlKey')
  external JSBoolean get _ctrlKey;
  bool get ctrlKey => _ctrlKey.toDart;

  @JS('key')
  external JSString? get _key;
  String? get key => _key?.toDart;

  @JS('keyCode')
  external JSNumber get _keyCode;
  double get keyCode => _keyCode.toDartDouble;

  @JS('location')
  external JSNumber get _location;
  double get location => _location.toDartDouble;

  @JS('metaKey')
  external JSBoolean get _metaKey;
  bool get metaKey => _metaKey.toDart;

  @JS('repeat')
  external JSBoolean? get _repeat;
  bool? get repeat => _repeat?.toDart;

  // Safari injects synthetic keyboard events after auto-complete that don't
  // have a `shiftKey` attribute, so this property must be nullable.
  @JS('shiftKey')
  external JSBoolean? get _shiftKey;
  bool? get shiftKey => _shiftKey?.toDart;

  @JS('isComposing')
  external JSBoolean get _isComposing;
  bool get isComposing => _isComposing.toDart;

  @JS('getModifierState')
  external JSBoolean _getModifierState(JSString keyArg);
  bool getModifierState(String keyArg) => _getModifierState(keyArg.toJS).toDart;
}

DomKeyboardEvent createDomKeyboardEvent(String type, [Map<dynamic, dynamic>? init]) {
  if (init == null) {
    return DomKeyboardEvent(type.toJS);
  } else {
    return DomKeyboardEvent(type.toJS, init.toJSAnyDeep);
  }
}

extension type DomHistory._(JSObject _) implements JSObject {
  @JS('state')
  external JSAny? get _state;
  dynamic get state => _state?.toObjectDeep;

  @JS('go')
  external void _go([JSNumber delta]);
  void go([int? delta]) {
    if (delta == null) {
      _go();
    } else {
      _go(delta.toJS);
    }
  }

  @JS('pushState')
  external void _pushState(JSAny? data, JSString title, JSString? url);
  void pushState(Object? data, String title, String? url) =>
      _pushState(data?.toJSAnyDeep, title.toJS, url?.toJS);

  @JS('replaceState')
  external void _replaceState(JSAny? data, JSString title, JSString? url);
  void replaceState(Object? data, String title, String? url) =>
      _replaceState(data?.toJSAnyDeep, title.toJS, url?.toJS);
}

extension type DomLocation._(JSObject _) implements JSObject {
  @JS('pathname')
  external JSString? get _pathname;
  String? get pathname => _pathname?.toDart;

  @JS('search')
  external JSString? get _search;
  String? get search => _search?.toDart;

  @JS('hash')
  external JSString get _hash;
  // We have to change the name here because 'hash' is inherited from [Object].
  String get locationHash => _hash.toDart;

  @JS('origin')
  external JSString get _origin;
  String get origin => _origin.toDart;

  @JS('href')
  external JSString get _href;
  String get href => _href.toDart;
}

@JS('PopStateEvent')
extension type DomPopStateEvent._(JSObject _) implements JSObject, DomEvent {
  external DomPopStateEvent(JSString type, [JSAny initDict]);

  @JS('state')
  external JSAny? get _state;
  dynamic get state => _state?.toObjectDeep;
}

DomPopStateEvent createDomPopStateEvent(String type, Map<Object?, Object?>? eventInitDict) {
  if (eventInitDict == null) {
    return DomPopStateEvent(type.toJS);
  } else {
    return DomPopStateEvent(type.toJS, eventInitDict.toJSAnyDeep);
  }
}

@JS('URL')
extension type DomURL._(JSObject _) implements JSObject {
  external DomURL(JSString url, [JSString? base]);

  @JS('createObjectURL')
  external JSString _createObjectURL(JSAny object);
  String createObjectURL(Object object) => _createObjectURL(object.toJSAnyShallow).toDart;

  @JS('revokeObjectURL')
  external void _revokeObjectURL(JSString url);
  void revokeObjectURL(String url) => _revokeObjectURL(url.toJS);

  @JS('toString')
  external JSString toJSString();
}

DomURL createDomURL(String url, [String? base]) =>
    base == null ? DomURL(url.toJS) : DomURL(url.toJS, base.toJS);

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
    return createDomListWrapper<DomNode>(list);
  }

  @JS('removedNodes')
  external _DomList? get _removedNodes;
  Iterable<DomNode>? get removedNodes {
    final _DomList? list = _removedNodes;
    if (list == null) {
      return null;
    }
    return createDomListWrapper<DomNode>(list);
  }

  @JS('attributeName')
  external JSString? get _attributeName;
  String? get attributeName => _attributeName?.toDart;

  @JS('type')
  external JSString? get _type;
  String? get type => _type?.toDart;
}

extension type DomMediaQueryList._(JSObject _) implements JSObject, DomEventTarget {
  @JS('matches')
  external JSBoolean get _matches;
  bool get matches => _matches.toDart;

  @JS('addListener')
  external void addListener(DomEventListener? listener);

  @JS('removeListener')
  external void removeListener(DomEventListener? listener);
}

extension type DomMediaQueryListEvent._(JSObject _) implements JSObject, DomEvent {
  @JS('matches')
  external JSBoolean? get _matches;
  bool? get matches => _matches?.toDart;
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
extension type DomInputEvent._(JSObject _) implements JSObject, DomUIEvent {
  external DomInputEvent(JSString type, [JSAny initDict]);
}

@JS('FocusEvent')
extension type DomFocusEvent._(JSObject _) implements JSObject, DomUIEvent {
  external DomEventTarget? get relatedTarget;
}

@JS('MouseEvent')
extension type DomMouseEvent._(JSObject _) implements JSObject, DomUIEvent {
  external DomMouseEvent(JSString type, [JSAny initDict]);

  @JS('clientX')
  external JSNumber get _clientX;
  double get clientX => _clientX.toDartDouble;

  @JS('clientY')
  external JSNumber get _clientY;
  double get clientY => _clientY.toDartDouble;

  @JS('offsetX')
  external JSNumber get _offsetX;
  double get offsetX => _offsetX.toDartDouble;

  @JS('offsetY')
  external JSNumber get _offsetY;
  double get offsetY => _offsetY.toDartDouble;

  @JS('pageX')
  external JSNumber get _pageX;
  double get pageX => _pageX.toDartDouble;

  @JS('pageY')
  external JSNumber get _pageY;
  double get pageY => _pageY.toDartDouble;

  DomPoint get client => DomPoint(clientX, clientY);
  DomPoint get offset => DomPoint(offsetX, offsetY);

  @JS('button')
  external JSNumber get _button;
  double get button => _button.toDartDouble;

  @JS('buttons')
  external JSNumber? get _buttons;
  double? get buttons => _buttons?.toDartDouble;

  @JS('ctrlKey')
  external JSBoolean get _ctrlKey;
  bool get ctrlKey => _ctrlKey.toDart;

  @JS('getModifierState')
  external JSBoolean _getModifierState(JSString keyArg);
  bool getModifierState(String keyArg) => _getModifierState(keyArg.toJS).toDart;
}

DomMouseEvent createDomMouseEvent(String type, [Map<dynamic, dynamic>? init]) {
  if (init == null) {
    return DomMouseEvent(type.toJS);
  } else {
    return DomMouseEvent(type.toJS, init.toJSAnyDeep);
  }
}

DomInputEvent createDomInputEvent(String type, [Map<dynamic, dynamic>? init]) {
  if (init == null) {
    return DomInputEvent(type.toJS);
  } else {
    return DomInputEvent(type.toJS, init.toJSAnyDeep);
  }
}

@JS('PointerEvent')
extension type DomPointerEvent._(JSObject _) implements JSObject, DomMouseEvent {
  external DomPointerEvent(JSString type, [JSAny initDict]);

  @JS('pointerId')
  external JSNumber? get _pointerId;
  double? get pointerId => _pointerId?.toDartDouble;

  @JS('pointerType')
  external JSString? get _pointerType;
  String? get pointerType => _pointerType?.toDart;

  @JS('pressure')
  external JSNumber? get _pressure;
  double? get pressure => _pressure?.toDartDouble;

  @JS('tiltX')
  external JSNumber? get _tiltX;
  double? get tiltX => _tiltX?.toDartDouble;

  @JS('tiltY')
  external JSNumber? get _tiltY;
  double? get tiltY => _tiltY?.toDartDouble;

  @JS('getCoalescedEvents')
  external JSArray<JSAny?> _getCoalescedEvents();
  List<DomPointerEvent> getCoalescedEvents() =>
      _getCoalescedEvents().toDart.cast<DomPointerEvent>();
}

DomPointerEvent createDomPointerEvent(String type, [Map<dynamic, dynamic>? init]) {
  if (init == null) {
    return DomPointerEvent(type.toJS);
  } else {
    return DomPointerEvent(type.toJS, init.toJSAnyDeep);
  }
}

@JS('WheelEvent')
extension type DomWheelEvent._(JSObject _) implements JSObject, DomMouseEvent {
  external DomWheelEvent(JSString type, [JSAny initDict]);

  @JS('deltaX')
  external JSNumber get _deltaX;
  double get deltaX => _deltaX.toDartDouble;

  @JS('deltaY')
  external JSNumber get _deltaY;
  double get deltaY => _deltaY.toDartDouble;

  @JS('wheelDeltaX')
  external JSNumber? get _wheelDeltaX;
  double? get wheelDeltaX => _wheelDeltaX?.toDartDouble;

  @JS('wheelDeltaY')
  external JSNumber? get _wheelDeltaY;
  double? get wheelDeltaY => _wheelDeltaY?.toDartDouble;

  @JS('deltaMode')
  external JSNumber get _deltaMode;
  double get deltaMode => _deltaMode.toDartDouble;
}

DomWheelEvent createDomWheelEvent(String type, [Map<dynamic, dynamic>? init]) {
  if (init == null) {
    return DomWheelEvent(type.toJS);
  } else {
    return DomWheelEvent(type.toJS, init.toJSAnyDeep);
  }
}

@JS('TouchEvent')
extension type DomTouchEvent._(JSObject _) implements JSObject, DomUIEvent {
  external DomTouchEvent(JSString type, [JSAny initDict]);

  @JS('altKey')
  external JSBoolean get _altKey;
  bool get altKey => _altKey.toDart;

  @JS('ctrlKey')
  external JSBoolean get _ctrlKey;
  bool get ctrlKey => _ctrlKey.toDart;

  @JS('metaKey')
  external JSBoolean get _metaKey;
  bool get metaKey => _metaKey.toDart;

  @JS('shiftKey')
  external JSBoolean get _shiftKey;
  bool get shiftKey => _shiftKey.toDart;

  @JS('changedTouches')
  external _DomTouchList get _changedTouches;
  Iterable<DomTouch> get changedTouches => createDomTouchListWrapper<DomTouch>(_changedTouches);
}

@JS('Touch')
extension type DomTouch._(JSObject _) implements JSObject {
  external DomTouch([JSAny initDict]);

  @JS('identifier')
  external JSNumber? get _identifier;
  double? get identifier => _identifier?.toDartDouble;

  @JS('clientX')
  external JSNumber get _clientX;
  double get clientX => _clientX.toDartDouble;

  @JS('clientY')
  external JSNumber get _clientY;
  double get clientY => _clientY.toDartDouble;

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
extension type DomCompositionEvent._(JSObject _) implements JSObject, DomUIEvent {
  external DomCompositionEvent(JSString type, [JSAny initDict]);

  @JS('data')
  external JSString? get _data;
  String? get data => _data?.toDart;
}

DomCompositionEvent createDomCompositionEvent(String type, [Map<dynamic, dynamic>? options]) {
  if (options == null) {
    return DomCompositionEvent(type.toJS);
  } else {
    return DomCompositionEvent(type.toJS, options.toJSAnyDeep);
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
extension type DomElementWithDisabledProperty._(JSObject _) implements JSObject, DomHTMLElement {
  @JS('disabled')
  external JSBoolean? get _disabled;
  bool? get disabled => _disabled?.toDart;

  @JS('disabled')
  external set _disabled(JSBoolean? value);
  set disabled(bool? value) => _disabled = value?.toJS;
}

extension type DomHTMLInputElement._(JSObject _) implements JSObject, DomHTMLElement {
  @JS('type')
  external set _type(JSString? value);
  set type(String? value) => _type = value?.toJS;

  @JS('max')
  external set _max(JSString? value);
  set max(String? value) => _max = value?.toJS;

  @JS('min')
  external set _min(JSString value);
  set min(String value) => _min = value.toJS;

  @JS('value')
  external set _value(JSString? value);
  set value(String? v) => _value = v?.toJS;

  @JS('value')
  external JSString? get _value;
  String? get value => _value?.toDart;

  @JS('disabled')
  external JSBoolean? get _disabled;
  bool? get disabled => _disabled?.toDart;

  @JS('disabled')
  external set _disabled(JSBoolean? value);
  set disabled(bool? value) => _disabled = value?.toJS;

  @JS('placeholder')
  external set _placeholder(JSString? value);
  set placeholder(String? value) => _placeholder = value?.toJS;

  @JS('name')
  external set _name(JSString? value);
  set name(String? value) => _name = value?.toJS;

  @JS('autocomplete')
  external set _autocomplete(JSString value);
  set autocomplete(String value) => _autocomplete = value.toJS;

  @JS('selectionDirection')
  external JSString? get _selectionDirection;
  String? get selectionDirection => _selectionDirection?.toDart;

  @JS('selectionStart')
  external JSNumber? get _selectionStart;
  double? get selectionStart => _selectionStart?.toDartDouble;

  @JS('selectionEnd')
  external JSNumber? get _selectionEnd;
  double? get selectionEnd => _selectionEnd?.toDartDouble;

  @JS('selectionStart')
  external set _selectionStart(JSNumber? value);
  set selectionStart(double? value) => _selectionStart = value?.toJS;

  @JS('selectionEnd')
  external set _selectionEnd(JSNumber? value);
  set selectionEnd(double? value) => _selectionEnd = value?.toJS;

  @JS('setSelectionRange')
  external void _setSelectionRange(JSNumber start, JSNumber end, [JSString direction]);
  void setSelectionRange(int start, int end, [String? direction]) {
    if (direction == null) {
      _setSelectionRange(start.toJS, end.toJS);
    } else {
      _setSelectionRange(start.toJS, end.toJS, direction.toJS);
    }
  }

  @JS('autocomplete')
  external JSString get _autocomplete;
  String get autocomplete => _autocomplete.toDart;

  @JS('name')
  external JSString? get _name;
  String? get name => _name?.toDart;

  @JS('type')
  external JSString? get _type;
  String? get type => _type?.toDart;

  @JS('placeholder')
  external JSString get _placeholder;
  String get placeholder => _placeholder.toDart;
}

DomHTMLInputElement createDomHTMLInputElement() =>
    domDocument.createElement('input') as DomHTMLInputElement;

extension type DomTokenList._(JSObject _) implements JSObject {
  @JS('add')
  external void _add(JSString value);
  void add(String value) => _add(value.toJS);

  @JS('remove')
  external void _remove(JSString value);
  void remove(String value) => _remove(value.toJS);

  @JS('contains')
  external JSBoolean _contains(JSString token);
  bool contains(String token) => _contains(token.toJS).toDart;
}

extension type DomHTMLFormElement._(JSObject _) implements JSObject, DomHTMLElement {
  @JS('noValidate')
  external set _noValidate(JSBoolean? value);
  set noValidate(bool? value) => _noValidate = value?.toJS;

  @JS('method')
  external set _method(JSString? value);
  set method(String? value) => _method = value?.toJS;

  @JS('action')
  external set _action(JSString? value);
  set action(String? value) => _action = value?.toJS;
}

DomHTMLFormElement createDomHTMLFormElement() =>
    domDocument.createElement('form') as DomHTMLFormElement;

extension type DomHTMLLabelElement._(JSObject _) implements JSObject, DomHTMLElement {}

DomHTMLLabelElement createDomHTMLLabelElement() =>
    domDocument.createElement('label') as DomHTMLLabelElement;

@JS('OffscreenCanvas')
extension type DomOffscreenCanvas._(JSObject _) implements JSObject, DomEventTarget {
  external DomOffscreenCanvas(JSNumber width, JSNumber height);

  @JS('height')
  external JSNumber? get _height;
  double? get height => _height?.toDartDouble;

  @JS('width')
  external JSNumber? get _width;
  double? get width => _width?.toDartDouble;

  @JS('height')
  external set _height(JSNumber? value);
  set height(double? value) => _height = value?.toJS;

  @JS('width')
  external set _width(JSNumber? value);
  set width(double? value) => _width = value?.toJS;

  @JS('getContext')
  external JSAny? _getContext(JSString contextType, [JSAny attributes]);
  Object? getContext(String contextType, [Map<dynamic, dynamic>? attributes]) {
    if (attributes == null) {
      return _getContext(contextType.toJS);
    } else {
      return _getContext(contextType.toJS, attributes.toJSAnyDeep);
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

  @JS('transferToImageBitmap')
  external JSAny? _transferToImageBitmap();
  DomImageBitmap transferToImageBitmap() => _transferToImageBitmap()! as DomImageBitmap;
}

DomOffscreenCanvas createDomOffscreenCanvas(int width, int height) =>
    DomOffscreenCanvas(width.toJS, height.toJS);

@JS('FileReader')
extension type DomFileReader._(JSObject _) implements JSObject, DomEventTarget {
  external DomFileReader();

  external void readAsDataURL(DomBlob blob);
}

DomFileReader createDomFileReader() => DomFileReader();

extension type DomDocumentFragment._(JSObject _) implements JSObject, DomNode {
  external DomElement? get firstElementChild;
  external DomElement? get lastElementChild;

  external void prepend(DomNode node);

  @JS('querySelector')
  external DomElement? _querySelector(JSString selectors);
  DomElement? querySelector(String selectors) => _querySelector(selectors.toJS);

  @JS('querySelectorAll')
  external _DomList _querySelectorAll(JSString selectors);
  Iterable<DomElement> querySelectorAll(String selectors) =>
      createDomListWrapper<DomElement>(_querySelectorAll(selectors.toJS));
}

extension type DomShadowRoot._(JSObject _) implements JSObject, DomDocumentFragment {
  external DomElement? get activeElement;
  external DomElement? get host;

  @JS('mode')
  external JSString? get _mode;
  String? get mode => _mode?.toDart;

  @JS('delegatesFocus')
  external JSBoolean? get _delegatesFocus;
  bool? get delegatesFocus => _delegatesFocus?.toDart;

  @JS('elementFromPoint')
  external DomElement? _elementFromPoint(JSNumber x, JSNumber y);
  DomElement? elementFromPoint(int x, int y) => _elementFromPoint(x.toJS, y.toJS);
}

extension type DomStyleSheet._(JSObject _) implements JSObject {}

extension type DomCSSStyleSheet._(JSObject _) implements JSObject, DomStyleSheet {
  @JS('cssRules')
  external _DomList get _cssRules;
  Iterable<DomCSSRule> get cssRules => createDomListWrapper<DomCSSRule>(_cssRules);

  @JS('insertRule')
  external JSNumber _insertRule(JSString rule, [JSNumber index]);
  double insertRule(String rule, [int? index]) {
    if (index == null) {
      return _insertRule(rule.toJS).toDartDouble;
    } else {
      return _insertRule(rule.toJS, index.toJS).toDartDouble;
    }
  }
}

extension type DomCSSRule._(JSObject _) implements JSObject {
  @JS('cssText')
  external JSString get _cssText;
  String get cssText => _cssText.toDart;
}

extension type DomScreen._(JSObject _) implements JSObject {
  external DomScreenOrientation? get orientation;

  external double get width;
  external double get height;
}

extension type DomScreenOrientation._(JSObject _) implements JSObject, DomEventTarget {
  @JS('lock')
  external JSPromise<JSAny?> _lock(JSString orientation);
  Future<dynamic> lock(String orientation) => _lock(orientation.toJS).toDart;

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
extension type DomWebSocket._(JSObject _) implements JSObject, DomEventTarget {
  external DomWebSocket(JSString url);

  @JS('send')
  external void _send(JSAny? data);
  void send(Object? data) => _send(data?.toJSAnyShallow);
}

DomWebSocket createDomWebSocket(String url) => DomWebSocket(url.toJS);

extension type DomMessageEvent._(JSObject _) implements JSObject, DomEvent {
  @JS('data')
  external JSAny? get _data;
  dynamic get data => _data?.toObjectDeep;

  @JS('origin')
  external JSString get _origin;
  String get origin => _origin.toDart;

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

extension type DomHTMLIFrameElement._(JSObject _) implements JSObject, DomHTMLElement {
  @JS('src')
  external set _src(JSString? value);
  set src(String? value) => _src = value?.toJS;

  @JS('src')
  external JSString? get _src;
  String? get src => _src?.toDart;

  @JS('height')
  external set _height(JSString? value);
  set height(String? value) => _height = value?.toJS;

  @JS('width')
  external set _width(JSString? value);
  set width(String? value) => _width = value?.toJS;

  external DomWindow get contentWindow;
}

DomHTMLIFrameElement createDomHTMLIFrameElement() =>
    domDocument.createElement('iframe') as DomHTMLIFrameElement;

extension type DomMessagePort._(JSObject _) implements JSObject, DomEventTarget {
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
  external DomResizeObserverObserveOptions({JSString box});
}

/// Type of the function used to create a Resize Observer.
typedef DomResizeObserverCallbackFn =
    void Function(List<DomResizeObserverEntry> entries, DomResizeObserver observer);

/// The object passed to the [DomResizeObserverCallbackFn], which allows access to the new dimensions of the observed element.
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/ResizeObserverEntry
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
extension type DomTrustedTypePolicyFactory._(JSObject _) implements JSObject {
  /// Creates a TrustedTypePolicy object named `policyName` that implements the
  /// rules passed as `policyOptions`.
  external DomTrustedTypePolicy createPolicy(
    JSString policyName,
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
extension type DomTrustedTypePolicy._(JSObject _) implements JSObject {
  /// Creates a `TrustedScriptURL` for the given [input].
  ///
  /// `input` is a string containing the data to be _sanitized_ by the policy.
  @JS('createScriptURL')
  external DomTrustedScriptURL _createScriptURL(JSString input);
  DomTrustedScriptURL createScriptURL(String input) => _createScriptURL(input.toJS);
}

/// Represents a string that a developer can insert into an _injection sink_
/// that will parse it as an external script.
///
/// These objects are created via `createScriptURL` and therefore have no
/// constructor.
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/TrustedScriptURL
extension type DomTrustedScriptURL._(JSObject _) implements JSObject {
  /// Exposes the `toString` JS method of TrustedScriptURL.
  @JS('toString')
  external JSString _toString();
  String get url => _toString().toDart;
}

// The expected set of files that the flutter-engine TrustedType policy is going
// to accept as valid.
const Set<String> _expectedFilesForTT = <String>{'canvaskit.js'};

// The definition of the `flutter-engine` TrustedType policy.
// Only accessible if the Trusted Types API is available.
final DomTrustedTypePolicy _ttPolicy = domWindow.trustedTypes!.createPolicy(
  'flutter-engine'.toJS,
  DomTrustedTypePolicyOptions(
    // Validates the given [url].
    createScriptURL:
        (JSString url) {
          final Uri uri = Uri.parse(url.toDart);
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
  @JS('length')
  external JSNumber get _length;
  double get length => _length.toDartDouble;

  @JS('item')
  external DomNode _item(JSNumber index);
  DomNode item(int index) => _item(index.toJS);
}

class _DomListIterator<T> implements Iterator<T> {
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
Iterable<T> createDomListWrapper<T>(_DomList list) => _DomListWrapper<T>._(list).cast<T>();

// https://developer.mozilla.org/en-US/docs/Web/API/TouchList
extension type _DomTouchList._(JSObject _) implements JSObject {
  @JS('length')
  external JSNumber get _length;
  double get length => _length.toDartDouble;

  @JS('item')
  external DomNode _item(JSNumber index);
  DomNode item(int index) => _item(index.toJS);
}

class _DomTouchListIterator<T> implements Iterator<T> {
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

extension type DomSymbol._(JSObject _) implements JSObject {
  @JS('iterator')
  external JSAny get iterator;
}

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
  DomSegments segment(String text) => segmentRaw(text.toJS);
}

// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Segmenter/segment/Segments
extension type DomSegments._(JSObject _) implements JSObject {
  DomIteratorWrapper<DomSegment> iterator() {
    final DomIterator segmentIterator =
        (this as JSObject).callMethod(domSymbol.iterator)! as DomIterator;
    return DomIteratorWrapper<DomSegment>(segmentIterator);
  }
}

// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Iteration_protocols
extension type DomIterator._(JSObject _) implements JSObject {
  external DomIteratorResult next();
}

extension type DomIteratorResult._(JSObject _) implements JSObject {
  @JS('done')
  external JSBoolean get _done;
  bool get done => _done.toDart;

  external JSAny get value;
}

/// Wraps a native JS iterator to provide a Dart [Iterator].
class DomIteratorWrapper<T> implements Iterator<T> {
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
  @JS('index')
  external JSNumber get _index;
  int get index => _index.toDartDouble.toInt();

  @JS('isWordLike')
  external JSBoolean get _isWordLike;
  bool get isWordLike => _isWordLike.toDart;

  @JS('segment')
  external JSString get _segment;
  String get segment => _segment.toDart;

  @JS('breakType')
  external JSString get _breakType;
  String get breakType => _breakType.toDart;
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

  @JS('adoptText')
  external void adoptText(JSString text);

  @JS('first')
  external JSNumber _first();
  double first() => _first().toDartDouble;

  @JS('next')
  external JSNumber _next();
  double next() => _next().toDartDouble;

  @JS('current')
  external JSNumber _current();
  double current() => _current().toDartDouble;

  @JS('breakType')
  external JSString _breakType();
  String breakType() => _breakType().toDart;
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

  @JS('register')
  external void register(ExternalDartReference target, ExternalDartReference value);

  @JS('register')
  external void registerWithToken(
    ExternalDartReference target,
    ExternalDartReference value,
    ExternalDartReference token,
  );

  @JS('unregister')
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
