import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// TODO(jamesblasco): Arbitrary values
const double _kWillPopThreshold = 0.8;
const Curve _kDecelerateEasing = Cubic(0.0, 0.0, 0.2, 1.0);
const Duration _kDefaultSheetDuration = Duration(milliseconds: 400);
const Duration _kBounceAnimationDuration = Duration(milliseconds: 300);

/// NEEDS DOCS
class SnapSheet extends StatefulWidget {

  const SnapSheet({
    Key? key,
    required this.child,
    this.controller,
    this.expanded = true,
    this.draggable = true,
    this.resized = false,
    this.bounceAtTop = false,
  }) : super(key: key);

  /// An object that can be used to control the vertical position of the sheet and
  /// the position to which the main inner scroll view is scrolled.
  final SheetController? controller;

  /// The child contained by the [SnapSheet].
  final Widget child;

  /// Whether the sheet should translate vertically through user interaction
  ///
  /// The default value is true.
  final bool draggable;

  /// Whether the sheet will keep its size when it moves vertically
  /// or it resizes to fit the remaining space
  ///
  /// Used in [CupertinoSheetRoute]
  ///
  /// The default value is false.
  final bool resized;

  /// Whether the widget should bounce when the user drag reaches the top
  /// limit
  ///
  /// Used in [CupertinoSheetRoute]
  ///
  /// The default value is false.
  final bool bounceAtTop;

  /// Whether the widget should expand to fill the available space in its parent
  /// or not.
  ///
  /// In most cases, this should be true. However, in the case of a parent
  /// widget that will position this one based on its desired size (such as a
  /// [Center]), this should be set to false.
  ///
  /// The default value is true.
  final bool expanded;

  @override
  _SheetState createState() => _SheetState();

  /// Called to create the animation controller that will drive the transitions to
  /// the [SheetRoute] route from the previous one, and back to the previous route from this
  /// one.
  static AnimationController createAnimationController(
    TickerProvider vsync, {
    Duration? duration,
  }) {
    return AnimationController(
      duration: duration ?? _kDefaultSheetDuration,
      debugLabel: 'Sheet',
      vsync: vsync,
    );
  }
}

class _SheetState extends State<SnapSheet> with TickerProviderStateMixin {
  late SheetController _controller;

  late AnimationController _topBounceController;

  @override
  void initState() {
    super.initState();
    _topBounceController = AnimationController(vsync: this, duration: _kBounceAnimationDuration);
    _controller = widget.controller ?? SheetController(vsync: this);
  }

  // TODO(jamesblasco): is there any way to access the Drag inside a GestureDetector and cancel it?
  bool canceledDrag = false;

  Future<void> _handleDragUpdate(double primaryDelta) async {
    if (canceledDrag) {
      return;
    }

    // If bounceAtTop is enabled check if needs bouncing
    if (widget.bounceAtTop) {
      final double progress = primaryDelta / _controller._availablePixels;
      final bool isBouncing = _topBounceController.value > 0;
      final bool willBounce = (_controller.currentExtent - progress) > _controller.maxExtent;

      if (isBouncing || willBounce) {
        _topBounceController.value -= progress * 10;
        return;
      }
    }

    _controller._addPixelDelta(-primaryDelta, onDragCancel: () {
      canceledDrag = true;
    });
  }

  Future<void> _handleDragEnd(double velocity) async {
    if (canceledDrag) {
      return;
    }
    if (_topBounceController.value != 0) {
      _topBounceController.reverse();
    }
    _controller.animateToNearestStop(velocity);
  }

  final GlobalKey _childKey = GlobalKey(debugLabel: 'Sheet child');

  // TODO(jamesblasco): User drag is relative to controller._availablePixels 
  // and it should be to _childHeight when expanded is false
  double? get _childHeight {
    final RenderBox? renderBox = _childKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.size.height;
  }

