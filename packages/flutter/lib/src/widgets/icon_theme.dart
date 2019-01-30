// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'framework.dart';
import 'icon_theme_data.dart';

/// Controls the default color, opacity, and size of icons in a widget subtree.
///
/// The icon theme is honored by [Icon] and [ImageIcon] widgets.
class IconTheme extends InheritedWidget {
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
    final IconThemeData iconThemeData = _getInheritedIconThemeData(context);
    return iconThemeData.isConcrete ? iconThemeData : const IconThemeData.fallback().merge(iconThemeData);
  }

  static IconThemeData _getInheritedIconThemeData(BuildContext context) {
    final IconTheme iconTheme = context.inheritFromWidgetOfExactType(IconTheme);
    return iconTheme?.data ?? const IconThemeData.fallback();
  }

  @override
  bool updateShouldNotify(IconTheme oldWidget) => data != oldWidget.data;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<IconThemeData>('data', data, showName: false));
  }
}
