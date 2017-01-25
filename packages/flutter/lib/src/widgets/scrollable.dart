// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui show window;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'basic.dart';
import 'clamp_overscrolls.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'notification_listener.dart';
import 'page_storage.dart';
import 'scroll_absolute.dart' show ViewportScrollBehavior;
import 'scroll_behavior.dart';
import 'scroll_configuration.dart';
import 'scroll_notification.dart';
import 'ticker_provider.dart';
import 'viewport.dart';

export 'package:flutter/physics.dart' show Tolerance;

// This file defines an unopinionated scrolling mechanism.
// See scroll_absolute.dart for variants that do things by pixels.

abstract class ScrollPosition extends ViewportOffset {
  /// Create a new [ScrollPosition].
  ///
  /// The first argument is the [Scrollable2State] object with which this scroll
  /// position is associated. The second provides the tolerances for activities
  /// that use simulations and need to decide when to end them. The final
  /// argument is the previous instance of [ScrollPosition] that was being used
  /// by the same [Scrollable2State], if any.
  ScrollPosition(this.state, this.scrollTolerances, ScrollPosition oldPosition) {
    assert(state is TickerProvider);
    assert(scrollTolerances != null);
    if (oldPosition != null)
      absorb(oldPosition);
    if (activity == null)
      beginIdleActivity();
    assert(activity != null);
    assert(activity.position == this);
  }

  @protected
  final Scrollable2State state;

  final Tolerance scrollTolerances;

  @protected
  TickerProvider get vsync => state;

  @protected
  ScrollActivity get activity => _activity;
  ScrollActivity _activity;

  /// Take any current applicable state from the given [ScrollPosition].
  ///
  /// This method is called by the constructor, instead of calling
  /// [beginIdleActivity], if it is given an `oldPosition`. It adopts the old
  /// position's current [activity] as its own.
  ///
  /// This method is destructive to the other [ScrollPosition]. The other
  /// object must be disposed immediately after this call (in the same call
  /// stack, before microtask resolution, by whomever called this object's
  /// constructor).
  ///
  /// If the old [ScrollPosition] object is a different [runtimeType] than this
  /// one, the [ScrollActivity.resetActivity] method is invoked on the newly
  /// adopted [ScrollActivity].
  ///
  /// When overriding this method, call `super.absorb` after setting any
  /// metrics-related or activity-related state, since this method may restart
  /// the activity and scroll activities tend to use those metrics when being
  /// restarted.
  @protected
  @mustCallSuper
  void absorb(ScrollPosition other) {
    assert(activity == null);
    assert(other != this);
    assert(other.state == state);
    assert(other.activity != null);
    final bool oldIgnorePointer = shouldIgnorePointer;
    _userScrollDirection = other._userScrollDirection;
    other.activity._position = this;
    _activity = other.activity;
    other._activity = null;
    if (oldIgnorePointer != shouldIgnorePointer)
      state._updateIgnorePointer(shouldIgnorePointer);
    if (other.runtimeType != runtimeType)
      activity.resetActivity();
  }

  /// Change the current [activity], disposing of the old one and
  /// sending scroll notifications as necessary.
  ///
  /// If the argument is null, this method has no effect. This is convenient for
  /// cases where the new activity is obtained from another method, and that
  /// method might return null, since it means the caller does not have to
  /// explictly null-check the argument.
  void beginActivity(ScrollActivity newActivity) {
    if (newActivity == null)
      return;
    assert(newActivity.position == this);
    final bool oldIgnorePointer = shouldIgnorePointer;
    bool wasScrolling;
    if (activity != null) {
      wasScrolling = activity.isScrolling;
      if (wasScrolling && !newActivity.isScrolling)
        dispatchNotification(activity.createScrollEndNotification(state));
      activity.dispose();
    } else {
      wasScrolling = false;
    }
    _activity = newActivity;
    if (oldIgnorePointer != shouldIgnorePointer)
      state._updateIgnorePointer(shouldIgnorePointer);
    if (!activity.isScrolling)
      updateUserScrollDirection(ScrollDirection.idle);
    if (!wasScrolling && activity.isScrolling)
      dispatchNotification(activity.createScrollStartNotification(state));
  }

  @protected
  void dispatchNotification(Notification notification) {
    assert(state.mounted);
    notification.dispatch(state._viewportKey.currentContext);
  }

  @override
  void dispose() {
    activity?.dispose(); // it will be null if it got absorbed by another ScrollPosition
    _activity = null;
    super.dispose();
  }

  void touched() {
    _activity.touched();
  }

  @override
  @mustCallSuper
  void applyViewportDimension(double viewportDimension) {
    state._updateGestureDetectors(canDrag);
  }

