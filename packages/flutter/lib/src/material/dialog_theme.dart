// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Defines a theme for [Dialog] widgets.
///
/// Descendant widgets obtain the current [DialogTheme] object using
/// `DialogTheme.of(context)`. Instances of [DialogTheme] can be customized with
/// [DialogTheme.copyWith].
///
/// [titleTextStyle] and [contentTextStyle] are used in [AlertDialog]s and [SimpleDialog]s.
///
/// See also:
///
///  * [Dialog], a dialog that can be customized using this [DialogTheme].
///  * [AlertDialog], a dialog that can be customized using this [DialogTheme].
///  * [SimpleDialog], a dialog that can be customized using this [DialogTheme].
///  * [ThemeData], which describes the overall theme information for the
///    application.
@immutable
class DialogTheme with Diagnosticable {
  /// Creates a dialog theme that can be used for [ThemeData.dialogTheme].
  const DialogTheme({
    this.backgroundColor,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.shape,
    this.alignment,
    this.iconColor,
    this.titleTextStyle,
    this.contentTextStyle,
    this.actionsPadding,
    this.barrierColor,
    this.insetPadding,
  });

  /// Overrides the default value for [Dialog.backgroundColor].
  final Color? backgroundColor;

  /// Overrides the default value for [Dialog.elevation].
  final double? elevation;

  /// Overrides the default value for [Dialog.shadowColor].
  final Color? shadowColor;

  /// Overrides the default value for [Dialog.surfaceTintColor].
  final Color? surfaceTintColor;

  /// Overrides the default value for [Dialog.shape].
  final ShapeBorder? shape;

  /// Overrides the default value for [Dialog.alignment].
  final AlignmentGeometry? alignment;

  /// Overrides the default value for [DefaultTextStyle] for [SimpleDialog.title] and
  /// [AlertDialog.title].
  final TextStyle? titleTextStyle;

  /// Overrides the default value for [DefaultTextStyle] for [SimpleDialog.children] and
  /// [AlertDialog.content].
  final TextStyle? contentTextStyle;

  /// Overrides the default value for [AlertDialog.actionsPadding].
  final EdgeInsetsGeometry? actionsPadding;

  /// Used to configure the [IconTheme] for the [AlertDialog.icon] widget.
  final Color? iconColor;

  /// Overrides the default value for [barrierColor] in [showDialog].
  final Color? barrierColor;

  /// Overrides the default value for [Dialog.insetPadding].
  final EdgeInsets? insetPadding;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  DialogTheme copyWith({
    Color? backgroundColor,
    double? elevation,
    Color? shadowColor,
    Color? surfaceTintColor,
    ShapeBorder? shape,
    AlignmentGeometry? alignment,
    Color? iconColor,
    TextStyle? titleTextStyle,
    TextStyle? contentTextStyle,
    EdgeInsetsGeometry? actionsPadding,
    Color? barrierColor,
    EdgeInsets? insetPadding,
  }) {
    return DialogTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      elevation: elevation ?? this.elevation,
      shadowColor: shadowColor ?? this.shadowColor,
      surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
      shape: shape ?? this.shape,
      alignment: alignment ?? this.alignment,
      iconColor: iconColor ?? this.iconColor,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      contentTextStyle: contentTextStyle ?? this.contentTextStyle,
      actionsPadding: actionsPadding ?? this.actionsPadding,
      barrierColor: barrierColor ?? this.barrierColor,
      insetPadding: insetPadding ?? this.insetPadding,
    );
  }

  /// The data from the closest [DialogTheme] instance given the build context.
  static DialogTheme of(BuildContext context) {
    return Theme.of(context).dialogTheme;
  }

  /// Linearly interpolate between two dialog themes.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static DialogTheme lerp(DialogTheme? a, DialogTheme? b, double t) {
    if (identical(a, b) && a != null) {
      return a;
    }
    return DialogTheme(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      shadowColor: Color.lerp(a?.shadowColor, b?.shadowColor, t),
      surfaceTintColor: Color.lerp(a?.surfaceTintColor, b?.surfaceTintColor, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
      alignment: AlignmentGeometry.lerp(a?.alignment, b?.alignment, t),
      iconColor: Color.lerp(a?.iconColor, b?.iconColor, t),
      titleTextStyle: TextStyle.lerp(a?.titleTextStyle, b?.titleTextStyle, t),
      contentTextStyle: TextStyle.lerp(a?.contentTextStyle, b?.contentTextStyle, t),
      actionsPadding: EdgeInsetsGeometry.lerp(a?.actionsPadding, b?.actionsPadding, t),
      barrierColor: Color.lerp(a?.barrierColor, b?.barrierColor, t),
      insetPadding: EdgeInsets.lerp(a?.insetPadding, b?.insetPadding, t),
    );
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    backgroundColor,
    elevation,
    shadowColor,
    surfaceTintColor,
    shape,
    alignment,
    iconColor,
    titleTextStyle,
    contentTextStyle,
    actionsPadding,
    barrierColor,
    insetPadding,
  ]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is DialogTheme
        && other.backgroundColor == backgroundColor
        && other.elevation == elevation
        && other.shadowColor == shadowColor
        && other.surfaceTintColor == surfaceTintColor
        && other.shape == shape
        && other.alignment == alignment
        && other.iconColor == iconColor
        && other.titleTextStyle == titleTextStyle
        && other.contentTextStyle == contentTextStyle
        && other.actionsPadding == actionsPadding
        && other.barrierColor == barrierColor
        && other.insetPadding == insetPadding;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('backgroundColor', backgroundColor));
    properties.add(DoubleProperty('elevation', elevation));
    properties.add(ColorProperty('shadowColor', shadowColor));
    properties.add(ColorProperty('surfaceTintColor', surfaceTintColor));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
    properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment, defaultValue: null));
    properties.add(ColorProperty('iconColor', iconColor));
    properties.add(DiagnosticsProperty<TextStyle>('titleTextStyle', titleTextStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('contentTextStyle', contentTextStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('actionsPadding', actionsPadding, defaultValue: null));
    properties.add(ColorProperty('barrierColor', barrierColor));
    properties.add(DiagnosticsProperty<EdgeInsets>('insetPadding', insetPadding, defaultValue: null));
  }
}
