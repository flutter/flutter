// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui show window;

import 'package:flutter/physics.dart';
import 'package:flutter/gestures.dart';
import 'package:meta/meta.dart';

import 'basic.dart';
import 'clamp_overscrolls.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'notification_listener.dart';
import 'page_storage.dart';
import 'scroll_behavior.dart';

/// The accuracy to which scrolling is computed.
final Tolerance kPixelScrollTolerance = new Tolerance(
  // TODO(ianh): Handle the case of the device pixel ratio changing.
  velocity: 1.0 / (0.050 * ui.window.devicePixelRatio), // logical pixels per second
  distance: 1.0 / ui.window.devicePixelRatio // logical pixels
);

typedef void ScrollListener(double scrollOffset);
typedef double SnapOffsetCallback(double scrollOffset, Size containerSize);

/// A base class for scrollable widgets.
///
/// Commonly used subclasses include [ScrollableList], [ScrollableGrid], and
/// [ScrollableViewport].
///
/// Widgets that subclass [Scrollable] typically use state objects that subclass
/// [ScrollableState].
abstract class Scrollable extends StatefulWidget {
  Scrollable({
    Key key,
    this.initialScrollOffset,
    this.scrollDirection: Axis.vertical,
    this.scrollAnchor: ViewportAnchor.start,
    this.onScrollStart,
    this.onScroll,
    this.onScrollEnd,
    this.snapOffsetCallback
  }) : super(key: key) {
    assert(scrollDirection == Axis.vertical || scrollDirection == Axis.horizontal);
    assert(scrollAnchor == ViewportAnchor.start || scrollAnchor == ViewportAnchor.end);
  }

  /// The scroll offset this widget should use when first created.
  final double initialScrollOffset;

  /// The axis along which this widget should scroll.
  final Axis scrollDirection;

  /// Whether to place first child at the start of the container or
  /// the last child at the end of the container, when the scrollable
  /// has not been scrolled and has no initial scroll offset.
  ///
  /// For example, if the [scrollDirection] is [Axis.vertical] and
  /// there are enough items to overflow the container, then
  /// [ViewportAnchor.start] means that the top of the first item
  /// should be aligned with the top of the scrollable with the last
  /// item below the bottom, and [ViewportAnchor.end] means the bottom
  /// of the last item should be aligned with the bottom of the
  /// scrollable, with the first item above the top.
  ///
  /// This also affects whether, when an item is added or removed, the
  /// displacement will be towards the first item or the last item.
  /// Continuing the earlier example, if a new item is inserted in the
  /// middle of the list, in the [ViewportAnchor.start] case the items
  /// after it (with greater indices, down to the item with the
  /// highest index) will be pushed down, while in the
  /// [ViewportAnchor.end] case the items before it (with lower
  /// indices, up to the item with the index 0) will be pushed up.
  ///
  /// Subclasses may ignore this value if, for instance, they do not
  /// have a concept of an anchor, or have more complicated behavior
  /// (e.g. they would by default put the middle item in the middle of
  /// the container).
  final ViewportAnchor scrollAnchor;

  /// Called whenever this widget starts to scroll.
  final ScrollListener onScrollStart;

  /// Called whenever this widget's scroll offset changes.
  final ScrollListener onScroll;

  /// Called whenever this widget stops scrolling.
  final ScrollListener onScrollEnd;

  /// Called to determine the offset to which scrolling should snap,
  /// when handling a fling.
  ///
  /// This callback, if set, will be called with the offset that the
  /// Scrollable would have scrolled to in the absence of this
  /// callback, and a Size describing the size of the Scrollable
  /// itself.
  ///
  /// The callback's return value is used as the new scroll offset to
  /// aim for.
  ///
  /// If the callback simply returns its first argument (the offset),
  /// then it is as if the callback was null.
  final SnapOffsetCallback snapOffsetCallback;

  /// The state from the closest instance of this class that encloses the given context.
  static ScrollableState of(BuildContext context) {
    return context.ancestorStateOfType(const TypeMatcher<ScrollableState>());
  }

