// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Defines the visual properties of [Tooltip] widgets.
///
/// Used by [TooltipTheme] to control the visual properties of tooltips in a
/// widget subtree.
///
/// To obtain this configuration, use [TooltipTheme.of] to access the closest
/// ancestor [TooltipTheme] of the current [BuildContext].
///
/// See also:
///
///  * [TooltipTheme], an [InheritedWidget] that propagates the theme down its
///    subtree.
///  * [TooltipThemeData], which describes the actual configuration of a
///    tooltip theme.
@immutable
class TooltipThemeData with Diagnosticable {
  /// Creates the set of properties used to configure [Tooltip]s.
  const TooltipThemeData({
    this.height,
    this.padding,
    this.margin,
    this.verticalOffset,
    this.preferBelow,
    this.excludeFromSemantics,
    this.decoration,
    this.textStyle,
    this.waitDuration,
    this.showDuration,
  });

  /// The height of [Tooltip.child].
  final double height;

  /// If provided, the amount of space by which to inset [Tooltip.child].
  final EdgeInsetsGeometry padding;

  /// If provided, the amount of empty space to surround the [Tooltip].
  final EdgeInsetsGeometry margin;

  /// The vertical gap between the widget and the displayed tooltip.
  ///
  /// When [preferBelow] is set to true and tooltips have sufficient space to
  /// display themselves, this property defines how much vertical space
  /// tooltips will position themselves under their corresponding widgets.
  /// Otherwise, tooltips will position themselves above their corresponding
  /// widgets with the given offset.
  final double verticalOffset;

  /// Whether the tooltip is displayed below its widget by default.
  ///
  /// If there is insufficient space to display the tooltip in the preferred
  /// direction, the tooltip will be displayed in the opposite direction.
  final bool preferBelow;

  /// Whether the [Tooltip.message] should be excluded from the semantics
  /// tree.
  ///
  /// By default, [Tooltip]s will add a [Semantics] label that is set to
  /// [Tooltip.message]. Set this property to true if the app is going to
  /// provide its own custom semantics label.
  final bool excludeFromSemantics;

  /// The [Tooltip]'s shape and background color.
  final Decoration decoration;

  /// The style to use for the message of [Tooltip]s.
  final TextStyle textStyle;

  /// The length of time that a pointer must hover over a tooltip's widget
  /// before the tooltip will be shown.
  final Duration waitDuration;

  /// The length of time that the tooltip will be shown once it has appeared.
  final Duration showDuration;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  TooltipThemeData copyWith({
    double height,
    EdgeInsetsGeometry padding,
    EdgeInsetsGeometry margin,
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
      margin: margin ?? this.margin,
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
  ///
  /// If both arguments are null, then null is returned.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static TooltipThemeData lerp(TooltipThemeData a, TooltipThemeData b, double t) {
    if (a == null && b == null)
      return null;
    assert(t != null);
    return TooltipThemeData(
      height: lerpDouble(a?.height, b?.height, t),
      padding: EdgeInsetsGeometry.lerp(a?.padding, b?.padding, t),
      margin: EdgeInsetsGeometry.lerp(a?.margin, b?.margin, t),
      verticalOffset: lerpDouble(a?.verticalOffset, b?.verticalOffset, t),
      preferBelow: t < 0.5 ? a.preferBelow: b.preferBelow,
      excludeFromSemantics: t < 0.5 ? a.excludeFromSemantics : b.excludeFromSemantics,
      decoration: Decoration.lerp(a?.decoration, b?.decoration, t),
      textStyle: TextStyle.lerp(a?.textStyle, b?.textStyle, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      height,
      padding,
      margin,
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
    return other is TooltipThemeData
        && other.height == height
        && other.padding == padding
        && other.margin == margin
        && other.verticalOffset == verticalOffset
        && other.preferBelow == preferBelow
        && other.excludeFromSemantics == excludeFromSemantics
        && other.decoration == decoration
        && other.textStyle == textStyle
        && other.waitDuration == waitDuration
        && other.showDuration == showDuration;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('margin', margin, defaultValue: null));
    properties.add(DoubleProperty('vertical offset', verticalOffset, defaultValue: null));
    properties.add(FlagProperty('position', value: preferBelow, ifTrue: 'below', ifFalse: 'above', showName: true, defaultValue: null));
    properties.add(FlagProperty('semantics', value: excludeFromSemantics, ifTrue: 'excluded', showName: true, defaultValue: null));
    properties.add(DiagnosticsProperty<Decoration>('decoration', decoration, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('textStyle', textStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<Duration>('wait duration', waitDuration, defaultValue: null));
    properties.add(DiagnosticsProperty<Duration>('show duration', showDuration, defaultValue: null));
  }
}

/// An inherited widget that defines the configuration for
/// [Tooltip]s in this widget's subtree.
///
/// Values specified here are used for [Tooltip] properties that are not
/// given an explicit non-null value.
///
/// {@tool snippet}
///
/// Here is an example of a tooltip theme that applies a blue foreground
/// with non-rounded corners.
///
/// ```dart
/// TooltipTheme(
///   data: TooltipThemeData(
///     decoration: BoxDecoration(
///       color: Colors.blue.withOpacity(0.9),
///       borderRadius: BorderRadius.zero,
///     ),
///   ),
///   child: Tooltip(
///     message: 'Example tooltip',
///     child: IconButton(
///       iconSize: 36.0,
///       icon: Icon(Icons.touch_app),
///       onPressed: () {},
///     ),
///   ),
/// ),
/// ```
/// {@end-tool}
class TooltipTheme extends InheritedTheme {
  /// Creates a tooltip theme that controls the configurations for
  /// [Tooltip].
  ///
  /// The data argument must not be null.
  const TooltipTheme({
    Key key,
    @required this.data,
    Widget child,
  }) : assert(data != null), super(key: key, child: child);

  /// The properties for descendant [Tooltip] widgets.
  final TooltipThemeData data;

  /// Returns the [data] from the closest [TooltipTheme] ancestor. If there is
  /// no ancestor, it returns [ThemeData.tooltipTheme]. Applications can assume
  /// that the returned value will not be null.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// TooltipThemeData theme = TooltipTheme.of(context);
  /// ```
  static TooltipThemeData of(BuildContext context) {
    final TooltipTheme tooltipTheme = context.dependOnInheritedWidgetOfExactType<TooltipTheme>();
    return tooltipTheme?.data ?? Theme.of(context).tooltipTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    final TooltipTheme ancestorTheme = context.findAncestorWidgetOfExactType<TooltipTheme>();
    return identical(this, ancestorTheme) ? child : TooltipTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(TooltipTheme oldWidget) => data != oldWidget.data;
}
