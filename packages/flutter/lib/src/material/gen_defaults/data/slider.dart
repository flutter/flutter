// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Version: 34.1.18

import 'color_role.dart';
import 'shape_struct.dart';

class TokenSlider {
  /// md.comp.slider.active.track.outer-corner.corner-size
  static const ShapeStruct activeTrackOuterCornerCornerSize = ShapeStruct(
    family: 'SHAPE_FAMILY_CIRCULAR',
    topLeft: 0.00,
    topRight: 0.00,
    bottomLeft: 0.00,
    bottomRight: 0.00,
  );

  /// md.comp.slider.pressed.inactive.track.color
  static const TokenColorRole pressedInactiveTrackColor =
      TokenColorRole.secondaryContainer;

  /// md.comp.slider.slider-active-handle-color
  static const TokenColorRole sliderActiveHandleColor = TokenColorRole.primary;

  /// md.comp.slider.disabled.active.track.opacity
  static const double disabledActiveTrackOpacity = 0.38;

  /// md.comp.slider.focus.handle.width
  static const double focusHandleWidth = 2.00;

  /// md.comp.slider.handle.height
  static const double handleHeight = 44.00;

  /// md.comp.slider.disabled.inactive.track.color
  static const TokenColorRole disabledInactiveTrackColor =
      TokenColorRole.onSurface;

  /// md.comp.slider.active.track.inner-corner.corner-size
  static const ShapeStruct activeTrackInnerCornerCornerSize = ShapeStruct(
    family: 'SHAPE_FAMILY_ROUNDED_CORNERS',
    topLeft: 0.00,
    topRight: 2.00,
    bottomLeft: 0.00,
    bottomRight: 2.00,
  );

  /// md.comp.slider.pressed.active.track.color
  static const TokenColorRole pressedActiveTrackColor = TokenColorRole.primary;

  /// md.comp.slider.disabled.active.stop-indicator.container.color
  static const TokenColorRole disabledActiveStopIndicatorContainerColor =
      TokenColorRole.inverseOnSurface;

  /// md.comp.slider.disabled.handle.width
  static const double disabledHandleWidth = 4.00;

  /// md.comp.slider.inactive.track.shape
  static const ShapeStruct inactiveTrackShape = ShapeStruct(
    family: 'SHAPE_FAMILY_CIRCULAR',
    topLeft: 0.00,
    topRight: 0.00,
    bottomLeft: 0.00,
    bottomRight: 0.00,
  );

  /// md.comp.slider.disabled.handle.opacity
  static const double disabledHandleOpacity = 0.38;

  /// md.comp.slider.value-indicator.active.bottom-space
  static const double valueIndicatorActiveBottomSpace = 12.00;

  /// md.comp.slider.active.track.color
  static const TokenColorRole activeTrackColor = TokenColorRole.primary;

  /// md.comp.slider.stop-indicator.color-selected
  static const TokenColorRole stopIndicatorColorSelected =
      TokenColorRole.onPrimary;

  /// md.comp.slider.pressed.handle.color
  static const TokenColorRole pressedHandleColor = TokenColorRole.primary;

  /// md.comp.slider.handle.width
  static const double handleWidth = 4.00;

  /// md.comp.slider.value-indicator.label.label-text.font
  static const String valueIndicatorLabelLabelTextFont = 'Roboto';

  /// md.comp.slider.disabled.handle.color
  static const TokenColorRole disabledHandleColor = TokenColorRole.onSurface;

  /// md.comp.slider.focus.inactive.track.color
  static const TokenColorRole focusInactiveTrackColor =
      TokenColorRole.secondaryContainer;

  /// md.comp.slider.active.stop-indicator.container.opacity
  static const double activeStopIndicatorContainerOpacity = 1.00;

  /// md.comp.slider.pressed.handle.width
  static const double pressedHandleWidth = 2.00;

  /// md.comp.slider.stop-indicator.size
  static const double stopIndicatorSize = 4.00;

