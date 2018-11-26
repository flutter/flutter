// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/src/cupertino/colors.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

@visibleForTesting
const double kDefaultTableViewCellHeight = 44.0;

@visibleForTesting
const double kDefaultCellInset = 16.0;

@visibleForTesting
const double kDefaultDividerHeight = 1.0;

/// WARNING: CupertinoTableView and its associated classes are EXPERIMENTAL. IF
/// YOU USE THESE APIS, WE WILL BREAK YOU!
///
/// An iOS-styled table view.
///
/// Table views are used in iOS to render lists of cells. They are the iOS
/// equivalent of Android's `ListView` and `RecyclerView`. [CupertinoTableView]
/// is Flutter's iOS-styled alternative to [ListView].
///
/// # Cells
///
/// To achieve complete iOS style parity, consider filling [CupertinoTableView]s
/// with [CupertinoTableViewCell]s. If custom cells are desired, any widget
/// can be added to a [CupertinoTableView].
///
/// # Dividers
///
/// By default, [CupertinoTableView]s render dividers between each cell. For
/// custom cells, the divider beneath the cell is rendered with a standard inset
/// on the starting edge and is then drawn all the way to the ending edge. For
/// [CupertinoTableViewCell]s, the divider starts where the title text starts
/// and then renders all the way to the ending edge. This divider behavior is
/// as per iOS behavior.
///
/// If a [CupertinoTableView] does not contain enough cells to fill the viewport
/// then extra dividers are rendered beyond the last cell to the end of the
/// viewport. This extra divider rendering extends into overscroll space at the
/// end, too. The gap between extra dividers is equal to the height of the
/// last cell in the [CupertinoTableView].
///
/// # Styles
///
/// A [CupertinoTableView] may be rendered either in a "plain" style or a
/// "grouped" style.
///
/// A plain [CupertinoTableView] renders a single set of cells without any
/// divisions between cells.
///
/// A grouped [CupertinoTableView] subdivides cells into sections. Sections
/// are rendered with gaps between them and optional headers before each section.
///
/// # Section Index
///
/// If a [CupertinoTableView] is in a grouped style, it can optionally display
/// a section "index". This index is a thin strip that appears on the right side
/// of the [CupertinoTableView], displays titles for each section in the
/// [CupertinoTableView], and allows users to tap on a given section title to
/// automatically scroll to that section.
///
/// See also:
///
///  * [CupertinoTableViewCell], which renders an iOS-style table view cell that
///    is intended to appear within a [CupertinoTableView].
///  * [ListView], which renders a style agnostic list.
class CupertinoTableView extends StatefulWidget {
  /// Creates a plain-style [CupertinoTableView] with an explicit list of cells.
  const CupertinoTableView.plain({
    this.scrollController,
    this.backgroundColor = CupertinoColors.white,
    this.plainChildren = const <Widget>[],
  }) : plainChildrenBuilder = null,
       plainChildCount = null;

  /// Creates a plain-style [CupertinoTableView] with a lazily built list of cells.
  const CupertinoTableView.plainBuilder({
    this.scrollController,
    this.backgroundColor = CupertinoColors.white,
    this.plainChildCount,
    @required this.plainChildrenBuilder,
  }) : plainChildren = null;

  /// ScrollController that controls the scroll position of this [CupertinoTableView].
  final ScrollController scrollController;

  /// The table's background color beneath its cells.
  final Color backgroundColor;

  /// Explicit list of child cell widgets. If [plainChildren] is provided then
  /// [plainChildrenBuilder] must be null.
  final List<Widget> plainChildren;

  /// Lazily built list of child cell widgets. If [plainChildrenBuilder] is
  /// provided then [plainChildren] must be null.
  final IndexedWidgetBuilder plainChildrenBuilder;

  /// The number of children that can be built with [plainChildrenBuilder].
  ///
  /// The [plainChildCount] is optional. If it's provided then only a subset
  /// of the plain children will be built at a time, based on viewport size. If
  /// [plainChildCount] is not provided, then all plain children will be
  /// created from the very beginning.
  final int plainChildCount;

  @override
  _CupertinoTableViewState createState() => _CupertinoTableViewState();
}

class _CupertinoTableViewState extends State<CupertinoTableView> {
  // The size of the last cell in the table, used to determine the desired gap
  // between all extra dividers below it.
  Size _lastItemSize;

  // Decorator that builds cell widgets with extra chrome and/or functionality,
  // e.g., adding a divider to a cell.
  IndexedWidgetBuilder _cellDecorator;

  @override
  void initState() {
    super.initState();
    _cellDecorator = _createCellDecorator();
  }

  @override
  void didUpdateWidget(CupertinoTableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _cellDecorator = _createCellDecorator();
  }

  @override
  void reassemble() {
    super.reassemble();
    _cellDecorator = _createCellDecorator();
  }

  IndexedWidgetBuilder _createCellDecorator() {
    if (widget.plainChildren != null) {
      return _buildPlainChildFromList;
    } else if (widget.plainChildrenBuilder != null) {
      return _buildPlainChildFromBuilder;
    } else {
      throw Exception('No children found.');
    }
  }

