// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:sky' as sky;

import 'package:newton/newton.dart';
import 'package:sky/animation/animated_simulation.dart';
import 'package:sky/animation/animated_value.dart';
import 'package:sky/animation/animation_performance.dart';
import 'package:sky/animation/curves.dart';
import 'package:sky/animation/scroll_behavior.dart';
import 'package:sky/theme/view_configuration.dart' as config;
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/block_viewport.dart';
import 'package:sky/widgets/scrollable.dart';
import 'package:sky/widgets/framework.dart';

export 'package:sky/widgets/block_viewport.dart' show BlockViewportLayoutState;

const double _kMillisecondsPerSecond = 1000.0;

double _velocityForFlingGesture(double eventVelocity) {
  // eventVelocity is pixels/second, config min,max limits are pixels/ms
  return eventVelocity.clamp(-config.kMaxFlingVelocity, config.kMaxFlingVelocity) /
    _kMillisecondsPerSecond;
}

abstract class ScrollClient {
  bool ancestorScrolled(Scrollable ancestor);
}

/// A base class for scrollable widgets that reacts to user input and generates
/// a scrollOffset.
abstract class Scrollable extends StatefulComponent {

  Scrollable({
    Key key,
    this.scrollDirection: ScrollDirection.vertical
  }) : super(key: key) {
    assert(scrollDirection == ScrollDirection.vertical ||
        scrollDirection == ScrollDirection.horizontal);
  }

  ScrollDirection scrollDirection;

  AnimatedSimulation _toEndAnimation; // See _startToEndAnimation()
  AnimationPerformance _toOffsetAnimation; // Started by scrollTo(offset, duration: d)

  void initState() {
    _toEndAnimation = new AnimatedSimulation(_tickScrollOffset);
    _toOffsetAnimation = new AnimationPerformance()
      ..addListener(() {
        AnimatedValue<double> offset = _toOffsetAnimation.variable;
        scrollTo(offset.value);
      });
  }

  void syncFields(Scrollable source) {
    scrollDirection == source.scrollDirection;
  }

  double _scrollOffset = 0.0;
  double get scrollOffset => _scrollOffset;

  Offset get scrollOffsetVector {
    if (scrollDirection == ScrollDirection.horizontal)
      return new Offset(scrollOffset, 0.0);
    return new Offset(0.0, scrollOffset);
  }

  ScrollBehavior _scrollBehavior;
  ScrollBehavior createScrollBehavior();
  ScrollBehavior get scrollBehavior {
    if (_scrollBehavior == null)
      _scrollBehavior = createScrollBehavior();
    return _scrollBehavior;
  }

  Widget buildContent();

  Widget build() {
    return new Listener(
      child: buildContent(),
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUpOrCancel,
      onPointerCancel: _handlePointerUpOrCancel,
      onGestureFlingStart: _handleFlingStart,
      onGestureFlingCancel: _handleFlingCancel,
      onGestureScrollUpdate: _handleScrollUpdate,
      onWheel: _handleWheel
    );
  }

  List<ScrollClient> _registeredScrollClients;

  void registerScrollClient(ScrollClient notifiee) {
    if (_registeredScrollClients == null)
      _registeredScrollClients = new List<ScrollClient>();
    setState(() {
      _registeredScrollClients.add(notifiee);
    });
  }

  void unregisterScrollClient(ScrollClient notifiee) {
    if (_registeredScrollClients == null)
      return;
    setState(() {
      _registeredScrollClients.remove(notifiee);
    });
  }

  void _startToOffsetAnimation(double newScrollOffset, Duration duration) {
      _stopToEndAnimation();
      _stopToOffsetAnimation();
      _toOffsetAnimation
        ..variable = new AnimatedValue<double>(scrollOffset,
          end: newScrollOffset,
          curve: ease
        )
        ..progress = 0.0
        ..duration = duration
        ..play();
  }

  void _stopToOffsetAnimation() {
    if (_toOffsetAnimation.isAnimating)
      _toOffsetAnimation.stop();
  }

