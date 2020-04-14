// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'bottom_navigation_bar.dart';
import 'theme.dart';

/// Defines default property values for descendant [BottomNavigationBar]
/// widgets.
///
/// Descendant widgets obtain the current [BottomNavigationBarThemeData] object
/// using `BottomNavigationBarTheme.of(context)`. Instances of
/// [BottomNavigationBar] can be customized with
/// [BottomNavigationBarThemeData.copyWith].
///
/// Typically a [BottomNavigationBarThemeData] is specified as part of the
/// overall [Theme] with [ThemeData.bottomNavigationBarTheme].
///
/// All [BottomNavigationBarThemeData] properties are `null` by default. When
/// null, the [BottomNavigationBar] constructor provides defaults.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
@immutable
class BottomNavigationBarThemeData with Diagnosticable {
  /// Creates a theme that can be used for [ThemeData.BottomNavigationBarTheme].
  const BottomNavigationBarThemeData({
    this.backgroundColor,
    this.elevation,
    this.selectedIconTheme,
    this.unselectedIconTheme,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.selectedLabelStyle,
    this.unselectedLabelStyle,
    this.showSelectedLabels,
    this.showUnselectedLabels,
    this.type,
  });

  /// Default value for [BottomNavigationBar.elevation].
  final double elevation;

  /// Default value for [BottomNavigationBar.type].
  final BottomNavigationBarType type;

  /// Default value for [BottomNavigationBar.backgroundColor].
  final Color backgroundColor;

  /// Default value for [BottomNavigationBar.selectedItemColor].
  final Color selectedItemColor;

  /// Default value for [BottomNavigationBar.unselectedItemColor].
  final Color unselectedItemColor;

  /// Default value for [BottomNavigationBar.selectedIconTheme].
  final IconThemeData selectedIconTheme;

  /// Default value for [BottomNavigationBar.unselectedIconTheme].
  final IconThemeData unselectedIconTheme;

  /// Default value for [BottomNavigationBar.selectedLabelStyle].
  final TextStyle selectedLabelStyle;

  /// Default value for [BottomNavigationBar.unselectedLabelStyle].
  final TextStyle unselectedLabelStyle;

  /// Default value for [BottomNavigationBar.showUnselectedLabels].
  final bool showUnselectedLabels;

  /// Default value for [BottomNavigationBar.showSelectedLabels].
  final bool showSelectedLabels;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  BottomNavigationBarThemeData copyWith({
    double elevation,
    BottomNavigationBarType type,
    Color backgroundColor,
    Color selectedItemColor,
    Color unselectedItemColor,
    IconThemeData selectedIconTheme,
    IconThemeData unselectedIconTheme,
    TextStyle selectedLabelStyle,
    TextStyle unselectedLabelStyle,
    bool showUnselectedLabels,
    bool showSelectedLabels,
  }) {
    return BottomNavigationBarThemeData(
      elevation: elevation ?? this.elevation,
      type: type ?? this.type,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      selectedItemColor: selectedItemColor ?? this.selectedItemColor,
      unselectedItemColor: unselectedItemColor ?? this.unselectedItemColor,
      selectedIconTheme: selectedIconTheme ?? this.selectedIconTheme,
      unselectedIconTheme: unselectedIconTheme ?? this.unselectedIconTheme,
      selectedLabelStyle: selectedLabelStyle ?? this.selectedLabelStyle,
      unselectedLabelStyle: unselectedLabelStyle ?? this.unselectedLabelStyle,
      showUnselectedLabels: showUnselectedLabels ?? this.showUnselectedLabels,
      showSelectedLabels: showSelectedLabels ?? this.showSelectedLabels,
    );
  }

  /// Linearly interpolate between two [BottomNavigationBarThemeData].
  ///
  /// The argument `t` must not be null.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static BottomNavigationBarThemeData lerp(BottomNavigationBarThemeData a, BottomNavigationBarThemeData b, double t) {
    assert(t != null);
    return BottomNavigationBarThemeData(
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      type: t < 0.5 ? a?.type : b?.type,
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      selectedItemColor: Color.lerp(a?.selectedItemColor, b?.selectedItemColor, t),
      unselectedItemColor: Color.lerp(a?.unselectedItemColor, b?.unselectedItemColor, t),
      selectedIconTheme: IconThemeData.lerp(a?.selectedIconTheme, b?.selectedIconTheme, t),
      unselectedIconTheme: IconThemeData.lerp(a?.unselectedIconTheme, b?.unselectedIconTheme, t),
      selectedLabelStyle: TextStyle.lerp(a?.selectedLabelStyle, b?.selectedLabelStyle, t),
      unselectedLabelStyle: TextStyle.lerp(a?.unselectedLabelStyle, b?.unselectedLabelStyle, t),
      showUnselectedLabels: t < 0.5 ? a?.showUnselectedLabels : b?.showUnselectedLabels,
      showSelectedLabels: t < 0.5 ? a?.showSelectedLabels : b?.showSelectedLabels,
    );
  }

  @override
  int get hashCode {
    return hashValues(
      elevation,
      type,
      backgroundColor,
      selectedItemColor,
      unselectedItemColor,
      selectedIconTheme,
      unselectedIconTheme,
      selectedLabelStyle,
      unselectedLabelStyle,
      showUnselectedLabels,
      showSelectedLabels,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is BottomNavigationBarThemeData
        && other.elevation == elevation
        && other.type == type
        && other.backgroundColor == backgroundColor
        && other.selectedItemColor == selectedItemColor
        && other.unselectedItemColor == unselectedItemColor
        && other.selectedIconTheme == selectedIconTheme
        && other.unselectedIconTheme == unselectedIconTheme
        && other.selectedLabelStyle == selectedLabelStyle
        && other.unselectedLabelStyle == unselectedLabelStyle
        && other.showUnselectedLabels == showUnselectedLabels
        && other.showSelectedLabels == showSelectedLabels;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<double>('elevation', elevation, defaultValue: null));
    properties.add(DiagnosticsProperty<BottomNavigationBarType>('type', type, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('selectedItemColor', selectedItemColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('unselectedItemColor', unselectedItemColor, defaultValue: null));
    properties.add(DiagnosticsProperty<IconThemeData>('selectedIconTheme', selectedIconTheme, defaultValue: null));
    properties.add(DiagnosticsProperty<IconThemeData>('unselectedIconTheme', unselectedIconTheme, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('selectedLabelStyle', selectedLabelStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('unselectedLabelStyle', unselectedLabelStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('showUnselectedLabels', showUnselectedLabels, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('showSelectedLabels', showSelectedLabels, defaultValue: null));
  }
}
