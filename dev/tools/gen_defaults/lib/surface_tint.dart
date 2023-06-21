// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class SurfaceTintTemplate extends TokenTemplate {
  const SurfaceTintTemplate(super.blockName, super.fileName, super.tokens);

  @override
  String generate() => '''
// Surface tint opacities based on elevations according to the
// Material Design 3 specification:
//   https://m3.material.io/styles/color/the-color-system/color-roles
// Ordered by increasing elevation.
const List<_ElevationOpacity> _surfaceTintElevationOpacities = <_ElevationOpacity>[
  _ElevationOpacity(${getToken('md.sys.elevation.level0')}, 0.0),   // Elevation level 0
  _ElevationOpacity(${getToken('md.sys.elevation.level1')}, 0.05),  // Elevation level 1
  _ElevationOpacity(${getToken('md.sys.elevation.level2')}, 0.08),  // Elevation level 2
  _ElevationOpacity(${getToken('md.sys.elevation.level3')}, 0.11),  // Elevation level 3
  _ElevationOpacity(${getToken('md.sys.elevation.level4')}, 0.12),  // Elevation level 4
  _ElevationOpacity(${getToken('md.sys.elevation.level5')}, 0.14), // Elevation level 5
];
''';
}
