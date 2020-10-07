import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

const Curve _decelerateEasing = Cubic(0.0, 0.0, 0.2, 1.0);
const Curve _modalBottomSheetCurve = _decelerateEasing;
const Duration _bottomSheetDuration = Duration(milliseconds: 400);
const double _minFlingVelocity = 500.0;
const double _closeProgressThreshold = 0.6;
const double _willPopThreshold = 0.8;

typedef WidgetWithChildBuilder = Widget Function(
    BuildContext context, Animation<double> animation, Widget child);

/// A custom bottom sheet.
///
/// The [ModalBottomSheet] widget itself is rarely used directly. Instead, prefer to
/// create a modal bottom sheet with [showMaterialModalBottomSheet].
///
/// See also:
///
///  * [showMaterialModalBottomSheet] which can be used to display a modal bottom
///    sheet with Material appareance.
///  * [showCupertinoModalBottomSheet] which can be used to display a modal bottom
///    sheet with Cupertino appareance.
class ModalBottomSheet extends StatefulWidget {
  /// Creates a bottom sheet.
  const ModalBottomSheet({
    Key? key,
    this.closeProgressThreshold,
    required this.animationController,
    required this.animationCurve,
    this.enableDrag = true,
    required this.containerBuilder,
    this.bounce = true,
    this.shouldClose,
    required this.scrollController,
    required this.expanded,
    required this.onClosing,
    required this.child,
  })   : assert(enableDrag != null),
        assert(onClosing != null),
        assert(child != null),
        super(key: key);

  /// The closeProgressThreshold parameter
  /// specifies when the bottom sheet will be dismissed when user drags it.
  final double? closeProgressThreshold;

  /// The animation controller that controls the bottom sheet's entrance and
  /// exit animations.
  ///
  /// The BottomSheet widget will manipulate the position of this animation, it
  /// is not just a passive observer.
  final AnimationController animationController;

  /// The curve used by the animation showing and dismissing the bottom sheet.
  ///
  /// If no curve is provided it falls back to `decelerateEasing`.
  final Curve? animationCurve;

  /// Allows the bottom sheet to  go beyond the top bound of the content,
  /// but then bounce the content back to the edge of
  /// the top bound.
  final bool bounce;

  // Force the widget to fill the maximum size of the viewport
  // or if false it will fit to the content of the widget
  final bool expanded;

  final WidgetWithChildBuilder containerBuilder;

  /// Called when the bottom sheet begins to close.
  ///
  /// A bottom sheet might be prevented from closing (e.g., by user
  /// interaction) even after this callback is called. For this reason, this
  /// callback might be call multiple times for a given bottom sheet.
  final Function() onClosing;

  // If shouldClose is null is ignored.
  // If returns true => The dialog closes
  // If returns false => The dialog cancels close
  // Notice that if shouldClose is not null, the dialog will go back to the
  // previous position until the function is solved
  final Future<bool> Function()? shouldClose;

  /// A builder for the contents of the sheet.
  ///
  final Widget child;

  /// If true, the bottom sheet can be dragged up and down and dismissed by
  /// swiping downwards.
  ///
  /// Default is true.
  final bool enableDrag;

  final ScrollController scrollController;

  @override
  _ModalBottomSheetState createState() => _ModalBottomSheetState();

  /// Creates an [AnimationController] suitable for a
  /// [ModalBottomSheet.animationController].
  ///
  /// This API available as a convenience for a Material compliant bottom sheet
  /// animation. If alternative animation durations are required, a different
  /// animation controller could be provided.
  static AnimationController createAnimationController(
    TickerProvider vsync, {
    Duration? duration,
  }) {
    return AnimationController(
      duration: duration ?? _bottomSheetDuration,
      debugLabel: 'BottomSheet',
      vsync: vsync,
    );
  }
}

