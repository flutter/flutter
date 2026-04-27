// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Version: 34.1.9

import 'color_role.dart';
import 'shape_struct.dart';

class TokenNavBar {
  /// md.comp.nav-bar.item.inactive.label-text.color
  static const TokenColorRole itemInactiveLabelTextColor =
      TokenColorRole.onSurfaceVariant;

  /// md.comp.nav-bar.item.active.hovered.state-layer.color
  static const TokenColorRole itemActiveHoveredStateLayerColor =
      TokenColorRole.onSecondaryContainer;

  /// md.comp.nav-bar.item.active.label-text.color
  static const TokenColorRole itemActiveLabelTextColor =
      TokenColorRole.secondary;

  /// md.comp.nav-bar.item.active.pressed.state-layer.opacity
  static const double itemActivePressedStateLayerOpacity = 0.10;

  /// md.comp.nav-bar.item.inactive.pressed.state-layer.color
  static const TokenColorRole itemInactivePressedStateLayerColor =
      TokenColorRole.onSecondaryContainer;

  /// md.comp.nav-bar.item.active.icon.color
  static const TokenColorRole itemActiveIconColor =
      TokenColorRole.onSecondaryContainer;

  /// md.comp.nav-bar.item.active.pressed.state-layer.color
  static const TokenColorRole itemActivePressedStateLayerColor =
      TokenColorRole.onSecondaryContainer;

  /// md.comp.nav-bar.item.inactive.hovered.state-layer.color
  static const TokenColorRole itemInactiveHoveredStateLayerColor =
      TokenColorRole.onSecondaryContainer;

  /// md.comp.nav-bar.item.between-space
  static const double itemBetweenSpace = 0.00;

  /// md.comp.nav-bar.container.color
  static const TokenColorRole containerColor = TokenColorRole.surfaceContainer;

  /// md.comp.nav-bar.item.active-indicator.shape
  static const ShapeStruct itemActiveIndicatorShape = ShapeStruct(
    family: 'SHAPE_FAMILY_CIRCULAR',
    topLeft: 0.00,
    topRight: 0.00,
    bottomLeft: 0.00,
    bottomRight: 0.00,
  );

  /// md.comp.nav-bar.container.elevation
  static const double containerElevation = 3.00;

  /// md.comp.nav-bar.item.active.hovered.state-layer.opacity
  static const double itemActiveHoveredStateLayerOpacity = 0.08;

  /// md.comp.nav-bar.item.icon.size
  static const double itemIconSize = 24.00;

  /// md.comp.nav-bar.container.shape
  static const ShapeStruct containerShape = ShapeStruct(
    family: 'SHAPE_FAMILY_ROUNDED_CORNERS',
    topLeft: 0.00,
    topRight: 0.00,
    bottomLeft: 0.00,
    bottomRight: 0.00,
  );

  /// md.comp.nav-bar.item.active.indicator.color
  static const TokenColorRole itemActiveIndicatorColor =
      TokenColorRole.secondaryContainer;

  /// md.comp.nav-bar.container.shadow-color
  static const TokenColorRole containerShadowColor = TokenColorRole.shadow;

  /// md.comp.nav-bar.item.inactive.icon.color
  static const TokenColorRole itemInactiveIconColor =
      TokenColorRole.onSurfaceVariant;

  /// md.comp.nav-bar.item.active.focused.state-layer.opacity
  static const double itemActiveFocusedStateLayerOpacity = 0.10;

  /// md.comp.nav-bar.container.height
  static const double containerHeight = 64.00;

  /// md.comp.nav-bar.item.active-indicator.icon-label-space
  static const double itemActiveIndicatorIconLabelSpace = 4.00;

  /// md.comp.nav-bar.item.inactive.focused.state-layer.color
  static const TokenColorRole itemInactiveFocusedStateLayerColor =
      TokenColorRole.onSecondaryContainer;

  /// md.comp.nav-bar.item.active.focused.state-layer.color
  static const TokenColorRole itemActiveFocusedStateLayerColor =
      TokenColorRole.onSecondaryContainer;
}
