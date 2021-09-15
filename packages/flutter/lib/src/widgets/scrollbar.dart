// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'binding.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'media_query.dart';
import 'notification_listener.dart';
import 'primary_scroll_controller.dart';
import 'scroll_controller.dart';
import 'scroll_metrics.dart';
import 'scroll_notification.dart';
import 'scroll_position.dart';
import 'scrollable.dart';
import 'ticker_provider.dart';

const double _kMinThumbExtent = 18.0;
const double _kMinInteractiveSize = 48.0;
const double _kScrollbarThickness = 6.0;
const Duration _kScrollbarFadeDuration = Duration(milliseconds: 300);
const Duration _kScrollbarTimeToFade = Duration(milliseconds: 600);

/// An orientation along either the horizontal or vertical [Axis].
enum ScrollbarOrientation {
  /// Place towards the left of the screen.
  left,

  /// Place towards the right of the screen.
  right,

  /// Place on top of the screen.
  top,

  /// Place on the bottom of the screen.
  bottom,
}

/// Paints a scrollbar's track and thumb.
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
    required this.fadeoutOpacityAnimation,
    Color trackColor = const Color(0x00000000),
    Color trackBorderColor = const Color(0x00000000),
    TextDirection? textDirection,
    double thickness = _kScrollbarThickness,
    EdgeInsets padding = EdgeInsets.zero,
    double mainAxisMargin = 0.0,
    double crossAxisMargin = 0.0,
    Radius? radius,
    OutlinedBorder? shape,
    double minLength = _kMinThumbExtent,
    double? minOverscrollLength,
    ScrollbarOrientation? scrollbarOrientation,
  }) : assert(color != null),
       assert(radius == null || shape == null),
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
       _thickness = thickness,
       _radius = radius,
       _shape = shape,
       _padding = padding,
       _mainAxisMargin = mainAxisMargin,
       _crossAxisMargin = crossAxisMargin,
       _minLength = minLength,
       _trackColor = trackColor,
       _trackBorderColor = trackBorderColor,
       _scrollbarOrientation = scrollbarOrientation,
       _minOverscrollLength = minOverscrollLength ?? minLength {
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

  /// [Color] of the track. Mustn't be null.
  Color get trackColor => _trackColor;
  Color _trackColor;
  set trackColor(Color value) {
    assert(value != null);
    if (trackColor == value)
      return;

    _trackColor = value;
    notifyListeners();
  }

  /// [Color] of the track border. Mustn't be null.
  Color get trackBorderColor => _trackBorderColor;
  Color _trackBorderColor;
  set trackBorderColor(Color value) {
    assert(value != null);
    if (trackBorderColor == value)
      return;

    _trackBorderColor = value;
    notifyListeners();
  }

  /// [TextDirection] of the [BuildContext] which dictates the side of the
  /// screen the scrollbar appears in (the trailing side). Must be set prior to
  /// calling paint.
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    assert(value != null);
    if (textDirection == value)
      return;

    _textDirection = value;
    notifyListeners();
  }

  /// Thickness of the scrollbar in its cross-axis in logical pixels. Mustn't be null.
  double get thickness => _thickness;
  double _thickness;
  set thickness(double value) {
    assert(value != null);
    if (thickness == value)
      return;

    _thickness = value;
    notifyListeners();
  }

  /// An opacity [Animation] that dictates the opacity of the thumb.
  /// Changes in value of this [Listenable] will automatically trigger repaints.
  /// Mustn't be null.
  final Animation<double> fadeoutOpacityAnimation;

  /// Distance from the scrollbar's start and end to the edge of the viewport
  /// in logical pixels. It affects the amount of available paint area.
  ///
  /// Mustn't be null and defaults to 0.
  double get mainAxisMargin => _mainAxisMargin;
  double _mainAxisMargin;
  set mainAxisMargin(double value) {
    assert(value != null);
    if (mainAxisMargin == value)
      return;

    _mainAxisMargin = value;
    notifyListeners();
  }

  /// Distance from the scrollbar thumb to the nearest cross axis edge
  /// in logical pixels.
  ///
  /// Must not be null and defaults to 0.
  double get crossAxisMargin => _crossAxisMargin;
  double _crossAxisMargin;
  set crossAxisMargin(double value) {
    assert(value != null);
    if (crossAxisMargin == value)
      return;

    _crossAxisMargin = value;
    notifyListeners();
  }

  /// [Radius] of corners if the scrollbar should have rounded corners.
  ///
  /// Scrollbar will be rectangular if [radius] is null.
  Radius? get radius => _radius;
  Radius? _radius;
  set radius(Radius? value) {
    assert(shape == null || value == null);
    if (radius == value)
      return;

    _radius = value;
    notifyListeners();
  }

  /// The [OutlinedBorder] of the scrollbar's thumb.
  ///
  /// Only one of [radius] and [shape] may be specified. For a rounded rectangle,
  /// it's simplest to just specify [radius]. By default, the scrollbar thumb's
  /// shape is a simple rectangle.
  ///
  /// If [shape] is specified, the thumb will take the shape of the passed
  /// [OutlinedBorder] and fill itself with [color] (or grey if it
  /// is unspecified).
  ///
  OutlinedBorder? get shape => _shape;
  OutlinedBorder? _shape;
  set shape(OutlinedBorder? value){
    assert(radius == null || value == null);
    if(shape == value)
      return;

    _shape = value;
    notifyListeners();
  }
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


  /// The preferred smallest size the scrollbar thumb can shrink to when the total
  /// scrollable extent is large, the current visible viewport is small, and the
  /// viewport is not overscrolled.
  ///
  /// The size of the scrollbar may shrink to a smaller size than [minLength] to
  /// fit in the available paint area. E.g., when [minLength] is
  /// `double.infinity`, it will not be respected if
  /// [ScrollMetrics.viewportDimension] and [mainAxisMargin] are finite.
  ///
  /// Mustn't be null and the value has to be greater or equal to
  /// [minOverscrollLength], which in turn is >= 0. Defaults to 18.0.
  double get minLength => _minLength;
  double _minLength;
  set minLength(double value) {
    assert(value != null);
    if (minLength == value)
      return;

    _minLength = value;
    notifyListeners();
  }

  /// The preferred smallest size the scrollbar thumb can shrink to when viewport is
  /// overscrolled.
  ///
  /// When overscrolling, the size of the scrollbar may shrink to a smaller size
  /// than [minOverscrollLength] to fit in the available paint area. E.g., when
  /// [minOverscrollLength] is `double.infinity`, it will not be respected if
  /// the [ScrollMetrics.viewportDimension] and [mainAxisMargin] are finite.
  ///
  /// The value is less than or equal to [minLength] and greater than or equal to 0.
  /// When null, it will default to the value of [minLength].
  double get minOverscrollLength => _minOverscrollLength;
  double _minOverscrollLength;
  set minOverscrollLength(double value) {
    assert(value != null);
    if (minOverscrollLength == value)
      return;

    _minOverscrollLength = value;
    notifyListeners();
  }

  /// {@template flutter.widgets.Scrollbar.scrollbarOrientation}
  /// Dictates the orientation of the scrollbar.
  ///
  /// [ScrollbarOrientation.top] places the scrollbar on top of the screen.
  /// [ScrollbarOrientation.bottom] places the scrollbar on the bottom of the screen.
  /// [ScrollbarOrientation.left] places the scrollbar on the left of the screen.
  /// [ScrollbarOrientation.right] places the scrollbar on the right of the screen.
  ///
  /// [ScrollbarOrientation.top] and [ScrollbarOrientation.bottom] can only be
  /// used with a vertical scroll.
  /// [ScrollbarOrientation.left] and [ScrollbarOrientation.right] can only be
  /// used with a horizontal scroll.
  ///
  /// For a vertical scroll the orientation defaults to
  /// [ScrollbarOrientation.right] for [TextDirection.ltr] and
  /// [ScrollbarOrientation.left] for [TextDirection.rtl].
  /// For a horizontal scroll the orientation defaults to [ScrollbarOrientation.bottom].
  /// {@endtemplate}
  ScrollbarOrientation? get scrollbarOrientation => _scrollbarOrientation;
  ScrollbarOrientation? _scrollbarOrientation;
  set scrollbarOrientation(ScrollbarOrientation? value) {
    if (scrollbarOrientation == value)
      return;

    _scrollbarOrientation = value;
    notifyListeners();
  }

  void _debugAssertIsValidOrientation(ScrollbarOrientation orientation) {
    assert(
    (_isVertical && _isVerticalOrientation(orientation)) || (!_isVertical && !_isVerticalOrientation(orientation)),
    'The given ScrollbarOrientation: $orientation is incompatible with the current AxisDirection: $_lastAxisDirection.'
    );
  }

  /// Check whether given scrollbar orientation is vertical
  bool _isVerticalOrientation(ScrollbarOrientation orientation) =>
    orientation == ScrollbarOrientation.left
    || orientation == ScrollbarOrientation.right;

  ScrollMetrics? _lastMetrics;
  AxisDirection? _lastAxisDirection;
  Rect? _thumbRect;
  Rect? _trackRect;
  late double _thumbOffset;

  /// Update with new [ScrollMetrics]. If the metrics change, the scrollbar will
  /// show and redraw itself based on these new metrics.
  ///
  /// The scrollbar will remain on screen.
  void update(
    ScrollMetrics metrics,
    AxisDirection axisDirection,
  ) {
    if (_lastMetrics != null &&
        _lastMetrics!.extentBefore == metrics.extentBefore &&
        _lastMetrics!.extentInside == metrics.extentInside &&
        _lastMetrics!.extentAfter == metrics.extentAfter &&
        _lastAxisDirection == axisDirection)
      return;

    final ScrollMetrics? oldMetrics = _lastMetrics;
    _lastMetrics = metrics;
    _lastAxisDirection = axisDirection;

    bool _needPaint(ScrollMetrics? metrics) => metrics != null && metrics.maxScrollExtent > metrics.minScrollExtent;
    if (!_needPaint(oldMetrics) && !_needPaint(metrics))
      return;

    notifyListeners();
  }

  /// Update and redraw with new scrollbar thickness and radius.
  void updateThickness(double nextThickness, Radius nextRadius) {
    thickness = nextThickness;
    radius = nextRadius;
  }

  Paint get _paintThumb {
    return Paint()
      ..color = color.withOpacity(color.opacity * fadeoutOpacityAnimation.value);
  }

  Paint _paintTrack({ bool isBorder = false }) {
    if (isBorder) {
      return Paint()
        ..color = trackBorderColor.withOpacity(trackBorderColor.opacity * fadeoutOpacityAnimation.value)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
    }
    return Paint()
      ..color = trackColor.withOpacity(trackColor.opacity * fadeoutOpacityAnimation.value);
  }

  void _paintScrollbar(Canvas canvas, Size size, double thumbExtent, AxisDirection direction) {
    assert(
      textDirection != null,
      'A TextDirection must be provided before a Scrollbar can be painted.',
    );

    final ScrollbarOrientation resolvedOrientation;

    if (scrollbarOrientation == null) {
      if (_isVertical)
        resolvedOrientation = textDirection == TextDirection.ltr
          ? ScrollbarOrientation.right
          : ScrollbarOrientation.left;
      else
        resolvedOrientation = ScrollbarOrientation.bottom;
    }
    else {
      resolvedOrientation = scrollbarOrientation!;
    }

    final double x, y;
    final Size thumbSize, trackSize;
    final Offset trackOffset;

    _debugAssertIsValidOrientation(resolvedOrientation);
    switch(resolvedOrientation) {
      case ScrollbarOrientation.left:
        thumbSize = Size(thickness, thumbExtent);
        trackSize = Size(thickness + 2 * crossAxisMargin, _trackExtent);
        x = crossAxisMargin + padding.left;
        y = _thumbOffset;
        trackOffset = Offset(x - crossAxisMargin, 0.0);
        break;
      case ScrollbarOrientation.right:
        thumbSize = Size(thickness, thumbExtent);
        trackSize = Size(thickness + 2 * crossAxisMargin, _trackExtent);
        x = size.width - thickness - crossAxisMargin - padding.right;
        y = _thumbOffset;
        trackOffset = Offset(x - crossAxisMargin, 0.0);
        break;
      case ScrollbarOrientation.top:
        thumbSize = Size(thumbExtent, thickness);
        trackSize = Size(_trackExtent, thickness + 2 * crossAxisMargin);
        x = _thumbOffset;
        y = crossAxisMargin + padding.top;
        trackOffset = Offset(0.0, y - crossAxisMargin);
        break;
      case ScrollbarOrientation.bottom:
        thumbSize = Size(thumbExtent, thickness);
        trackSize = Size(_trackExtent, thickness + 2 * crossAxisMargin);
        x = _thumbOffset;
        y = size.height - thickness - crossAxisMargin - padding.bottom;
        trackOffset = Offset(0.0, y - crossAxisMargin);
        break;
    }

    _trackRect = trackOffset & trackSize;
    canvas.drawRect(_trackRect!, _paintTrack());
    canvas.drawLine(
      trackOffset,
      Offset(trackOffset.dx, trackOffset.dy + _trackExtent),
      _paintTrack(isBorder: true),
    );

    _thumbRect = Offset(x, y) & thumbSize;

    if (radius != null) {
      canvas.drawRRect(RRect.fromRectAndRadius(_thumbRect!, radius!), _paintThumb);
      return;
    }

    if (shape == null) {
      canvas.drawRect(_thumbRect!, _paintThumb);
      return;
    }

    final Path outerPath = shape!.getOuterPath(_thumbRect!);
    canvas.drawPath(outerPath, _paintThumb);
    shape!.paint(canvas, _thumbRect!);
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
        || fadeoutOpacityAnimation.value == 0.0
        || _lastMetrics!.maxScrollExtent <= _lastMetrics!.minScrollExtent)
      return;

    // Skip painting if there's not enough space.
    if (_lastMetrics!.viewportDimension <= _mainAxisPadding || _trackExtent <= 0) {
      return;
    }

    final double beforePadding = _isVertical ? padding.top : padding.left;
    final double thumbExtent = _thumbExtent();
    final double thumbOffsetLocal = _getScrollToTrack(_lastMetrics!, thumbExtent);
    _thumbOffset = thumbOffsetLocal + mainAxisMargin + beforePadding;

    // Do not paint a scrollbar if the scroll view is infinitely long.
    // TODO(Piinks): Special handling for infinite scroll views, https://github.com/flutter/flutter/issues/41434
    if (_lastMetrics!.maxScrollExtent.isInfinite)
      return;

    return _paintScrollbar(canvas, size, thumbExtent, _lastAxisDirection!);
  }

  /// Same as hitTest, but includes some padding when the [PointerEvent] is
  /// caused by [PointerDeviceKind.touch] to make sure that the region
  /// isn't too small to be interacted with by the user.
  ///
  /// The hit test area for hovering with [PointerDeviceKind.mouse] over the
  /// scrollbar also uses this extra padding. This is to make it easier to
  /// interact with the scrollbar by presenting it to the mouse for interaction
  /// based on proximity. When `forHover` is true, the larger hit test area will
  /// be used.
  bool hitTestInteractive(Offset position, PointerDeviceKind kind, { bool forHover = false }) {
    if (_thumbRect == null) {
      // We have never painted the scrollbar, so we do not know where it will be.
      return false;
    }

    final Rect interactiveRect = _trackRect ?? _thumbRect!;
    final Rect paddedRect = interactiveRect.expandToInclude(
      Rect.fromCircle(center: _thumbRect!.center, radius: _kMinInteractiveSize / 2),
    );

    // The scrollbar is not able to be hit when transparent - except when
    // hovering with a mouse. This should bring the scrollbar into view so the
    // mouse can interact with it.
    if (fadeoutOpacityAnimation.value == 0.0) {
      if (forHover && kind == PointerDeviceKind.mouse)
        return paddedRect.contains(position);
      return false;
    }

    switch (kind) {
      case PointerDeviceKind.touch:
        return paddedRect.contains(position);
      case PointerDeviceKind.mouse:
      case PointerDeviceKind.stylus:
      case PointerDeviceKind.invertedStylus:
      case PointerDeviceKind.unknown:
        return interactiveRect.contains(position);
    }
  }

  /// Same as hitTestInteractive, but excludes the track portion of the scrollbar.
  /// Used to evaluate interactions with only the scrollbar thumb.
  bool hitTestOnlyThumbInteractive(Offset position, PointerDeviceKind kind) {
    if (_thumbRect == null) {
      return false;
    }
    // The thumb is not able to be hit when transparent.
    if (fadeoutOpacityAnimation.value == 0.0) {
      return false;
    }

    switch (kind) {
      case PointerDeviceKind.touch:
        final Rect touchThumbRect = _thumbRect!.expandToInclude(
          Rect.fromCircle(center: _thumbRect!.center, radius: _kMinInteractiveSize / 2),
        );
        return touchThumbRect.contains(position);
      case PointerDeviceKind.mouse:
      case PointerDeviceKind.stylus:
      case PointerDeviceKind.invertedStylus:
      case PointerDeviceKind.unknown:
        return _thumbRect!.contains(position);
    }
  }

  // Scrollbars are interactive.
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
        || trackColor != old.trackColor
        || trackBorderColor != old.trackBorderColor
        || textDirection != old.textDirection
        || thickness != old.thickness
        || fadeoutOpacityAnimation != old.fadeoutOpacityAnimation
        || mainAxisMargin != old.mainAxisMargin
        || crossAxisMargin != old.crossAxisMargin
        || radius != old.radius
        || minLength != old.minLength
        || padding != old.padding
        || minOverscrollLength != old.minOverscrollLength
        || scrollbarOrientation != old.scrollbarOrientation;
  }

  @override
  bool shouldRebuildSemantics(CustomPainter oldDelegate) => false;

  @override
  SemanticsBuilderCallback? get semanticsBuilder => null;
}