class _ModalBottomSheetState extends State<ModalBottomSheet>
    with TickerProviderStateMixin {
  final GlobalKey _childKey = GlobalKey(debugLabel: 'BottomSheet child');

  ScrollController get _scrollController => widget.scrollController;

  late AnimationController _bounceDragController;

  double? get _childHeight {
    final renderBox = _childKey.currentContext?.findRenderObject() as RenderBox;
    return renderBox.size.height;
  }

  bool get _dismissUnderway =>
      widget.animationController.status == AnimationStatus.reverse;

  // Detect if user is dragging.
  // Used on NotificationListener to detect if ScrollNotifications are
  // before or after the user stop dragging
  bool isDragging = false;

  bool get hasReachedWillPopThreshold =>
      widget.animationController.value < _willPopThreshold;

  bool get hasReachedCloseThreshold =>
      widget.animationController.value <
      (widget.closeProgressThreshold ?? _closeProgressThreshold);

  void _close() {
    isDragging = false;
    widget.onClosing();
  }

  void _cancelClose() {
    widget.animationController.forward().then((value) {
      // When using WillPop, animation doesn't end at 1.
      // Check more in detail the problem
      if (!widget.animationController.isCompleted) {
        widget.animationController.value = 1;
      }
    });
    _bounceDragController.reverse();
  }

  bool _isCheckingShouldClose = false;

  FutureOr<bool> shouldClose() async {
    if (_isCheckingShouldClose) return false;
    if (widget.shouldClose == null) return false;
    _isCheckingShouldClose = true;
    final result = await widget.shouldClose!();
    _isCheckingShouldClose = false;
    return result;
  }

  late ParametricCurve<double> animationCurve;

  void _handleDragUpdate(double primaryDelta) async {
    animationCurve = Curves.linear;
    assert(widget.enableDrag, 'Dragging is disabled');

    if (_dismissUnderway) return;
    isDragging = true;

    final progress = primaryDelta / (_childHeight ?? primaryDelta);

    if (widget.shouldClose != null && hasReachedWillPopThreshold) {
      _cancelClose();
      final canClose = await shouldClose();
      if (canClose) {
        _close();
        return;
      } else {
        _cancelClose();
      }
    }

    // Bounce top
    final bounce = widget.bounce == true;
    final shouldBounce = _bounceDragController.value > 0;
    final isBouncing = (widget.animationController.value - progress) > 1;
    if (bounce && (shouldBounce || isBouncing)) {
      _bounceDragController.value -= progress * 10;
      return;
    }

    widget.animationController.value -= progress;
  }

  void _handleDragEnd(double? velocity) async {
    assert(widget.enableDrag, 'Dragging is disabled');

    animationCurve = BottomSheetSuspendedCurve(
      widget.animationController.value,
      curve: _defaultCurve,
    );

    if (_dismissUnderway || !isDragging) return;
    isDragging = false;
    _bounceDragController.reverse();

    var canClose = true;
    if (widget.shouldClose != null && hasReachedWillPopThreshold) {
      _cancelClose();
      canClose = await shouldClose();
    }
    if (canClose) {
      // If speed is bigger than _minFlingVelocity try to close it
      if (velocity != null && velocity > _minFlingVelocity) {
        _close();
      } else if (hasReachedCloseThreshold) {
        if (widget.animationController.value > 0.0) {
          widget.animationController.fling(velocity: -1.0);
        }
        _close();
      } else {
        _cancelClose();
      }
    } else {
      _cancelClose();
    }
  }

  // As we cannot access the dragGesture detector of the scroll view
  // we can not know the DragDownDetails and therefore the end velocity.
  // VelocityTracker it is used to calculate the end velocity  of the scroll
  // when user is trying to close the modal by dragging
  VelocityTracker? _velocityTracker;
  DateTime? _startTime;

  void _handleScrollUpdate(ScrollNotification notification) {
    //Check if scrollController is used
    if (!_scrollController.hasClients) return;
    //Check if there is more than 1 attached ScrollController e.g. swiping page in PageView
    // ignore: invalid_use_of_protected_member
    if (_scrollController.positions.length > 1) return;
    if (notification.context == null ||
        Scrollable.of(notification.context!) == null) return;
    final scrollWidget = Scrollable.of(notification.context!)!;
    if (_scrollController != scrollWidget.widget.controller) return;

    final scrollPosition = _scrollController.position;

    if (scrollPosition.axis == Axis.horizontal) return;

    final isScrollReversed = scrollPosition.axisDirection == AxisDirection.down;
    final offset = isScrollReversed
        ? scrollPosition.pixels
        : scrollPosition.maxScrollExtent - scrollPosition.pixels;

    if (offset <= 0) {
      // Clamping Scroll Physics end with a ScrollEndNotification with a DragEndDetail class
      // while Bouncing Scroll Physics or other physics that Overflow don't return a drag end info

      // We use the velocity from DragEndDetail in case it is available
      if (notification is ScrollEndNotification &&
          notification.dragDetails != null) {
        _handleDragEnd(notification.dragDetails?.primaryVelocity);
        _velocityTracker = null;
        _startTime = null;
        return;
      }

      DragUpdateDetails? dragDetails;
      if (notification is ScrollUpdateNotification) {
        dragDetails = notification.dragDetails;
      }
      if (notification is OverscrollNotification) {
        dragDetails = notification.dragDetails;
      }
      // Otherwise the calculate the velocity with a VelocityTracker
      if (_velocityTracker == null || _startTime == null) {
        //final pointerKind = defaultPointerDeviceKind(context);
        _velocityTracker = VelocityTracker();
        _startTime = DateTime.now();
      }
      if (dragDetails != null) {
        final duration = _startTime!.difference(DateTime.now());
        _velocityTracker!.addPosition(duration, Offset(0, offset));
        _handleDragUpdate(dragDetails.delta.dy);
      } else if (isDragging) {
        final velocity = _velocityTracker!.getVelocity().pixelsPerSecond.dy;
        _velocityTracker = null;
        _startTime = null;
        _handleDragEnd(velocity);
      }
    }
  }

  Curve get _defaultCurve => widget.animationCurve ?? _modalBottomSheetCurve;

  @override
  void initState() {
    animationCurve = _defaultCurve;
    _bounceDragController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));

    // Todo: Check if we can remove scroll Controller
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bounceAnimation = CurvedAnimation(
      parent: _bounceDragController,
      curve: Curves.easeOutSine,
    );

    var child = widget.child;
    if (widget.containerBuilder != null) {
      child = widget.containerBuilder(
        context,
        widget.animationController,
        child,
      );
    }

    final accessibleNavigation =
        MediaQuery.of(context)?.accessibleNavigation ?? false;

    child = AnimatedBuilder(
      animation: widget.animationController,
      child: RepaintBoundary(child: child),
      builder: (context, Widget? child) {
        assert(child != null);
        final animationValue = animationCurve.transform(
            accessibleNavigation ? 1.0 : widget.animationController.value);

        final draggableChild = !widget.enableDrag
            ? child
            : KeyedSubtree(
                key: _childKey,
                child: AnimatedBuilder(
                  animation: bounceAnimation,
                  builder: (context, _) => CustomSingleChildLayout(
                    delegate: _CustomBottomSheetLayout(bounceAnimation.value),
                    child: GestureDetector(
                      onVerticalDragUpdate: (details) {
                        _handleDragUpdate(details.delta.dy);
                      },
                      onVerticalDragEnd: (details) {
                        _handleDragEnd(details.primaryVelocity);
                      },
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification notification) {
                          _handleScrollUpdate(notification);
                          return false;
                        },
                        child: child!,
                      ),
                    ),
                  ),
                ),
              );
        return ClipRect(
          child: CustomSingleChildLayout(
            delegate: _ModalBottomSheetLayout(
              animationValue,
              widget.expanded,
            ),
            child: draggableChild,
          ),
        );
      },
    );

    return ScrollToTopStatusBarHandler(
      child: child,
      scrollController: _scrollController,
    );
  }
}

