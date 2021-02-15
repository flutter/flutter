// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';

// todo: compose to allow backdrop filter's use?
// todo: https://github.com/material-components/material-components-flutter/blob/develop/docs/components/expanding-bottom-sheet.md

const double _kMinFlingVelocity = 700.0;
const double _kMinFlingVelocityDelta = 400.0;
const double _kFlingVelocityScale = 1.0 / 300.0;
const double _kExpandThreshold = 0.4;

/// The fling velocity to back to some state,
/// for example when user releases the finger in some intermediate state
const double _kBackToStateVelocity = 1.0;

/// The direction in which a [Slidable] can be slid.
enum SlideDirection {
  /// The [Slidable] can be slid by dragging in the reverse of the
  /// reading direction (e.g., from right to left in left-to-right languages).
  endToStart,

  /// The [Slidable] can be slid by dragging in the reading direction
  /// (e.g., from left to right in left-to-right languages).
  startToEnd,

  /// The [Slidable] can be slid by dragging up only.
  upFromBottom,

  /// The [Slidable] can be slid by dragging down only.
  downFromTop,

  /// The [Slidable] cannot be slid by dragging.
  none,
}

/// todo: might be split up to framework.dart as new builder signature?
/// todo: change name and docs
typedef _Builder = Widget Function(Animation<double> animation, Widget child);

/// Used by [DragEventListenersMixin.addDragEventListener].
typedef void SlidableDragEventListener(SlidableDragEvent status);

/// Signature for a function used to notify about controller value changes.
///
/// Used by [Slidable.onSlideChange].
typedef void SlideChangeCallback(double value);

/// Signature for a function used to notify about slidable drag begins.
///
/// Used by [Slidable.onDragStart].
typedef void SlideStartCallback(DragStartDetails dragDetails);

/// Signature for a function used to notify about slidable drag updates.
///
/// Used by [Slidable.onDragUpdate].
typedef void SlideUpdateCallback(DragUpdateDetails details);

/// Signature for a function used to notify about slidable drag ends.
///
/// The [result] indicates whether the slidable will return to start offset (if its `false`)
/// or will be slid out to the end offset (if its `true`).
///
/// Used by [Slidable.onDragEnd]
typedef SlideEndCallback = void Function(DragEndDetails details, bool result);

/// Base class for slide drag events.
abstract class SlidableDragEvent {
  const SlidableDragEvent();
}

/// Emitted when user starts dragging slidable.
class SlidableDragStart extends SlidableDragEvent {
  const SlidableDragStart({ required this.details });
  final DragStartDetails details;
}

/// Emitted on updates of drag on slidable.
class SlidableDragUpdate extends SlidableDragEvent {
  const SlidableDragUpdate({ required this.details });
  final DragUpdateDetails details;
}

/// Emitted when user ends dragging slidable.
///
/// The [closing] indicates whether the slidable will return to start offset (if its `false`)
/// or will be slid out to the end offset (if its `true`).
class SlidableDragEnd extends SlidableDragEvent {
  const SlidableDragEnd({ required this.details, required this.closing });
  final DragEndDetails details;
  final bool closing;
}

/// todo: should add panning or no?
/// todo: snapping points
///
/// A widget that allows to slide its child in the indictaed [direction].
///
/// See also:
///  * [SlideDirection], the direction in which a slidable can be slid.
///  * [SlidableController], a controller to use with slidable
///  * [SlidableControllerProvider], inherited widget to provide a [SlidableController]
class Slidable extends StatefulWidget {
  const Slidable({
    Key? key,
    required this.child,
    required this.direction,
    required this.startOffset,
    required this.endOffset,
    this.controller,
    this.childBuilder,
    this.barrier,
    this.barrierBuilder = _defaultBarrierBuilder,
    this.springDescription,
    this.onBarrierTap,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onSlideChange,
    this.disableSlideTransition = false,
    this.barrierIgnoringStrategy = const IgnoringStrategy(dismissed: true, reverse: true),
    this.catchIgnoringStrategy = const MovingIgnoringStrategy(),
    this.hitTestBehaviorStrategy = const HitTestBehaviorStrategy(),
    this.draggedHitTestBehaviorStrategy = const HitTestBehaviorStrategy.opaque(),
    this.slideThresholds = const <SlideDirection, double>{},
    this.dragStartBehavior = DragStartBehavior.start,
  }) : assert(springDescription == null || controller == null),
       super(key: key);

