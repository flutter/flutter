// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/// A library containing geometry generators (like [CubeGenerator],
/// [SphereGenerator] and [CylinderGenerator]) and filters ([BarycentricFilter],
/// [ColorFilter] and [InvertFilter]).
library vector_math_geometry;

import 'dart:math' as math;
import 'dart:typed_data';

import 'vector_math.dart';
import 'vector_math_lists.dart';

part 'src/vector_math_geometry/mesh_geometry.dart';

part 'src/vector_math_geometry/filters/barycentric_filter.dart';
part 'src/vector_math_geometry/filters/color_filter.dart';
part 'src/vector_math_geometry/filters/flat_shade_filter.dart';
part 'src/vector_math_geometry/filters/geometry_filter.dart';
part 'src/vector_math_geometry/filters/invert_filter.dart';
part 'src/vector_math_geometry/filters/transform_filter.dart';

part 'src/vector_math_geometry/generators/attribute_generators.dart';
part 'src/vector_math_geometry/generators/circle_generator.dart';
part 'src/vector_math_geometry/generators/cube_generator.dart';
part 'src/vector_math_geometry/generators/cylinder_generator.dart';
part 'src/vector_math_geometry/generators/geometry_generator.dart';
part 'src/vector_math_geometry/generators/sphere_generator.dart';
part 'src/vector_math_geometry/generators/ring_generator.dart';