class _ModalBottomSheetLayout extends SingleChildLayoutDelegate {
  _ModalBottomSheetLayout(this.progress, this.expand);

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
  bool shouldRelayout(_ModalBottomSheetLayout oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

class _CustomBottomSheetLayout extends SingleChildLayoutDelegate {
  _CustomBottomSheetLayout(this.progress);

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
  bool shouldRelayout(_CustomBottomSheetLayout oldDelegate) {
    if (progress != oldDelegate.progress) {
      childHeight = oldDelegate.childHeight;
      return true;
    }
    return false;
  }
}

// Checks the device input type as per the OS installed in it
// Mobile platforms will be default to `touch` while desktop will do to `mouse`
// Used with VelocityTracker
// https://github.com/flutter/flutter/pull/64267#issuecomment-694196304
PointerDeviceKind defaultPointerDeviceKind(BuildContext context) {
  final platform =  defaultTargetPlatform;
  switch (platform) {
    case TargetPlatform.iOS:
    case TargetPlatform.android:
      return PointerDeviceKind.touch;
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
      return PointerDeviceKind.mouse;
    case TargetPlatform.fuchsia:
      return PointerDeviceKind.unknown;
  }
  return PointerDeviceKind.unknown;
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
class BottomSheetSuspendedCurve extends ParametricCurve<double> {
  /// Creates a suspended curve.
  const BottomSheetSuspendedCurve(
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

    final curveProgress = (t - startingPoint) / (1 - startingPoint);
    final transformed = curve.transform(curveProgress);
    return lerpDouble(startingPoint, 1, transformed) ?? 0;
  }

  @override
  String toString() {
    return '${describeIdentity(this)}($startingPoint, $curve)';
  }
}

/// Associates a [ScrollController] with a subtree.
///
/// This mechanism can be used to provide default behavior for scroll views in a
/// subtree inside a modal bottom sheet.
///
/// We want to remove this and use [PrimaryScrollController].
/// This issue should be solved first https://github.com/flutter/flutter/issues/64236
///
/// See [PrimaryScrollController]
class ModalScrollController extends InheritedWidget {
  /// Creates a widget that associates a [ScrollController] with a subtree.
  ModalScrollController({
    Key? key,
    required this.controller,
    required Widget child,
  })   : assert(controller != null),
        super(
          key: key,
          child: PrimaryScrollController(
            controller: controller,
            child: child,
          ),
        );

  /// The [ScrollController] associated with the subtree.
  ///
  /// See also:
  ///
  ///  * [ScrollView.controller], which discusses the purpose of specifying a
  ///    scroll controller.
  final ScrollController controller;

  /// Returns the [ScrollController] most closely associated with the given
  /// context.
  ///
  /// Returns null if there is no [ScrollController] associated with the given
  /// context.
  static ScrollController? of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<ModalScrollController>();
    return result?.controller;
  }

  @override
  bool updateShouldNotify(ModalScrollController oldWidget) =>
      controller != oldWidget.controller;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ScrollController>(
        'controller', controller,
        ifNull: 'no controller', showName: false));
  }
}


/// Widget that that will scroll to the top the ScrollController
/// when tapped on the status bar
///
/// Extracted from Scaffold and used in modal bottom sheet
class ScrollToTopStatusBarHandler extends StatefulWidget {
  final Widget child;
  final ScrollController scrollController;

  const ScrollToTopStatusBarHandler({
    Key? key,
    required this.child,
    required this.scrollController,
  }) : super(key: key);

  @override
  _ScrollToTopStatusBarState createState() => _ScrollToTopStatusBarState();
}

class _ScrollToTopStatusBarState extends State<ScrollToTopStatusBarHandler> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context)?.padding.top ?? 0,
          child: Builder(
            builder: (context) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _handleStatusBarTap(context),
              // iOS accessibility automatically adds scroll-to-top to the clock in the status bar
              excludeFromSemantics: true,
            ),
          ),
        ),
      ],
    );
  }

  void _handleStatusBarTap(BuildContext context) {
    final controller = widget.scrollController;
    if (controller != null && controller.hasClients) {
      controller.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.linear, // TODO(ianh): Use a more appropriate curve.
      );
    }
  }
}
