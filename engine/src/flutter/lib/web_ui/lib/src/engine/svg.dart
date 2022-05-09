// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:js/js.dart';

import 'dom.dart';

@JS()
@staticInterop
class SVGElement extends DomElement {}

@JS()
@staticInterop
class SVGGraphicsElement extends SVGElement {}

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
