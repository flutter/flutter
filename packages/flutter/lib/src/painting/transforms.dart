// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:vector_math/vector_math_64.dart';

import 'basic_types.dart';

class MatrixUtils {
  MatrixUtils._();

  /// Returns the given [transform] matrix as Offset, if the matrix is nothing
  /// but a 2D translation.
  ///
  /// Returns null, otherwise.
  static Offset getAsTranslation(Matrix4 transform) {
    Float64List values = transform.storage;
    // Values are stored in column-major order.
    if (values[0] == 1.0 &&
        values[1] == 0.0 &&
        values[2] == 0.0 &&
        values[3] == 0.0 &&
        values[4] == 0.0 &&
        values[5] == 1.0 &&
        values[6] == 0.0 &&
        values[7] == 0.0 &&
        values[8] == 0.0 &&
        values[9] == 0.0 &&
        values[10] == 1.0 &&
        values[11] == 0.0 &&
        values[14] == 0.0 &&
        values[15] == 1.0) {
      return new Offset(values[12], values[13]);
    }
    return null;
  }

}