  @override
  @mustCallSuper
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    state._updateGestureDetectors(canDrag);
    return true;
  }

  /// The direction that the user most recently began scrolling in.
  @override
  ScrollDirection get userScrollDirection => _userScrollDirection;
  ScrollDirection _userScrollDirection = ScrollDirection.idle;

  /// Set [userScrollDirection] to the given value.
  ///
  /// If this changes the value, then a [UserScrollNotification] is dispatched.
  ///
  /// This should only be set from the current [ScrollActivity] (see [activity]).
  void updateUserScrollDirection(ScrollDirection value) {
    assert(value != null);
    if (userScrollDirection == value)
      return;
    _userScrollDirection = value;
    dispatchNotification(new UserScrollNotification(scrollable: state, direction: value));
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$activity');
    description.add('$userScrollDirection');
  }

  bool get canDrag => false;

  bool get shouldIgnorePointer => false;

  @mustCallSuper
  void postFrameCleanup() { }

  void beginIdleActivity() {
    beginActivity(new IdleScrollActivity(this));
  }

  DragScrollActivity beginDragActivity(DragStartDetails details) {
    if (canDrag) {
      throw new FlutterError(
        '$runtimeType does not implement beginDragActivity but canDrag is true.\n'
        'If a ScrollPosition class ever returns true from canDrag, then it must '
        'implement the beginDragActivity method to handle drags.\n'
        'The beginDragActivity method should call beginActivity, passing it a new '
        'instance of a DragScrollActivity subclass that has been initialized with '
        'this ScrollPosition object as its position.'
      );
    }
    assert(false);
    return null;
  }

  /// Used by [AbsoluteDragScrollActivity] and other user-driven activities to
  /// convert an offset in logical pixels as provided by the [DragUpdateDetails]
  /// into a delta to apply using [setPixels].
  ///
  /// This is used by some [ScrollPosition] subclasses to apply friction during
  /// overscroll situations.
  double applyPhysicsToUserOffset(double offset) => offset;

  // ///
  // /// The velocity should be in logical pixels per second.
  void beginBallisticActivity(double velocity) {
    beginIdleActivity();
  }

  // ABSTRACT METHODS

  /// Update the scroll position ([pixels]) to a given pixel value.
  ///
  /// This should only be called by the current [ScrollActivity], either during
  /// the transient callback phase or in response to user input.
  ///
  /// Returns the overscroll, if any. If the return value is 0.0, that means
  /// that [pixels] now returns the given `value`. If the return value is
  /// positive, then [pixels] is less than the requested `value` by the given
  /// amount (overscroll past the max extent), and if it is negative, it is
  /// greater than the requested `value` by the given amount (underscroll past
  /// the min extent).
  ///
  /// Implementations of this method must dispatch scroll update notifications
  /// (using [dispatchNotification] and
  /// [ScrollActivity.createScrollUpdateNotification]) after applying the new
  /// value (so after [pixels] changes). If the entire change is not applied,
  /// the overscroll should be reported by subsequently also dispatching an
  /// overscroll notification using
  /// [ScrollActivity.createOverscrollNotification].
  double setPixels(double value);

  /// Returns a description of the [Scrollable].
  ///
  /// Accurately describing the metrics typicaly requires using information
  /// provided by the viewport to the [applyViewportDimension] and
  /// [applyContentDimensions] methods.
  ///
  /// The metrics do not need to be in absolute (pixel) units, but they must be
  /// in consistent units (so that they can be compared over time or used to
  /// drive diagrammatic user interfaces such as scrollbars).
  ScrollableMetrics getMetrics();

  // Subclasses must also implement the [pixels] getter and [correctBy].
}

/// Base class for scrolling activities like dragging, and flinging.
abstract class ScrollActivity {
  ScrollActivity(ScrollPosition position) {
    _position = position;
  }

  @protected
  ScrollPosition get position => _position;
  ScrollPosition _position;

  /// Called by the [ScrollPosition] when it has changed type (for example, when
  /// changing from an Android-style scroll position to an iOS-style scroll
  /// position). If this activity can differ between the two modes, then it
  /// should tell the position to restart that activity appropriately.
  ///
  /// For example, [BallisticScrollActivity]'s implementation calls
  /// [ScrollPosition.beginBallisticActivity].
  void resetActivity() { }

  Notification createScrollStartNotification(Scrollable2State scrollable) {
    return new ScrollStartNotification(scrollable: scrollable);
  }

  Notification createScrollUpdateNotification(Scrollable2State scrollable, double scrollDelta) {
    return new ScrollUpdateNotification(scrollable: scrollable, scrollDelta: scrollDelta);
  }

  Notification createOverscrollNotification(Scrollable2State scrollable, double overscroll) {
    return new OverscrollNotification(scrollable: scrollable, overscroll: overscroll);
  }

  Notification createScrollEndNotification(Scrollable2State scrollable) {
    return new ScrollEndNotification(scrollable: scrollable);
  }

  void touched() { }

  void applyNewDimensions() { }

  bool get shouldIgnorePointer;

  bool get isScrolling;

  @mustCallSuper
  void dispose() { }

  @override
  String toString() => '$runtimeType';
}

class IdleScrollActivity extends ScrollActivity {
  IdleScrollActivity(ScrollPosition position) : super(position);

  @override
  void applyNewDimensions() {
    position.beginBallisticActivity(0.0);
  }

  @override
  bool get shouldIgnorePointer => false;

  @override
  bool get isScrolling => false;
}

abstract class DragScrollActivity extends ScrollActivity {
  DragScrollActivity(ScrollPosition position) : super(position);

  void update(DragUpdateDetails details, { bool reverse });

  void end(DragEndDetails details, { bool reverse });

  @override
  void touched() {
    assert(false);
  }

  @override
  void dispose() {
    position.state._drag = null;
    super.dispose();
  }
}

/// Base class for delegates that instantiate [ScrollPosition] objects.
abstract class ScrollBehavior2 {
  const ScrollBehavior2();

  Widget wrap(BuildContext context, Widget child, AxisDirection axisDirection);

  Widget createViewport({
    Key key,
    AxisDirection axisDirection: AxisDirection.down,
    double anchor: 0.0,
    ViewportOffset offset,
    Key center,
    List<Widget> children: const <Widget>[],
  });

  /// Returns a new instance of the ScrollPosition class that this
  /// ScrollBehavior2 subclass creates.
  ///
  /// A given ScrollBehavior2 object must always return the same kind of
  /// ScrollPosition, with the same configuration.
  ///
  /// The `oldPosition` argument should be passed to the `ScrollPosition`
  /// constructor so that the new position can take over the old position's
  /// offset and (if it's the same type) activity.
  ///
  /// When calling [createScrollPosition] with a non-null `oldPosition`, that
  /// object must be disposed (via [ScrollPosition.oldPosition]) in the same
  /// call stack. Passing a non-null `oldPosition` is a destructive operation
  /// for that [ScrollPosition].
  ScrollPosition createScrollPosition(BuildContext context, Scrollable2State state, ScrollPosition oldPosition);

