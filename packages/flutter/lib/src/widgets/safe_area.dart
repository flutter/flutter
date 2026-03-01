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
/// by the operating system.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=lkF0TQJO0bA}
///
/// When a [minimum] padding is specified, the greater of the minimum padding
/// or the safe area padding will be applied.
///
/// When a [baseMinimum] padding is specified, the padding already applied by
/// ancestor [SafeArea] widgets is taken into account. The greater of the
/// [minimum] padding, the [baseMinimum] padding (minus any ancestor padding),
/// or the safe area padding will be applied. This prevents padding duplication
/// when [SafeArea] widgets are nested.
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
/// to avoid intrusions by the operating system.
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
///  * [SliverSafeArea], for insetting slivers to avoid operating system
///    intrusions.
///  * [Padding], for insetting widgets in general.
///  * [MediaQuery], from which the view padding is obtained.
///  * [dart:ui.FlutterView.padding], which reports the padding from the operating
///    system.
class SafeArea extends StatelessWidget {
  /// Creates a widget that avoids operating system interfaces.
  const SafeArea({
    super.key,
    this.left = true,
    this.top = true,
    this.right = true,
    this.bottom = true,
    this.minimum = EdgeInsets.zero,
    this.baseMinimum = EdgeInsets.zero,
    this.maintainBottomViewPadding = false,
    required this.child,
  });

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

  /// This minimum padding to apply, taking into account the padding already
  /// applied by ancestor [SafeArea] widgets.
  ///
  /// If an ancestor [SafeArea] has already applied padding that is greater
  /// than or equal to this [baseMinimum], no additional padding will be
  /// applied. Otherwise, the padding will be increased to satisfy this
  /// [baseMinimum].
  ///
  /// This helps prevent padding duplication when [SafeArea] widgets are nested.
  final EdgeInsets baseMinimum;

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

    final EdgeInsets ancestorPadding = _SafeAreaPadding.of(context);

    final double padLeft = math.max(
      left ? padding.left : 0.0,
      math.max(minimum.left, baseMinimum.left - ancestorPadding.left),
    );
    final double padTop = math.max(
      top ? padding.top : 0.0,
      math.max(minimum.top, baseMinimum.top - ancestorPadding.top),
    );
    final double padRight = math.max(
      right ? padding.right : 0.0,
      math.max(minimum.right, baseMinimum.right - ancestorPadding.right),
    );
    final double padBottom = math.max(
      bottom ? padding.bottom : 0.0,
      math.max(minimum.bottom, baseMinimum.bottom - ancestorPadding.bottom),
    );

    return Padding(
      padding: EdgeInsets.only(left: padLeft, top: padTop, right: padRight, bottom: padBottom),
      child: MediaQuery.removePadding(
        context: context,
        removeLeft: left,
        removeTop: top,
        removeRight: right,
        removeBottom: bottom,
        child: _SafeAreaPadding(
          padding: EdgeInsets.only(
            left: ancestorPadding.left + padLeft,
            top: ancestorPadding.top + padTop,
            right: ancestorPadding.right + padRight,
            bottom: ancestorPadding.bottom + padBottom,
          ),
          child: child,
        ),
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
    properties.add(
      DiagnosticsProperty<EdgeInsets>('minimum', minimum, defaultValue: EdgeInsets.zero),
    );
    properties.add(
      DiagnosticsProperty<EdgeInsets>('baseMinimum', baseMinimum, defaultValue: EdgeInsets.zero),
    );
  }
}

class _SafeAreaPadding extends InheritedWidget {
  const _SafeAreaPadding({required this.padding, required super.child});

  final EdgeInsets padding;

  static EdgeInsets of(BuildContext context) {
    final _SafeAreaPadding? result = context.dependOnInheritedWidgetOfExactType<_SafeAreaPadding>();
    return result?.padding ?? EdgeInsets.zero;
  }

  @override
  bool updateShouldNotify(_SafeAreaPadding oldWidget) {
    return padding != oldWidget.padding;
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
/// When a [baseMinimum] padding is specified, the padding already applied by
/// ancestor [SafeArea] widgets is taken into account. The greater of the
/// [baseMinimum] padding (minus any ancestor padding) or the safe area padding
/// will be applied. This prevents padding duplication when [SafeArea]
/// widgets are nested.
///
/// See also:
///
///  * [SafeArea], for insetting box widgets to avoid operating system intrusions.
///  * [SliverPadding], for insetting slivers in general.
///  * [MediaQuery], from which the window padding is obtained.
///  * [dart:ui.FlutterView.padding], which reports the padding from the operating
///    system.
class SliverSafeArea extends StatelessWidget {
  /// Creates a sliver that avoids operating system interfaces.
  const SliverSafeArea({
    super.key,
    this.left = true,
    this.top = true,
    this.right = true,
    this.bottom = true,
    this.minimum = EdgeInsets.zero,
    this.baseMinimum = EdgeInsets.zero,
    required this.sliver,
  });

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

  /// This minimum padding to apply, taking into account the padding already
  /// applied by ancestor [SafeArea] widgets.
  ///
  /// If an ancestor [SafeArea] has already applied padding that is greater
  /// than or equal to this [baseMinimum], no additional padding will be
  /// applied. Otherwise, the padding will be increased to satisfy this
  /// [baseMinimum].
  ///
  /// This helps prevent padding duplication when [SafeArea] widgets are nested.
  final EdgeInsets baseMinimum;

  /// The sliver below this sliver in the tree.
  ///
  /// The padding on the [MediaQuery] for the [sliver] will be suitably adjusted
  /// to zero out any sides that were avoided by this sliver.
  final Widget sliver;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    final EdgeInsets ancestorPadding = _SafeAreaPadding.of(context);

    final double padLeft = math.max(
      left ? padding.left : 0.0,
      math.max(minimum.left, baseMinimum.left - ancestorPadding.left),
    );
    final double padTop = math.max(
      top ? padding.top : 0.0,
      math.max(minimum.top, baseMinimum.top - ancestorPadding.top),
    );
    final double padRight = math.max(
      right ? padding.right : 0.0,
      math.max(minimum.right, baseMinimum.right - ancestorPadding.right),
    );
    final double padBottom = math.max(
      bottom ? padding.bottom : 0.0,
      math.max(minimum.bottom, baseMinimum.bottom - ancestorPadding.bottom),
    );

    return SliverPadding(
      padding: EdgeInsets.only(left: padLeft, top: padTop, right: padRight, bottom: padBottom),
      sliver: MediaQuery.removePadding(
        context: context,
        removeLeft: left,
        removeTop: top,
        removeRight: right,
        removeBottom: bottom,
        child: _SafeAreaPadding(
          padding: EdgeInsets.only(
            left: ancestorPadding.left + padLeft,
            top: ancestorPadding.top + padTop,
            right: ancestorPadding.right + padRight,
            bottom: ancestorPadding.bottom + padBottom,
          ),
          child: sliver,
        ),
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
    properties.add(
      DiagnosticsProperty<EdgeInsets>('minimum', minimum, defaultValue: EdgeInsets.zero),
    );
    properties.add(
      DiagnosticsProperty<EdgeInsets>('baseMinimum', baseMinimum, defaultValue: EdgeInsets.zero),
    );
  }
}