  static Widget _defaultBarrierBuilder(Animation<double> animation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// The direction in which the widget can be slid.
  /// todo: more docs and for SlideDirection too
  final SlideDirection direction;

  /// Defines the start offset in terms of `Offset(mainAxis, crossAxis)`.
  ///
  ///todo: macro
  /// For example, the `Offset(-0.5, 0.3)` will mean the -0.5 offset for the main axis and 0.3 for cross axis.
  /// The main axis for horizontal directions is X, for vertical is Y.
  final Offset startOffset;

  /// Defines the end offset in terms of `Offset(mainAxis, crossAxis)`.
  ///
  /// For example , the `Offset(-0.5, 0.3)` will mean the -0.5 offset for the main axis and 0.3 for cross axis.
  /// The main axis for horizontal directions is X, for vertical is Y.
  final Offset endOffset;

  /// A controller to use with this slidable.
  /// 
  /// When passing a controller, [springDescription] must be null.
  /// If none given, instead the default one will be used.
  final SlidableController? controller;

  //todo: docs
  final _Builder? childBuilder;

  /// The widget to show on `Offset.zero`, can be used for barriers.
  /// todo: better doc regarding barrier, onBarrierTap and ignoring strategy
  final Widget? barrier;
  //todo: docs
  final _Builder barrierBuilder;

  /// A spring to use with default slidable controller.
  /// If this was specified, [controller] must be null.
  final SpringDescription? springDescription;

  /// Called on tap on [barrier].
  ///
  /// By default, corresponding to [barrierIgnoringStrategy], it can be tapped when
  /// slidable is opening or already opened.
  final VoidCallback? onBarrierTap;

  /// Called when user starts dragging the slidable.
  final SlideStartCallback? onDragStart;

  /// Called on updates of drag on the slidable.
  final SlideUpdateCallback? onDragUpdate;

  /// Called when user ends dragging the slidable.
  final SlideEndCallback? onDragEnd;

  /// Fires whenever value of the [controller] changes.
  final SlideChangeCallback? onSlideChange;

  ///todo: docs
  final bool disableSlideTransition;

  /// When to ignore the taps on barrier.
  ///
  /// Ignores dismissed and reverse states by default.
  final IgnoringStrategy barrierIgnoringStrategy;

  /// Describes the ability to "catch" currently moving slidable.
  /// If some of the statuses, let's say, [AnimatingIgnoringStrategy.forward] is disabled,
  /// then you won't be able to stop the slidable while it's animating forward.
  final MovingIgnoringStrategy catchIgnoringStrategy;

  /// What [HitTestBehavior] to apply to the gesture detector when it's not dragged.
  ///
  /// Defaults to [new HitTestBehaviorStrategy].
  final HitTestBehaviorStrategy hitTestBehaviorStrategy;

  /// What [HitTestBehavior] to apply to the gesture detector when the slidable is dragged.
  ///
  /// Defaults to [new HitTestBehaviorStrategy.opaque].
  final HitTestBehaviorStrategy draggedHitTestBehaviorStrategy;

  /// The offset threshold the item has to be dragged in order to be considered
  /// slid.
  ///
  /// Represented as a fraction, e.g. if it is 0.4 (the default), then the item
  /// has to be dragged at least 40% towards one direction to be considered
  /// slid. Clients can define different thresholds for each slide
  /// direction.
  ///
  /// Flinging is treated as being equivalent to dragging almost to 1.0, so
  /// flinging can slide an item past any threshold less than 1.0.
  ///
  /// Setting a threshold of 1.0 (or greater) prevents a drag in the given
  /// [SlideDirection] even if it would be allowed by the [direction]
  /// property.
  ///
  /// See also:
  ///
  ///  * [direction], which controls the directions in which the items can
  ///    be slid.
  final Map<SlideDirection, double> slideThresholds;

  /// todo: macro
  /// 
  /// Determines the way that drag start behavior is handled.
  ///
  /// If set to [DragStartBehavior.start], the drag gesture used to dismiss a
  /// dismissible will begin upon the detection of a drag gesture. If set to
  /// [DragStartBehavior.down] it will begin when a down event is first detected.
  ///
  /// In general, setting this to [DragStartBehavior.start] will make drag
  /// animation smoother and setting it to [DragStartBehavior.down] will make
  /// drag behavior feel slightly more reactive.
  ///
  /// By default, the drag start behavior is [DragStartBehavior.start].
  ///
  /// See also:
  ///
  ///  * [DragGestureRecognizer.dragStartBehavior], which gives an example for the different behaviors.
  final DragStartBehavior dragStartBehavior;

  @override
  SlidableState createState() => SlidableState();
}

enum _FlingGestureKind { none, forward, reverse }

// todo: AutomaticKeepAliveClientMixin ???
class SlidableState extends State<Slidable> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _initController();
    _evaluateStrategies();
    _updateAnimation();
  }

  void _handleChange() {
    widget.onSlideChange?.call(controller.value);
  }

  void _handleStatusChange(AnimationStatus status) {
    setState(() {
      _evaluateStrategies();
    });
  }

  void _initController() {
    if (widget.controller == null) {
      // todo: try to do it with SingleTickerProviderStateMixin (now it doesn allow to creat another ticker after disposing previos one)
      _controller = SlidableController(
        vsync: this,
        springDescription: widget.springDescription,
      );
    } else {
      _controller?.dispose();
      _controller = null;
    }
    controller.addListener(_handleChange);
    controller.addStatusListener(_handleStatusChange);
  }

  void _evaluateStrategies() {
    _ignoringBarrier = widget.barrierIgnoringStrategy.evaluate(controller);
    if (controller.dragged) {
      _hitTestBehavior = widget.draggedHitTestBehaviorStrategy.ask(controller);
    } else {
      _hitTestBehavior = widget.hitTestBehaviorStrategy.ask(controller);
    }
  }

  @override
  void didUpdateWidget (covariant Slidable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(oldWidget.controller != widget.controller) {
      // todo: should we support attaching/unattaching controller? or it should be handled in some other way?
      oldWidget.controller?.removeListener(_handleChange);
      oldWidget.controller?.removeStatusListener(_handleStatusChange);
      _initController();
    }
    if (oldWidget.startOffset != widget.startOffset ||
       oldWidget.endOffset != widget.endOffset) {
      _updateAnimation();
    }
    // We don't care about comparing the strategies to check wether they chagned,
    // it's cheaper just to evaluate them again.
    _evaluateStrategies();
  }

  @override
  void dispose() {
    _controller?.dispose();
    controller.removeListener(_handleChange);
    controller.removeStatusListener(_handleStatusChange);
    super.dispose();
  }

  SlidableController? _controller;
  SlidableController get controller => widget.controller ?? _controller!;

  bool get _draggable => widget.direction != SlideDirection.none;

  late Animation<Offset> _animation;
  double _dragExtent = 0.0;

  late bool _ignoringBarrier;
  late HitTestBehavior _hitTestBehavior;

  bool get _directionIsXAxis {
    return widget.direction == SlideDirection.endToStart ||
           widget.direction == SlideDirection.startToEnd;
  }

  SlideDirection _extentToDirection(double extent) {
    if (extent == 0.0)
      return SlideDirection.none;
    if (_directionIsXAxis) {
      switch (Directionality.of(context)) {
        case TextDirection.rtl:
          return extent < 0 ? SlideDirection.startToEnd: SlideDirection.endToStart;
        case TextDirection.ltr:
          return extent > 0 ? SlideDirection.startToEnd : SlideDirection.endToStart;
      }
    }
    return extent > 0 ? SlideDirection.downFromTop : SlideDirection.upFromBottom;
  }

  SlideDirection get _slideDirection => _extentToDirection(_dragExtent);

  double get _overallDragAxisExtent {
    final Size size = context.size!;
    return _directionIsXAxis ? size.width : size.height;
  }

  void _handleDragStart(DragStartDetails details) {
    controller._dragged = true;
    double sign = 1.0;
    if (controller.status != AnimationStatus.dismissed) {
      final TextDirection textDirection = Directionality.of(context);
      if (widget.direction == SlideDirection.upFromBottom ||
          textDirection == TextDirection.ltr && widget.direction == SlideDirection.endToStart || 
          textDirection == TextDirection.rtl && widget.direction == SlideDirection.startToEnd) {
        // this is quite vodoo
        // todo: i guess this can be simplified (as well as _handleDragUpdate, _handleDragEnd, _extentToDirection and _describeFlingGesture)
        sign = -1.0;
      }
      // wrong behaviour tests (for ltr)
      // -0.5 0.0 upFromBottom
      // 0.5 0.0 upFromBottom
      // 0.0 -0.5 upFromBottom
      // 0.0 0.5 upFromBottom
      // -0.5 0.0 endToStart
      // 0.5 0.0 endToStart
      // 0.0 -0.5 endToStart
      // 0.0 0.5 endToStart
    }
    _dragExtent = controller.value * _overallDragAxisExtent * sign;
    if (controller.status == AnimationStatus.forward && !widget.catchIgnoringStrategy.forward ||
        controller.status == AnimationStatus.reverse && !widget.catchIgnoringStrategy.reverse) {
      controller.stop();
    }
    widget.onDragStart?.call(details);
    controller.notifyDragEventListeners(SlidableDragStart(details: details));
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!controller.isActive || controller.isAnimating) return;
    widget.onDragUpdate?.call(details);
    controller.notifyDragEventListeners(SlidableDragUpdate(details: details));

    final double delta = details.primaryDelta!;
    switch (widget.direction) {
      case SlideDirection.upFromBottom:
        if (_dragExtent + delta < 0)
          _dragExtent += delta;
        break;

      case SlideDirection.downFromTop:
        if (_dragExtent + delta > 0)
          _dragExtent += delta;
        break;
      case SlideDirection.endToStart:
        switch (Directionality.of(context)) {
          case TextDirection.rtl:
            if (_dragExtent + delta > 0)
              _dragExtent += delta;
            break;
          case TextDirection.ltr:
            if (_dragExtent + delta < 0)
              _dragExtent += delta;
            break;
        }
        break;

      case SlideDirection.startToEnd:
        switch (Directionality.of(context)) {
          case TextDirection.rtl:
            if (_dragExtent + delta < 0)
              _dragExtent += delta;
            break;
          case TextDirection.ltr:
            if (_dragExtent + delta > 0)
              _dragExtent += delta;
            break;
        }
        break;

      case SlideDirection.none:
        // todo: in dismissible.dart here's _dragExtent = 0, but why?
        // setting it to 0 doesn't seem ok, but i need to be 100% sure it's not to do anything here
        break;
    }
    if (!controller.isAnimating) {
      controller.value = _dragExtent.abs() / _overallDragAxisExtent;
    }
  }

  void _updateAnimation() {
    double startX = widget.startOffset.dx;
    double startY = widget.startOffset.dy;
    double endX = widget.endOffset.dx;
    double endY = widget.endOffset.dy;
    late Offset begin;
    late Offset end;
    if (_directionIsXAxis) {
      begin = Offset(startX, startY);
      end = Offset(endX, endY);
    } else {
      begin = Offset(startY, startX);
      end = Offset(endY, endX);
    }
    _animation = controller.drive(Tween<Offset>(
      begin: begin,
      end: end,
    ));
  }

  _FlingGestureKind _describeFlingGesture(Velocity velocity) {
    if (_dragExtent == 0.0) {
      // If it was a fling, then it was a fling that was let loose at the exact
      // middle of the range (i.e. when there's no displacement). In that case,
      // we assume that the user meant to fling it back to the center, as
      // opposed to having wanted to drag it out one way, then fling it past the
      // center and into and out the other side.
      return _FlingGestureKind.none;
    }
    final double vx = velocity.pixelsPerSecond.dx;
    final double vy = velocity.pixelsPerSecond.dy;
    SlideDirection flingDirection;
    // Verify that the fling is in the generally right direction and fast enough.
    if (_directionIsXAxis) {
      if (vx.abs() - vy.abs() < _kMinFlingVelocityDelta || vx.abs() < _kMinFlingVelocity)
        return _FlingGestureKind.none;
      assert(vx != 0.0);
      flingDirection = _extentToDirection(vx);
    } else {
      if (vy.abs() - vx.abs() < _kMinFlingVelocityDelta || vy.abs() < _kMinFlingVelocity)
        return _FlingGestureKind.none;
      assert(vy != 0.0);
      flingDirection = _extentToDirection(vy);
    }
    if (flingDirection == _slideDirection) return _FlingGestureKind.forward;
    return _FlingGestureKind.reverse;
  }

  Future<void> _handleDragEnd(DragEndDetails details) async {
    if (!controller.isActive || controller.isAnimating) return;

    controller._dragged = false;
    final double flingVelocity = _directionIsXAxis
        ? details.velocity.pixelsPerSecond.dx
        : details.velocity.pixelsPerSecond.dy;
    late final bool closing;
    
    switch (_describeFlingGesture(details.velocity)) {
      case _FlingGestureKind.forward:
        assert(_dragExtent != 0.0);
        assert(!controller.isDismissed);
        if ((widget.slideThresholds[_slideDirection] ?? _kExpandThreshold) >= 1.0) {
          controller.fling(velocity: -_kBackToStateVelocity);
          closing = false;
          break;
        }
        _dragExtent = flingVelocity.sign;
        controller.fling(velocity: flingVelocity.abs() * _kFlingVelocityScale);
        closing = true;
        break;
      case _FlingGestureKind.reverse:
        assert(_dragExtent != 0.0);
        assert(!controller.isDismissed);
        _dragExtent = flingVelocity.sign;
        controller.fling(velocity: -flingVelocity.abs() * _kFlingVelocityScale);
        closing = false;
        break;
      case _FlingGestureKind.none:
        if (!controller.isDismissed) {
          // we already know it's not completed, we check that above
          if (controller.value > (widget.slideThresholds[_slideDirection] ?? _kExpandThreshold)) {
            controller.fling(velocity: _kBackToStateVelocity);
            closing = true;
          } else {
            controller.fling(velocity: -_kBackToStateVelocity);
            closing = false;
          }
        } else {
          closing = false;
        }
        break;
    }
    widget.onDragEnd?.call(details, closing);
    controller.notifyDragEventListeners(
      SlidableDragEnd(details: details, closing: closing)
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(!_directionIsXAxis || debugCheckHasDirectionality(context));

    final Size size = MediaQuery.of(context).size;
    final Widget? barrier = widget.barrier != null ? widget.barrierBuilder(controller, widget.barrier!) : null;
    final Widget child = Container(
      width: size.width,
      height: size.height,
      child: widget.childBuilder == null ? widget.child : widget.childBuilder!(controller, widget.child),
    );
    final Widget wrappedChild = widget.disableSlideTransition ? child : SlideTransition(position: _animation, child: child);

    return RepaintBoundary(
      child: GestureDetector(
        behavior: _hitTestBehavior,
        dragStartBehavior: widget.dragStartBehavior,
        onHorizontalDragStart: _draggable && _directionIsXAxis ? _handleDragStart : null,
        onHorizontalDragUpdate: _draggable && _directionIsXAxis ? _handleDragUpdate : null,
        onHorizontalDragEnd: _draggable && _directionIsXAxis ? _handleDragEnd : null,
        onVerticalDragStart: _draggable && !_directionIsXAxis ? _handleDragStart : null,
        onVerticalDragUpdate: _draggable && !_directionIsXAxis ? _handleDragUpdate : null,
        onVerticalDragEnd: _draggable && !_directionIsXAxis ? _handleDragEnd : null,
        child: barrier == null
          ? wrappedChild
          : () {
              final List<Widget> children = [
                IgnorePointer(
                  ignoring: _ignoringBarrier,
                  child: widget.onBarrierTap == null
                    ? barrier
                    : GestureDetector(
                        onTap: widget.onBarrierTap,
                        behavior: HitTestBehavior.opaque,
                        child: barrier,
                      ),
                ),
                wrappedChild,
              ];
              return _hitTestBehavior == HitTestBehavior.translucent
                  // todo(nt4f04und): remove/update this when https://github.com/flutter/flutter/issues/75099 is resolved
                  ? _StackWithAllChildrenReceiveEvents(children: children)
                  : Stack(children: children);
            }(),
      ),
    );
  }
}

