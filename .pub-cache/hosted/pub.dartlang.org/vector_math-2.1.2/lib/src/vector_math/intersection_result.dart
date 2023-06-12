// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
part of vector_math;

/// Defines a result of an intersection test.
class IntersectionResult {
  double? _depth;

  /// The penetration depth of the intersection.
  double? get depth => _depth;

  /// The [axis] of the intersection.
  final axis = Vector3.zero();

  IntersectionResult();
}
