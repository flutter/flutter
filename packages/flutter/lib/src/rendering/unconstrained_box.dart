// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'box.dart';
import 'debug_overflow_indicator.dart';
import 'object.dart';
import 'shifted_box.dart';
import 'stack.dart';

/// Renders a box, imposing no constraints on its child, allowing the child to
/// render at its "natural" size.
///
/// This allows a child to render at the size it would render if it were alone
/// on an infinite canvas with no constraints. This container will then expand
/// as much as it can within its own constraints and align the child based on
/// [alignment].  If the container cannot expand enough to accommodate the
/// entire child, the child will be clipped.
///
/// In debug mode, if the child overflows the container, a warning will be
/// printed on the console, and black and yellow striped areas will appear where
/// the overflow occurs.
///
/// See also:
///
///  * [ConstrainedBox] for a box which imposes constraints on its child.
///  * [Container], a convenience widget that combines common painting,
///    positioning, and sizing widgets.
///  * [OverflowBox], a widget that imposes different constraints on its child
///    than it gets from its parent, possibly allowing the child to overflow
///    the parent.
class RenderUnconstrainedBox extends RenderAligningShiftedBox with DebugOverflowIndicatorMixin {
  RenderUnconstrainedBox({
    RenderBox child,
    @required TextDirection textDirection,
    @required AlignmentGeometry alignment,
  }) : assert(alignment != null),
       super.mixin() {
    this.textDirection = textDirection;
    this.alignment = alignment;
    this.child = child;
  }

  Rect _overflowContainerRect = Rect.zero;
  Rect _overflowChildRect = Rect.zero;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! BoxParentData)
      child.parentData = new BoxParentData();
  }

  @override
  void performLayout() {
    if (child != null) {
      // Let the child lay itself out at it's "natural" size.
      child.layout(const BoxConstraints(), parentUsesSize: true);
      size = constraints.constrain(child.size);
      alignChild();
      final BoxParentData childParentData = child.parentData;
      _overflowContainerRect = Offset.zero & size;
      _overflowChildRect = childParentData.offset & child.size;
    } else {
      size = constraints.constrain(Size.zero);
      _overflowContainerRect = Rect.zero;
      _overflowChildRect = Rect.zero;
    }
  }

  // Returns true if the [overflowContainerRect] has been found to overflow.
  bool get _isOverflowing {
    final RelativeRect overflow = new RelativeRect.fromRect(_overflowContainerRect, _overflowChildRect);
    return overflow.left > 0.0 ||
        overflow.right > 0.0 ||
        overflow.top > 0.0 ||
        overflow.bottom > 0.0;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // There's no point in drawing the child if we're empty, or there is no
    // child.
    if (child == null || size.isEmpty)
      return;

    if (!_isOverflowing) {
      super.paint(context, offset);
      return;
    }

    // We have overflow. Clip it.
    context.pushClipRect(needsCompositing, offset, Offset.zero & size, super.paint);

    // Display the overflow indicator.
    assert(() {
      paintOverflowIndicator(context, offset, _overflowContainerRect, _overflowChildRect);
      return true;
    }());
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) {
    return _isOverflowing ? Offset.zero & size : null;
  }

  @override
  String toStringShort() {
    String header = super.toStringShort();
    if (_isOverflowing)
      header += ' OVERFLOWING';
    return header;
  }
}