/// An extendable base class for building scrollbars that fade in and out.
///
/// To add a scrollbar to a [ScrollView], like a [ListView] or a
/// [CustomScrollView], wrap the scroll view widget in a [RawScrollbar] widget.
///
/// {@template flutter.widgets.Scrollbar}
/// A scrollbar thumb indicates which portion of a [ScrollView] is actually
/// visible.
///
/// By default, the thumb will fade in and out as the child scroll view
/// scrolls. When [isAlwaysShown] is true, the scrollbar thumb will remain
/// visible without the fade animation. This requires that the [ScrollController]
/// associated with the Scrollable widget is provided to [controller], or that
/// the [PrimaryScrollController] is being used by that Scrollable widget.
///
/// If the scrollbar is wrapped around multiple [ScrollView]s, it only responds to
/// the nearest ScrollView and shows the corresponding scrollbar thumb by default.
/// The [notificationPredicate] allows the ability to customize which
/// [ScrollNotification]s the Scrollbar should listen to.
///
/// If the child [ScrollView] is infinitely long, the [RawScrollbar] will not be
/// painted. In this case, the scrollbar cannot accurately represent the
/// relative location of the visible area, or calculate the accurate delta to
/// apply when  dragging on the thumb or tapping on the track.
///
/// ### Interaction
///
/// Scrollbars are interactive and can use the [PrimaryScrollController] if
/// a [controller] is not set. Interactive Scrollbar thumbs can be dragged along
/// the main axis of the [ScrollView] to change the [ScrollPosition]. Tapping
/// along the track exclusive of the thumb will trigger a
/// [ScrollIncrementType.page] based on the relative position to the thumb.
///
/// When using the [PrimaryScrollController], it must not be attached to more
/// than one [ScrollPosition]. [ScrollView]s that have not been provided a
/// [ScrollController] and have a [ScrollView.scrollDirection] of
/// [Axis.vertical] will automatically attach their ScrollPosition to the
/// PrimaryScrollController. Provide a unique ScrollController to each
/// [Scrollable] in this case to prevent having multiple ScrollPositions
/// attached to the PrimaryScrollController.
///
/// {@tool dartpad --template=stateful_widget_scaffold_center}
/// This sample shows an app with two scrollables in the same route. Since by
/// default, there is one [PrimaryScrollController] per route, and they both have a
/// scroll direction of [Axis.vertical], they would both try to attach to that
/// controller. The [Scrollbar] cannot support multiple positions attached to
/// the same controller, so one [ListView], and its [Scrollbar] have been
/// provided a unique [ScrollController].
///
/// Alternatively, a new PrimaryScrollController could be created above one of
/// the [ListView]s.
///
/// ** See code in examples/api/lib/widgets/scrollbar/raw_scrollbar.0.dart **
/// {@end-tool}
///
/// ### Automatic Scrollbars on Desktop Platforms
///
/// Scrollbars are added to most [Scrollable] widgets by default on
/// [TargetPlatformVariant.desktop] platforms. This is done through
/// [ScrollBehavior.buildScrollbar] as part of an app's
/// [ScrollConfiguration]. Scrollables that do not use the
/// [PrimaryScrollController] or have a [ScrollController] provided to them
/// will receive a unique ScrollController for use with the Scrollbar. In this
/// case, only one Scrollable can be using the PrimaryScrollController, unless
/// [interactive] is false. To prevent [Axis.vertical] Scrollables from using
/// the PrimaryScrollController, set [ScrollView.primary] to false. Scrollable
/// widgets that do not have automatically applied Scrollbars include
///
///   * [EditableText]
///   * [ListWheelScrollView]
///   * [PageView]
///   * [NestedScrollView]
///   * [DropdownButton]
/// {@endtemplate}
///
/// {@tool dartpad --template=stateless_widget_scaffold}
/// This sample shows a [RawScrollbar] that executes a fade animation as
/// scrolling occurs. The RawScrollbar will fade into view as the user scrolls,
/// and fade out when scrolling stops. The [GridView] uses the
/// [PrimaryScrollController] since it has an [Axis.vertical] scroll direction
/// and has not been provided a [ScrollController].
///
/// ** See code in examples/api/lib/widgets/scrollbar/raw_scrollbar.1.dart **
/// {@end-tool}
///
/// {@tool dartpad --template=stateful_widget_scaffold}
/// When `isAlwaysShown` is true, the scrollbar thumb will remain visible without
/// the fade animation. This requires that a [ScrollController] is provided to
/// `controller` for both the [RawScrollbar] and the [GridView].
/// Alternatively, the [PrimaryScrollController] can be used automatically so long
/// as it is attached to the singular [ScrollPosition] associated with the GridView.
///
/// ** See code in examples/api/lib/widgets/scrollbar/raw_scrollbar.2.dart **
/// {@end-tool}
///
/// See also:
///
///  * [ListView], which displays a linear, scrollable list of children.
///  * [GridView], which displays a 2 dimensional, scrollable array of children.
class RawScrollbar extends StatefulWidget {
  /// Creates a basic raw scrollbar that wraps the given [child].
  ///
  /// The [child], or a descendant of the [child], should be a source of
  /// [ScrollNotification] notifications, typically a [Scrollable] widget.
  ///
  /// The [child], [fadeDuration], [pressDuration], and [timeToFade] arguments
  /// must not be null.
  const RawScrollbar({
    Key? key,
    required this.child,
    this.controller,
    this.isAlwaysShown,
    this.shape,
    this.radius,
    this.thickness,
    this.thumbColor,
    this.minThumbLength = _kMinThumbExtent,
    this.minOverscrollLength,
    this.fadeDuration = _kScrollbarFadeDuration,
    this.timeToFade = _kScrollbarTimeToFade,
    this.pressDuration = Duration.zero,
    this.notificationPredicate = defaultScrollNotificationPredicate,
    this.interactive,
    this.scrollbarOrientation,
    this.mainAxisMargin = 0.0,
    this.crossAxisMargin = 0.0
  }) : assert(child != null),
       assert(minThumbLength != null),
       assert(minThumbLength >= 0),
       assert(minOverscrollLength == null || minOverscrollLength <= minThumbLength),
       assert(minOverscrollLength == null || minOverscrollLength >= 0),
       assert(fadeDuration != null),
       assert(radius == null || shape == null),
       assert(timeToFade != null),
       assert(pressDuration != null),
       assert(mainAxisMargin != null),
       assert(crossAxisMargin != null),
       super(key: key);

