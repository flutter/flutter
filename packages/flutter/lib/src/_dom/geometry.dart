// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

@JS('DOMPointReadOnly')
@staticInterop
class DOMPointReadOnly {
  external factory DOMPointReadOnly([
    num x,
    num y,
    num z,
    num w,
  ]);

  external static DOMPointReadOnly fromPoint([DOMPointInit other]);
}

extension DOMPointReadOnlyExtension on DOMPointReadOnly {
  external DOMPoint matrixTransform([DOMMatrixInit matrix]);
  external JSObject toJSON();
  external num get x;
  external num get y;
  external num get z;
  external num get w;
}

@JS('DOMPoint')
@staticInterop
class DOMPoint implements DOMPointReadOnly {
  external factory DOMPoint([
    num x,
    num y,
    num z,
    num w,
  ]);

  external static DOMPoint fromPoint([DOMPointInit other]);
}

extension DOMPointExtension on DOMPoint {
  external set x(num value);
  external num get x;
  external set y(num value);
  external num get y;
  external set z(num value);
  external num get z;
  external set w(num value);
  external num get w;
}

@JS()
@staticInterop
@anonymous
class DOMPointInit {
  external factory DOMPointInit({
    num x,
    num y,
    num z,
    num w,
  });
}

extension DOMPointInitExtension on DOMPointInit {
  external set x(num value);
  external num get x;
  external set y(num value);
  external num get y;
  external set z(num value);
  external num get z;
  external set w(num value);
  external num get w;
}

@JS('DOMRectReadOnly')
@staticInterop
class DOMRectReadOnly {
  external factory DOMRectReadOnly([
    num x,
    num y,
    num width,
    num height,
  ]);

  external static DOMRectReadOnly fromRect([DOMRectInit other]);
}

extension DOMRectReadOnlyExtension on DOMRectReadOnly {
  external JSObject toJSON();
  external num get x;
  external num get y;
  external num get width;
  external num get height;
  external num get top;
  external num get right;
  external num get bottom;
  external num get left;
}

@JS('DOMRect')
@staticInterop
class DOMRect implements DOMRectReadOnly {
  external factory DOMRect([
    num x,
    num y,
    num width,
    num height,
  ]);

  external static DOMRect fromRect([DOMRectInit other]);
}

extension DOMRectExtension on DOMRect {
  external set x(num value);
  external num get x;
  external set y(num value);
  external num get y;
  external set width(num value);
  external num get width;
  external set height(num value);
  external num get height;
}

@JS()
@staticInterop
@anonymous
class DOMRectInit {
  external factory DOMRectInit({
    num x,
    num y,
    num width,
    num height,
  });
}

extension DOMRectInitExtension on DOMRectInit {
  external set x(num value);
  external num get x;
  external set y(num value);
  external num get y;
  external set width(num value);
  external num get width;
  external set height(num value);
  external num get height;
}

@JS('DOMRectList')
@staticInterop
class DOMRectList {}

extension DOMRectListExtension on DOMRectList {
  external DOMRect? item(int index);
  external int get length;
}

@JS('DOMQuad')
@staticInterop
class DOMQuad {
  external factory DOMQuad([
    DOMPointInit p1,
    DOMPointInit p2,
    DOMPointInit p3,
    DOMPointInit p4,
  ]);

  external static DOMQuad fromRect([DOMRectInit other]);
  external static DOMQuad fromQuad([DOMQuadInit other]);
}

extension DOMQuadExtension on DOMQuad {
  external DOMRect getBounds();
  external JSObject toJSON();
  external DOMPoint get p1;
  external DOMPoint get p2;
  external DOMPoint get p3;
  external DOMPoint get p4;
}

@JS()
@staticInterop
@anonymous
class DOMQuadInit {
  external factory DOMQuadInit({
    DOMPointInit p1,
    DOMPointInit p2,
    DOMPointInit p3,
    DOMPointInit p4,
  });
}

extension DOMQuadInitExtension on DOMQuadInit {
  external set p1(DOMPointInit value);
  external DOMPointInit get p1;
  external set p2(DOMPointInit value);
  external DOMPointInit get p2;
  external set p3(DOMPointInit value);
  external DOMPointInit get p3;
  external set p4(DOMPointInit value);
  external DOMPointInit get p4;
}

@JS('DOMMatrixReadOnly')
@staticInterop
class DOMMatrixReadOnly {
  external factory DOMMatrixReadOnly([JSAny init]);

  external static DOMMatrixReadOnly fromMatrix([DOMMatrixInit other]);
  external static DOMMatrixReadOnly fromFloat32Array(JSFloat32Array array32);
  external static DOMMatrixReadOnly fromFloat64Array(JSFloat64Array array64);
}

