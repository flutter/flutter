// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Place `cellNum` number of the target widget in a grid sheet.
/// 
/// The [SheetDisplay] tries to fill as much space as the parent allows, then
/// display clones of the target widget in cells of size `cellSize`, placing
/// cells from top left to bottom right, horizontal first. Cells are keyed from
/// the tail to the front, meaning new clones are added to the front of the list.
/// 
/// See also:
/// 
///  * [WidgetTester.pumpFrames], which is often used together to display the
///    frame-by-frame animation of a widget in a test.
class SheetDisplay extends StatelessWidget {
  /// Create an [SheetDisplay] using a fixed `target` widget.
  /// 
  /// The `cellSize` and `frameIndex` are required.
  const SheetDisplay({
    Key key,
    this.target, 
    @required this.cellSize,
    @required this.cellNum,
  }) : assert(cellSize != null),
       assert(cellNum != null),
       super(key: key);

  /// The widget to show animation of.
  final Widget target;

  /// The size of a cell. Should contain a widget.
  /// 
  /// Should not change throughout the test.
  final Size cellSize;

  /// The number of clones to be displayed.
  final int cellNum;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _CellGrid(
        cellSize: cellSize,
        children: List<Widget>.generate(cellNum + 1, (int index) {
          final int i = cellNum - index;
          return Container(
            key: ValueKey<int>(i),
            child: target,
          );
        }),
      )
    );
  }
}

// A grid of fixed-sized cells that are positioned from top left, horizontal-first,
// until the the entire grid is filled, discarding the remaining children.
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