  @override
  Widget build(BuildContext context) {
    final bool accessible = MediaQuery.of(context)!.accessibleNavigation;

    final Widget child = RepaintBoundary(
      child: KeyedSubtree(
        key: _childKey,
        child: widget.child,
      ),
    );

    final CurvedAnimation bounceAnimation = CurvedAnimation(
      parent: _topBounceController,
      curve: Curves.easeOutSine,
    );

    final Widget sheet = _ScrollToTopStatusBarHandler(
      scrollController: _controller._scrollController,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          _controller._availablePixels = _controller._stops.last * constraints.biggest.height;
          return AnimatedBuilder(
            animation: _controller._animationController,
            child: child,
            builder: (BuildContext context, Widget? child) {
              // If accessibleNavigation is enabled keep the sheet at maximum
              final double extent = accessible ? 1 : _controller.suspendedValue;
              if (widget.resized) {
                final Widget page = FractionallySizedBox(
                  heightFactor: extent,
                  child: child,
                  alignment: Alignment.bottomCenter,
                );
                return widget.expanded ? SizedBox.expand(child: page) : page;
              } else
                return SizedBox.expand(
                  child: CustomSingleChildLayout(
                    child: child,
                    delegate: _SheetLayoutDelegate(
                      progress: extent,
                      expand: widget.expanded,
                    ),
                  ),
                );
            },
          );
        },
      ),
    );

    return widget.draggable
        ? AnimatedBuilder(
            animation: bounceAnimation,
            child: GestureDetector(
              onVerticalDragStart: (DragStartDetails details) {
                _controller._animationController.stop();
              },
              onVerticalDragUpdate: (DragUpdateDetails details) {
                _handleDragUpdate(details.delta.dy);
              },
              onVerticalDragEnd: (DragEndDetails details) {
                _handleDragEnd(-(details.primaryVelocity ?? 0));
                canceledDrag = false;
              },
              child: sheet,
            ),
            builder: (BuildContext context, Widget? child) {
              return CustomSingleChildLayout(
                delegate: _TopBounceLayoutDelegate(bounceAnimation.value),
                child: child,
              );
            },
          )
        : sheet;
  }

  @override
  void dispose() {
    if (_controller != widget.controller) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SnapSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
  }
}

/// STILL NEED DOCS
/// An object that can be used to control the vertical position of a [SnapSheet] and
/// the position to which the main inner scroll view is scrolled.
/// Manages state between [_SheetState],
/// [_SheetScrollController], and
/// [_SheetScrollPosition].
class SheetController extends ChangeNotifier {

  SheetController({
    required TickerProvider vsync,
    Duration duration = _kDefaultSheetDuration,
    this.animationCurve,
    this.initialExtent = 0.5,
    List<double>? stops,
    this.snap = true,
  })  : _shouldDisposeAnimationController = true,
        _stops = stops ?? <double>[initialExtent],
        assert(initialExtent != null),
        assert(stops == null || stops.isNotEmpty, 'Stops can not be empty'),
        assert(stops == null || stops.first >= 0.0),
        assert(stops == null || stops.last <= 1.0),
        assert(stops == null || stops.first <= initialExtent),
        assert(stops == null || initialExtent <= stops.last),
        _animationController =
            AnimationController(vsync: vsync, value: initialExtent, duration: duration) {
    _scrollController = _SheetScrollController(controller: this);
  }

  SheetController._({
    required AnimationController controller,
    this.animationCurve,
    List<double>? stops,
    this.snap = true,
  })  : _shouldDisposeAnimationController = false,
        _stops = stops ?? <double>[controller.value],
        initialExtent = controller.value,
        assert(stops == null || stops.isNotEmpty, 'Stops can not be empty'),
        assert(stops == null || stops.first >= 0.0),
        assert(stops == null || stops.last <= 1.0),
        assert(controller != null),
        _animationController = controller {
    _scrollController = _SheetScrollController(controller: this);
  }

  /// If a [SnapSheet] contains content that is exceeds the height
  /// of its container, this controller will allow the sheet to both be dragged to
  /// fill the container and then scroll the child content.
  ScrollController get scrollController => _scrollController;
  late _SheetScrollController _scrollController;

  /// AnimationController that controls the relative vertical offset
  /// of the sheet inside its parent
  ///
  /// To modify use [currentExtent] or [animateTo]
  final AnimationController _animationController;

  /// An animation that follows the relative vertical offset of the sheet
  /// inside its parent
  Animation<double> get animation => _animationController;

  /// Curve used to animate the vertical position of the sheet when this is
  /// not being done by user drag input
  final Curve? animationCurve;

