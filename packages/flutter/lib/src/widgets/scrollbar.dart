// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'binding.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'primary_scroll_controller.dart';
import 'scroll_controller.dart';
import 'scroll_metrics.dart';
import 'scroll_notification.dart';
import 'ticker_provider.dart';

const double _kMinThumbExtent = 18.0;
const double _kMinInteractiveSize = 48.0;

/// A [CustomPainter] for painting scrollbars.
///
/// The size of the scrollbar along its scroll direction is typically
/// proportional to the percentage of content completely visible on screen,
/// as long as its size isn't less than [minLength] and it isn't overscrolling.
///
/// Unlike [CustomPainter]s that subclasses [CustomPainter] and only repaint
/// when [shouldRepaint] returns true (which requires this [CustomPainter] to
/// be rebuilt), this painter has the added optimization of repainting and not
/// rebuilding when:
///
///  * the scroll position changes; and
///  * when the scrollbar fades away.
///
/// Calling [update] with the new [ScrollMetrics] will repaint the new scrollbar
/// position.
///
/// Updating the value on the provided [fadeoutOpacityAnimation] will repaint
/// with the new opacity.
///
/// You must call [dispose] on this [ScrollbarPainter] when it's no longer used.
///
/// See also:
///
///  * [Scrollbar] for a widget showing a scrollbar around a [Scrollable] in the
///    Material Design style.
///  * [CupertinoScrollbar] for a widget showing a scrollbar around a
///    [Scrollable] in the iOS style.
class ScrollbarPainter extends ChangeNotifier implements CustomPainter {
  /// Creates a scrollbar with customizations given by construction arguments.
  ScrollbarPainter({
    required Color color,
    required TextDirection textDirection,
    required this.thickness,
    required this.fadeoutOpacityAnimation,
    EdgeInsets padding = EdgeInsets.zero,
    this.mainAxisMargin = 0.0,
    this.crossAxisMargin = 0.0,
    this.radius,
    this.minLength = _kMinThumbExtent,
    double? minOverscrollLength,
  }) : assert(color != null),
       assert(textDirection != null),
       assert(thickness != null),
       assert(fadeoutOpacityAnimation != null),
       assert(mainAxisMargin != null),
       assert(crossAxisMargin != null),
       assert(minLength != null),
       assert(minLength >= 0),
       assert(minOverscrollLength == null || minOverscrollLength <= minLength),
       assert(minOverscrollLength == null || minOverscrollLength >= 0),
       assert(padding != null),
       assert(padding.isNonNegative),
       _color = color,
       _textDirection = textDirection,
       _padding = padding,
       minOverscrollLength = minOverscrollLength ?? minLength {
    fadeoutOpacityAnimation.addListener(notifyListeners);
  }

  /// [Color] of the thumb. Mustn't be null.
  Color get color => _color;
  Color _color;
  set color(Color value) {
    assert(value != null);
    if (color == value)
      return;

    _color = value;
    notifyListeners();
  }

  /// [TextDirection] of the [BuildContext] which dictates the side of the
  /// screen the scrollbar appears in (the trailing side). Mustn't be null.
  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    assert(value != null);
    if (textDirection == value)
      return;

