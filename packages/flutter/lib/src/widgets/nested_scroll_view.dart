// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'basic.dart';
import 'framework.dart';
import 'primary_scroll_controller.dart';
import 'scroll_activity.dart';
import 'scroll_controller.dart';
import 'scroll_interfaces.dart';
import 'scroll_metrics.dart';
import 'scroll_notification.dart';
import 'scroll_physics.dart';
import 'scroll_position.dart';
import 'scroll_view.dart';
import 'sliver.dart';
import 'ticker_provider.dart';

typedef ScrollActivity _NestedScrollActivityGetter(_NestedScrollPosition position);

typedef List<Widget> NestedScrollViewOuterSliversBuilder(BuildContext context, bool innerBoxIsScrolled);

class NestedScrollView extends StatefulWidget {
  NestedScrollView({
    Key key,
    this.scrollDirection: Axis.vertical,
    this.reverse: false,
    this.physics,
    @required this.outerSliverBuilder,
    @required this.innerBox,
  }) : super(key: key) {
    assert(scrollDirection != null);
    assert(reverse != null);
    assert(outerSliverBuilder != null);
    assert(innerBox != null);
  }

  // TODO(ianh): we should expose a controller so you can call animateTo, etc.

  final Axis scrollDirection;

  final bool reverse;

  final ScrollPhysics physics;

  final NestedScrollViewOuterSliversBuilder outerSliverBuilder;

  final Widget innerBox;

  double get initialScrollOffset => 0.0;

  @protected
  List<Widget> buildSlivers(BuildContext context, ScrollController innerController, bool innerBoxIsScrolled) {
    final List<Widget> slivers = <Widget>[];
    slivers.addAll(outerSliverBuilder(context, innerBoxIsScrolled));
    slivers.add(new SliverFillRemaining(
      child: new PrimaryScrollController(
        controller: innerController,
        child: innerBox,
      ),
    ));
    return slivers;
  }

  @override
  _NestedScrollViewState createState() => new _NestedScrollViewState();
}

class _NestedScrollViewState extends State<NestedScrollView> {
  @override
  void initState() {
    super.initState();
    _outerController = new _NestedScrollController(this, debugLabel: 'outer');
    _innerController = new _NestedScrollController(this, debugLabel: 'inner');
  }

  ScrollController get outerController => _outerController;
  _NestedScrollController _outerController;

  @protected
  _NestedScrollPosition get _outerPosition {
    if (!_outerController.hasClients)
      return null;
    return _outerController.nestedPositions.single;
  }

  ScrollController get innerController => _innerController;
  _NestedScrollController _innerController;

  @protected
  Iterable<_NestedScrollPosition> get _innerPositions {
    return _innerController.nestedPositions;
  }

  bool get hasScrolledInnerBox {
    for (_NestedScrollPosition position in _innerPositions) {
      if (position.pixels > position.minScrollExtent)
        return true;
    }
    return false;
  }

  ScrollDirection get userScrollDirection => _userScrollDirection;
  ScrollDirection _userScrollDirection = ScrollDirection.idle;

  void updateUserScrollDirection(ScrollDirection value) {
    assert(value != null);
    if (userScrollDirection == value)
      return;
    _userScrollDirection = value;
    _outerPosition.reportScrollDirection(value);
    for (_NestedScrollPosition position in _innerPositions)
      position.reportScrollDirection(value);
  }

  _NestedDragScrollCoordinator _currentDrag;

  void beginActivity(ScrollActivity newOuterActivity, _NestedScrollActivityGetter newInnerActivityCallback) {
    _outerPosition.beginActivity(newOuterActivity);
    bool scrolling = newOuterActivity.isScrolling;
    for (_NestedScrollPosition position in _innerPositions) {
      final ScrollActivity newInnerActivity = newInnerActivityCallback(position);
      position.beginActivity(newInnerActivity);
      scrolling = scrolling && newInnerActivity.isScrolling;
    }
    if (_currentDrag != null)
      _currentDrag.dispose();
    if (!scrolling)
      updateUserScrollDirection(ScrollDirection.idle);
  }