  /// The values in the [stops] list must be in ascending order. If a value in
  /// the [stops] list is less than an earlier value in the list, then its value
  /// is assumed to equal the previous value.
  List<double> get stops => List<double>.from(_stops);
  final List<double> _stops;

  /// The initial vertical position of the sheet
  final double initialExtent;

  /// If true the sheet snaps to the positions inside the list [stops],
  /// otherwise it acts as a [DraggableScrollableSheet]
  // TODO(jamesblasco): remove?
  bool snap;

  /// Current position of the sheet
  /// It has a value between 0 and 1 and is clampled between [minExtent] and [maxExtent]
  ///
  /// 0 will mean that the top of the sheet will be located at the bottom of the
  /// parent while 1 the sheet will be located at the top.
  double get currentExtent => _animationController.value;

  /// Updates the current position of the sheet.
  /// The min value allowed is 0 and the maximum is 1 and it will be clamped
  /// to the [minExtent] and [maxExtent] values allowed
  ///
  /// This will make the sheet jumt to the new position, if you want to animate
  /// the sheet to a new position use [animateTo]
  set currentExtent(double value) {
    assert(value != null);
    _animationController.value = value.clamp(minExtent, maxExtent);
    notifyListeners();
  }

  /// The lowest relative position that the sheet can be located
  double get minExtent => _stops.first;

  /// The highest relative position that the sheet can be located
  double get maxExtent => _stops.last;

  /// Returns true if the sheet is located at the lowest position posible
  bool get isAtMin => minExtent >= currentExtent;

  /// Returns true if the sheet is located at the highest position posible
  bool get isAtMax => maxExtent <= currentExtent;

  /// Returns true if the sheet is located at one of the stops
  bool get isAtStop => _stops.contains(currentExtent);

  /// Vertical availabe pixels where the sheet can be positioned.
  /// Needs to be set by the [SnapSheet] and it is used to translate
  /// drag metrics to relative values
  double _availablePixels = 0;

  /// Current animation curve used to display the sheet.
  /// If the user is dragging this value should be [Curves.linear] while
  /// the rest of the time it will be [animationCurve]
  ParametricCurve<double> _currentAnimationCurve = Curves.linear;

  // TODO(jamesblasco): Not working yet.
  double get suspendedValue => _currentAnimationCurve.transform(currentExtent);

  /// Animate the vertical position of the sheet to a new offset
  /// The animation will use [animationCurve] and the duration predefined
  /// by the animation controller
  void animateTo(double extent) {
    if (_availablePixels == 0) {
      return;
    }
    /*  _currentAnimationCurve = BottomSheetSuspendedCurve(
      currentExtent,
      curve: animationCurve ?? _kDecelerateEasing,
    ); */

    _animationController.animateTo(extent).whenCompleteOrCancel(
      () {
        _currentAnimationCurve = Curves.linear;
      },
    );
  }

  /// Animate the vertical position of the sheet to the closest stop
  /// The animation will use [animationCurve] and the duration predefined
  /// by the animation controller
  ///
  /// You can add a listener that will be used only during this animation
  /// Used in [_SheetScrollPosition]
  void animateToNearestStop(double velocity, [VoidCallback? listener]) {
    if (_availablePixels == 0) {
      return;
    }
    // TODO(jamesblasco): : Need to fix this
    /*  _currentAnimationCurve = BottomSheetSuspendedCurve(
      currentExtent,
      curve: animationCurve ?? _kDecelerateEasing,
    ); */

    if (listener != null) {
      _animationController.addListener(listener);
    }

    final int index = _nearestStopIndexForExtent(currentExtent);
    double stop;
    if (velocity > 0 && index != _stops.length - 1) {
      stop = _stops[index + 1];
    } else if (velocity < 0 && index > 0) {
      stop = _stops[index - 1];
    } else {
      stop = _stops[index];
    }

    _animationController.animateTo(stop).whenCompleteOrCancel(
      () {
        _currentAnimationCurve = Curves.linear;
        if (listener != null) {
          _animationController.removeListener(listener);
        }
      },
    );
  }

  /// Moves the sheet vertically [delta] pixels with a linear curve
  ///
  /// `onDragCancel` could be called in extended classes if the drag needs to be
  /// cancelled when moving the sheet. Used in [WillPopSheetController]
  void _addPixelDelta(double delta, {VoidCallback? onDragCancel}) {
    if (_availablePixels == 0) {
      return;
    }
    _currentAnimationCurve = _BottomSheetSuspendedCurve(
      currentExtent,
      curve: Curves.linear,
    );
    final double newExtent = currentExtent + delta / _availablePixels * maxExtent;
    currentExtent = newExtent;
  }

