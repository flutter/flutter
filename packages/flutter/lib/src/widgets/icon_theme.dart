// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'framework.dart';
import 'icon_theme_data.dart';
import 'inherited_theme.dart';

/// Controls the default color, opacity, and size of icons in a widget subtree.
///
/// The icon theme is honored by [Icon] and [ImageIcon] widgets.
class IconTheme extends InheritedTheme {
  /// Creates an icon theme that controls the color, opacity, and size of
  /// descendant widgets.
  ///
  /// Both [data] and [child] arguments must not be null.
  const IconTheme({
    Key key,
    @required this.data,
    @required Widget child,
  }) : assert(data != null),
       assert(child != null),
       super(key: key, child: child);

  /// Creates an icon theme that controls the color, opacity, and size of
  /// descendant widgets, and merges in the current icon theme, if any.
  ///
  /// The [data] and [child] arguments must not be null.
  static Widget merge({
    Key key,
    @required IconThemeData data,
    @required Widget child,
  }) {
    return Builder(
      builder: (BuildContext context) {
        return IconTheme(
          key: key,
          data: _getInheritedIconThemeData(context).merge(data),
          child: child,
        );
      },
    );
  }

  /// The color, opacity, and size to use for icons in this subtree.
  final IconThemeData data;

  /// The data from the closest instance of this class that encloses the given
  /// context.
  ///
  /// Defaults to the current [ThemeData.iconTheme].
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// IconThemeData theme = IconTheme.of(context);
  /// ```
  static IconThemeData of(BuildContext context) {
    final IconThemeData iconThemeData = _getInheritedIconThemeData(context).resolve(context);
    return iconThemeData.isConcrete
      ? iconThemeData
      : iconThemeData.copyWith(
        size: iconThemeData.size ?? const IconThemeData.fallback().size,
        color: iconThemeData.color ?? const IconThemeData.fallback().color,
        opacity: iconThemeData.opacity ?? const IconThemeData.fallback().opacity,
      );
  }

  static IconThemeData _getInheritedIconThemeData(BuildContext context) {
    final IconTheme iconTheme = context.dependOnInheritedWidgetOfExactType<IconTheme>();
    return iconTheme?.data ?? const IconThemeData.fallback();
  }

  @override
  bool updateShouldNotify(IconTheme oldWidget) => data != oldWidget.data;

  @override
  Widget wrap(BuildContext context, Widget child) {
    final IconTheme iconTheme = context.findAncestorWidgetOfExactType<IconTheme>();
    return identical(this, iconTheme) ? child : IconTheme(data: data, child: child);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    data.debugFillProperties(properties);
  }
}