  void goIdle() {
    beginActivity(
      new IdleScrollActivity(_outerPosition),
      (_NestedScrollPosition position) => new IdleScrollActivity(position),
    );
  }

  void goBallistic(double velocity) {
    beginActivity(
      createOuterBallisticScrollActivity(velocity),
      (_NestedScrollPosition position) => createInnerBallisticScrollActivity(position, velocity),
    );
  }

  @protected
  ScrollActivity createOuterBallisticScrollActivity(double velocity) {
    // TODO(ianh): Refactor so this doesn't need to poke at the internals of the
    // other classes here (e.g. calling through _outerPosition.physics)

    // This function creates a ballistic scroll for the outer scrollable.
    //
    // It assumes that the outer scrollable can't be overscrolled, and sets up a
    // ballistic scroll over the combined space of the innerPositions and the
    // outerPosition.

    // First we must pick a representative inner position that we will care
    // about. This is somewhat arbitrary. Ideally we'd pick the one that is "in
    // the center" but there isn't currently a good way to do that so we
    // arbitrarily pick the one that is the furthest away from the infinity we
    // are heading towards.
    _NestedScrollPosition innerPosition;
    if (velocity != 0.0) {
      for (_NestedScrollPosition position in _innerPositions) {
        if (innerPosition != null) {
          if (velocity > 0.0) {
            if (innerPosition.pixels < position.pixels)
              continue;
          } else {
            assert(velocity < 0.0);
            if (innerPosition.pixels > position.pixels)
              continue;
          }
        }
        innerPosition = position;
      }
    }

    if (innerPosition == null) {
      // It's either just us or a velocity=0 situation.
      return _outerPosition.createBallisticScrollActivity(
        _outerPosition.physics.createBallisticSimulation(_outerPosition, velocity),
        mode: _NestedBallisticScrollActivityMode.independent,
      );
    }

    final _NestedScrollingSituation situationReport = _computeSituationReport(innerPosition, velocity);

    return _outerPosition.createBallisticScrollActivity(
      _outerPosition.physics.createBallisticSimulation(situationReport, velocity),
      mode: _NestedBallisticScrollActivityMode.outer,
      minRange: situationReport.minRange,
      maxRange: situationReport.maxRange,
      correctionOffset: situationReport.correctionOffset,
    );
  }

  @protected
  ScrollActivity createInnerBallisticScrollActivity(_NestedScrollPosition position, double velocity) {
    return position.createBallisticScrollActivity(
      position.physics.createBallisticSimulation(
        velocity == 0 ? position : _computeSituationReport(position, velocity),
        velocity,
      ),
      mode: _NestedBallisticScrollActivityMode.inner,
    );
  }

