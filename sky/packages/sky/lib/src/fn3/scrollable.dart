// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:sky' as sky;

import 'package:newton/newton.dart';
import 'package:sky/animation.dart';
import 'package:sky/gestures.dart';
import 'package:sky/src/rendering/box.dart';
import 'package:sky/src/rendering/viewport.dart';
import 'package:sky/src/fn3/basic.dart';
import 'package:sky/src/fn3/framework.dart';
import 'package:sky/src/fn3/gesture_detector.dart';
import 'package:sky/src/fn3/homogeneous_viewport.dart';

// The gesture velocity properties are pixels/second, config min,max limits are pixels/ms
const double _kMillisecondsPerSecond = 1000.0;
const double _kMinFlingVelocity = -kMaxFlingVelocity * _kMillisecondsPerSecond;
const double _kMaxFlingVelocity = kMaxFlingVelocity * _kMillisecondsPerSecond;

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

  final double initialScrollOffset;
  final ScrollDirection scrollDirection;
}

abstract class ScrollableState<T extends Scrollable> extends ComponentState<T> {
  ScrollableState(T config) : super(config) {
    if (config.initialScrollOffset is double)
      _scrollOffset = config.initialScrollOffset;
    _toEndAnimation = new AnimatedSimulation(_setScrollOffset);
    _toOffsetAnimation = new ValueAnimation<double>()
      ..addListener(() {
        AnimatedValue<double> offset = _toOffsetAnimation.variable;
        _setScrollOffset(offset.value);
      });
  }

  AnimatedSimulation _toEndAnimation; // See _startToEndAnimation()
  ValueAnimation<double> _toOffsetAnimation; // Started by scrollTo()

  double _scrollOffset = 0.0;
  double get scrollOffset => _scrollOffset;