  void _startToEndAnimation({ double velocity: 0.0 }) {
    _stopToEndAnimation();
    _stopToOffsetAnimation();
    Simulation simulation = scrollBehavior.release(scrollOffset, velocity);
    if (simulation != null)
      _toEndAnimation.start(simulation);
  }

  void _stopToEndAnimation() {
    _toEndAnimation.stop();
  }

  void didUnmount() {
    _stopToEndAnimation();
    _stopToOffsetAnimation();
    super.didUnmount();
  }

  bool scrollTo(double newScrollOffset, { Duration duration }) {
    if (newScrollOffset == _scrollOffset)
      return false;

    if (duration == null) {
      setState(() {
        _scrollOffset = newScrollOffset;
      });
    } else {
      _startToOffsetAnimation(newScrollOffset, duration);
    }

    if (_registeredScrollClients != null) {
      var newList = null;
      _registeredScrollClients.forEach((target) {
        if (target.ancestorScrolled(this)) {
          if (newList == null)
            newList = new List<ScrollClient>();
          newList.add(target);
        }
      });
      setState(() {
        _registeredScrollClients = newList;
      });
    }
    return true;
  }

  bool scrollBy(double scrollDelta) {
    double newScrollOffset = scrollBehavior.applyCurve(_scrollOffset, scrollDelta);
    return scrollTo(newScrollOffset);
  }

  void settleScrollOffset() {
    _startToEndAnimation();
  }

  void _tickScrollOffset(double value) {
    scrollTo(value);
  }

  EventDisposition _handlePointerDown(_) {
    _stopToEndAnimation();
    _stopToOffsetAnimation();
    return EventDisposition.processed;
  }

  EventDisposition _handleScrollUpdate(sky.GestureEvent event) {
    scrollBy(scrollDirection == ScrollDirection.horizontal ? event.dx : -event.dy);
    return EventDisposition.processed;
  }

  EventDisposition _handleFlingStart(sky.GestureEvent event) {
    double eventVelocity = scrollDirection == ScrollDirection.horizontal
      ? -event.velocityX
      : -event.velocityY;
    _startToEndAnimation(velocity: _velocityForFlingGesture(eventVelocity));
    return EventDisposition.processed;
  }

  void _maybeSettleScrollOffset() {
    if (!_toEndAnimation.isAnimating && !_toOffsetAnimation.isAnimating)
      settleScrollOffset();
  }

  EventDisposition _handlePointerUpOrCancel(_) {
    _maybeSettleScrollOffset();
    return EventDisposition.processed;
  }

  EventDisposition _handleFlingCancel(sky.GestureEvent event) {
    _maybeSettleScrollOffset();
    return EventDisposition.processed;
  }


  EventDisposition _handleWheel(sky.WheelEvent event) {
    scrollBy(-event.offsetY);
    return EventDisposition.processed;
  }
}

/// A simple scrollable widget that has a single child. Use this component if
/// you are not worried about offscreen widgets consuming resources.
class ScrollableViewport extends Scrollable {
  ScrollableViewport({
    Key key,
    this.child,
    ScrollDirection scrollDirection: ScrollDirection.vertical
  }) : super(key: key, scrollDirection: scrollDirection);

  Widget child;

  void syncFields(ScrollableViewport source) {
    child = source.child;
    super.syncFields(source);
  }

  ScrollBehavior createScrollBehavior() => new OverscrollWhenScrollableBehavior();
  OverscrollWhenScrollableBehavior get scrollBehavior => super.scrollBehavior;

  double _viewportSize = 0.0;
  double _childSize = 0.0;
  void _handleViewportSizeChanged(Size newSize) {
    _viewportSize = scrollDirection == ScrollDirection.vertical ? newSize.height : newSize.width;
    _updateScrollBehaviour();
  }
  void _handleChildSizeChanged(Size newSize) {
    _childSize = scrollDirection == ScrollDirection.vertical ? newSize.height : newSize.width;
    _updateScrollBehaviour();
  }
  void _updateScrollBehaviour() {
    scrollBehavior.contentsSize = _childSize;
    scrollBehavior.containerSize = _viewportSize;
    if (scrollOffset > scrollBehavior.maxScrollOffset)
      settleScrollOffset();
  }

