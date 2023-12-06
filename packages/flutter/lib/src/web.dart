// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A stripped down version of `package:web` to avoid pinning that repo in
/// Flutter as a dependency.
///
/// This should stay in sync with `package:web` as much as possible to make it
/// easier to add new members as needed.
library;

import 'dart:js_interop';

typedef EventListener = JSFunction;
typedef XMLHttpRequestResponseType = String;

@JS()
external Document get document;

@JS()
external Window get window;

@JS('CSSStyleDeclaration')
@staticInterop
class CSSStyleDeclaration {}

extension CSSStyleDeclarationExtension on CSSStyleDeclaration {
  external set height(String value);
  external String get height;
  external set width(String value);
  external String get width;
}
@JS('CSSStyleSheet')
@staticInterop
class CSSStyleSheet {}

extension CSSStyleSheetExtension on CSSStyleSheet {
  external int insertRule(
    String rule, [
    int index,
  ]);
}

@JS('Document')
@staticInterop
class Document implements Node {}

extension DocumentExtension on Document {
  external Element createElement(
    String localName, [
    JSAny options,
  ]);
  external Range createRange();
  external HTMLHeadElement? get head;
}

@JS('DOMTokenList')
@staticInterop
class DOMTokenList {}

extension DOMTokenListExtension on DOMTokenList {
  external void add(String tokens);
}

@JS('Element')
@staticInterop
class Element implements Node {}

extension ElementExtension on Element {
  external DOMTokenList get classList;
  external void append(JSAny nodes);
}

@JS('Event')
@staticInterop
class Event {}

@JS('EventTarget')
@staticInterop
class EventTarget {}

extension EventTargetExtension on EventTarget {
  external void addEventListener(
    String type,
    EventListener? callback, [
    JSAny options,
  ]);
}

@JS('HTMLElement')
@staticInterop
class HTMLElement implements Element {}

extension HTMLElementExtension on HTMLElement {
  external set innerText(String value);
  external CSSStyleDeclaration get style;
}

@JS('HTMLHeadElement')
@staticInterop
class HTMLHeadElement implements HTMLElement {}

@JS('HTMLStyleElement')
@staticInterop
class HTMLStyleElement implements HTMLElement {}

extension HTMLStyleElementExtension on HTMLStyleElement {
  external CSSStyleSheet? get sheet;
}

@JS('MediaQueryList')
@staticInterop
class MediaQueryList {}

extension MediaQueryListExtension on MediaQueryList {
  external bool get matches;
}

@JS('MouseEvent')
@staticInterop
class MouseEvent {}

extension MouseEventExtension on MouseEvent {
  external num get offsetX;
  external num get offsetY;
  external int get button;
}

@JS('Navigator')
@staticInterop
class Navigator {}

extension NavigatorExtension on Navigator {
  external String get platform;
}

@JS('Node')
@staticInterop
class Node implements EventTarget {}

@JS('Range')
@staticInterop
class Range {}

extension RangeExtension on Range {
  external void selectNode(Node node);
}

@JS('Selection')
@staticInterop
class Selection {}

extension SelectionExtension on Selection {
  external void addRange(Range range);
  external void removeAllRanges();
}

@JS('Window')
@staticInterop
class Window {}

extension WindowExtension on Window {
  external Navigator get navigator;
  external MediaQueryList matchMedia(String query);
  external Selection? getSelection();
}

@JS('XMLHttpRequest')
@staticInterop
class XMLHttpRequest implements XMLHttpRequestEventTarget {}

extension XMLHttpRequestExtension on XMLHttpRequest {
  external void open(
    String method,
    String url, [
    bool async,
    String? username,
    String? password,
  ]);
  external void setRequestHeader(
    String name,
    String value,
  );
  external void send([JSAny? body]);
  external int get status;
  external set responseType(XMLHttpRequestResponseType value);
  external XMLHttpRequestResponseType get responseType;
  external JSAny? get response;
}

@JS('XMLHttpRequestEventTarget')
@staticInterop
class XMLHttpRequestEventTarget implements EventTarget {}
