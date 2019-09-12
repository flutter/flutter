// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

// All values eyeballed.
const Color _kScrollbarColor = Color(0x99777777);
const double _kScrollbarMinLength = 36.0;
const double _kScrollbarMinOverscrollLength = 8.0;
const Radius _kScrollbarRadius = Radius.circular(1.5);
const Radius _kScrollbarRadiusDragging = Radius.circular(4.0);
const Duration _kScrollbarTimeToFade = Duration(milliseconds: 1200);
const Duration _kScrollbarFadeDuration = Duration(milliseconds: 250);
const Duration _kScrollbarResizeDuration = Duration(milliseconds: 150);

// These values are measured using screenshots from an iPhone XR 13.0 simulator.
const double _kScrollbarThickness = 2.5;
const double _kScrollbarThicknessDragging = 8.0;
// This is the amount of space from the top of a vertical scrollbar to the
// top edge of the scrollable, measured when the vertical scrollbar overscrolls
// to the top.
// TODO(LongCatIsLooong): fix https://github.com/flutter/flutter/issues/32175
const double _kScrollbarMainAxisMargin = 3.0;
const double _kScrollbarCrossAxisMargin = 3.0;

/// An iOS style scrollbar.
///
/// A scrollbar indicates which portion of a [Scrollable] widget is actually
/// visible.
///
/// To add a scrollbar to a [ScrollView], simply wrap the scroll view widget in
/// a [CupertinoScrollbar] widget.
///
/// See also:
///
///  * [ListView], which display a linear, scrollable list of children.
///  * [GridView], which display a 2 dimensional, scrollable array of children.
///  * [Scrollbar], a Material Design scrollbar that dynamically adapts to the
///    platform showing either an Android style or iOS style scrollbar.
class CupertinoScrollbar extends StatefulWidget {
  /// Creates an iOS style scrollbar that wraps the given [child].
  ///
  /// The [child] should be a source of [ScrollNotification] notifications,
  /// typically a [Scrollable] widget.
  const CupertinoScrollbar({
    Key key,
    this.controller,
    @required this.child,
  }) : super(key: key);

  /// The subtree to place inside the [CupertinoScrollbar].
  ///
  /// This should include a source of [ScrollNotification] notifications,
  /// typically a [Scrollable] widget.
  final Widget child;

  /// The [ScrollController] used to implement Scrollbar dragging.
  ///
  /// Scrollbar dragging is started with a long press or a drag in from the side
  /// on top of the scrollbar thumb, which enlarges the thumb and makes it
  /// interactive. Dragging it then causes the view to scroll. This feature was
  /// introduced in iOS 13.
  ///
  /// In order to enable this feature, pass an active ScrollController to this
  /// parameter.  A stateful ancestor of this CupertinoScrollbar needs to
  /// manage the ScrollController and either pass it to a scrollable descendant
  /// or use a PrimaryScrollController to share it.
  ///
  /// Here is an example of using PrimaryScrollController to enable scrollbar
  /// dragging:
  ///
  /// {@tool sample}
  ///
  /// ```dart
  /// build(BuildContext context) {
  ///   final ScrollController controller = ScrollController();
  ///   return PrimaryScrollController(
  ///     controller: controller,
  ///     child: CupertinoScrollbar(
  ///       controller: controller,
  ///       child: ListView.builder(
  ///         itemCount: 150,
  ///         itemBuilder: (BuildContext context, int index) => Text('item $index'),
  ///       ),
  ///     ),
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  final ScrollController controller;

  @override
  _CupertinoScrollbarState createState() => _CupertinoScrollbarState();
}

class _CupertinoScrollbarState extends State<CupertinoScrollbar> with TickerProviderStateMixin {
  final GlobalKey _customPaintKey = GlobalKey();
  ScrollbarPainter _painter;
  TextDirection _textDirection;

  AnimationController _fadeoutAnimationController;
  Animation<double> _fadeoutOpacityAnimation;
  AnimationController _thicknessAnimationController;
  Timer _fadeoutTimer;
  double _dragScrollbarPositionY;
  Drag _drag;

  double get _thickness {
    return _kScrollbarThickness + _thicknessAnimationController.value * (_kScrollbarThicknessDragging - _kScrollbarThickness);
  }

  Radius get _radius {
    return Radius.lerp(_kScrollbarRadius, _kScrollbarRadiusDragging, _thicknessAnimationController.value);
  }

