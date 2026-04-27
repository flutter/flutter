// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Version: 34.1.9

import 'color_role.dart';
import 'shape_struct.dart';

class TokenDialog {
  /// md.comp.dialog.supporting-text.color
  static const TokenColorRole supportingTextColor =
      TokenColorRole.onSurfaceVariant;

  /// md.comp.dialog.action.pressed.state-layer.color
  static const TokenColorRole actionPressedStateLayerColor =
      TokenColorRole.primary;

  /// md.comp.dialog.action.hover.state-layer.opacity
  static const double actionHoverStateLayerOpacity = 0.08;

  /// md.comp.dialog.action.pressed.state-layer.opacity
  static const double actionPressedStateLayerOpacity = 0.10;

  /// md.comp.dialog.headline.color
  static const TokenColorRole headlineColor = TokenColorRole.onSurface;

  /// md.comp.dialog.headline.font
  static const String headlineFont = 'Roboto Flex';

  /// md.comp.dialog.container.shape
  static const ShapeStruct containerShape = ShapeStruct(
    family: 'SHAPE_FAMILY_ROUNDED_CORNERS',
    topLeft: 28.00,
    topRight: 28.00,
    bottomLeft: 28.00,
    bottomRight: 28.00,
  );

  /// md.comp.dialog.action.focus.state-layer.color
  static const TokenColorRole actionFocusStateLayerColor =
      TokenColorRole.primary;

  /// md.comp.dialog.headline.type
  static const double headlineTypeFontSize = 24.00;

  /// md.comp.dialog.headline.type
  static const double headlineTypeFontWeight = 400;

  /// md.comp.dialog.headline.type
  static const double headlineTypeLineHeight = 32.00;

  /// md.comp.dialog.headline.type
  static const double headlineTypeLetterSpacing = 0.00;

  /// md.comp.dialog.headline.type
  static const String headlineTypeFontFamily = 'Roboto';

  /// md.comp.dialog.action.focus.state-layer.opacity
  static const double actionFocusStateLayerOpacity = 0.10;

  /// md.comp.dialog.action.label-text.type
  static const double actionLabelTextTypeFontSize = 14.00;

  /// md.comp.dialog.action.label-text.type
  static const double actionLabelTextTypeFontWeight = 700;

  /// md.comp.dialog.action.label-text.type
  static const double actionLabelTextTypeLineHeight = 20.00;

  /// md.comp.dialog.action.label-text.type
  static const double actionLabelTextTypeLetterSpacing = 0.10;

  /// md.comp.dialog.action.label-text.type
  static const String actionLabelTextTypeFontFamily = 'Roboto';

  /// md.comp.dialog.action.focus.label-text.color
  static const TokenColorRole actionFocusLabelTextColor =
      TokenColorRole.primary;

  /// md.comp.dialog.container.color
  static const TokenColorRole containerColor =
      TokenColorRole.surfaceContainerHigh;

  /// md.comp.dialog.action.hover.label-text.color
  static const TokenColorRole actionHoverLabelTextColor =
      TokenColorRole.primary;

  /// md.comp.dialog.supporting-text.font
  static const String supportingTextFont = 'Roboto Flex';

  /// md.comp.dialog.action.pressed.label-text.color
  static const TokenColorRole actionPressedLabelTextColor =
      TokenColorRole.primary;

  /// md.comp.dialog.supporting-text.type
  static const double supportingTextTypeFontSize = 14.00;

  /// md.comp.dialog.supporting-text.type
  static const double supportingTextTypeFontWeight = 400;

  /// md.comp.dialog.supporting-text.type
  static const double supportingTextTypeLineHeight = 20.00;

  /// md.comp.dialog.supporting-text.type
  static const double supportingTextTypeLetterSpacing = 0.00;

  /// md.comp.dialog.supporting-text.type
  static const String supportingTextTypeFontFamily = 'Roboto Flex';

  /// md.comp.dialog.action.hover.state-layer.color
  static const TokenColorRole actionHoverStateLayerColor =
      TokenColorRole.primary;

  /// md.comp.dialog.with-icon.icon.color
  static const TokenColorRole withIconIconColor = TokenColorRole.secondary;

  /// md.comp.dialog.container.elevation
  static const double containerElevation = 6.00;

  /// md.comp.dialog.action.label-text.color
  static const TokenColorRole actionLabelTextColor = TokenColorRole.primary;

  /// md.comp.dialog.with-icon.icon.size
  static const double withIconIconSize = 24.00;

  /// md.comp.dialog.action.label-text.font
  static const String actionLabelTextFont = 'Roboto Flex';
}
