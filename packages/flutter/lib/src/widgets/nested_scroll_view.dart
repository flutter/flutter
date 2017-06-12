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
import 'scroll_context.dart';
import 'scroll_controller.dart';
import 'scroll_metrics.dart';
import 'scroll_physics.dart';
import 'scroll_position.dart';
import 'scroll_view.dart';
import 'sliver.dart';
import 'ticker_provider.dart';

/// Signature used by [NestedScrollView] for building its header.
typedef List<Widget> NestedScrollViewHeaderSliversBuilder(BuildContext context, bool innerBoxIsScrolled);

class NestedScrollView extends StatefulWidget {
  NestedScrollView({
    Key key,
    this.scrollDirection: Axis.vertical,
    this.reverse: false,
    this.physics,
    @required this.headerSliverBuilder,
    @required this.body,
  }) : super(key: key) {
    assert(scrollDirection != null);
    assert(reverse != null);
    assert(headerSliverBuilder != null);
    assert(body != null);
  }

  // TODO(ianh): we should expose a controller so you can call animateTo, etc.

  final Axis scrollDirection;

  final bool reverse;

  final ScrollPhysics physics;

  final NestedScrollViewHeaderSliversBuilder headerSliverBuilder;

  final Widget body;

  double get initialScrollOffset => 0.0;

  @protected
  List<Widget> buildSlivers(BuildContext context, ScrollController innerController, bool bodyIsScrolled) {
    final List<Widget> slivers = <Widget>[];
    slivers.addAll(headerSliverBuilder(context, bodyIsScrolled));
    slivers.add(new SliverFillRemaining(
      child: new PrimaryScrollController(
        controller: innerController,
        child: body,
      ),
    ));
    return slivers;
  }

  @override
  _NestedScrollViewState createState() => new _NestedScrollViewState();
}

class _NestedScrollViewState extends State<NestedScrollView> {
  _NestedScrollCoorindator _coordinator;

  @override
  void initState() {
    super.initState();
    _coordinator = new _NestedScrollCoorindator(context, widget.initialScrollOffset);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _coordinator.updateParent();
  }

  @override
  void dispose() {
    _coordinator.dispose();
    _coordinator = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new CustomScrollView(
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      physics: new ClampingScrollPhysics(parent: widget.physics),
      controller: _coordinator._outerController,
      slivers: widget.buildSlivers(context, _coordinator._innerController, _coordinator.hasScrolledBody),
    );
  }
}

class _NestedScrollMetrics extends FixedScrollMetrics {
  _NestedScrollMetrics({
    @required double minScrollExtent,
    @required double maxScrollExtent,
    @required double pixels,
    @required double viewportDimension,
    @required AxisDirection axisDirection,
    @required this.minRange,
    @required this.maxRange,
    @required this.correctionOffset,
  }) : super(
    minScrollExtent: minScrollExtent,
    maxScrollExtent: maxScrollExtent,
    pixels: pixels,
    viewportDimension: viewportDimension,
    axisDirection: axisDirection,
  );

  final double minRange;

  final double maxRange;

  final double correctionOffset;
}

typedef ScrollActivity _NestedScrollActivityGetter(_NestedScrollPosition position);

class _NestedScrollCoorindator implements ScrollActivityDelegate {
  _NestedScrollCoorindator(this._context, double initialScrollOffset) {
    _outerController = new _NestedScrollController(this, initialScrollOffset: initialScrollOffset, debugLabel: 'outer');
    _innerController = new _NestedScrollController(this, initialScrollOffset: initialScrollOffset, debugLabel: 'inner');
  }

  final BuildContext _context;
  _NestedScrollController _outerController;
  _NestedScrollController _innerController;

  _NestedScrollPosition get _outerPosition {
    if (!_outerController.hasClients)
      return null;
    return _outerController.nestedPositions.single;
  }

  Iterable<_NestedScrollPosition> get _innerPositions {
    return _innerController.nestedPositions;
  }

  bool get hasScrolledBody {
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
    _outerPosition.didUpdateScrollDirection(value);
    for (_NestedScrollPosition position in _innerPositions)
      position.didUpdateScrollDirection(value);
  }

  ScrollDragController _currentDrag;

