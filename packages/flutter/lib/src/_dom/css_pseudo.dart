// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'cssom_view.dart';
import 'dom.dart';
import 'geometry.dart';

@JS('CSSPseudoElement')
@staticInterop
class CSSPseudoElement implements EventTarget {}

extension CSSPseudoElementExtension on CSSPseudoElement {
  external CSSPseudoElement? pseudo(String type);
  external JSArray getBoxQuads([BoxQuadOptions options]);
  external DOMQuad convertQuadFromNode(
    DOMQuadInit quad,
    GeometryNode from, [
    ConvertCoordinateOptions options,
  ]);
  external DOMQuad convertRectFromNode(
    DOMRectReadOnly rect,
    GeometryNode from, [
    ConvertCoordinateOptions options,
  ]);
  external DOMPoint convertPointFromNode(
    DOMPointInit point,
    GeometryNode from, [
    ConvertCoordinateOptions options,
  ]);
  external String get type;
  external Element get element;
  external JSObject get parent;
}
