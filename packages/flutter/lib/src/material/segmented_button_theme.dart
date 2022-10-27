// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'button_style.dart';
import 'theme.dart';

// Examples can assume:
// late BuildContext context;

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
    this.style,
    this.selectedIcon,
  });

  /// DMA: Document this.
  final ButtonStyle? style;

  /// DMA: Document this.
  final IconData? selectedIcon;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  SegmentedButtonThemeData copyWith({
    ButtonStyle? style,
    IconData? selectedIcon,
  }) {
    return SegmentedButtonThemeData(
      style: style ?? this.style,
      selectedIcon: selectedIcon ?? this.selectedIcon,
    );
  }

  /// Linearly interpolate between two toggle buttons themes.
  static SegmentedButtonThemeData lerp(SegmentedButtonThemeData? a, SegmentedButtonThemeData? b, double t) {
    return SegmentedButtonThemeData(
      style: ButtonStyle.lerp(a?.style, b?.style, t),
      selectedIcon: t < 0.5 ? a?.selectedIcon : b?.selectedIcon,
    );
  }

  @override
  int get hashCode => Object.hash(
    style,
    selectedIcon,
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
        && other.style == style
        && other.selectedIcon == selectedIcon;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ButtonStyle>('style', style, defaultValue: null));
    properties.add(DiagnosticsProperty<IconData>('selectedIcon', selectedIcon, defaultValue: null));
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