  void beginActivity(ScrollActivity newOuterActivity, _NestedScrollActivityGetter innerActivityGetter) {
    _outerPosition.beginActivity(newOuterActivity);
    bool scrolling = newOuterActivity.isScrolling;
    for (_NestedScrollPosition position in _innerPositions) {
      final ScrollActivity newInnerActivity = innerActivityGetter(position);
      position.beginActivity(newInnerActivity);
      scrolling = scrolling && newInnerActivity.isScrolling;
    }
    _currentDrag?.dispose();
    _currentDrag = null;
    if (!scrolling)
      updateUserScrollDirection(ScrollDirection.idle);
  }

  @override
  AxisDirection get axisDirection => _outerPosition.axisDirection;

  static IdleScrollActivity _createIdleScrollActivity(_NestedScrollPosition position) {
    return new IdleScrollActivity(position);
  }

  @override
  void goIdle() {
    beginActivity(_createIdleScrollActivity(_outerPosition), _createIdleScrollActivity);
  }

  @override
  void goBallistic(double velocity) {
    beginActivity(
      createOuterBallisticScrollActivity(velocity),
      (_NestedScrollPosition position) => createInnerBallisticScrollActivity(position, velocity),
    );
  }

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

    final _NestedScrollMetrics metrics = _getMetrics(innerPosition, velocity);

