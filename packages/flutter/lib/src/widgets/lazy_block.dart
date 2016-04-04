// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'scrollable.dart';
import 'scroll_behavior.dart';

/// Provides children for [LazyBlock] and [LazyBlockViewport]
abstract class LazyBlockDelegate {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const LazyBlockDelegate();

  /// Returns a widget representing the item with the given index.
  ///
  /// The returned widget might or might not be cached by [LazyBlock]. See
  /// [shouldRebuild] for details about how to evict the cache.
  Widget buildItem(BuildContext context, int index);

  /// Whether [LazyBlock] should evict its cache of widgets returned by [buildItem].
  ///
  /// When a [LazyBlock] receives a new configuration, it evicts its cache of
  /// widgets if (1) the new configuration has a delegate with a different
  /// runtimeType thant he old delegate, or (2) the [shouldRebuild] method of
  /// the new delegate returns true when passed the old delgate.
  ///
  /// When calling this function, [LazyBlock] will always pass an argument that
  /// matches the runtimeType of the receiver.
  bool shouldRebuild(LazyBlockDelegate oldDelegate);
}

class LazyBlock extends Scrollable {
  LazyBlock({
    Key key,
    double initialScrollOffset,
    ScrollListener onScroll,
    SnapOffsetCallback snapOffsetCallback,
    this.delegate
  }) : super(
    key: key,
    initialScrollOffset: initialScrollOffset,
    onScroll: onScroll,
    snapOffsetCallback: snapOffsetCallback
  );

  final LazyBlockDelegate delegate;

  @override
  ScrollableState<LazyBlock> createState() => new _LazyBlockState();
}

class _LazyBlockState extends ScrollableState<LazyBlock> {
  @override
  BoundedBehavior createScrollBehavior() => new OverscrollWhenScrollableBehavior();

  @override
  BoundedBehavior get scrollBehavior => super.scrollBehavior;

  void _handleExtentsChanged(double contentExtent, double containerExtent, double minScrollOffset) {
    setState(() {
      didUpdateScrollBehavior(scrollBehavior.updateExtents(
        contentExtent: contentExtent,
        containerExtent: containerExtent,
        minScrollOffset: minScrollOffset,
        scrollOffset: scrollOffset
      ));
    });
  }

  @override
  Widget buildContent(BuildContext context) {
    return new LazyBlockViewport(
      startOffset: scrollOffset,
      direction: config.scrollDirection,
      onExtentsChanged: _handleExtentsChanged,
      delegate: config.delegate
    );
  }
}

typedef void LazyBlockExtentsChangedCallback(double contentExtent, double containerExtent, double minScrollOffset);

class LazyBlockViewport extends RenderObjectWidget {
  LazyBlockViewport({
    Key key,
    this.startOffset,
    this.direction,
    this.onExtentsChanged,
    this.delegate
  }) : super(key: key);

  final double startOffset;
  final Axis direction;
  final LazyBlockExtentsChangedCallback onExtentsChanged;
  final LazyBlockDelegate delegate;

  @override
  _LazyBlockElement createElement() => new _LazyBlockElement(this);

  @override
  _RenderLazyBlock createRenderObject(BuildContext context) => new _RenderLazyBlock();
}

class _LazyBlockParentData extends ContainerBoxParentDataMixin<RenderBox> { }

class _RenderLazyBlock extends RenderVirtualViewport<_LazyBlockParentData> {
  _RenderLazyBlock({
    Offset paintOffset: Offset.zero,
    Axis mainAxis: Axis.vertical,
    LayoutCallback callback
  }) : super(
    paintOffset: paintOffset,
    mainAxis: mainAxis,
    callback: callback
  );

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _LazyBlockParentData)
      child.parentData = new _LazyBlockParentData();
  }

  double _noIntrinsicExtent() {
    assert(() {
      if (!RenderObject.debugCheckingIntrinsics) {
        throw new UnsupportedError(
          'MixedViewport does not support returning intrinsic dimensions.\n'
          'Calculating the intrinsic dimensions would require walking the entire child list,\n'
          'which defeats the entire point of having a lazily-built list of children.'
        );
      }
      return true;
    });
    return null;
  }

  double getIntrinsicWidth(BoxConstraints constraints) {
    switch (mainAxis) {
      case Axis.horizontal:
        return constraints.constrainWidth(0.0);
      case Axis.vertical:
        return _noIntrinsicExtent();
    }
  }

  @override
  double getMinIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    return getIntrinsicWidth(constraints);
  }

  @override
  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    return getIntrinsicWidth(constraints);
  }

  double getIntrinsicHeight(BoxConstraints constraints) {
    switch (mainAxis) {
      case Axis.horizontal:
        return constraints.constrainWidth(0.0);
      case Axis.vertical:
        return _noIntrinsicExtent();
    }
  }

  @override
  double getMinIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    return getIntrinsicHeight(constraints);
  }

  @override
  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    return getIntrinsicHeight(constraints);
  }

  @override
  bool get sizedByParent => true;

  @override
  bool get isRepaintBoundary => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  void performLayout() {
    if (callback != null)
      invokeLayoutCallback(callback);
  }
}

