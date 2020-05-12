// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';

final SimdMatrix4 _identityMatrix = SimdMatrix4(
  1, 0, 0, 0,
  0, 1, 0, 0,
  0, 0, 1, 0,
  0, 0, 0, 1
);

/// A matrix4 implementation backed by Float32x4 SIMD data types.
class SimdMatrix4 {
  /// Create a new Matrix4.
  factory SimdMatrix4(
    double a0,
    double a1,
    double a2,
    double a3,
    double b0,
    double b1,
    double b2,
    double b3,
    double c0,
    double c1,
    double c2,
    double c3,
    double d0,
    double d1,
    double d2,
    double d3,
  ) {
    return SimdMatrix4._(
      Float32x4(a0, b0, c0, d0),
      Float32x4(a1, b1, c1, d1),
      Float32x4(a2, b2, c2, d2),
      Float32x4(a3, b3, c3, d3),
    );
  }

  /// Create a new [SimdMatrix4] from a vector math package [Matrix4].
  factory SimdMatrix4.fromVectorMath(Matrix4 matrix4) {
    final Float64List storage = matrix4.storage;
    return SimdMatrix4._(
      Float32x4(storage[0],   storage[1],    storage[2],  storage[3]),
      Float32x4(storage[4],   storage[5],    storage[6],  storage[7]),
      Float32x4(storage[8],   storage[9],   storage[10],  storage[11]),
      Float32x4(storage[12],  storage[13],  storage[14],  storage[15]),
    );
  }

  SimdMatrix4._(this._column0, this._column1, this._column2, this._column3);

  /// The identity matrix.
  static final SimdMatrix4 identity = _identityMatrix;

  final Float32x4 _column0;
  final Float32x4 _column1;
  final Float32x4 _column2;
  final Float32x4 _column3;

  Float32List toFloatList() {
    final Float32List buffer = Float32List(16);
    final Float32x4List temp = buffer.buffer.asFloat32x4List();
    temp[3] = _column3;
    temp[2] = _column2;
    temp[1] = _column1;
    temp[0] = _column0;
    return buffer;
  }

  /// Multiply this matrix by [other], producing a new Matrix.
  ///
  /// Taken from an archived dart.dev website post about SIMD from
  /// 2012.
  SimdMatrix4 operator *(SimdMatrix4 other) {
    final Float32x4 a0 = _column0;
    final Float32x4 a1 = _column1;
    final Float32x4 a2 = _column2;
    final Float32x4 a3 = _column3;

    final Float32x4 b0 = other._column0;
    final Float32x4 result0 = b0.shuffle(Float32x4.xxxx) * a0 +
        b0.shuffle(Float32x4.yyyy) * a1 +
        b0.shuffle(Float32x4.zzzz) * a2 +
        b0.shuffle(Float32x4.wwww) * a3;
    final Float32x4 b1 = other._column1;
    final Float32x4 result1 = b1.shuffle(Float32x4.xxxx) * a0 +
        b1.shuffle(Float32x4.yyyy) * a1 +
        b1.shuffle(Float32x4.zzzz) * a2 +
        b1.shuffle(Float32x4.wwww) * a3;
    final Float32x4 b2 = other._column2;
    final Float32x4 result2 = b2.shuffle(Float32x4.xxxx) * a0 +
        b2.shuffle(Float32x4.yyyy) * a1 +
        b2.shuffle(Float32x4.zzzz) * a2 +
        b2.shuffle(Float32x4.wwww) * a3;
    final Float32x4 b3 = other._column3;
    final Float32x4 result3 = b3.shuffle(Float32x4.xxxx) * a0 +
        b3.shuffle(Float32x4.yyyy) * a1 +
        b3.shuffle(Float32x4.zzzz) * a2 +
        b3.shuffle(Float32x4.wwww) * a3;
    return SimdMatrix4._(result0, result1, result2, result3);
  }