  _NestedScrollingSituation _computeSituationReport(_NestedScrollPosition innerPosition, double velocity) {
    assert(innerPosition != null);
    double pixels, minRange, maxRange, correctionOffset, extra;
    if (innerPosition.pixels == innerPosition.minScrollExtent) {
      pixels = _outerPosition.pixels.clamp(_outerPosition.minScrollExtent, _outerPosition.maxScrollExtent); // TODO(ianh): gracefully handle out-of-range outer positions
      minRange = _outerPosition.minScrollExtent;
      maxRange = _outerPosition.maxScrollExtent;
      assert(minRange <= maxRange);
      correctionOffset = 0.0;
      extra = 0.0;
    } else {
      assert(innerPosition.pixels != innerPosition.minScrollExtent);
      if (innerPosition.pixels < innerPosition.minScrollExtent) {
        pixels = innerPosition.pixels - innerPosition.minScrollExtent + _outerPosition.minScrollExtent;
      } else {
        assert(innerPosition.pixels > innerPosition.minScrollExtent);
        pixels = innerPosition.pixels - innerPosition.minScrollExtent + _outerPosition.maxScrollExtent;
      }
      if ((velocity > 0.0) && (innerPosition.pixels > innerPosition.minScrollExtent)) {
        // This handles going forward (fling up) and inner list is scrolled past
        // zero. We want to grab the extra pixels immediately to shrink.
        extra = _outerPosition.maxScrollExtent - _outerPosition.pixels;
        assert(extra >= 0.0);
        minRange = pixels;
        maxRange = pixels + extra;
        assert(minRange <= maxRange);
        correctionOffset = _outerPosition.pixels - pixels;
      } else if ((velocity < 0.0) && (innerPosition.pixels < innerPosition.minScrollExtent)) {
        // This handles going backward (fling down) and inner list is
        // underscrolled. We want to grab the extra pixels immediately to grow.
        extra = _outerPosition.pixels - _outerPosition.minScrollExtent;
        assert(extra >= 0.0);
        minRange = pixels - extra;
        maxRange = pixels;
        assert(minRange <= maxRange);
        correctionOffset = _outerPosition.pixels - pixels;
      } else {
        // This handles going forward (fling up) and inner list is
        // underscrolled, OR, going backward (fling down) and inner list is
        // scrolled past zero. We want to skip the pixels we don't need to grow
        // or shrink over.
        if (velocity > 0.0) {
          // shrinking
          extra = _outerPosition.minScrollExtent - _outerPosition.pixels;
        } else {
          assert(velocity < 0.0);
          // growing
          extra = _outerPosition.pixels - (_outerPosition.maxScrollExtent - _outerPosition.minScrollExtent);
        }
        assert(extra <= 0.0);
        minRange = _outerPosition.minScrollExtent;
        maxRange = _outerPosition.maxScrollExtent + extra;
        assert(minRange <= maxRange);
        correctionOffset = 0.0;
      }
    }
    return new _NestedScrollingSituation(
      minScrollExtent: _outerPosition.minScrollExtent,
      maxScrollExtent: _outerPosition.maxScrollExtent + innerPosition.maxScrollExtent - innerPosition.minScrollExtent + extra,
      pixels: pixels,
      viewportDimension: _outerPosition.viewportDimension,
      axisDirection: _outerPosition.axisDirection,
      minRange: minRange,
      maxRange: maxRange,
      correctionOffset: correctionOffset,
    );
  }

  double unnestOffset(double value, _NestedScrollPosition source) {
    if (source == _outerPosition)
      return value.clamp(_outerPosition.minScrollExtent, _outerPosition.maxScrollExtent);
    if (value < source.minScrollExtent)
      return value - source.minScrollExtent + _outerPosition.minScrollExtent;
    return value - source.minScrollExtent + _outerPosition.maxScrollExtent;
  }

  double nestOffset(double value, _NestedScrollPosition target) {
    if (target == _outerPosition)
      return value.clamp(_outerPosition.minScrollExtent, _outerPosition.maxScrollExtent);
    if (value < _outerPosition.minScrollExtent)
      return value - _outerPosition.minScrollExtent + target.minScrollExtent;
    if (value > _outerPosition.maxScrollExtent)
      return value - _outerPosition.maxScrollExtent + target.minScrollExtent;
    return target.minScrollExtent;
  }

  void updateCanDrag() {
    if (!_outerPosition.haveDimensions)
      return;
    double maxInnerExtent = 0.0;
    for (_NestedScrollPosition position in _innerPositions) {
      if (!position.haveDimensions)
        return;
      maxInnerExtent = math.max(maxInnerExtent, position.maxScrollExtent - position.minScrollExtent);
    }
    _outerPosition.updateCanDrag(maxInnerExtent);
  }