  /// {@template flutter.widgets.Scrollbar.child}
  /// The widget below this widget in the tree.
  ///
  /// The scrollbar will be stacked on top of this child. This child (and its
  /// subtree) should include a source of [ScrollNotification] notifications.
  /// Typically a [Scrollbar] is created on desktop platforms by a
  /// [ScrollBehavior.buildScrollbar] method, in which case the child is usually
  /// the one provided as an argument to that method.
  ///
  /// Typically a [ListView] or [CustomScrollView].
  /// {@endtemplate}
  final Widget child;

  /// {@template flutter.widgets.Scrollbar.controller}
  /// The [ScrollController] used to implement Scrollbar dragging.
  ///
  /// If nothing is passed to controller, the default behavior is to automatically
  /// enable scrollbar dragging on the nearest ScrollController using
  /// [PrimaryScrollController.of].
  ///
  /// If a ScrollController is passed, then dragging on the scrollbar thumb will
  /// update the [ScrollPosition] attached to the controller. A stateful ancestor
  /// of this widget needs to manage the ScrollController and either pass it to
  /// a scrollable descendant or use a PrimaryScrollController to share it.
  ///
  /// {@tool snippet}
  /// Here is an example of using the `controller` parameter to enable
  /// scrollbar dragging for multiple independent ListViews:
  ///
  /// ```dart
  /// final ScrollController _controllerOne = ScrollController();
  /// final ScrollController _controllerTwo = ScrollController();
  ///
  /// Widget build(BuildContext context) {
  ///   return Column(
  ///     children: <Widget>[
  ///       SizedBox(
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
  ///      SizedBox(
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
  /// {@endtemplate}
  final ScrollController? controller;