    _textDirection = value;
    notifyListeners();
  }

  /// Thickness of the scrollbar in its cross-axis in logical pixels. Mustn't be null.
  double thickness;

  /// An opacity [Animation] that dictates the opacity of the thumb.
  /// Changes in value of this [Listenable] will automatically trigger repaints.
  /// Mustn't be null.
  final Animation<double> fadeoutOpacityAnimation;

  /// Distance from the scrollbar's start and end to the edge of the viewport
  /// in logical pixels. It affects the amount of available paint area.
  ///
  /// Mustn't be null and defaults to 0.
  final double mainAxisMargin;

  /// Distance from the scrollbar's side to the nearest edge in logical pixels.
  ///
  /// Must not be null and defaults to 0.
  final double crossAxisMargin;

  /// [Radius] of corners if the scrollbar should have rounded corners.
  ///
  /// Scrollbar will be rectangular if [radius] is null.
  Radius? radius;

  /// The amount of space by which to inset the scrollbar's start and end, as
  /// well as its side to the nearest edge, in logical pixels.
  ///
  /// This is typically set to the current [MediaQueryData.padding] to avoid
  /// partial obstructions such as display notches. If you only want additional
  /// margins around the scrollbar, see [mainAxisMargin].
  ///
  /// Defaults to [EdgeInsets.zero]. Must not be null and offsets from all four
  /// directions must be greater than or equal to zero.
  EdgeInsets get padding => _padding;
  EdgeInsets _padding;
  set padding(EdgeInsets value) {
    assert(value != null);
    if (padding == value)
      return;

    _padding = value;
    notifyListeners();
  }


  /// The preferred smallest size the scrollbar can shrink to when the total
  /// scrollable extent is large, the current visible viewport is small, and the
  /// viewport is not overscrolled.
  ///
  /// The size of the scrollbar may shrink to a smaller size than [minLength] to
  /// fit in the available paint area. E.g., when [minLength] is
  /// `double.infinity`, it will not be respected if
  /// [ScrollMetrics.viewportDimension] and [mainAxisMargin] are finite.
  ///
  /// Mustn't be null and the value has to be within the range of 0 to
  /// [minOverscrollLength], inclusive. Defaults to 18.0.
  final double minLength;

  /// The preferred smallest size the scrollbar can shrink to when viewport is
  /// overscrolled.
  ///
  /// When overscrolling, the size of the scrollbar may shrink to a smaller size
  /// than [minOverscrollLength] to fit in the available paint area. E.g., when
  /// [minOverscrollLength] is `double.infinity`, it will not be respected if
  /// the [ScrollMetrics.viewportDimension] and [mainAxisMargin] are finite.
  ///
  /// The value is less than or equal to [minLength] and greater than or equal to 0.
  /// If unspecified or set to null, it will defaults to the value of [minLength].
  final double minOverscrollLength;

  ScrollMetrics? _lastMetrics;
  AxisDirection? _lastAxisDirection;
  Rect? _thumbRect;

  /// Update with new [ScrollMetrics]. The scrollbar will show and redraw itself
  /// based on these new metrics.
  ///
  /// The scrollbar will remain on screen.
  void update(
    ScrollMetrics metrics,
    AxisDirection axisDirection,
  ) {
    _lastMetrics = metrics;
    _lastAxisDirection = axisDirection;
    notifyListeners();
  }

  /// Update and redraw with new scrollbar thickness and radius.
  void updateThickness(double nextThickness, Radius nextRadius) {
    thickness = nextThickness;
    radius = nextRadius;
    notifyListeners();
  }

  Paint get _paint {
    return Paint()
      ..color = color.withOpacity(color.opacity * fadeoutOpacityAnimation.value);
  }

  void _paintThumbCrossAxis(Canvas canvas, Size size, double thumbOffset, double thumbExtent, AxisDirection direction) {
    final double x, y;
    final Size thumbSize;

    switch (direction) {
      case AxisDirection.down:
        thumbSize = Size(thickness, thumbExtent);
        x = textDirection == TextDirection.rtl
          ? crossAxisMargin + padding.left
          : size.width - thickness - crossAxisMargin - padding.right;
        y = thumbOffset;
        break;
      case AxisDirection.up:
        thumbSize = Size(thickness, thumbExtent);
        x = textDirection == TextDirection.rtl
          ? crossAxisMargin + padding.left
          : size.width - thickness - crossAxisMargin - padding.right;
        y = thumbOffset;
        break;
      case AxisDirection.left:
        thumbSize = Size(thumbExtent, thickness);
        x = thumbOffset;
        y = size.height - thickness - crossAxisMargin - padding.bottom;
        break;
      case AxisDirection.right:
        thumbSize = Size(thumbExtent, thickness);
        x = thumbOffset;
        y = size.height - thickness - crossAxisMargin - padding.bottom;
        break;
    }

    _thumbRect = Offset(x, y) & thumbSize;
    if (radius == null)
      canvas.drawRect(_thumbRect!, _paint);
    else
      canvas.drawRRect(RRect.fromRectAndRadius(_thumbRect!, radius!), _paint);
  }

  double _thumbExtent() {
    // Thumb extent reflects fraction of content visible, as long as this
    // isn't less than the absolute minimum size.
    // _totalContentExtent >= viewportDimension, so (_totalContentExtent - _mainAxisPadding) > 0
    final double fractionVisible = ((_lastMetrics!.extentInside - _mainAxisPadding) / (_totalContentExtent - _mainAxisPadding))
      .clamp(0.0, 1.0);

    final double thumbExtent = math.max(
      math.min(_trackExtent, minOverscrollLength),
      _trackExtent * fractionVisible,
    );

    final double fractionOverscrolled = 1.0 - _lastMetrics!.extentInside / _lastMetrics!.viewportDimension;
    final double safeMinLength = math.min(minLength, _trackExtent);
    final double newMinLength = (_beforeExtent > 0 && _afterExtent > 0)
      // Thumb extent is no smaller than minLength if scrolling normally.
      ? safeMinLength
      // User is overscrolling. Thumb extent can be less than minLength
      // but no smaller than minOverscrollLength. We can't use the
      // fractionVisible to produce intermediate values between minLength and
      // minOverscrollLength when the user is transitioning from regular
      // scrolling to overscrolling, so we instead use the percentage of the
      // content that is still in the viewport to determine the size of the
      // thumb. iOS behavior appears to have the thumb reach its minimum size
      // with ~20% of overscroll. We map the percentage of minLength from
      // [0.8, 1.0] to [0.0, 1.0], so 0% to 20% of overscroll will produce
      // values for the thumb that range between minLength and the smallest
      // possible value, minOverscrollLength.
      : safeMinLength * (1.0 - fractionOverscrolled.clamp(0.0, 0.2) / 0.2);

    // The `thumbExtent` should be no greater than `trackSize`, otherwise
    // the scrollbar may scroll towards the wrong direction.
    return thumbExtent.clamp(newMinLength, _trackExtent);
  }

  @override
  void dispose() {
    fadeoutOpacityAnimation.removeListener(notifyListeners);
    super.dispose();
  }

  bool get _isVertical => _lastAxisDirection == AxisDirection.down || _lastAxisDirection == AxisDirection.up;
  bool get _isReversed => _lastAxisDirection == AxisDirection.up || _lastAxisDirection == AxisDirection.left;
  // The amount of scroll distance before and after the current position.
  double get _beforeExtent => _isReversed ? _lastMetrics!.extentAfter : _lastMetrics!.extentBefore;
  double get _afterExtent => _isReversed ? _lastMetrics!.extentBefore : _lastMetrics!.extentAfter;
  // Padding of the thumb track.
  double get _mainAxisPadding => _isVertical ? padding.vertical : padding.horizontal;
  // The size of the thumb track.
  double get _trackExtent => _lastMetrics!.viewportDimension - 2 * mainAxisMargin - _mainAxisPadding;

  // The total size of the scrollable content.
  double get _totalContentExtent {
    return _lastMetrics!.maxScrollExtent
      - _lastMetrics!.minScrollExtent
      + _lastMetrics!.viewportDimension;
  }

  /// Convert between a thumb track position and the corresponding scroll
  /// position.
  ///
  /// thumbOffsetLocal is a position in the thumb track. Cannot be null.
  double getTrackToScroll(double thumbOffsetLocal) {
    assert(thumbOffsetLocal != null);
    final double scrollableExtent = _lastMetrics!.maxScrollExtent - _lastMetrics!.minScrollExtent;
    final double thumbMovableExtent = _trackExtent - _thumbExtent();

    return scrollableExtent * thumbOffsetLocal / thumbMovableExtent;
  }

  // Converts between a scroll position and the corresponding position in the
  // thumb track.
  double _getScrollToTrack(ScrollMetrics metrics, double thumbExtent) {
    final double scrollableExtent = metrics.maxScrollExtent - metrics.minScrollExtent;

    final double fractionPast = (scrollableExtent > 0)
      ? ((metrics.pixels - metrics.minScrollExtent) / scrollableExtent).clamp(0.0, 1.0)
      : 0;

    return (_isReversed ? 1 - fractionPast : fractionPast) * (_trackExtent - thumbExtent);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_lastAxisDirection == null
        || _lastMetrics == null
        || fadeoutOpacityAnimation.value == 0.0)
      return;

    // Skip painting if there's not enough space.
    if (_lastMetrics!.viewportDimension <= _mainAxisPadding || _trackExtent <= 0) {
      return;
    }

    final double beforePadding = _isVertical ? padding.top : padding.left;
    final double thumbExtent = _thumbExtent();
    final double thumbOffsetLocal = _getScrollToTrack(_lastMetrics!, thumbExtent);
    final double thumbOffset = thumbOffsetLocal + mainAxisMargin + beforePadding;

    return _paintThumbCrossAxis(canvas, size, thumbOffset, thumbExtent, _lastAxisDirection!);
  }

  /// Same as hitTest, but includes some padding to make sure that the region
  /// isn't too small to be interacted with by the user.
  bool hitTestInteractive(Offset position) {
    if (_thumbRect == null) {
      return false;
    }
    // The thumb is not able to be hit when transparent.
    if (fadeoutOpacityAnimation.value == 0.0) {
      return false;
    }
    final Rect interactiveThumbRect = _thumbRect!.expandToInclude(
      Rect.fromCircle(center: _thumbRect!.center, radius: _kMinInteractiveSize / 2),
    );
    return interactiveThumbRect.contains(position);
  }

  // Scrollbars can be interactive in Cupertino.
  @override
  bool? hitTest(Offset? position) {
    if (_thumbRect == null) {
      return null;
    }
    // The thumb is not able to be hit when transparent.
    if (fadeoutOpacityAnimation.value == 0.0) {
      return false;
    }
    return _thumbRect!.contains(position!);
  }

  @override
  bool shouldRepaint(ScrollbarPainter old) {
    // Should repaint if any properties changed.
    return color != old.color
        || textDirection != old.textDirection
        || thickness != old.thickness
        || fadeoutOpacityAnimation != old.fadeoutOpacityAnimation
        || mainAxisMargin != old.mainAxisMargin
        || crossAxisMargin != old.crossAxisMargin
        || radius != old.radius
        || minLength != old.minLength
        || padding != old.padding;
  }

  @override
  bool shouldRebuildSemantics(CustomPainter oldDelegate) => false;

  @override
  SemanticsBuilderCallback? get semanticsBuilder => null;
}