    return _outerPosition.createBallisticScrollActivity(
      _outerPosition.physics.createBallisticSimulation(metrics, velocity),
      mode: _NestedBallisticScrollActivityMode.outer,
      metrics: metrics,
    );
  }

  @protected
  ScrollActivity createInnerBallisticScrollActivity(_NestedScrollPosition position, double velocity) {
    return position.createBallisticScrollActivity(
      position.physics.createBallisticSimulation(
        velocity == 0 ? position : _getMetrics(position, velocity),
        velocity,
      ),
      mode: _NestedBallisticScrollActivityMode.inner,
    );
  }

  _NestedScrollMetrics _getMetrics(_NestedScrollPosition innerPosition, double velocity) {
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
    return new _NestedScrollMetrics(
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
    final DrivenScrollActivity outerActivity = _outerPosition.createDrivenScrollActivity(
      nestOffset(to, _outerPosition),
      duration,
      curve,
    );
    final List<Future<Null>> resultFutures = <Future<Null>>[outerActivity.done];
    beginActivity(
      outerActivity,
      (_NestedScrollPosition position) {
        final DrivenScrollActivity innerActivity = position.createDrivenScrollActivity(
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

  @override
  double setPixels(double newPixels) {
    assert(false);
    return 0.0;
  }

  void didTouch() {
    _outerPosition._propagateTouched();
    for (_NestedScrollPosition position in _innerPositions)
      position._propagateTouched();
  }

  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    final ScrollDragController drag = new ScrollDragController(
      delegate: this,
      details: details,
      onDragCanceled: dragCancelCallback,
    );
    beginActivity(
      new DragScrollActivity(_outerPosition, drag),
      (_NestedScrollPosition position) => new DragScrollActivity(position, drag),
    );
    assert(_currentDrag == null);
    _currentDrag = drag;
    return drag;
  }

  @override
  void applyUserOffset(double delta) {
    updateUserScrollDirection(delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
    assert(delta != 0.0);
    if (_innerPositions.isEmpty) {
      _outerPosition.applyFullDragUpdate(delta);
    } else if (delta < 0.0) {
      // dragging "up"
      // TODO(ianh): prioritize first getting rid of overscroll, and then the
      // outer view, so that the app bar will scroll out of the way asap.
      // Right now we ignore overscroll. This works fine on Android but looks
      // weird on iOS if you fling down then up. The problem is it's not at all
      // clear what this should do when you have multiple inner positions at
      // different levels of overscroll.
      final double innerDelta = _outerPosition.applyClampedDragUpdate(delta);
      if (innerDelta != 0.0) {
        for (_NestedScrollPosition position in _innerPositions)
          position.applyFullDragUpdate(innerDelta);
      }
    } else {
      // dragging "down" - delta is positive
      // prioritize the inner views, so that the inner content will move before the app bar grows
      double outerDelta = 0.0; // it will go positive if it changes
      final List<double> overscrolls = <double>[];
      final List<_NestedScrollPosition> innerPositions = _innerPositions.toList();
      for (_NestedScrollPosition position in innerPositions) {
        final double overscroll = position.applyClampedDragUpdate(delta);
        outerDelta = math.max(outerDelta, overscroll);
        overscrolls.add(overscroll);
      }
      if (outerDelta != 0.0)
        outerDelta -= _outerPosition.applyClampedDragUpdate(outerDelta);
      // now deal with any overscroll
      for (int i = 0; i < innerPositions.length; ++i) {
        final double remainingDelta = overscrolls[i] - outerDelta;
        if (remainingDelta > 0.0)
          innerPositions[i].applyFullDragUpdate(remainingDelta);
      }
    }
  }

  void updateParent() {
    _outerPosition?.setParent(PrimaryScrollController.of(_context));
  }

  @mustCallSuper
  void dispose() {
    _currentDrag?.dispose();
    _currentDrag = null;
    _outerController.dispose();
    _innerController.dispose();
  }
}

class _NestedScrollController extends ScrollController {
  _NestedScrollController(this.coorindator, {
    double initialScrollOffset: 0.0,
    String debugLabel,
  }) : super(initialScrollOffset: initialScrollOffset, debugLabel: debugLabel);

  final _NestedScrollCoorindator coorindator;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition oldPosition,
  ) {
    return new _NestedScrollPosition(
      coorindator: coorindator,
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }

  @override
  void attach(ScrollPosition position) {
    assert(position is _NestedScrollPosition);
    super.attach(position);
    coorindator.updateParent();
    coorindator.updateCanDrag();
  }

  Iterable<_NestedScrollPosition> get nestedPositions sync* {
    yield* positions;
  }
}

class _NestedScrollPosition extends ScrollPosition implements ScrollActivityDelegate {
  _NestedScrollPosition({
    @required ScrollPhysics physics,
    @required ScrollContext context,
    double initialPixels: 0.0,
    ScrollPosition oldPosition,
    String debugLabel,
    @required this.coorindator,
  }) : super(
    physics: physics,
    context: context,
    oldPosition: oldPosition,
    debugLabel: debugLabel,
  ) {
    if (pixels == null && initialPixels != null)
      correctPixels(initialPixels);
    if (activity == null)
      goIdle();
    assert(activity != null);
  }

  final _NestedScrollCoorindator coorindator;

  TickerProvider get vsync => context.vsync;

  ScrollController _parent;

  void setParent(ScrollController value) {
    _parent?.detach(this);
    _parent = value;
    _parent?.attach(this);
  }

  @override
  AxisDirection get axisDirection => context.axisDirection;

  @override
  void absorb(ScrollPosition other) {
    super.absorb(other);
    activity.updateDelegate(this);
  }

  // Returns the amount of delta that was not used.
  double applyClampedDragUpdate(double delta) {
    assert(delta != 0.0);
    final double min = delta < 0.0 ? -double.INFINITY : minScrollExtent;
    final double max = delta > 0.0 ? double.INFINITY : maxScrollExtent;
    final double oldPixels = pixels;
    final double newPixels = (pixels - delta).clamp(min, max);
    final double clampedDelta = newPixels - pixels;
    if (clampedDelta == 0.0)
      return delta;
    final double overscroll = physics.applyBoundaryConditions(this, newPixels);
    final double actualNewPixels = newPixels - overscroll;
    final double offset = actualNewPixels - oldPixels;
    if (offset != 0.0) {
      forcePixels(actualNewPixels);
      didUpdateScrollPositionBy(offset);
    }
    return delta + offset;
  }

  // Returns the overscroll.
  double applyFullDragUpdate(double delta) {
    assert(delta != 0.0);
    final double oldPixels = pixels;
    final double newPixels = pixels - physics.applyPhysicsToUserOffset(this, delta);
    if (oldPixels == newPixels)
      return 0.0; // delta must have been so small we dropped it during floating point addition
    final double overscroll = physics.applyBoundaryConditions(this, newPixels);
    final double actualNewPixels = newPixels - overscroll;
    if (actualNewPixels != oldPixels) {
      forcePixels(actualNewPixels);
      didUpdateScrollPositionBy(actualNewPixels - oldPixels);
    }
    if (overscroll != 0.0) {
      didOverscrollBy(overscroll);
      return overscroll;
    }
    return 0.0;
  }

  @override
  ScrollDirection get userScrollDirection => coorindator.userScrollDirection;

  DrivenScrollActivity createDrivenScrollActivity(double to, Duration duration, Curve curve) {
    return new DrivenScrollActivity(
      this,
      from: pixels,
      to: to,
      duration: duration,
      curve: curve,
      vsync: vsync,
    );
  }

  @override
  double applyUserOffset(double delta) {
    assert(false);
    return 0.0;
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
    _NestedScrollMetrics metrics,
  }) {
    if (simulation == null)
      return new IdleScrollActivity(this);
    assert(mode != null);
    switch (mode) {
      case _NestedBallisticScrollActivityMode.outer:
        assert(metrics != null);
        if (metrics.minRange == metrics.maxRange)
          return new IdleScrollActivity(this);
        return new _NestedOuterBallisticScrollActivity(coorindator, this, metrics, simulation, context.vsync);
      case _NestedBallisticScrollActivityMode.inner:
        return new _NestedInnerBallisticScrollActivity(coorindator, this, simulation, context.vsync);
      case _NestedBallisticScrollActivityMode.independent:
        return new BallisticScrollActivity(this, simulation, context.vsync);
    }
    return null;
  }

  @override
  Future<Null> animateTo(double to, {
    @required Duration duration,
    @required Curve curve,
  }) {
    return coorindator.animateTo(coorindator.unnestOffset(to, this), duration: duration, curve: curve);
  }

  @override
  void jumpTo(double value) {
    return coorindator.jumpTo(coorindator.unnestOffset(value, this));
  }

  @override
  void jumpToWithoutSettling(double value) {
    assert(false);
  }

  void localJumpTo(double value) {
    if (pixels != value) {
      final double oldPixels = pixels;
      forcePixels(value);
      didStartScroll();
      didUpdateScrollPositionBy(pixels - oldPixels);
      didEndScroll();
    }
  }

  @override
  void applyNewDimensions() {
    super.applyNewDimensions();
    coorindator.updateCanDrag();
  }

  void updateCanDrag(double totalExtent) {
    context.setCanDrag(totalExtent > (viewportDimension - maxScrollExtent) || minScrollExtent != maxScrollExtent);
  }

  @override
  void didTouch() {
    coorindator.didTouch();
  }

  void _propagateTouched() {
    activity.didTouch();
  }

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    return coorindator.drag(details, dragCancelCallback);
  }

  @override
  void dispose() {
    _parent?.detach(this);
    super.dispose();
  }
}

enum _NestedBallisticScrollActivityMode { outer, inner, independent }

class _NestedInnerBallisticScrollActivity extends BallisticScrollActivity {
  _NestedInnerBallisticScrollActivity(
    this.coorindator,
    _NestedScrollPosition position,
    Simulation simulation,
    TickerProvider vsync,
  ) : super(position, simulation, vsync);

  final _NestedScrollCoorindator coorindator;

  @override
  _NestedScrollPosition get delegate => super.delegate;

  @override
  void resetActivity() {
    delegate.beginActivity(coorindator.createInnerBallisticScrollActivity(delegate, velocity));
  }

  @override
  void applyNewDimensions() {
    delegate.beginActivity(coorindator.createInnerBallisticScrollActivity(delegate, velocity));
  }

  @override
  bool applyMoveTo(double value) {
    return super.applyMoveTo(coorindator.nestOffset(value, delegate));
  }
}

class _NestedOuterBallisticScrollActivity extends BallisticScrollActivity {
  _NestedOuterBallisticScrollActivity(
    this.coorindator,
    _NestedScrollPosition position,
    this.metrics,
    Simulation simulation,
    TickerProvider vsync,
  ) : super(position, simulation, vsync) {
    assert(metrics.minRange != metrics.maxRange);
    assert(metrics.maxRange > metrics.minRange);
  }

  final _NestedScrollCoorindator coorindator;
  final _NestedScrollMetrics metrics;

  @override
  _NestedScrollPosition get delegate => super.delegate;

  @override
  void resetActivity() {
    delegate.beginActivity(coorindator.createOuterBallisticScrollActivity(velocity));
  }

  @override
  void applyNewDimensions() {
    delegate.beginActivity(coorindator.createOuterBallisticScrollActivity(velocity));
  }

  @override
  bool applyMoveTo(double value) {
    bool done = false;
    if (velocity > 0.0) {
      if (value < metrics.minRange)
        return true;
      if (value > metrics.maxRange) {
        value = metrics.maxRange;
        done = true;
      }
    } else if (velocity < 0.0) {
      assert(velocity < 0.0);
      if (value > metrics.maxRange)
        return true;
      if (value < metrics.minRange) {
        value = metrics.minRange;
        done = true;
      }
    } else {
      value = value.clamp(metrics.minRange, metrics.maxRange);
      done = true;
    }
    final bool result = super.applyMoveTo(value + metrics.correctionOffset);
    assert(result); // since we tried to pass an in-range value, it shouldn't ever overflow
    return !done;
  }

  @override
  String toString() {
    return '$runtimeType(${metrics.minRange} .. ${metrics.maxRange}; correcting by ${metrics.correctionOffset})';
  }
}
