// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';


/// Present frame-by-frame clones of the target widget in a grid.
///
/// This grid displays the frame-by-frame state of the `target` widget,
/// and composes them into a grid.
///
/// To use this, pump this widget with an increased `currentFrame` and a duration
/// of a frame.
class AnimationSheetRecorder extends StatelessWidget {
  /// Create an [AnimationSheetRecorder]. The `cellSize` and `frameIndex` are required.
  const AnimationSheetRecorder(
    this.target, {
    Key key,
    @required this.cellSize,
    @required this.frameIndex,
  }) : assert(cellSize != null),
       assert(frameIndex != null),
       super(key: key);

  /// The widget to show animation of.
  final Widget target;

  /// The size of a cell. Should contain a widget.
  /// 
  /// Should not change throughout the test.
  final Size cellSize;

  /// An increasing integer that starts from 0.
  /// 
  /// At the [frameIndex]'th frame, [frameIndex] clones will be displayed.
  final int frameIndex;

  @override
  Widget build(BuildContext context) {
    return _CellGrid(
      cellSize: cellSize,
      children: List<Widget>.generate(frameIndex + 1, (int index) {
        final int i = frameIndex - index;
        return Container(
          key: ValueKey<int>(i),
          child: target,
        );
      }),
    );
  }
}

// A grid of fixed-sized cells that are positioned from top left, horizontal-first,
// until the the entire grid is filled. 
class _CellGrid extends MultiChildRenderObjectWidget {
  _CellGrid({
    Key key,
    @required this.cellSize,
    List<Widget> children = const <Widget>[],
  }) : assert(cellSize != null),
       super(key: key, children: children);

  final Size cellSize;

  @override
  _RenderCellGrid createRenderObject(BuildContext context) {
    return _RenderCellGrid(
      cellSize: cellSize,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant _RenderCellGrid renderObject) {
    renderObject
      .cellSize = cellSize;
  }
}

class _CellGridParentData extends ContainerBoxParentData<RenderBox>{
}

class _RenderCellGrid extends RenderBox with ContainerRenderObjectMixin<RenderBox, _CellGridParentData>,
                                             RenderBoxContainerDefaultsMixin<RenderBox, _CellGridParentData> {
  _RenderCellGrid({
    List<RenderBox> children,
    Size cellSize,
  }) : _cellSize = cellSize {
    addAll(children);
  }

  Size get cellSize => _cellSize;
  Size _cellSize;
  set cellSize(Size value) {
    _cellSize = value;
    markNeedsLayout();
  }

  int get _columnNum {
    assert(size != null);
    return (size.width / cellSize.width).floor();
  }

  int get _rowNum {
    assert(size != null);
    return (size.height / cellSize.height).floor();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _CellGridParentData)
      child.parentData = _CellGridParentData();
  }

  @override
  void performResize() {
    size = constraints.biggest;
    final int maxChildrenNum = _columnNum * _rowNum;
    int childrenNum = 0;
    RenderBox child = firstChild;
    double x = 0;
    double y = 0;
    while (child != null && childrenNum < maxChildrenNum) {
      assert(y + cellSize.height < size.height);
      assert(x + cellSize.width < size.width);
      final _CellGridParentData childParentData = child.parentData as _CellGridParentData;
      child.layout(BoxConstraints.tight(cellSize), parentUsesSize: false);
      childParentData.offset = Offset(x, y);
      childrenNum += 1;
      x += cellSize.width;
      if (x >= size.width - cellSize.width) {
        x = 0;
        y += cellSize.height;
      }
      child = childParentData.nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
    return;
  }

  @override
  bool get sizedByParent => true;
}
