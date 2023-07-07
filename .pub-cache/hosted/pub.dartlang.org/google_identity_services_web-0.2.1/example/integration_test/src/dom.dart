// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;

@JS()
@staticInterop
class DomDocument {}

extension DomDocumentExtension on DomDocument {
  DomElement createElement(String name, [Object? options]) =>
      js_util.callMethod(this, 'createElement',
          <Object>[name, if (options != null) options]) as DomElement;
}

@JS()
@staticInterop
class DomElement {}

extension DomElementExtension on DomElement {
  external DomElement? querySelector(String selector);
}

@JS('document')
external DomDocument get domDocument;

DomElement createDomElement(String tag) => domDocument.createElement(tag);