class _LazyBlockElement extends RenderObjectElement {
  _LazyBlockElement(LazyBlockViewport widget) : super(widget);

  @override
  LazyBlockViewport get widget => super.widget;

  @override
  _RenderLazyBlock get renderObject => super.renderObject;

  /// The offset of the top of the first item represented in _children from the top of the item with logical index zero.
  double _firstChildLogicalOffset = 0.0;

  /// The logical index of the first item represented in _children.
  int _firstChildLogicalIndex = 0;

  /// The explicitly represented items.
  List<Element> _children = <Element>[];

  /// The minimum scroll offset used by the scroll behavior.
  ///
  /// Not all the items between the minimum and maximum scroll offsets are
  /// reprsented explicitly in _children.
  double _minScrollOffset = 0.0;

  /// The maximum scroll offset used by the scroll behavior.
  ///
  /// Not all the items between the minimum and maximum scroll offsets are
  /// reprsented explicitly in _children.
  double _maxScrollOffset = 0.0;

  /// The smallest start offset (inclusive) that can be displayed properly with the items currently represented in [_children].
  double _startOffsetLowerLimit = 0.0;

  /// The largest start offset (exclusive) that can be displayed properly with the items currently represented in [_children].
  double _startOffsetUpperLimit = 0.0;

  double _lastReportedContentExtent;
  double _lastReportedContainerExtent;
  double _lastReportedMinScrollOffset;

  @override
  void visitChildren(ElementVisitor visitor) {
    for (Element child in _children)
      visitor(child);
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    renderObject
      ..callback = _layout
      ..mainAxis = widget.direction;
    // Children will get built during layout.
    // Paint offset will get updated during layout.
  }

  @override
  void update(LazyBlockViewport newWidget) {
    LazyBlockViewport oldWidget = widget;
    super.update(newWidget);
    renderObject.mainAxis = widget.direction;
    if (newWidget.delegate.runtimeType != oldWidget.delegate.runtimeType ||
        newWidget.delegate.shouldRebuild(oldWidget.delegate)) {
      IndexedBuilder builder = widget.delegate.buildItem;
      List<Widget> widgets = new List<Widget>(_children.length);
      for (int i = 0; i < widgets.length; ++i)
        widgets[i] = builder(this, _firstChildLogicalIndex + i);
      _children = updateChildren(_children, widgets);
    }
    // If the new start offset can be displayed properly with the items
    // currently represented in _children, we just need to update the paint
    // offset. Otherwise, we need to trigger a layout in order to change the
    // set of explicitly represented children.
    if (widget.startOffset >= _startOffsetLowerLimit && widget.startOffset < _startOffsetUpperLimit)
      _updatePaintOffset();
    else
      renderObject.markNeedsLayout();
  }

  @override
  void unmount() {
    renderObject.callback = null;
    super.unmount();
  }