  Widget _buildPlainChildFromList(BuildContext context, int index) {
    if (index >= widget.plainChildren.length) {
      return null;
    }

    final bool isLastCell = index == widget.plainChildren.length - 1;
    return _decorateCell(widget.plainChildren[index], isLastCell);
  }

  Widget _buildPlainChildFromBuilder(BuildContext context, int index) {
    final Widget cell = widget.plainChildrenBuilder(context, index);
    if (cell == null) {
      return null;
    }

    bool isLastCell;
    if (widget.plainChildCount != null) {
      // The child count was provided so we will simply compare cell indices.
      isLastCell = index == widget.plainChildCount - 1;
    } else {
      // No child count was provided, so the only way to know if this is the
      // last cell is to build the next cell and check for null.
      final Widget nextCell = widget.plainChildrenBuilder(context, index + 1);
      isLastCell =  nextCell == null;
    }

    return _decorateCell(cell, isLastCell);
  }

  // Decorates an individual cell with a divider beneath it. If this cell
  // [isLastCell] in the table then this decorator also adds a
  // [_LayoutSizeReport] so that the height of this last cell can be reported
  // to the extra dividers sliver.
  Widget _decorateCell(Widget cell, bool isLastCell) {
    final Widget cellWithDivider = Container(
      foregroundDecoration: CupertinoDividerDecoration(),
      child: cell,
    );

    if (isLastCell) {
      return _LayoutSizeReport(
        sizeCallback: (Size size) {
          if (size != _lastItemSize) {
            WidgetsBinding.instance.addPostFrameCallback((Duration dt) {
              setState(() {
                _lastItemSize = size;
              });
            });
          }
        },
        child: cellWithDivider,
      );
    } else {
      return cellWithDivider;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Visual list of cells.
    final Widget sliverList = SliverList(
      delegate: SliverChildBuilderDelegate(
        _cellDecorator,
        childCount: widget.plainChildCount,
      ),
    );

    // Visual list of cells + extra dividers at the bottom.
    final Widget scrollingList = CustomScrollView(
      controller: widget.scrollController,
      slivers: <Widget>[]
        ..add(sliverList)
        ..add(CupertinoTableViewExtraDividers(
          cellHeight: _lastItemSize?.height,
        )),
    );

    // Apply a background color beneath the cells in the table.
    return Container(
      color: widget.backgroundColor,
      child: scrollingList,
    );
  }
}

/// [Decoration] that paints a Cupertino-style divider at the bottom of its content.
///
/// The [dividerThickness], [dividerInset], and [dividerColor] are all customizable.
/// They default to the standard iOS values.
class CupertinoDividerDecoration extends Decoration {
  /// Constructs a [CupertinoDividerDecoration] with default iOS values for
  /// omitted parameters.
  const CupertinoDividerDecoration({
    this.dividerThickness = kDefaultDividerHeight,
    this.dividerInset = kDefaultCellInset,
    this.dividerColor = CupertinoColors.lightBackgroundGray,
  });

  /// Thickness of the painted divider.
  final double dividerThickness;

  /// Gap from the starting horizontal edge to the start of the painted divider.
  final double dividerInset;

  /// Color of the painted divider.
  final Color dividerColor;

  @override
  BoxPainter createBoxPainter([VoidCallback onChanged]) {
    return _CupertinoDividerDecorationPainter(
      dividerThickness: dividerThickness,
      dividerInset: dividerInset,
      dividerColor: dividerColor,
    );
  }
}

class _CupertinoDividerDecorationPainter extends BoxPainter {
  _CupertinoDividerDecorationPainter({
    this.dividerThickness = kDefaultDividerHeight,
    this.dividerInset = kDefaultCellInset,
    this.dividerColor = CupertinoColors.lightBackgroundGray,
  }) : _dividerPaint = Paint()
    ..color = dividerColor
    ..style = PaintingStyle.fill;

  final double dividerThickness;
  final double dividerInset;
  final Color dividerColor;
  final Paint _dividerPaint;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Size size = configuration.size;

    canvas.drawRect(
      Rect.fromLTRB(
        dividerInset,
        size.height - dividerThickness,
        size.width,
        size.height,
      ).shift(offset),
      _dividerPaint,
    );
  }
}

/// Widget that renders a [Sliver] that draws extra dividers after the last cell
/// in a [CupertinoTableView].
///
/// No dividers will be drawn if [CupertinoTableView] has enough cells to scroll,
/// as per iOS behavior.
///
/// The gap between extra dividers is equal to the height of the last cell in
/// the [CupertinoTableView], as per iOS behavior.
@visibleForTesting
class CupertinoTableViewExtraDividers extends RenderObjectWidget {
  const CupertinoTableViewExtraDividers({
    double cellHeight,
  }) : cellHeight = cellHeight ?? kDefaultTableViewCellHeight;

  final double cellHeight;

  @override
  RenderObjectElement createElement() {
    return CupertinoTableViewExtraDividersElement(this);
  }

  @override
  RenderObject createRenderObject(BuildContext context) {
    return CupertinoTableViewExtraDividersRenderObject(
      cellHeight: cellHeight,
    );
  }