///
abstract class RawScrollbarThumb extends StatefulWidget {
  /// Initializes fields for subclasses.
  const RawScrollbarThumb({
    Key? key,
    required this.child,
    this.controller,
    this.isAlwaysShown = false,
    this.radius,
    this.thickness,
    required this.fadeDuration,
    required this.timeToFade,
  }) : assert(!isAlwaysShown || controller != null, 'When isAlwaysShown is true, must pass a controller that is attached to a scroll view'),
       super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// The scrollbar will be stacked on top of this child. This child (and its
  /// subtree) should include a source of [ScrollNotification] notifications.
  ///
  /// Typically a [ListView] or [CustomScrollView].
  final Widget child;

  /// The [ScrollController] used to implement Scrollbar dragging.
  ///
  /// If nothing is passed to controller, the default behavior is to automatically
  /// enable scrollbar dragging on the nearest ScrollController using
  /// [PrimaryScrollController.of].
  ///
  /// If a ScrollController is passed, then scrollbar dragging will be enabled on
  /// the given ScrollController. A stateful ancestor of the RawScrollbarThumb
  /// subclass needs to manage the ScrollController and either pass it to a
  /// scrollable descendant or use a PrimaryScrollController to share it.
  ///
  /// Here is an example of using the `controller` parameter to enable
  /// scrollbar dragging for multiple independent ListViews:
  ///
  /// {@tool snippet}
  ///
  /// ```dart
  /// final ScrollController _controllerOne = ScrollController();
  /// final ScrollController _controllerTwo = ScrollController();
  ///
  /// build(BuildContext context) {
  /// return Column(
  ///   children: <Widget>[
  ///     Container(
  ///        height: 200,
  ///        child: CupertinoScrollbar(
  ///          controller: _controllerOne,
  ///          child: ListView.builder(
  ///            controller: _controllerOne,
  ///            itemCount: 120,
  ///            itemBuilder: (BuildContext context, int index) => Text('item $index'),
  ///          ),
  ///        ),
  ///      ),
  ///      Container(
  ///        height: 200,
  ///        child: CupertinoScrollbar(
  ///          controller: _controllerTwo,
  ///          child: ListView.builder(
  ///            controller: _controllerTwo,
  ///            itemCount: 120,
  ///            itemBuilder: (BuildContext context, int index) => Text('list 2 item $index'),
  ///          ),
  ///        ),
  ///      ),
  ///    ],
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  final ScrollController? controller;

