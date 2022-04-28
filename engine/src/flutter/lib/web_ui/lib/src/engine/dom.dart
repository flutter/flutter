// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;

@JS()
@staticInterop
class DomWindow {}

extension DomWindowExtension on DomWindow {
  external DomDocument get document;
}

@JS('window')
external DomWindow get domWindow;

@JS()
@staticInterop
class DomDocument {}

extension DomDocumentExtension on DomDocument {
  external /* List<Node> */ List<Object?> querySelectorAll(String selectors);
}

@JS()
@staticInterop
class DomEventTarget {}

@JS()
@staticInterop
class DomNode extends DomEventTarget {}

@JS()
@staticInterop
class DomHTMLElement extends DomNode {}

@JS()
@staticInterop
class DomHTMLMetaElement {}

extension DomHTMLMetaElementExtension on DomHTMLMetaElement {
  external String get name;
  external String get content;
  external set name(String value);
}

Object? domGetConstructor(String constructorName) =>
    js_util.getProperty(domWindow, constructorName);

bool domInstanceOfString(Object? element, String objectType) =>
    js_util.instanceof(element, domGetConstructor(objectType)!);
