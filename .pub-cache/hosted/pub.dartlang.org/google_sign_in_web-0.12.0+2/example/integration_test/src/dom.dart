// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/*
// DOM shim. This file contains everything we need from the DOM API written as
// @staticInterop, so we don't need dart:html
// https://developer.mozilla.org/en-US/docs/Web/API/
//
// (To be replaced by `package:web`)
*/

import 'package:js/js.dart';

/// Document interface
@JS()
@staticInterop
abstract class DomHtmlDocument {}

/// Some methods of document
extension DomHtmlDocumentExtension on DomHtmlDocument {
  /// document.head
  external DomHtmlElement get head;

  /// document.createElement
  external DomHtmlElement createElement(String tagName);

  /// document.querySelector
  external DomHtmlElement? querySelector(String selector);
}

/// An instance of an HTMLElement
@JS()
@staticInterop
abstract class DomHtmlElement {}

/// (Some) methods of HtmlElement
extension DomHtmlElementExtension on DomHtmlElement {
  external String get id;
  external set id(String id);
  external set innerText(String innerText);
  external String? getAttribute(String attributeName);

  /// Node.appendChild
  external DomHtmlElement appendChild(DomHtmlElement child);

  /// Element.setAttribute
  external void setAttribute(String name, Object value);

  /// Element.remove
  external void remove();
}

/// An instance of an HTMLMetaElement
@JS()
@staticInterop
abstract class DomHtmlMetaElement extends DomHtmlElement {}

/// Some methods exclusive of Script elements
extension DomHtmlMetaElementExtension on DomHtmlMetaElement {
  external set name(String name);
  external set content(String content);
}

// Getters

/// window.document
@JS()
@staticInterop
external DomHtmlDocument get document;
