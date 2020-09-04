// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'debug.dart';
import 'framework.dart';
import 'media_query.dart';

/// A widget that insets its child by sufficient padding to avoid intrusions by
/// the operating system.
///
/// For example, this will indent the child by enough to avoid the status bar at
/// the top of the screen.
///
/// It will also indent the child by the amount necessary to avoid The Notch on
/// the iPhone X, or other similar creative physical features of the display.
///
/// When a [minimum] padding is specified, the greater of the minimum padding
/// or the safe area padding will be applied.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=lkF0TQJO0bA}
///
/// See also:
///
///  * [SliverSafeArea], for insetting slivers to avoid operating system
///    intrusions.
///  * [Padding], for insetting widgets in general.
///  * [MediaQuery], from which the window padding is obtained.
///  * [dart:ui.Window.padding], which reports the padding from the operating
///    system.
class SafeArea extends StatelessWidget {
  /// Creates a widget that avoids operating system interfaces.
  ///
  /// The [left], [top], [right], [bottom], and [minimum] arguments must not be
  /// null.
  const SafeArea({
    Key key,
    this.left = true,
    this.top = true,
    this.right = true,
    this.bottom = true,
    this.minimum = EdgeInsets.zero,
    this.maintainBottomViewPadding = false,
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

  /// This minimum padding to apply.
  ///
  /// The greater of the minimum insets and the media padding will be applied.
  final EdgeInsets minimum;

  /// Specifies whether the [SafeArea] should maintain the
  /// [MediaQueryData.viewPadding] instead of the [MediaQueryData.padding] when
  /// consumed by the [MediaQueryData.viewInsets] of the current context's
  /// [MediaQuery], defaults to false.
  ///
  /// For example, if there is an onscreen keyboard displayed above the
  /// SafeArea, the padding can be maintained below the obstruction rather than
  /// being consumed. This can be helpful in cases where your layout contains
  /// flexible widgets, which could visibly move when opening a software
  /// keyboard due to the change in the padding value. Setting this to true will
  /// avoid the UI shift.
  final bool maintainBottomViewPadding;

  /// The widget below this widget in the tree.
  ///
  /// The padding on the [MediaQuery] for the [child] will be suitably adjusted
  /// to zero out any sides that were avoided by this widget.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData data = MediaQuery.of(context);
    EdgeInsets padding = data.padding;
    // Bottom padding has been consumed - i.e. by the keyboard
    if (data.padding.bottom == 0.0 && data.viewInsets.bottom != 0.0 && maintainBottomViewPadding)
      padding = padding.copyWith(bottom: data.viewPadding.bottom);

    return Padding(
      padding: EdgeInsets.only(
        left: math.max(left ? padding.left : 0.0, minimum.left),
        top: math.max(top ? padding.top : 0.0, minimum.top),
        right: math.max(right ? padding.right : 0.0, minimum.right),
        bottom: math.max(bottom ? padding.bottom : 0.0, minimum.bottom),
      ),
      child: MediaQuery.removePadding(
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
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('left', value: left, ifTrue: 'avoid left padding'));
    properties.add(FlagProperty('top', value: top, ifTrue: 'avoid top padding'));
    properties.add(FlagProperty('right', value: right, ifTrue: 'avoid right padding'));
    properties.add(FlagProperty('bottom', value: bottom, ifTrue: 'avoid bottom padding'));
  }
}

/// A sliver that insets another sliver by sufficient padding to avoid
/// intrusions by the operating system.
///
/// For example, this will indent the sliver by enough to avoid the status bar
/// at the top of the screen.
///
/// It will also indent the sliver by the amount necessary to avoid The Notch
/// on the iPhone X, or other similar creative physical features of the
/// display.
///
/// When a [minimum] padding is specified, the greater of the minimum padding
/// or the safe area padding will be applied.
///
/// See also:
///
///  * [SafeArea], for insetting widgets to avoid operating system intrusions.
///  * [SliverPadding], for insetting slivers in general.
///  * [MediaQuery], from which the window padding is obtained.
///  * [dart:ui.Window.padding], which reports the padding from the operating
///    system.
class SliverSafeArea extends StatelessWidget {
  /// Creates a sliver that avoids operating system interfaces.
  ///
  /// The [left], [top], [right], [bottom], and [minimum] arguments must not be null.
  const SliverSafeArea({
    Key key,
    this.left = true,
    this.top = true,
    this.right = true,
    this.bottom = true,
    this.minimum = EdgeInsets.zero,
    @required this.sliver,
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

  /// This minimum padding to apply.
  ///
  /// The greater of the minimum padding and the media padding is be applied.
  final EdgeInsets minimum;

  /// The sliver below this sliver in the tree.
  ///
  /// The padding on the [MediaQuery] for the [sliver] will be suitably adjusted
  /// to zero out any sides that were avoided by this sliver.
  final Widget sliver;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final EdgeInsets padding = MediaQuery.of(context).padding;
    return SliverPadding(
      padding: EdgeInsets.only(
        left: math.max(left ? padding.left : 0.0, minimum.left),
        top: math.max(top ? padding.top : 0.0, minimum.top),
        right: math.max(right ? padding.right : 0.0, minimum.right),
        bottom: math.max(bottom ? padding.bottom : 0.0, minimum.bottom),
      ),
      sliver: MediaQuery.removePadding(
        context: context,
        removeLeft: left,
        removeTop: top,
        removeRight: right,
        removeBottom: bottom,
        child: sliver,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('left', value: left, ifTrue: 'avoid left padding'));
    properties.add(FlagProperty('top', value: top, ifTrue: 'avoid top padding'));
    properties.add(FlagProperty('right', value: right, ifTrue: 'avoid right padding'));
    properties.add(FlagProperty('bottom', value: bottom, ifTrue: 'avoid bottom padding'));
  }
}