  /// {@template flutter.widgets.Scrollbar.isAlwaysShown}
  /// Indicates that the scrollbar should be visible, even when a scroll is not
  /// underway.
  ///
  /// When false, the scrollbar will be shown during scrolling
  /// and will fade out otherwise.
  ///
  /// When true, the scrollbar will always be visible and never fade out. This
  /// requires that the Scrollbar can access the [ScrollController] of the
  /// associated Scrollable widget. This can either be the provided [controller],
  /// or the [PrimaryScrollController] of the current context.
  ///
  ///   * When providing a controller, the same ScrollController must also be
  ///     provided to the associated Scrollable widget.
  ///   * The [PrimaryScrollController] is used by default for a [ScrollView]
  ///     that has not been provided a [ScrollController] and that has an
  ///     [Axis.vertical] [ScrollDirection]. This automatic behavior does not
  ///     apply to those with a ScrollDirection of Axis.horizontal. To explicitly
  ///     use the PrimaryScrollController, set [ScrollView.primary] to true.
  ///
  /// Defaults to false when null.
  ///
  /// {@tool snippet}
  ///
  /// ```dart
  /// final ScrollController _controllerOne = ScrollController();
  /// final ScrollController _controllerTwo = ScrollController();
  ///
  /// Widget build(BuildContext context) {
  /// return Column(
  ///   children: <Widget>[
  ///     SizedBox(
  ///        height: 200,
  ///        child: Scrollbar(
  ///          isAlwaysShown: true,
  ///          controller: _controllerOne,
  ///          child: ListView.builder(
  ///            controller: _controllerOne,
  ///            itemCount: 120,
  ///            itemBuilder: (BuildContext context, int index) {
  ///              return  Text('item $index');
  ///            },
  ///          ),
  ///        ),
  ///      ),
  ///      SizedBox(
  ///        height: 200,
  ///        child: CupertinoScrollbar(
  ///          isAlwaysShown: true,
  ///          controller: _controllerTwo,
  ///          child: SingleChildScrollView(
  ///            controller: _controllerTwo,
  ///            child: const SizedBox(
  ///              height: 2000,
  ///              width: 500,
  ///              child: Placeholder(),
  ///            ),
  ///          ),
  ///        ),
  ///      ),
  ///    ],
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///   * [RawScrollbarState.showScrollbar], an overridable getter which uses
  ///     this value to override the default behavior.
  ///   * [ScrollView.primary], which indicates whether the ScrollView is the primary
  ///     scroll view associated with the parent [PrimaryScrollController].
  ///   * [PrimaryScrollController], which associates a [ScrollController] with
  ///     a subtree.
  /// {@endtemplate}
  final bool? isAlwaysShown;