/// A controller for a [Slidable].
///
/// Provides an ability to listen to the drag events, see [addDragEventListener]/[removeDragEventListener].
///
/// See also:
///  * [Slidable], a widget that allows you to slide it's content
///  * [SlidableControllerProvider], inherited widget that provides access to the controller
class SlidableController extends AnimationController with _DragEventListenersMixin {
  SlidableController({
    double value = 0.0,
    Duration? duration,
    Duration? reverseDuration,
    String? debugLabel,
    double lowerBound = 0.0,
    double upperBound = 1.0,
    SpringDescription? springDescription,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
    required TickerProvider vsync,
  }) : super(
         value: value,
         duration: duration,
         reverseDuration: reverseDuration,
         debugLabel: debugLabel,
         lowerBound: lowerBound,
         upperBound: upperBound,
         springDescription: springDescription,
         animationBehavior: animationBehavior,
         vsync: vsync,
       );

  bool _dragged = false;

  /// Indicates wether the slidable is currently dragged.
  bool get dragged => _dragged;

  /// Indicates that the slidable is being dragged or it is animating.
  bool get isActive => _dragged || isAnimating;

  /// True when slidable is fully opened, or when it has accepted
  /// a gesture to be opened and currently is animating to this state.
  bool get opened => _dragged || isCompleted || !_dragged && status == AnimationStatus.forward;