  /// Scrolls the closest enclosing scrollable to make the given context visible.
  static Future<Null> ensureVisible(BuildContext context, { Duration duration, Curve curve: Curves.ease }) {
    assert(context.findRenderObject() is RenderBox);
    // TODO(abarth): This function doesn't handle nested scrollable widgets.

    ScrollableState scrollable = Scrollable.of(context);
    if (scrollable == null)
      return new Future<Null>.value();

    RenderBox targetBox = context.findRenderObject();
    assert(targetBox.attached);
    Size targetSize = targetBox.size;

    RenderBox scrollableBox = scrollable.context.findRenderObject();
    assert(scrollableBox.attached);
    Size scrollableSize = scrollableBox.size;

    double targetMin;
    double targetMax;
    double scrollableMin;
    double scrollableMax;

    switch (scrollable.config.scrollDirection) {
      case Axis.vertical:
        targetMin = targetBox.localToGlobal(Point.origin).y;
        targetMax = targetBox.localToGlobal(new Point(0.0, targetSize.height)).y;
        scrollableMin = scrollableBox.localToGlobal(Point.origin).y;
        scrollableMax = scrollableBox.localToGlobal(new Point(0.0, scrollableSize.height)).y;
        break;
      case Axis.horizontal:
        targetMin = targetBox.localToGlobal(Point.origin).x;
        targetMax = targetBox.localToGlobal(new Point(targetSize.width, 0.0)).x;
        scrollableMin = scrollableBox.localToGlobal(Point.origin).x;
        scrollableMax = scrollableBox.localToGlobal(new Point(scrollableSize.width, 0.0)).x;
        break;
    }

    double scrollOffsetDelta;
    if (targetMin < scrollableMin) {
      if (targetMax > scrollableMax) {
        // The target is to big to fit inside the scrollable. The best we can do
        // is to center the target.
        double targetCenter = (targetMin + targetMax) / 2.0;
        double scrollableCenter = (scrollableMin + scrollableMax) / 2.0;
        scrollOffsetDelta = targetCenter - scrollableCenter;
      } else {
        scrollOffsetDelta = targetMin - scrollableMin;
      }
    } else if (targetMax > scrollableMax) {
      scrollOffsetDelta = targetMax - scrollableMax;
    } else {
      return new Future<Null>.value();
    }

    ExtentScrollBehavior scrollBehavior = scrollable.scrollBehavior;
    double scrollOffset = (scrollable.scrollOffset + scrollOffsetDelta)
      .clamp(scrollBehavior.minScrollOffset, scrollBehavior.maxScrollOffset);

    if (scrollOffset != scrollable.scrollOffset)
      return scrollable.scrollTo(scrollOffset, duration: duration, curve: curve);

    return new Future<Null>.value();
  }

  @override
  ScrollableState createState();
}

/// Contains the state for common scrolling widgets that scroll only
/// along one axis.
///
/// Widgets that subclass [Scrollable] typically use state objects
/// that subclass [ScrollableState].
///
/// The main state of a ScrollableState is the "scroll offset", which
/// is the the logical description of the current scroll position and
/// is stored in [scrollOffset] as a double. The units of the scroll
/// offset are defined by the specific subclass. By default, the units
/// are logical pixels.
///
/// A "pixel offset" is a distance in logical pixels (or a velocity in
/// logical pixels per second). The pixel offset corresponding to the
/// current scroll position is typically used as the paint offset
/// argument to the underlying [Viewport] class (or equivalent); see
/// the [buildContent] method.
///
/// A "pixel delta" is an [Offset] that describes a two-dimensional
/// distance as reported by input events. If the scrolling convention
/// is axis-aligned (as in a vertical scrolling list or a horizontal
/// scrolling list), then the pixel delta will consist of a pixel
/// offset in the scroll axis, and a value in the other axis that is
/// either ignored (when converting to a scroll offset) or set to zero
/// (when converting a scroll offset to a pixel delta).
///
/// If the units of the scroll offset are not logical pixels, then a
/// mapping must be made from logical pixels (as used by incoming
/// input events) and the scroll offset (as stored internally). To
/// provide this mapping, override the [pixelOffsetToScrollOffset] and
/// [scrollOffsetToPixelOffset] methods.
///
/// If the scrollable is not providing axis-aligned scrolling, then,
/// to convert pixel deltas to scroll offsets and vice versa, override
/// the [pixelDeltaToScrollOffset] and [scrollOffsetToPixelOffset]
/// methods. By default, these assume an axis-aligned scroll behavior
/// along the [config.scrollDirection] axis and are implemented in
/// terms of the [pixelOffsetToScrollOffset] and
/// [scrollOffsetToPixelOffset] methods.
@optionalTypeArgs
abstract class ScrollableState<T extends Scrollable> extends State<T> {
  @override
  void initState() {
    super.initState();
    _controller = new AnimationController.unbounded()
      ..addListener(_handleAnimationChanged);
    _scrollOffset = PageStorage.of(context)?.readState(context) ?? config.initialScrollOffset ?? 0.0;
  }