  Offset get scrollOffsetVector {
    if (config.scrollDirection == ScrollDirection.horizontal)
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

  GestureDragUpdateCallback _getDragUpdateHandler(ScrollDirection direction) {
    if (config.scrollDirection != direction || !scrollBehavior.isScrollable)
      return null;
    return _handleDragUpdate;
  }

  GestureDragEndCallback _getDragEndHandler(ScrollDirection direction) {
    if (config.scrollDirection != direction || !scrollBehavior.isScrollable)
      return null;
    return _handleDragEnd;
  }

  Widget build(BuildContext context) {
    return new GestureDetector(
      onVerticalDragUpdate: _getDragUpdateHandler(ScrollDirection.vertical),
      onVerticalDragEnd: _getDragEndHandler(ScrollDirection.vertical),
      onHorizontalDragUpdate: _getDragUpdateHandler(ScrollDirection.horizontal),
      onHorizontalDragEnd: _getDragEndHandler(ScrollDirection.horizontal),
      child: new Listener(
        child: buildContent(context),
        onPointerDown: _handlePointerDown
      )
    );
  }

  Widget buildContent(BuildContext context);

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

  void dispose() {
    _stopAnimations();
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

  double _scrollVelocity(sky.Offset velocity) {
    double scrollVelocity = config.scrollDirection == ScrollDirection.horizontal
      ? -velocity.dx
      : -velocity.dy;
    return scrollVelocity.clamp(_kMinFlingVelocity, _kMaxFlingVelocity) / _kMillisecondsPerSecond;
  }

  void _handlePointerDown(_) {
    _stopAnimations();
  }

  void _handleDragUpdate(double delta) {
    // We negate the delta here because a positive scroll offset moves the
    // the content up (or to the left) rather than down (or the right).
    scrollBy(-delta);
  }

  void _handleDragEnd(Offset velocity) {
    if (velocity != Offset.zero) {
      _startToEndAnimation(velocity: _scrollVelocity(velocity));
    } else if (!_toEndAnimation.isAnimating && (_toOffsetAnimation == null || !_toOffsetAnimation.isAnimating)) {
      settleScrollOffset();
    }
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

// TODO(abarth): findScrollableAncestor
// TODO(abarth): ensureWidgetIsVisible

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

  final Widget child;

  ScrollableViewportState createState() => new ScrollableViewportState(this);
}

class ScrollableViewportState extends ScrollableState<ScrollableViewport> {
  ScrollableViewportState(ScrollableViewport config) : super(config);

  ScrollBehavior createScrollBehavior() => new OverscrollWhenScrollableBehavior();
  OverscrollWhenScrollableBehavior get scrollBehavior => super.scrollBehavior;

  double _viewportSize = 0.0;
  double _childSize = 0.0;
  void _handleViewportSizeChanged(Size newSize) {
    _viewportSize = config.scrollDirection == ScrollDirection.vertical ? newSize.height : newSize.width;
    setState(() {
      _updateScrollBehaviour();
    });
  }
  void _handleChildSizeChanged(Size newSize) {
    _childSize = config.scrollDirection == ScrollDirection.vertical ? newSize.height : newSize.width;
    setState(() {
      _updateScrollBehaviour();
    });
  }
  void _updateScrollBehaviour() {
    // if you don't call this from build() or syncConstructorArguments(), you must call it from setState().
    scrollTo(scrollBehavior.updateExtents(
      contentExtent: _childSize,
      containerExtent: _viewportSize,
      scrollOffset: scrollOffset
    ));
  }

  Widget buildContent(BuildContext context) {
    return new SizeObserver(
      callback: _handleViewportSizeChanged,
      child: new Viewport(
        scrollOffset: scrollOffsetVector,
        scrollDirection: config.scrollDirection,
        child: new SizeObserver(
          callback: _handleChildSizeChanged,
          child: config.child
        )
      )
    );
  }
}

/// A mashup of [ScrollableViewport] and [BlockBody]. Useful when you have a small,
/// fixed number of children that you wish to arrange in a block layout and that
/// might exceed the height of its container (and therefore need to scroll).
class Block extends StatelessComponent {
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

  Widget build(BuildContext context) {
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
    this.itemsWrap: false,
    this.itemExtent,
    this.padding
  }) : super(key: key, initialScrollOffset: initialScrollOffset, scrollDirection: scrollDirection) {
    assert(itemExtent != null);
  }

  EdgeDims padding;
  bool itemsWrap;
  double itemExtent;
  Size containerSize = Size.zero;
}

abstract class ScrollableWidgetListState<T extends ScrollableWidgetList> extends ScrollableState<T> {
  ScrollableWidgetListState(T config) : super(config);

  /// Subclasses must implement `get itemCount` to tell ScrollableWidgetList
  /// how many items there are in the list.
  int get itemCount;
  int _previousItemCount;

  void didUpdateConfig(T oldConfig) {
    super.didUpdateConfig(oldConfig);

    bool scrollBehaviorUpdateNeeded =
      config.padding != oldConfig.padding ||
      config.itemExtent != oldConfig.itemExtent ||
      config.scrollDirection != oldConfig.scrollDirection;

    if (config.itemsWrap != oldConfig.itemsWrap) {
      _scrollBehavior = null;
      scrollBehaviorUpdateNeeded = true;
    }

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
    return config.scrollDirection == ScrollDirection.vertical
      ? config.containerSize.height
      : config.containerSize.width;
  }

  void _handleSizeChanged(Size newSize) {
    setState(() {
      config.containerSize = newSize;
      _updateScrollBehavior();
    });
  }

  double get _leadingPadding {
    EdgeDims padding = config.padding;
    if (config.scrollDirection == ScrollDirection.vertical)
      return padding != null ? padding.top : 0.0;
    return padding != null ? padding.left : -.0;
  }

  double get _trailingPadding {
    EdgeDims padding = config.padding;
    if (config.scrollDirection == ScrollDirection.vertical)
      return padding != null ? padding.bottom : 0.0;
    return padding != null ? padding.right : 0.0;
  }

  EdgeDims get _crossAxisPadding {
    EdgeDims padding = config.padding;
    if (padding == null)
      return null;
    if (config.scrollDirection == ScrollDirection.vertical)
      return new EdgeDims.only(left: padding.left, right: padding.right);
    return new EdgeDims.only(top: padding.top, bottom: padding.bottom);
  }

  void _updateScrollBehavior() {
    // if you don't call this from build() or syncConstructorArguments(), you must call it from setState().
    double contentExtent = config.itemExtent * itemCount;
    if (config.padding != null)
      contentExtent += _leadingPadding + _trailingPadding;
    scrollTo(scrollBehavior.updateExtents(
      contentExtent: contentExtent,
      containerExtent: _containerExtent,
      scrollOffset: scrollOffset
    ));
  }

  Widget buildContent(BuildContext context) {
    if (itemCount != _previousItemCount) {
      _previousItemCount = itemCount;
      _updateScrollBehavior();
    }

    return new SizeObserver(
      callback: _handleSizeChanged,
      child: new Container(
        padding: _crossAxisPadding,
        child: new HomogeneousViewport(
          builder: _buildItems,
          itemsWrap: config.itemsWrap,
          itemExtent: config.itemExtent,
          itemCount: itemCount,
          direction: config.scrollDirection,
          startOffset: scrollOffset - _leadingPadding
        )
      )
    );
  }

  List<Widget> _buildItems(BuildContext context, int start, int count) {
    List<Widget> result = buildItems(context, start, count);
    assert(result.every((item) => item.key != null));
    return result;
  }

  List<Widget> buildItems(BuildContext context, int start, int count);

}

typedef Widget ItemBuilder<T>(BuildContext context, T item);

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
    itemsWrap: false,
    double itemExtent,
    EdgeDims padding
  }) : super(
    key: key,
    initialScrollOffset: initialScrollOffset,
    scrollDirection: scrollDirection,
    itemsWrap: itemsWrap,
    itemExtent: itemExtent,
    padding: padding);

  final List<T> items;
  final ItemBuilder<T> itemBuilder;

  ScrollableListState<T, ScrollableList<T>> createState() => new ScrollableListState<T, ScrollableList<T>>(this);
}

