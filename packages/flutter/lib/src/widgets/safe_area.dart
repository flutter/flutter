// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'debug.dart';
import 'framework.dart';
import 'media_query.dart';

/// A widget that insets its child by sufficient padding to avoid
/// intrusions by the operating system.
///
/// For example, this will indent the child by enough to avoid the status bar at
/// the top of the screen.
///
/// It will also indent the child by the amount necessary to avoid The Notch on
/// the iPhone X, or other similar creative physical features of the display.
///
/// See also:
///
///  * [Padding], for insetting widgets in general.
///  * [MediaQuery], from which the window padding is obtained.
///  * [dart:ui.Window.padding], which reports the padding from the operating
///    system.
class SafeArea extends StatelessWidget {
  /// Creates a widget that avoids operating system interfaces.
  ///
  /// The [left], [top], [right], and [bottom] arguments must not be null.
  const SafeArea({
    Key key,
    this.left: true,
    this.top: true,
    this.right: true,
    this.bottom: true,
    @required this.child,
  }) : assert(left != null),
       assert(top != null),
       assert(right != null),
       assert(bottom != null),
       super(key: key);

  /// Whether to avoid system intrusions on the left.
  final bool left;

  /// Whether to avoid system intrusions at the top of the screen, typically the
  /// system status bar.
  final bool top;

  /// Whether to avoid system intrusions on the right.
  final bool right;

  /// Whether to avoid system intrusions on the bottom side of the screen.
  final bool bottom;

  /// The widget below this widget in the tree.
  ///
  /// The padding on the [MediaQuery] for the [child] will be suitably adjusted
  /// to zero out any sides that were avoided by this widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final EdgeInsets padding = MediaQuery.of(context).padding;
    return new Padding(
      padding: new EdgeInsets.only(
        left: left ? padding.left : 0.0,
        top: top ? padding.top : 0.0,
        right: right ? padding.right : 0.0,
        bottom: bottom ? padding.bottom : 0.0,
      ),
      child: new MediaQuery.removePadding(
        context: context,
        removeLeft: left,
        removeTop: top,
        removeRight: right,
        removeBottom: bottom,
        child: child,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new FlagProperty('left', value: left, ifTrue: 'avoid left padding'));
    description.add(new FlagProperty('top', value: left, ifTrue: 'avoid top padding'));
    description.add(new FlagProperty('right', value: left, ifTrue: 'avoid right padding'));
    description.add(new FlagProperty('bottom', value: left, ifTrue: 'avoid bottom padding'));
  }
}
