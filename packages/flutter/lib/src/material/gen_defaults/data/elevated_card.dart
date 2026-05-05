// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Version: 34.1.18

import 'color_role.dart';
import 'shape_struct.dart';

class TokenElevatedCard {
  /// md.comp.elevated-card.disabled.container.color
  static const TokenColorRole disabledContainerColor = TokenColorRole.surface;

  /// md.comp.elevated-card.dragged.state-layer.color
  static const TokenColorRole draggedStateLayerColor = TokenColorRole.onSurface;

  /// md.comp.elevated-card.container.color
  static const TokenColorRole containerColor =
      TokenColorRole.surfaceContainerLow;

  /// md.comp.elevated-card.icon.size
  static const double iconSize = 24.00;

  /// md.comp.elevated-card.pressed.container.elevation
  static const double pressedContainerElevation = 1.00;

  /// md.comp.elevated-card.disabled.container.elevation
  static const double disabledContainerElevation = 1.00;

  /// md.comp.elevated-card.focus.indicator.thickness
  static const double focusIndicatorThickness = 3.00;

  /// md.comp.elevated-card.icon.color
  static const TokenColorRole iconColor = TokenColorRole.primary;

  /// md.comp.elevated-card.container.shape
  static const ShapeStruct containerShape = ShapeStruct(
    family: 'SHAPE_FAMILY_ROUNDED_CORNERS',
    topLeft: 12.00,
    topRight: 12.00,
    bottomLeft: 12.00,
    bottomRight: 12.00,
  );

  /// md.comp.elevated-card.container.shadow-color
  static const TokenColorRole containerShadowColor = TokenColorRole.shadow;

  /// md.comp.elevated-card.hover.container.elevation
  static const double hoverContainerElevation = 3.00;

  /// md.comp.elevated-card.hover.state-layer.color
  static const TokenColorRole hoverStateLayerColor = TokenColorRole.onSurface;

  /// md.comp.elevated-card.pressed.state-layer.color
  static const TokenColorRole pressedStateLayerColor = TokenColorRole.onSurface;

  /// md.comp.elevated-card.focus.state-layer.color
  static const TokenColorRole focusStateLayerColor = TokenColorRole.onSurface;

  /// md.comp.elevated-card.dragged.container.elevation
  static const double draggedContainerElevation = 8.00;

  /// md.comp.elevated-card.focus.indicator.outline.offset
  static const double focusIndicatorOutlineOffset = 2.00;

  /// md.comp.elevated-card.focus.container.elevation
  static const double focusContainerElevation = 1.00;

  /// md.comp.elevated-card.focus.indicator.color
  static const TokenColorRole focusIndicatorColor = TokenColorRole.secondary;

  /// md.comp.elevated-card.container.elevation
  static const double containerElevation = 1.00;
}
