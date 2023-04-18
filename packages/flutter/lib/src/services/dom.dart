// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
import 'package:js/js.dart';

/// This file includes static interop helpers for Flutter Web.
// TODO(joshualitt): This file will eventually be removed,
// https://github.com/flutter/flutter/issues/113402.

/// [DomWindow] interop object.
@JS()
@staticInterop
class DomWindow {}

/// [DomWindow] required extension.
extension DomWindowExtension on DomWindow {
  @JS('matchMedia')
  external DomMediaQueryList _matchMedia(final JSString? query);

  /// Returns a [DomMediaQueryList] of the media that matches [query].
  DomMediaQueryList matchMedia(final String? query) => _matchMedia(query?.toJS);

  /// Returns the [DomNavigator] associated with this window.
  external DomNavigator get navigator;

  /// Gets the current selection.
  external DomSelection? getSelection();
}

/// The underyling window.
@JS('window')
external DomWindow get domWindow;

/// [DomMediaQueryList] interop object.
@JS()
@staticInterop
class DomMediaQueryList {}

/// [DomMediaQueryList] required extension.
extension DomMediaQueryListExtension on DomMediaQueryList {
  @JS('matches')
  external JSBoolean get _matches;

  /// Whether or not the query matched.
  bool get matches => _matches.toDart;
}

/// [DomNavigator] interop object.
@JS()
@staticInterop
class DomNavigator {}

/// [DomNavigator] required extension.
extension DomNavigatorExtension on DomNavigator {
  @JS('platform')
  external JSString? get _platform;

  /// The underyling platform string.
  String? get platform => _platform?.toDart;
}

/// A DOM event target.
@JS()
@staticInterop
class DomEventTarget {}

/// [DomEventTarget]'s required extension.
extension DomEventTargetExtension on DomEventTarget {
  @JS('addEventListener')
  external JSVoid _addEventListener1(final JSString type, final DomEventListener? listener);

  @JS('addEventListener')
  external JSVoid _addEventListener2(
      final JSString type, final DomEventListener? listener, final JSBoolean useCapture);

  /// Adds an event listener to this event target.
  @JS('addEventListener')
  void addEventListener(final String type, final DomEventListener? listener,
      [final bool? useCapture]) {
    if (listener != null) {
      if (useCapture == null) {
        _addEventListener1(type.toJS, listener);
      } else {
        _addEventListener2(type.toJS, listener, useCapture.toJS);
      }
    }
  }
}

/// [DomXMLHttpRequest] interop class.
@JS('XMLHttpRequest')
@staticInterop
class DomXMLHttpRequest extends DomEventTarget {
  /// Constructor for [DomXMLHttpRequest].
  external factory DomXMLHttpRequest();
}

/// [DomXMLHttpRequest] extension.
extension DomXMLHttpRequestExtension on DomXMLHttpRequest {
  /// Gets the response.
  external JSAny? get response;

  @JS('responseText')
  external JSString? get _responseText;

  /// Gets the response text.
  String? get responseText => _responseText?.toDart;

  @JS('responseType')
  external JSString get _responseType;

  /// Gets the response type.
  String get responseType => _responseType.toDart;

  @JS('status')
  external JSNumber? get _status;

  /// Gets the status.
  int? get status => _status?.toDart.toInt();

  @JS('responseType')
  external set _responseType(final JSString value);

  /// Set the response type.
  set responseType(final String value) => _responseType = value.toJS;

  @JS('setRequestHeader')
  external void _setRequestHeader(final JSString header, final JSString value);

  /// Set the request header.
  void setRequestHeader(final String header, final String value) =>
      _setRequestHeader(header.toJS, value.toJS);

  @JS('open')
  external JSVoid _open(final JSString method, final JSString url, final JSBoolean isAsync);

  /// Open the request.
  void open(final String method, final String url, final bool isAsync) =>
      _open(method.toJS, url.toJS, isAsync.toJS);

  /// Send the request.
  external JSVoid send();
}

/// Type for event listener.
typedef DartDomEventListener = JSVoid Function(DomEvent event);

/// The type of [JSFunction] expected as an `EventListener`.
@JS()
@staticInterop
class DomEventListener {}

/// Creates a [DomEventListener] from a [DartDomEventListener].
DomEventListener createDomEventListener(final DartDomEventListener listener) =>
    listener.toJS as DomEventListener;

/// [DomEvent] interop object.
@JS()
@staticInterop
class DomEvent {}

/// [DomEvent] required extension.
extension DomEventExtension on DomEvent {
  @JS('type')
  external JSString get _type;

  /// Get the event type.
  String get type => _type.toDart;

  /// Initialize an event.
  external JSVoid initEvent(
      final JSString type, final JSBoolean bubbles, final JSBoolean cancelable);
}

/// [DomProgressEvent] interop object.
@JS()
@staticInterop
class DomProgressEvent extends DomEvent {}

/// [DomProgressEvent] required extension.
extension DomProgressEventExtension on DomProgressEvent {
  @JS('loaded')
  external JSNumber? get _loaded;

  /// Amount of work done.
  int? get loaded => _loaded?.toDart.toInt();

  @JS('total')
  external JSNumber? get _total;

  /// Total amount of work.
  int? get total => _total?.toDart.toInt();
}

/// The underlying DOM document.
@JS()
@staticInterop
class DomDocument {}

/// [DomDocument]'s required extension.
extension DomDocumentExtension on DomDocument {
  @JS('createEvent')
  external DomEvent _createEvent(final JSString eventType);

  /// Creates an event.
  DomEvent createEvent(final String eventType) => _createEvent(eventType.toJS);