  Simulation _simulation; // if we're flinging, then this is the animation with which we're doing it
  AnimationController _controller;

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  /// The current scroll offset.
  ///
  /// The scroll offset is applied to the child widget along the scroll
  /// direction before painting. A positive scroll offset indicates that
  /// more content in the preferred reading direction is visible.
  double get scrollOffset => _scrollOffset;
  double _scrollOffset;

  /// Convert a position or velocity measured in terms of pixels to a scrollOffset.
  /// Scrollable gesture handlers convert their incoming values with this method.
  /// Subclasses that define scrollOffset in units other than pixels must
  /// override this method.
  ///
  /// This function should be the inverse of [scrollOffsetToPixelOffset].
  double pixelOffsetToScrollOffset(double pixelOffset) {
    switch (config.scrollAnchor) {
      case ViewportAnchor.start:
        // We negate the delta here because a positive scroll offset moves the
        // the content up (or to the left) rather than down (or the right).
        return -pixelOffset;
      case ViewportAnchor.end:
        return pixelOffset;
    }
  }

  /// Convert a scrollOffset value to the number of pixels to which it corresponds.
  ///
  /// This function should be the inverse of [pixelOffsetToScrollOffset].
  double scrollOffsetToPixelOffset(double scrollOffset) {
    switch (config.scrollAnchor) {
      case ViewportAnchor.start:
        return -scrollOffset;
      case ViewportAnchor.end:
        return scrollOffset;
    }
  }

  /// Returns the scroll offset component of the given pixel delta, accounting
  /// for the scroll direction and scroll anchor.
  ///
  /// A pixel delta is an [Offset] in pixels. Typically this function
  /// is implemented in terms of [pixelOffsetToScrollOffset].
  double pixelDeltaToScrollOffset(Offset pixelDelta) {
    switch (config.scrollDirection) {
      case Axis.horizontal:
        return pixelOffsetToScrollOffset(pixelDelta.dx);
      case Axis.vertical:
        return pixelOffsetToScrollOffset(pixelDelta.dy);
    }
  }

  /// Returns a two-dimensional representation of the scroll offset, accounting
  /// for the scroll direction and scroll anchor.
  ///
  /// See the definition of [ScrollableState] for more details.
  Offset scrollOffsetToPixelDelta(double scrollOffset) {
    switch (config.scrollDirection) {
      case Axis.horizontal:
        return new Offset(scrollOffsetToPixelOffset(scrollOffset), 0.0);
      case Axis.vertical:
        return new Offset(0.0, scrollOffsetToPixelOffset(scrollOffset));
    }
  }

  /// The current scroll behavior of this widget.
  ///
  /// Scroll behaviors control where the boundaries of the scrollable are placed
  /// and how the scrolling physics should behave near those boundaries and
  /// after the user stops directly manipulating the scrollable.
  ScrollBehavior<double, double> get scrollBehavior {
    return _scrollBehavior ??= createScrollBehavior();
  }
  ScrollBehavior<double, double> _scrollBehavior;

  /// Subclasses should override this function to create the [ScrollBehavior]
  /// they desire.
  ScrollBehavior<double, double> createScrollBehavior();

  bool _scrollOffsetIsInBounds(double scrollOffset) {
    if (scrollBehavior is! ExtentScrollBehavior)
      return false;
    ExtentScrollBehavior behavior = scrollBehavior;
    return scrollOffset >= behavior.minScrollOffset && scrollOffset < behavior.maxScrollOffset;
  }

  void _handleAnimationChanged() {
    _setScrollOffset(_controller.value);
  }

  void _setScrollOffset(double newScrollOffset) {
    if (_scrollOffset == newScrollOffset)
      return;
    setState(() {
      _scrollOffset = newScrollOffset;
    });
    PageStorage.of(context)?.writeState(context, _scrollOffset);
    _startScroll();
    dispatchOnScroll();
    _endScroll();
  }