class ScrollableListState<T, Config extends ScrollableList<T>> extends ScrollableWidgetListState<Config> {
  ScrollableListState(Config config) : super(config);

  ScrollBehavior createScrollBehavior() {
    return config.itemsWrap ? new UnboundedBehavior() : super.createScrollBehavior();
  }

  int get itemCount => config.items.length;

  List<Widget> buildItems(BuildContext context, int start, int count) {
    List<Widget> result = new List<Widget>();
    int begin = config.itemsWrap ? start : math.max(0, start);
    int end = config.itemsWrap ? begin + count : math.min(begin + count, config.items.length);
    for (int i = begin; i < end; ++i)
      result.add(config.itemBuilder(context, config.items[i % itemCount]));
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
}

class PageableListState<T> extends ScrollableListState<T, PageableList<T>> {
  PageableListState(PageableList<T> config) : super(config);

  double _snapScrollOffset(double newScrollOffset) {
    double scaledScrollOffset = newScrollOffset / config.itemExtent;
    double previousScrollOffset = scaledScrollOffset.floor() * config.itemExtent;
    double nextScrollOffset = scaledScrollOffset.ceil() * config.itemExtent;
    double delta = newScrollOffset - previousScrollOffset;
    return (delta < config.itemExtent / 2.0 ? previousScrollOffset : nextScrollOffset)
      .clamp(scrollBehavior.minScrollOffset, scrollBehavior.maxScrollOffset);
  }

  void _handleDragEnd(sky.Offset velocity) {
    double scrollVelocity = _scrollVelocity(velocity);
    double newScrollOffset = _snapScrollOffset(scrollOffset + scrollVelocity.sign * config.itemExtent)
      .clamp(_snapScrollOffset(scrollOffset - config.itemExtent / 2.0),
             _snapScrollOffset(scrollOffset + config.itemExtent / 2.0));
    scrollTo(newScrollOffset, duration: config.duration, curve: config.curve).then(_notifyPageChanged);
  }

  int get currentPage => (scrollOffset / config.itemExtent).floor() % itemCount;

  void _notifyPageChanged(_) {
    if (config.pageChanged != null)
      config.pageChanged(currentPage);
  }

  void settleScrollOffset() {
    scrollTo(_snapScrollOffset(scrollOffset), duration: config.duration, curve: config.curve).then(_notifyPageChanged);
  }
}

// TODO(abarth): ScrollableMixedWidgetList
