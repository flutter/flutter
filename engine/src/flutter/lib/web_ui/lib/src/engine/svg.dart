// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:js/js.dart';

import 'dom.dart';

@JS()
@staticInterop
class SVGElement extends DomElement {}

SVGElement createSVGElement(String tag) =>
    domDocument.createElementNS('http://www.w3.org/2000/svg', tag)
        as SVGElement;

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

extension SVGSVGElementExtension on SVGSVGElement {
  external SVGNumber createSVGNumber();
  external SVGAnimatedLength? get height;
  external SVGAnimatedLength? get width;
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

@JS()
@staticInterop
class SVGFilterElement extends SVGElement {}

extension SVGFilterElementExtension on SVGFilterElement {
  external SVGAnimatedEnumeration? get filterUnits;
  external SVGAnimatedLength? get height;
  external SVGAnimatedLength? get width;
  external SVGAnimatedLength? get x;
  external SVGAnimatedLength? get y;
}

SVGFilterElement createSVGFilterElement() =>
    domDocument.createElementNS('http://www.w3.org/2000/svg', 'filter')
        as SVGFilterElement;

@JS()
@staticInterop
class SVGAnimatedLength {}

extension SVGAnimatedLengthExtension on SVGAnimatedLength {
  external SVGLength? get baseVal;
}

@JS()
@staticInterop
class SVGLength {}

extension SVGLengthExtension on SVGLength {
  external set valueAsString(String? value);
  external void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits);
}

const int svgLengthTypeNumber = 1;

@JS()
@staticInterop
class SVGAnimatedEnumeration {}

extension SVGAnimatedEnumerationExtenson on SVGAnimatedEnumeration {
  external set baseVal(int? value);
}

@JS()
@staticInterop
class SVGFEColorMatrixElement extends SVGElement {}

extension SVGFEColorMatrixElementExtension on SVGFEColorMatrixElement {
  external SVGAnimatedEnumeration? get type;
  external SVGAnimatedString? get result;
  external SVGAnimatedNumberList? get values;
}

SVGFEColorMatrixElement createSVGFEColorMatrixElement() =>
    domDocument.createElementNS('http://www.w3.org/2000/svg', 'feColorMatrix')
        as SVGFEColorMatrixElement;

@JS()
@staticInterop
class SVGFEFloodElement extends SVGElement {}

extension SVGFEFloodElementExtension on SVGFEFloodElement {
  external SVGAnimatedString? get result;
}

SVGFEFloodElement createSVGFEFloodElement() =>
    domDocument.createElementNS('http://www.w3.org/2000/svg', 'feFlood')
        as SVGFEFloodElement;

@JS()
@staticInterop
class SVGFEBlendElement extends SVGElement {}

extension SVGFEBlendElementExtension on SVGFEBlendElement {
  external SVGAnimatedString? get in1;
  external SVGAnimatedString? get in2;
  external SVGAnimatedEnumeration? get mode;
}

SVGFEBlendElement createSVGFEBlendElement() =>
    domDocument.createElementNS('http://www.w3.org/2000/svg', 'feBlend')
        as SVGFEBlendElement;

@JS()
@staticInterop
class SVGFEImageElement extends SVGElement {}

extension SVGFEImageElementExtension on SVGFEImageElement {
  external SVGAnimatedLength? get height;
  external SVGAnimatedLength? get width;
  external SVGAnimatedString? get result;
  external SVGAnimatedLength? get x;
  external SVGAnimatedLength? get y;
  external SVGAnimatedString? get href;
}

SVGFEImageElement createSVGFEImageElement() =>
    domDocument.createElementNS('http://www.w3.org/2000/svg', 'feImage')
        as SVGFEImageElement;

@JS()
@staticInterop
class SVGFECompositeElement extends SVGElement {}

SVGFECompositeElement createSVGFECompositeElement() =>
    domDocument.createElementNS('http://www.w3.org/2000/svg', 'feComposite')
        as SVGFECompositeElement;

extension SVGFEBlendCompositeExtension on SVGFECompositeElement {
  external SVGAnimatedString? get in1;
  external SVGAnimatedString? get in2;
  external SVGAnimatedNumber? get k1;
  external SVGAnimatedNumber? get k2;
  external SVGAnimatedNumber? get k3;
  external SVGAnimatedNumber? get k4;
  external SVGAnimatedEnumeration? get operator;
  external SVGAnimatedString? get result;
}

@JS()
@staticInterop
class SVGAnimatedString {}

extension SVGAnimatedStringExtension on SVGAnimatedString {
  external set baseVal(String? value);
}

@JS()
@staticInterop
class SVGAnimatedNumber {}

extension SVGAnimatedNumberExtension on SVGAnimatedNumber {
  external set baseVal(num? value);
}

@JS()
@staticInterop
class SVGAnimatedNumberList {}

extension SVGAnimatedNumberListExtension on SVGAnimatedNumberList {
  external SVGNumberList? get baseVal;
}

@JS()
@staticInterop
class SVGNumberList {}

extension SVGNumberListExtension on SVGNumberList {
  external SVGNumber appendItem(SVGNumber newItem);
}

@JS()
@staticInterop
class SVGNumber {}

extension SVGNumberExtension on SVGNumber {
  external set value(num? value);
}
