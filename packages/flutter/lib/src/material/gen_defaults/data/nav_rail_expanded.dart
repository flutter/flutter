// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Version: 34.1.9

import 'color_role.dart';
import 'shape_struct.dart';

class TokenNavRailExpanded {
  /// md.comp.nav-rail.expanded.container.shape
  static const ShapeStruct containerShape = ShapeStruct(
    family: 'SHAPE_FAMILY_ROUNDED_CORNERS',
    topLeft: 0.00,
    topRight: 0.00,
    bottomLeft: 0.00,
    bottomRight: 0.00,
  );

  /// md.comp.nav-rail.expanded.container.width.minimum
  static const double containerWidthMinimum = 220.00;

  /// md.comp.nav-rail.expanded.container.elevation
  static const double containerElevation = 0.00;

  /// md.comp.nav-rail.expanded.top-space
  static const double topSpace = 44.00;

  /// md.comp.nav-rail.expanded.container.color
  static const TokenColorRole containerColor = TokenColorRole.surface;

  /// md.comp.nav-rail.expanded.modal.container.elevation
  static const double modalContainerElevation = 3.00;

  /// md.comp.nav-rail.expanded.modal.container.color
  static const TokenColorRole modalContainerColor =
      TokenColorRole.surfaceContainer;

  /// md.comp.nav-rail.expanded.modal.container.shape
  static const ShapeStruct modalContainerShape = ShapeStruct(
    family: 'SHAPE_FAMILY_ROUNDED_CORNERS',
    topLeft: 16.00,
    topRight: 16.00,
    bottomLeft: 16.00,
    bottomRight: 16.00,
  );

  /// md.comp.nav-rail.expanded.container.width.maximum
  static const double containerWidthMaximum = 360.00;
}
