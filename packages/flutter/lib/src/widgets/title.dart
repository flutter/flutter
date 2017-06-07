// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A widget that describes this app in the operating system.
class Title extends StatelessWidget {
  /// Creates a widget that describes this app to the operating system.
  Title({
    Key key,
    this.title,
    this.color,
    @required this.child,
  }) : assert(color == null || color.alpha == 0xFF),
       super(key: key);

  /// A one-line description of this app for use in the window manager.
  final String title;

  /// A color that the window manager should use to identify this app.
  final Color color;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setApplicationSwitcherDescription(
      new ApplicationSwitcherDescription(
        label: title,
        primaryColor: color.value,
      )
    );
    return child;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (title != null)
      description.add('"$title"');
    if (color != null)
      description.add('color: $color');
  }
}
