// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;

/// This file includes static interop helpers for Flutter Web.
// TODO(joshualitt): This file will eventually be removed,
// https://github.com/flutter/flutter/issues/113402.

/// [DomWindow] interop object.
@JS()
@staticInterop
class DomWindow {}

/// [DomWindow] required extension.
extension DomWindowExtension on DomWindow {
  /// Returns a [DomMediaQueryList] of the media that matches [query].
  external DomMediaQueryList matchMedia(String? query);

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
  /// Whether or not the query matched.
  external bool get matches;
}

/// [DomNavigator] interop object.
@JS()
@staticInterop
class DomNavigator {}

/// [DomNavigator] required extension.
extension DomNavigatorExtension on DomNavigator {
  /// The underyling platform string.
  external String? get platform;
}

/// A DOM event target.
@JS()
@staticInterop
class DomEventTarget {}

/// [DomEventTarget]'s required extension.
extension DomEventTargetExtension on DomEventTarget {
  /// Adds an event listener to this event target.
  void addEventListener(String type, DomEventListener? listener,
      [bool? useCapture]) {
    if (listener != null) {
      js_util.callMethod(this, 'addEventListener',
          <Object>[type, listener, if (useCapture != null) useCapture]);
    }
  }
}

/// [DomXMLHttpRequest] interop class.
@JS()
@staticInterop
class DomXMLHttpRequest extends DomEventTarget {}

/// [DomXMLHttpRequest] extension.
extension DomXMLHttpRequestExtension on DomXMLHttpRequest {
  /// Gets the response.
  external dynamic get response;

  /// Gets the response text.
  external String? get responseText;

  /// Gets the response type.
  external String get responseType;

  /// Gets the status.
  external int? get status;

  /// Set the response type.
  external set responseType(String value);

  /// Set the request header.
  external void setRequestHeader(String header, String value);

  /// Open the request.
  void open(String method, String url, bool isAsync) => js_util.callMethod(
      this, 'open', <Object>[method, url, isAsync]);

  /// Send the request.
  void send() => js_util.callMethod(this, 'send', <Object>[]);
}

/// Factory function for creating [DomXMLHttpRequest].
DomXMLHttpRequest createDomXMLHttpRequest() =>
    domCallConstructorString('XMLHttpRequest', <Object?>[])!
        as DomXMLHttpRequest;

/// Type for event listener.
typedef DomEventListener = void Function(DomEvent event);

/// [DomEvent] interop object.
@JS()
@staticInterop
class DomEvent {}

/// [DomEvent] required extension.
extension DomEventExtension on DomEvent {
  /// Get the event type.
  external String get type;

  /// Initialize an event.
  void initEvent(String type, [bool? bubbles, bool? cancelable]) =>
      js_util.callMethod(this, 'initEvent', <Object>[
        type,
        if (bubbles != null) bubbles,
        if (cancelable != null) cancelable
      ]);
}

/// [DomProgressEvent] interop object.
@JS()
@staticInterop
class DomProgressEvent extends DomEvent {}

/// [DomProgressEvent] required extension.
extension DomProgressEventExtension on DomProgressEvent {
  /// Amount of work done.
  external int? get loaded;

  /// Total amount of work.
  external int? get total;
}

/// Gets a constructor from a [String].
Object? domGetConstructor(String constructorName) =>
    js_util.getProperty(domWindow, constructorName);

/// Calls a constructor as a [String].
Object? domCallConstructorString(String constructorName, List<Object?> args) {
  final Object? constructor = domGetConstructor(constructorName);
  if (constructor == null) {
    return null;
  }
  return js_util.callConstructor(constructor, args);
}

/// The underlying DOM document.
@JS()
@staticInterop
class DomDocument {}

/// [DomDocument]'s required extension.
extension DomDocumentExtension on DomDocument {
  /// Creates an event.
  external DomEvent createEvent(String eventType);

  /// Creates a range.
  external DomRange createRange();

  /// Gets the head element.
  external DomHTMLHeadElement? get head;

  /// Creates a new element.
  DomElement createElement(String name, [Object? options]) =>
      js_util.callMethod(this, 'createElement',
          <Object>[name, if (options != null) options]) as DomElement;
}

/// Returns the top level document.
@JS('window.document')
external DomDocument get domDocument;

/// Creates a new DOM event.
DomEvent createDomEvent(String type, String name) {
  final DomEvent event = domDocument.createEvent(type);
  event.initEvent(name, true, true);
  return event;
}

/// Defines a new property on an Object.
@JS('Object.defineProperty')
external void objectDefineProperty(Object o, String symbol, dynamic desc);

/// A Range object.
@JS()
@staticInterop
class DomRange {}

/// [DomRange]'s required extension.
extension DomRangeExtension on DomRange {
  /// Selects the provided node.
  external void selectNode(DomNode node);
}

/// A node in the DOM.
@JS()
@staticInterop
class DomNode extends DomEventTarget {}

/// [DomNode]'s required extension.
extension DomNodeExtension on DomNode {
  /// Sets the innerText of this node.
  external set innerText(String text);

  /// Appends a node this node.
  external void append(DomNode node);
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
  /// Returns the current x offset.
  external num get offsetX;

  /// Returns the current y offset.
  external num get offsetY;

  /// Returns the current button.
  external int get button;
}

/// A DOM selection.
@JS()
@staticInterop
class DomSelection {}

/// [DomSelection]'s required extension.
extension DomSelectionExtension on DomSelection {
  /// Removes all ranges from this selection.
  external void removeAllRanges();

  /// Adds a range to this selection.
  external void addRange(DomRange range);
}

/// A DOM html div element.
@JS()
@staticInterop
class DomHTMLDivElement extends DomHTMLElement {}

/// Factory constructor for [DomHTMLDivElement].
DomHTMLDivElement createDomHTMLDivElement() =>
    domDocument.createElement('div') as DomHTMLDivElement;

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
    domDocument.createElement('style') as DomHTMLStyleElement;

/// CSS styles.
@JS()
@staticInterop
class DomCSSStyleDeclaration {}

/// [DomCSSStyleDeclaration]'s required extension.
extension DomCSSStyleDeclarationExtension on DomCSSStyleDeclaration {
  /// Sets the width.
  set width(String value) => setProperty('width', value);

  /// Sets the height.
  set height(String value) => setProperty('height', value);

  /// Sets a CSS property by name.
  void setProperty(String propertyName, String value, [String? priority]) {
    priority ??= '';
    js_util.callMethod(
        this, 'setProperty', <Object>[propertyName, value, priority]);
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
  /// Inserts a rule into this style sheet.
  int insertRule(String rule, [int? index]) =>
    js_util.callMethod<double>(this, 'insertRule', <Object>[
      rule,
      if (index != null) index.toDouble()
    ]).toInt();
}

/// A list of token.
@JS()
@staticInterop
class DomTokenList {}

/// [DomTokenList]'s required extension.
extension DomTokenListExtension on DomTokenList {
  /// Adds a token to this token list.
  external void add(String value);
}
