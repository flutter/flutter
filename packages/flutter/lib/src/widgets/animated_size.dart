// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'basic.dart';
import 'framework.dart';

/// Animated widget that automatically transitions its size over a given
/// duration whenever the given child's size changes.
class AnimatedSize extends SingleChildRenderObjectWidget {
  /// Creates a widget that animates its size to match that of its child.
  ///
  /// The [curve] and [duration] arguments must not be null.
  const AnimatedSize({
    Key key,
    Widget child,
    this.alignment = Alignment.center,
    this.curve = Curves.linear,
    @required this.duration,
    @required this.vsync,
  }) : super(key: key, child: child);

  /// The alignment of the child within the parent when the parent is not yet
  /// the same size as the child.
  ///
  /// The x and y values of the alignment control the horizontal and vertical
  /// alignment, respectively. An x value of -1.0 means that the left edge of
  /// the child is aligned with the left edge of the parent whereas an x value
  /// of 1.0 means that the right edge of the child is aligned with the right
  /// edge of the parent. Other values interpolate (and extrapolate) linearly.
  /// For example, a value of 0.0 means that the center of the child is aligned
  /// with the center of the parent.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// The animation curve when transitioning this widget's size to match the
  /// child's size.
  final Curve curve;

  /// The duration when transitioning this widget's size to match the child's
  /// size.
  final Duration duration;

  /// The [TickerProvider] for this widget.
  final TickerProvider vsync;

  @override
  RenderAnimatedSize createRenderObject(BuildContext context) {
    return RenderAnimatedSize(
      alignment: alignment,
      duration: duration,
      curve: curve,
      vsync: vsync,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderAnimatedSize renderObject) {
    renderObject
      ..alignment = alignment
      ..duration = duration
      ..curve = curve
      ..vsync = vsync
      ..textDirection = Directionality.of(context);
  }
}