  /// If _animationController has been created inside [SheetController]
  final bool _shouldDisposeAnimationController;

  @override
  void dispose() {
    _scrollController.dispose();
    if (_shouldDisposeAnimationController) {
      _animationController.dispose();
    }
    super.dispose();
  }

  /// Finds the closest stop position to a given extent
  double _nearestStopForExtent(double extent) {
    return _stops.reduce((double prev, double curr) {
      return (curr - extent).abs() < (prev - extent).abs() ? curr : prev;
    });
  }

  /// Finds the index inside [stops] of the closest stop position to a given extent
  int _nearestStopIndexForExtent(double extent) {
    return _stops.asMap().entries.toList().reduce(
      (MapEntry<int, double> prev, MapEntry<int, double> curr) {
        return (curr.value - extent).abs() < (prev.value - extent).abs() ? curr : prev;
      },
    ).key;
  }

  /// Resets the sheet to the original position and scrolls the [scollController]
  /// to the top if needed
  void reset() {
    // jumpTo can result in trying to replace semantics during build.
    // Just animate really fast.
    // Avoid doing it at all if the offset is already 0.0.
    if (_scrollController.offset != 0.0) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 1),
        curve: Curves.linear,
      );
    }
    currentExtent = initialExtent;
  }
}

/// A [SheetController] that also implements the behaviour for
/// willPop inside the sheet
///
/// If the sheet reaches the [willPopThreshold] and [shouldPreventPop] returns
/// true, the sheet will stop animating and will animate back to the top.
/// If willPop returns true, the sheet will close.
class WillPopSheetController extends SheetController {
  // TODO(jamesblasco): Do we want this to be private?
  // Then _animationController should be made public and protected in [SheetController]
  WillPopSheetController({
    required AnimationController controller,
    Curve? animationCurve,
    List<double>? stops,
    bool snap = true,
    this.onPop,
    this.willPop,
    this.hasScopedWillPopCallback,
    this.willPopThreshold = _kWillPopThreshold,
  }) : super._(controller: controller, animationCurve: animationCurve, stops: stops, snap: snap) {
    _animationController.addListener(_onAnimationUpdate);
  }

  /// The extent limit that will call willPop
  final double willPopThreshold;

  /// Return true if the sheet should prevent pop and call willPop
  final bool Function()? hasScopedWillPopCallback;

  /// If returns true, the sheet will close, otherwise the sheet will stay open
  /// Notice that if willPop is not null, the dialog will go back to the
  /// previous position until the function is solved
  final Future<bool> Function()? willPop;

  /// Callback called when the route that wraps the sheet should pop
  final VoidCallback? onPop;

  /// Once is confirmed by willPop that the sheet can pop, force it to pop.
  bool _forcePop = false;

  /// Check if  controller should prevent popping for a given extent
  bool _shouldPreventPopForExtent(double extent) {
    final bool shouldPreventClose = hasScopedWillPopCallback?.call() ?? false;
    return !_forcePop &&
        extent < willPopThreshold &&
        shouldPreventClose &&
        _animationController.velocity <= 0;
  }

  /// Stop current sheet transition and call willPop to confirm/cancel the pop
  void _preventPop() {
    _animationController.stop();
    _animationController.animateTo(1);
    willPop?.call().then((bool close) {
      if (close) {
        _forcePop = true;
        onPop?.call();
      }
    });
  }

  @override
  void _addPixelDelta(double delta, {VoidCallback? onDragCancel}) {
    if (_availablePixels == 0) {
      return;
    }
    final double newExtent = currentExtent + delta / _availablePixels * maxExtent;

    /// Check if the newExtent needs to call willPop
    if (_shouldPreventPopForExtent(newExtent)) {
      _preventPop();
      // Cancel drag if pop is prevented
      onDragCancel?.call();
      return;
    }
    super._addPixelDelta(delta, onDragCancel: onDragCancel);
  }

  bool get _dismissUnderway => _animationController.velocity < 0;

