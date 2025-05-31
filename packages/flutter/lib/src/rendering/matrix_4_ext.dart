// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:vector_math/vector_math_64.dart' show Matrix4;

/// Extensions on [Matrix4] to easy migration to more efficient implementations.
extension Matrix4Ext on Matrix4 {
  /// Convenience wrapper over [translateByDouble].
  void translateD(double x, [double y = 0, double z = 0]) {
    translateByDouble(x, y, z, 1.0);
  }

  /// Convenience wrapper over [scaleByDouble].
  void scaleD(double x, [double? y, double? z]) {
    scaleByDouble(x, y ?? x, z ?? x, 1.0);
  }
}
