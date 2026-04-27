// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Version: 34.1.9

import 'color_role.dart';
import 'shape_struct.dart';

class TokenFilledCard {
  /// md.comp.filled-card.hover.state-layer.opacity
  static const double hoverStateLayerOpacity = 0.08;

  /// md.comp.filled-card.focus.container.elevation
  static const double focusContainerElevation = 0.00;

  /// md.comp.filled-card.focus.indicator.color
  static const TokenColorRole focusIndicatorColor = TokenColorRole.secondary;

  /// md.comp.filled-card.focus.indicator.thickness
  static const double focusIndicatorThickness = 3.00;

  /// md.comp.filled-card.focus.state-layer.color
  static const TokenColorRole focusStateLayerColor = TokenColorRole.onSurface;

  /// md.comp.filled-card.container.shadow-color
  static const TokenColorRole containerShadowColor = TokenColorRole.shadow;

  /// md.comp.filled-card.hover.container.elevation
  static const double hoverContainerElevation = 1.00;

  /// md.comp.filled-card.pressed.state-layer.color
  static const TokenColorRole pressedStateLayerColor = TokenColorRole.onSurface;

  /// md.comp.filled-card.pressed.container.elevation
  static const double pressedContainerElevation = 0.00;

  /// md.comp.filled-card.icon.color
  static const TokenColorRole iconColor = TokenColorRole.primary;

  /// md.comp.filled-card.disabled.container.elevation
  static const double disabledContainerElevation = 0.00;

  /// md.comp.filled-card.dragged.container.elevation
  static const double draggedContainerElevation = 6.00;

  /// md.comp.filled-card.container.elevation
  static const double containerElevation = 0.00;

  /// md.comp.filled-card.dragged.state-layer.color
  static const TokenColorRole draggedStateLayerColor = TokenColorRole.onSurface;

  /// md.comp.filled-card.focus.indicator.outline.offset
  static const double focusIndicatorOutlineOffset = 2.00;

  /// md.comp.filled-card.container.color
  static const TokenColorRole containerColor =
      TokenColorRole.surfaceContainerHighest;

  /// md.comp.filled-card.container.shape
  static const ShapeStruct containerShape = ShapeStruct(
    family: 'SHAPE_FAMILY_ROUNDED_CORNERS',
    topLeft: 12.00,
    topRight: 12.00,
    bottomLeft: 12.00,
    bottomRight: 12.00,
  );

  /// md.comp.filled-card.dragged.state-layer.opacity
  static const double draggedStateLayerOpacity = 0.16;

  /// md.comp.filled-card.icon.size
  static const double iconSize = 24.00;

  /// md.comp.filled-card.hover.state-layer.color
  static const TokenColorRole hoverStateLayerColor = TokenColorRole.onSurface;

  /// md.comp.filled-card.focus.state-layer.opacity
  static const double focusStateLayerOpacity = 0.10;

  /// md.comp.filled-card.disabled.container.opacity
  static const double disabledContainerOpacity = 0.38;

  /// md.comp.filled-card.pressed.state-layer.opacity
  static const double pressedStateLayerOpacity = 0.10;

  /// md.comp.filled-card.disabled.container.color
  static const TokenColorRole disabledContainerColor =
      TokenColorRole.surfaceVariant;
}
