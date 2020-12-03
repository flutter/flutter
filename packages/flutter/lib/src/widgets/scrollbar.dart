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
import 'media_query.dart';
import 'notification_listener.dart';
import 'primary_scroll_controller.dart';
import 'scroll_controller.dart';
import 'scroll_metrics.dart';
import 'scroll_notification.dart';
import 'scrollable.dart';
import 'ticker_provider.dart';

const double _kMinThumbExtent = 18.0;
const double _kMinInteractiveSize = 48.0;
const double _kScrollbarThickness = 6.0;
const Duration _kScrollbarFadeDuration = Duration(milliseconds: 300);
const Duration _kScrollbarTimeToFade = Duration(milliseconds: 600);

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
    Color trackColor = const Color(0x00000000),
    Color trackBorderColor = const Color(0x00000000),
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
       _trackColor = trackColor,
       _trackBorderColor = trackBorderColor,
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
  Rect? _trackRect;
  late double _thumbOffset;

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

  /// Update and redraw with new scrollbar color.
  void updateColors(Color newThumbColor, Color newTrackColor, Color newTrackBorderColor) {
    color = newThumbColor;
    trackColor = newTrackColor;
    trackBorderColor = newTrackBorderColor;
    notifyListeners();
  }

  Paint get _thumbPaint {
    return Paint()
      ..color = color.withOpacity(color.opacity * fadeoutOpacityAnimation.value);
  }

  Paint _trackPaint({ bool isBorder = false }) {
    if (isBorder)
      return Paint()
        ..color = _trackBorderColor.withOpacity(trackBorderColor.opacity * fadeoutOpacityAnimation.value)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
    return Paint()
      ..color = _trackColor.withOpacity(trackColor.opacity * fadeoutOpacityAnimation.value);
  }

  void _paintScrollbar(Canvas canvas, Size size, double thumbExtent, AxisDirection direction) {
    final double x, y;
    final Size thumbSize, trackSize;
    final Offset trackOffset;

    switch (direction) {
      case AxisDirection.down:
        thumbSize = Size(thickness, thumbExtent);
        trackSize = Size(thickness + 2 * crossAxisMargin, _trackExtent);
        x = textDirection == TextDirection.rtl
          ? crossAxisMargin + padding.left
          : size.width - thickness - crossAxisMargin - padding.right;
        y = _thumbOffset;
        trackOffset = Offset(x - crossAxisMargin, 0.0);
        break;
      case AxisDirection.up:
        thumbSize = Size(thickness, thumbExtent);
        trackSize = Size(thickness + 2 * crossAxisMargin, _trackExtent);
        x = textDirection == TextDirection.rtl
          ? crossAxisMargin + padding.left
          : size.width - thickness - crossAxisMargin - padding.right;
        y = _thumbOffset;
        trackOffset = Offset(x - crossAxisMargin, 0.0);
        break;
      case AxisDirection.left:
        thumbSize = Size(thumbExtent, thickness);
        x = _thumbOffset;
        y = size.height - thickness - crossAxisMargin - padding.bottom;
        trackSize = Size(_trackExtent, thickness + 2 * crossAxisMargin);
        trackOffset = Offset(0.0, y - crossAxisMargin);
        break;
      case AxisDirection.right:
        thumbSize = Size(thumbExtent, thickness);
        trackSize = Size(_trackExtent, thickness + 2 * crossAxisMargin);
        x = _thumbOffset;
        y = size.height - thickness - crossAxisMargin - padding.bottom;
        trackOffset = Offset(0.0, y - crossAxisMargin);
        break;
    }

    _trackRect = trackOffset & trackSize;
    canvas.drawRect(_trackRect!, _trackPaint());
    canvas.drawLine(
      trackOffset,
      Offset(trackOffset.dx, trackOffset.dy + _trackExtent),
      _trackPaint(isBorder: true),
    );

    _thumbRect = Offset(x, y) & thumbSize;
    if (radius == null)
      canvas.drawRect(_thumbRect!, _thumbPaint);
    else
      canvas.drawRRect(RRect.fromRectAndRadius(_thumbRect!, radius!), _thumbPaint);
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
    _thumbOffset = thumbOffsetLocal + mainAxisMargin + beforePadding;

    return _paintScrollbar(canvas, size, thumbExtent, _lastAxisDirection!);
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
    final Rect interactiveScrollbarRect = _trackRect == null
      ? _thumbRect!.expandToInclude(
          Rect.fromCircle(center: _thumbRect!.center, radius: _kMinInteractiveSize / 2),
        )
      : _trackRect!.expandToInclude(
          Rect.fromCircle(center: _thumbRect!.center, radius: _kMinInteractiveSize / 2),
        );
    return interactiveScrollbarRect.contains(position);
  }

  /// Same as hitTestInteractive, but excludes the track portion of the scrollbar.
  /// Used to evaluate interactions with only the scrollbar thumb.
  bool hitTestOnlyThumbInteractive(Offset position) {
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

/// An extendable base class for building scrollbars that fade in and out.
///
/// To add a scrollbar thumb to a [ScrollView], like a [ListView] or a
/// [CustomScrollView], simply wrap the scroll view widget in a [RawScrollbar]
/// widget.
///
/// {@template flutter.widgets.Scrollbar}
/// A scrollbar thumb indicates which portion of a [ScrollView] is actually
/// visible.
///
/// By default, the thumb will fade in and out as the child scroll view
/// scrolls. When [isAlwaysShown] is true, and ta [controller] is specified, the
/// scrollbar thumb will remain visible without the fade animation.
///
/// Scrollbars are interactive and will use the [PrimaryScrollController] if
/// a [controller] is not set. Scrollbar thumbs can be dragged along the main axis
/// of the [ScrollView] to change the [ScrollPosition]. Tapping along the track
/// exclusive of the thumb will trigger a [ScrollIncrementType.page] based on
/// the relative position to the thumb.
/// {@endtemplate}
///
// TODO(Piinks): Add code sample
///
/// See also:
///
///  * [RawScrollbar], the abstract base class this inherits from.
///  * [ListView], which displays a linear, scrollable list of children.
///  * [GridView], which displays a 2 dimensional, scrollable array of children.
class RawScrollbar extends StatefulWidget {
  /// Creates a basic raw scrollbar that wraps the given [child].
  ///
  /// The [child] should be a source of [ScrollNotification] notifications,
  /// typically a [Scrollable] widget.
  ///
  /// The [child], [thickness], [thumbColor], [isAlwaysShown], [fadeDuration],
  /// and [timeToFade] arguments must not be null.
  const RawScrollbar({
    Key? key,
    required this.child,
    this.controller,
    this.isAlwaysShown = false,
    this.radius,
    this.thickness = _kScrollbarThickness,
    this.thumbColor = const Color(0x66BCBCBC),
    this.fadeDuration = _kScrollbarFadeDuration,
    this.timeToFade = _kScrollbarTimeToFade,
    this.pressDuration = Duration.zero,
  }) : assert(
         !isAlwaysShown || controller != null,
         'When isAlwaysShown is true, a ScrollController must be provided.',
       ),
       assert(child != null),
       assert(thickness != null),
       assert(thumbColor != null),
       assert(fadeDuration != null),
       assert(timeToFade != null),
       assert(pressDuration != null),
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
  /// the given ScrollController. A stateful ancestor of this widget needs to
  /// manage the ScrollController and either pass it to a scrollable descendant
  /// or use a PrimaryScrollController to share it.
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

  /// Indicates that the scrollbar should be visible, even when a scroll is not
  /// underway.
  ///
  /// When false, the scrollbar will be shown during scrolling
  /// and will fade out otherwise.
  ///
  /// When true, the scrollbar will always be visible and never fade out. The
  /// [controller] property must be set in this case.
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
  ///            child: SizedBox(
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
  final bool isAlwaysShown;

  /// [Radius] of corners if the scrollbar should have rounded corners.
  ///
  /// Scrollbar will be rectangular if [radius] is null, which is the default
  /// behavior.
  final Radius? radius;

  /// The thickness of the scrollbar in the cross axis of the scrollable.
  ///
  /// Cannot be null, defaults to 6.0 pixels.
  final double thickness;

  /// The color of the scrollbar thumb.
  ///
  /// Cannot be null, defaults to Color(0x66BCBCBC).
  final Color thumbColor;

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

  @override
  RawScrollbarState<RawScrollbar> createState() => RawScrollbarState<RawScrollbar>();
}

/// The state for a [RawScrollbar] widget, also shared by the [Scrollbar] and
/// [CupertinoScrollbar] widgets.
///
/// Controls the animation that fades a scrollbar thumb in and out of view.
///
/// Provides defaults gestures for dragging the scrollbar thumb and tapping on the
/// scrollbar track.
class RawScrollbarState<T extends RawScrollbar> extends State<T> with TickerProviderStateMixin<T> {
  double? _dragScrollbarAxisPosition;
  ScrollController? _currentController;
  Timer? _fadeoutTimer;
  late AnimationController _fadeoutAnimationController;

  /// A [GlobalKey] associated with the [scrollbarPainter], must be assigned to
  /// the [CustomPaint] of the scrollbar.
  @protected
  GlobalKey get scrollbarPainterKey => _scrollbarPainterKey;
  final GlobalKey _scrollbarPainterKey = GlobalKey();


  /// Used to paint the scrollbar.
  ///
  /// Can be overridden by subclasses to further customize scrollbar behavior.
  @protected
  ScrollbarPainter? scrollbarPainter;

  /// The current value of the animation that fades the scrollbar in and out of
  /// view.
  ///
  /// The animation is triggered by scroll events, fading the scrollbar into
  /// view upon scrolling, and out of view upon stopping.
  ///
  /// If [isAlwaysShown] is true, the animation will not be triggered to fade out.
  @protected
  Animation<double> get fadeoutOpacityAnimation => _fadeoutOpacityAnimation;
  late Animation<double> _fadeoutOpacityAnimation;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If a painter has not been created by a subclass, create a raw scrollbar
    // painter.
    scrollbarPainter ??= _buildRawScrollbarPainter();
    _maybeTriggerScrollbar();
  }

  // Waits one frame and cause an empty scroll event (zero delta pixels).
  //
  // This allows the thumb to show immediately when isAlwaysShown is true.
  // A scroll event is required in order to paint the thumb.
  void _maybeTriggerScrollbar() {
    WidgetsBinding.instance!.addPostFrameCallback((Duration duration) {
      if (widget.isAlwaysShown) {
        _fadeoutTimer?.cancel();
        // Wait one frame and cause an empty scroll event.  This allows the
        // thumb to show immediately when isAlwaysShown is true. A scroll
        // event is required in order to paint the thumb.
        widget.controller!.position.didUpdateScrollPositionBy(0);
      }
    });
  }

  ScrollbarPainter _buildRawScrollbarPainter() {
    return ScrollbarPainter(
      color: widget.thumbColor,
      textDirection: Directionality.of(context),
      thickness: widget.thickness,
      radius: widget.radius,
      fadeoutOpacityAnimation: fadeoutOpacityAnimation,
      padding: MediaQuery.of(context).padding,
    );
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAlwaysShown != oldWidget.isAlwaysShown) {
      if (widget.isAlwaysShown == true) {
        _maybeTriggerScrollbar();
        _fadeoutAnimationController.animateTo(1.0);
      } else {
        _fadeoutAnimationController.reverse();
      }
    }
    scrollbarPainter!
      ..thickness = widget.thickness
      ..radius = widget.radius
      ..color = widget.thumbColor;
  }

  void _updateScrollPosition(double primaryDelta) {
    assert(_currentController != null);

    // Convert primaryDelta, the amount that the scrollbar moved since the last
    // time _dragScrollbar was called, into the coordinate space of the scroll
    // position, and jump to that position.
    final double scrollOffsetLocal = scrollbarPainter!.getTrackToScroll(primaryDelta);
    final double scrollOffsetGlobal = scrollOffsetLocal + _currentController!.position.pixels;
    _currentController!.position.jumpTo(scrollOffsetGlobal);
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

  /// Returns the [Axis] of the child scroll view, or null if one is not
  /// determined.
  @protected
  Axis? getScrollbarDirection() {
    try {
      return _currentController!.position.axis;
    } catch (_) {
      // Ignore the gesture if we cannot determine the direction.
      return null;
    }
  }

  /// Handler called when a press on the scrollbar thumb has been recognized.
  ///
  /// Cancels the [Timer] associated with the fade animation of the scrollbar.
  @protected
  @mustCallSuper
  void handleThumbPress() {
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
  void handleThumbPressStart(LongPressStartDetails details) {
    _currentController = widget.controller ?? PrimaryScrollController.of(context);
    final Axis? direction = getScrollbarDirection();
    if (direction == null) {
      return;
    }
    _fadeoutTimer?.cancel();
    _fadeoutAnimationController.forward();
    switch (direction) {
      case Axis.vertical:
        _dragScrollbarAxisPosition = details.localPosition.dy;
        break;
      case Axis.horizontal:
        _dragScrollbarAxisPosition = details.localPosition.dx;
        break;
    }
  }

  /// Handler called when a currently active long press gesture moves.
  ///
  /// Updates the position of the child scrollable.
  @protected
  @mustCallSuper
  void handleThumbPressUpdate(LongPressMoveUpdateDetails details) {
    final Axis? direction = getScrollbarDirection();
    if (direction == null) {
      return;
    }
    switch(direction) {
      case Axis.vertical:
        _updateScrollPosition(details.localPosition.dy - _dragScrollbarAxisPosition!);
        _dragScrollbarAxisPosition = details.localPosition.dy;
        break;
      case Axis.horizontal:
        _updateScrollPosition(details.localPosition.dx - _dragScrollbarAxisPosition!);
        _dragScrollbarAxisPosition = details.localPosition.dx;
        break;
    }
  }

  /// Handler called when a long press has ended.
  @protected
  @mustCallSuper
  void handleThumbPressEnd(LongPressEndDetails details) {
    final Axis? direction = getScrollbarDirection();
    if (direction == null)
      return;
    _maybeStartFadeoutTimer();
    _dragScrollbarAxisPosition = null;
    _currentController = null;
  }

  void _handleTrackTapDown(TapDownDetails details) {
    // The Scrollbar should page towards the position of the tap on the track.
    _currentController = widget.controller ?? PrimaryScrollController.of(context);

    double scrollIncrement;
    // Is an increment calculator available?
    final ScrollIncrementCalculator? calculator = Scrollable.of(
      _currentController!.position.context.notificationContext!
    )?.widget.incrementCalculator;
    if (calculator != null) {
      scrollIncrement = calculator(
        ScrollIncrementDetails(
          type: ScrollIncrementType.page,
          metrics: _currentController!.position,
        )
      );
    } else {
      // Default page increment
      scrollIncrement = 0.8 * _currentController!.position.viewportDimension;
    }

    // Adjust scrollIncrement for direction
    switch (_currentController!.position.axisDirection) {
      case AxisDirection.up:
        if (details.localPosition.dy > scrollbarPainter!._thumbOffset)
          scrollIncrement = -scrollIncrement;
        break;
      case AxisDirection.down:
        if (details.localPosition.dy < scrollbarPainter!._thumbOffset)
          scrollIncrement = -scrollIncrement;
        break;
      case AxisDirection.right:
        if (details.localPosition.dx < scrollbarPainter!._thumbOffset)
          scrollIncrement = -scrollIncrement;
        break;
      case AxisDirection.left:
        if (details.localPosition.dx > scrollbarPainter!._thumbOffset)
          scrollIncrement = -scrollIncrement;
        break;
    }

    _currentController!.position.moveTo(
      _currentController!.position.pixels + scrollIncrement,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
    );
  }

  /// Updates the scrollbar thumb and it's animations based on the received
  /// [ScrollNotification].
  @protected
  @mustCallSuper
  bool handleScrollNotification(ScrollNotification notification) {
    final ScrollMetrics metrics = notification.metrics;
    if (metrics.maxScrollExtent <= metrics.minScrollExtent)
      return false;

    if (notification is ScrollUpdateNotification ||
      notification is OverscrollNotification) {
      // Any movements always makes the scrollbar start showing up.
      if (_fadeoutAnimationController.status != AnimationStatus.forward)
        _fadeoutAnimationController.forward();

      _fadeoutTimer?.cancel();
      scrollbarPainter!.update(notification.metrics, notification.metrics.axisDirection);
    } else if (notification is ScrollEndNotification) {
      if (_dragScrollbarAxisPosition == null)
        _maybeStartFadeoutTimer();
    }
    return false;
  }

  /// Get the GestureRecognizerFactories used to detect gestures on the scrollbar
  /// thumb.
  ///
  /// The RawScrollbar provides for dragging gestures on the scrollbar thumb,
  /// and tapping gestures on the area of the scrollbar track.
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
          customPaintKey: scrollbarPainterKey,
          pressDuration: widget.pressDuration,
        ),
          (_ThumbPressGestureRecognizer instance) {
          instance
            ..onLongPress = handleThumbPress
            ..onLongPressStart = handleThumbPressStart
            ..onLongPressMoveUpdate = handleThumbPressUpdate
            ..onLongPressEnd = handleThumbPressEnd;
        },
      );

    gestures[_TrackTapGestureRecognizer] =
      GestureRecognizerFactoryWithHandlers<_TrackTapGestureRecognizer>(
          () => _TrackTapGestureRecognizer(
          debugOwner: this,
          customPaintKey: scrollbarPainterKey,
        ),
          (_TrackTapGestureRecognizer instance) {
          instance.onTapDown = _handleTrackTapDown;
        },
      );

    return gestures;
  }

  @override
  void dispose() {
    _fadeoutAnimationController.dispose();
    _fadeoutTimer?.cancel();
    scrollbarPainter?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: handleScrollNotification,
      child: RepaintBoundary(
        child: RawGestureDetector(
          gestures: gestures,
          child: CustomPaint(
            key: scrollbarPainterKey,
            foregroundPainter: scrollbarPainter,
            child: RepaintBoundary(child: widget.child),
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
    PointerDeviceKind? kind,
    required Object debugOwner,
    required GlobalKey customPaintKey,
    required Duration pressDuration,
  }) :  _customPaintKey = customPaintKey,
      super(
      postAcceptSlopTolerance: postAcceptSlopTolerance,
      kind: kind,
      debugOwner: debugOwner,
      duration: pressDuration,
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
    return painter.hitTestOnlyThumbInteractive(localOffset);
  }
}

// A tap gesture detector that only responds to events on the scrollbar's
// track and ignores everything else, including the thumb.
class _TrackTapGestureRecognizer extends TapGestureRecognizer {
  _TrackTapGestureRecognizer({
    required Object debugOwner,
    required GlobalKey customPaintKey,
  }) :  _customPaintKey = customPaintKey,
      super(debugOwner: debugOwner);

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
    // We only receive track taps that are not on the thumb.
    return painter.hitTestInteractive(localOffset) && !painter.hitTestOnlyThumbInteractive(localOffset);
  }
}