  Widget buildContent() {
    return new SizeObserver(
      callback: _handleViewportSizeChanged,
      child: new Viewport(
        scrollOffset: scrollOffsetVector,
        scrollDirection: scrollDirection,
        child: new SizeObserver(
          callback: _handleChildSizeChanged,
          child: child
        )
      )
    );
  }
}

/// A mashup of [ScrollableViewport] and [Block]. Useful when you have a small,
/// fixed number of children that you wish to arrange in a block layout and that
/// might exceed the height of its container (and therefore need to scroll).
class ScrollableBlock extends Component {
  ScrollableBlock(this.children, {
    Key key,
    this.scrollDirection: ScrollDirection.vertical
  }) : super(key: key);

  final List<Widget> children;
  final ScrollDirection scrollDirection;

  BlockDirection get _direction {
    if (scrollDirection == ScrollDirection.vertical)
      return BlockDirection.vertical;
    return BlockDirection.horizontal;
  }

  Widget build() {
    return new ScrollableViewport(
      scrollDirection: scrollDirection,
      child: new Block(children, direction: _direction)
    );
  }
}

/// An optimized scrollable widget for a large number of children that are all
/// of the same height. Use this widget when you have a large number of children
/// or when you are concerned about offscreen widgets consuming resources.
abstract class FixedHeightScrollable extends Scrollable {

  FixedHeightScrollable({ Key key, this.itemHeight, this.padding })
      : super(key: key) {
    assert(itemHeight != null);
  }

  EdgeDims padding;
  double itemHeight;

  /// Subclasses must implement `get itemCount` to tell FixedHeightScrollable
  /// how many items there are in the list.
  int get itemCount;
  int _previousItemCount;

  void syncFields(FixedHeightScrollable source) {
    padding = source.padding;
    itemHeight = source.itemHeight;
    super.syncFields(source);
  }

  ScrollBehavior createScrollBehavior() => new OverscrollBehavior();
  OverscrollBehavior get scrollBehavior => super.scrollBehavior;

  double _height;
  void _handleSizeChanged(Size newSize) {
    setState(() {
      _height = newSize.height;
      scrollBehavior.containerSize = _height;
    });
  }

  void _updateContentsHeight() {
    double contentsHeight = itemHeight * itemCount;
    if (padding != null)
      contentsHeight += padding.top + padding.bottom;
    scrollBehavior.contentsSize = contentsHeight;
  }

  void _updateScrollOffset() {
    if (scrollOffset > scrollBehavior.maxScrollOffset)
      settleScrollOffset();
  }

  Widget buildContent() {
    if (itemCount != _previousItemCount) {
      _previousItemCount = itemCount;
      _updateContentsHeight();
      _updateScrollOffset();
    }

    int itemShowIndex = 0;
    int itemShowCount = 0;
    double offsetY = 0.0;
    if (_height != null && _height > 0.0) {
      if (scrollOffset < 0.0) {
        double visibleHeight = _height + scrollOffset;
        itemShowCount = (visibleHeight / itemHeight).round() + 1;
        offsetY = scrollOffset;
      } else {
        itemShowCount = (_height / itemHeight).ceil();
        double alignmentDelta = -scrollOffset % itemHeight;
        double drawStart;
        if (alignmentDelta != 0.0) {
          alignmentDelta -= itemHeight;
          itemShowCount += 1;
          drawStart = scrollOffset + alignmentDelta;
          offsetY = -alignmentDelta;
        } else {
          drawStart = scrollOffset;
        }
        itemShowIndex = math.max(0, (drawStart / itemHeight).floor());
      }
    }

    List<Widget> items = buildItems(itemShowIndex, itemShowCount);
    assert(items.every((item) => item.key != null));

    // TODO(ianh): Refactor this so that it does the building in the
    // same frame as the size observing, similar to BlockViewport, but
    // keeping the fixed-height optimisations.
    return new SizeObserver(
      callback: _handleSizeChanged,
      child: new Viewport(
        scrollOffset: new Offset(0.0, offsetY),
        child: new Container(
          padding: padding,
          child: new Block(items)
        )
      )
    );
  }

