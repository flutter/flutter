// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:vector_math/vector_math_64.dart';

import 'basic_types.dart';

/// Utility functions for working with matrices.
class MatrixUtils {
  MatrixUtils._();

  /// Returns the given [transform] matrix as an [Offset], if the matrix is
  /// nothing but a 2D translation.
  ///
  /// Otherwise, returns null.
  static Offset getAsTranslation(Matrix4 transform) {
    assert(transform != null);
    final Float64List values = transform.storage;
    // Values are stored in column-major order.
    if (values[0] == 1.0 && // col 1
        values[1] == 0.0 &&
        values[2] == 0.0 &&
        values[3] == 0.0 &&
        values[4] == 0.0 && // col 2
        values[5] == 1.0 &&
        values[6] == 0.0 &&
        values[7] == 0.0 &&
        values[8] == 0.0 && // col 3
        values[9] == 0.0 &&
        values[10] == 1.0 &&
        values[11] == 0.0 &&
        values[14] == 0.0 && // bottom of col 4 (values 12 and 13 are the x and y offsets)
        values[15] == 1.0) {
      return new Offset(values[12], values[13]);
    }
    return null;
  }

  /// Returns the given [transform] matrix as a [double] describing a uniform
  /// scale, if the matrix is nothing but a symmetric 2D scale transform.
  ///
  /// Otherwise, returns null.
  static double getAsScale(Matrix4 transform) {
    assert(transform != null);
    final Float64List values = transform.storage;
    // Values are stored in column-major order.
    if (values[1] == 0.0 && // col 1 (value 0 is the scale)
        values[2] == 0.0 &&
        values[3] == 0.0 &&
        values[4] == 0.0 && // col 2 (value 5 is the scale)
        values[6] == 0.0 &&
        values[7] == 0.0 &&
        values[8] == 0.0 && // col 3
        values[9] == 0.0 &&
        values[10] == 1.0 &&
        values[11] == 0.0 &&
        values[12] == 0.0 && // col 4
        values[13] == 0.0 &&
        values[14] == 0.0 &&
        values[15] == 1.0 &&
        values[0] == values[5]) { // uniform scale
      return values[0];
    }
    return null;
  }

  /// Returns true if the given matrices are exactly equal, and false
  /// otherwise. Null values are assumed to be the identity matrix.
  static bool matrixEquals(Matrix4 a, Matrix4 b) {
    if (identical(a, b))
      return true;
    assert(a != null || b != null);
    if (a == null)
      return isIdentity(b);
    if (b == null)
      return isIdentity(a);
    assert(a != null && b != null);
    return a.storage[0] == b.storage[0]
        && a.storage[1] == b.storage[1]
        && a.storage[2] == b.storage[2]
        && a.storage[3] == b.storage[3]
        && a.storage[4] == b.storage[4]
        && a.storage[5] == b.storage[5]
        && a.storage[6] == b.storage[6]
        && a.storage[7] == b.storage[7]
        && a.storage[8] == b.storage[8]
        && a.storage[9] == b.storage[9]
        && a.storage[10] == b.storage[10]
        && a.storage[11] == b.storage[11]
        && a.storage[12] == b.storage[12]
        && a.storage[13] == b.storage[13]
        && a.storage[14] == b.storage[14]
        && a.storage[15] == b.storage[15];
  }

  /// Whether the given matrix is the identity matrix.
  static bool isIdentity(Matrix4 a) {
    assert(a != null);
    return a.storage[0] == 1.0 // col 1
        && a.storage[1] == 0.0
        && a.storage[2] == 0.0
        && a.storage[3] == 0.0
        && a.storage[4] == 0.0 // col 2
        && a.storage[5] == 1.0
        && a.storage[6] == 0.0
        && a.storage[7] == 0.0
        && a.storage[8] == 0.0 // col 3
        && a.storage[9] == 0.0
        && a.storage[10] == 1.0
        && a.storage[11] == 0.0
        && a.storage[12] == 0.0 // col 4
        && a.storage[13] == 0.0
        && a.storage[14] == 0.0
        && a.storage[15] == 1.0;
  }

  /// Applies the given matrix as a perspective transform to the given point.
  ///
  /// This function assumes the given point has a z-coordinate of 0.0. The
  /// z-coordinate of the result is ignored.
  static Offset transformPoint(Matrix4 transform, Offset point) {
    final Vector3 position3 = new Vector3(point.dx, point.dy, 0.0);
    final Vector3 transformed3 = transform.perspectiveTransform(position3);
    return new Offset(transformed3.x, transformed3.y);
  }

  /// Returns a rect that bounds the result of applying the given matrix as a
  /// perspective transform to the given rect.
  ///
  /// This function assumes the given rect is in the plane with z equals 0.0.
  /// The transformed rect is then projected back into the plane with z equals
  /// 0.0 before computing its bounding rect.
  static Rect transformRect(Matrix4 transform, Rect rect) {
    final Offset point1 = transformPoint(transform, rect.topLeft);
    final Offset point2 = transformPoint(transform, rect.topRight);
    final Offset point3 = transformPoint(transform, rect.bottomLeft);
    final Offset point4 = transformPoint(transform, rect.bottomRight);
    return new Rect.fromLTRB(
        _min4(point1.dx, point2.dx, point3.dx, point4.dx),
        _min4(point1.dy, point2.dy, point3.dy, point4.dy),
        _max4(point1.dx, point2.dx, point3.dx, point4.dx),
        _max4(point1.dy, point2.dy, point3.dy, point4.dy)
    );
  }

  static double _min4(double a, double b, double c, double d) {
    return math.min(a, math.min(b, math.min(c, d)));
  }
  static double _max4(double a, double b, double c, double d) {
    return math.max(a, math.max(b, math.max(c, d)));
  }

  /// Returns a rect that bounds the result of applying the inverse of the given
  /// matrix as a perspective transform to the given rect.
  ///
  /// This function assumes the given rect is in the plane with z equals 0.0.
  /// The transformed rect is then projected back into the plane with z equals
  /// 0.0 before computing its bounding rect.
  static Rect inverseTransformRect(Matrix4 transform, Rect rect) {
    assert(rect != null);
    assert(transform.determinant != 0.0);
    if (isIdentity(transform))
      return rect;
    transform = new Matrix4.copy(transform)..invert();
    return transformRect(transform, rect);
  }
}