  void _onAnimationUpdate() {
    /// Prevent pop if sheet is being dismissed and [_shouldPreventPopForExtent] is true
    if (_dismissUnderway && _shouldPreventPopForExtent(currentExtent)) {
      _preventPop();
      return;
    }

    /// If sheet reaches the bottom call onPop
    if (_animationController.value == 0 && _animationController.isCompleted) {
      _forcePop = false;
      _animationController.stop();
      return onPop?.call();
    }
  }

  @override
  void dispose() {
    _animationController.removeListener(_onAnimationUpdate);
    super.dispose();
  }
}

/// A [ScrollController] suitable for use in a [SheetController] created
/// by a [SnapSheet].
///
/// If a [SnapSheet] contains content that is exceeds the height
/// of its container, this controller will allow the sheet to both be dragged to
/// fill the container and then scroll the child content.
///
/// See also:
///
///  * [_SheetScrollPosition], which manages the positioning logic for
///    this controller.
///  * [DefaultSheetController], which can be used to establish a
///    [_SheetScrollController] as the primary controller for
///    descendants.
class _SheetScrollController extends ScrollController {
  _SheetScrollController({
    double initialScrollOffset = 0.0,
    String? debugLabel,
    required this.controller,
  })   : assert(controller != null),
        super(
          debugLabel: debugLabel,
          initialScrollOffset: initialScrollOffset,
        );

  final SheetController controller;

  @override
  _SheetScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _SheetScrollPosition(
        physics: physics, context: context, oldPosition: oldPosition, controller: controller);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('controller: $controller');
  }
}

/// A scroll position that manages scroll activities for
/// [_SheetScrollController].
///
/// This class is a concrete subclass of [ScrollPosition] logic that handles a
/// single [ScrollContext], such as a [Scrollable]. An instance of this class
/// manages [ScrollActivity] instances, which changes the
/// [SheetController.currentExtent] or visible content offset in the
/// [Scrollable]'s [Viewport]
///
/// See also:
///
///  * [_SheetScrollController], which uses this as its [ScrollPosition].
class _SheetScrollPosition extends ScrollPositionWithSingleContext {
  _SheetScrollPosition({
    required ScrollPhysics physics,
    required ScrollContext context,
    double initialPixels = 0.0,
    bool keepScrollOffset = true,
    ScrollPosition? oldPosition,
    String? debugLabel,
    required this.controller,
  })   : assert(controller != null),
        super(
          physics: physics,
          context: context,
          initialPixels: initialPixels,
          keepScrollOffset: keepScrollOffset,
          oldPosition: oldPosition,
          debugLabel: debugLabel,
        );

  final SheetController controller;

  VoidCallback? _dragCancelCallback;
  bool get listShouldScroll => pixels > 0.0;

