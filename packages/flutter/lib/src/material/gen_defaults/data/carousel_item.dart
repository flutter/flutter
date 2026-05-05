// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Version: 34.1.18

import 'color_role.dart';
import 'shape_struct.dart';

class TokenCarouselItem {
  /// md.comp.carousel-item.pressed.state-layer.color
  static const TokenColorRole pressedStateLayerColor = TokenColorRole.onSurface;

  /// md.comp.carousel-item.container.elevation
  static const double containerElevation = 0.00;

  /// md.comp.carousel-item.focus.indicator.outline.offset
  static const double focusIndicatorOutlineOffset = 2.00;

  /// md.comp.carousel-item.focus.state-layer.color
  static const TokenColorRole focusStateLayerColor = TokenColorRole.onSurface;

  /// md.comp.carousel-item.focus.container.elevation
  static const double focusContainerElevation = 0.00;

  /// md.comp.carousel-item.container.shape
  static const ShapeStruct containerShape = ShapeStruct(
    family: 'SHAPE_FAMILY_ROUNDED_CORNERS',
    topLeft: 28.00,
    topRight: 28.00,
    bottomLeft: 28.00,
    bottomRight: 28.00,
  );

  /// md.comp.carousel-item.focus.indicator.color
  static const TokenColorRole focusIndicatorColor = TokenColorRole.secondary;

  /// md.comp.carousel-item.container.color
  static const TokenColorRole containerColor = TokenColorRole.surface;

  /// md.comp.carousel-item.with-outline.pressed.outline.color
  static const TokenColorRole withOutlinePressedOutlineColor =
      TokenColorRole.outline;

  /// md.comp.carousel-item.with-outline.outline.width
  static const double withOutlineOutlineWidth = 1.00;

  /// md.comp.carousel-item.with-outline.hover.outline.color
  static const TokenColorRole withOutlineHoverOutlineColor =
      TokenColorRole.outline;

  /// md.comp.carousel-item.disabled.container.elevation
  static const double disabledContainerElevation = 0.00;

  /// md.comp.carousel-item.with-outline.focus.outline.color
  static const TokenColorRole withOutlineFocusOutlineColor =
      TokenColorRole.onSurface;

  /// md.comp.carousel-item.hover.container.elevation
  static const double hoverContainerElevation = 1.00;

  /// md.comp.carousel-item.hover.state-layer.color
  static const TokenColorRole hoverStateLayerColor = TokenColorRole.onSurface;

  /// md.comp.carousel-item.container.shadow-color
  static const TokenColorRole containerShadowColor = TokenColorRole.shadow;

  /// md.comp.carousel-item.pressed.container.elevation
  static const double pressedContainerElevation = 0.00;

  /// md.comp.carousel-item.with-outline.outline.color
  static const TokenColorRole withOutlineOutlineColor = TokenColorRole.outline;

  /// md.comp.carousel-item.disabled.container.color
  static const TokenColorRole disabledContainerColor = TokenColorRole.surface;

  /// md.comp.carousel-item.focus.indicator.thickness
  static const double focusIndicatorThickness = 3.00;

  /// md.comp.carousel-item.with-outline.disabled.outline.color
  static const TokenColorRole withOutlineDisabledOutlineColor =
      TokenColorRole.outline;
}
