// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'framework.dart';

/// A widget that describes this app in the operating system.
class Title extends StatelessWidget {
  /// Creates a widget that describes this app to the Android operating system.
  ///
  /// [title] will default to the empty string if not supplied.
  /// [color] must be an opaque color (i.e. color.alpha must be 255 (0xFF)).
  /// [color] and [child] are required arguments.
  Title({
    super.key,
    this.title = '',
    this.automaticAppSwitcherDescAdjustment = true,
    required this.color,
    required this.child,
  }) : assert(title != null),
       assert(color != null && color.alpha == 0xFF);

  /// A one-line description of this app for use in the window manager.
  /// Must not be null.
  final String title;

  /// A color that the window manager should use to identify this app. Must be
  /// an opaque color (i.e. color.alpha must be 255 (0xFF)), and must not be
  /// null.
  final Color color;

  /// Whether Flutter should automatically compute the desired application
  /// switcher description.
  ///
  /// When this setting is enabled, Flutter will use the [title] to set the
  /// application switcher description on build.
  ///
  /// Setting this to false does not cause previous automatic adjustments to be
  /// reset.
  ///
  /// If you want to imperatively set the application switcher description
  /// instead, it is recommended that [automaticAppSwitcherDescAdjustment] is
  /// set to false.
  ///
  /// See also:
  ///
  ///  * [SystemChrome.setApplicationSwitcherDescription], for imperatively
  ///  setting the application switcher description.
  final bool automaticAppSwitcherDescAdjustment;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (automaticAppSwitcherDescAdjustment) {
      SystemChrome.setApplicationSwitcherDescription(
        ApplicationSwitcherDescription(
          label: title,
          primaryColor: color.value,
        ),
      );
    }
    return child;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('title', title, defaultValue: ''));
    properties.add(ColorProperty('color', color, defaultValue: null));
  }
}