  double get _additionalMinExtent => controller.isAtMin ? 0.0 : 1.0;
  double get _additionalMaxExtent => controller.isAtMax ? 0.0 : 1.0;

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    // We need to provide some extra extent if we haven't yet reached the max or
    // min extents. Otherwise, a list with fewer children than the extent of
    // the available space will get stuck.
    return super.applyContentDimensions(
      minScrollExtent - _additionalMinExtent,
      maxScrollExtent + _additionalMaxExtent,
    );
  }

  @override
  void applyUserOffset(double delta) {
    final double sheetDelta = isReversed ? -delta : delta;
    if (!listShouldScroll &&
        (!(controller.isAtMin || controller.isAtMax) ||
            (controller.isAtMin && delta < 0) ||
            (controller.isAtMax && delta > 0))) {
      controller._addPixelDelta(
        -sheetDelta,
        onDragCancel: () => _dragCancelCallback?.call(),
      );
    } else {
      super.applyUserOffset(delta);
    }
  }

  bool get isReversed => axisDirectionIsReversed(axisDirection);

  @override
  void goBallistic(double velocity) {
    final double sheetVelocity = isReversed ? -velocity : velocity;
    if (_dragCancelCallback == null ||
        sheetVelocity == 0.0 && controller.isAtStop ||
        sheetVelocity < 0.0 && listShouldScroll ||
        sheetVelocity > 0.0 && controller.isAtMax) {
      super.goBallistic(velocity);
      return;
    }
    // Scrollable expects that we will dispose of its current _dragCancelCallback
    _dragCancelCallback?.call();
    _dragCancelCallback = null;

    if (controller.snap) {
      if (sheetVelocity <= 0.0 && controller.isAtStop) {
        super.goBallistic(velocity);
      }

      void _tick() {
        if ((sheetVelocity > 0 && controller.isAtMax) ||
            (sheetVelocity < 0 && controller.isAtMin)) {
          // Make sure we pass along enough velocity to keep scrolling - otherwise
          // we just "bounce" off the top making it look like the list doesn't
          // have more to scroll.
          velocity = controller._animationController.velocity +
              (physics.tolerance.velocity * controller._animationController.velocity.sign);
          super.goBallistic(velocity);
        } else if (controller._animationController.isCompleted) {
          super.goBallistic(0);
        }
      }

      controller.animateToNearestStop(sheetVelocity, _tick);
    } else {
      // TODO(jamesblasco): Do we want snapping?
      final Simulation simulation = ClampingScrollSimulation(
        position: controller.currentExtent,
        velocity: sheetVelocity,
        tolerance: physics.tolerance,
      );

      if (simulation == null) {
        super.goBallistic(velocity);
      } else {
        final AnimationController ballisticController = AnimationController.unbounded(
          debugLabel: objectRuntimeType(this, '_DraggableScrollableSheetPosition'),
          vsync: context.vsync,
        );
        double lastDelta = 0;
        void _tick() {
          final double delta = ballisticController.value - lastDelta;
          lastDelta = ballisticController.value;
          controller._addPixelDelta(delta);
          if ((velocity > 0 && controller.isAtMax) || (velocity < 0 && controller.isAtMin)) {
            // Make sure we pass along enough velocity to keep scrolling - otherwise
            // we just "bounce" off the top making it look like the list doesn't
            // have more to scroll.
            velocity = ballisticController.velocity +
                (physics.tolerance.velocity * ballisticController.velocity.sign);
            super.goBallistic(velocity);
            ballisticController.stop();
          } else if (ballisticController.isCompleted) {
            super.goBallistic(0);
          }
        }

        ballisticController
          ..addListener(_tick)
          ..animateWith(simulation).whenCompleteOrCancel(
            ballisticController.dispose,
          );
      }
    }
  }

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    controller._animationController.stop();
    // Save this so we can call it later if we have to [goBallistic] on our own.
    _dragCancelCallback = dragCancelCallback;
    return super.drag(details, dragCancelCallback);
  }
}

/// A layout delegate that positions its child with a vertical offset depending of
/// the progress given as param
///
/// A maximum progress of one will mean the top child is located at the top of the
/// parent while a progress of zero will mean the top of the child is located at the bottom
///
/// If expanded is true, the child will expand vertically to match maxHeight constraint of
/// the parent. If false it will fit its minimun size
class _SheetLayoutDelegate extends SingleChildLayoutDelegate {
  _SheetLayoutDelegate({
    this.progress = 0,
    this.expand = false,
  });

  final double progress;
  final bool expand;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: constraints.maxWidth,
      maxWidth: constraints.maxWidth,
      minHeight: expand ? constraints.maxHeight : 0,
      maxHeight: expand ? constraints.maxHeight : constraints.minHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(0.0, size.height - childSize.height * progress);
  }

  @override
  bool shouldRelayout(_SheetLayoutDelegate oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

/// A layout delegate that forces its child to have a bigger height depending
/// of a progress.
///
/// It is used by [SnapSheet] to allow the sheet to bounce the height ot itself
/// when the user drag reaches the top limit.
class _TopBounceLayoutDelegate extends SingleChildLayoutDelegate {
  _TopBounceLayoutDelegate(this.progress);

  final double progress;
  double? childHeight;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: constraints.maxWidth,
      maxWidth: constraints.maxWidth,
      minHeight: constraints.minHeight,
      maxHeight: constraints.maxHeight + progress * 8,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    childHeight ??= childSize.height;
    return Offset(0.0, size.height - childSize.height);
  }

  @override
  bool shouldRelayout(_TopBounceLayoutDelegate oldDelegate) {
    if (progress != oldDelegate.progress) {
      childHeight = oldDelegate.childHeight;
      return true;
    }
    return false;
  }
}

