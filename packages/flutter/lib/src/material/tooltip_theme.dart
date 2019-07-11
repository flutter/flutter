// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Defines the properties of [Tooltip] widgets.
///
/// Used by [TooltipTheme] to control the properties of tooltips in a widget
/// subtree.
///
/// To obtain the current [TooltipTheme], use [TooltipTheme.of].
///
/// See also:
///
///  * [TooltipTheme], which describes the actual configuration of a
///    tooltip theme.
class TooltipThemeData extends Diagnosticable {
  /// Creates the set of properties used to configure [Tooltip]s.
  const TooltipThemeData({
    this.height = _defaultTooltipHeight,
    this.padding = _defaultPadding,
    this.verticalOffset = _defaultVerticalOffset,
    this.preferBelow = true,
    this.excludeFromSemantics = false,
    this.decoration,
    this.textStyle,
    this.waitDuration = _defaultWaitDuration,
    this.showDuration = _defaultShowDuration,
  }) : assert(height != null),
       assert(padding != null),
       assert(verticalOffset != null),
       assert(preferBelow != null),
       assert(excludeFromSemantics != null),
       assert(waitDuration != null),
       assert(showDuration != null);

  static const Duration _defaultShowDuration = Duration(milliseconds: 1500);
  static const Duration _defaultWaitDuration = Duration(milliseconds: 0);
  static const double _defaultTooltipHeight = 32.0;
  static const double _defaultVerticalOffset = 24.0;
  static const EdgeInsetsGeometry _defaultPadding = EdgeInsets.symmetric(horizontal: 16.0);

  /// They height of the tooltip's [child].
  ///
  /// If the [child] is null, then this is the intrinsic height.
  final double height;

  /// The amount of space by which to inset the child.
  ///
  /// Defaults to 16.0 logical pixels in each direction.
  final EdgeInsetsGeometry padding;

  /// The vertical gap between the widget and the displayed tooltip.
  final double verticalOffset;

  /// Whether the tooltip defaults to being displayed below the widget.
  ///
  /// Defaults to true. If there is insufficient space to display the tooltip in
  /// the preferred direction, the tooltip will be displayed in the opposite
  /// direction.
  final bool preferBelow;

  /// Whether the tooltip's [message] should be excluded from the semantics
  /// tree.
  final bool excludeFromSemantics;

  /// Specifies the tooltip's shape and background color.
  ///
  /// If not specified, defaults to a rounded rectangle with a border radius of
  /// 4.0, and a color derived from the [ThemeData.textTheme] if the
  /// [ThemeData.brightness] is dark, and [ThemeData.primaryTextTheme] if not.
  final Decoration decoration;

  /// The style to use for the message of the tooltip.
  ///
  /// If null, the message's [TextStyle] will be determined based on
  /// [ThemeData]. If [ThemeData.brightness] is set to [Brightness.dark],
  /// [ThemeData.textTheme.body1] will be merged with
  /// [ThemeData.typography.white]. Otherwise, if [ThemeData.brightness] is set
  /// to [Brightness.light], [ThemeData.primaryTextTheme.body1] will be merged
  /// with [ThemeData.typography.white].
  final TextStyle textStyle;

  /// The amount of time that a pointer must hover over the widget before it
  /// will show a tooltip.
  ///
  /// Defaults to 0 milliseconds (tooltips show immediately upon hover).
  final Duration waitDuration;

  /// The amount of time that the tooltip will be shown once it has appeared.
  ///
  /// Defaults to 1.5 seconds.
  final Duration showDuration;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  TooltipThemeData copyWith({
    double height,
    EdgeInsetsGeometry padding,
    double verticalOffset,
    bool preferBelow,
    bool excludeFromSemantics,
    Decoration decoration,
    TextStyle textStyle,
    Duration waitDuration,
    Duration showDuration,
  }) {
    return TooltipThemeData(
      height: height ?? this.height,
      padding: padding ?? this.padding,
      verticalOffset: verticalOffset ?? this.verticalOffset,
      preferBelow: preferBelow ?? this.preferBelow,
      excludeFromSemantics: excludeFromSemantics ?? this.excludeFromSemantics,
      decoration: decoration ?? this.decoration,
      textStyle: textStyle ?? this.textStyle,
      waitDuration: waitDuration ?? this.waitDuration,
      showDuration: showDuration ?? this.showDuration,
    );
  }

