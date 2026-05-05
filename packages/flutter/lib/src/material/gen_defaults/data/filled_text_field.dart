// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Version: 34.1.18

import 'color_role.dart';
import 'shape_struct.dart';

class TokenFilledTextField {
  /// md.comp.filled-text-field.container.color
  static const TokenColorRole containerColor =
      TokenColorRole.surfaceContainerHighest;

  /// md.comp.filled-text-field.error.focus.trailing-icon.color
  static const TokenColorRole errorFocusTrailingIconColor =
      TokenColorRole.error;

  /// md.comp.filled-text-field.disabled.input-text.color
  static const TokenColorRole disabledInputTextColor = TokenColorRole.onSurface;

  /// md.comp.filled-text-field.supporting-text.font
  static const String supportingTextFont = 'Roboto';

  /// md.comp.filled-text-field.disabled.supporting-text.color
  static const TokenColorRole disabledSupportingTextColor =
      TokenColorRole.onSurface;

  /// md.comp.filled-text-field.error.hover.trailing-icon.color
  static const TokenColorRole errorHoverTrailingIconColor =
      TokenColorRole.onErrorContainer;

  /// md.comp.filled-text-field.disabled.trailing-icon.color
  static const TokenColorRole disabledTrailingIconColor =
      TokenColorRole.onSurface;

  /// md.comp.filled-text-field.error.label-text.color
  static const TokenColorRole errorLabelTextColor = TokenColorRole.error;

  /// md.comp.filled-text-field.focus.leading-icon.color
  static const TokenColorRole focusLeadingIconColor =
      TokenColorRole.onSurfaceVariant;

  /// md.comp.filled-text-field.input-text.font
  static const String inputTextFont = 'Roboto';

  /// md.comp.filled-text-field.error.focus.label-text.color
  static const TokenColorRole errorFocusLabelTextColor = TokenColorRole.error;

  /// md.comp.filled-text-field.focus.active-indicator.height
  static const double focusActiveIndicatorHeight = 2.00;

  /// md.comp.filled-text-field.focus.trailing-icon.color
  static const TokenColorRole focusTrailingIconColor =
      TokenColorRole.onSurfaceVariant;

  /// md.comp.filled-text-field.hover.leading-icon.color
  static const TokenColorRole hoverLeadingIconColor =
      TokenColorRole.onSurfaceVariant;

  /// md.comp.filled-text-field.error.hover.leading-icon.color
  static const TokenColorRole errorHoverLeadingIconColor =
      TokenColorRole.onSurfaceVariant;

  /// md.comp.filled-text-field.error.input-text.color
  static const TokenColorRole errorInputTextColor = TokenColorRole.onSurface;

  /// md.comp.filled-text-field.focus.label-text.color
  static const TokenColorRole focusLabelTextColor = TokenColorRole.primary;

  /// md.comp.filled-text-field.label-text.type
  static const double labelTextTypeFontSize = 16.00;

  /// md.comp.filled-text-field.label-text.type
  static const double labelTextTypeFontWeight = 400;

  /// md.comp.filled-text-field.label-text.type
  static const double labelTextTypeLineHeight = 24.00;

  /// md.comp.filled-text-field.label-text.type
  static const double labelTextTypeLetterSpacing = 0.50;

  /// md.comp.filled-text-field.label-text.type
  static const String labelTextTypeFontFamily = 'Roboto';

  /// md.comp.filled-text-field.input-text.type
  static const double inputTextTypeFontSize = 16.00;

  /// md.comp.filled-text-field.input-text.type
  static const double inputTextTypeFontWeight = 400;

  /// md.comp.filled-text-field.input-text.type
  static const double inputTextTypeLineHeight = 24.00;

  /// md.comp.filled-text-field.input-text.type
  static const double inputTextTypeLetterSpacing = 0.50;

  /// md.comp.filled-text-field.input-text.type
  static const String inputTextTypeFontFamily = 'Roboto';

  /// md.comp.filled-text-field.error.focus.supporting-text.color
  static const TokenColorRole errorFocusSupportingTextColor =
      TokenColorRole.error;

  /// md.comp.filled-text-field.trailing-icon.color
  static const TokenColorRole trailingIconColor =
      TokenColorRole.onSurfaceVariant;

  /// md.comp.filled-text-field.disabled.active-indicator.color
  static const TokenColorRole disabledActiveIndicatorColor =
      TokenColorRole.onSurface;

  /// md.comp.filled-text-field.disabled.leading-icon.color
  static const TokenColorRole disabledLeadingIconColor =
      TokenColorRole.onSurface;

  /// md.comp.filled-text-field.input-text.placeholder.color
  static const TokenColorRole inputTextPlaceholderColor =
      TokenColorRole.onSurfaceVariant;

  /// md.comp.filled-text-field.hover.supporting-text.color
  static const TokenColorRole hoverSupportingTextColor =
      TokenColorRole.onSurfaceVariant;

  /// md.comp.filled-text-field.label-text.color
  static const TokenColorRole labelTextColor = TokenColorRole.onSurfaceVariant;

  /// md.comp.filled-text-field.hover.state-layer.color
  static const TokenColorRole hoverStateLayerColor = TokenColorRole.onSurface;

  /// md.comp.filled-text-field.error.hover.state-layer.color
  static const TokenColorRole errorHoverStateLayerColor =
      TokenColorRole.onSurface;

  /// md.comp.filled-text-field.error.focus.leading-icon.color
  static const TokenColorRole errorFocusLeadingIconColor =
      TokenColorRole.onSurfaceVariant;

  /// md.comp.filled-text-field.hover.active-indicator.height
  static const double hoverActiveIndicatorHeight = 1.00;

