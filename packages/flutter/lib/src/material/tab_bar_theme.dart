// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'ink_well.dart';
import 'material_state.dart';
import 'tabs.dart';
import 'theme.dart';

/// Defines a theme for [TabBar] widgets.
///
/// A tab bar theme describes the color of the tab label and the size/shape of
/// the [TabBar.indicator].
///
/// Descendant widgets obtain the current theme's [TabBarTheme] object using
/// `TabBarTheme.of(context)`. Instances of [TabBarTheme] can be customized with
/// [TabBarTheme.copyWith].
///
/// See also:
///
///  * [TabBar], a widget that displays a horizontal row of tabs.
///  * [ThemeData], which describes the overall theme information for the
///    application.
@immutable
class TabBarTheme with Diagnosticable {
  /// Creates a tab bar theme that can be used with [ThemeData.tabBarTheme].
  const TabBarTheme({
    this.indicator,
    this.indicatorColor,
    this.indicatorSize,
    this.dividerColor,
    this.dividerHeight,
    this.labelColor,
    this.labelPadding,
    this.labelStyle,
    this.unselectedLabelColor,
    this.unselectedLabelStyle,
    this.overlayColor,
    this.splashFactory,
    this.mouseCursor,
    this.tabAlignment,
  });

  /// Overrides the default value for [TabBar.indicator].
  final Decoration? indicator;

  /// Overrides the default value for [TabBar.indicatorColor].
  final Color? indicatorColor;

  /// Overrides the default value for [TabBar.indicatorSize].
  final TabBarIndicatorSize? indicatorSize;

  /// Overrides the default value for [TabBar.dividerColor].
  final Color? dividerColor;

  /// Overrides the default value for [TabBar.dividerHeight].
  final double? dividerHeight;

  /// Overrides the default value for [TabBar.labelColor].
  ///
  /// If [labelColor] is a [MaterialStateColor], then the effective color will
  /// depend on the [MaterialState.selected] state, i.e. if the [Tab] is
  /// selected or not. In case of unselected state, this [MaterialStateColor]'s
  /// resolved color will be used even if [TabBar.unselectedLabelColor] or
  /// [unselectedLabelColor] is non-null.
  final Color? labelColor;

  /// Overrides the default value for [TabBar.labelPadding].
  ///
  /// If there are few tabs with both icon and text and few
  /// tabs with only icon or text, this padding is vertically
  /// adjusted to provide uniform padding to all tabs.
  final EdgeInsetsGeometry? labelPadding;

  /// Overrides the default value for [TabBar.labelStyle].
  final TextStyle? labelStyle;

  /// Overrides the default value for [TabBar.unselectedLabelColor].
  final Color? unselectedLabelColor;

  /// Overrides the default value for [TabBar.unselectedLabelStyle].
  final TextStyle? unselectedLabelStyle;

  /// Overrides the default value for [TabBar.overlayColor].
  final MaterialStateProperty<Color?>? overlayColor;

  /// Overrides the default value for [TabBar.splashFactory].
  final InteractiveInkFeatureFactory? splashFactory;

  /// {@macro flutter.material.tabs.mouseCursor}
  ///
  /// If specified, overrides the default value of [TabBar.mouseCursor].
  final MaterialStateProperty<MouseCursor?>? mouseCursor;

  /// Overrides the default value for [TabBar.tabAlignment].
  final TabAlignment? tabAlignment;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  TabBarTheme copyWith({
    Decoration? indicator,
    Color? indicatorColor,
    TabBarIndicatorSize? indicatorSize,
    Color? dividerColor,
    double? dividerHeight,
    Color? labelColor,
    EdgeInsetsGeometry? labelPadding,
    TextStyle? labelStyle,
    Color? unselectedLabelColor,
    TextStyle? unselectedLabelStyle,
    MaterialStateProperty<Color?>? overlayColor,
    InteractiveInkFeatureFactory? splashFactory,
    MaterialStateProperty<MouseCursor?>? mouseCursor,
    TabAlignment? tabAlignment,
  }) {
    return TabBarTheme(
      indicator: indicator ?? this.indicator,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      indicatorSize: indicatorSize ?? this.indicatorSize,
      dividerColor: dividerColor ?? this.dividerColor,
      dividerHeight: dividerHeight ?? this.dividerHeight,
      labelColor: labelColor ?? this.labelColor,
      labelPadding: labelPadding ?? this.labelPadding,
      labelStyle: labelStyle ?? this.labelStyle,
      unselectedLabelColor: unselectedLabelColor ?? this.unselectedLabelColor,
      unselectedLabelStyle: unselectedLabelStyle ?? this.unselectedLabelStyle,
      overlayColor: overlayColor ?? this.overlayColor,
      splashFactory: splashFactory ?? this.splashFactory,
      mouseCursor: mouseCursor ?? this.mouseCursor,
      tabAlignment: tabAlignment ?? this.tabAlignment,
    );
  }

  /// The data from the closest [TabBarTheme] instance given the build context.
  static TabBarTheme of(BuildContext context) {
    return Theme.of(context).tabBarTheme;
  }

  /// Linearly interpolate between two tab bar themes.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static TabBarTheme lerp(TabBarTheme a, TabBarTheme b, double t) {
    if (identical(a, b)) {
      return a;
    }
    return TabBarTheme(
      indicator: Decoration.lerp(a.indicator, b.indicator, t),
      indicatorColor: Color.lerp(a.indicatorColor, b.indicatorColor, t),
      indicatorSize: t < 0.5 ? a.indicatorSize : b.indicatorSize,
      dividerColor: Color.lerp(a.dividerColor, b.dividerColor, t),
      dividerHeight: t < 0.5 ? a.dividerHeight : b.dividerHeight,
      labelColor: Color.lerp(a.labelColor, b.labelColor, t),
      labelPadding: EdgeInsetsGeometry.lerp(a.labelPadding, b.labelPadding, t),
      labelStyle: TextStyle.lerp(a.labelStyle, b.labelStyle, t),
      unselectedLabelColor: Color.lerp(a.unselectedLabelColor, b.unselectedLabelColor, t),
      unselectedLabelStyle: TextStyle.lerp(a.unselectedLabelStyle, b.unselectedLabelStyle, t),
      overlayColor: MaterialStateProperty.lerp<Color?>(a.overlayColor, b.overlayColor, t, Color.lerp),
      splashFactory: t < 0.5 ? a.splashFactory : b.splashFactory,
      mouseCursor: t < 0.5 ? a.mouseCursor : b.mouseCursor,
      tabAlignment: t < 0.5 ? a.tabAlignment : b.tabAlignment,
    );
  }

  @override
  int get hashCode => Object.hash(
    indicator,
    indicatorColor,
    indicatorSize,
    dividerColor,
    dividerHeight,
    labelColor,
    labelPadding,
    labelStyle,
    unselectedLabelColor,
    unselectedLabelStyle,
    overlayColor,
    splashFactory,
    mouseCursor,
    tabAlignment,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is TabBarTheme
        && other.indicator == indicator
        && other.indicatorColor == indicatorColor
        && other.indicatorSize == indicatorSize
        && other.dividerColor == dividerColor
        && other.dividerHeight == dividerHeight
        && other.labelColor == labelColor
        && other.labelPadding == labelPadding
        && other.labelStyle == labelStyle
        && other.unselectedLabelColor == unselectedLabelColor
        && other.unselectedLabelStyle == unselectedLabelStyle
        && other.overlayColor == overlayColor
        && other.splashFactory == splashFactory
        && other.mouseCursor == mouseCursor
        && other.tabAlignment == tabAlignment;
  }
}