  /// Whether this delegate is different than the old delegate, or would now
  /// return meaningfully different widgets from [wrap] or a meaningfully
  /// different [ScrollPosition] from [createScrollPosition].
  ///
  /// It is not necessary to return true if the return values for [wrap] and
  /// [createScrollPosition] would only be different because of depending on the
  /// [BuildContext] argument they are provided, as dependency checking is
  /// handled separately.
  bool shouldNotify(@checked ScrollBehavior2 oldDelegate);

  @override
  String toString() => '$runtimeType';
}

abstract class ScrollBehavior2Proxy extends ScrollBehavior2 {
  ScrollBehavior2Proxy(this.parent) {
    assert(parent != null);
  }

  final ScrollBehavior2 parent;

  @override
  Widget wrap(BuildContext context, Widget child, AxisDirection axisDirection) {
    return parent.wrap(context, child, axisDirection);
  }

  @override
  Widget createViewport({
    Key key,
    AxisDirection axisDirection: AxisDirection.down,
    double anchor: 0.0,
    ViewportOffset offset,
    Key center,
    List<Widget> children: const <Widget>[],
  }) {
    return parent.createViewport(
      key: key,
      axisDirection: axisDirection,
      anchor: anchor,
      offset: offset,
      center: center,
      children: children,
    );
  }

  @override
  ScrollPosition createScrollPosition(BuildContext context, Scrollable2State state, ScrollPosition oldPosition) {
    return parent.createScrollPosition(context, state, oldPosition);
  }

  @override
  bool shouldNotify(@checked ScrollBehavior2Proxy oldDelegate) {
    return parent.shouldNotify(oldDelegate.parent);
  }
}

class ScrollConfiguration2 extends InheritedWidget {
  const ScrollConfiguration2({
    Key key,
    @required this.delegate,
    @required Widget child,
  }) : super(key: key, child: child);

  final ScrollBehavior2 delegate;

  static ScrollBehavior2 of(BuildContext context) {
    ScrollConfiguration2 configuration = context.inheritFromWidgetOfExactType(ScrollConfiguration2);
    return configuration?.delegate;
  }

  @override
  bool updateShouldNotify(ScrollConfiguration2 old) {
    assert(delegate != null);
    return delegate.runtimeType != old.delegate.runtimeType
        || delegate.shouldNotify(old.delegate);
  }
}

class Scrollable2 extends StatefulWidget {
  Scrollable2({
    Key key,
    this.axisDirection: AxisDirection.down,
    this.anchor: 0.0,
    this.initialScrollOffset: 0.0,
    this.scrollBehavior,
    this.center,
    this.children,
  }) : super (key: key) {
    assert(axisDirection != null);
    assert(anchor != null);
    assert(initialScrollOffset != null);
  }

  final AxisDirection axisDirection;

  final double anchor;

  final double initialScrollOffset;

  /// The delegate that creates the [ScrollPosition] and wraps the viewport
  /// in extra widgets (e.g. for overscroll effects).
  ///
  /// If no scroll behavior delegate is explicitly supplied, the scroll behavior
  /// from the nearest [ScrollConfiguration2] is used. If there is no
  /// [ScrollConfiguration2] in scope, a new [ViewportScrollBehavior] is used.
  final ScrollBehavior2 scrollBehavior;

  final Key center;

  final List<Widget> children;

  Axis get axis => axisDirectionToAxis(axisDirection);

  @override
  Scrollable2State createState() => new Scrollable2State();

  static ScrollBehavior2 getScrollBehavior(BuildContext context) {
    return ScrollConfiguration2.of(context)
        ?? new ViewportScrollBehavior();
  }

  /// Whether, when this widget has been replaced by another, the scroll
  /// behavior and scroll position need to be updated as well.
  bool shouldUpdateScrollPosition(Scrollable2 oldWidget) {
    return scrollBehavior.runtimeType != oldWidget.scrollBehavior.runtimeType
        || (scrollBehavior != null && scrollBehavior.shouldNotify(oldWidget.scrollBehavior));
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$axisDirection');
    if (anchor != 0.0)
      description.add('anchor: ${anchor.toStringAsFixed(1)}');
    if (initialScrollOffset != 0.0)
      description.add('initialScrollOffset: ${initialScrollOffset.toStringAsFixed(1)}');
    if (scrollBehavior != null) {
      description.add('scrollBehavior: $scrollBehavior');
    } else {
      description.add('scrollBehavior: use inherited ScrollBehavior2');
    }
    if (center != null)
      description.add('center: $center');
  }
}

/// State object for a [Scrollable2] widget.
///
/// To manipulate a [Scrollable2] widget's scroll position, use the object
/// obtained from the [position] property.
///
/// To be informed of when a [Scrollable2] widget is scrolling, use a
/// [NotificationListener] to listen for [ScrollNotification2] notifications.
///
/// This class is not intended to be subclassed. To specialize the behavior of a
/// [Scrollable2], provide it with a custom [ScrollBehavior2] delegate.
class Scrollable2State extends State<Scrollable2> with TickerProviderStateMixin {
  /// The controller for this [Scrollable2] widget's viewport position.
  ///
  /// To control what kind of [ScrollPosition] is created for a [Scrollable2],
  /// provide it with a custom [ScrollBehavior2] delegate that creates the
  /// appropriate [ScrollPosition] controller in its
  /// [ScrollBehavior2.createScrollPosition] method.
  ScrollPosition get position => _position;
  ScrollPosition _position;

  ScrollBehavior2 _scrollBehavior;

