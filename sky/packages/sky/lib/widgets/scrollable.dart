// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:sky' as sky;

import 'package:newton/newton.dart';
import 'package:sky/animation/animated_simulation.dart';
import 'package:sky/animation/animation_performance.dart';
import 'package:sky/animation/animated_value.dart';
import 'package:sky/animation/curves.dart';
import 'package:sky/animation/scroll_behavior.dart';
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/viewport.dart';
import 'package:sky/theme/view_configuration.dart' as config;
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/framework.dart';
import 'package:sky/widgets/mixed_viewport.dart';
import 'package:sky/widgets/scrollable.dart';

export 'package:sky/widgets/mixed_viewport.dart' show MixedViewportLayoutState;

// The GestureEvent velocity properties are pixels/second, config min,max limits are pixels/ms
const double _kMillisecondsPerSecond = 1000.0;
const double _kMinFlingVelocity = -config.kMaxFlingVelocity * _kMillisecondsPerSecond;
const double _kMaxFlingVelocity = config.kMaxFlingVelocity * _kMillisecondsPerSecond;

typedef void ScrollListener();

/// A base class for scrollable widgets that reacts to user input and generates
/// a scrollOffset.
abstract class Scrollable extends StatefulComponent {

  Scrollable({
    Key key,
    this.initialScrollOffset,
    this.scrollDirection: ScrollDirection.vertical
  }) : super(key: key) {
    assert(scrollDirection == ScrollDirection.vertical ||
           scrollDirection == ScrollDirection.horizontal);
  }

  double initialScrollOffset;
  ScrollDirection scrollDirection;

  AnimatedSimulation _toEndAnimation; // See _startToEndAnimation()
  ValueAnimation<double> _toOffsetAnimation; // Started by scrollTo()

  void initState() {
    if (initialScrollOffset is double)
      _scrollOffset = initialScrollOffset;
    _toEndAnimation = new AnimatedSimulation(_setScrollOffset);
    _toOffsetAnimation = new ValueAnimation<double>()
      ..addListener(() {
        AnimatedValue<double> offset = _toOffsetAnimation.variable;
        _setScrollOffset(offset.value);
      });
  }