  /// The [OutlinedBorder] of the scrollbar's thumb.
  ///
  /// Only one of [radius] and [shape] may be specified. For a rounded rectangle,
  /// it's simplest to just specify [radius]. By default, the scrollbar thumb's
  /// shape is a simple rectangle.
  ///
  /// If [shape] is specified, the thumb will take the shape of the passed
  /// [OutlinedBorder] and fill itself with [thumbColor] (or grey if it
  /// is unspecified).
  ///
  /// Here is an example of using a [StadiumBorder] for drawing the [shape] of the
  /// thumb in a [RawScrollbar]:
  ///
  /// {@tool dartpad --template=stateless_widget_material}
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return Scaffold(
  ///     body: RawScrollbar(
  ///       child: ListView(
  ///         children: List<Text>.generate(100, (int index) => Text((index * index).toString())),
  ///         physics: const BouncingScrollPhysics(),
  ///       ),
  ///       shape: const StadiumBorder(side: BorderSide(color: Colors.brown, width: 3.0)),
  ///       thickness: 15.0,
  ///       thumbColor: Colors.blue,
  ///       isAlwaysShown: true,
  ///     ),
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  final OutlinedBorder? shape;

  /// The [Radius] of the scrollbar thumb's rounded rectangle corners.
  ///
  /// Scrollbar will be rectangular if [radius] is null, which is the default
  /// behavior.
  final Radius? radius;

  /// The thickness of the scrollbar in the cross axis of the scrollable.
  ///
  /// If null, will default to 6.0 pixels.
  final double? thickness;

  /// The color of the scrollbar thumb.
  ///
  /// If null, defaults to Color(0x66BCBCBC).
  final Color? thumbColor;

  /// The preferred smallest size the scrollbar thumb can shrink to when the total
  /// scrollable extent is large, the current visible viewport is small, and the
  /// viewport is not overscrolled.
  ///
  /// The size of the scrollbar's thumb may shrink to a smaller size than [minThumbLength]
  /// to fit in the available paint area (e.g., when [minThumbLength] is greater
  /// than [ScrollMetrics.viewportDimension] and [mainAxisMargin] combined).
  ///
  /// Mustn't be null and the value has to be greater or equal to
  /// [minOverscrollLength], which in turn is >= 0. Defaults to 18.0.
  final double minThumbLength;

  /// The preferred smallest size the scrollbar thumb can shrink to when viewport is
  /// overscrolled.
  ///
  /// When overscrolling, the size of the scrollbar's thumb may shrink to a smaller size
  /// than [minOverscrollLength] to fit in the available paint area (e.g., when
  /// [minOverscrollLength] is greater than [ScrollMetrics.viewportDimension] and
  /// [mainAxisMargin] combined).
  ///
  /// Overscrolling can be made possible by setting the `physics` property
  /// of the `child` Widget to a `BouncingScrollPhysics`, which is a special
  /// `ScrollPhysics` that allows overscrolling.
  ///
  /// The value is less than or equal to [minThumbLength] and greater than or equal to 0.
  /// When null, it will default to the value of [minThumbLength].
  final double? minOverscrollLength;

  /// The [Duration] of the fade animation.
  ///
  /// Cannot be null, defaults to a [Duration] of 300 milliseconds.
  final Duration fadeDuration;

  /// The [Duration] of time until the fade animation begins.
  ///
  /// Cannot be null, defaults to a [Duration] of 600 milliseconds.
  final Duration timeToFade;

  /// The [Duration] of time that a LongPress will trigger the drag gesture of
  /// the scrollbar thumb.
  ///
  /// Cannot be null, defaults to [Duration.zero].
  final Duration pressDuration;

  /// {@template flutter.widgets.Scrollbar.notificationPredicate}
  /// A check that specifies whether a [ScrollNotification] should be
  /// handled by this widget.
  ///
  /// By default, checks whether `notification.depth == 0`. That means if the
  /// scrollbar is wrapped around multiple [ScrollView]s, it only responds to the
  /// nearest scrollView and shows the corresponding scrollbar thumb.
  /// {@endtemplate}
  final ScrollNotificationPredicate notificationPredicate;

  /// {@template flutter.widgets.Scrollbar.interactive}
  /// Whether the Scrollbar should be interactive and respond to dragging on the
  /// thumb, or tapping in the track area.
  ///
  /// Does not apply to the [CupertinoScrollbar], which is always interactive to
  /// match native behavior. On Android, the scrollbar is not interactive by
  /// default.
  ///
  /// When false, the scrollbar will not respond to gesture or hover events.
  ///
  /// Defaults to true when null, unless on Android, which will default to false
  /// when null.
  ///
  /// See also:
  ///
  ///   * [RawScrollbarState.enableGestures], an overridable getter which uses
  ///     this value to override the default behavior.
  /// {@endtemplate}
  final bool? interactive;

  /// {@macro flutter.widgets.Scrollbar.scrollbarOrientation}
  final ScrollbarOrientation? scrollbarOrientation;

  /// Distance from the scrollbar's start and end to the edge of the viewport
  /// in logical pixels. It affects the amount of available paint area.
  ///
  /// Mustn't be null and defaults to 0.
  final double mainAxisMargin;

  /// Distance from the scrollbar thumb side to the nearest cross axis edge
  /// in logical pixels.
  ///
  /// Must not be null and defaults to 0.
  final double crossAxisMargin;

  @override
  RawScrollbarState<RawScrollbar> createState() => RawScrollbarState<RawScrollbar>();
}

/// The state for a [RawScrollbar] widget, also shared by the [Scrollbar] and
/// [CupertinoScrollbar] widgets.
///
/// Controls the animation that fades a scrollbar's thumb in and out of view.
///
/// Provides defaults gestures for dragging the scrollbar thumb and tapping on the
/// scrollbar track.
class RawScrollbarState<T extends RawScrollbar> extends State<T> with TickerProviderStateMixin<T> {
  Offset? _dragScrollbarAxisOffset;
  ScrollController? _currentController;
  Timer? _fadeoutTimer;
  late AnimationController _fadeoutAnimationController;
  late Animation<double> _fadeoutOpacityAnimation;
  final GlobalKey  _scrollbarPainterKey = GlobalKey();
  bool _hoverIsActive = false;


  /// Used to paint the scrollbar.
  ///
  /// Can be customized by subclasses to change scrollbar behavior by overriding
  /// [updateScrollbarPainter].
  @protected
  late final ScrollbarPainter scrollbarPainter;

  /// Overridable getter to indicate that the scrollbar should be visible, even
  /// when a scroll is not underway.
  ///
  /// Subclasses can override this getter to make its value depend on an inherited
  /// theme.
  ///
  /// Defaults to false when [RawScrollbar.isAlwaysShown] is null.
  ///
  /// See also:
  ///
  ///   * [RawScrollbar.isAlwaysShown], which overrides the default behavior.
  @protected
  bool get showScrollbar => widget.isAlwaysShown ?? false;

  /// Overridable getter to indicate is gestures should be enabled on the
  /// scrollbar.
  ///
  /// Subclasses can override this getter to make its value depend on an inherited
  /// theme.
  ///
  /// Defaults to true when [RawScrollbar.interactive] is null.
  ///
  /// See also:
  ///
  ///   * [RawScrollbar.interactive], which overrides the default behavior.
  @protected
  bool get enableGestures => widget.interactive ?? true;

  @override
  void initState() {
    super.initState();
    _fadeoutAnimationController = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    )..addStatusListener(_validateInteractions);
    _fadeoutOpacityAnimation = CurvedAnimation(
      parent: _fadeoutAnimationController,
      curve: Curves.fastOutSlowIn,
    );
    scrollbarPainter = ScrollbarPainter(
      color: widget.thumbColor ?? const Color(0x66BCBCBC),
      minLength: widget.minThumbLength,
      minOverscrollLength: widget.minOverscrollLength ?? widget.minThumbLength,
      thickness: widget.thickness ?? _kScrollbarThickness,
      fadeoutOpacityAnimation: _fadeoutOpacityAnimation,
      scrollbarOrientation: widget.scrollbarOrientation,
      mainAxisMargin: widget.mainAxisMargin,
      shape: widget.shape,
      crossAxisMargin: widget.crossAxisMargin
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    assert(_debugScheduleCheckHasValidScrollPosition());
  }

