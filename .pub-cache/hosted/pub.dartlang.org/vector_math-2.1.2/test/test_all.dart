// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library console_test_harness;

import 'aabb2_test.dart' as aabb2;
import 'aabb3_test.dart' as aabb3;
import 'colors_test.dart' as colors;
import 'frustum_test.dart' as frustum;
import 'geometry_test.dart' as geometry;
import 'matrix2_test.dart' as matrix2;
import 'matrix3_test.dart' as matrix3;
import 'matrix4_test.dart' as matrix4;
import 'noise_test.dart' as noise;
import 'obb3_test.dart' as obb3;
import 'opengl_matrix_test.dart' as opengl_matrix;
import 'plane_test.dart' as plane;
import 'quad_test.dart' as quad;
import 'quaternion_test.dart' as quaternion;
import 'ray_test.dart' as ray;
import 'scalar_list_view_test.dart' as scalar_list_view;
import 'sphere_test.dart' as sphere;
import 'triangle_test.dart' as triangle;
import 'utilities_test.dart' as utilities;
import 'vector2_list_test.dart' as vector2_list;
import 'vector2_test.dart' as vector2;
import 'vector3_list_test.dart' as vector3_list;
import 'vector3_test.dart' as vector3;
import 'vector4_list_test.dart' as vector4_list;
import 'vector4_test.dart' as vector4;

void main() {
  aabb2.main();
  aabb3.main();
  colors.main();
  frustum.main();
  geometry.main();
  matrix2.main();
  matrix3.main();
  matrix4.main();
  noise.main();
  obb3.main();
  opengl_matrix.main();
  plane.main();
  quad.main();
  quaternion.main();
  ray.main();
  sphere.main();
  triangle.main();
  utilities.main();
  scalar_list_view.main();
  vector2_list.main();
  vector3_list.main();
  vector4_list.main();
  vector2.main();
  vector3.main();
  vector4.main();
}