  /// Creates a range.
  external DomRange createRange();

  /// Gets the head element.
  external DomHTMLHeadElement? get head;

  /// Creates a [DomElement].
  @JS('createElement')
  external DomElement createElement(final JSString name);
}

/// Returns the top level document.
@JS('window.document')
external DomDocument get domDocument;

/// Creates a new DOM event.
DomEvent createDomEvent(final String type, final String name) {
  final DomEvent event = domDocument.createEvent(type);
  event.initEvent(name.toJS, true.toJS, true.toJS);
  return event;
}

/// A Range object.
@JS()
@staticInterop
class DomRange {}

/// [DomRange]'s required extension.
extension DomRangeExtension on DomRange {
  /// Selects the provided node.
  external JSVoid selectNode(final DomNode node);
}

/// A node in the DOM.
@JS()
@staticInterop
class DomNode extends DomEventTarget {}

/// [DomNode]'s required extension.
extension DomNodeExtension on DomNode {
  @JS('innerText')
  external set _innerText(final JSString text);

  /// Sets the innerText of this node.
  set innerText(final String text) => _innerText = text.toJS;

  /// Appends a node this node.
  external JSVoid append(final DomNode node);
}

/// An element in the DOM.
@JS()
@staticInterop
class DomElement extends DomNode {}

/// [DomElement]'s required extension.
extension DomElementExtension on DomElement {
  /// Returns the style of this element.
  external DomCSSStyleDeclaration get style;

  /// Returns the class list of this element.
  external DomTokenList get classList;
}

/// An HTML element in the DOM.
@JS()
@staticInterop
class DomHTMLElement extends DomElement {}

/// A UI event.
@JS()
@staticInterop
class DomUIEvent extends DomEvent {}

/// A mouse event.
@JS()
@staticInterop
class DomMouseEvent extends DomUIEvent {}

/// [DomMouseEvent]'s required extension.
extension DomMouseEventExtension on DomMouseEvent {
  @JS('offsetX')
  external JSNumber get _offsetX;

  /// Returns the current x offset.
  num get offsetX => _offsetX.toDart;

  @JS('offsetY')
  external JSNumber get _offsetY;

  /// Returns the current y offset.
  num get offsetY => _offsetY.toDart;

  @JS('button')
  external JSNumber get _button;

  /// Returns the current button.
  int get button => _button.toDart.toInt();
}

/// A DOM selection.
@JS()
@staticInterop
class DomSelection {}

/// [DomSelection]'s required extension.
extension DomSelectionExtension on DomSelection {
  /// Removes all ranges from this selection.
  external JSVoid removeAllRanges();

  /// Adds a range to this selection.
  external JSVoid addRange(final DomRange range);
}

/// A DOM html div element.
@JS()
@staticInterop
class DomHTMLDivElement extends DomHTMLElement {}

/// Factory constructor for [DomHTMLDivElement].
DomHTMLDivElement createDomHTMLDivElement() =>
    domDocument.createElement('div'.toJS) as DomHTMLDivElement;

/// An html style element.
@JS()
@staticInterop
class DomHTMLStyleElement extends DomHTMLElement {}

/// [DomHTMLStyleElement]'s required extension.
extension DomHTMLStyleElementExtension on DomHTMLStyleElement {
  /// Get's the style sheet of this element.
  external DomStyleSheet? get sheet;
}

/// Factory constructor for [DomHTMLStyleElement].
DomHTMLStyleElement createDomHTMLStyleElement() =>
    domDocument.createElement('style'.toJS) as DomHTMLStyleElement;

/// CSS styles.
@JS()
@staticInterop
class DomCSSStyleDeclaration {}

/// [DomCSSStyleDeclaration]'s required extension.
extension DomCSSStyleDeclarationExtension on DomCSSStyleDeclaration {
  /// Sets the width.
  set width(final String value) => setProperty('width', value);

  /// Sets the height.
  set height(final String value) => setProperty('height', value);

  @JS('setProperty')
  external JSVoid _setProperty(
      final JSString propertyName, final JSString value, final JSString priority);

  /// Sets a CSS property by name.
  void setProperty(final String propertyName, final String value, [String? priority]) {
    priority ??= '';
    _setProperty(propertyName.toJS, value.toJS, priority.toJS);
  }
}

/// The HTML head element.
@JS()
@staticInterop
class DomHTMLHeadElement extends DomHTMLElement {}

/// A DOM style sheet.
@JS()
@staticInterop
class DomStyleSheet {}

/// A DOM CSS style sheet.
@JS()
@staticInterop
class DomCSSStyleSheet extends DomStyleSheet {}

/// [DomCSSStyleSheet]'s required extension.
extension DomCSSStyleSheetExtension on DomCSSStyleSheet {
  @JS('insertRule')
  external JSNumber _insertRule1(final JSString rule);

  @JS('insertRule')
  external JSNumber _insertRule2(final JSString rule, final JSNumber index);

  /// Inserts a rule into this style sheet.
  int insertRule(final String rule, [final int? index]) {
    if (index == null) {
      return _insertRule1(rule.toJS).toDart.toInt();
    } else {
      return _insertRule2(rule.toJS, index.toDouble().toJS).toDart.toInt();
    }
  }
}

/// A list of token.
@JS()
@staticInterop
class DomTokenList {}

/// [DomTokenList]'s required extension.
extension DomTokenListExtension on DomTokenList {
  @JS('add')
  external JSVoid _add(final JSString value);

  /// Adds a token to this token list.
  void add(final String value) => _add(value.toJS);
}