  /// Scroll this widget by the given scroll delta.
  ///
  /// If a non-null [duration] is provided, the widget will animate to the new
  /// scroll offset over the given duration with the given curve.
  Future<Null> scrollBy(double scrollDelta, { Duration duration, Curve curve: Curves.ease }) {
    double newScrollOffset = scrollBehavior.applyCurve(_scrollOffset, scrollDelta);
    return scrollTo(newScrollOffset, duration: duration, curve: curve);
  }

  /// Scroll this widget to the given scroll offset.
  ///
  /// If a non-null [duration] is provided, the widget will animate to the new
  /// scroll offset over the given duration with the given curve.
  ///
  /// This function does not accept a zero duration. To jump-scroll to
  /// the new offset, do not provide a duration, rather than providing
  /// a zero duration.
  Future<Null> scrollTo(double newScrollOffset, { Duration duration, Curve curve: Curves.ease }) {
    if (newScrollOffset == _scrollOffset)
      return new Future<Null>.value();

    if (duration == null) {
      _stop();
      _setScrollOffset(newScrollOffset);
      return new Future<Null>.value();
    }

    assert(duration > Duration.ZERO);
    return _animateTo(newScrollOffset, duration, curve);
  }

  Future<Null> _animateTo(double newScrollOffset, Duration duration, Curve curve) {
    _stop();
    _controller.value = scrollOffset;
    _startScroll();
    return _controller.animateTo(newScrollOffset, duration: duration, curve: curve).then(_endScroll);
  }

  /// Update any in-progress scrolling physics to account for new scroll behavior.
  ///
  /// The scrolling physics depends on the scroll behavior. When changing the
  /// scrolling behavior, call this function to update any in-progress scrolling
  /// physics to account for the new scroll behavior. This function preserves
  /// the current velocity when updating the physics.
  ///
  /// If there are no in-progress scrolling physics, this function scrolls to
  /// the given offset instead.
  void didUpdateScrollBehavior(double newScrollOffset) {
    assert(_controller.isAnimating || _simulation == null);
    if (_numberOfInProgressScrolls > 0) {
      if (_simulation != null) {
        double dx = _simulation.dx(_controller.lastElapsedDuration.inMicroseconds / Duration.MICROSECONDS_PER_SECOND);
        // TODO(abarth): We should be consistent about the units we use for velocity (i.e., per second).
        _startToEndAnimation(dx / Duration.MILLISECONDS_PER_SECOND);
      }
      return;
    }
    scrollTo(newScrollOffset);
  }

  /// Fling the scroll offset with the given velocity.
  ///
  /// Calling this function starts a physics-based animation of the scroll
  /// offset with the given value as the initial velocity. The physics
  /// simulation used is determined by the scroll behavior.
  Future<Null> fling(double scrollVelocity) {
    if (scrollVelocity != 0.0 || !_controller.isAnimating)
      return _startToEndAnimation(scrollVelocity);
    return new Future<Null>.value();
  }

  /// Animate the scroll offset to a value with a local minima of energy.
  ///
  /// Calling this function starts a physics-based animation of the scroll
  /// offset either to a snap point or to within the scrolling bounds. The
  /// physics simulation used is determined by the scroll behavior.
  Future<Null> settleScrollOffset() {
    return _startToEndAnimation(0.0);
  }

  Future<Null> _startToEndAnimation(double scrollVelocity) {
    _stop();
    _simulation = _createSnapSimulation(scrollVelocity) ?? _createFlingSimulation(scrollVelocity);
    if (_simulation == null)
      return new Future<Null>.value();
    _startScroll();
    return _controller.animateWith(_simulation).then(_endScroll);
  }

  /// Whether this scrollable should attempt to snap scroll offsets.
  bool get shouldSnapScrollOffset => config.snapOffsetCallback != null;

  /// Returns the snapped offset closest to the given scroll offset.
  double snapScrollOffset(double scrollOffset) {
    RenderBox box = context.findRenderObject();
    return config.snapOffsetCallback == null ? scrollOffset : config.snapOffsetCallback(scrollOffset, box.size);
  }