  /// True when slidable is fully closed, or when it has accepted
  /// a gesture to be closed and currently is animating to this state.
  bool get closed => isDismissed || !_dragged && status == AnimationStatus.reverse;

  @override
  TickerFuture fling({ double velocity = 1.0, SpringDescription? springDescription, AnimationBehavior? animationBehavior }) {
    return super.fling(velocity: velocity, springDescription: springDescription, animationBehavior: animationBehavior);
  }

  /// Calls [fling] with default velocity to end in the [opened] state.
  TickerFuture open({ SpringDescription? springDescription, AnimationBehavior? animationBehavior }) {
    return fling(springDescription: springDescription, animationBehavior: animationBehavior);
  }

  /// Calls [fling] with default velocity to end in the [closed] state.
  TickerFuture close({ SpringDescription? springDescription, AnimationBehavior? animationBehavior }) {
    return fling(velocity: -1.0, springDescription: springDescription, animationBehavior: animationBehavior);
  }
}

/// Provides access to the [SlidableController].
/// 
/// Type parameter [T] is used to distunguish different types of controllers.
class SlidableControllerProvider<T> extends InheritedWidget {
  const SlidableControllerProvider({
    Key? key,
    required this.child,
    required this.controller,
  }) : super(key: key, child: child);

  final Widget child;
  final SlidableController controller;

