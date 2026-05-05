// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Version: 34.1.18

import 'color_role.dart';
import 'shape_struct.dart';

class TokenOutlinedCard {
  /// md.comp.outlined-card.dragged.state-layer.color
  static const TokenColorRole draggedStateLayerColor = TokenColorRole.onSurface;

  /// md.comp.outlined-card.outline.width
  static const double outlineWidth = 1.00;

  /// md.comp.outlined-card.focus.container.elevation
  static const double focusContainerElevation = 0.00;

  /// md.comp.outlined-card.hover.outline.color
  static const TokenColorRole hoverOutlineColor = TokenColorRole.outlineVariant;

  /// md.comp.outlined-card.container.elevation
  static const double containerElevation = 0.00;

  /// md.comp.outlined-card.hover.container.elevation
  static const double hoverContainerElevation = 1.00;

  /// md.comp.outlined-card.icon.color
  static const TokenColorRole iconColor = TokenColorRole.primary;

  /// md.comp.outlined-card.dragged.outline.color
  static const TokenColorRole draggedOutlineColor =
      TokenColorRole.outlineVariant;

  /// md.comp.outlined-card.focus.indicator.outline.offset
  static const double focusIndicatorOutlineOffset = 2.00;

  /// md.comp.outlined-card.disabled.container.elevation
  static const double disabledContainerElevation = 0.00;

  /// md.comp.outlined-card.dragged.container.elevation
  static const double draggedContainerElevation = 6.00;

  /// md.comp.outlined-card.focus.indicator.thickness
  static const double focusIndicatorThickness = 3.00;

  /// md.comp.outlined-card.hover.state-layer.color
  static const TokenColorRole hoverStateLayerColor = TokenColorRole.onSurface;

  /// md.comp.outlined-card.container.shape
  static const ShapeStruct containerShape = ShapeStruct(
    family: 'SHAPE_FAMILY_ROUNDED_CORNERS',
    topLeft: 12.00,
    topRight: 12.00,
    bottomLeft: 12.00,
    bottomRight: 12.00,
  );

  /// md.comp.outlined-card.outline.color
  static const TokenColorRole outlineColor = TokenColorRole.outlineVariant;

  /// md.comp.outlined-card.pressed.container.elevation
  static const double pressedContainerElevation = 0.00;

  /// md.comp.outlined-card.container.shadow-color
  static const TokenColorRole containerShadowColor = TokenColorRole.shadow;

  /// md.comp.outlined-card.container.color
  static const TokenColorRole containerColor = TokenColorRole.surface;

  /// md.comp.outlined-card.pressed.outline.color
  static const TokenColorRole pressedOutlineColor =
      TokenColorRole.outlineVariant;

  /// md.comp.outlined-card.focus.state-layer.color
  static const TokenColorRole focusStateLayerColor = TokenColorRole.onSurface;

  /// md.comp.outlined-card.focus.indicator.color
  static const TokenColorRole focusIndicatorColor = TokenColorRole.secondary;

  /// md.comp.outlined-card.disabled.outline.color
  static const TokenColorRole disabledOutlineColor = TokenColorRole.outline;

  /// md.comp.outlined-card.icon.size
  static const double iconSize = 24.00;

  /// md.comp.outlined-card.pressed.state-layer.color
  static const TokenColorRole pressedStateLayerColor = TokenColorRole.onSurface;

  /// md.comp.outlined-card.focus.outline.color
  static const TokenColorRole focusOutlineColor = TokenColorRole.onSurface;
}