  Simulation _createSnapSimulation(double scrollVelocity) {
    if (!shouldSnapScrollOffset || scrollVelocity == 0.0 || !_scrollOffsetIsInBounds(scrollOffset))
      return null;

    Simulation simulation = _createFlingSimulation(scrollVelocity);
    if (simulation == null)
        return null;

    final double endScrollOffset = simulation.x(double.INFINITY);
    if (endScrollOffset.isNaN)
      return null;

    final double snappedScrollOffset = snapScrollOffset(endScrollOffset); // invokes the config.snapOffsetCallback callback
    if (!_scrollOffsetIsInBounds(snappedScrollOffset))
      return null;

    final double snapVelocity = scrollVelocity.abs() * (snappedScrollOffset - scrollOffset).sign;
    final double endVelocity = pixelOffsetToScrollOffset(kPixelScrollTolerance.velocity).abs() * (scrollVelocity < 0.0 ? -1.0 : 1.0);
    Simulation toSnapSimulation = scrollBehavior.createSnapScrollSimulation(
      scrollOffset, snappedScrollOffset, snapVelocity, endVelocity
    );
    if (toSnapSimulation == null)
      return null;

    final double scrollOffsetMin = math.min(scrollOffset, snappedScrollOffset);
    final double scrollOffsetMax = math.max(scrollOffset, snappedScrollOffset);
    return new ClampedSimulation(toSnapSimulation, xMin: scrollOffsetMin, xMax: scrollOffsetMax);
  }

  Simulation _createFlingSimulation(double scrollVelocity) {
    final Simulation simulation =  scrollBehavior.createScrollSimulation(scrollOffset, scrollVelocity);
    if (simulation != null) {
      final double endVelocity = pixelOffsetToScrollOffset(kPixelScrollTolerance.velocity).abs();
      final double endDistance = pixelOffsetToScrollOffset(kPixelScrollTolerance.distance).abs();
      simulation.tolerance = new Tolerance(velocity: endVelocity, distance: endDistance);
    }
    return simulation;
  }

  // When we start an scroll animation, we stop any previous scroll animation.
  // However, the code that would deliver the onScrollEnd callback is watching
  // for animations to end using a Future that resolves at the end of the
  // microtask. That causes animations to "overlap" between the time we start a
  // new animation and the end of the microtask. By the time the microtask is
  // over and we check whether to deliver an onScrollEnd callback, we will have
  // started the new animation (having skipped the onScrollStart) and therefore
  // we won't deliver the onScrollEnd until the second animation is finished.
  int _numberOfInProgressScrolls = 0;

  /// Calls the onScroll callback.
  ///
  /// Subclasses can override this function to hook the scroll callback.
  void dispatchOnScroll() {
    assert(_numberOfInProgressScrolls > 0);
    if (config.onScroll != null)
      config.onScroll(_scrollOffset);
    new ScrollNotification(this, ScrollNotificationKind.updated).dispatch(context);
  }

  void _handleDragDown(_) {
    _stop();
  }

  void _stop() {
    assert(_controller.isAnimating || _simulation == null);
    _controller.stop();
    _simulation = null;
  }

  void _handleDragStart(_) {
    _startScroll();
  }

  void _startScroll() {
    _numberOfInProgressScrolls += 1;
    if (_numberOfInProgressScrolls == 1)
      dispatchOnScrollStart();
  }

  /// Calls the onScrollStart callback.
  ///
  /// Subclasses can override this function to hook the scroll start callback.
  void dispatchOnScrollStart() {
    assert(_numberOfInProgressScrolls == 1);
    if (config.onScrollStart != null)
      config.onScrollStart(_scrollOffset);
    new ScrollNotification(this, ScrollNotificationKind.started).dispatch(context);
  }

  void _handleDragUpdate(double delta) {
    scrollBy(pixelOffsetToScrollOffset(delta));
  }

  Future<Null> _handleDragEnd(Velocity velocity) {
    double scrollVelocity = pixelDeltaToScrollOffset(velocity.pixelsPerSecond) / Duration.MILLISECONDS_PER_SECOND;
    return fling(scrollVelocity).then(_endScroll);
  }

  Null _endScroll([Null _]) {
    _numberOfInProgressScrolls -= 1;
    if (_numberOfInProgressScrolls == 0) {
      _simulation = null;
      dispatchOnScrollEnd();
    }
    return null;
  }

  /// Calls the dispatchOnScrollEnd callback.
  ///
  /// Subclasses can override this function to hook the scroll end callback.
  void dispatchOnScrollEnd() {
    assert(_numberOfInProgressScrolls == 0);
    if (config.onScrollEnd != null)
      config.onScrollEnd(_scrollOffset);
    if (mounted)
      new ScrollNotification(this, ScrollNotificationKind.ended).dispatch(context);
  }