  /// Indicates whether the [Scrollbar] should always be visible.
  ///
  /// When false, the scrollbar will be shown during scrolling
  /// and will fade out otherwise.
  ///
  /// When true, the scrollbar will always be visible and never fade out.
  ///
  /// The [controller] property must be set in this case.
  /// It should be passed the relevant [Scrollable]'s [ScrollController].
  ///
  /// Defaults to false.
  ///
  /// {@tool snippet}
  ///
  /// ```dart
  /// final ScrollController _controllerOne = ScrollController();
  /// final ScrollController _controllerTwo = ScrollController();
  ///
  /// build(BuildContext context) {
  /// return Column(
  ///   children: <Widget>[
  ///     Container(
  ///        height: 200,
  ///        child: Scrollbar(
  ///          isAlwaysShown: true,
  ///          controller: _controllerOne,
  ///          child: ListView.builder(
  ///            controller: _controllerOne,
  ///            itemCount: 120,
  ///            itemBuilder: (BuildContext context, int index)
  ///                => Text('item $index'),
  ///          ),
  ///        ),
  ///      ),
  ///      Container(
  ///        height: 200,
  ///        child: CupertinoScrollbar(
  ///          isAlwaysShown: true,
  ///          controller: _controllerTwo,
  ///          child: SingleChildScrollView(
  ///            controller: _controllerTwo,
  ///            child: SizedBox(height: 2000, width: 500,),
  ///          ),
  ///        ),
  ///      ),
  ///    ],
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  final bool isAlwaysShown;