  static SlidableControllerProvider<T>? of<T>(BuildContext context) {
    return context.getElementForInheritedWidgetOfExactType<SlidableControllerProvider<T>>()?.widget as SlidableControllerProvider<T>?;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}

mixin _DragEventListenersMixin {
  final ObserverList<SlidableDragEventListener> _dragEventListeners = ObserverList<SlidableDragEventListener>();

  void addDragEventListener(SlidableDragEventListener listener) {
    _dragEventListeners.add(listener);
  }

  void removeDragEventListener(SlidableDragEventListener listener) {
    _dragEventListeners.remove(listener);
  }

  void notifyDragEventListeners(SlidableDragEvent event) {
    final List<SlidableDragEventListener> localListeners = List<SlidableDragEventListener>.from(_dragEventListeners);
    for (final SlidableDragEventListener listener in localListeners) {
      if (_dragEventListeners.contains(listener)) listener(event);
    }
  }
}

/// see https://github.com/flutter/flutter/issues/75099
class _StackWithAllChildrenReceiveEvents extends Stack {
  _StackWithAllChildrenReceiveEvents({
    Key? key,
    AlignmentDirectional alignment = AlignmentDirectional.topStart,
    TextDirection textDirection = TextDirection.ltr,
    StackFit fit = StackFit.loose,
    List<Widget> children = const <Widget>[],
  }) : super(
          key: key,
          alignment: alignment,
          textDirection: textDirection,
          fit: fit,
          children: children,
        );

