// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport '../action_buttons.dart';
/// @docImport '../app_bar.dart';
/// @docImport '../elevated_button.dart';
/// @docImport '../ink_decoration.dart';
/// @docImport '../outlined_button.dart';
/// @docImport '../text_button.dart';
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../button_style.dart';
import '../button_style_button.dart';
import '../color_scheme.dart';
import '../colors.dart';
import '../constants.dart';
import '../debug.dart';
import '../icon_button_theme.dart';
import '../icons.dart';
import '../ink_well.dart';
import '../material.dart';
import '../material_state.dart';
import '../theme.dart';
import '../theme_data.dart';
import '../tooltip.dart';
import '../material_3/icon_button.dart' as m3;

class IconButton extends ButtonStyleButton {
  IconButton({
    required super.onPressed,
    required super.child,
    super.onLongPress,
    super.onHover,
    super.onFocusChange,
    super.style,
    super.focusNode,
    super.autofocus = false,
    super.clipBehavior,
  });
}

// BEGIN GENERATED TOKEN PROPERTIES - IconButtonM3E

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   packages/flutter/lib/src/material/gen_defaults/bin/gen_defaults.dart.

// dart format off
class _IconButtonDefaultsM3E extends ButtonStyle {
  _IconButtonDefaultsM3E(this.context, this.toggleable)
    : super(
        animationDuration: kThemeChangeDuration,
        enableFeedback: true,
        alignment: Alignment.center,
      );

  final BuildContext context;
  final bool toggleable;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  // No default text style

  @override
  WidgetStateProperty<Color?>? get backgroundColor =>
    const MaterialStatePropertyAll<Color?>(Colors.transparent);

  @override
  WidgetStateProperty<Color?>? get foregroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return _colors.onSurface.withOpacity(0.38);
      }
      if (states.contains(WidgetState.selected)) {
        return _colors.primary;
      }
      return _colors.onSurfaceVariant;
    });

  @override
  WidgetStateProperty<Color?>? get overlayColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.pressed)) {
          return _colors.primary.withOpacity(0.1);
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.primary.withOpacity(0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.primary.withOpacity(0.1);
        }
      }
      if (states.contains(WidgetState.pressed)) {
        return _colors.onSurfaceVariant.withOpacity(0.1);
      }
      if (states.contains(WidgetState.hovered)) {
        return _colors.onSurfaceVariant.withOpacity(0.08);
      }
      if (states.contains(WidgetState.focused)) {
        return _colors.onSurfaceVariant.withOpacity(0.1);
      }
      return Colors.transparent;
    });

  @override
  WidgetStateProperty<double>? get elevation =>
    const MaterialStatePropertyAll<double>(0.0);

  @override
  WidgetStateProperty<Color>? get shadowColor =>
    const MaterialStatePropertyAll<Color>(Colors.transparent);

  @override
  WidgetStateProperty<Color>? get surfaceTintColor =>
    const MaterialStatePropertyAll<Color>(Colors.transparent);

  @override
  WidgetStateProperty<EdgeInsetsGeometry>? get padding =>
    const MaterialStatePropertyAll<EdgeInsetsGeometry>(EdgeInsets.all(8.0));

  @override
  WidgetStateProperty<Size>? get minimumSize =>
    const MaterialStatePropertyAll<Size>(Size(40.0, 40.0));

  // No default fixedSize

  @override
  WidgetStateProperty<Size>? get maximumSize =>
    const MaterialStatePropertyAll<Size>(Size.infinite);

  @override
  WidgetStateProperty<double>? get iconSize =>
    const MaterialStatePropertyAll<double>(24.0);

  @override
  WidgetStateProperty<BorderSide?>? get side => null;

  @override
  WidgetStateProperty<OutlinedBorder>? get shape =>
    const MaterialStatePropertyAll<OutlinedBorder>(StadiumBorder());

  @override
  WidgetStateProperty<MouseCursor?>? get mouseCursor => WidgetStateMouseCursor.adaptiveClickable;

  @override
  VisualDensity? get visualDensity => VisualDensity.standard;

  @override
  MaterialTapTargetSize? get tapTargetSize => Theme.of(context).materialTapTargetSize;

  @override
  InteractiveInkFeatureFactory? get splashFactory => Theme.of(context).splashFactory;
}
// dart format on
// END GENERATED TOKEN PROPERTIES - IconButtonM3E