  /// The radius of the corners of the scrollbar.
  ///
  /// By default (if this is left null), each platform will get a radius
  /// that matches the look and feel of the platform, and the radius may
  /// change while the scrollbar is being dragged if the platform look and feel
  /// calls for such behavior.
  final Radius? radius;

  /// The thickness of the scrollbar.
  ///
  /// By default (if this is left null), each platform will get a thickness
  /// that matches the look and feel of the platform, and the thickness may
  /// grow while the scrollbar is being dragged if the platform look and feel
  /// calls for such behavior.
  final double? thickness;

  ///
  final Duration fadeDuration;

  ///
  final Duration timeToFade;

  @override
  RawScrollbarThumbState<RawScrollbarThumb> createState();
}

/// Doc
abstract class RawScrollbarThumbState<T extends RawScrollbarThumb> extends State<T> with TickerProviderStateMixin<T> {
  double? _dragScrollbarAxisPosition;
  Drag? _drag;
  ScrollController? _currentController;

  ///
  @protected
  ScrollbarPainter? get painter;

  ///
  @protected
  GlobalKey get customPaintKey;

  ///
  @protected
  AnimationController get fadeoutAnimationController => _fadeoutAnimationController;
  late AnimationController _fadeoutAnimationController;
  
  ///
  @protected
  Animation<double> get fadeoutOpacityAnimation => _fadeoutOpacityAnimation;
  late Animation<double> _fadeoutOpacityAnimation;

  ///
  @protected
  Timer? get fadeoutTimer => _fadeoutTimer;
  Timer? _fadeoutTimer;
  set fadeoutTimer(Timer? value) {
    _fadeoutTimer = value;
  }
  