extension DOMMatrixReadOnlyExtension on DOMMatrixReadOnly {
  external DOMMatrix translate([
    num tx,
    num ty,
    num tz,
  ]);
  external DOMMatrix scale([
    num scaleX,
    num scaleY,
    num scaleZ,
    num originX,
    num originY,
    num originZ,
  ]);
  external DOMMatrix scaleNonUniform([
    num scaleX,
    num scaleY,
  ]);
  external DOMMatrix scale3d([
    num scale,
    num originX,
    num originY,
    num originZ,
  ]);
  external DOMMatrix rotate([
    num rotX,
    num rotY,
    num rotZ,
  ]);
  external DOMMatrix rotateFromVector([
    num x,
    num y,
  ]);
  external DOMMatrix rotateAxisAngle([
    num x,
    num y,
    num z,
    num angle,
  ]);
  external DOMMatrix skewX([num sx]);
  external DOMMatrix skewY([num sy]);
  external DOMMatrix multiply([DOMMatrixInit other]);
  external DOMMatrix flipX();
  external DOMMatrix flipY();
  external DOMMatrix inverse();
  external DOMPoint transformPoint([DOMPointInit point]);
  external JSFloat32Array toFloat32Array();
  external JSFloat64Array toFloat64Array();
  external JSObject toJSON();
  external num get a;
  external num get b;
  external num get c;
  external num get d;
  external num get e;
  external num get f;
  external num get m11;
  external num get m12;
  external num get m13;
  external num get m14;
  external num get m21;
  external num get m22;
  external num get m23;
  external num get m24;
  external num get m31;
  external num get m32;
  external num get m33;
  external num get m34;
  external num get m41;
  external num get m42;
  external num get m43;
  external num get m44;
  external bool get is2D;
  external bool get isIdentity;
}

@JS('DOMMatrix')
@staticInterop
class DOMMatrix implements DOMMatrixReadOnly {
  external factory DOMMatrix([JSAny init]);

  external static DOMMatrix fromMatrix([DOMMatrixInit other]);
  external static DOMMatrix fromFloat32Array(JSFloat32Array array32);
  external static DOMMatrix fromFloat64Array(JSFloat64Array array64);
}

extension DOMMatrixExtension on DOMMatrix {
  external DOMMatrix multiplySelf([DOMMatrixInit other]);
  external DOMMatrix preMultiplySelf([DOMMatrixInit other]);
  external DOMMatrix translateSelf([
    num tx,
    num ty,
    num tz,
  ]);
  external DOMMatrix scaleSelf([
    num scaleX,
    num scaleY,
    num scaleZ,
    num originX,
    num originY,
    num originZ,
  ]);
  external DOMMatrix scale3dSelf([
    num scale,
    num originX,
    num originY,
    num originZ,
  ]);
  external DOMMatrix rotateSelf([
    num rotX,
    num rotY,
    num rotZ,
  ]);
  external DOMMatrix rotateFromVectorSelf([
    num x,
    num y,
  ]);
  external DOMMatrix rotateAxisAngleSelf([
    num x,
    num y,
    num z,
    num angle,
  ]);
  external DOMMatrix skewXSelf([num sx]);
  external DOMMatrix skewYSelf([num sy]);
  external DOMMatrix invertSelf();
  external DOMMatrix setMatrixValue(String transformList);
  external set a(num value);
  external num get a;
  external set b(num value);
  external num get b;
  external set c(num value);
  external num get c;
  external set d(num value);
  external num get d;
  external set e(num value);
  external num get e;
  external set f(num value);
  external num get f;
  external set m11(num value);
  external num get m11;
  external set m12(num value);
  external num get m12;
  external set m13(num value);
  external num get m13;
  external set m14(num value);
  external num get m14;
  external set m21(num value);
  external num get m21;
  external set m22(num value);
  external num get m22;
  external set m23(num value);
  external num get m23;
  external set m24(num value);
  external num get m24;
  external set m31(num value);
  external num get m31;
  external set m32(num value);
  external num get m32;
  external set m33(num value);
  external num get m33;
  external set m34(num value);
  external num get m34;
  external set m41(num value);
  external num get m41;
  external set m42(num value);
  external num get m42;
  external set m43(num value);
  external num get m43;
  external set m44(num value);
  external num get m44;
}

@JS()
@staticInterop
@anonymous
class DOMMatrix2DInit {
  external factory DOMMatrix2DInit({
    num a,
    num b,
    num c,
    num d,
    num e,
    num f,
    num m11,
    num m12,
    num m21,
    num m22,
    num m41,
    num m42,
  });
}

extension DOMMatrix2DInitExtension on DOMMatrix2DInit {
  external set a(num value);
  external num get a;
  external set b(num value);
  external num get b;
  external set c(num value);
  external num get c;
  external set d(num value);
  external num get d;
  external set e(num value);
  external num get e;
  external set f(num value);
  external num get f;
  external set m11(num value);
  external num get m11;
  external set m12(num value);
  external num get m12;
  external set m21(num value);
  external num get m21;
  external set m22(num value);
  external num get m22;
  external set m41(num value);
  external num get m41;
  external set m42(num value);
  external num get m42;
}

@JS()
@staticInterop
@anonymous
class DOMMatrixInit implements DOMMatrix2DInit {
  external factory DOMMatrixInit({
    num m13,
    num m14,
    num m23,
    num m24,
    num m31,
    num m32,
    num m33,
    num m34,
    num m43,
    num m44,
    bool is2D,
  });
}

extension DOMMatrixInitExtension on DOMMatrixInit {
  external set m13(num value);
  external num get m13;
  external set m14(num value);
  external num get m14;
  external set m23(num value);
  external num get m23;
  external set m24(num value);
  external num get m24;
  external set m31(num value);
  external num get m31;
  external set m32(num value);
  external num get m32;
  external set m33(num value);
  external num get m33;
  external set m34(num value);
  external num get m34;
  external set m43(num value);
  external num get m43;
  external set m44(num value);
  external num get m44;
  external set is2D(bool value);
  external bool get is2D;
}