  @override
  void initState() {
    super.initState();
    _fadeoutAnimationController = AnimationController(
      vsync: this,
      duration: _kScrollbarFadeDuration,
    );
    _fadeoutOpacityAnimation = CurvedAnimation(
      parent: _fadeoutAnimationController,
      curve: Curves.fastOutSlowIn,
    );
    _thicknessAnimationController = AnimationController(
      vsync: this,
      duration: _kScrollbarResizeDuration,
    );
    _thicknessAnimationController.addListener(() {
      _painter.updateThickness(_thickness, _radius);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _textDirection = Directionality.of(context);
    _painter = _buildCupertinoScrollbarPainter();
  }

  /// Returns a [ScrollbarPainter] visually styled like the iOS scrollbar.
  ScrollbarPainter _buildCupertinoScrollbarPainter() {
    return ScrollbarPainter(
      color: _kScrollbarColor,
      textDirection: _textDirection,
      thickness: _thickness,
      fadeoutOpacityAnimation: _fadeoutOpacityAnimation,
      mainAxisMargin: _kScrollbarMainAxisMargin,
      crossAxisMargin: _kScrollbarCrossAxisMargin,
      radius: _radius,
      padding: MediaQuery.of(context).padding,
      minLength: _kScrollbarMinLength,
      minOverscrollLength: _kScrollbarMinOverscrollLength,
    );
  }

  // Handle a gesture that drags the scrollbar by the given amount.
  void _dragScrollbar(double primaryDelta) {
    assert(widget.controller != null);

    // Convert primaryDelta, the amount that the scrollbar moved since the last
    // time _dragScrollbar was called, into the coordinate space of the scroll
    // position, and create/update the drag event with that position.
    final double scrollOffsetLocal = _painter.getTrackToScroll(primaryDelta);
    final double scrollOffsetGlobal = scrollOffsetLocal + widget.controller.position.pixels;

    if (_drag == null) {
      _drag = widget.controller.position.drag(
        DragStartDetails(
          globalPosition: Offset(0.0, scrollOffsetGlobal),
        ),
        () {},
      );
    } else {
      _drag.update(DragUpdateDetails(
        globalPosition: Offset(0.0, scrollOffsetGlobal),
        delta: Offset(0.0, -scrollOffsetLocal),
        primaryDelta: -scrollOffsetLocal,
      ));
    }
  }

  void _startFadeoutTimer() {
    _fadeoutTimer?.cancel();
    _fadeoutTimer = Timer(_kScrollbarTimeToFade, () {
      _fadeoutAnimationController.reverse();
      _fadeoutTimer = null;
    });
  }

  void _assertVertical() {
    assert(
      widget.controller.position.axis == Axis.vertical,
      'Scrollbar dragging is only supported for vertical scrolling. Don\'t pass the controller param to a horizontal scrollbar.',
    );
  }

  // Long press event callbacks handle the gesture where the user long presses
  // on the scrollbar thumb and then drags the scrollbar without releasing.
  void _handleLongPressStart(LongPressStartDetails details) {
    _assertVertical();
    _fadeoutTimer?.cancel();
    _fadeoutAnimationController.forward();
    HapticFeedback.mediumImpact();
    _dragScrollbar(details.localPosition.dy);
    _dragScrollbarPositionY = details.localPosition.dy;
  }

  void _handleLongPress() {
    _assertVertical();
    _fadeoutTimer?.cancel();
    _thicknessAnimationController.forward();
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    _assertVertical();
    _dragScrollbar(details.localPosition.dy - _dragScrollbarPositionY);
    _dragScrollbarPositionY = details.localPosition.dy;
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    _handleDragScrollEnd(details.velocity.pixelsPerSecond.dy);
  }

  // Horizontal drag event callbacks handle the gesture where the user swipes in
  // from the right on top of the scrollbar thumb and then drags the scrollbar
  // without releasing.
  void _handleHorizontalDragStart(DragStartDetails details) {
    _assertVertical();
    _fadeoutTimer?.cancel();
    _thicknessAnimationController.forward();
    HapticFeedback.mediumImpact();
    _dragScrollbar(details.localPosition.dy);
    _dragScrollbarPositionY = details.localPosition.dy;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    _assertVertical();
    _dragScrollbar(details.localPosition.dy - _dragScrollbarPositionY);
    _dragScrollbarPositionY = details.localPosition.dy;
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    _handleDragScrollEnd(details.velocity.pixelsPerSecond.dy);
  }

  void _handleDragScrollEnd(double trackVelocityY) {
    _assertVertical();
    _startFadeoutTimer();
    _thicknessAnimationController.reverse();
    _dragScrollbarPositionY = null;
    final double scrollVelocityY = _painter.getTrackToScroll(trackVelocityY);
    _drag?.end(DragEndDetails(
      primaryVelocity: -scrollVelocityY,
      velocity: Velocity(
        pixelsPerSecond: Offset(
          0.0,
          -scrollVelocityY,
        ),
      ),
    ));
    _drag = null;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final ScrollMetrics metrics = notification.metrics;
    if (metrics.maxScrollExtent <= metrics.minScrollExtent) {
      return false;
    }

    if (notification is ScrollUpdateNotification ||
        notification is OverscrollNotification) {
      // Any movements always makes the scrollbar start showing up.
      if (_fadeoutAnimationController.status != AnimationStatus.forward) {
        _fadeoutAnimationController.forward();
      }

      _fadeoutTimer?.cancel();
      _painter.update(notification.metrics, notification.metrics.axisDirection);
    } else if (notification is ScrollEndNotification) {
      // On iOS, the scrollbar can only go away once the user lifted the finger.
      if (_dragScrollbarPositionY == null) {
        _startFadeoutTimer();
      }
    }
    return false;
  }

  // Get the GestureRecognizerFactories used to detect gestures on the scrollbar
  // thumb.
  Map<Type, GestureRecognizerFactory> get _gestures {
    final Map<Type, GestureRecognizerFactory> gestures = <Type, GestureRecognizerFactory>{};
    if (widget.controller == null) {
      return gestures;
    }

    gestures[_ThumbLongPressGestureRecognizer] =
      GestureRecognizerFactoryWithHandlers<_ThumbLongPressGestureRecognizer>(
        () => _ThumbLongPressGestureRecognizer(
          debugOwner: this,
          kind: PointerDeviceKind.touch,
          customPaintKey: _customPaintKey,
        ),
        (_ThumbLongPressGestureRecognizer instance) {
          instance
            ..onLongPressStart = _handleLongPressStart
            ..onLongPress = _handleLongPress
            ..onLongPressMoveUpdate = _handleLongPressMoveUpdate
            ..onLongPressEnd = _handleLongPressEnd;
        },
      );
    gestures[_ThumbHorizontalDragGestureRecognizer] =
      GestureRecognizerFactoryWithHandlers<_ThumbHorizontalDragGestureRecognizer>(
        () => _ThumbHorizontalDragGestureRecognizer(
          debugOwner: this,
          kind: PointerDeviceKind.touch,
          customPaintKey: _customPaintKey,
        ),
        (_ThumbHorizontalDragGestureRecognizer instance) {
          instance
            ..onStart = _handleHorizontalDragStart
            ..onUpdate = _handleHorizontalDragUpdate
            ..onEnd = _handleHorizontalDragEnd;
        },
      );

    return gestures;
  }

  @override
  void dispose() {
    _fadeoutAnimationController.dispose();
    _thicknessAnimationController.dispose();
    _fadeoutTimer?.cancel();
    _painter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: RepaintBoundary(
        child: RawGestureDetector(
          gestures: _gestures,
          child: CustomPaint(
            key: _customPaintKey,
            foregroundPainter: _painter,
            child: RepaintBoundary(
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

// A longpress gesture detector that only responds to events on the scrollbar's
// thumb and ignores everything else.
class _ThumbLongPressGestureRecognizer extends LongPressGestureRecognizer {
  _ThumbLongPressGestureRecognizer({
    double postAcceptSlopTolerance,
    PointerDeviceKind kind,
    Object debugOwner,
    GlobalKey customPaintKey,
  }) :  _customPaintKey = customPaintKey,
        super(
          postAcceptSlopTolerance: postAcceptSlopTolerance,
          kind: kind,
          debugOwner: debugOwner,
        );

  final GlobalKey _customPaintKey;

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    if (!_hitTestInteractive(_customPaintKey, event.position)) {
      return false;
    }
    return super.isPointerAllowed(event);
  }
}

// A horizontal drag gesture detector that only responds to events on the
// scrollbar's thumb and ignores everything else.
class _ThumbHorizontalDragGestureRecognizer extends HorizontalDragGestureRecognizer {
  _ThumbHorizontalDragGestureRecognizer({
    PointerDeviceKind kind,
    Object debugOwner,
    GlobalKey customPaintKey,
  }) :  _customPaintKey = customPaintKey,
        super(
          kind: kind,
          debugOwner: debugOwner,
        );

  final GlobalKey _customPaintKey;

  @override
  bool isPointerAllowed(PointerEvent event) {
    if (!_hitTestInteractive(_customPaintKey, event.position)) {
      return false;
    }
    return super.isPointerAllowed(event);
  }

  // Flings are actually in the vertical direction. Even though the event starts
  // horizontal, the scrolling is tracked vertically.
  @override
  bool isFlingGesture(VelocityEstimate estimate) {
    final double minVelocity = minFlingVelocity ?? kMinFlingVelocity;
    final double minDistance = minFlingDistance ?? kTouchSlop;
    return estimate.pixelsPerSecond.dy.abs() > minVelocity && estimate.offset.dy.abs() > minDistance;
  }
}

// foregroundPainter also hit tests its children by default, but the
// scrollbar should only respond to a gesture directly on its thumb, so
// manually check for a hit on the thumb here.
bool _hitTestInteractive(GlobalKey customPaintKey, Offset offset) {
  if (customPaintKey.currentContext == null) {
    return false;
  }
  final CustomPaint customPaint = customPaintKey.currentContext.widget;
  final ScrollbarPainter painter = customPaint.foregroundPainter;
  final RenderBox renderBox = customPaintKey.currentContext.findRenderObject();
  final Offset localOffset = renderBox.globalToLocal(offset);
  return painter.hitTestInteractive(localOffset);
}