  final GlobalKey<RawGestureDetectorState> _gestureDetectorKey = new GlobalKey<RawGestureDetectorState>();

  @override
  Widget build(BuildContext context) {
    return new RawGestureDetector(
      key: _gestureDetectorKey,
      gestures: buildGestureDetectors(),
      behavior: HitTestBehavior.opaque,
      child: buildContent(context)
    );
  }

  /// Fixes up the gesture detector to listen to the appropriate
  /// gestures based on the current information about the layout.
  ///
  /// This method should be called from the
  /// [onPaintOffsetUpdateNeeded] or [onExtentsChanged] handler given
  /// to the [Viewport] or equivalent used by the subclass's
  /// [buildContent] method. See the [buildContent] method's
  /// description for details.
  void updateGestureDetector() {
    _gestureDetectorKey.currentState.replaceGestureRecognizers(buildGestureDetectors());
  }

  /// Return the gesture detectors, in the form expected by
  /// [RawGestureDetector.gestures] and
  /// [RawGestureDetectorState.replaceGestureRecognizers], that are
  /// applicable to this [Scrollable] in its current state.
  ///
  /// This is called by [build] and [updateGestureDetector].
  Map<Type, GestureRecognizerFactory> buildGestureDetectors() {
    if (scrollBehavior.isScrollable) {
      switch (config.scrollDirection) {
        case Axis.vertical:
          return <Type, GestureRecognizerFactory>{
            VerticalDragGestureRecognizer: (VerticalDragGestureRecognizer recognizer) {
              return (recognizer ??= new VerticalDragGestureRecognizer())
                ..onDown = _handleDragDown
                ..onStart = _handleDragStart
                ..onUpdate = _handleDragUpdate
                ..onEnd = _handleDragEnd;
            }
          };
        case Axis.horizontal:
          return <Type, GestureRecognizerFactory>{
            HorizontalDragGestureRecognizer: (HorizontalDragGestureRecognizer recognizer) {
              return (recognizer ??= new HorizontalDragGestureRecognizer())
                ..onDown = _handleDragDown
                ..onStart = _handleDragStart
                ..onUpdate = _handleDragUpdate
                ..onEnd = _handleDragEnd;
            }
          };
      }
    }
    return const <Type, GestureRecognizerFactory>{};
  }

  /// Subclasses should override this function to build the interior of their
  /// scrollable widget. Scrollable wraps the returned widget in a
  /// [GestureDetector] to observe the user's interaction with this widget and
  /// to adjust the scroll offset accordingly.
  ///
  /// The widgets used by this method should be widgets that provide a
  /// layout-time callback that reports the sizes that are relevant to
  /// the scroll offset (typically the size of the scrollable
  /// container and the scrolled contents). [Viewport] provides an
  /// [onPaintOffsetUpdateNeeded] callback for this purpose; [GridViewport],
  /// [ListViewport], [LazyListViewport], and [LazyBlockViewport] provide an
  /// [onExtentsChanged] callback for this purpose.
  ///
  /// This callback should be used to update the scroll behavior, if
  /// necessary, and then to call [updateGestureDetector] to update
  /// the gesture detectors accordingly.
  Widget buildContent(BuildContext context);
}

/// Indicates if a [ScrollNotification] indicates the start, end or the
/// middle of a scroll.
enum ScrollNotificationKind {
  /// The [ScrollNotification] indicates that the scrollOffset has been changed
  /// and no existing scroll is underway.
  started,

  /// The [ScrollNotification] indicates that the scrollOffset has been changed.
  updated,

  /// The [ScrollNotification] indicates that the scrollOffset has stopped changing.
  /// This may be because the fling animation that follows a drag gesture has
  /// completed or simply because the scrollOffset was reset.
  ended
}

/// Indicates that a descendant scrollable has scrolled.
class ScrollNotification extends Notification {
  ScrollNotification(this.scrollable, this.kind);

  // Indicates if we're at the start, end or the middle of a scroll.
  final ScrollNotificationKind kind;

  /// The scrollable that scrolled.
  final ScrollableState scrollable;
}