  Future<Null> animateTo(double to, {
    @required Duration duration,
    @required Curve curve,
  }) {
    final DrivenScrollActivity outerActivity = _outerPosition.createAnimateScrollActivity(
      nestOffset(to, _outerPosition),
      duration,
      curve,
    );
    final List<Future<Null>> resultFutures = <Future<Null>>[outerActivity.done];
    beginActivity(
      outerActivity,
      (_NestedScrollPosition position) {
        final DrivenScrollActivity innerActivity = position.createAnimateScrollActivity(
          nestOffset(to, position),
          duration,
          curve,
        );
        resultFutures.add(innerActivity.done);
        return innerActivity;
      },
    );
    return Future.wait<Null>(resultFutures);
  }

  void jumpTo(double to) {
    goIdle();
    _outerPosition.localJumpTo(nestOffset(to, _outerPosition));
    for (_NestedScrollPosition position in _innerPositions)
      position.localJumpTo(nestOffset(to, position));
    goBallistic(0.0);
  }

  void touched() {
    _outerPosition.propagateTouched();
    for (_NestedScrollPosition position in _innerPositions)
      position.propagateTouched();
  }

  Drag beginDrag(DragStartDetails details, VoidCallback dragCancelCallback) {
    final _NestedDragScrollCoordinator result = new _NestedDragScrollCoordinator(
      this,
      details,
      dragCancelCallback,
    );
    beginActivity(
      new _NestedScrollDragActivity(_outerPosition, result),
      (_NestedScrollPosition position) => new _NestedScrollDragActivity(position, result),
    );
    _currentDrag = result;
    return result;
  }