  bool _debugScheduleCheckHasValidScrollPosition() {
    if (!showScrollbar)
      return true;
    WidgetsBinding.instance!.addPostFrameCallback((Duration duration) {
      assert(_debugCheckHasValidScrollPosition());
    });
    return true;
  }

  void _validateInteractions(AnimationStatus status) {
    final ScrollController? scrollController = widget.controller ?? PrimaryScrollController.of(context);
    if (status == AnimationStatus.dismissed) {
      assert(_fadeoutOpacityAnimation.value == 0.0);
      // We do not check for a valid scroll position if the scrollbar is not
      // visible, because it cannot be interacted with.
    } else if (scrollController != null && enableGestures) {
      // Interactive scrollbars need to be properly configured. If it is visible
      // for interaction, ensure we are set up properly.
      assert(_debugCheckHasValidScrollPosition());
    }
  }

  bool _debugCheckHasValidScrollPosition() {
    final ScrollController? scrollController = widget.controller ?? PrimaryScrollController.of(context);
    final bool tryPrimary = widget.controller == null;
    final String controllerForError = tryPrimary
      ? 'PrimaryScrollController'
      : 'provided ScrollController';

    String when = '';
    if (showScrollbar) {
      when = 'Scrollbar.isAlwaysShown is true';
    } else if (enableGestures) {
      when = 'the scrollbar is interactive';
    } else {
      when = 'using the Scrollbar';
    }

    assert(
      scrollController != null,
      'A ScrollController is required when $when. '
      '${tryPrimary ? 'The Scrollbar was not provided a ScrollController, '
      'and attempted to use the PrimaryScrollController, but none was found.' :''}',
    );
    assert (() {
      if (!scrollController!.hasClients) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            "The Scrollbar's ScrollController has no ScrollPosition attached.",
          ),
          ErrorDescription(
            'A Scrollbar cannot be painted without a ScrollPosition. ',
          ),
          ErrorHint(
            'The Scrollbar attempted to use the $controllerForError. This '
            'ScrollController should be associated with the ScrollView that '
            'the Scrollbar is being applied to. '
            '${tryPrimary
              ? 'A ScrollView with an Axis.vertical '
                'ScrollDirection will automatically use the '
                'PrimaryScrollController if the user has not provided a '
                'ScrollController, but a ScrollDirection of Axis.horizontal will '
                'not. To use the PrimaryScrollController explicitly, set ScrollView.primary '
                'to true for the Scrollable widget.'
              : 'When providing your own ScrollController, ensure both the '
                'Scrollbar and the Scrollable widget use the same one.'
            }',
          ),
        ]);
      }
      return true;
    }());
    assert (() {
      try {
        scrollController!.position;
      } catch (_) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'The $controllerForError is currently attached to more than one '
            'ScrollPosition.',
          ),
          ErrorDescription(
            'The Scrollbar requires a single ScrollPosition in order to be painted.',
          ),
          ErrorHint(
            'When $when, the associated Scrollable '
            'widgets must have unique ScrollControllers. '
            '${tryPrimary
              ? 'The PrimaryScrollController is used by default for '
                'ScrollViews with an Axis.vertical ScrollDirection, '
                'unless the ScrollView has been provided its own '
                'ScrollController. More than one Scrollable may have tried '
                'to use the PrimaryScrollController of the current context.'
              : 'The provided ScrollController must be unique to a '
                'Scrollable widget.'
            }',
          ),
        ]);
      }
      return true;
    }());
    return true;
  }

  /// This method is responsible for configuring the [scrollbarPainter]
  /// according to the [widget]'s properties and any inherited widgets the
  /// painter depends on, like [Directionality] and [MediaQuery].
  ///
  /// Subclasses can override to configure the [scrollbarPainter].
  @protected
  void  updateScrollbarPainter() {
    scrollbarPainter
      ..color =  widget.thumbColor ?? const Color(0x66BCBCBC)
      ..textDirection = Directionality.of(context)
      ..thickness = widget.thickness ?? _kScrollbarThickness
      ..radius = widget.radius
      ..padding = MediaQuery.of(context).padding
      ..scrollbarOrientation = widget.scrollbarOrientation
      ..mainAxisMargin = widget.mainAxisMargin
      ..shape = widget.shape
      ..crossAxisMargin = widget.crossAxisMargin
      ..minLength = widget.minThumbLength
      ..minOverscrollLength = widget.minOverscrollLength ?? widget.minThumbLength;
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAlwaysShown != oldWidget.isAlwaysShown) {
      if (widget.isAlwaysShown == true) {
        assert(_debugScheduleCheckHasValidScrollPosition());
        _fadeoutTimer?.cancel();
        _fadeoutAnimationController.animateTo(1.0);
      } else {
        _fadeoutAnimationController.reverse();
      }
    }
  }

  void _updateScrollPosition(Offset updatedOffset) {
    assert(_currentController != null);
    assert(_dragScrollbarAxisOffset != null);
    final ScrollPosition position = _currentController!.position;
    late double primaryDelta;
    switch (position.axisDirection) {
      case AxisDirection.up:
        primaryDelta = _dragScrollbarAxisOffset!.dy - updatedOffset.dy;
        break;
      case AxisDirection.right:
        primaryDelta = updatedOffset.dx -_dragScrollbarAxisOffset!.dx;
        break;
      case AxisDirection.down:
        primaryDelta = updatedOffset.dy -_dragScrollbarAxisOffset!.dy;
        break;
      case AxisDirection.left:
        primaryDelta = _dragScrollbarAxisOffset!.dx - updatedOffset.dx;
        break;
    }

    // Convert primaryDelta, the amount that the scrollbar moved since the last
    // time _updateScrollPosition was called, into the coordinate space of the scroll
    // position, and jump to that position.
    final double scrollOffsetLocal = scrollbarPainter.getTrackToScroll(primaryDelta);
    final double scrollOffsetGlobal = scrollOffsetLocal + position.pixels;
    if (scrollOffsetGlobal != position.pixels) {
      // Ensure we don't drag into overscroll if the physics do not allow it.
      final double physicsAdjustment = position.physics.applyBoundaryConditions(position, scrollOffsetGlobal);
      position.jumpTo(scrollOffsetGlobal - physicsAdjustment);
    }
  }

  void _maybeStartFadeoutTimer() {
    if (!showScrollbar) {
      _fadeoutTimer?.cancel();
      _fadeoutTimer = Timer(widget.timeToFade, () {
        _fadeoutAnimationController.reverse();
        _fadeoutTimer = null;
      });
    }
  }

  /// Returns the [Axis] of the child scroll view, or null if the
  /// current scroll controller does not have any attached positions.
  @protected
  Axis? getScrollbarDirection() {
    assert(_currentController != null);
    if (_currentController!.hasClients)
      return _currentController!.position.axis;
    return null;
  }

  /// Handler called when a press on the scrollbar thumb has been recognized.
  ///
  /// Cancels the [Timer] associated with the fade animation of the scrollbar.
  @protected
  @mustCallSuper
  void handleThumbPress() {
    assert(_debugCheckHasValidScrollPosition());
    if (getScrollbarDirection() == null) {
      return;
    }
    _fadeoutTimer?.cancel();
  }

  /// Handler called when a long press gesture has started.
  ///
  /// Begins the fade out animation and initializes dragging the scrollbar thumb.
  @protected
  @mustCallSuper
  void handleThumbPressStart(Offset localPosition) {
    assert(_debugCheckHasValidScrollPosition());
    _currentController = widget.controller ?? PrimaryScrollController.of(context);
    final Axis? direction = getScrollbarDirection();
    if (direction == null) {
      return;
    }
    _fadeoutTimer?.cancel();
    _fadeoutAnimationController.forward();
    _dragScrollbarAxisOffset = localPosition;
  }

  /// Handler called when a currently active long press gesture moves.
  ///
  /// Updates the position of the child scrollable.
  @protected
  @mustCallSuper
  void handleThumbPressUpdate(Offset localPosition) {
    assert(_debugCheckHasValidScrollPosition());
    final Axis? direction = getScrollbarDirection();
    if (direction == null) {
      return;
    }
    _updateScrollPosition(localPosition);
    _dragScrollbarAxisOffset = localPosition;
  }

  /// Handler called when a long press has ended.
  @protected
  @mustCallSuper
  void handleThumbPressEnd(Offset localPosition, Velocity velocity) {
    assert(_debugCheckHasValidScrollPosition());
    final Axis? direction = getScrollbarDirection();
    if (direction == null) {
      return;
    }
    _maybeStartFadeoutTimer();
    _dragScrollbarAxisOffset = null;
    _currentController = null;
  }

  void _handleTrackTapDown(TapDownDetails details) {
    // The Scrollbar should page towards the position of the tap on the track.
    assert(_debugCheckHasValidScrollPosition());
    _currentController = widget.controller ?? PrimaryScrollController.of(context);

    double scrollIncrement;
    // Is an increment calculator available?
    final ScrollIncrementCalculator? calculator = Scrollable.of(
      _currentController!.position.context.notificationContext!,
    )?.widget.incrementCalculator;
    if (calculator != null) {
      scrollIncrement = calculator(
        ScrollIncrementDetails(
          type: ScrollIncrementType.page,
          metrics: _currentController!.position,
        ),
      );
    } else {
      // Default page increment
      scrollIncrement = 0.8 * _currentController!.position.viewportDimension;
    }

    // Adjust scrollIncrement for direction
    switch (_currentController!.position.axisDirection) {
      case AxisDirection.up:
        if (details.localPosition.dy > scrollbarPainter._thumbOffset)
          scrollIncrement = -scrollIncrement;
        break;
      case AxisDirection.down:
        if (details.localPosition.dy < scrollbarPainter._thumbOffset)
          scrollIncrement = -scrollIncrement;
        break;
      case AxisDirection.right:
        if (details.localPosition.dx < scrollbarPainter._thumbOffset)
          scrollIncrement = -scrollIncrement;
        break;
      case AxisDirection.left:
        if (details.localPosition.dx > scrollbarPainter._thumbOffset)
          scrollIncrement = -scrollIncrement;
        break;
    }

    _currentController!.position.moveTo(
      _currentController!.position.pixels + scrollIncrement,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
    );
  }

  // ScrollController takes precedence over ScrollNotification
  bool _shouldUpdatePainter(Axis notificationAxis) {
    final ScrollController? scrollController = widget.controller ??
        PrimaryScrollController.of(context);
    // Only update the painter of this scrollbar if the notification
    // metrics do not conflict with the information we have from the scroll
    // controller.

    // We do not have a scroll controller dictating axis.
    if (scrollController == null) {
      return true;
    }
    // Has more than one attached positions.
    if (scrollController.positions.length > 1) {
      return false;
    }

    return
      // The scroll controller is not attached to a position.
      !scrollController.hasClients
      // The notification matches the scroll controller's axis.
      || scrollController.position.axis == notificationAxis;
  }

  bool _handleScrollMetricsNotification(ScrollMetricsNotification notification) {
    if (!widget.notificationPredicate(ScrollUpdateNotification(
          metrics: notification.metrics,
          context: notification.context,
          depth: notification.depth,
        )))
      return false;

    if (showScrollbar) {
      if (_fadeoutAnimationController.status != AnimationStatus.forward
          && _fadeoutAnimationController.status != AnimationStatus.completed)
        _fadeoutAnimationController.forward();
    }

    final ScrollMetrics metrics = notification.metrics;
    if (_shouldUpdatePainter(metrics.axis)) {
      scrollbarPainter.update(metrics, metrics.axisDirection);
    }
    return false;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!widget.notificationPredicate(notification))
      return false;

    final ScrollMetrics metrics = notification.metrics;
    if (metrics.maxScrollExtent <= metrics.minScrollExtent) {
      // Hide the bar when the Scrollable widget has no space to scroll.
      if (_fadeoutAnimationController.status != AnimationStatus.dismissed
          && _fadeoutAnimationController.status != AnimationStatus.reverse)
        _fadeoutAnimationController.reverse();

      if (_shouldUpdatePainter(metrics.axis)) {
        scrollbarPainter.update(metrics, metrics.axisDirection);
      }
      return false;
    }

    if (notification is ScrollUpdateNotification ||
      notification is OverscrollNotification) {
      // Any movements always makes the scrollbar start showing up.
      if (_fadeoutAnimationController.status != AnimationStatus.forward
          && _fadeoutAnimationController.status != AnimationStatus.completed)
        _fadeoutAnimationController.forward();

      _fadeoutTimer?.cancel();

      if (_shouldUpdatePainter(metrics.axis)) {
        scrollbarPainter.update(metrics, metrics.axisDirection);
      }
    } else if (notification is ScrollEndNotification) {
      if (_dragScrollbarAxisOffset == null)
        _maybeStartFadeoutTimer();
    }
    return false;
  }

  Map<Type, GestureRecognizerFactory> get _gestures {
    final Map<Type, GestureRecognizerFactory> gestures = <Type, GestureRecognizerFactory>{};
    final ScrollController? controller = widget.controller ?? PrimaryScrollController.of(context);
    if (controller == null || !enableGestures)
      return gestures;

    gestures[_ThumbPressGestureRecognizer] =
      GestureRecognizerFactoryWithHandlers<_ThumbPressGestureRecognizer>(
        () => _ThumbPressGestureRecognizer(
          debugOwner: this,
          customPaintKey: _scrollbarPainterKey,
          pressDuration: widget.pressDuration,
        ),
        (_ThumbPressGestureRecognizer instance) {
          instance.onLongPress = handleThumbPress;
          instance.onLongPressStart = (LongPressStartDetails details) => handleThumbPressStart(details.localPosition);
          instance.onLongPressMoveUpdate = (LongPressMoveUpdateDetails details) => handleThumbPressUpdate(details.localPosition);
          instance.onLongPressEnd = (LongPressEndDetails details) => handleThumbPressEnd(details.localPosition, details.velocity);
        },
      );

    gestures[_TrackTapGestureRecognizer] =
      GestureRecognizerFactoryWithHandlers<_TrackTapGestureRecognizer>(
        () => _TrackTapGestureRecognizer(
          debugOwner: this,
          customPaintKey: _scrollbarPainterKey,
        ),
        (_TrackTapGestureRecognizer instance) {
          instance.onTapDown = _handleTrackTapDown;
        },
      );

    return gestures;
  }
  /// Returns true if the provided [Offset] is located over the track of the
  /// [RawScrollbar].
  ///
  /// Excludes the [RawScrollbar] thumb.
  @protected
  bool isPointerOverTrack(Offset position, PointerDeviceKind kind) {
    if (_scrollbarPainterKey.currentContext == null) {
      return false;
    }
    final Offset localOffset = _getLocalOffset(_scrollbarPainterKey, position);
    return scrollbarPainter.hitTestInteractive(localOffset, kind)
      && !scrollbarPainter.hitTestOnlyThumbInteractive(localOffset, kind);
  }
  /// Returns true if the provided [Offset] is located over the thumb of the
  /// [RawScrollbar].
  @protected
  bool isPointerOverThumb(Offset position, PointerDeviceKind kind) {
    if (_scrollbarPainterKey.currentContext == null) {
      return false;
    }
    final Offset localOffset = _getLocalOffset(_scrollbarPainterKey, position);
    return scrollbarPainter.hitTestOnlyThumbInteractive(localOffset, kind);
  }
  /// Returns true if the provided [Offset] is located over the track or thumb
  /// of the [RawScrollbar].
  ///
  /// The hit test area for mouse hovering over the scrollbar is larger than
  /// regular hit testing. This is to make it easier to interact with the
  /// scrollbar and present it to the mouse for interaction based on proximity.
  /// When `forHover` is true, the larger hit test area will be used.
  @protected
  bool isPointerOverScrollbar(Offset position, PointerDeviceKind kind, { bool forHover = false }) {
    if (_scrollbarPainterKey.currentContext == null) {
      return false;
    }
    final Offset localOffset = _getLocalOffset(_scrollbarPainterKey, position);
    return scrollbarPainter.hitTestInteractive(localOffset, kind, forHover: true);
  }

  /// Cancels the fade out animation so the scrollbar will remain visible for
  /// interaction.
  ///
  /// Can be overridden by subclasses to respond to a [PointerHoverEvent].
  ///
  /// Helper methods [isPointerOverScrollbar], [isPointerOverThumb], and
  /// [isPointerOverTrack] can be used to determine the location of the pointer
  /// relative to the painter scrollbar elements.
  @protected
  @mustCallSuper
  void handleHover(PointerHoverEvent event) {
    // Check if the position of the pointer falls over the painted scrollbar
    if (isPointerOverScrollbar(event.position, event.kind, forHover: true)) {
      _hoverIsActive = true;
      // Bring the scrollbar back into view if it has faded or started to fade
      // away.
      _fadeoutAnimationController.forward();
      _fadeoutTimer?.cancel();
    } else if (_hoverIsActive) {
      // Pointer is not over painted scrollbar.
      _hoverIsActive = false;
      _maybeStartFadeoutTimer();
    }
  }

  /// Initiates the fade out animation.
  ///
  /// Can be overridden by subclasses to respond to a [PointerExitEvent].
  @protected
  @mustCallSuper
  void handleHoverExit(PointerExitEvent event) {
    _hoverIsActive = false;
    _maybeStartFadeoutTimer();
  }

  @override
  void dispose() {
    _fadeoutAnimationController.dispose();
    _fadeoutTimer?.cancel();
    scrollbarPainter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    updateScrollbarPainter();

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _handleScrollMetricsNotification,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: RepaintBoundary(
          child: RawGestureDetector(
            gestures: _gestures,
            child: MouseRegion(
              onExit: (PointerExitEvent event) {
                switch(event.kind) {
                  case PointerDeviceKind.mouse:
                    if (enableGestures)
                      handleHoverExit(event);
                    break;
                  case PointerDeviceKind.stylus:
                  case PointerDeviceKind.invertedStylus:
                  case PointerDeviceKind.unknown:
                  case PointerDeviceKind.touch:
                    break;
                }
              },
              onHover: (PointerHoverEvent event) {
                switch(event.kind) {
                  case PointerDeviceKind.mouse:
                    if (enableGestures)
                      handleHover(event);
                    break;
                  case PointerDeviceKind.stylus:
                  case PointerDeviceKind.invertedStylus:
                  case PointerDeviceKind.unknown:
                  case PointerDeviceKind.touch:
                    break;
                }
              },
              child: CustomPaint(
                key: _scrollbarPainterKey,
                foregroundPainter: scrollbarPainter,
                child: RepaintBoundary(child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// A long press gesture detector that only responds to events on the scrollbar's
// thumb and ignores everything else.
class _ThumbPressGestureRecognizer extends LongPressGestureRecognizer {
  _ThumbPressGestureRecognizer({
    double? postAcceptSlopTolerance,
    Set<PointerDeviceKind>? supportedDevices,
    required Object debugOwner,
    required GlobalKey customPaintKey,
    required Duration pressDuration,
  }) : _customPaintKey = customPaintKey,
       super(
         postAcceptSlopTolerance: postAcceptSlopTolerance,
         supportedDevices: supportedDevices,
         debugOwner: debugOwner,
         duration: pressDuration,
       );

  final GlobalKey _customPaintKey;

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    if (!_hitTestInteractive(_customPaintKey, event.position, event.kind)) {
      return false;
    }
    return super.isPointerAllowed(event);
  }

  bool _hitTestInteractive(GlobalKey customPaintKey, Offset offset, PointerDeviceKind kind) {
    if (customPaintKey.currentContext == null) {
      return false;
    }
    final CustomPaint customPaint = customPaintKey.currentContext!.widget as CustomPaint;
    final ScrollbarPainter painter = customPaint.foregroundPainter! as ScrollbarPainter;
    final Offset localOffset = _getLocalOffset(customPaintKey, offset);
    return painter.hitTestOnlyThumbInteractive(localOffset, kind);
  }
}

// A tap gesture detector that only responds to events on the scrollbar's
// track and ignores everything else, including the thumb.
class _TrackTapGestureRecognizer extends TapGestureRecognizer {
  _TrackTapGestureRecognizer({
    required Object debugOwner,
    required GlobalKey customPaintKey,
  }) : _customPaintKey = customPaintKey,
       super(debugOwner: debugOwner);

  final GlobalKey _customPaintKey;

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    if (!_hitTestInteractive(_customPaintKey, event.position, event.kind)) {
      return false;
    }
    return super.isPointerAllowed(event);
  }

  bool _hitTestInteractive(GlobalKey customPaintKey, Offset offset, PointerDeviceKind kind) {
    if (customPaintKey.currentContext == null) {
      return false;
    }
    final CustomPaint customPaint = customPaintKey.currentContext!.widget as CustomPaint;
    final ScrollbarPainter painter = customPaint.foregroundPainter! as ScrollbarPainter;
    final Offset localOffset = _getLocalOffset(customPaintKey, offset);
    // We only receive track taps that are not on the thumb.
    return painter.hitTestInteractive(localOffset, kind) && !painter.hitTestOnlyThumbInteractive(localOffset, kind);
  }
}

Offset _getLocalOffset(GlobalKey scrollbarPainterKey, Offset position) {
  final RenderBox renderBox = scrollbarPainterKey.currentContext!.findRenderObject()! as RenderBox;
  return renderBox.globalToLocal(position);
}
