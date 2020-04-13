// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Defines the visual properties of [Dialog] widgets.
///
/// Used by [DialogTheme] to control the visual properties of Dialogs in a
/// widget subtree.
///
/// To obtain this configuration, use [DialogTheme.of] to access the closest
/// ancestor [DialogTheme] of the current [BuildContext].
///
/// All [DialogThemeData] properties are `null` by default. When null, the
/// [Dialog] will provide its own defaults.
///
/// See also:
///
///  * [DialogTheme], an [InheritedWidget] that propagates the theme down its
///    subtree.
///  * [ThemeData.dialogTheme], which is where default properties can be set for
///    the entire app.
@immutable
class DialogThemeData with Diagnosticable {
  /// Creates the set of properties used to configure [Dialog]s.
  const DialogThemeData({
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.titleTextStyle,
    this.contentTextStyle,
  });

  /// Default value for [Dialog.backgroundColor].
  ///
  /// If null, [ThemeData.dialogBackgroundColor] is used, if that's null,
  /// defaults to [ThemeData.colorScheme.surface].
  final Color backgroundColor;

  /// Default value for [Dialog.elevation].
  ///
  /// If null, the [Dialog] elevation defaults to `24.0`.
  final double elevation;

  /// Default value for [Dialog.shape].
  ///
  /// If null, the [Dialog] shape defaults to a [RoundedRectangleBorder] with a
  /// radius of `4.0`.
  final ShapeBorder shape;

  /// Used to configure the [DefaultTextStyle] for the [AlertDialog.title] widget.
  ///
  /// If null, defaults to [ThemeData.textTheme.headline6].
  final TextStyle titleTextStyle;

  /// Used to configure the [DefaultTextStyle] for the [AlertDialog.content] widget.
  ///
  /// If null, defaults to [ThemeData.textTheme.subtitle1].
  final TextStyle contentTextStyle;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  DialogThemeData copyWith({
    Color backgroundColor,
    double elevation,
    ShapeBorder shape,
    TextStyle titleTextStyle,
    TextStyle contentTextStyle,
  }) {
    return DialogThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      elevation: elevation ?? this.elevation,
      shape: shape ?? this.shape,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      contentTextStyle: contentTextStyle ?? this.contentTextStyle,
    );
  }

  /// Linearly interpolate between two dialog themes.
  ///
  /// If both arguments are null, then null is returned.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static DialogThemeData lerp(DialogThemeData a, DialogThemeData b, double t) {
    if (a == null && b == null)
      return null;
    assert(t != null);
    return DialogThemeData(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
      titleTextStyle: TextStyle.lerp(a?.titleTextStyle, b?.titleTextStyle, t),
      contentTextStyle: TextStyle.lerp(a?.contentTextStyle, b?.contentTextStyle, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      backgroundColor,
      elevation,
      shape,
      titleTextStyle,
      contentTextStyle,
    );
  }

  @override
  bool operator==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is DialogThemeData
      && other.backgroundColor == backgroundColor
      && other.elevation == elevation
      && other.shape == shape
      && other.titleTextStyle == titleTextStyle
      && other.contentTextStyle == contentTextStyle;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('backgroundColor', backgroundColor));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
    properties.add(DoubleProperty('elevation', elevation));
    properties.add(DiagnosticsProperty<TextStyle>('titleTextStyle', titleTextStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('contentTextStyle', contentTextStyle, defaultValue: null));
  }
}

/// An inherited widget that defines the configuration for
/// [Dialog]s in this widget's subtree.
///
/// Values specified here are used for [Dialog] properties that are not
/// given an explicit non-null value.
class DialogTheme extends InheritedTheme {
  /// Creates a dialog theme that controls the configurations for [Dialog].
  ///
  /// The data argument must not be null.
  const DialogTheme({
    Key key,
    @required this.data,
    Widget child,
  }) : assert(data != null), super(key: key, child: child);

  /// The properties for descendant [Dialog] widgets.
  final DialogThemeData data;

  /// Returns the [data] from the closest [DialogTheme] ancestor. If there is
  /// no ancestor, it returns [ThemeData.DialogTheme]. Applications can assume
  /// that the returned value will not be null.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// DialogThemeData theme = DialogTheme.of(context);
  /// ```
  static DialogThemeData of(BuildContext context) {
    final DialogTheme dialogTheme = context.dependOnInheritedWidgetOfExactType<DialogTheme>();
    return dialogTheme?.data ?? Theme.of(context).dialogTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    final DialogTheme ancestorTheme = context.findAncestorWidgetOfExactType<DialogTheme>();
    return identical(this, ancestorTheme) ? child : DialogTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(DialogTheme oldWidget) => data != oldWidget.data;
}