  void syncConstructorArguments(Scrollable source) {
    scrollDirection = source.scrollDirection;
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

  Future _startToOffsetAnimation(double newScrollOffset, Duration duration, Curve curve) {
    _stopAnimations();
    _toOffsetAnimation
      ..variable = new AnimatedValue<double>(scrollOffset,
        end: newScrollOffset,
        curve: curve
      )
      ..progress = 0.0
      ..duration = duration;
    return _toOffsetAnimation.play();
  }

  void _stopAnimations() {
    if (_toOffsetAnimation.isAnimating)
      _toOffsetAnimation.stop();
    if (_toEndAnimation.isAnimating)
      _toEndAnimation.stop();
  }

  void _startToEndAnimation({ double velocity: 0.0 }) {
    _stopAnimations();
    Simulation simulation = scrollBehavior.release(scrollOffset, velocity);
    if (simulation != null)
      _toEndAnimation.start(simulation);
  }

  void didUnmount() {
    _stopAnimations();
    super.didUnmount();
  }

  void _setScrollOffset(double newScrollOffset) {
    if (_scrollOffset == newScrollOffset)
      return;
    setState(() {
      _scrollOffset = newScrollOffset;
    });
    if (_listeners.length > 0)
      _notifyListeners();
  }

  Future scrollTo(double newScrollOffset, { Duration duration, Curve curve: ease }) {
    if (newScrollOffset == _scrollOffset)
      return new Future.value();

    if (duration == null) {
      _stopAnimations();
      _setScrollOffset(newScrollOffset);
      return new Future.value();
    }

    return _startToOffsetAnimation(newScrollOffset, duration, curve);
  }

  Future scrollBy(double scrollDelta, { Duration duration, Curve curve }) {
    double newScrollOffset = scrollBehavior.applyCurve(_scrollOffset, scrollDelta);
    return scrollTo(newScrollOffset, duration: duration, curve: curve);
  }

  void settleScrollOffset() {
    _startToEndAnimation();
  }

  // Return the event's velocity in pixels/second.
  double _eventVelocity(sky.GestureEvent event) {
    double velocity = scrollDirection == ScrollDirection.horizontal
      ? -event.velocityX
      : -event.velocityY;
    return velocity.clamp(_kMinFlingVelocity, _kMaxFlingVelocity) / _kMillisecondsPerSecond;
  }

  EventDisposition _handlePointerDown(_) {
    _stopAnimations();
    return EventDisposition.processed;
  }

  EventDisposition _handleScrollUpdate(sky.GestureEvent event) {
    scrollBy(scrollDirection == ScrollDirection.horizontal ? event.dx : -event.dy);
    return EventDisposition.processed;
  }

  EventDisposition _handleFlingStart(sky.GestureEvent event) {
    _startToEndAnimation(velocity: _eventVelocity(event));
    return EventDisposition.processed;
  }

  void _maybeSettleScrollOffset() {
    if (!_toEndAnimation.isAnimating &&
        (_toOffsetAnimation == null || !_toOffsetAnimation.isAnimating))
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

  final List<ScrollListener> _listeners = new List<ScrollListener>();
  void addListener(ScrollListener listener) {
    _listeners.add(listener);
  }

  void removeListener(ScrollListener listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    List<ScrollListener> localListeners = new List<ScrollListener>.from(_listeners);
    for (ScrollListener listener in localListeners)
      listener();
  }
}

Scrollable findScrollableAncestor({ Widget target }) {
  Widget ancestor = target;
  while (ancestor != null && ancestor is! Scrollable)
    ancestor = ancestor.parent;
  return ancestor;
}

Future ensureWidgetIsVisible(Widget target, { Duration duration, Curve curve }) {
  assert(target.mounted);
  assert(target.renderObject is RenderBox);

  Scrollable scrollable = findScrollableAncestor(target: target);
  if (scrollable == null)
    return new Future.value();

  Size targetSize = (target.renderObject as RenderBox).size;
  Point targetCenter = target.localToGlobal(
    scrollable.scrollDirection == ScrollDirection.vertical
      ? new Point(0.0, targetSize.height / 2.0)
      : new Point(targetSize.width / 2.0, 0.0)
  );

  Size scrollableSize = (scrollable.renderObject as RenderBox).size;
  Point scrollableCenter = scrollable.localToGlobal(
    scrollable.scrollDirection == ScrollDirection.vertical
      ? new Point(0.0, scrollableSize.height / 2.0)
      : new Point(scrollableSize.width / 2.0, 0.0)
  );
  double scrollOffsetDelta = scrollable.scrollDirection == ScrollDirection.vertical
    ? targetCenter.y - scrollableCenter.y
    : targetCenter.x - scrollableCenter.x;
  ExtentScrollBehavior scrollBehavior = scrollable.scrollBehavior;
  double scrollOffset = (scrollable.scrollOffset + scrollOffsetDelta)
    .clamp(scrollBehavior.minScrollOffset, scrollBehavior.maxScrollOffset);

  if (scrollOffset != scrollable.scrollOffset)
    return scrollable.scrollTo(scrollOffset, duration: duration, curve: curve);

  return new Future.value();
}

/// A simple scrollable widget that has a single child. Use this component if
/// you are not worried about offscreen widgets consuming resources.
class ScrollableViewport extends Scrollable {
  ScrollableViewport({
    Key key,
    this.child,
    double initialScrollOffset,
    ScrollDirection scrollDirection: ScrollDirection.vertical
  }) : super(
    key: key,
    scrollDirection: scrollDirection,
    initialScrollOffset: initialScrollOffset
  );

  Widget child;

  void syncConstructorArguments(ScrollableViewport source) {
    child = source.child;
    super.syncConstructorArguments(source);
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
    scrollTo(scrollBehavior.updateExtents(
      contentExtent: _childSize,
      containerExtent: _viewportSize,
      scrollOffset: scrollOffset));
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

/// A mashup of [ScrollableViewport] and [BlockBody]. Useful when you have a small,
/// fixed number of children that you wish to arrange in a block layout and that
/// might exceed the height of its container (and therefore need to scroll).
class Block extends Component {
  Block(this.children, {
    Key key,
    this.initialScrollOffset,
    this.scrollDirection: ScrollDirection.vertical
  }) : super(key: key);

  final List<Widget> children;
  final double initialScrollOffset;
  final ScrollDirection scrollDirection;

  BlockDirection get _direction {
    if (scrollDirection == ScrollDirection.vertical)
      return BlockDirection.vertical;
    return BlockDirection.horizontal;
  }

  Widget build() {
    return new ScrollableViewport(
      initialScrollOffset: initialScrollOffset,
      scrollDirection: scrollDirection,
      child: new BlockBody(children, direction: _direction)
    );
  }
}

/// An optimized scrollable widget for a large number of children that are all
/// the same size (extent) in the scrollDirection. For example for
/// ScrollDirection.vertical itemExtent is the height of each item. Use this
/// widget when you have a large number of children or when you are concerned
// about offscreen widgets consuming resources.
abstract class ScrollableWidgetList extends Scrollable {
  ScrollableWidgetList({
    Key key,
    double initialScrollOffset,
    ScrollDirection scrollDirection: ScrollDirection.vertical,
    this.itemExtent,
    this.padding
  }) : super(key: key, initialScrollOffset: initialScrollOffset, scrollDirection: scrollDirection) {
    assert(itemExtent != null);
  }

  EdgeDims padding;
  double itemExtent;
  Size containerSize = Size.zero;

  /// Subclasses must implement `get itemCount` to tell ScrollableWidgetList
  /// how many items there are in the list.
  int get itemCount;
  int _previousItemCount;

  void syncConstructorArguments(ScrollableWidgetList source) {
    bool scrollBehaviorUpdateNeeded =
      padding != source.padding ||
      itemExtent != source.itemExtent ||
      scrollDirection != source.scrollDirection;

    padding = source.padding;
    itemExtent = source.itemExtent;
    super.syncConstructorArguments(source); // update scrollDirection

    if (itemCount != _previousItemCount) {
      scrollBehaviorUpdateNeeded = true;
      _previousItemCount = itemCount;
    }

    if (scrollBehaviorUpdateNeeded)
      _updateScrollBehavior();
  }

  ScrollBehavior createScrollBehavior() => new OverscrollBehavior();
  ExtentScrollBehavior get scrollBehavior => super.scrollBehavior;

  double get _containerExtent {
    return scrollDirection == ScrollDirection.vertical
      ? containerSize.height
      : containerSize.width;
  }

  void _handleSizeChanged(Size newSize) {
    setState(() {
      containerSize = newSize;
      _updateScrollBehavior();
    });
  }

  double get _leadingPadding {
    if (scrollDirection == ScrollDirection.vertical)
      return padding != null ? padding.top : 0.0;
    return padding != null ? padding.left : -.0;
  }

  double get _trailingPadding {
    if (scrollDirection == ScrollDirection.vertical)
      return padding != null ? padding.bottom : 0.0;
    return padding != null ? padding.right : 0.0;
  }

  EdgeDims get _crossAxisPadding {
    if (padding == null)
      return null;
    if (scrollDirection == ScrollDirection.vertical)
      return new EdgeDims.only(left: padding.left, right: padding.right);
    return new EdgeDims.only(top: padding.top, bottom: padding.bottom);
  }

  void _updateScrollBehavior() {
    double contentExtent = itemExtent * itemCount;
    if (padding != null)
      contentExtent += _leadingPadding + _trailingPadding;

    scrollTo(scrollBehavior.updateExtents(
      contentExtent: contentExtent,
      containerExtent: _containerExtent,
      scrollOffset: scrollOffset));
  }

  Offset _toOffset(double value) {
    return scrollDirection == ScrollDirection.vertical
      ? new Offset(0.0, value)
      : new Offset(value, 0.0);
  }

  Widget buildContent() {
    if (itemCount != _previousItemCount) {
      _previousItemCount = itemCount;
      _updateScrollBehavior();
    }

    double paddedScrollOffset = scrollOffset - _leadingPadding;
    int itemShowIndex = 0;
    int itemShowCount = 0;
    Offset viewportOffset = Offset.zero;

    if (_containerExtent != null && _containerExtent > 0.0 && itemCount > 0) {
      if (paddedScrollOffset < scrollBehavior.minScrollOffset) {
        // Underscroll
        double visibleExtent = _containerExtent + paddedScrollOffset;
        itemShowCount = (visibleExtent / itemExtent).ceil();
        viewportOffset = _toOffset(paddedScrollOffset);
      } else {
        itemShowCount = (_containerExtent / itemExtent).ceil() + 1;
        itemShowIndex = (paddedScrollOffset / itemExtent).floor();
        viewportOffset = _toOffset(paddedScrollOffset - itemShowIndex * itemExtent);
        itemShowIndex %= itemCount; // Wrap index for when itemWrap is true.
      }
    }

    List<Widget> items = buildItems(itemShowIndex, itemShowCount);
    assert(items.every((item) => item.key != null));

    BlockDirection blockDirection = scrollDirection == ScrollDirection.vertical
      ? BlockDirection.vertical
      : BlockDirection.horizontal;

    // TODO(ianh): Refactor this so that it does the building in the
    // same frame as the size observing, similar to MixedViewport, but
    // keeping the fixed-height optimisations.
    return new SizeObserver(
      callback: _handleSizeChanged,
      child: new Viewport(
        scrollDirection: scrollDirection,
        scrollOffset: viewportOffset,
        child: new Container(
          padding: _crossAxisPadding,
          child: new BlockBody(items, direction: blockDirection)
        )
      )
    );
  }

  List<Widget> buildItems(int start, int count);

}

typedef Widget ItemBuilder<T>(T item);

/// A wrapper around [ScrollableWidgetList] that helps you translate a list of
/// model objects into a scrollable list of widgets. Assumes all the widgets
/// have the same height.
class ScrollableList<T> extends ScrollableWidgetList {
  ScrollableList({
    Key key,
    double initialScrollOffset,
    ScrollDirection scrollDirection: ScrollDirection.vertical,
    this.items,
    this.itemBuilder,
    this.itemsWrap: false,
    double itemExtent,
    EdgeDims padding
  }) : super(
    key: key,
    initialScrollOffset: initialScrollOffset,
    scrollDirection: scrollDirection,
    itemExtent: itemExtent,
    padding: padding);

  List<T> items;
  ItemBuilder<T> itemBuilder;
  bool itemsWrap;

  void syncConstructorArguments(ScrollableList<T> source) {
    items = source.items;
    itemBuilder = source.itemBuilder;
    itemsWrap = source.itemsWrap;
    super.syncConstructorArguments(source);
  }

  ScrollBehavior createScrollBehavior() {
    return itemsWrap ? new UnboundedBehavior() : super.createScrollBehavior();
  }

  int get itemCount => items.length;

  List<Widget> buildItems(int start, int count) {
    List<Widget> result = new List<Widget>();
    int begin = itemsWrap ? start : math.max(0, start);
    int end = itemsWrap ? begin + count : math.min(begin + count, items.length);
    for (int i = begin; i < end; ++i)
      result.add(itemBuilder(items[i % itemCount]));
    return result;
  }
}

typedef void PageChangedCallback(int newPage);

class PageableList<T> extends ScrollableList<T> {
  PageableList({
    Key key,
    double initialScrollOffset,
    ScrollDirection scrollDirection: ScrollDirection.horizontal,
    List<T> items,
    ItemBuilder<T> itemBuilder,
    bool itemsWrap: false,
    double itemExtent,
    PageChangedCallback this.pageChanged,
    EdgeDims padding,
    this.duration: const Duration(milliseconds: 200),
    this.curve: ease
  }) : super(
    key: key,
    initialScrollOffset: initialScrollOffset,
    scrollDirection: scrollDirection,
    items: items,
    itemBuilder: itemBuilder,
    itemsWrap: itemsWrap,
    itemExtent: itemExtent,
    padding: padding
  );

  Duration duration;
  Curve curve;
  PageChangedCallback pageChanged;

  void syncConstructorArguments(PageableList<T> source) {
    duration = source.duration;
    curve = source.curve;
    pageChanged = source.pageChanged;
    super.syncConstructorArguments(source);
  }

  double _snapScrollOffset(double newScrollOffset) {
    double scaledScrollOffset = newScrollOffset / itemExtent;
    double previousScrollOffset = scaledScrollOffset.floor() * itemExtent;
    double nextScrollOffset = scaledScrollOffset.ceil() * itemExtent;
    double delta = newScrollOffset - previousScrollOffset;
    return (delta < itemExtent / 2.0 ? previousScrollOffset : nextScrollOffset)
      .clamp(scrollBehavior.minScrollOffset, scrollBehavior.maxScrollOffset);
  }

  EventDisposition _handlePointerDown(_) {
    return EventDisposition.ignored;
  }

  EventDisposition _handleFlingStart(sky.GestureEvent event) {
    double velocity = _eventVelocity(event);
    double newScrollOffset = _snapScrollOffset(scrollOffset + velocity.sign * itemExtent)
      .clamp(_snapScrollOffset(scrollOffset - itemExtent / 2.0),
             _snapScrollOffset(scrollOffset + itemExtent / 2.0));
    scrollTo(newScrollOffset, duration: duration, curve: curve).then(_notifyPageChanged);
    return EventDisposition.processed;
  }

  int get currentPage => (scrollOffset / itemExtent).floor();

  void _notifyPageChanged(_) {
    if (pageChanged != null)
      pageChanged(currentPage);
  }

  void settleScrollOffset() {
    scrollTo(_snapScrollOffset(scrollOffset), duration: duration, curve: curve).then(_notifyPageChanged);
  }
}

/// A general scrollable list for a large number of children that might not all
/// have the same height. Prefer [ScrollableWidgetList] when all the children
/// have the same height because it can use that property to be more efficient.
/// Prefer [ScrollableViewport] with a single child.
class ScrollableMixedWidgetList extends Scrollable {
  ScrollableMixedWidgetList({
    Key key,
    double initialScrollOffset,
    this.builder,
    this.token,
    this.layoutState
  }) : super(key: key, initialScrollOffset: initialScrollOffset);

  IndexedBuilder builder;
  Object token;
  MixedViewportLayoutState layoutState;

  // When the token changes the scrollable's contents may have
  // changed. Remember as much so that after the new contents
  // have been laid out we can adjust the scrollOffset so that
  // the last page of content is still visible.
  bool _contentChanged = true;

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

  void syncConstructorArguments(ScrollableMixedWidgetList source) {
    builder = source.builder;
    if (token != source.token)
      _contentChanged = true;
    token = source.token;
    if (layoutState != source.layoutState) {
      // Warning: this is unlikely to be what you intended.
      assert(source.layoutState != null);
      layoutState.removeListener(_handleLayoutChanged);
      layoutState = source.layoutState;
      layoutState.addListener(_handleLayoutChanged);
    }
    super.syncConstructorArguments(source);
  }

  ScrollBehavior createScrollBehavior() => new OverscrollBehavior();
  OverscrollBehavior get scrollBehavior => super.scrollBehavior;

  void _handleSizeChanged(Size newSize) {
    scrollBy(scrollBehavior.updateExtents(
      containerExtent: newSize.height,
      scrollOffset: scrollOffset
    ));
  }

  void _handleLayoutChanged() {
    double newScrollOffset = scrollBehavior.updateExtents(
      contentExtent: layoutState.didReachLastChild ? layoutState.contentsSize : double.INFINITY,
      scrollOffset: scrollOffset);
    if (_contentChanged) {
      _contentChanged = false;
      scrollTo(newScrollOffset);
    }
  }

  Widget buildContent() {
    return new SizeObserver(
      callback: _handleSizeChanged,
      child: new MixedViewport(
        builder: builder,
        layoutState: layoutState,
        startOffset: scrollOffset,
        token: token
      )
    );
  }
}