  List<Widget> buildItems(int start, int count);

}

typedef Widget ItemBuilder<T>(T item);

/// A wrapper around [FixedHeightScrollable] that helps you translate a list of
/// model objects into a scrollable list of widgets. Assumes all the widgets
/// have the same height.
class ScrollableList<T> extends FixedHeightScrollable {
  ScrollableList({
    Key key,
    this.items,
    this.itemBuilder,
    double itemHeight,
    EdgeDims padding
  }) : super(key: key, itemHeight: itemHeight, padding: padding);

  List<T> items;
  ItemBuilder<T> itemBuilder;

  void syncFields(ScrollableList<T> source) {
    items = source.items;
    itemBuilder = source.itemBuilder;
    super.syncFields(source);
  }

  int get itemCount => items.length;

  List<Widget> buildItems(int start, int count) {
    List<Widget> result = new List<Widget>();
    int end = math.min(start + count, items.length);
    for (int i = start; i < end; ++i)
      result.add(itemBuilder(items[i]));
    return result;
  }
}

/// A general scrollable list for a large number of children that might not all
/// have the same height. Prefer [FixedHeightScrollable] when all the children
/// have the same height because it can use that property to be more efficient.
/// Prefer [ScrollableViewport] with a single child.
class VariableHeightScrollable extends Scrollable {
  VariableHeightScrollable({
    Key key,
    this.builder,
    this.token,
    this.layoutState
  }) : super(key: key);

  IndexedBuilder builder;
  Object token;
  BlockViewportLayoutState layoutState;

  // When the token changes the scrollable's contents may have
  // changed. Remember as much so that after the new contents
  // have been laid out we can adjust the scrollOffset so that
  // the last page of content is still visible.
  bool _contentsChanged = true;

  void initState() {
    assert(layoutState != null);
    super.initState();
  }

  void didMount() {
    layoutState.addListener(_handleLayoutChanged);
    super.didMount();
  }

  void didUnmount() {
    layoutState.removeListener(_handleLayoutChanged);
    super.didUnmount();
  }

  void syncFields(VariableHeightScrollable source) {
    builder = source.builder;
    if (token != source.token)
      _contentsChanged = true;
    token = source.token;
    if (layoutState != source.layoutState) {
      // Warning: this is unlikely to be what you intended.
      assert(source.layoutState != null);
      layoutState.removeListener(_handleLayoutChanged);
      layoutState = source.layoutState;
      layoutState.addListener(_handleLayoutChanged);
    }
    super.syncFields(source);
  }

  ScrollBehavior createScrollBehavior() => new OverscrollBehavior();
  OverscrollBehavior get scrollBehavior => super.scrollBehavior;

  void _handleSizeChanged(Size newSize) {
    scrollBehavior.containerSize = newSize.height;
  }

  void _handleLayoutChanged() {
    if (layoutState.didReachLastChild) {
      scrollBehavior.contentsSize = layoutState.contentsSize;
      if (_contentsChanged && scrollOffset > scrollBehavior.maxScrollOffset) {
        _contentsChanged = false;
        settleScrollOffset();
      }
    } else {
      scrollBehavior.contentsSize = double.INFINITY;
    }
  }

  Widget buildContent() {
    return new SizeObserver(
      callback: _handleSizeChanged,
      child: new BlockViewport(
        builder: builder,
        layoutState: layoutState,
        startOffset: scrollOffset,
        token: token
      )
    );
  }
}
