// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'debug.dart';
import 'framework.dart';
import 'media_query.dart';

/// A widget that insets its child with sufficient padding to avoid intrusions
/// by the operating system (such as the status bar, display cutouts/notches, or
/// navigation bar) or ambient obstructions introduced by edge-docked overlays
/// such as [SafeAreaOverlay].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=lkF0TQJO0bA}
///
/// When a [minimum] padding is specified, the greater of the minimum padding
/// or the safe area padding will be applied.
///
/// {@tool dartpad}
/// This example shows how `SafeArea` can apply padding within a mobile device's
/// screen to make the relevant content completely visible.
///
/// ** See code in examples/api/lib/widgets/safe_area/safe_area.0.dart **
/// {@end-tool}
///
/// {@tool snippet}
///
/// This example creates a blue box containing text that is sufficiently padded
/// to avoid intrusions by the operating system or edge overlays.
///
/// ```dart
/// SafeArea(
///   child: Container(
///     constraints: const BoxConstraints.expand(),
///     alignment: Alignment.center,
///     color: Colors.blue,
///     child: const Text('Hello, World!'),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// ### [MediaQuery] impact
///
/// The padding on the [MediaQuery] for the [child] will be suitably adjusted
/// to zero out any sides that were avoided by this widget.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=ceCo8U0XHqw}
///
/// See also:
///
///  * [SafeAreaOverlay], for positioning edge-docked overlays and adjusting
///    descendant safe area insets.
///  * [SliverSafeArea], for insetting slivers to avoid operating system
///    intrusions and edge-docked overlays.
///  * [Padding], for insetting widgets in general.
///  * [MediaQuery], from which the view padding is obtained.
///  * [dart:ui.FlutterView.padding], which reports the padding from the operating
///    system.
class SafeArea extends StatelessWidget {
  /// Creates a widget that avoids operating system interfaces and ambient edge
  /// overlays.
  const SafeArea({
    super.key,
    this.left = true,
    this.top = true,
    this.right = true,
    this.bottom = true,
    this.minimum = EdgeInsets.zero,
    this.maintainBottomViewPadding = false,
    required this.child,
  });

  /// Whether to avoid system intrusions and edge overlays on the left.
  final bool left;

  /// Whether to avoid intrusions at the top of the screen, typically the
  /// system status bar or top edge overlays.
  final bool top;

  /// Whether to avoid system intrusions and edge overlays on the right.
  final bool right;

  /// Whether to avoid intrusions on the bottom side of the screen, such as the
  /// system navigation bar or bottom edge overlays.
  final bool bottom;

  /// This minimum padding to apply.
  ///
  /// The greater of the minimum insets and the media padding will be applied.
  final EdgeInsets minimum;

  /// Specifies whether the [SafeArea] should maintain the bottom
  /// [MediaQueryData.viewPadding] instead of the bottom [MediaQueryData.padding],
  /// defaults to false.
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
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    EdgeInsets padding = MediaQuery.paddingOf(context);
    // Bottom padding has been consumed - i.e. by the keyboard
    if (maintainBottomViewPadding) {
      padding = padding.copyWith(bottom: MediaQuery.viewPaddingOf(context).bottom);
    }

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
/// intrusions by the operating system or ambient obstructions introduced by
/// edge-docked overlays (such as [SafeAreaOverlay]).
///
/// For example, this will indent the sliver by enough to avoid the status bar
/// at the top of the screen.
///
/// It will also indent the sliver by the amount necessary to avoid The Notch
/// on the iPhone X, or other similar creative physical features of the
/// display, as well as any edge overlays placed above the sliver viewport.
///
/// When a [minimum] padding is specified, the greater of the minimum padding
/// or the safe area padding will be applied.
///
/// See also:
///
///  * [SafeArea], for insetting box widgets to avoid operating system
///    intrusions and edge overlays.
///  * [SafeAreaOverlay], for positioning edge-docked overlays and adjusting
///    descendant safe area insets.
///  * [SliverPadding], for insetting slivers in general.
///  * [MediaQuery], from which the window padding is obtained.
///  * [dart:ui.FlutterView.padding], which reports the padding from the operating
///    system.
class SliverSafeArea extends StatelessWidget {
  /// Creates a sliver that avoids operating system interfaces and ambient edge
  /// overlays.
  const SliverSafeArea({
    super.key,
    this.left = true,
    this.top = true,
    this.right = true,
    this.bottom = true,
    this.minimum = EdgeInsets.zero,
    required this.sliver,
  });

  /// Whether to avoid system intrusions and edge overlays on the left.
  final bool left;

  /// Whether to avoid intrusions at the top of the screen, typically the
  /// system status bar or top edge overlays.
  final bool top;

  /// Whether to avoid system intrusions and edge overlays on the right.
  final bool right;

  /// Whether to avoid intrusions on the bottom side of the screen, such as the
  /// system navigation bar or bottom edge overlays.
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
    final EdgeInsets padding = MediaQuery.paddingOf(context);
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
