// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'dom.dart';

extension type SVGElement(JSObject _) implements JSObject, DomElement {}

SVGElement createSVGElement(String tag) =>
    domDocument.createElementNS('http://www.w3.org/2000/svg', tag) as SVGElement;

extension type SVGGraphicsElement(JSObject _) implements JSObject, SVGElement {}

extension type SVGSVGElement(JSObject _) implements JSObject, SVGGraphicsElement {
  external SVGNumber createSVGNumber();
  external SVGAnimatedLength? get height;
  external SVGAnimatedLength? get width;
}

SVGSVGElement createSVGSVGElement() {
  final SVGElement el = createSVGElement('svg');
  el.setAttribute('version', '1.1');
  return el as SVGSVGElement;
}

extension type SVGClipPathElement(JSObject _) implements JSObject, SVGGraphicsElement {}

SVGClipPathElement createSVGClipPathElement() =>
    domDocument.createElementNS('http://www.w3.org/2000/svg', 'clipPath') as SVGClipPathElement;

extension type SVGDefsElement(JSObject _) implements JSObject, SVGGraphicsElement {}

SVGDefsElement createSVGDefsElement() =>
    domDocument.createElementNS('http://www.w3.org/2000/svg', 'defs') as SVGDefsElement;

extension type SVGGeometryElement(JSObject _) implements JSObject, SVGGraphicsElement {}

extension type SVGPathElement(JSObject _) implements JSObject, SVGGeometryElement {}

SVGPathElement createSVGPathElement() =>
    domDocument.createElementNS('http://www.w3.org/2000/svg', 'path') as SVGPathElement;

extension type SVGFilterElement(JSObject _) implements JSObject, SVGElement {
  external SVGAnimatedEnumeration? get filterUnits;
  external SVGAnimatedLength? get height;
  external SVGAnimatedLength? get width;
  external SVGAnimatedLength? get x;
  external SVGAnimatedLength? get y;
}

SVGFilterElement createSVGFilterElement() =>
    domDocument.createElementNS('http://www.w3.org/2000/svg', 'filter') as SVGFilterElement;

extension type SVGAnimatedLength(JSObject _) implements JSObject {
  external SVGLength? get baseVal;
}

extension type SVGLength(JSObject _) implements JSObject {
  @JS('valueAsString')
  external set _valueAsString(JSString? value);
  set valueAsString(String? value) => _valueAsString = value?.toJS;

  @JS('newValueSpecifiedUnits')
  external JSVoid _newValueSpecifiedUnits(JSNumber unitType, JSNumber valueInSpecifiedUnits);
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) =>
      _newValueSpecifiedUnits(unitType.toJS, valueInSpecifiedUnits.toJS);
}

const int svgLengthTypeNumber = 1;

extension type SVGAnimatedEnumeration(JSObject _) implements JSObject {
  @JS('baseVal')
  external set _baseVal(JSNumber? value);
  set baseVal(int? value) => _baseVal = value?.toJS;
}

extension type SVGFEColorMatrixElement(JSObject _) implements JSObject, SVGElement {
  external SVGAnimatedEnumeration? get type;
  external SVGAnimatedString? get result;
  external SVGAnimatedNumberList? get values;
}

SVGFEColorMatrixElement createSVGFEColorMatrixElement() =>
    domDocument.createElementNS('http://www.w3.org/2000/svg', 'feColorMatrix')
        as SVGFEColorMatrixElement;

extension type SVGFEFloodElement(JSObject _) implements JSObject, SVGElement {
  external SVGAnimatedString? get result;
}

SVGFEFloodElement createSVGFEFloodElement() =>
    domDocument.createElementNS('http://www.w3.org/2000/svg', 'feFlood') as SVGFEFloodElement;

extension type SVGFEBlendElement(JSObject _) implements JSObject, SVGElement {
  external SVGAnimatedString? get in1;
  external SVGAnimatedString? get in2;
  external SVGAnimatedEnumeration? get mode;
}

SVGFEBlendElement createSVGFEBlendElement() =>
    domDocument.createElementNS('http://www.w3.org/2000/svg', 'feBlend') as SVGFEBlendElement;

extension type SVGFEImageElement(JSObject _) implements JSObject, SVGElement {
  external SVGAnimatedLength? get height;
  external SVGAnimatedLength? get width;
  external SVGAnimatedString? get result;
  external SVGAnimatedLength? get x;
  external SVGAnimatedLength? get y;
  external SVGAnimatedString? get href;
}

SVGFEImageElement createSVGFEImageElement() =>
    domDocument.createElementNS('http://www.w3.org/2000/svg', 'feImage') as SVGFEImageElement;

extension type SVGFECompositeElement(JSObject _) implements JSObject, SVGElement {
  external SVGAnimatedString? get in1;
  external SVGAnimatedString? get in2;
  external SVGAnimatedNumber? get k1;
  external SVGAnimatedNumber? get k2;
  external SVGAnimatedNumber? get k3;
  external SVGAnimatedNumber? get k4;
  external SVGAnimatedEnumeration? get operator;
  external SVGAnimatedString? get result;
}

SVGFECompositeElement createSVGFECompositeElement() =>
    domDocument.createElementNS('http://www.w3.org/2000/svg', 'feComposite')
        as SVGFECompositeElement;

extension type SVGAnimatedString(JSObject _) implements JSObject {
  external set _baseVal(JSString? value);
  set baseVal(String? value) => _baseVal = value?.toJS;
}

extension type SVGAnimatedNumber(JSObject _) implements JSObject {
  @JS('baseVal')
  external set _baseVal(JSNumber? value);
  set baseVal(num? value) => _baseVal = value?.toJS;
}

extension type SVGAnimatedNumberList(JSObject _) implements JSObject {
  external SVGNumberList? get baseVal;
}

extension type SVGNumberList(JSObject _) implements JSObject {
  external SVGNumber appendItem(SVGNumber newItem);
}

extension type SVGNumber(JSObject _) implements JSObject {
  @JS('value')
  external set _value(JSNumber? value);
  set value(num? v) => _value = v?.toJS;
}