  /// An implementation of matrix inversion based on
  /// https://www.geometrictools.com/Documentation/LaplaceExpansionTheorem.pdf
  SimdMatrix4 invert() {
    // Given the 4x4 matrix below:
    //
    //  [ a00 a01 a02 a03 ]
    //  [ a10 a11 a12 a13 ]
    //  [ a20 a21 a22 a23 ]
    //  [ a30 a31 a32 a33 ]
    //
    // First, compute the determinants of the 12 2x2 sub-matrices:
    //
    // s0 = [ a00 a01 ]
    //      [ a10 a11 ]
    //
    // s1 = [ a00 a02 ]
    //      [ a10 a12 ]
    //
    // s2 = [ a00 a03 ]
    //      [ a10 a13 ]
    //
    // s3 = [ a01 a02 ]
    //      [ a11 a12 ]
    //
    // s4 = [ a01 a03 ]
    //      [ a11 a13 ]
    //
    // s5 = [ a02 a03 ]
    //      [ a12 a13 ]
    //
    // c5 = [ a22 a23 ]
    //      [ a32 a33 ]
    //
    // c4 = [ a21 a23 ]
    //      [ a31 a33 ]
    //
    // c3 = [ a21 a22 ]
    //      [ a31 a32 ]
    //
    // c2 = [ a20 a23 ]
    //      [ a30 a33 ]
    //
    // c1 = [ a20 a22 ]
    //      [ a30 a32 ]
    //
    // c0 = [ a20 a21 ]
    //      [ a30 a31 ]

    // Using SIMD operations we can compute the determinant
    // for the upper half `sn` and the lower half `cn` at the
    // same time. In the resulting multiplication and shuffle,
    // the determinant of `sn` ends up in lane `x` and the
    // determinant of `cn` ends up in lane `z`.

    // Preprocessing
    final Float32x4 col0Process = _column0.shuffle(Float32x4.yxwz);
    final Float32x4 col1Process = _column1.shuffle(Float32x4.yxwz);
    final Float32x4 col2Process = _column2.shuffle(Float32x4.yxwz);
    final Float32x4 col3Process = _column3.shuffle(Float32x4.yxwz);

    // Compute s0 and c0.
    Float32x4 tmp1 = _column0 * col1Process;
    final Float32x4 s0c0 = tmp1 - tmp1.shuffle(Float32x4.yyww);

    // Compute s1 and c1
    tmp1 = _column0 * col2Process;
    final Float32x4 s1c1 = tmp1 - tmp1.shuffle(Float32x4.yyww);

    // Compute s2 and c2
    tmp1 = _column0 * col3Process;
    final Float32x4 s2c2 = tmp1 - tmp1.shuffle(Float32x4.yyww);

    // Compute s3 and c3
    tmp1 = _column1 * col2Process;
    final Float32x4 s3c3 = tmp1 - tmp1.shuffle(Float32x4.yyww);

    // Compute s4 and c4
    tmp1 = _column1 * col3Process;
    final Float32x4 s4c4 = tmp1 - tmp1.shuffle(Float32x4.yyww);

    // Compute s5 and c5
    tmp1 = _column2 * col3Process;
    final Float32x4 s5c5 = tmp1 - tmp1.shuffle(Float32x4.yyww);

    // The determinant of `A` can then be computed from the equation:
    // s0c5 - s1c4 + s2c3 + s3c2 - s4c1 + s5c0
    final Float32x4 detA =
      s0c0.shuffle(Float32x4.xxxx) * s5c5.shuffle(Float32x4.zzzz) -
      s1c1.shuffle(Float32x4.xxxx) * s4c4.shuffle(Float32x4.zzzz) +
      s2c2.shuffle(Float32x4.xxxx) * s3c3.shuffle(Float32x4.zzzz) +
      s3c3.shuffle(Float32x4.xxxx) * s2c2.shuffle(Float32x4.zzzz) -
      s4c4.shuffle(Float32x4.xxxx) * s1c1.shuffle(Float32x4.zzzz) +
      s5c5.shuffle(Float32x4.xxxx) * s0c0.shuffle(Float32x4.zzzz);

    // Compute the inverse of the determinant.
    final Float32x4 invDetA = detA.reciprocal();

    // The rows of the adjugate are treated as if they were columns,
    // and then transposed at the end.

    // Preprocessing
    final Float32x4 neg0 = Float32x4(1, -1, 1, -1);
    final Float32x4 neg1 = Float32x4(-1, 1, -1, 1);
    final Float32x4 s0c0Process = s0c0.shuffle(Float32x4.zzxx);
    final Float32x4 s1c1Process = s1c1.shuffle(Float32x4.zzxx);
    final Float32x4 s2c2Process = s2c2.shuffle(Float32x4.zzxx);
    final Float32x4 s3c3Process = s3c3.shuffle(Float32x4.zzxx);
    final Float32x4 s4c4Process = s4c4.shuffle(Float32x4.zzxx);
    final Float32x4 s5c5Process = s5c5.shuffle(Float32x4.zzxx);

    // Row 1
    tmp1 = col1Process * neg0 * s5c5Process;
    Float32x4 tmp2 = col2Process * neg1 * s4c4Process;
    Float32x4 tmp3 = col3Process * neg0 * s3c3Process;
    final Float32x4 row0 = (tmp1 + tmp2 + tmp3) * invDetA;

    // Row 2
    tmp1 = col0Process * neg1 * s5c5Process;
    tmp2 = col2Process * neg0 * s2c2Process;
    tmp3 = col3Process * neg1 * s1c1Process;
    final Float32x4 row1 = (tmp1 + tmp2 + tmp3) * invDetA;

    // Row 3
    tmp1 = col0Process * neg0 * s4c4Process;
    tmp2 = col1Process * neg1 * s2c2Process;
    tmp3 = col3Process * neg0 * s0c0Process;
    final Float32x4 row2 = (tmp1 + tmp2 + tmp3) * invDetA;

    // Row 4
    tmp1 = col0Process * neg1 * s3c3Process;
    tmp2 = col1Process * neg0 * s1c1Process;
    tmp3 = col2Process * neg1 * s0c0Process;
    final Float32x4 row3 = (tmp1 + tmp2 + tmp3)* invDetA;

    // ARM was a transpose op that would shorten this
    // to 3 transposes.
    return SimdMatrix4._(
      Float32x4(row0.x, row1.x, row2.x, row3.x),
      Float32x4(row0.y, row1.y, row2.y, row3.y),
      Float32x4(row0.z, row1.z, row2.z, row3.z),
      Float32x4(row0.w, row1.w, row2.w, row3.w),
    );
  }
}

