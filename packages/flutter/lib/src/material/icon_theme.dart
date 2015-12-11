// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'icon_theme_data.dart';

class IconTheme extends InheritedWidget {
  IconTheme({
    Key key,
    this.data,
    Widget child
  }) : super(key: key, child: child) {
    assert(data != null);
    assert(child != null);
  }

  final IconThemeData data;

  /// The data from the closest instance of this class that encloses the given context.
  static IconThemeData of(BuildContext context) {
    IconTheme result = context.inheritFromWidgetOfType(IconTheme);
    return result?.data;
  }

  bool updateShouldNotify(IconTheme old) => data != old.data;

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$data');
  }
}
