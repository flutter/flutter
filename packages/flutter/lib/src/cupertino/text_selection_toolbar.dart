// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

// TODO(justinmc): Deduplicate between here and text_selection.dart.
// Values extracted from https://developer.apple.com/design/resources/.
// The height of the toolbar, including the arrow.
const double _kToolbarHeight = 43.0;
// Minimal padding from all edges of the selection toolbar to all edges of the
// screen.
const double _kToolbarScreenPadding = 8.0;
const Size _kToolbarArrowSize = Size(14.0, 7.0);

// TODO(justinmc): These constants are already deduped.
// Values extracted from https://developer.apple.com/design/resources/.
const Radius _kToolbarBorderRadius = Radius.circular(8);

/// An iOS-style toolbar that appears in response to text selection.
///
/// Typically displays buttons for text manipulation, e.g. copying and pasting text.
///
/// See also:
///
///  * [TextSelectionControls.buildToolbar], where [CupertinoTextSelectionToolbar]
///    will be used to build an iOS-style toolbar.
class CupertinoTextSelectionToolbar extends SingleChildRenderObjectWidget {
  /// Create an instance of CupertinoTextSelectionToolbar.
  const CupertinoTextSelectionToolbar({
    Key? key,
    required double barTopY,
    required double arrowTipX,
    required bool isArrowPointingDown,
    Widget? child,
  }) : _barTopY = barTopY,
       _arrowTipX = arrowTipX,
       _isArrowPointingDown = isArrowPointingDown,
       super(key: key, child: child);

  // The y-coordinate of toolbar's top edge, in global coordinate system.
  final double _barTopY;

  // The y-coordinate of the tip of the arrow, in global coordinate system.
  final double _arrowTipX;

  // Whether the arrow should point down and be attached to the bottom
  // of the toolbar, or point up and be attached to the top of the toolbar.
  final bool _isArrowPointingDown;

  @override
  _ToolbarRenderBox createRenderObject(BuildContext context) => _ToolbarRenderBox(_barTopY, _arrowTipX, _isArrowPointingDown, null);

  @override
  void updateRenderObject(BuildContext context, _ToolbarRenderBox renderObject) {
    renderObject
      ..barTopY = _barTopY
      ..arrowTipX = _arrowTipX
      ..isArrowPointingDown = _isArrowPointingDown;
  }
}

// TODO(justinmc): Document.
class _ToolbarRenderBox extends RenderShiftedBox {
  _ToolbarRenderBox(
    this._barTopY,
    this._arrowTipX,
    this._isArrowPointingDown,
    RenderBox? child,
  ) : super(child);


  @override
  bool get isRepaintBoundary => true;

  double _barTopY;
  set barTopY(double value) {
    if (_barTopY == value) {
      return;
    }
    _barTopY = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  double _arrowTipX;
  set arrowTipX(double value) {
    if (_arrowTipX == value) {
      return;
    }
    _arrowTipX = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  bool _isArrowPointingDown;
  set isArrowPointingDown(bool value) {
    if (_isArrowPointingDown == value) {
      return;
    }
    _isArrowPointingDown = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  final BoxConstraints heightConstraint = const BoxConstraints.tightFor(height: _kToolbarHeight);

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! _ToolbarParentData) {
      child.parentData = _ToolbarParentData();
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    size = constraints.biggest;

    if (child == null) {
      return;
    }
    final BoxConstraints enforcedConstraint = constraints
      .deflate(const EdgeInsets.symmetric(horizontal: _kToolbarScreenPadding))
      .loosen();

    child!.layout(heightConstraint.enforce(enforcedConstraint), parentUsesSize: true,);
    final _ToolbarParentData childParentData = child!.parentData! as _ToolbarParentData;

    // The local x-coordinate of the center of the toolbar.
    final double lowerBound = child!.size.width/2 + _kToolbarScreenPadding;
    final double upperBound = size.width - child!.size.width/2 - _kToolbarScreenPadding;
    final double adjustedCenterX = _arrowTipX.clamp(lowerBound, upperBound);

    childParentData.offset = Offset(adjustedCenterX - child!.size.width / 2, _barTopY);
    childParentData.arrowXOffsetFromCenter = _arrowTipX - adjustedCenterX;
  }

  // The path is described in the toolbar's coordinate system.
  Path _clipPath() {
    final _ToolbarParentData childParentData = child!.parentData! as _ToolbarParentData;
    final Path rrect = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset(0, _isArrowPointingDown ? 0 : _kToolbarArrowSize.height)
            & Size(child!.size.width, child!.size.height - _kToolbarArrowSize.height),
          _kToolbarBorderRadius,
        ),
      );

    final double arrowTipX = child!.size.width / 2 + childParentData.arrowXOffsetFromCenter!;

    final double arrowBottomY = _isArrowPointingDown
      ? child!.size.height - _kToolbarArrowSize.height
      : _kToolbarArrowSize.height;

    final double arrowTipY = _isArrowPointingDown ? child!.size.height : 0;

    final Path arrow = Path()
      ..moveTo(arrowTipX, arrowTipY)
      ..lineTo(arrowTipX - _kToolbarArrowSize.width / 2, arrowBottomY)
      ..lineTo(arrowTipX + _kToolbarArrowSize.width / 2, arrowBottomY)
      ..close();

    return Path.combine(PathOperation.union, rrect, arrow);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      return;
    }

    final _ToolbarParentData childParentData = child!.parentData! as _ToolbarParentData;
    _clipPathLayer = context.pushClipPath(
      needsCompositing,
      offset + childParentData.offset,
      Offset.zero & child!.size,
      _clipPath(),
      (PaintingContext innerContext, Offset innerOffset) => innerContext.paintChild(child!, innerOffset),
      oldLayer: _clipPathLayer
    );
  }

  ClipPathLayer? _clipPathLayer;
  Paint? _debugPaint;

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    assert(() {
      if (child == null) {
        return true;
      }

      _debugPaint ??= Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0.0, 0.0),
          const Offset(10.0, 10.0),
          const <Color>[Color(0x00000000), Color(0xFFFF00FF), Color(0xFFFF00FF), Color(0x00000000)],
          const <double>[0.25, 0.25, 0.75, 0.75],
          TileMode.repeated,
        )
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final _ToolbarParentData childParentData = child!.parentData! as _ToolbarParentData;
      context.canvas.drawPath(_clipPath().shift(offset + childParentData.offset), _debugPaint!);
      return true;
    }());
  }
}

class _ToolbarParentData extends BoxParentData {
  // The x offset from the tip of the arrow to the center of the toolbar.
  // Positive if the tip of the arrow has a larger x-coordinate than the
  // center of the toolbar.
  double? arrowXOffsetFromCenter;
  @override
  String toString() => 'offset=$offset, arrowXOffsetFromCenter=$arrowXOffsetFromCenter';
}