/// An implementation of SIMD matrix utilities to replace [MatrixUtils].
class SimdMatrixUtils {
  // This class is not meant to be instatiated or extended; this constructor
  // prevents instantiation and extension.
  // ignore: unused_element
  SimdMatrixUtils._();

  /// Returns true if the given matrices are exactly equal, and false
  /// otherwise. Null values are assumed to be the identity matrix.
  static bool matrixEquals(SimdMatrix4 a, SimdMatrix4 b) {
    final Int32x4 col0Equals = a._column0.equal(b._column0);
    final Int32x4 col1Equals = a._column1.equal(b._column1);
    final Int32x4 col2Equals = a._column2.equal(b._column2);
    final Int32x4 col3Equals = a._column3.equal(b._column3);
    final Int32x4 temp = col0Equals & col1Equals & col2Equals & col3Equals;

    // This command is not efficient on ARM.
    return temp.signMask == 15;
  }

  /// Returns a rect that bounds the result of applying the given matrix as a
  /// perspective transform to the given rect.
  static Rect transformRect(SimdMatrix4 transform, Rect rect) {
    // Convert the rect into an efficient SIMD representation using a 4x4
    // matrix.
    final SimdMatrix4 points = SimdMatrix4(
      rect.left,  rect.top,    0, 1,
      rect.left,  rect.bottom, 0, 1,
      rect.right, rect.top,    0, 1,
      rect.right, rect.bottom, 0, 1,
    );
    final SimdMatrix4 result = transform * points;
    return Rect.fromLTRB(
      result._column0.x,
      result._column0.y,
      result._column2.x,
      result._column3.y,
    );
  }

  /// Applies the given matrix as a perspective transform to the given point.
  ///
  /// This function assumes the given point has a z-coordinate of 0.0. The
  /// z-coordinate of the result is ignored.
  static Offset transformPoint(SimdMatrix4 transform, Offset point) {
    // Given the transform matrix M and an offset P, the offset can
    // be expanded to a 1-dimensional vector: [x, y, 0, 0]. The transformation
    // can be applied by multiply it by this vector, which expands to:
    //
    //  M * [ x, y, 0, 1 ]
    //
    //  [a00 * x + a01 * y + a02 * z + a03 * w ]
    //  [a10 * x + a11 * y + a12 * z + a13 * w ]
    //  [a20 * x + a21 * y + a22 * z + a23 * w ]
    //  [a30 * x + a31 * y + a32 * z + a33 * w ]
    //
    // Which given z = 0 and w = 1 simplifies to:
    //
    //  [a00 * x + a01 * y + a03]
    //  [a10 * x + a11 * y + a13]
    //  [a20 * x + a21 * y + a23]
    //  [a30 * x + a31 * y + a33]
    //
    // Using SIMD operations, we can scale column0 with x and column1 with y,
    // then add them together in a single operation. The `x` and `y` lanes will
    // contain the new Offset's `dx` and `dy` values, respectively.
    final Float32x4 result =
        transform._column0.scale(point.dx)
      + transform._column1.scale(point.dy)
      + transform._column3;

    // If the w component is not 1, scale the x and y by it.
    final double w = result.w;
    if (w == 1.0) {
      return Offset(result.x, result.y);
    }
    return Offset(result.x / w, result.y / w);
  }

