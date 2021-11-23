// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Slots used for the children of [_Diagonal] and [_RenderDiagonal].
enum _DiagonalSlot {
  topLeft,
  bottomRight,
}

/// A widget that demonstrates the usage of [SlottedMultiChildRenderObjectWidgetMixin]
/// by providing slots for two children that will be arranged diagonally.
class _Diagonal extends RenderObjectWidget with SlottedMultiChildRenderObjectWidgetMixin<_DiagonalSlot> {
  const _Diagonal({
    Key? key,
    required this.topLeft,
    required this.bottomRight,
    this.backgroundColor,
  }) : super(key: key);

  final Widget topLeft;
  final Widget bottomRight;
  final Color? backgroundColor;

  @override
  Iterable<_DiagonalSlot> get slots => _DiagonalSlot.values;

  @override
  Widget? childForSlot(_DiagonalSlot slot) {
    switch (slot) {
      case _DiagonalSlot.topLeft:
        return topLeft;
      case _DiagonalSlot.bottomRight:
        return bottomRight;
    }
  }

  @override
  SlottedContainerRenderObjectMixin<_DiagonalSlot> createRenderObject(BuildContext context) {
    return _RenderDiagonal(
      backgroundColor: backgroundColor,
    );
  }

  @override
  void updateRenderObject(BuildContext context, SlottedContainerRenderObjectMixin<_DiagonalSlot> renderObject) {
    (renderObject as _RenderDiagonal).backgroundColor = backgroundColor;
  }
}

/// A render object that demonstrates the usage of [SlottedContainerRenderObjectMixin]
/// by providing slots for two children that will be arranged diagonally.
class _RenderDiagonal extends RenderBox with SlottedContainerRenderObjectMixin<_DiagonalSlot>, DebugOverflowIndicatorMixin {
  _RenderDiagonal({Color? backgroundColor}) : _backgroundColor = backgroundColor;

  Color? get backgroundColor => _backgroundColor;
  Color? _backgroundColor;
  set backgroundColor(Color? value) {
    assert(value != null);
    if (_backgroundColor == value)
      return;
    _backgroundColor = value;
    markNeedsPaint();
  }

  // Getters to simplify accessing the slotted children.
  RenderBox get _topLeft => childForSlot(_DiagonalSlot.topLeft)!;
  RenderBox get _bottomRight => childForSlot(_DiagonalSlot.bottomRight)!;

  // The size this render object would have if the incoming constraints were
  // unconstrained; calculated during performLayout.
  late Size _childrenSize;

  // Returns children in hit test order.
  @override
  Iterable<RenderBox> get children sync* {
    yield _topLeft;
    yield _bottomRight;
  }

  // LAYOUT

  @override
  void performLayout() {
    // Children are allowed to be as big as they want (= unconstrained).
    const BoxConstraints childConstraints = BoxConstraints();

    // Lay out the top left child and position it at offset zero.
    _topLeft.layout(childConstraints, parentUsesSize: true);
    _positionChild(_topLeft, Offset.zero);

    // Lay out the bottom right child and position it at the bottom right corner
    // of the top left child.
    _bottomRight.layout(childConstraints, parentUsesSize: true);
    _positionChild(
      _bottomRight,
      Offset(_topLeft.size.width, _topLeft.size.height),
    );

    // Calculate the overall size and constrains it to the given constraints.
    // Any overflow is marked (in debug mode) during paint.
    _childrenSize = Size(
      _topLeft.size.width + _bottomRight.size.width,
      _topLeft.size.height + _bottomRight.size.height,
    );
    size = constraints.constrain(_childrenSize);
  }

  void _positionChild(RenderBox child, Offset offset) {
    (child.parentData! as BoxParentData).offset = offset;
  }

  // PAINT

  @override
  void paint(PaintingContext context, Offset offset) {
    // Paint the background.
    if (backgroundColor != null) {
      context.canvas.drawRect(
        offset & size,
        Paint()
          ..color = backgroundColor!,
      );
    }

    // Paint the children at the offset calculated during layout.
    _paintChild(_topLeft, context, offset);
    _paintChild(_bottomRight, context, offset);

    // Paint an overflow indicator in debug mode if the children want to be
    // larger than the incoming constraints allow.
    assert(() {
      paintOverflowIndicator(
        context,
        offset,
        Offset.zero & size,
        Offset.zero & _childrenSize,
      );
      return true;
    }());
  }

  void _paintChild(RenderBox child, PaintingContext context, Offset offset) {
    final BoxParentData childParentData = child.parentData! as BoxParentData;
    context.paintChild(child, childParentData.offset + offset);
  }

  // HIT TEST

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
    for (final RenderBox child in children) {
      final BoxParentData parentData = child.parentData! as BoxParentData;
      final bool isHit = result.addWithPaintOffset(
        offset: parentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - parentData.offset);
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit)
        return true;
    }
    return false;
  }

  // INTRINSICS

  // Incoming height/width are ignored as children are always laid out unconstrained.

  @override
  double computeMinIntrinsicWidth(double height) {
    return _topLeft.getMinIntrinsicWidth(double.infinity) + _bottomRight.getMinIntrinsicWidth(double.infinity);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _topLeft.getMaxIntrinsicWidth(double.infinity) + _bottomRight.getMaxIntrinsicWidth(double.infinity);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _topLeft.getMinIntrinsicHeight(double.infinity) + _bottomRight.getMinIntrinsicHeight(double.infinity);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _topLeft.getMaxIntrinsicHeight(double.infinity) + _bottomRight.getMaxIntrinsicHeight(double.infinity);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    const BoxConstraints childConstraints = BoxConstraints();
    final Size topLeftSize = _topLeft.computeDryLayout(childConstraints);
    final Size bottomRightSize = _bottomRight.computeDryLayout(childConstraints);
    return constraints.constrain(Size(
      topLeftSize.width + bottomRightSize.width,
      topLeftSize.height + bottomRightSize.height,
    ));
  }
}

class ExampleWidget extends StatelessWidget {
  const ExampleWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Slotted RenderObject Example')),
        body: Center(
          child: _Diagonal(
            topLeft: Container(
              color: Colors.green,
              height: 100,
              width: 200,
              child: const Center(
                child: Text('topLeft'),
              ),
            ),
            bottomRight: Container(
              color: Colors.yellow,
              height: 60,
              width: 30,
              child: const Center(
                child: Text('bottomRight'),
              ),
            ),
            backgroundColor: Colors.blue,
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const ExampleWidget());
}
