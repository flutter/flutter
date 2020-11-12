// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'notification_listener.dart';
import 'scroll_controller.dart';
import 'scroll_metrics.dart';
import 'scroll_notification.dart';
import 'scrollable.dart';

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
class RawScrollbar extends StatefulWidget {
  ///
  const RawScrollbar({
    Key? key,
    this.leading,
    this.track,
    required this.thumb,
    this.trailing,
    required this.child,
    this.controller,
    this.overlapsChild = false,
    this.isAlwaysShown = false,
    //animateOnHover
    //hoverAnimationDuration
    //animateOnScroll
    //scrollAnimationDuration
    //animateOnDrag
    //dragAnimationDuration
  }) : super(key: key);

  // TODO(Piinks): leading, track, thumb, trailing should all be builders to
  //  pass animation values, whether drag is active etc.
  ///
  final Widget? leading;
  ///
  final Widget? track;
  ///
  final Widget thumb;
  ///
  final Widget? trailing;
  ///
  final Widget child;
  ///
  final ScrollController? controller;
  ///
  final bool overlapsChild;
  ///
  final bool isAlwaysShown;

  @override
  _RawScrollbarState createState() => _RawScrollbarState();
}

class _RawScrollbarState extends State<RawScrollbar> {
  ScrollMetrics? _lastMetrics;
  late _ScrollbarLayout _scrollbarLayoutDelegate;

  bool _handleScrollNotification(ScrollNotification notification) {
    setState(() {
      _lastMetrics = notification.metrics;
    });

    if (_lastMetrics!.maxScrollExtent <= _lastMetrics!.minScrollExtent) {
      return false;
    }
    return false;
  }

  void _handleTrackTapDown(TapDownDetails details) {
    // TODO(Piink): There are a lot of different behaviors we could support here,
    // it's really a matter of how many and how to configure? For now, just paging.
    assert(widget.controller != null);
    // Tapping the scrollbar track pages up or down the scroll view.
    double scrollIncrement = 0.0;
    // Is an increment calculator available?
    final ScrollIncrementCalculator? calculator = Scrollable.of(
      widget.controller!.position.context.notificationContext!
    )?.widget.incrementCalculator;
    if (calculator != null) {
      scrollIncrement = calculator(
        ScrollIncrementDetails(
          type: ScrollIncrementType.page,
          metrics: widget.controller!.position,
        )
      );
    } else {
      scrollIncrement = 0.8 * widget.controller!.position.viewportDimension;
    }
    // Determine direction to scroll in
    final int incrementCorrection = _scrollbarLayoutDelegate.getTrackIncrementCorrection(details.localPosition);
    widget.controller!.position.moveTo(
      widget.controller!.position.pixels + incrementCorrection * scrollIncrement,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    _scrollbarLayoutDelegate = _ScrollbarLayout(
      textDirection: Directionality.of(context),
      overlapsChild: widget.overlapsChild,
      controller: widget.controller,
      metrics: _lastMetrics,
    );
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: CustomMultiChildLayout(
        delegate: _scrollbarLayoutDelegate,
        children: <Widget>[
          // Any gestures in the leading widget are handled by the user
          if (widget.leading != null)
            LayoutId(
              id: _ScrollbarSlot.leading,
              child: widget.leading!,
            ),
          if (widget.track != null)
            // TODO(Piinks): Should users implement tap gestures? What if they
            //  want their tracks to have inkwell etc?
            LayoutId(
              id: _ScrollbarSlot.track,
              child: widget.controller != null
                ? GestureDetector(
                    onTapDown: _handleTrackTapDown,
                    child: widget.track!,
                  )
                : widget.track!,
            ),
          // TODO(Piinks): Add drag gestures?
          LayoutId(
            id: _ScrollbarSlot.thumb,
            child: widget.thumb,
          ),
          // Any gestures in the trailing widget are handled by the user
          if (widget.trailing != null)
            LayoutId(
              id: _ScrollbarSlot.trailing,
              child: widget.trailing!,
            ),
          LayoutId(
            id: _ScrollbarSlot.child,
            child: widget.child,
          )
        ],
      ),
    );
  }
}

enum _ScrollbarSlot {
  leading,
  track,
  thumb,
  trailing,
  child,
}

class _ScrollbarLayout extends MultiChildLayoutDelegate {
  _ScrollbarLayout({
    this.overlapsChild = false,
    this.controller,
    this.metrics,
    required this.textDirection,
  }) : assert(controller != null || metrics != null),
       assert(overlapsChild != null);


  final bool overlapsChild;
  final ScrollController? controller;
  final ScrollMetrics? metrics;
  final TextDirection textDirection;
  late double _thumbLocalPosition;
  
  int getTrackIncrementCorrection(Offset localPosition) {
    final AxisDirection direction = controller?.position.axisDirection ?? metrics!.axisDirection;
    switch (direction) {
      case AxisDirection.up:
        if (localPosition.dy > _thumbLocalPosition)
          return -1;
        return 1;
      case AxisDirection.down:
        if (localPosition.dy > _thumbLocalPosition)
          return 1;
        return -1;
      case AxisDirection.right:
        if (localPosition.dx > _thumbLocalPosition)
          return 1;
        return -1;
      case AxisDirection.left:
        if (localPosition.dx > _thumbLocalPosition)
          return -1;
        return 1;
    }
  }