  @override
  void updateRenderObject(BuildContext context, CupertinoTableViewExtraDividersRenderObject renderObject) {
    renderObject.cellHeight = cellHeight;
  }
}

@visibleForTesting
class CupertinoTableViewExtraDividersElement extends RenderObjectElement {
  CupertinoTableViewExtraDividersElement(Widget widget) : super(widget);

  @override
  void forgetChild(Element child) {}

  @override
  void insertChildRenderObject(RenderObject child, dynamic slot) {}

  @override
  void moveChildRenderObject(RenderObject child, dynamic slot) {}

  @override
  void removeChildRenderObject(RenderObject child) {}

}

@visibleForTesting
class CupertinoTableViewExtraDividersRenderObject extends RenderSliver {
  CupertinoTableViewExtraDividersRenderObject({
    double cellHeight,
    double dividerThickness = kDefaultDividerHeight,
  }) : _cellHeight = cellHeight ?? kDefaultTableViewCellHeight,
       _linePaint = Paint()
         ..color = CupertinoColors.lightBackgroundGray
         ..strokeWidth = dividerThickness;

  double get cellHeight => _cellHeight;
  double _cellHeight;
  set cellHeight(double newCellHeight) {
    _cellHeight = newCellHeight;
    markNeedsLayout();
  }

  final Paint _linePaint;

  @override
  void performLayout() {
    if (constraints.precedingScrollExtent < constraints.viewportMainAxisExtent) {
      geometry = SliverGeometry(
        paintExtent: constraints.remainingPaintExtent,
        maxPaintExtent: constraints.remainingPaintExtent,
        layoutExtent: constraints.remainingPaintExtent,
        hitTestExtent: 0.0,
      );
    } else {
      geometry = SliverGeometry.zero;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (geometry == SliverGeometry.zero) {
      return;
    }

    final double extentToPaint = geometry.paintExtent + constraints.scrollOffset;
    final int dividerCount = (extentToPaint / cellHeight).round();
    final Canvas canvas = context.canvas;
    final double paintAndScrollOffset = -constraints.scrollOffset + offset.dy;
    for (int i = 0; i < dividerCount; ++i) {
      final double lineY = ((i + 1) * cellHeight) + paintAndScrollOffset;
      canvas.drawLine(
        Offset(kDefaultCellInset, lineY),
        Offset(constraints.crossAxisExtent, lineY),
        _linePaint,
      );
    }
  }

  CupertinoTableViewExtraDividersDescription debugDescribe() {
    return CupertinoTableViewExtraDividersDescription(
      isDrawingDividers: geometry != SliverGeometry.zero,
      dividerGapHeight: cellHeight,
      extraDividersExtent: geometry.paintExtent,
    );
  }
}

@visibleForTesting
class CupertinoTableViewExtraDividersDescription {
  CupertinoTableViewExtraDividersDescription({
    this.isDrawingDividers,
    this.dividerGapHeight,
    this.extraDividersExtent,
  });

  final bool isDrawingDividers;
  final double dividerGapHeight;
  final double extraDividersExtent;
}

// Widget that reports its child's size at layout time.
//
// During this widget's [RenderBox]'s layout phase, its child is sized. That
// size is then immediately reported to the provided [sizeCallback]. The
// [sizeCallback] can then use this size information to impact layout or paint
// behavior.
//
// Ideally, [sizeCallback] should be used for painting behavior and not layout
// behavior because the size is determined during the layout pass. Calling
// `setState()` within the [sizeCallback] will throw an error.
// [SchedulerBinding#addPostFrameCallback()] can be used to invoke `setState()`
// during the next frame, but then the use of the reported size will be one
// frame behind the layout/rendering of the given [child].
//
// This widget is used by CupertinoTableView to determine the height of the last
// cell in the table and use that height for drawing extra dividers below the
// last cell.
class _LayoutSizeReport extends SingleChildRenderObjectWidget {
  const _LayoutSizeReport({
    Key key,
    this.sizeCallback,
    Widget child,
  }) : super(key: key, child: child);

  final _SizeCallback sizeCallback;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _LayoutSizeReportRenderBox(
      callback: sizeCallback,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _LayoutSizeReportRenderBox renderObject) {
    renderObject.sizeCallback = sizeCallback;
  }
}

// [RenderBox] that reports the size of its child at layout time.
class _LayoutSizeReportRenderBox extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  _LayoutSizeReportRenderBox({
    _SizeCallback callback,
  }) : _sizeCallback = callback;

  _SizeCallback get sizeCallback => _sizeCallback;
  _SizeCallback _sizeCallback;
  set sizeCallback(_SizeCallback callback) {
    _sizeCallback = callback;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    child.layout(constraints, parentUsesSize: true);
    size = child.size;

    if (_sizeCallback != null) {
      _sizeCallback(size);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    child.paint(context, offset);
  }

  @override
  bool hitTestChildren(HitTestResult result, {Offset position}) {
    return child.hitTest(result, position: position);
  }
}

// Callback that reports the size of a [RenderBox] widget at layout time.
typedef _SizeCallback = void Function(Size size);