  // only call this from places that will definitely trigger a rebuild
  void _updatePosition() {
    _scrollBehavior = config.scrollBehavior ?? Scrollable2.getScrollBehavior(context);
    final ScrollPosition oldPosition = position;
    _position = _scrollBehavior.createScrollPosition(context, this, oldPosition);
    assert(position != null);
    if (oldPosition != null) {
      // It's important that we not do this until after the RenderViewport2
      // object has had a chance to unregister its listeners from the old
      // position. So, schedule a microtask to do it.
      scheduleMicrotask(oldPosition.dispose);
    }
  }

  @override
  void dependenciesChanged() {
    super.dependenciesChanged();
    _updatePosition();
  }

  @override
  void didUpdateConfig(Scrollable2 oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (config.shouldUpdateScrollPosition(oldConfig))
      _updatePosition();
  }

  @override
  void dispose() {
    position.dispose();
    super.dispose();
  }


  // GESTURE RECOGNITION AND POINTER IGNORING

  final GlobalKey<RawGestureDetectorState> _gestureDetectorKey = new GlobalKey<RawGestureDetectorState>();
  final GlobalKey _ignorePointerKey = new GlobalKey();
  final GlobalKey _viewportKey = new GlobalKey();

  // This field is set during layout, and then reused until the next time it is set.
  Map<Type, GestureRecognizerFactory> _gestureRecognizers = const <Type, GestureRecognizerFactory>{};
  bool _shouldIgnorePointer = false;

  bool _lastCanDrag;
  Axis _lastAxisDirection;

  void _updateGestureDetectors(bool canDrag) {
    if (canDrag == _lastCanDrag && (!canDrag || config.axis == _lastAxisDirection))
      return;
    if (!canDrag) {
      _gestureRecognizers = const <Type, GestureRecognizerFactory>{};
    } else {
      switch (config.axis) {
        case Axis.vertical:
          _gestureRecognizers = <Type, GestureRecognizerFactory>{
            VerticalDragGestureRecognizer: (VerticalDragGestureRecognizer recognizer) {  // ignore: map_value_type_not_assignable, https://github.com/flutter/flutter/issues/7173
              return (recognizer ??= new VerticalDragGestureRecognizer())
                ..onDown = _handleDragDown
                ..onStart = _handleDragStart
                ..onUpdate = _handleDragUpdate
                ..onEnd = _handleDragEnd;
            }
          };
          break;
        case Axis.horizontal:
          _gestureRecognizers = <Type, GestureRecognizerFactory>{
            HorizontalDragGestureRecognizer: (HorizontalDragGestureRecognizer recognizer) {  // ignore: map_value_type_not_assignable, https://github.com/flutter/flutter/issues/7173
              return (recognizer ??= new HorizontalDragGestureRecognizer())
                ..onDown = _handleDragDown
                ..onStart = _handleDragStart
                ..onUpdate = _handleDragUpdate
                ..onEnd = _handleDragEnd;
            }
          };
          break;
      }
    }
    _lastCanDrag = canDrag;
    _lastAxisDirection = config.axis;
    if (_gestureDetectorKey.currentState != null)
      _gestureDetectorKey.currentState.replaceGestureRecognizers(_gestureRecognizers);
  }

  void _updateIgnorePointer(bool value) {
    if (_shouldIgnorePointer == value)
      return;
    _shouldIgnorePointer = value;
    if (_ignorePointerKey.currentContext != null) {
      RenderIgnorePointer renderBox = _ignorePointerKey.currentContext.findRenderObject();
      renderBox.ignoring = _shouldIgnorePointer;
    }
  }


  // TOUCH HANDLERS

  DragScrollActivity _drag;

  bool get _reverseDirection {
    assert(config.axisDirection != null);
    switch (config.axisDirection) {
      case AxisDirection.up:
      case AxisDirection.left:
        return true;
      case AxisDirection.down:
      case AxisDirection.right:
        return false;
    }
    return null;
  }

  void _handleDragDown(DragDownDetails details) {
    assert(_drag == null);
    position.touched();
  }

  void _handleDragStart(DragStartDetails details) {
    assert(_drag == null);
    _drag = position.beginDragActivity(details);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(_drag != null);
    _drag.update(details, reverse: _reverseDirection);
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(_drag != null);
    _drag.end(details, reverse: _reverseDirection);
    assert(_drag == null);
  }


  // DESCRIPTION

  @override
  Widget build(BuildContext context) {
    assert(position != null);
    // TODO(ianh): Having all these global keys is sad.
    Widget result = new RawGestureDetector(
      key: _gestureDetectorKey,
      gestures: _gestureRecognizers,
      behavior: HitTestBehavior.opaque,
      child: new IgnorePointer(
        key: _ignorePointerKey,
        ignoring: _shouldIgnorePointer,
        child: _scrollBehavior.createViewport(
          key: _viewportKey,
          axisDirection: config.axisDirection,
          anchor: config.anchor,
          offset: position,
          center: config.center,
          children: config.children,
        ),
      ),
    );
    return _scrollBehavior.wrap(context, result, config.axisDirection);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('position: $position');
  }
}


// DELETE EVERYTHING BELOW THIS LINE WHEN REMOVING LEGACY SCROLLING CODE

/// Identifies one or both limits of a [Scrollable] in terms of its scrollDirection.
enum ScrollableEdge {
  /// The top and bottom of the scrollable if its scrollDirection is vertical
  /// or the left and right if its scrollDirection is horizontal.
  both,

  /// Only the top of the scrollable if its scrollDirection is vertical,
  /// or only the left if its scrollDirection is horizontal.
  leading,

  /// Only the bottom of the scrollable if its scroll-direction is vertical,
  /// or only the right if its scrollDirection is horizontal.
  trailing,

  /// The overscroll indicator should not appear at all.
  none,
}