/// A simple scrollable widget that has a single child. Use this widget if
/// you are not worried about offscreen widgets consuming resources.
class ScrollableViewport extends Scrollable {
  ScrollableViewport({
    Key key,
    double initialScrollOffset,
    Axis scrollDirection: Axis.vertical,
    ViewportAnchor scrollAnchor: ViewportAnchor.start,
    ScrollListener onScrollStart,
    ScrollListener onScroll,
    ScrollListener onScrollEnd,
    this.child
  }) : super(
    key: key,
    scrollDirection: scrollDirection,
    scrollAnchor: scrollAnchor,
    initialScrollOffset: initialScrollOffset,
    onScrollStart: onScrollStart,
    onScroll: onScroll,
    onScrollEnd: onScrollEnd
  );

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  ScrollableState createState() => new _ScrollableViewportState();
}

class _ScrollableViewportState extends ScrollableState<ScrollableViewport> {
  @override
  OverscrollWhenScrollableBehavior createScrollBehavior() => new OverscrollWhenScrollableBehavior();

  @override
  OverscrollWhenScrollableBehavior get scrollBehavior => super.scrollBehavior;

  double _viewportSize = 0.0;
  double _childSize = 0.0;

  Offset _handlePaintOffsetUpdateNeeded(ViewportDimensions dimensions) {
    // We make various state changes here but don't have to do so in a
    // setState() callback because we are called during layout and all
    // we're updating is the new offset, which we are providing to the
    // render object via our return value.
    _viewportSize = config.scrollDirection == Axis.vertical ? dimensions.containerSize.height : dimensions.containerSize.width;
    _childSize = config.scrollDirection == Axis.vertical ? dimensions.contentSize.height : dimensions.contentSize.width;
    didUpdateScrollBehavior(scrollBehavior.updateExtents(
      contentExtent: _childSize,
      containerExtent: _viewportSize,
      scrollOffset: scrollOffset
    ));
    updateGestureDetector();
    return scrollOffsetToPixelDelta(scrollOffset);
  }

  @override
  Widget buildContent(BuildContext context) {
    final bool clampOverscrolls = ClampOverscrolls.of(context);
    final double clampedScrollOffset = clampOverscrolls
      ? scrollOffset.clamp(scrollBehavior.minScrollOffset, scrollBehavior.maxScrollOffset)
      : scrollOffset;
    return new Viewport(
      paintOffset: scrollOffsetToPixelDelta(clampedScrollOffset),
      mainAxis: config.scrollDirection,
      anchor: config.scrollAnchor,
      onPaintOffsetUpdateNeeded: _handlePaintOffsetUpdateNeeded,
      child: config.child
    );
  }
}

/// A mashup of [ScrollableViewport] and [BlockBody]. Useful when you have a small,
/// fixed number of children that you wish to arrange in a block layout and that
/// might exceed the height of its container (and therefore need to scroll).
///
/// If you have a large number of children, consider using [LazyBlock] (if the
/// children have variable height) or [ScrollableList] (if the children all have
/// the same fixed height).
class Block extends StatelessWidget {
  Block({
    Key key,
    this.children: const <Widget>[],
    this.padding,
    this.initialScrollOffset,
    this.scrollDirection: Axis.vertical,
    this.scrollAnchor: ViewportAnchor.start,
    this.onScrollStart,
    this.onScroll,
    this.onScrollEnd,
    this.scrollableKey
  }) : super(key: key) {
    assert(children != null);
    assert(!children.any((Widget child) => child == null));
  }

  final List<Widget> children;

  /// The amount of space by which to inset the children inside the viewport.
  final EdgeInsets padding;

  /// The scroll offset this widget should use when first created.
  final double initialScrollOffset;

  final Axis scrollDirection;
  final ViewportAnchor scrollAnchor;

  /// Called whenever this widget starts to scroll.
  final ScrollListener onScrollStart;

  /// Called whenever this widget's scroll offset changes.
  final ScrollListener onScroll;

  /// Called whenever this widget stops scrolling.
  final ScrollListener onScrollEnd;

  /// The key to use for the underlying scrollable widget.
  final Key scrollableKey;

  @override
  Widget build(BuildContext context) {
    Widget contents = new BlockBody(children: children, mainAxis: scrollDirection);
    if (padding != null)
      contents = new Padding(padding: padding, child: contents);
    return new ScrollableViewport(
      key: scrollableKey,
      initialScrollOffset: initialScrollOffset,
      scrollDirection: scrollDirection,
      scrollAnchor: scrollAnchor,
      onScrollStart: onScrollStart,
      onScroll: onScroll,
      onScrollEnd: onScrollEnd,
      child: contents
    );
  }
}
