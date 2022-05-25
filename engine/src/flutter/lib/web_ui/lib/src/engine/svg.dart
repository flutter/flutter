// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:js/js.dart';

import 'dom.dart';

@JS()
@staticInterop
class SVGElement extends DomElement {}

SVGElement createSVGElement(String tag) =>
    domDocument.createElementNS('http://www.w3.org/2000/svg', tag) as SVGElement;

@JS()
@staticInterop
class SVGGraphicsElement extends SVGElement {}

@JS()
@staticInterop
class SVGSVGElement extends SVGGraphicsElement {}

SVGSVGElement createSVGSVGElement() {
  final SVGElement el = createSVGElement('svg');
  el.setAttribute('version', '1.1');
  return el as SVGSVGElement;
}

@JS()
@staticInterop
class SVGClipPathElement extends SVGGraphicsElement {}

SVGClipPathElement createSVGClipPathElement() =>
    domDocument.createElementNS('http://www.w3.org/2000/svg', 'clipPath')
        as SVGClipPathElement;

@JS()
@staticInterop
class SVGDefsElement extends SVGGraphicsElement {}

SVGDefsElement createSVGDefsElement() =>
    domDocument.createElementNS('http://www.w3.org/2000/svg', 'defs')
        as SVGDefsElement;

@JS()
@staticInterop
class SVGGeometryElement extends SVGGraphicsElement {}

@JS()
@staticInterop
class SVGPathElement extends SVGGeometryElement {}

SVGPathElement createSVGPathElement() =>
    domDocument.createElementNS('http://www.w3.org/2000/svg', 'path')
        as SVGPathElement;
