// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'icon_theme_data.dart';

/// Controls the default color, opacity, and size of icons in a widget subtree.
class IconTheme extends InheritedWidget {
  /// Creates an icon theme that controls the color, opacity, and size of
  /// descendant widgets.
  ///
  /// Both [data] and [child] arguments must not be null.
  IconTheme({
    Key key,
    @required this.data,
    Widget child
  }) : super(key: key, child: child) {
    assert(data != null);
    assert(child != null);
  }

  /// The color, opacity, and size to use for icons in this subtree.
  final IconThemeData data;

  /// The data from the closest instance of this class that encloses the given context.
  static IconThemeData of(BuildContext context) {
    IconTheme result = context.inheritFromWidgetOfExactType(IconTheme);
    return result?.data;
  }

  @override
  bool updateShouldNotify(IconTheme old) => data != old.data;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$data');
  }
}