/// The accuracy to which scrolling is computed.
final Tolerance kPixelScrollTolerance = new Tolerance(
  // TODO(ianh): Handle the case of the device pixel ratio changing.
  velocity: 1.0 / (0.050 * ui.window.devicePixelRatio), // logical pixels per second
  distance: 1.0 / ui.window.devicePixelRatio // logical pixels
);

/// Signature for building a widget based on [ScrollableState].
///
/// Used by [Scrollable.builder].
typedef Widget ScrollBuilder(BuildContext context, ScrollableState state);

/// Signature for callbacks that receive a scroll offset.
///
/// Used by [Scrollable.onScrollStart], [Scrollable.onScroll], and [Scrollable.onScrollEnd].
typedef void ScrollListener(double scrollOffset);

/// Signature for determining the offset at which scrolling should snap.
///
/// Used by [Scrollable.snapOffsetCallback].
typedef double SnapOffsetCallback(double scrollOffset, Size containerSize);

/// A base class for scrollable widgets.
///
/// If you have a list of widgets and want them to be able to scroll if there is
/// insufficient room, consider using [Block].
///
/// Commonly used classes that are based on Scrollable include [ScrollableList],
/// [ScrollableGrid], and [ScrollableViewport].
///
/// Widgets that subclass [Scrollable] typically use state objects that subclass
/// [ScrollableState].
class Scrollable extends StatefulWidget {
  /// Initializes fields for subclasses.
  ///
  /// The [scrollDirection] and [scrollAnchor] arguments must not be null.
  Scrollable({
    Key key,
    this.initialScrollOffset,
    this.scrollDirection: Axis.vertical,
    this.scrollAnchor: ViewportAnchor.start,
    this.onScrollStart,
    this.onScroll,
    this.onScrollEnd,
    this.snapOffsetCallback,
    this.builder
  }) : super(key: key) {
    assert(scrollDirection == Axis.vertical || scrollDirection == Axis.horizontal);
    assert(scrollAnchor == ViewportAnchor.start || scrollAnchor == ViewportAnchor.end);
  }

  // Warning: keep the dartdoc comments that follow in sync with the copies in
  // ScrollableViewport, LazyBlock, ScrollableLazyList, ScrollableList, and
  // ScrollableGrid. And see: https://github.com/dart-lang/dartdoc/issues/1161.

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

  /// Using to build the content of this widget.
  ///
  /// See [buildContent] for details.
  final ScrollBuilder builder;