  /// Linearly interpolate between two tooltip themes.
  static TooltipThemeData lerp(TooltipThemeData a, TooltipThemeData b, double t) {
    assert(t != null);
    assert(a?.preferBelow == b?.preferBelow);
    assert(a?.excludeFromSemantics == b?.excludeFromSemantics);
    if (a == null && b == null)
      return null;
    return TooltipThemeData(
      height: lerpDouble(a?.height, b?.height, t),
      padding: EdgeInsets.lerp(a?.padding, b?.padding, t),
      verticalOffset: lerpDouble(a?.verticalOffset, b?.verticalOffset, t),
      decoration: Decoration.lerp(a?.decoration, b?.decoration, t),
      textStyle: TextStyle.lerp(a?.textStyle, b?.textStyle, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      height,
      padding,
      verticalOffset,
      preferBelow,
      excludeFromSemantics,
      decoration,
      textStyle,
      waitDuration,
      showDuration,
    );
  }

  @override
  bool operator==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final TooltipThemeData typedOther = other;
    return typedOther.height == height
        && typedOther.padding == padding
        && typedOther.verticalOffset == verticalOffset
        && typedOther.preferBelow == preferBelow
        && typedOther.excludeFromSemantics == excludeFromSemantics
        && typedOther.decoration == decoration
        && typedOther.textStyle == textStyle
        && typedOther.waitDuration == waitDuration
        && typedOther.showDuration == showDuration;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('height', height, defaultValue: _defaultTooltipHeight));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding, defaultValue: _defaultPadding));
    properties.add(DoubleProperty('vertical offset', verticalOffset, defaultValue: _defaultVerticalOffset));
    properties.add(FlagProperty('position', value: preferBelow, ifTrue: 'below', ifFalse: 'above', showName: true));
    properties.add(FlagProperty('semantics', value: excludeFromSemantics, ifTrue: 'excluded', showName: true, defaultValue: false));
    properties.add(DiagnosticsProperty<Duration>('wait duration', waitDuration, defaultValue: _defaultWaitDuration));
    properties.add(DiagnosticsProperty<Duration>('show duration', showDuration, defaultValue: _defaultShowDuration));
  }
}

/// An inherited widget that defines the configuration for
/// [Tooltip]s in this widget's subtree.
///
/// Values specified here are used for [Tooltip] properties that are not
/// given an explicit non-null value.
class TooltipTheme extends InheritedWidget {
  /// Creates a toggle buttons theme that controls the configurations for
  /// [Tooltip].
  TooltipTheme({
    Key key,
    double height,
    EdgeInsetsGeometry padding,
    double verticalOffset,
    bool preferBelow,
    bool excludeFromSemantics,
    Decoration decoration,
    TextStyle textStyle,
    Duration waitDuration,
    Duration showDuration,
    Widget child,
  }) : data = TooltipThemeData(
         height: height,
         padding: padding,
         verticalOffset: verticalOffset,
         preferBelow: preferBelow,
         excludeFromSemantics: excludeFromSemantics,
         decoration: decoration,
         textStyle: textStyle,
         waitDuration: waitDuration,
         showDuration: showDuration,
       ),
       super(key: key, child: child);

  /// Specifies the properties for descendant [Tooltip] widgets.
  final TooltipThemeData data;

  /// The closest instance of this class that encloses the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// TooltipTheme theme = TooltipTheme.of(context);
  /// ```
  static TooltipThemeData of(BuildContext context) {
    final TooltipTheme tooltipTheme = context.inheritFromWidgetOfExactType(TooltipTheme);
    return tooltipTheme?.data ?? Theme.of(context).tooltipTheme;
  }

  @override
  bool updateShouldNotify(TooltipTheme oldWidget) => data != oldWidget.data;
}
