// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/// A library containing different type of vector operations for use in games,
/// simulations, or rendering.
///
/// The library contains Vector classes ([Vector2], [Vector3] and [Vector4]),
/// Matrices classes ([Matrix2], [Matrix3] and [Matrix4]) and collision
/// detection related classes ([Aabb2], [Aabb3], [Frustum], [Obb3], [Plane],
/// [Quad], [Ray], [Sphere] and [Triangle]).
///
/// In addition some utilities are available as color operations (See [Colors]
/// class), noise generators ([SimplexNoise]) and common OpenGL operations
/// (like [makeViewMatrix], [makePerspectiveMatrix], or [pickRay]).
library vector_math;

import 'dart:math' as math;
import 'dart:typed_data';

part 'src/vector_math/utilities.dart';
part 'src/vector_math/aabb2.dart';
part 'src/vector_math/aabb3.dart';
part 'src/vector_math/colors.dart';
part 'src/vector_math/constants.dart';
part 'src/vector_math/error_helpers.dart';
part 'src/vector_math/frustum.dart';
part 'src/vector_math/intersection_result.dart';
part 'src/vector_math/matrix2.dart';
part 'src/vector_math/matrix3.dart';
part 'src/vector_math/matrix4.dart';
part 'src/vector_math/obb3.dart';
part 'src/vector_math/opengl.dart';
part 'src/vector_math/plane.dart';
part 'src/vector_math/quad.dart';
part 'src/vector_math/quaternion.dart';
part 'src/vector_math/ray.dart';
part 'src/vector_math/sphere.dart';
part 'src/vector_math/third_party/noise.dart';
part 'src/vector_math/triangle.dart';
part 'src/vector_math/vector.dart';
part 'src/vector_math/vector2.dart';
part 'src/vector_math/vector3.dart';
part 'src/vector_math/vector4.dart';