  void scrollByDelta(double offset) {
    assert(offset != 0.0);
    if (_innerPositions.isEmpty) {
      _outerPosition.applyFullDragUpdate(offset);
    } else if (offset > 0.0) {
      // dragging "up"
      // TODO(ianh): prioritize first getting rid of overscroll, and then the
      // outer view, so that the app bar will scroll out of the way asap.
      // Right now we ignore overscroll. This works fine on Android but looks
      // weird on iOS if you fling down then up. The problem is it's not at all
      // clear what this should do when you have multiple inner positions at
      // different levels of overscroll.
      final double innerOffset = _outerPosition.applyClampedDragUpdate(offset);
      if (innerOffset != 0.0) {
        for (_NestedScrollPosition position in _innerPositions)
          position.applyFullDragUpdate(innerOffset);
      }
    } else {
      // dragging "down" - offsets are negative
      // prioritize the inner views, so that the inner content will move before the app bar grows
      double minimumRemainingOffset = 0.0; // it will go negative if it changes
      final List<double> remainingOffsets = <double>[];
      final List<_NestedScrollPosition> innerPositions = _innerPositions.toList();
      for (_NestedScrollPosition position in innerPositions) {
        final double thisRemainingOffset = position.applyClampedDragUpdate(offset);
        minimumRemainingOffset = math.min(minimumRemainingOffset, thisRemainingOffset);
        remainingOffsets.add(thisRemainingOffset);
      }
      if (minimumRemainingOffset != 0.0) {
        final double outerRemainingOffset = _outerPosition.applyClampedDragUpdate(minimumRemainingOffset);
        minimumRemainingOffset = minimumRemainingOffset - outerRemainingOffset;
      }
      // now deal with any overscroll
      for (_NestedScrollPosition position in innerPositions) {
        final double thisRemainingOffset = remainingOffsets.removeAt(0) - minimumRemainingOffset;
        if (thisRemainingOffset < 0.0)
          position.applyFullDragUpdate(thisRemainingOffset);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    updateParent();
  }

  void updateParent() {
    _outerPosition?.setParent(PrimaryScrollController.of(context));
  }

  @override
  void dispose() {
    _currentDrag?.dispose();
    _outerController.dispose();
    _innerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new CustomScrollView(
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      physics: new ClampingScrollPhysics(parent: widget.physics),
      controller: _outerController,
      slivers: widget.buildSlivers(context, _innerController, hasScrolledInnerBox),
    );
  }
}

class _NestedScrollingSituation extends ScrollMetrics {
  _NestedScrollingSituation({
    @required this.minScrollExtent,
    @required this.maxScrollExtent,
    @required this.pixels,
    @required this.viewportDimension,
    @required this.axisDirection,
    @required this.minRange,
    @required this.maxRange,
    @required this.correctionOffset,
  });

  @override
  final double minScrollExtent;

  @override
  final double maxScrollExtent;

  @override
  final double pixels;

  @override
  final double viewportDimension;

  @override
  final AxisDirection axisDirection;

  // The remainder are for outer ballistics logic:

  final double minRange;

  final double maxRange;

  final double correctionOffset;
}

class _NestedScrollController extends ScrollController {
  _NestedScrollController(this.owner, { this.debugLabel });

  final _NestedScrollViewState owner;

  final String debugLabel;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext state,
    ScrollPosition oldPosition,
  ) {
    return new _NestedScrollPosition(
      owner: owner,
      physics: physics,
      state: state,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }

  @override
  void attach(ScrollPosition position) {
    assert(position is _NestedScrollPosition);
    super.attach(position);
    owner.updateParent();
    owner.updateCanDrag();
  }

  Iterable<_NestedScrollPosition> get nestedPositions sync* {
    yield* positions;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (debugLabel != null)
      description.add('debug label: $debugLabel');
  }
}

class _NestedScrollPosition extends ScrollPosition {
  _NestedScrollPosition({
    this.owner,
    this.state,
    this.debugLabel,
    ScrollPhysics physics,
    ScrollPosition oldPosition,
  }) : super(physics: physics, oldPosition: oldPosition) {
    if (pixels == null)
      correctPixels(owner.widget.initialScrollOffset);
    if (_activity == null)
      goIdle();
  }

  final _NestedScrollViewState owner;

  final ScrollContext state;

  final String debugLabel;

  TickerProvider get vsync => state.vsync;

  ScrollController _parent;

  void setParent(ScrollController value) {
    _parent?.detach(this);
    _parent = value;
    _parent?.attach(this);
  }

  @override
  AxisDirection get axisDirection => state.axisDirection;

  @override
  void absorb(ScrollPosition otherPosition) {
    if (otherPosition is! _NestedScrollPosition) {
      super.absorb(otherPosition);
      return;
    }
    final _NestedScrollPosition other = otherPosition;
    assert(other != this);
    assert(other.state == state);
    // TODO(ianh): Code duplication with ScrollIndependentPosition
    super.absorb(other);
    final bool oldIgnorePointer = shouldIgnorePointer;
    assert(_activity == null);
    assert(other._activity != null);
    other._activity.updatePosition(this);
    _activity = other._activity;
    other._activity = null;
    if (other.runtimeType != runtimeType)
      _activity.resetActivity();
    // TODO(ianh): Have _NestedScrollViewState repropagate its shouldIgnorePointer
    if (oldIgnorePointer != shouldIgnorePointer)
      setIgnorePointer(shouldIgnorePointer);
  }

  double applyClampedDragUpdate(double delta) {
    assert(delta != 0.0);
    final double min = delta > 0.0 ? -double.INFINITY : minScrollExtent;
    final double max = delta < 0.0 ? double.INFINITY : maxScrollExtent;
    final double clampedDelta = (pixels + delta).clamp(min, max) - pixels;
    if (clampedDelta == 0.0)
      return delta;
    final double overscroll = physics.applyBoundaryConditions(this, pixels + clampedDelta);
    final double adjustedClampedDelta = clampedDelta - overscroll;
    forcePixels(pixels + adjustedClampedDelta);
    reportScroll(adjustedClampedDelta);
    return delta - adjustedClampedDelta;
  }

  double applyFullDragUpdate(double delta) {
    assert(delta != 0.0);
    final double oldPixels = pixels;
    final double newPixels = pixels + applyPhysicsToUserOffset(delta);
    if (oldPixels == newPixels)
      return 0.0; // delta must have been so small we dropped it during floating point addition
    final double overScroll = physics.applyBoundaryConditions(this, newPixels);
    final double actualNewPixels = newPixels - overScroll;
    if (actualNewPixels != oldPixels) {
      forcePixels(actualNewPixels);
      reportScroll(pixels - oldPixels);
    }
    if (overScroll != 0.0) {
      reportOverscroll(overScroll);
      return overScroll;
    }
    return 0.0;
  }

  @override
  ScrollDirection get userScrollDirection => owner.userScrollDirection;

  ScrollActivity _activity;

  void beginActivity(ScrollActivity newActivity) {
    // TODO(ianh): there's code duplication here. See ScrollIndependentPosition.
    assert(newActivity != null);
    assert(newActivity.position == this);
    bool wasScrolling, oldIgnorePointer;
    if (_activity != null) {
      oldIgnorePointer = _activity.shouldIgnorePointer;
      wasScrolling = _activity.isScrolling;
      if (wasScrolling && !newActivity.isScrolling)
        reportScrollEnd();
      _activity.dispose();
    } else {
      oldIgnorePointer = false;
      wasScrolling = false;
    }
    _activity = newActivity;
    if (!wasScrolling && _activity.isScrolling)
      reportScrollStart();
    if (oldIgnorePointer != shouldIgnorePointer)
      state.setIgnorePointer(shouldIgnorePointer);
  }

  DrivenScrollActivity createAnimateScrollActivity(double to, Duration duration, Curve curve) {
    return new DrivenScrollActivity(
      this,
      from: pixels,
      to: to,
      duration: duration,
      curve: curve,
      vsync: vsync,
    );
  }

  // This is called by activities when they finish their work.
  @override
  void goIdle() {
    beginActivity(new IdleScrollActivity(this));
  }

  // This is called by activities when they finish their work and want to go ballistic.
  @override
  void goBallistic(double velocity) {
    Simulation simulation;
    if (velocity != 0.0 || outOfRange)
      simulation = physics.createBallisticSimulation(this, velocity);
    beginActivity(createBallisticScrollActivity(
      simulation,
      mode: _NestedBallisticScrollActivityMode.independent,
    ));
  }

  ScrollActivity createBallisticScrollActivity(Simulation simulation, {
    @required _NestedBallisticScrollActivityMode mode,
    double minRange,
    double maxRange,
    double correctionOffset,
  }) {
    if (simulation == null)
      return new IdleScrollActivity(this);
    assert(mode != null);
    switch (mode) {
      case _NestedBallisticScrollActivityMode.outer:
        assert(minRange != null);
        assert(maxRange != null);
        assert(correctionOffset != null);
        if (minRange == maxRange)
          return new IdleScrollActivity(this);
        return new _NestedOuterBallisticScrollActivity(owner, this, minRange, maxRange, correctionOffset, simulation, state.vsync);
      case _NestedBallisticScrollActivityMode.inner:
        return new _NestedInnerBallisticScrollActivity(owner, this, simulation, state.vsync);
      case _NestedBallisticScrollActivityMode.independent:
        return new BallisticScrollActivity(this, simulation, state.vsync);
    }
    return null;
  }

  @override
  Future<Null> animateTo(double to, {
    @required Duration duration,
    @required Curve curve,
  }) {
    return owner.animateTo(owner.unnestOffset(to, this), duration: duration, curve: curve);
  }

  @override
  void jumpTo(double value) {
    return owner.jumpTo(owner.unnestOffset(value, this));
  }

  @override
  void jumpToWithoutSettling(double value) {
    assert(false);
  }

  void localJumpTo(double value) {
    if (pixels != value) {
      final double oldPixels = pixels;
      forcePixels(value);
      reportScrollStart();
      reportScroll(pixels - oldPixels);
      reportScrollEnd();
    }
  }

  @override
  void applyNewDimensions() {
    _activity.applyNewDimensions();
    owner.updateCanDrag();
  }

  void updateCanDrag(double totalExtent) {
    state.setCanDrag(totalExtent > (viewportDimension - maxScrollExtent) || minScrollExtent != maxScrollExtent);
  }

  @override
  void touched() {
    owner.touched();
  }

  void propagateTouched() {
    _activity.touched();
  }

  @override
  Drag beginDrag(DragStartDetails details, VoidCallback dragCancelCallback) {
    return owner.beginDrag(details, dragCancelCallback);
  }

  @override
  void updateUserScrollDirection(ScrollDirection value) {
    assert(false);
    owner.updateUserScrollDirection(value);
  }

  @override
  void reportScrollStart() {
    _activity.dispatchScrollStartNotification(cloneMetrics(), state.notificationContext);
  }

  @override
  void reportScroll(double delta) {
    _activity.dispatchScrollUpdateNotification(cloneMetrics(), state.notificationContext, delta);
  }

  @override
  void reportScrollEnd() {
    _activity.dispatchScrollEndNotification(cloneMetrics(), state.notificationContext);
  }

  @override
  void reportOverscroll(double value) {
    assert(_activity.isScrolling);
    _activity.dispatchOverscrollNotification(cloneMetrics(), state.notificationContext, value);
  }

  @override
  void reportScrollDirection(ScrollDirection direction) {
    new UserScrollNotification(metrics: cloneMetrics(), context: state.notificationContext, direction: direction)
      .dispatch(state.notificationContext);
  }

  bool get shouldIgnorePointer => _activity?.shouldIgnorePointer;

  void setIgnorePointer(bool value) {
    state.setIgnorePointer(value);
  }

  @override
  void dispose() {
    _activity?.dispose();
    _parent?.detach(this);
    super.dispose();
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (debugLabel != null)
      description.add('debug label: $debugLabel');
  }
}

class _NestedDragScrollCoordinator implements Drag {
  // TODO(ianh): There's a lot of code duplication with DragScrollActivity here.
  _NestedDragScrollCoordinator(
    this.owner,
    DragStartDetails details,
    this.onDragCanceled,
  ) : _lastDetails = details;

  final _NestedScrollViewState owner;

  final VoidCallback onDragCanceled;

  dynamic get lastDetails => _lastDetails;
  dynamic _lastDetails;

  bool get _reversed {
    assert(owner?._outerPosition?.axisDirection != null);
    switch (owner._outerPosition.axisDirection) {
      case AxisDirection.up:
      case AxisDirection.left:
        return true;
      case AxisDirection.down:
      case AxisDirection.right:
        return false;
    }
    return null;
  }

  @override
  void update(DragUpdateDetails details) {
    assert(details.primaryDelta != null);
    _lastDetails = details;
    double offset = details.primaryDelta;
    if (offset == 0.0)
      return;
    if (_reversed) // e.g. an AxisDirection.up scrollable
      offset = -offset;
    owner.updateUserScrollDirection(offset > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
    owner.scrollByDelta(-offset);
  }

  @override
  void end(DragEndDetails details) {
    assert(details.primaryVelocity != null);
    double velocity = details.primaryVelocity;
    if (_reversed) // e.g. an AxisDirection.up scrollable
      velocity = -velocity;
    _lastDetails = details;
    // We negate the velocity here because if the touch is moving downwards,
    // the scroll has to move upwards. It's the same reason that update()
    // above negates the delta before applying it to the scroll offset.
    owner.goBallistic(-velocity);
  }

  @override
  void cancel() {
    owner.goBallistic(0.0);
  }

  void touched() { }

  void dispose() {
    _lastDetails = null;
    if (onDragCanceled != null)
      onDragCanceled();
  }
}

class _NestedScrollDragActivity extends ScrollActivity {
  // TODO(ianh): There's a lot of code duplication with DragScrollActivity here.
  _NestedScrollDragActivity(
    ScrollPosition position,
    this.coordinator,
  ) : super(position);

  final _NestedDragScrollCoordinator coordinator;

  @override
  void dispatchScrollStartNotification(ScrollMetrics metrics, BuildContext context) {
    assert(coordinator.lastDetails is DragStartDetails);
    new ScrollStartNotification(metrics: metrics, context: context, dragDetails: coordinator.lastDetails).dispatch(context);
  }

  @override
  void dispatchScrollUpdateNotification(ScrollMetrics metrics, BuildContext context, double scrollDelta) {
    assert(coordinator.lastDetails is DragUpdateDetails);
    new ScrollUpdateNotification(metrics: metrics, context: context, scrollDelta: scrollDelta, dragDetails: coordinator.lastDetails).dispatch(context);
  }

  @override
  void dispatchOverscrollNotification(ScrollMetrics metrics, BuildContext context, double overscroll) {
    assert(coordinator.lastDetails is DragUpdateDetails);
    new OverscrollNotification(metrics: metrics, context: context, overscroll: overscroll, dragDetails: coordinator.lastDetails).dispatch(context);
  }

  @override
  void dispatchScrollEndNotification(ScrollMetrics metrics, BuildContext context) {
    // We might not have DragEndDetails yet if we're being called from beginActivity.
    new ScrollEndNotification(
      metrics: metrics,
      context: context,
      dragDetails: coordinator.lastDetails is DragEndDetails ? coordinator.lastDetails : null
    ).dispatch(context);
  }

  @override
  bool get shouldIgnorePointer => true;

  @override
  bool get isScrolling => true;
}

enum _NestedBallisticScrollActivityMode { outer, inner, independent }

class _NestedInnerBallisticScrollActivity extends BallisticScrollActivity {
  _NestedInnerBallisticScrollActivity(
    this.owner,
    _NestedScrollPosition position,
    Simulation simulation,
    TickerProvider vsync,
  ) : super(position, simulation, vsync);

  final _NestedScrollViewState owner;

  @override
  _NestedScrollPosition get position => super.position;

  @override
  void resetActivity() {
    position.beginActivity(owner.createInnerBallisticScrollActivity(position, velocity));
  }

  @override
  void applyNewDimensions() {
    position.beginActivity(owner.createInnerBallisticScrollActivity(position, velocity));
  }

  @override
  bool applyMoveTo(double value) {
    return super.applyMoveTo(owner.nestOffset(value, position));
  }
}

class _NestedOuterBallisticScrollActivity extends BallisticScrollActivity {
  _NestedOuterBallisticScrollActivity(
    this.owner,
    _NestedScrollPosition position,
    this.minRange,
    this.maxRange,
    this.correctionOffset,
    Simulation simulation,
    TickerProvider vsync,
  ) : super(position, simulation, vsync) {
    assert(minRange != maxRange);
    assert(maxRange > minRange);
  }

  final _NestedScrollViewState owner;

  final double minRange;
  final double maxRange;
  final double correctionOffset;

  @override
  _NestedScrollPosition get position => super.position;

  @override
  void resetActivity() {
    position.beginActivity(owner.createOuterBallisticScrollActivity(velocity));
  }

  @override
  void applyNewDimensions() {
    position.beginActivity(owner.createOuterBallisticScrollActivity(velocity));
  }

  @override
  bool applyMoveTo(double value) {
    bool done = false;
    if (velocity > 0.0) {
      if (value < minRange)
        return true;
      if (value > maxRange) {
        value = maxRange;
        done = true;
      }
    } else if (velocity < 0.0) {
      assert(velocity < 0.0);
      if (value > maxRange)
        return true;
      if (value < minRange) {
        value = minRange;
        done = true;
      }
    } else {
      value = value.clamp(minRange, maxRange);
      done = true;
    }
    final bool result = super.applyMoveTo(value + correctionOffset);
    assert(result); // since we tried to pass an in-range value, it shouldn't ever overflow
    return !done;
  }

  @override
  String toString() {
    return '$runtimeType($minRange .. $maxRange; correcting by $correctionOffset)';
  }
}
