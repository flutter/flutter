// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'text_button.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'button_style.dart';
import 'theme.dart';

// Examples can assume:
// late BuildContext context;

/// A [ButtonStyle] that overrides the default appearance of
/// [TextButton]s when it's used with [TextButtonTheme] or with the
/// overall [Theme]'s [ThemeData.textButtonTheme].
///
/// The [style]'s properties override [TextButton]'s default style,
/// i.e. the [ButtonStyle] returned by [TextButton.defaultStyleOf]. Only
/// the style's non-null property values or resolved non-null
/// [WidgetStateProperty] values are used.
///
/// See also:
///
///  * [TextButtonTheme], the theme which is configured with this class.
///  * [TextButton.defaultStyleOf], which returns the default [ButtonStyle]
///    for text buttons.
///  * [TextButton.styleFrom], which converts simple values into a
///    [ButtonStyle] that's consistent with [TextButton]'s defaults.
///  * [WidgetStateProperty.resolve], "resolve" a material state property
///    to a simple value based on a set of [WidgetState]s.
///  * [ThemeData.textButtonTheme], which can be used to override the default
///    [ButtonStyle] for [TextButton]s below the overall [Theme].
@immutable
class TextButtonThemeData with Diagnosticable {
  /// Creates a [TextButtonThemeData].
  ///
  /// The [style] may be null.
  const TextButtonThemeData({this.style});

  /// Overrides for [TextButton]'s default style.
  ///
  /// Non-null properties or non-null resolved [WidgetStateProperty]
  /// values override the [ButtonStyle] returned by
  /// [TextButton.defaultStyleOf].
  ///
  /// If [style] is null, then this theme doesn't override anything.
  final ButtonStyle? style;

  /// Linearly interpolate between two text button themes.
  static TextButtonThemeData? lerp(TextButtonThemeData? a, TextButtonThemeData? b, double t) {
    if (identical(a, b)) {
      return a;
    }
    return TextButtonThemeData(style: ButtonStyle.lerp(a?.style, b?.style, t));
  }

  @override
  int get hashCode => style.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is TextButtonThemeData && other.style == style;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ButtonStyle>('style', style, defaultValue: null));
  }
}

/// Overrides the default [ButtonStyle] of its [TextButton] descendants.
///
/// See also:
///
///  * [TextButtonThemeData], which is used to configure this theme.
///  * [TextButton.defaultStyleOf], which returns the default [ButtonStyle]
///    for text buttons.
///  * [TextButton.styleFrom], which converts simple values into a
///    [ButtonStyle] that's consistent with [TextButton]'s defaults.
///  * [ThemeData.textButtonTheme], which can be used to override the default
///    [ButtonStyle] for [TextButton]s below the overall [Theme].
class TextButtonTheme extends InheritedTheme<TextButtonThemeData> {
  /// Create a [TextButtonTheme].
  const TextButtonTheme({super.key, required this.data, required super.child});

  /// The configuration of this theme.
  final TextButtonThemeData data;

  /// The closest instance of this class that encloses the given context.
  ///
  /// If there is no enclosing [TextButtonTheme] widget, then
  /// [ThemeData.textButtonTheme] is used.
  ///
  /// For specific theme properties, consider using [selectOf],
  /// which will only rebuild widget when the selected property changes:
  /// ```dart
  /// final ButtonStyle? style = TextButtonTheme.selectOf(
  ///   context,
  ///   (TextButtonThemeData data) => data.style,
  /// );
  /// ```
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// TextButtonThemeData theme = TextButtonTheme.of(context);
  /// ```
  static TextButtonThemeData of(BuildContext context) {
    final TextButtonTheme? buttonTheme =
        context.dependOnInheritedWidgetOfExactType<TextButtonTheme>();
    return buttonTheme?.data ?? Theme.of(context).textButtonTheme;
  }

  /// Evaluates [ThemeSelector.selectFrom] using [data] provided by the
  /// nearest ancestor [TextButtonTheme] widget, and returns the result.
  ///
  /// When this value changes, a notification is sent to the [context]
  /// to trigger an update.
  static T selectOf<T>(BuildContext context, T Function(TextButtonThemeData) selector) {
    final ThemeSelector<TextButtonThemeData, T> themeSelector =
        ThemeSelector<TextButtonThemeData, T>.from(selector);
    final TextButtonThemeData theme =
        InheritedModel.inheritFrom<TextButtonTheme>(context, aspect: themeSelector)!.data;
    return themeSelector.selectFrom(theme);
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return TextButtonTheme(data: data, child: child);
  }

  @override
  TextButtonThemeData get themeData => data;
}
