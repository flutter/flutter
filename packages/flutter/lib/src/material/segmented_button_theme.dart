// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'material_state.dart';
import 'theme.dart';

/// Defines the color and border properties of [SegmentedButton] widgets.
///
/// Used by [SegmentedButtonTheme] to control the color and border properties
/// of toggle buttons in a widget subtree.
///
/// To obtain the current [SegmentedButtonTheme], use [SegmentedButtonTheme.of].
///
/// Values specified here are used for [SegmentedButton] properties that are not
/// given an explicit non-null value.
///
/// See also:
///
///  * [SegmentedButtonTheme], which describes the actual configuration of a
///    toggle buttons theme.
@immutable
class SegmentedButtonThemeData with Diagnosticable {
  /// Creates the set of color and border properties used to configure
  /// [SegmentedButton].
  const SegmentedButtonThemeData({
    this.backgroundColor,
    this.foregroundColor,
    this.overlayColor,
    this.textStyle,
    this.iconSize,
    this.startSegmentShape,
    this.segmentShape,
    this.endSegmentShape,
    this.divider,
  });

  final MaterialStateProperty<Color?>? backgroundColor;
  final MaterialStateProperty<Color?>? foregroundColor;
  final MaterialStateProperty<Color?>? overlayColor;
  final MaterialStateProperty<TextStyle?>? textStyle;
  final MaterialStateProperty<double?>? iconSize;

  final MaterialStateProperty<OutlinedBorder?>? startSegmentShape;
  final MaterialStateProperty<OutlinedBorder?>? segmentShape;
  final MaterialStateProperty<OutlinedBorder?>? endSegmentShape;
  final MaterialStateProperty<BorderSide?>? divider;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  SegmentedButtonThemeData copyWith({
    MaterialStateProperty<Color?>? backgroundColor,
    MaterialStateProperty<Color?>? foregroundColor,
    MaterialStateProperty<Color?>? overlayColor,
    MaterialStateProperty<TextStyle?>? textStyle,
    MaterialStateProperty<double?>? iconSize,
    MaterialStateProperty<OutlinedBorder?>? startSegmentShape,
    MaterialStateProperty<OutlinedBorder?>? segmentShape,
    MaterialStateProperty<OutlinedBorder?>? endSegmentShape,
    MaterialStateProperty<BorderSide?>? divider,
  }) {
    return SegmentedButtonThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      overlayColor: overlayColor ?? this.overlayColor,
      textStyle: textStyle ?? this.textStyle,
      iconSize: iconSize ?? this.iconSize,
      startSegmentShape: startSegmentShape ?? this.startSegmentShape,
      segmentShape: segmentShape ?? this.segmentShape,
      endSegmentShape: endSegmentShape ?? this.endSegmentShape,
      divider: divider ?? this.divider,
    );
  }

  /// Linearly interpolate between two toggle buttons themes.
  static SegmentedButtonThemeData lerp(SegmentedButtonThemeData? a, SegmentedButtonThemeData? b, double t) {
    return SegmentedButtonThemeData(
      backgroundColor: MaterialStateProperty.lerp<Color?>(a?.backgroundColor, b?.backgroundColor, t, Color.lerp),
      foregroundColor: MaterialStateProperty.lerp<Color?>(a?.foregroundColor, b?.foregroundColor, t, Color.lerp),
      overlayColor: MaterialStateProperty.lerp<Color?>(a?.overlayColor, b?.overlayColor, t, Color.lerp),
      textStyle: MaterialStateProperty.lerp<TextStyle?>(a?.textStyle, b?.textStyle, t, TextStyle.lerp),
      iconSize: MaterialStateProperty.lerp<double?>(a?.iconSize, b?.iconSize, t, lerpDouble),
      startSegmentShape: MaterialStateProperty.lerp<OutlinedBorder?>(a?.startSegmentShape, b?.startSegmentShape, t, OutlinedBorder.lerp),
      segmentShape: MaterialStateProperty.lerp<OutlinedBorder?>(a?.segmentShape, b?.segmentShape, t, OutlinedBorder.lerp),
      endSegmentShape: MaterialStateProperty.lerp<OutlinedBorder?>(a?.endSegmentShape, b?.endSegmentShape, t, OutlinedBorder.lerp),
      divider: MaterialStateProperty.lerp<BorderSide?>(a?.divider, b?.divider, t, _lerpBorderSide),
    );
  }

  static BorderSide? _lerpBorderSide(BorderSide? a, BorderSide? b, double t) {
    if (a == null || b == null) {
      return t > 0.5 ? b : a;
    }
    return BorderSide.lerp(a, b, t);
  }

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    overlayColor,
    textStyle,
    iconSize,
    startSegmentShape,
    segmentShape,
    endSegmentShape,
    divider,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SegmentedButtonThemeData
        && other.backgroundColor == backgroundColor
        && other.foregroundColor == foregroundColor
        && other.overlayColor == overlayColor
        && other.textStyle == textStyle
        && other.iconSize == iconSize
        && other.startSegmentShape == startSegmentShape
        && other.segmentShape == segmentShape
        && other.endSegmentShape == endSegmentShape
        && other.divider == divider;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('foregroundColor', foregroundColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('overlayColor', overlayColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<TextStyle?>>('textStyle', textStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<double?>>('iconSize', iconSize, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<OutlinedBorder?>>('startSegmentShape', startSegmentShape, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<OutlinedBorder?>>('segmentShape', segmentShape, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<OutlinedBorder?>>('endSegmentShape', endSegmentShape, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<BorderSide?>>('divider', divider, defaultValue: null));
  }
}

/// An inherited widget that defines color and border parameters for
/// [SegmentedButton] in this widget's subtree.
///
/// Values specified here are used for [SegmentedButton] properties that are not
/// given an explicit non-null value.
class SegmentedButtonTheme extends InheritedTheme {
  /// Creates a toggle buttons theme that controls the color and border
  /// parameters for [SegmentedButton].
  ///
  /// The data argument must not be null.
  const SegmentedButtonTheme({
    super.key,
    required this.data,
    required super.child,
  }) : assert(data != null);

  /// Specifies the color and border values for descendant [SegmentedButton] widgets.
  final SegmentedButtonThemeData data;

  /// The closest instance of this class that encloses the given context.
  ///
  /// If there is no enclosing [SegmentedButtonTheme] widget, then
  /// [ThemeData.segmentedButtonTheme] is used.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// SegmentedButtonThemeData theme = SegmentedButtonTheme.of(context);
  /// ```
  static SegmentedButtonThemeData of(BuildContext context) {
    final SegmentedButtonTheme? segmentedButtonTheme = context.dependOnInheritedWidgetOfExactType<SegmentedButtonTheme>();
    return segmentedButtonTheme?.data ?? Theme.of(context).segmentedButtonTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return SegmentedButtonTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(SegmentedButtonTheme oldWidget) => data != oldWidget.data;
}