  @override
  _RenderStackWithAllChildrenReceiveEvents createRenderObject(BuildContext context) {
    return _RenderStackWithAllChildrenReceiveEvents(
      alignment: alignment,
      textDirection: textDirection ?? Directionality.of(context),
      fit: fit,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderStackWithAllChildrenReceiveEvents renderObject) {
    renderObject
      ..alignment = alignment
      ..textDirection = textDirection ?? Directionality.of(context)
      ..fit = fit;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
    properties.add(EnumProperty<StackFit>('fit', fit));
  }
}

class _RenderStackWithAllChildrenReceiveEvents extends RenderStack {
  _RenderStackWithAllChildrenReceiveEvents({
    AlignmentGeometry alignment = AlignmentDirectional.topStart,
    TextDirection? textDirection,
    StackFit fit = StackFit.loose,
  }) : super(
          alignment: alignment,
          textDirection: textDirection,
          fit: fit,
        );

  bool allCdefaultHitTestChildren(BoxHitTestResult result, {required Offset position}) {
    RenderBox? child = lastChild;
    while (child != null) {
      final StackParentData childParentData = child.parentData! as StackParentData;
      child.hitTest(result, position: position - childParentData.offset);
      child = childParentData.previousSibling;
    }
    return false;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return allCdefaultHitTestChildren(result, position: position);
  }
}
