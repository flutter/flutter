// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Defines the visual properties of [TextField], and [SelectableText] widgets.
///
/// Used by [TextInputTheme] to control the visual properties of text fields in
/// a widget subtree.
///
/// Use [TextInputTheme.of] to access the closest ancestor [TextInputTheme] of
/// the current [BuildContext].
///
/// See also:
///
///  * [TextInputTheme], an [InheritedWidget] that propagates the theme down its
///    subtree.
///  * [InputDecorationTheme], which defines most other visual properties of
///    text fields.
@immutable
class TextInputThemeData with Diagnosticable {
  /// Creates the set of properties used to configure [TextField]s.
  const TextInputThemeData({
    this.cursorColor,
    this.selectionHandleColor,
  });

  /// The color used to paint the cursor in the text field.
  ///
  /// The cursor indicates the current location of text input in the field.
  final Color cursorColor;

  /// The color used to paint the selection handles on the text field.
  ///
  /// Selection handles are used to indicate the bounds of the selected text,
  /// or as a handle to drag the cursor to a new location in the text.
  final Color selectionHandleColor;

  /// Creates a copy of this object with the given fields replaced with the
  /// specified values.
  TextInputThemeData copyWith({
    Color cursorColor,
    Color selectionHandleColor,
  }) {
    return TextInputThemeData(
      cursorColor: cursorColor ?? this.cursorColor,
      selectionHandleColor: selectionHandleColor ?? this.selectionHandleColor,
    );
  }

  /// Linearly interpolate between two text field themes.
  ///
  /// If both arguments are null, then null is returned.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static TextInputThemeData lerp(TextInputThemeData a, TextInputThemeData b, double t) {
    if (a == null && b == null)
      return null;
    assert(t != null);
    return TextInputThemeData(
      cursorColor: Color.lerp(a?.cursorColor, b?.cursorColor, t),
      selectionHandleColor: Color.lerp(a?.selectionHandleColor, b?.selectionHandleColor, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      cursorColor,
      selectionHandleColor,
    );
  }

  @override
  bool operator==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is TextInputThemeData
      && other.cursorColor == cursorColor
      && other.selectionHandleColor == selectionHandleColor;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('cursorColor', cursorColor, defaultValue: null));
    properties.add(ColorProperty('selectionHandleColor', selectionHandleColor, defaultValue: null));
  }
}

/// An inherited widget that defines the configuration for
/// [TextField]s in this widget's subtree.
///
/// Values specified here are used for [TextField] properties that are not
/// given an explicit non-null value.
///
/// {@tool snippet}
///
/// Here is an example of a text input theme that applies a blue cursor color
/// with light blue selection handles to the child text field.
///
/// ```dart
/// TextInputTheme(
///   data: TextInputThemeData(
///     cursorColor: Colors.blue,
///     selectionHandleColor: Colors.lightBlue,
///   ),
///   child: TextField(),
/// ),
/// ```
/// {@end-tool}
class TextInputTheme extends InheritedTheme {
  /// Creates a text field theme that controls the configurations for
  /// [TextField].
  ///
  /// The data argument must not be null.
  const TextInputTheme({
    Key key,
    @required this.data,
    Widget child,
  }) : assert(data != null), super(key: key, child: child);

  /// The properties for descendant [TextField] widgets.
  final TextInputThemeData data;

  /// Returns the [data] from the closest [TextInputTheme] ancestor. If there is
  /// no ancestor, it returns [ThemeData.textInputTheme]. Applications can assume
  /// that the returned value will not be null.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// TextInputThemeData theme = TextInputTheme.of(context);
  /// ```
  static TextInputThemeData of(BuildContext context) {
    final TextInputTheme textInputTheme = context.dependOnInheritedWidgetOfExactType<TextInputTheme>();
    return textInputTheme?.data ?? Theme.of(context).textInputTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    final TextInputTheme ancestorTheme = context.findAncestorWidgetOfExactType<TextInputTheme>();
    return identical(this, ancestorTheme) ? child : TextInputTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(TextInputTheme oldWidget) => data != oldWidget.data;
}
