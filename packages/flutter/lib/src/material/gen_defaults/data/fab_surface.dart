// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Version: 34.1.18

import 'color_role.dart';
import 'shape_struct.dart';

class TokenFabSurface {
  /// md.comp.fab.surface.lowered.container.elevation
  static const double loweredContainerElevation = 1.00;

  /// md.comp.fab.surface.pressed.container.elevation
  static const double pressedContainerElevation = 6.00;

  /// md.comp.fab.surface.focus.indicator.color
  static const TokenColorRole focusIndicatorColor = TokenColorRole.secondary;

  /// md.comp.fab.surface.focus.state-layer.color
  static const TokenColorRole focusStateLayerColor = TokenColorRole.primary;

  /// md.comp.fab.surface.pressed.state-layer.color
  static const TokenColorRole pressedStateLayerColor = TokenColorRole.primary;

  /// md.comp.fab.surface.lowered.focus.container.elevation
  static const double loweredFocusContainerElevation = 1.00;

  /// md.comp.fab.surface.hover.state-layer.color
  static const TokenColorRole hoverStateLayerColor = TokenColorRole.primary;

  /// md.comp.fab.surface.container.elevation
  static const double containerElevation = 6.00;

  /// md.comp.fab.surface.lowered.hover.container.elevation
  static const double loweredHoverContainerElevation = 3.00;

  /// md.comp.fab.surface.container.shape
  static const ShapeStruct containerShape = ShapeStruct(
    family: 'SHAPE_FAMILY_ROUNDED_CORNERS',
    topLeft: 16.00,
    topRight: 16.00,
    bottomLeft: 16.00,
    bottomRight: 16.00,
  );

  /// md.comp.fab.surface.focus.container.elevation
  static const double focusContainerElevation = 6.00;

  /// md.comp.fab.surface.container.width
  static const double containerWidth = 56.00;

  /// md.comp.fab.surface.focus.icon.color
  static const TokenColorRole focusIconColor = TokenColorRole.primary;

  /// md.comp.fab.surface.lowered.pressed.container.elevation
  static const double loweredPressedContainerElevation = 1.00;

  /// md.comp.fab.surface.hover.icon.color
  static const TokenColorRole hoverIconColor = TokenColorRole.primary;

  /// md.comp.fab.surface.focus.indicator.thickness
  static const double focusIndicatorThickness = 3.00;

  /// md.comp.fab.surface.pressed.icon.color
  static const TokenColorRole pressedIconColor = TokenColorRole.primary;

  /// md.comp.fab.surface.lowered.container.color
  static const TokenColorRole loweredContainerColor =
      TokenColorRole.surfaceContainerLow;

  /// md.comp.fab.surface.icon.size
  static const double iconSize = 24.00;

  /// md.comp.fab.surface.container.shadow-color
  static const TokenColorRole containerShadowColor = TokenColorRole.shadow;

  /// md.comp.fab.surface.focus.indicator.outline.offset
  static const double focusIndicatorOutlineOffset = 2.00;

  /// md.comp.fab.surface.container.height
  static const double containerHeight = 56.00;

  /// md.comp.fab.surface.container.color
  static const TokenColorRole containerColor =
      TokenColorRole.surfaceContainerHigh;

  /// md.comp.fab.surface.hover.container.elevation
  static const double hoverContainerElevation = 8.00;

  /// md.comp.fab.surface.icon.color
  static const TokenColorRole iconColor = TokenColorRole.primary;
}