  @override
  void performLayout(Size size) {
    final BoxConstraints looseConstraints = BoxConstraints.loose(size);
    final AxisDirection direction = controller?.position.axisDirection ?? metrics!.axisDirection;
    final Axis scrollAxis = controller?.position.axis ?? metrics!.axis;
    double trackPadding = 0.0;

    if (overlapsChild) {
      // TODO(Piinks): This does not work yet..
      // Scrollbar is laid out on top of the child, does not contribute to
      // padding it.
      layoutChild(_ScrollbarSlot.child, looseConstraints);
    }

    // Leading Widget
    Size leadingSize = Size.zero;
    if (hasChild(_ScrollbarSlot.leading)) {
      leadingSize = layoutChild(_ScrollbarSlot.leading, looseConstraints);
      double x, y;
      switch (direction) {
        case AxisDirection.down:
          x = textDirection == TextDirection.rtl ? 0.0 : size.width - leadingSize.width;
          y = 0.0;
          trackPadding += leadingSize.height;
          break;
        case AxisDirection.up:
          x = textDirection == TextDirection.rtl ? 0.0 : size.width - leadingSize.width;
          y = size.height - leadingSize.height;
          trackPadding += leadingSize.height;
          break;
        case AxisDirection.left:
          x = size.width - leadingSize.width;
          y = size.height - leadingSize.height;
          trackPadding += leadingSize.width;
          break;
        case AxisDirection.right:
          x = 0.0;
          y = size.height - leadingSize.height;
          trackPadding += leadingSize.width;
          break;
      }
      positionChild(_ScrollbarSlot.leading, Offset(x, y));
    }

    // Trailing Widget
    Size? trailingSize;
    if (hasChild(_ScrollbarSlot.trailing)) {
      trailingSize = layoutChild(_ScrollbarSlot.trailing, looseConstraints);
      double x, y;
      switch (direction) {
        case AxisDirection.down:
          x = textDirection == TextDirection.rtl ? 0.0 : size.width - trailingSize.width;
          y = size.height - trailingSize.height;
          trackPadding += trailingSize.height;
          break;
        case AxisDirection.up:
          x = textDirection == TextDirection.rtl ? 0.0 : size.width - trailingSize.width;
          y = 0.0;
          trackPadding += trailingSize.height;
          break;
        case AxisDirection.left:
          x = 0.0;
          y = size.height - trailingSize.height;
          trackPadding += trailingSize.width;
          break;
        case AxisDirection.right:
          x = size.width - trailingSize.width;
          y = size.height - trailingSize.height;
          trackPadding += trailingSize.width;
          break;
      }
      positionChild(_ScrollbarSlot.trailing, Offset(x, y));
    }

    final BoxConstraints trackConstraints = scrollAxis == Axis.vertical
      ? BoxConstraints(maxHeight: size.height - trackPadding)
      : BoxConstraints(maxWidth: size.width - trackPadding);
    // Track Widget
    Size? trackSize;
    if (hasChild(_ScrollbarSlot.track)) {
      trackSize = layoutChild(_ScrollbarSlot.track, trackConstraints);
      double x, y;
      switch (direction) {
        case AxisDirection.down:
        case AxisDirection.up:
          x = textDirection == TextDirection.rtl ? 0.0 : size.width - trackSize.width;
          y = leadingSize.height;
          break;
        case AxisDirection.left:
        case AxisDirection.right:
          x = leadingSize.width;
          y = size.height - trackSize.height;
          break;
      }
      positionChild(_ScrollbarSlot.track, Offset(x, y));
    }

    // Thumb Widget
    final Size thumbSize = layoutChild(_ScrollbarSlot.thumb, trackConstraints);
    late double maxScrollExtent;
    // TODO(Piinks): Handle infinite scroll views
    // Assume always [~100 || custom number] of pixels ahead, and add to current offset?
    // Also check variable sized list items performance.
    try {
      maxScrollExtent = controller?.position.maxScrollExtent ?? metrics!.maxScrollExtent;
    } catch (_) {
      maxScrollExtent = 0.0;
    }

    final double scrollOffset = controller?.offset ?? metrics!.pixels;
    final double fractionalOffset = maxScrollExtent == 0.0
      ? 0.0
      : (scrollOffset / maxScrollExtent).clamp(0.0, 1.0);
    double x, y;
    switch (direction) {
      case AxisDirection.down:
        x = textDirection == TextDirection.rtl ? 0.0 : size.width - thumbSize.width;
        _thumbLocalPosition = (size.height - trackPadding - thumbSize.height) * fractionalOffset;
        y = _thumbLocalPosition + leadingSize.height;
        break;
      case AxisDirection.up:
        x = textDirection == TextDirection.rtl ? 0.0 : size.width - thumbSize.width;
        _thumbLocalPosition = (size.height - trackPadding - thumbSize.height) * (1 - fractionalOffset);
        y = _thumbLocalPosition + leadingSize.height;
        break;
      case AxisDirection.left:
        _thumbLocalPosition = (size.width - trackPadding - thumbSize.width) * (1 - fractionalOffset);
        x = _thumbLocalPosition + leadingSize.width;
        y = size.height - thumbSize.height;
        break;
      case AxisDirection.right:
        _thumbLocalPosition = (size.width - trackPadding - thumbSize.width) * fractionalOffset;
        x = _thumbLocalPosition + leadingSize.width;
        y = size.height - thumbSize.height;
        break;
    }
    positionChild(_ScrollbarSlot.thumb, Offset(x, y));

    // Child
    if (!overlapsChild) {
      layoutChild(
        _ScrollbarSlot.child,
        scrollAxis == Axis.vertical
          ? BoxConstraints(
              maxWidth: size.width - thumbSize.width,
              maxHeight: size.height,
            )
          : BoxConstraints(
              maxHeight: size.height - thumbSize.height,
              maxWidth: size.width,
            ),
      );
    }
  }

  @override
  bool shouldRelayout(_ScrollbarLayout oldDelegate) {
    return  oldDelegate.textDirection != textDirection
      || oldDelegate.controller != controller
      || oldDelegate.metrics != metrics
      || oldDelegate.overlapsChild != overlapsChild;
  }
}