  void _layout(BoxConstraints constraints) {
    final double blockExtent = _getMainAxisExtent(renderObject.size);

    owner.lockState(() {
      final IndexedBuilder builder = widget.delegate.buildItem;
      final double startLogicalOffset = widget.startOffset;
      final double endLogicalOffset = startLogicalOffset + blockExtent;
      final _RenderLazyBlock block = renderObject;
      final BoxConstraints innerConstraints = _getInnerConstraints(constraints);

      // A high watermark for which children have been through layout this pass.
      int firstLogicalIndexNeedingLayout = _firstChildLogicalIndex;

      // The index of the current child we're examining. The index is the same one
      // used for the builder (as opposed to the physical index in the _children
      // list).
      int currentLogicalIndex = _firstChildLogicalIndex;

      // The offset of the current child we're examining from the start of the
      // entire block (in the direction of the main axis). As we compute layout
      // information, we use dead reckoning to keep track of where all the
      // children are based on this quantity.
      double currentLogicalOffset = _firstChildLogicalOffset;

      // First, we check if we need to inflate any children before the start of
      // the viewport. Because we're dead reckoning from the current viewport, we
      // inflate the children in reverse tree order.

      if (currentLogicalIndex > 0 && currentLogicalOffset > startLogicalOffset) {
        final List<Element> newChildren = <Element>[];

        while (currentLogicalIndex > 0 && currentLogicalOffset > startLogicalOffset) {
          currentLogicalIndex -= 1;
          Widget newWidget = new RepaintBoundary.wrap(builder(this, currentLogicalIndex), currentLogicalIndex);
          assert(newWidget != null);
          newChildren.add(inflateWidget(newWidget, null));
          RenderBox child = block.firstChild;
          assert(child == newChildren.last.renderObject);
          child.layout(innerConstraints, parentUsesSize: true);
          currentLogicalOffset -= _getMainAxisExtent(child.size);
        }

        final int numberOfNewChildren = newChildren.length;
        _children.insertAll(0, newChildren.reversed);
        _firstChildLogicalIndex = currentLogicalIndex;
        _firstChildLogicalOffset = currentLogicalOffset;
        firstLogicalIndexNeedingLayout = currentLogicalIndex + numberOfNewChildren;
      } else if (currentLogicalOffset < startLogicalOffset) {
        // If we didn't need to inflate more children before the viewport, we
        // might need to deactivate children that have left the viewport from the
        // top. We repeatedly check whether the first child overlaps the viewport
        // and deactivate it if it's outside the viewport.
        int currentPhysicalIndex = 0;
        while (block.firstChild != null) {
          RenderBox child = block.firstChild;
          child.layout(innerConstraints, parentUsesSize: true);
          firstLogicalIndexNeedingLayout += 1;
          double childExtent = _getMainAxisExtent(child.size);
          if (currentLogicalOffset + childExtent >= startLogicalOffset)
            break;
          deactivateChild(_children[currentPhysicalIndex]);
          _children[currentPhysicalIndex] = null;
          currentPhysicalIndex += 1;
          currentLogicalIndex += 1;
          currentLogicalOffset += childExtent;
        }

        if (currentPhysicalIndex > 0) {
          _children.removeRange(0, currentPhysicalIndex);
          _firstChildLogicalIndex = currentLogicalIndex;
          _firstChildLogicalOffset = currentLogicalOffset;
        }
      }

      // We've now established the invariant that the first physical child in the
      // block is the first child that ought to be visible in the viewport. Now we
      // need to walk forward until we've filled up the viewport. We might have
      // already called layout for some of the children we encounter in this phase
      // of the algorithm, we we'll need to be careful not to call layout on them again.

      if (currentLogicalOffset >= startLogicalOffset) {
        // The first element is visible. We need to update our reckoning of where
        // the min scroll offset is.
        _minScrollOffset = currentLogicalOffset;
        _startOffsetLowerLimit = double.NEGATIVE_INFINITY;
      } else {
        // The first element is not visible. Ensure that we have enough headroom
        // so we don't hit the min scroll offset prematurely.
        _minScrollOffset = currentLogicalOffset - blockExtent * 2.0;
        _startOffsetLowerLimit = currentLogicalOffset;
      }

      // Materialize new children until we fill the viewport (or run out of
      // children to materialize).

      RenderBox child;
      while (currentLogicalOffset < endLogicalOffset) {
        int physicalIndex = currentLogicalIndex - _firstChildLogicalIndex;
        if (physicalIndex >= _children.length) {
          assert(physicalIndex == _children.length);
          Widget newWidget = new RepaintBoundary.wrap(builder(this, currentLogicalIndex), currentLogicalIndex);
          if (newWidget == null)
            break;
          Element previousChild = _children.isEmpty ? null : _children.last;
          _children.add(inflateWidget(newWidget, previousChild));
        }
        child = _getNextWithin(block, child);
        assert(child != null);
        if (currentLogicalIndex >= firstLogicalIndexNeedingLayout) {
          assert(currentLogicalIndex == firstLogicalIndexNeedingLayout);
          child.layout(innerConstraints, parentUsesSize: true);
          firstLogicalIndexNeedingLayout += 1;
        }
        currentLogicalOffset += _getMainAxisExtent(child.size);
        currentLogicalIndex += 1;
      }

      // We now have all the physical children we ought to have to fill the
      // viewport. The currentLogicalIndex is the index of the first child that
      // we don't need.

      if (currentLogicalOffset < endLogicalOffset) {
        // The last element is visible. We need to update our reckoning of where
        // the max scroll offset is.
        _maxScrollOffset = currentLogicalOffset;
        _startOffsetUpperLimit = double.INFINITY;
      } else {
        // The last element is not visible. Ensure that we have enough headroom
        // so we don't hit the max scroll offset prematurely.
        _maxScrollOffset = currentLogicalOffset + blockExtent * 2.0;
        _startOffsetUpperLimit = currentLogicalOffset - blockExtent;
      }

      // Remove any unneeded children.

      int currentPhysicalIndex = currentLogicalIndex - _firstChildLogicalIndex;
      final int numberOfRequiredPhysicalChildren = currentPhysicalIndex;
      while (currentPhysicalIndex < _children.length) {
        deactivateChild(_children[currentPhysicalIndex]);
        _children[currentPhysicalIndex] = null;
        currentPhysicalIndex += 1;
      }
      _children.length = numberOfRequiredPhysicalChildren;

      // We now have the correct physical children, each of which has gone through
      // layout exactly once. We still need to position them correctly. We
      // position the first physical child at Offset.zero and use the paintOffset
      // on the render object to adjust the final paint location of the children.

      Offset currentChildOffset = Offset.zero;
      child = block.firstChild;
      while (child != null) {
        final _LazyBlockParentData childParentData = child.parentData;
        childParentData.offset = currentChildOffset;
        currentChildOffset += _getMainAxisOffsetForSize(child.size);
        child = childParentData.nextSibling;
      }

      _updatePaintOffset();
    }, building: true, context: 'during $runtimeType layout');

    LazyBlockExtentsChangedCallback onExtentsChanged = widget.onExtentsChanged;
    if (onExtentsChanged != null) {
      double contentExtent = _maxScrollOffset - _minScrollOffset;
      if (_lastReportedContentExtent != contentExtent ||
          _lastReportedContainerExtent != blockExtent ||
          _lastReportedMinScrollOffset != _minScrollOffset) {
        _lastReportedContentExtent = contentExtent;
        _lastReportedContainerExtent = blockExtent;
        _lastReportedMinScrollOffset = _minScrollOffset;
        onExtentsChanged(_lastReportedContentExtent, _lastReportedContainerExtent, _lastReportedMinScrollOffset);
      }
    }
  }

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    switch (widget.direction) {
      case Axis.horizontal:
        return new BoxConstraints.tightFor(height: constraints.maxHeight);
      case Axis.vertical:
        return new BoxConstraints.tightFor(width: constraints.maxWidth);
    }
  }

  double _getMainAxisExtent(Size size) {
    switch (widget.direction) {
      case Axis.horizontal:
        return size.width;
      case Axis.vertical:
        return size.height;
    }
  }

  Offset _getMainAxisOffsetForSize(Size size) {
    switch (widget.direction) {
      case Axis.horizontal:
        return new Offset(size.width, 0.0);
      case Axis.vertical:
        return new Offset(0.0, size.height);
    }
  }

  static RenderBox _getNextWithin(_RenderLazyBlock block, RenderBox child) {
    if (child == null)
      return block.firstChild;
    final _LazyBlockParentData childParentData = child.parentData;
    return childParentData.nextSibling;
  }

  void _updatePaintOffset() {
    double physicalStartOffset = widget.startOffset - _firstChildLogicalOffset;
    switch (widget.direction) {
      case Axis.horizontal:
        renderObject.paintOffset = new Offset(-physicalStartOffset, 0.0);
        break;
      case Axis.vertical:
        renderObject.paintOffset = new Offset(0.0, -physicalStartOffset);
        break;
    }
  }

  @override
  void insertChildRenderObject(RenderObject child, Element slot) {
    renderObject.insert(child, after: slot?.renderObject);
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slot) {
    assert(child.parent == renderObject);
    renderObject.move(child, after: slot?.renderObject);
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    assert(child.parent == renderObject);
    renderObject.remove(child);
  }
}
