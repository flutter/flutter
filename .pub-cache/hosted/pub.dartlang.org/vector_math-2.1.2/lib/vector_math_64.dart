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
library vector_math_64;

import 'dart:math' as math;
import 'dart:typed_data';

part 'src/vector_math_64/utilities.dart';
part 'src/vector_math_64/aabb2.dart';
part 'src/vector_math_64/aabb3.dart';
part 'src/vector_math_64/colors.dart';
part 'src/vector_math_64/constants.dart';
part 'src/vector_math_64/error_helpers.dart';
part 'src/vector_math_64/frustum.dart';
part 'src/vector_math_64/intersection_result.dart';
part 'src/vector_math_64/matrix2.dart';
part 'src/vector_math_64/matrix3.dart';
part 'src/vector_math_64/matrix4.dart';
part 'src/vector_math_64/obb3.dart';
part 'src/vector_math_64/opengl.dart';
part 'src/vector_math_64/plane.dart';
part 'src/vector_math_64/quad.dart';
part 'src/vector_math_64/quaternion.dart';
part 'src/vector_math_64/ray.dart';
part 'src/vector_math_64/sphere.dart';
part 'src/vector_math_64/third_party/noise.dart';
part 'src/vector_math_64/triangle.dart';
part 'src/vector_math_64/vector.dart';
part 'src/vector_math_64/vector2.dart';
part 'src/vector_math_64/vector3.dart';
part 'src/vector_math_64/vector4.dart';
