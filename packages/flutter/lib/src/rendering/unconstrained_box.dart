// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'box.dart';
import 'debug_overflow_indicator.dart';
import 'object.dart';
import 'proxy_box.dart';
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
class RenderUnconstrainedBox extends RenderBox
  with RenderObjectWithChildMixin<RenderBox>,
       RenderProxyBoxMixin,
       DebugOverflowIndicatorMixin {
  RenderUnconstrainedBox({
    RenderBox child,
    @required TextDirection textDirection,
    @required AlignmentGeometry alignment,
  }) : assert(alignment != null),
       _textDirection = textDirection,
       _alignment = alignment {
    this.child = child;
  }

  /// Determines the order to lay children out horizontally and how to interpret
  /// `start` and `end` in the horizontal direction for the alignment.
  ///
  /// The textDirection is only used when [alignment] is an
  /// [AlignmentDirectional], but must be non-null in that case.
  @override
  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection != value) {
      _textDirection = value;
      _markNeedResolution();
    }
  }

  /// How to align the the child in the box.
  ///
  /// If this is set to an [AlignmentDirectional] object, then [textDirection]
  /// must not be null.
  ///
  /// See also:
  ///
  ///  * [AlignmentDirectional] for direction-aware alignment.
  ///  * [Alignment] for non-direction-aware alignment.
  AlignmentGeometry get alignment => _alignment;
  AlignmentGeometry _alignment;
  set alignment(AlignmentGeometry value) {
    assert(value != null);
    if (_alignment == value)
      return;
    _alignment = value;
    _markNeedResolution();
  }

  Alignment _resolvedAlignment;
  void _resolve() {
    _resolvedAlignment ??= alignment.resolve(textDirection ?? TextDirection.ltr);
  }

  void _markNeedResolution() {
    _resolvedAlignment = null;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! BoxParentData)
      child.parentData = new BoxParentData();
  }

  @override
  void performLayout() {
    if (child != null) {
      _resolve();
      assert(_resolvedAlignment != null);
      final BoxParentData childParentData = child.parentData;
      // Let the child lay itself out at it's "natural" size.
      child.layout(const BoxConstraints(), parentUsesSize: true);
      size = constraints.constrain(child.size);
      childParentData.offset = _resolvedAlignment.alongOffset(size - child.size);
      overflowChildRect = childParentData.offset & child.size;
      overflowContainerRect = Offset.zero & size;
    } else {
      size = constraints.constrain(Size.zero);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // There's no point in drawing the child if we're empty, or there is no
    // child.
    if (child == null || size.isEmpty)
      return;

    final BoxParentData childParentData = child.parentData;
    if (!isOverflowing) {
      super.paint(context, offset + childParentData.offset);
      return;
    }

    // We have overflow. Clip it.
    context.pushClipRect(
      needsCompositing,
      offset + childParentData.offset,
      (Offset.zero - childParentData.offset) & size,
      super.paint,
    );

    // Display the overflow indicator.
    assert(() {
      overflowRenderObject ??= this;
      overflowPaintIndicator(context, offset);
      return true;
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    // Each time we reassemble, we want to see the next overflow debug message.
    assert(() {
      overflowReportNeeded = true;
      return true;
    }());
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) {
    return isOverflowing ? Offset.zero & size : null;
  }

  @override
  String toStringShort() {
    String header = super.toStringShort();
    if (isOverflowing)
      header += ' OVERFLOWING';
    return header;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new EnumProperty<AlignmentGeometry>('alignment', alignment));
    description.add(new EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
  }
}
