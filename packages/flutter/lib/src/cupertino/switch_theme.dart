// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'colors.dart';
import 'theme.dart';
import '../material/theme.dart';
import '../material/theme_data.dart';

/// Defines default property values for descendant [CupertinoSwitch] widgets.
///
/// Descendant widgets obtain the current [CupertinoSwitchThemeData] object using
/// `CupertinoSwitchTheme.of(context)`. Instances of [CupertinoSwitchThemeData] can be customized
/// with [CupertinoSwitchThemeData.copyWith].
///
/// Typically a [CupertinoSwitchThemeData] is specified as part of the overall [Theme]
/// with [ThemeData.switchTheme].
///
/// All [CupertinoSwitchThemeData] properties are `null` by default. When null, the
/// [Switch] will use the values from [ThemeData] if they exist, otherwise it
/// will provide its own defaults based on the overall [Theme]'s colorScheme.
/// See the individual [Switch] properties for details.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
@immutable
class CupertinoSwitchThemeData with Diagnosticable {
  /// Creates a theme that can be used for [ThemeData.switchTheme].
  const CupertinoSwitchThemeData({
    this.thumbColor,
    this.trackColor,
    this.activeColor,
  });

  /// The color to use for the track when the switch is on.
  final Color? activeColor;
  /// The color to use for the track when the switch is off.
  final Color? trackColor;
  /// The color to use for the thumb of the switch.
  final Color? thumbColor;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  CupertinoSwitchThemeData copyWith({
    Color? activeColor,
    Color? trackColor,
    Color? thumbColor,
  }) {
    return CupertinoSwitchThemeData(
      activeColor: activeColor ?? this.activeColor,
      thumbColor: thumbColor ?? this.thumbColor,
      trackColor: trackColor ?? this.trackColor,
    );
  }

  /// Resolves this [CupertinoSwitchThemeData] using the provided [BuildContext].
  CupertinoSwitchThemeData resolveFrom(BuildContext context) {
    return copyWith(
        activeColor: CupertinoDynamicColor.maybeResolve(
            activeColor, context),
        thumbColor: CupertinoDynamicColor.maybeResolve(
            thumbColor, context),
        trackColor: CupertinoDynamicColor.maybeResolve(trackColor, context));
  }

  @override
  int get hashCode => Object.hash(
    thumbColor,
    trackColor,
    activeColor,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is CupertinoSwitchThemeData
        && other.thumbColor == thumbColor
        && other.trackColor == trackColor
        && other.activeColor == activeColor;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Color?>('thumbColor', thumbColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Color?>('trackColor', trackColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Color?>('activeColor', activeColor, defaultValue: null));
  }
}


/// Applies a switch theme to descendant [CupertinoSwitch] widgets.
///
/// Descendant widgets obtain the current theme's [CupertinoSwitchTheme] object using
/// [CupertinoSwitchTheme.of]. When a widget uses [CupertinoSwitchTheme.of], it is automatically
/// rebuilt if the theme later changes.
///
/// A switch theme can be specified as part of the overall Material theme using
/// [ThemeData.switchTheme].
///
/// See also:
///
///  * [CupertinoSwitchThemeData], which describes the actual configuration of a switch
///    theme.
class CupertinoSwitchTheme extends InheritedWidget {
  /// Constructs a cupertino switch theme that configures all descendant [CupertinoSwitch] widgets.
  const CupertinoSwitchTheme({
    super.key,
    required this.data,
    required super.child,
  });

  /// The properties used for all descendant [Switch] widgets.
  final CupertinoSwitchThemeData data;

  /// Returns the configuration [data] from the closest [CupertinoSwitchTheme] ancestor.
  /// If there is no ancestor, it returns [CupertinoTheme.switchTheme].
  static CupertinoSwitchThemeData? of(BuildContext context) {
    final CupertinoSwitchTheme? switchTheme = context.dependOnInheritedWidgetOfExactType<CupertinoSwitchTheme>();
    return (switchTheme?.data ?? CupertinoTheme.of(context).switchTheme) ?? Theme.of(context).cupertinoOverrideTheme?.switchTheme;
  }

  @override
  bool updateShouldNotify(CupertinoSwitchTheme oldWidget) => data != oldWidget.data;
}