  /// md.comp.slider.hover.handle.width
  static const double hoverHandleWidth = 4.00;

  /// md.comp.slider.active.handle.height
  static const double activeHandleHeight = 44.00;

  /// md.comp.slider.value-indicator.label.label-text.color
  static const TokenColorRole valueIndicatorLabelLabelTextColor =
      TokenColorRole.inverseOnSurface;

  /// md.comp.slider.inactive.stop-indicator.container.opacity
  static const double inactiveStopIndicatorContainerOpacity = 1.00;

  /// md.comp.slider.active.handle.leading-space
  static const double activeHandleLeadingSpace = 6.00;

  /// md.comp.slider.active.track.shape
  static const ShapeStruct activeTrackShape = ShapeStruct(
    family: 'SHAPE_FAMILY_CIRCULAR',
    topLeft: 0.00,
    topRight: 0.00,
    bottomLeft: 0.00,
    bottomRight: 0.00,
  );

  /// md.comp.slider.disabled.inactive.track.opacity
  static const double disabledInactiveTrackOpacity = 0.12;

  /// md.comp.slider.active.handle.trailing-space
  static const double activeHandleTrailingSpace = 6.00;

  /// md.comp.slider.inactive.stop-indicator.container.color
  static const TokenColorRole inactiveStopIndicatorContainerColor =
      TokenColorRole.onSecondaryContainer;

  /// md.comp.slider.stop-indicator.trailing-space
  static const double stopIndicatorTrailingSpace = 4.00;

  /// md.comp.slider.inactive.track.color
  static const TokenColorRole inactiveTrackColor =
      TokenColorRole.secondaryContainer;

  /// md.comp.slider.handle.shape
  static const ShapeStruct handleShape = ShapeStruct(
    family: 'SHAPE_FAMILY_CIRCULAR',
    topLeft: 0.00,
    topRight: 0.00,
    bottomLeft: 0.00,
    bottomRight: 0.00,
  );

  /// md.comp.slider.value-indicator.container.color
  static const TokenColorRole valueIndicatorContainerColor =
      TokenColorRole.inverseSurface;

  /// md.comp.slider.active.handle.shape
  static const ShapeStruct activeHandleShape = ShapeStruct(
    family: 'SHAPE_FAMILY_CIRCULAR',
    topLeft: 0.00,
    topRight: 0.00,
    bottomLeft: 0.00,
    bottomRight: 0.00,
  );

  /// md.comp.slider.active.handle.width
  static const double activeHandleWidth = 4.00;

  /// md.comp.slider.stop-indicator.shape
  static const ShapeStruct stopIndicatorShape = ShapeStruct(
    family: 'SHAPE_FAMILY_CIRCULAR',
    topLeft: 0.00,
    topRight: 0.00,
    bottomLeft: 0.00,
    bottomRight: 0.00,
  );

  /// md.comp.slider.active.track.height
  static const double activeTrackHeight = 16.00;

  /// md.comp.slider.inactive.track.height
  static const double inactiveTrackHeight = 16.00;

  /// md.comp.slider.disabled.inactive.stop-indicator.container.color
  static const TokenColorRole disabledInactiveStopIndicatorContainerColor =
      TokenColorRole.onSurface;

  /// md.comp.slider.handle.color
  static const TokenColorRole handleColor = TokenColorRole.primary;

  /// md.comp.slider.stop-indicator.color
  static const TokenColorRole stopIndicatorColor =
      TokenColorRole.onSecondaryContainer;

  /// md.comp.slider.active.stop-indicator.container.color
  static const TokenColorRole activeStopIndicatorContainerColor =
      TokenColorRole.onPrimary;

  /// md.comp.slider.disabled.active.track.color
  static const TokenColorRole disabledActiveTrackColor =
      TokenColorRole.onSurface;

  /// md.comp.slider.active.handle.padding
  static const double activeHandlePadding = 6.00;

  /// md.comp.slider.focus.active.track.color
  static const TokenColorRole focusActiveTrackColor = TokenColorRole.primary;
}