  /// Create a transformation matrix which mimics the effects of tangentially
  /// wrapping the plane on which this transform is applied around a cylinder
  /// and then looking at the cylinder from a point outside the cylinder.
  ///
  /// The `radius` simulates the radius of the cylinder the plane is being
  /// wrapped onto. If the transformation is applied to a 0-dimensional dot
  /// instead of a plane, the dot would simply translate by +/- `radius` pixels
  /// along the `orientation` [Axis] when rotating from 0 to +/- 90 degrees.
  ///
  /// A positive radius means the object is closest at 0 `angle` and a negative
  /// radius means the object is closest at π `angle` or 180 degrees.
  ///
  /// The `angle` argument is the difference in angle in radians between the
  /// object and the viewing point. A positive `angle` on a positive `radius`
  /// moves the object up when `orientation` is vertical and right when
  /// horizontal.
  ///
  /// The transformation is always done such that a 0 `angle` keeps the
  /// transformed object at exactly the same size as before regardless of
  /// `radius` and `perspective` when `radius` is positive.
  ///
  /// The `perspective` argument is a number between 0 and 1 where 0 means
  /// looking at the object from infinitely far with an infinitely narrow field
  /// of view and 1 means looking at the object from infinitely close with an
  /// infinitely wide field of view. Defaults to a sane but arbitrary 0.001.
  ///
  /// The `orientation` is the direction of the rotation axis.
  ///
  /// Because the viewing position is a point, it's never possible to see the
  /// outer side of the cylinder at or past +/- π / 2 or 90 degrees and it's
  /// almost always possible to end up seeing the inner side of the cylinder
  /// or the back side of the transformed plane before π / 2 when perspective > 0.
  static SimdMatrix4 createCylindricalProjectionTransform({
    @required double radius,
    @required double angle,
    double perspective = 0.001,
    bool vertical = true,
  }) {
    assert(radius != null);
    assert(angle != null);
    assert(perspective >= 0 && perspective <= 1.0);
    assert(vertical != null);

    // Pre-multiplied matrix of a projection matrix and a view matrix.
    //
    // Projection matrix is a simplified perspective matrix
    // http://web.iitd.ac.in/~hegde/cad/lecture/L9_persproj.pdf
    // in the form of
    // [[1.0, 0.0, 0.0, 0.0],
    //  [0.0, 1.0, 0.0, 0.0],
    //  [0.0, 0.0, 1.0, 0.0],
    //  [0.0, 0.0, -perspective, 1.0]]
    //
    // View matrix is a simplified camera view matrix.
    // Basically re-scales to keep object at original size at angle = 0 at
    // any radius in the form of
    // [[1.0, 0.0, 0.0, 0.0],
    //  [0.0, 1.0, 0.0, 0.0],
    //  [0.0, 0.0, 1.0, -radius],
    //  [0.0, 0.0, 0.0, 1.0]]
    final SimdMatrix4 result = SimdMatrix4(
      1, 0,            0,                          0,
      0, 1,            0,                          0,
      0, 0,            1,                    -radius,
      0, 0, -perspective, perspective * radius + 1.0,
    );
    // Model matrix by first translating the object from the origin of the world
    // by radius in the z axis and then rotating against the wo
    final double c = math.cos(angle);
    final double s = math.sin(angle);
    final SimdMatrix4 orientation = vertical
      ? SimdMatrix4(
          1,  0, 0, 0,
          0,  c, s, 0,
          0, -s, c, 0,
          0,  0, 0, 1,
        )
      : SimdMatrix4(
          c, 0, -s, 0,
          0, 1,  0, 0,
          s, 0,  c, 0,
          0, 0,  0, 1,
        );
    // Essentially perspective * view * model.
    return result * orientation * SimdMatrix4(
      1, 0,      0, 0,
      0, 1,      0, 0,
      0, 0,      1, 0,
      0, 0, radius, 1,
    );
  }

  /// Returns a rect that bounds the result of applying the inverse of the given
  /// matrix as a perspective transform to the given rect.
  ///
  /// This function assumes the given rect is in the plane with z equals 0.0.
  /// The transformed rect is then projected back into the plane with z equals
  /// 0.0 before computing its bounding rect.
  static Rect inverseTransformRect(SimdMatrix4 transform, Rect rect) {
    return transformRect(transform.invert(), rect);
  }
}