  @override
  void initState() {
    super.initState();
    _fadeoutAnimationController = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    );
    _fadeoutOpacityAnimation = CurvedAnimation(
      parent: _fadeoutAnimationController,
      curve: Curves.fastOutSlowIn,
    );
  }

  /// Waits one frame and cause an empty scroll event.
  ///
  /// This allows the thumb to show immediately when isAlwaysShown is true.
  /// A scroll event is required in order to paint the thumb.
  @protected
  void triggerScrollbar() {
    WidgetsBinding.instance!.addPostFrameCallback((Duration duration) {
      if (widget.isAlwaysShown) {
        _fadeoutTimer?.cancel();
        // Wait one frame and cause an empty scroll event.  This allows the
        // thumb to show immediately when isAlwaysShown is true.  A scroll
        // event is required in order to paint the thumb.
        widget.controller!.position.didUpdateScrollPositionBy(0);
      }
    });
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAlwaysShown != oldWidget.isAlwaysShown) {
      if (widget.isAlwaysShown == true) {
        triggerScrollbar();
        _fadeoutAnimationController.animateTo(1.0);
      } else {
        _fadeoutAnimationController.reverse();
      }
    }
  }

  void _dragScrollbar(double primaryDelta) {
    assert(_currentController != null);

    // Convert primaryDelta, the amount that the scrollbar moved since the last
    // time _dragScrollbar was called, into the coordinate space of the scroll
    // position, and create/update the drag event with that position.
    final double scrollOffsetLocal = painter!.getTrackToScroll(primaryDelta);
    final double scrollOffsetGlobal = scrollOffsetLocal + _currentController!.position.pixels;
    final Axis direction = _currentController!.position.axis;

    if (_drag == null) {
      _drag = _currentController!.position.drag(
        DragStartDetails(
          globalPosition: direction == Axis.vertical
            ? Offset(0.0, scrollOffsetGlobal)
            : Offset(scrollOffsetGlobal, 0.0),
        ),
          () {},
      );
    } else {
      _drag!.update(DragUpdateDetails(
        globalPosition: direction == Axis.vertical
          ? Offset(0.0, scrollOffsetGlobal)
          : Offset(scrollOffsetGlobal, 0.0),
        delta: direction == Axis.vertical
          ? Offset(0.0, -scrollOffsetLocal)
          : Offset(-scrollOffsetLocal, 0.0),
        primaryDelta: -scrollOffsetLocal,
      ));
    }
  }

  void _maybeStartFadeoutTimer() {
    if (!widget.isAlwaysShown) {
      _fadeoutTimer?.cancel();
      _fadeoutTimer = Timer(widget.timeToFade, () {
        _fadeoutAnimationController.reverse();
        _fadeoutTimer = null;
      });
    }
  }

  /// Doc
  @protected
  Axis? getDirection() {
    try {
      return _currentController!.position.axis;
    } catch (_) {
      // Ignore the gesture if we cannot determine the direction.
      return null;
    }
  }

  ///
  @protected
  void handleLongPress() {
    if (getDirection() == null) {
      return;
    }
    fadeoutTimer?.cancel();
  }

  /// Doc
  @protected
  void handleLongPressStart(LongPressStartDetails details) {
    _currentController = widget.controller ?? PrimaryScrollController.of(context);
    final Axis? direction = getDirection();
    if (direction == null) {
      return;
    }
    _fadeoutTimer?.cancel();
    _fadeoutAnimationController.forward();
    switch (direction) {
      case Axis.vertical:
        _dragScrollbar(details.localPosition.dy);
        _dragScrollbarAxisPosition = details.localPosition.dy;
        break;
      case Axis.horizontal:
        _dragScrollbar(details.localPosition.dx);
        _dragScrollbarAxisPosition = details.localPosition.dx;
        break;
    }
  }

  /// Doc
  @protected
  void handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    final Axis? direction = getDirection();
    if (direction == null) {
      return;
    }
    switch(direction) {
      case Axis.vertical:
        _dragScrollbar(details.localPosition.dy - _dragScrollbarAxisPosition!);
        _dragScrollbarAxisPosition = details.localPosition.dy;
        break;
      case Axis.horizontal:
        _dragScrollbar(details.localPosition.dx - _dragScrollbarAxisPosition!);
        _dragScrollbarAxisPosition = details.localPosition.dx;
        break;
    }
  }

  /// Doc
  @protected
  void handleLongPressEnd(LongPressEndDetails details) {
    final Axis? direction = getDirection();
    if (direction == null)
      return;
    final Offset pixelsPerSecond = details.velocity.pixelsPerSecond;
    _maybeStartFadeoutTimer();
    _dragScrollbarAxisPosition = null;
    final double scrollVelocity = painter!.getTrackToScroll(
      direction == Axis.vertical
        ? pixelsPerSecond.dy
        : pixelsPerSecond.dx
    );
    _drag?.end(DragEndDetails(
      primaryVelocity: -scrollVelocity,
      velocity: Velocity(
        pixelsPerSecond: direction == Axis.vertical
          ? Offset(0.0, -scrollVelocity)
          : Offset(-scrollVelocity, 0.0),
      ),
    ));
    _drag = null;
    _currentController = null;
  }

  /// Handles [ScrollNotification]s
  @protected
  bool handleScrollNotification(ScrollNotification notification) {
    final ScrollMetrics metrics = notification.metrics;
    if (metrics.maxScrollExtent <= metrics.minScrollExtent)
      return false;

    if (notification is ScrollUpdateNotification ||
      notification is OverscrollNotification) {
      // Any movements always makes the scrollbar start showing up.
      if (_fadeoutAnimationController.status != AnimationStatus.forward)
        _fadeoutAnimationController.forward();

      fadeoutTimer?.cancel();
      painter!.update(notification.metrics, notification.metrics.axisDirection);
    } else if (notification is ScrollEndNotification) {
      if (_dragScrollbarAxisPosition == null)
        _maybeStartFadeoutTimer();
    }
    return false;
  }

  /// Get the GestureRecognizerFactories used to detect gestures on the scrollbar
  /// thumb.
  @protected
  Map<Type, GestureRecognizerFactory> get gestures {
    final Map<Type, GestureRecognizerFactory> gestures = <Type, GestureRecognizerFactory>{};
    final ScrollController? controller = widget.controller ?? PrimaryScrollController.of(context);
    if (controller == null)
      return gestures;

    gestures[_ThumbPressGestureRecognizer] =
      GestureRecognizerFactoryWithHandlers<_ThumbPressGestureRecognizer>(
          () => _ThumbPressGestureRecognizer(
          debugOwner: this,
          customPaintKey: customPaintKey,
        ),
          (_ThumbPressGestureRecognizer instance) {
          instance
            ..onLongPress = handleLongPress
            ..onLongPressStart = handleLongPressStart
            ..onLongPressMoveUpdate = handleLongPressMoveUpdate
            ..onLongPressEnd = handleLongPressEnd;
        },
      );

    return gestures;
  }

  @override
  void dispose() {
    _fadeoutAnimationController.dispose();
    _fadeoutTimer?.cancel();
    painter?.dispose();
    super.dispose();
  }
}
// A long press gesture detector that only responds to events on the scrollbar's
// thumb and ignores everything else.
class _ThumbPressGestureRecognizer extends LongPressGestureRecognizer {
  _ThumbPressGestureRecognizer({
    double? postAcceptSlopTolerance,
    PointerDeviceKind? kind,
    required Object debugOwner,
    required GlobalKey customPaintKey,
  }) :  _customPaintKey = customPaintKey,
      super(
      postAcceptSlopTolerance: postAcceptSlopTolerance,
      kind: kind,
      debugOwner: debugOwner,
      duration: const Duration(milliseconds: 100),
    );

  final GlobalKey _customPaintKey;

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    if (!_hitTestInteractive(_customPaintKey, event.position)) {
      return false;
    }
    return super.isPointerAllowed(event);
  }

  bool _hitTestInteractive(GlobalKey customPaintKey, Offset offset) {
    if (customPaintKey.currentContext == null) {
      return false;
    }
    final CustomPaint customPaint = customPaintKey.currentContext!.widget as CustomPaint;
    final ScrollbarPainter painter = customPaint.foregroundPainter! as ScrollbarPainter;
    final RenderBox renderBox = customPaintKey.currentContext!.findRenderObject()! as RenderBox;
    final Offset localOffset = renderBox.globalToLocal(offset);
    return painter.hitTestInteractive(localOffset);
  }
}