/// Widget that that will make the [scrollController] to scroll the top
/// when tapped on the status bar
///
/// Extracted from [Scaffold] and used in [SnapSheet]
class _ScrollToTopStatusBarHandler extends StatefulWidget {
  const _ScrollToTopStatusBarHandler({
    Key? key,
    required this.child,
    required this.scrollController,
  }) : super(key: key);

  final Widget child;

  final ScrollController scrollController;

  @override
  _ScrollToTopStatusBarState createState() => _ScrollToTopStatusBarState();
}

class _ScrollToTopStatusBarState extends State<_ScrollToTopStatusBarHandler> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context)?.padding.top ?? 0,
          child: Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _handleStatusBarTap(context),
                // iOS accessibility automatically adds scroll-to-top to the clock in the status bar
                excludeFromSemantics: true,
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleStatusBarTap(BuildContext context) {
    final ScrollController controller = widget.scrollController;
    if (controller != null && controller.hasClients) {
      controller.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.linear, // TODO(ianh): Use a more appropriate curve.
      );
    }
  }
}

// Copied from bottom_sheet.dart as is a private class
// https://github.com/flutter/flutter/issues/51627

// TODO(guidezpl): Look into making this public. A copy of this class is in
//  scaffold.dart, for now, https://github.com/flutter/flutter/issues/51627

/// A curve that progresses linearly until a specified [startingPoint], at which
/// point [curve] will begin. Unlike [Interval], [curve] will not start at zero,
/// but will use [startingPoint] as the Y position.
///
/// For example, if [startingPoint] is set to `0.5`, and [curve] is set to
/// [Curves.easeOut], then the bottom-left quarter of the curve will be a
/// straight line, and the top-right quarter will contain the entire contents of
/// [Curves.easeOut].
///
/// This is useful in situations where a widget must track the user's finger
/// (which requires a linear animation), and afterwards can be flung using a
/// curve specified with the [curve] argument, after the finger is released. In
/// such a case, the value of [startingPoint] would be the progress of the
/// animation at the time when the finger was released.
///
/// The [startingPoint] and [curve] arguments must not be null.
class _BottomSheetSuspendedCurve extends ParametricCurve<double> {
  /// Creates a suspended curve.
  const _BottomSheetSuspendedCurve(
    this.startingPoint, {
    this.curve = Curves.easeOutCubic,
  })  : assert(startingPoint != null),
        assert(curve != null);

  /// The progress value at which [curve] should begin.
  ///
  /// This defaults to [Curves.easeOutCubic].
  final double startingPoint;

  /// The curve to use when [startingPoint] is reached.
  final Curve curve;

  @override
  double transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    assert(startingPoint >= 0.0 && startingPoint <= 1.0);

    if (t < startingPoint) {
      return t;
    }

    if (t == 1.0) {
      return t;
    }

    final double curveProgress = (t - startingPoint) / (1 - startingPoint);
    final double transformed = curve.transform(curveProgress);
    return lerpDouble(startingPoint, 1, transformed) ?? 0;
  }

  @override
  String toString() {
    return '${describeIdentity(this)}($startingPoint, $curve)';
  }
}

/// Associates a [SheetController] with a subtree.
///
/// This mechanism can be used to provide default behavior for scroll views in a
/// subtree inside a sheet.
/// See [SheetController]
class DefaultSheetController extends InheritedWidget {
  /// Creates a widget that associates a [ScrollController] with a subtree.
  DefaultSheetController({
    Key? key,
    required this.controller,
    required Widget child,
  }) : super(
          key: key,
          child: PrimaryScrollController(
            controller: controller._scrollController,
            child: child,
          ),
        );

  /// The [SheetController] associated with the subtree.
  ///
  /// See also:
  ///
  ///  * [SnapSheet.controller], which discusses the purpose of specifying a
  ///    sheet controller.
  final SheetController controller;

  /// Returns the [SheetController] most closely associated with the given
  /// context.
  ///
  /// Returns null if there is no [SheetController] associated with the given
  /// context.
  static SheetController? of(BuildContext context) {
    final DefaultSheetController? result =
        context.dependOnInheritedWidgetOfExactType<DefaultSheetController>();
    return result?.controller;
  }

  @override
  bool updateShouldNotify(DefaultSheetController oldWidget) => controller != oldWidget.controller;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<SheetController>('controller', controller,
        ifNull: 'no sheet controller', showName: false));
  }
}