  /// The state from the closest instance of this class that encloses the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// ScrollableState scrollable = Scrollable.of(context);
  /// ```
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
        // The target is too big to fit inside the scrollable. The best we can do
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
  ScrollableState createState() => new ScrollableState<Scrollable>();
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
class ScrollableState<T extends Scrollable> extends State<T> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _controller = new AnimationController.unbounded(vsync: this)
      ..addListener(_handleAnimationChanged)
      ..addStatusListener(_handleAnimationStatusChanged);
    _scrollOffset = PageStorage.of(context)?.readState(context) ?? config.initialScrollOffset ?? 0.0;
    _virtualScrollOffset = _scrollOffset;
  }

  Simulation _simulation; // if we're flinging, then this is the animation with which we're doing it
  AnimationController _controller;
  double _contentExtent;
  double _containerExtent;
  bool _scrollUnderway = false;

  @override
  void dispose() {
    _controller.dispose();
    _simulation = null;
    super.dispose();
  }

  @override
  void dependenciesChanged() {
    _scrollBehavior = createScrollBehavior();
    didUpdateScrollBehavior(_scrollBehavior.updateExtents(
      contentExtent: _contentExtent,
      containerExtent: _containerExtent,
      scrollOffset: scrollOffset
    ));
    super.dependenciesChanged();
  }

  /// The current scroll offset.
  ///
  /// The scroll offset is applied to the child widget along the scroll
  /// direction before painting. A positive scroll offset indicates that
  /// more content in the preferred reading direction is visible.
  ///
  /// The scroll offset's value may be above or below the limits defined
  /// by the [scrollBehavior]. This is called "overscrolling" and it can be
  /// prevented with the [ClampOverscrolls] widget.
  ///
  /// See also:
  ///
  /// * [virtualScrollOffset]
  /// * [initialScrollOffset]
  /// * [onScrollStart]
  /// * [onScroll]
  /// * [onScrollEnd]
  /// * [ScrollNotification]
  double get scrollOffset => _scrollOffset;
  double _scrollOffset;

  /// The current scroll offset, irrespective of the constraints defined
  /// by any [ClampOverscrolls] widget ancestors.
  ///
  /// See also:
  ///
  /// * [scrollOffset]
  double get virtualScrollOffset => _virtualScrollOffset;
  double _virtualScrollOffset;

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
    assert(config.scrollAnchor != null);
    return null;
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
    assert(config.scrollAnchor != null);
    return null;
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
    assert(config.scrollDirection != null);
    return null;
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
    assert(config.scrollDirection != null);
    return null;
  }

  /// The current scroll behavior of this widget.
  ///
  /// Scroll behaviors control where the boundaries of the scrollable are placed
  /// and how the scrolling physics should behave near those boundaries and
  /// after the user stops directly manipulating the scrollable.
  ExtentScrollBehavior get scrollBehavior => _scrollBehavior;
  ExtentScrollBehavior _scrollBehavior;

  /// Use the value returned by [ScrollConfiguration.createScrollBehavior].
  /// If this widget doesn't have a ScrollConfiguration ancestor,
  /// or its createScrollBehavior callback is null, then return a new instance
  /// of [OverscrollWhenScrollableBehavior].
  @protected
  ExtentScrollBehavior createScrollBehavior() {
    return ScrollConfiguration.of(context)?.createScrollBehavior();
  }

  bool _scrollOffsetIsInBounds(double scrollOffset) {
    if (scrollBehavior is! ExtentScrollBehavior)
      return false;
    final ExtentScrollBehavior behavior = scrollBehavior;
    return scrollOffset >= behavior.minScrollOffset && scrollOffset < behavior.maxScrollOffset;
  }

  void _handleAnimationChanged() {
    _setScrollOffset(_controller.value);
  }

  void _handleAnimationStatusChanged(AnimationStatus status) {
    // this is not called when stop() is called on the controller
    setState(() {
      if (!_controller.isAnimating) {
        _simulation = null;
        _scrollUnderway = false;
      }
    });
  }

  void _setScrollOffset(double newScrollOffset, { DragUpdateDetails details }) {
    if (_scrollOffset == newScrollOffset)
      return;

    final ClampOverscrolls clampOverscrolls = ClampOverscrolls.of(context);
    final double clampedScrollOffset = clampOverscrolls?.clampScrollOffset(this, newScrollOffset) ?? newScrollOffset;
    _setStateMaybeDuringBuild(() {
      _virtualScrollOffset = newScrollOffset;
      _scrollUnderway = _scrollOffset != clampedScrollOffset;
      _scrollOffset = clampedScrollOffset;
    });
    PageStorage.of(context)?.writeState(context, _scrollOffset);
    _startScroll();
    dispatchOnScroll();
    new ScrollNotification(
      scrollable: this,
      kind: ScrollNotificationKind.updated,
      details: details
    ).dispatch(context);
    _endScroll();
  }

  /// Scroll this widget by the given scroll delta.
  ///
  /// If a non-null [duration] is provided, the widget will animate to the new
  /// scroll offset over the given duration with the given curve.
  Future<Null> scrollBy(double scrollDelta, {
    Duration duration,
    Curve curve: Curves.ease,
    DragUpdateDetails details
  }) {
    double newScrollOffset = scrollBehavior.applyCurve(virtualScrollOffset, scrollDelta);
    return scrollTo(newScrollOffset, duration: duration, curve: curve, details: details);
  }

  /// Scroll this widget to the given scroll offset.
  ///
  /// If a non-null [duration] is provided, the widget will animate to the new
  /// scroll offset over the given duration with the given curve.
  ///
  /// This function does not accept a zero duration. To jump-scroll to
  /// the new offset, do not provide a duration, rather than providing
  /// a zero duration.
  ///
  /// The returned [Future] completes when the scrolling animation is complete.
  Future<Null> scrollTo(double newScrollOffset, {
    Duration duration,
    Curve curve: Curves.ease,
    DragUpdateDetails details
  }) {
    if (newScrollOffset == _scrollOffset)
      return new Future<Null>.value();

    if (duration == null) {
      _stop();
      _setScrollOffset(newScrollOffset, details: details);
      return new Future<Null>.value();
    }

    assert(duration > Duration.ZERO);
    return _animateTo(newScrollOffset, duration, curve);
  }

  Future<Null> _animateTo(double newScrollOffset, Duration duration, Curve curve) {
    _stop();
    _controller.value = virtualScrollOffset;
    _startScroll();
    return _controller.animateTo(newScrollOffset, duration: duration, curve: curve).then((Null _) {
      _endScroll();
    });
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
    _setStateMaybeDuringBuild(() {
      _contentExtent = scrollBehavior.contentExtent;
      _containerExtent = scrollBehavior.containerExtent;
    });

    // This does not call setState, because if anything below actually
    // changes our build, it will itself independently trigger a frame.
    assert(_controller.isAnimating || _simulation == null);
    if (_numberOfInProgressScrolls > 0) {
      if (_simulation != null) {
        double dx = _simulation.dx(_controller.lastElapsedDuration.inMicroseconds / Duration.MICROSECONDS_PER_SECOND);
        _startToEndAnimation(dx); // dx - logical pixels / second
      }
      return;
    }
    scrollTo(newScrollOffset);
  }

  /// Updates the scroll behavior for the new content and container extent.
  ///
  /// For convenience, this function combines three common operations:
  ///
  ///  1. Updating the scroll behavior extents with
  ///     [ExtentScrollBehavior.updateExtents].
  ///  2. Notifying this object that the scroll behavior was updated with
  ///     [didUpdateScrollBehavior].
  ///  3. Updating this object's gesture detector with [updateGestureDetector].
  void handleExtentsChanged(double contentExtent, double containerExtent) {
    didUpdateScrollBehavior(scrollBehavior.updateExtents(
      contentExtent: contentExtent,
      containerExtent: containerExtent,
      scrollOffset: scrollOffset
    ));
    updateGestureDetector();
  }

  /// If [scrollVelocity] is greater than [PixelScrollTolerance.velocity] then
  /// fling the scroll offset with the given velocity in logical pixels/second.
  /// Otherwise, if this scrollable is overscrolled or a [snapOffsetCallback]
  /// was given, animate the scroll offset to its final value with [settleScrollOffset].
  ///
  /// Calling this function starts a physics-based animation of the scroll
  /// offset with the given value as the initial velocity. The physics
  /// simulation is determined by the scroll behavior.
  ///
  /// The returned [Future] completes when the scrolling animation is complete.
  Future<Null> fling(double scrollVelocity) {
    if (scrollVelocity.abs() > kPixelScrollTolerance.velocity)
      return _startToEndAnimation(scrollVelocity);

    // If a scroll animation isn't underway already and we're overscrolled or we're
    // going to have to snap the scroll offset, then animate the scroll offset to its
    // final value.
    if (!_controller.isAnimating &&
        (shouldSnapScrollOffset || !_scrollOffsetIsInBounds(scrollOffset)))
      return settleScrollOffset();

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
    return _controller.animateWith(_simulation).then((Null _) {
      _endScroll();
    });
  }

  /// Whether this scrollable should attempt to snap scroll offsets.
  bool get shouldSnapScrollOffset => config.snapOffsetCallback != null;

  /// Returns the snapped offset closest to the given scroll offset.
  double snapScrollOffset(double scrollOffset) {
    return config.snapOffsetCallback == null ? scrollOffset : config.snapOffsetCallback(scrollOffset, context.size);
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

    final double snappedScrollOffset = snapScrollOffset(endScrollOffset);
    if (!_scrollOffsetIsInBounds(snappedScrollOffset))
      return null;

    final double snapVelocity = scrollVelocity.abs() * (snappedScrollOffset - scrollOffset).sign;
    final double endVelocity = pixelOffsetToScrollOffset(kPixelScrollTolerance.velocity).abs() * (scrollVelocity < 0.0 ? -1.0 : 1.0);
    Simulation toSnapSimulation = scrollBehavior.createSnapScrollSimulation(
      virtualScrollOffset, snappedScrollOffset, snapVelocity, endVelocity
    );
    if (toSnapSimulation == null)
      return null;

    final double scrollOffsetMin = math.min(scrollOffset, snappedScrollOffset);
    final double scrollOffsetMax = math.max(scrollOffset, snappedScrollOffset);
    return new ClampedSimulation(toSnapSimulation, xMin: scrollOffsetMin, xMax: scrollOffsetMax);
  }

  Simulation _createFlingSimulation(double scrollVelocity) {
    final Simulation simulation = scrollBehavior.createScrollSimulation(virtualScrollOffset, scrollVelocity);
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
  /// Subclasses can override this method to hook the scroll callback.
  void dispatchOnScroll() {
    assert(_numberOfInProgressScrolls > 0);
    if (config.onScroll != null)
      config.onScroll(_scrollOffset);
  }

  void _handleDragDown(DragDownDetails details) {
    setState(() {
      _stop();
    });
  }

  void _stop() {
    assert(mounted);
    assert(_controller.isAnimating || _simulation == null);
    _controller.stop(); // this does not trigger a status notification
    _simulation = null;
  }

  void _handleDragStart(DragStartDetails details) {
    _startScroll(details: details);
  }

  void _startScroll({ DragStartDetails details }) {
    _numberOfInProgressScrolls += 1;
    if (_numberOfInProgressScrolls == 1) {
      dispatchOnScrollStart();
      new ScrollNotification(
        scrollable: this,
        kind: ScrollNotificationKind.started,
        details: details
      ).dispatch(context);
    }
  }

  /// Calls the onScrollStart callback.
  ///
  /// Subclasses can override this method to hook the scroll start callback.
  void dispatchOnScrollStart() {
    assert(_numberOfInProgressScrolls == 1);
    if (config.onScrollStart != null)
      config.onScrollStart(_scrollOffset);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    scrollBy(pixelOffsetToScrollOffset(details.primaryDelta), details: details);
  }

  void _handleDragEnd(DragEndDetails details) {
    final double scrollVelocity = pixelDeltaToScrollOffset(details.velocity.pixelsPerSecond);
    fling(scrollVelocity).then<Null>((Null value) {
      _endScroll(details: details);
    });
  }

  // Used for state changes that sometimes occur during a build phase. If so,
  // we skip calling setState, as the changes will apply to the next build.
  // TODO(ianh): This is ugly and hopefully temporary. Ideally this won't be
  // needed after Scrollable is rewritten.
  void _setStateMaybeDuringBuild(VoidCallback fn) {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      fn();
    } else {
      setState(fn);
    }
  }

  void _endScroll({ DragEndDetails details }) {
    _numberOfInProgressScrolls -= 1;
    if (_numberOfInProgressScrolls == 0) {
      _simulation = null;
      if (_scrollUnderway && mounted) {
        // If the scroll hasn't already stopped because we've hit a clamped
        // edge or the controller stopped animating, then rebuild the Scrollable
        // with the IgnorePointer widget turned off.
        _setStateMaybeDuringBuild(() {
          _scrollUnderway = false;
        });
      }
      dispatchOnScrollEnd();
      if (mounted) {
        new ScrollNotification(
          scrollable: this,
          kind: ScrollNotificationKind.ended,
          details: details
        ).dispatch(context);
      }
    }
  }

  /// Calls the dispatchOnScrollEnd callback.
  ///
  /// Subclasses can override this method to hook the scroll end callback.
  void dispatchOnScrollEnd() {
    assert(_numberOfInProgressScrolls == 0);
    if (config.onScrollEnd != null)
      config.onScrollEnd(_scrollOffset);
  }

  final GlobalKey<RawGestureDetectorState> _gestureDetectorKey = new GlobalKey<RawGestureDetectorState>();

  @override
  Widget build(BuildContext context) {
    return new RawGestureDetector(
      key: _gestureDetectorKey,
      gestures: buildGestureDetectors(),
      behavior: HitTestBehavior.opaque,
      child: new IgnorePointer(
        ignoring: _scrollUnderway,
        child: buildContent(context)
      )
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
            VerticalDragGestureRecognizer: (VerticalDragGestureRecognizer recognizer) {  // ignore: map_value_type_not_assignable, https://github.com/flutter/flutter/issues/5771
              return (recognizer ??= new VerticalDragGestureRecognizer())
                ..onDown = _handleDragDown
                ..onStart = _handleDragStart
                ..onUpdate = _handleDragUpdate
                ..onEnd = _handleDragEnd;
            }
          };
        case Axis.horizontal:
          return <Type, GestureRecognizerFactory>{
            HorizontalDragGestureRecognizer: (HorizontalDragGestureRecognizer recognizer) {  // ignore: map_value_type_not_assignable, https://github.com/flutter/flutter/issues/5771
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

  /// Calls the widget's [builder] by default.
  ///
  /// Subclasses can override this method to build the interior of their
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
  Widget buildContent(BuildContext context) {
    assert(config.builder != null);
    return config.builder(context, this);
  }
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

/// Indicates that a scrollable descendant is scrolling.
///
/// See also:
///
/// * [NotificationListener].
class ScrollNotification extends Notification {
  /// Creates a notification about scrolling.
  ScrollNotification({ this.scrollable, this.kind, dynamic details }) : _details = details {
    assert(scrollable != null);
    assert(kind != null);
    assert(details == null
        || (kind == ScrollNotificationKind.started && details is DragStartDetails)
        || (kind == ScrollNotificationKind.updated && details is DragUpdateDetails)
        || (kind == ScrollNotificationKind.ended && details is DragEndDetails));
  }

  /// Indicates if we're at the start, middle, or end of a scroll.
  final ScrollNotificationKind kind;

  /// The scrollable that scrolled.
  final ScrollableState scrollable;

  /// The details from the underlying [DragGestureRecognizer] gesture, if the
  /// notification ultimately came from a [DragGestureRecognizer.onStart]
  /// handler; otherwise null.
  DragStartDetails get dragStartDetails => kind == ScrollNotificationKind.started ? _details : null;

  /// The details from the underlying [DragGestureRecognizer] gesture, if the
  /// notification ultimately came from a [DragGestureRecognizer.onUpdate]
  /// handler; otherwise null.
  DragUpdateDetails get dragUpdateDetails => kind == ScrollNotificationKind.updated ? _details : null;

  /// The details from the underlying [DragGestureRecognizer] gesture, if the
  /// notification ultimately came from a [DragGestureRecognizer.onEnd]
  /// handler; otherwise null.
  DragEndDetails get dragEndDetails => kind == ScrollNotificationKind.ended ? _details : null;

  final dynamic _details;

  /// The number of scrollable widgets that have already received this
  /// notification. Typically listeners only respond to notifications
  /// with depth = 0.
  int get depth => _depth;
  int _depth = 0;

  @override
  bool visitAncestor(Element element) {
    if (element is StatefulElement && element.state is ScrollableState)
      _depth += 1;
    return super.visitAncestor(element);
  }
}

/// A simple scrolling widget that has a single child.
///
/// Use this widget if you are not worried about offscreen widgets consuming
/// resources.
///
/// See also:
///
///  * [Block], if your single child is a [Column].
///  * [ScrollableList], if you have many identically-sized children.
///  * [PageableList], if you have children that each take the entire screen.
///  * [ScrollableGrid], if your children are in a grid pattern.
///  * [LazyBlock], if you have many children of varying sizes.
class ScrollableViewport extends StatelessWidget {
  /// Creates a simple scrolling widget that has a single child.
  ///
  /// The [scrollDirection] and [scrollAnchor] arguments must not be null.
  ScrollableViewport({
    Key key,
    this.initialScrollOffset,
    this.scrollDirection: Axis.vertical,
    this.scrollAnchor: ViewportAnchor.start,
    this.onScrollStart,
    this.onScroll,
    this.onScrollEnd,
    this.snapOffsetCallback,
    this.scrollableKey,
    this.child
  }) : super(key: key) {
    assert(scrollDirection != null);
    assert(scrollAnchor != null);
  }

  // Warning: keep the dartdoc comments that follow in sync with the copies in
  // Scrollable, LazyBlock, ScrollableLazyList, ScrollableList, and
  // ScrollableGrid. And see: https://github.com/dart-lang/dartdoc/issues/1161.

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

  /// The key for the Scrollable created by this widget.
  final Key scrollableKey;

  /// The widget that will be scrolled. It will become the child of a Scrollable.
  final Widget child;

  Widget _buildViewport(BuildContext context, ScrollableState state) {
    return new Viewport(
      paintOffset: state.scrollOffsetToPixelDelta(state.scrollOffset),
      mainAxis: scrollDirection,
      anchor: scrollAnchor,
      onPaintOffsetUpdateNeeded: (ViewportDimensions dimensions) {
        final double contentExtent = scrollDirection == Axis.vertical ? dimensions.contentSize.height : dimensions.contentSize.width;
        final double containerExtent = scrollDirection == Axis.vertical ? dimensions.containerSize.height : dimensions.containerSize.width;
        state.handleExtentsChanged(contentExtent, containerExtent);
        return state.scrollOffsetToPixelDelta(state.scrollOffset);
      },
      child: child
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget result = new Scrollable(
      key: scrollableKey,
      initialScrollOffset: initialScrollOffset,
      scrollDirection: scrollDirection,
      scrollAnchor: scrollAnchor,
      onScrollStart: onScrollStart,
      onScroll: onScroll,
      onScrollEnd: onScrollEnd,
      snapOffsetCallback: snapOffsetCallback,
      builder: _buildViewport
    );
    return ScrollConfiguration.wrap(context, result);
  }
}

/// A scrolling list of variably-sized children.
///
/// Useful when you have a small, fixed number of children that you wish to
/// arrange in a block layout and that might exceed the height of its container
/// (and therefore need to scroll).
///
/// If you have a large number of children, or if you always expect this to need
/// to scroll, consider using [LazyBlock] (if the children have variable height)
/// or [ScrollableList] (if the children all have the same fixed height), as
/// they avoid doing work for children that are not visible.
///
/// This widget is implemented using [ScrollableViewport] and [BlockBody]. If
/// you have a single child, consider using [ScrollableViewport] directly.
///
/// See also:
///
///  * [LazyBlock], if you have many children with varying heights.
///  * [ScrollableList], if all your children are the same height.
///  * [ScrollableViewport], if you only have one child.
class Block extends StatelessWidget {
  /// Creates a scrollable array of children.
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

  /// The children, all of which are materialized.
  final List<Widget> children;

  /// The amount of space by which to inset the children inside the viewport.
  final EdgeInsets padding;

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
      scrollableKey: scrollableKey,
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