  /// md.comp.filled-text-field.hover.trailing-icon.color
  static const TokenColorRole hoverTrailingIconColor =
      TokenColorRole.onSurfaceVariant;

  /// md.comp.filled-text-field.trailing-icon.size
  static const double trailingIconSize = 24.00;

  /// md.comp.filled-text-field.hover.label-text.color
  static const TokenColorRole hoverLabelTextColor =
      TokenColorRole.onSurfaceVariant;

  /// md.comp.filled-text-field.error.focus.active-indicator.color
  static const TokenColorRole errorFocusActiveIndicatorColor =
      TokenColorRole.error;

  /// md.comp.filled-text-field.input-text.color
  static const TokenColorRole inputTextColor = TokenColorRole.onSurface;

  /// md.comp.filled-text-field.error.hover.active-indicator.color
  static const TokenColorRole errorHoverActiveIndicatorColor =
      TokenColorRole.onErrorContainer;

  /// md.comp.filled-text-field.active-indicator.color
  static const TokenColorRole activeIndicatorColor =
      TokenColorRole.onSurfaceVariant;

  /// md.comp.filled-text-field.disabled.container.color
  static const TokenColorRole disabledContainerColor = TokenColorRole.onSurface;

  /// md.comp.filled-text-field.error.leading-icon.color
  static const TokenColorRole errorLeadingIconColor =
      TokenColorRole.onSurfaceVariant;

  /// md.comp.filled-text-field.caret.color
  static const TokenColorRole caretColor = TokenColorRole.primary;

  /// md.comp.filled-text-field.focus.active-indicator.thickness
  static const double focusActiveIndicatorThickness = 3.00;

  /// md.comp.filled-text-field.label-text.font
  static const String labelTextFont = 'Roboto';

  /// md.comp.filled-text-field.error.active-indicator.color
  static const TokenColorRole errorActiveIndicatorColor = TokenColorRole.error;

  /// md.comp.filled-text-field.disabled.label-text.color
  static const TokenColorRole disabledLabelTextColor = TokenColorRole.onSurface;

  /// md.comp.filled-text-field.error.hover.supporting-text.color
  static const TokenColorRole errorHoverSupportingTextColor =
      TokenColorRole.error;

  /// md.comp.filled-text-field.focus.input-text.color
  static const TokenColorRole focusInputTextColor = TokenColorRole.onSurface;

  /// md.comp.filled-text-field.supporting-text.type
  static const double supportingTextTypeFontSize = 12.00;

  /// md.comp.filled-text-field.supporting-text.type
  static const double supportingTextTypeFontWeight = 400;

  /// md.comp.filled-text-field.supporting-text.type
  static const double supportingTextTypeLineHeight = 16.00;

  /// md.comp.filled-text-field.supporting-text.type
  static const double supportingTextTypeLetterSpacing = 0.40;

  /// md.comp.filled-text-field.supporting-text.type
  static const String supportingTextTypeFontFamily = 'Roboto';

  /// md.comp.filled-text-field.hover.input-text.color
  static const TokenColorRole hoverInputTextColor = TokenColorRole.onSurface;

  /// md.comp.filled-text-field.error.supporting-text.color
  static const TokenColorRole errorSupportingTextColor = TokenColorRole.error;

  /// md.comp.filled-text-field.hover.active-indicator.color
  static const TokenColorRole hoverActiveIndicatorColor =
      TokenColorRole.onSurface;

  /// md.comp.filled-text-field.container.shape
  static const ShapeStruct containerShape = ShapeStruct(
    family: 'SHAPE_FAMILY_ROUNDED_CORNERS',
    topLeft: 4.00,
    topRight: 4.00,
    bottomLeft: 0.00,
    bottomRight: 0.00,
  );

  /// md.comp.filled-text-field.supporting-text.color
  static const TokenColorRole supportingTextColor =
      TokenColorRole.onSurfaceVariant;

  /// md.comp.filled-text-field.error.focus.input-text.color
  static const TokenColorRole errorFocusInputTextColor =
      TokenColorRole.onSurface;

  /// md.comp.filled-text-field.error.focus.caret.color
  static const TokenColorRole errorFocusCaretColor = TokenColorRole.error;

  /// md.comp.filled-text-field.input-text.prefix.color
  static const TokenColorRole inputTextPrefixColor =
      TokenColorRole.onSurfaceVariant;

  /// md.comp.filled-text-field.active-indicator.height
  static const double activeIndicatorHeight = 1.00;

  /// md.comp.filled-text-field.focus.active-indicator.color
  static const TokenColorRole focusActiveIndicatorColor =
      TokenColorRole.primary;

  /// md.comp.filled-text-field.leading-icon.color
  static const TokenColorRole leadingIconColor =
      TokenColorRole.onSurfaceVariant;

  /// md.comp.filled-text-field.focus.supporting-text.color
  static const TokenColorRole focusSupportingTextColor =
      TokenColorRole.onSurfaceVariant;

  /// md.comp.filled-text-field.error.hover.input-text.color
  static const TokenColorRole errorHoverInputTextColor =
      TokenColorRole.onSurface;

  /// md.comp.filled-text-field.error.trailing-icon.color
  static const TokenColorRole errorTrailingIconColor = TokenColorRole.error;

  /// md.comp.filled-text-field.disabled.active-indicator.height
  static const double disabledActiveIndicatorHeight = 1.00;

  /// md.comp.filled-text-field.leading-icon.size
  static const double leadingIconSize = 24.00;

  /// md.comp.filled-text-field.error.hover.label-text.color
  static const TokenColorRole errorHoverLabelTextColor =
      TokenColorRole.onErrorContainer;

  /// md.comp.filled-text-field.input-text.suffix.color
  static const TokenColorRole inputTextSuffixColor =
      TokenColorRole.onSurfaceVariant;
}
