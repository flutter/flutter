// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'framework.dart';

/// A widget that describes this app in the operating system.
class Title extends StatefulWidget {
  /// Creates a widget that describes this app to the Android operating system.
  ///
  /// [title] will default to the empty string if not supplied.
  /// [color] must be an opaque color (i.e. color.alpha must be 255 (0xFF)).
  /// [color] and [child] are required arguments.
  Title({super.key, this.title = '', required this.color, required this.child})
    : assert(color.alpha == 0xFF);

  /// A one-line description of this app for use in the window manager.
  final String title;

  /// A color that the window manager should use to identify this app. Must be
  /// an opaque color (i.e. color.alpha must be 255 (0xFF)), and must not be
  /// null.
  final Color color;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  State<Title> createState() => _TitleState();
}

class _TitleState extends State<Title> {
  @override
  void initState() {
    super.initState();
    _updateChrome();
  }

  @override
  void didUpdateWidget(covariant Title oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title || oldWidget.color != widget.color) {
      _updateChrome();
    }
  }

  void _updateChrome() {
    SystemChrome.setApplicationSwitcherDescription(
      ApplicationSwitcherDescription(label: widget.title, primaryColor: widget.color.value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('title', widget.title, defaultValue: ''));
    properties.add(ColorProperty('color', widget.color, defaultValue: null));
  }
}
