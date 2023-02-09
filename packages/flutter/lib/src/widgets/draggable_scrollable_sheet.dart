// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'binding.dart';
import 'framework.dart';
import 'inherited_notifier.dart';
import 'layout_builder.dart';
import 'notification_listener.dart';
import 'scroll_activity.dart';
import 'scroll_context.dart';
import 'scroll_controller.dart';
import 'scroll_notification.dart';
import 'scroll_physics.dart';
import 'scroll_position.dart';
import 'scroll_position_with_single_context.dart';
import 'scroll_simulation.dart';
import 'value_listenable_builder.dart';

/// The signature of a method that provides a [BuildContext] and
/// [ScrollController] for building a widget that may overflow the draggable
/// [Axis] of the containing [DraggableScrollableSheet].
///
/// Users should apply the [scrollController] to a [ScrollView] subclass, such
/// as a [SingleChildScrollView], [ListView] or [GridView], to have the whole
/// sheet be draggable.
typedef ScrollableWidgetBuilder = Widget Function(
  BuildContext context,
  ScrollController scrollController,
);

/// Controls a [DraggableScrollableSheet].
///
/// Draggable scrollable controllers are typically stored as member variables in
/// [State] objects and are reused in each [State.build]. Controllers can only
/// be used to control one sheet at a time. A controller can be reused with a
/// new sheet if the previous sheet has been disposed.
///
/// The controller's methods cannot be used until after the controller has been
/// passed into a [DraggableScrollableSheet] and the sheet has run initState.
///
/// A [DraggableScrollableController] is a [Listenable]. It notifies its
/// listeners whenever an attached sheet changes sizes. It does not notify its
/// listeners when a sheet is first attached or when an attached sheet's
/// parameters change without affecting the sheet's current size. It does not
/// fire when [pixels] changes without [size] changing. For example, if the
/// constraints provided to an attached sheet change.
class DraggableScrollableController extends ChangeNotifier {
  _DraggableScrollableSheetScrollController? _attachedController;
  final Set<AnimationController> _animationControllers = <AnimationController>{};

  /// Get the current size (as a fraction of the parent height) of the attached sheet.
  double get size {
    _assertAttached();
    return _attachedController!.extent.currentSize;
  }

  /// Get the current pixel height of the attached sheet.
  double get pixels {
    _assertAttached();
    return _attachedController!.extent.currentPixels;
  }

  /// Convert a sheet's size (fractional value of parent container height) to pixels.
  double sizeToPixels(double size) {
    _assertAttached();
    return _attachedController!.extent.sizeToPixels(size);
  }

  /// Returns Whether any [DraggableScrollableController] objects have attached themselves to the
  /// [DraggableScrollableSheet].
  ///
  /// If this is false, then members that interact with the [ScrollPosition],
  /// such as [sizeToPixels], [size], [animateTo], and [jumpTo], must not be
  /// called.
  bool get isAttached => _attachedController != null && _attachedController!.hasClients;

  /// Convert a sheet's pixel height to size (fractional value of parent container height).
  double pixelsToSize(double pixels) {
    _assertAttached();
    return _attachedController!.extent.pixelsToSize(pixels);
  }

  /// Animates the attached sheet from its current size to the given [size], a
  /// fractional value of the parent container's height.
  ///
  /// Any active sheet animation is canceled. If the sheet's internal scrollable
  /// is currently animating (e.g. responding to a user fling), that animation is
  /// canceled as well.
  ///
  /// An animation will be interrupted whenever the user attempts to scroll
  /// manually, whenever another activity is started, or when the sheet hits its
  /// max or min size (e.g. if you animate to 1 but the max size is .8, the
  /// animation will stop playing when it reaches .8).
  ///
  /// The duration must not be zero. To jump to a particular value without an
  /// animation, use [jumpTo].
  ///
  /// The sheet will not snap after calling [animateTo] even if [DraggableScrollableSheet.snap]
  /// is true. Snapping only occurs after user drags.
  ///
  /// When calling [animateTo] in widget tests, `await`ing the returned
  /// [Future] may cause the test to hang and timeout. Instead, use
  /// [WidgetTester.pumpAndSettle].
  Future<void> animateTo(
    double size, {
    required Duration duration,
    required Curve curve,
  }) async {
    _assertAttached();
    assert(size >= 0 && size <= 1);
    assert(duration != Duration.zero);
    final AnimationController animationController = AnimationController.unbounded(
      vsync: _attachedController!.position.context.vsync,
      value: _attachedController!.extent.currentSize,
    );
    _animationControllers.add(animationController);
    _attachedController!.position.goIdle();
    // This disables any snapping until the next user interaction with the sheet.
    _attachedController!.extent.hasDragged = false;
    _attachedController!.extent.hasChanged = true;
    _attachedController!.extent.startActivity(onCanceled: () {
      // Don't stop the controller if it's already finished and may have been disposed.
      if (animationController.isAnimating) {
        animationController.stop();
      }
    });
    animationController.addListener(() {
      _attachedController!.extent.updateSize(
        animationController.value,
        _attachedController!.position.context.notificationContext!,
      );
    });
    await animationController.animateTo(
      clampDouble(size, _attachedController!.extent.minSize, _attachedController!.extent.maxSize),
      duration: duration,
      curve: curve,
    );
  }

  /// Jumps the attached sheet from its current size to the given [size], a
  /// fractional value of the parent container's height.
  ///
  /// If [size] is outside of a the attached sheet's min or max child size,
  /// [jumpTo] will jump the sheet to the nearest valid size instead.
  ///
  /// Any active sheet animation is canceled. If the sheet's inner scrollable
  /// is currently animating (e.g. responding to a user fling), that animation is
  /// canceled as well.
  ///
  /// The sheet will not snap after calling [jumpTo] even if [DraggableScrollableSheet.snap]
  /// is true. Snapping only occurs after user drags.
  void jumpTo(double size) {
    _assertAttached();
    assert(size >= 0 && size <= 1);
    // Call start activity to interrupt any other playing activities.
    _attachedController!.extent.startActivity(onCanceled: () {});
    _attachedController!.position.goIdle();
    _attachedController!.extent.hasDragged = false;
    _attachedController!.extent.hasChanged = true;
    _attachedController!.extent.updateSize(size, _attachedController!.position.context.notificationContext!);
  }

  /// Reset the attached sheet to its initial size (see: [DraggableScrollableSheet.initialChildSize]).
  void reset() {
    _assertAttached();
    _attachedController!.reset();
  }

  void _assertAttached() {
    assert(
      isAttached,
      'DraggableScrollableController is not attached to a sheet. A DraggableScrollableController '
        'must be used in a DraggableScrollableSheet before any of its methods are called.',
    );
  }

  void _attach(_DraggableScrollableSheetScrollController scrollController) {
    assert(_attachedController == null, 'Draggable scrollable controller is already attached to a sheet.');
    _attachedController = scrollController;
    _attachedController!.extent._currentSize.addListener(notifyListeners);
    _attachedController!.onPositionDetached = _disposeAnimationControllers;
  }

  void _onExtentReplaced(_DraggableSheetExtent previousExtent) {
    // When the extent has been replaced, the old extent is already disposed and
    // the controller will point to a new extent. We have to add our listener to
    // the new extent.
    _attachedController!.extent._currentSize.addListener(notifyListeners);
    if (previousExtent.currentSize != _attachedController!.extent.currentSize) {
      // The listener won't fire for a change in size between two extent
      // objects so we have to fire it manually here.
      notifyListeners();
    }
  }

  void _detach({bool disposeExtent = false}) {
    if (disposeExtent) {
      _attachedController?.extent.dispose();
    } else {
      _attachedController?.extent._currentSize.removeListener(notifyListeners);
    }
    _attachedController = null;
  }

  void _disposeAnimationControllers() {
    for (final AnimationController animationController in _animationControllers) {
      animationController.dispose();
    }
    _animationControllers.clear();
  }
}

/// A container for a [Scrollable] that responds to drag gestures by resizing
/// the scrollable until a limit is reached, and then scrolling.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=Hgw819mL_78}
///
/// This widget can be dragged along the vertical axis between its
/// [minChildSize], which defaults to `0.25` and [maxChildSize], which defaults
/// to `1.0`. These sizes are percentages of the height of the parent container.
///
/// The widget coordinates resizing and scrolling of the widget returned by
/// builder as the user drags along the horizontal axis.
///
/// The widget will initially be displayed at its initialChildSize which
/// defaults to `0.5`, meaning half the height of its parent. Dragging will work
/// between the range of minChildSize and maxChildSize (as percentages of the
/// parent container's height) as long as the builder creates a widget which
/// uses the provided [ScrollController]. If the widget created by the
/// [ScrollableWidgetBuilder] does not use the provided [ScrollController], the
/// sheet will remain at the initialChildSize.
///
/// By default, the widget will stay at whatever size the user drags it to. To
/// make the widget snap to specific sizes whenever they lift their finger
/// during a drag, set [snap] to `true`. The sheet will snap between
/// [minChildSize] and [maxChildSize]. Use [snapSizes] to add more sizes for
/// the sheet to snap between.
///
/// The snapping effect is only applied on user drags. Programmatically
/// manipulating the sheet size via [DraggableScrollableController.animateTo] or
/// [DraggableScrollableController.jumpTo] will ignore [snap] and [snapSizes].
///
/// By default, the widget will expand its non-occupied area to fill available
/// space in the parent. If this is not desired, e.g. because the parent wants
/// to position sheet based on the space it is taking, the [expand] property
/// may be set to false.
///
/// {@tool snippet}
///
/// This is a sample widget which shows a [ListView] that has 25 [ListTile]s.
/// It starts out as taking up half the body of the [Scaffold], and can be
/// dragged up to the full height of the scaffold or down to 25% of the height
/// of the scaffold. Upon reaching full height, the list contents will be
/// scrolled up or down, until they reach the top of the list again and the user
/// drags the sheet back down.
///
/// ```dart
/// class HomePage extends StatelessWidget {
///   const HomePage({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(
///         title: const Text('DraggableScrollableSheet'),
///       ),
///       body: SizedBox.expand(
///         child: DraggableScrollableSheet(
///           builder: (BuildContext context, ScrollController scrollController) {
///             return Container(
///               color: Colors.blue[100],
///               child: ListView.builder(
///                 controller: scrollController,
///                 itemCount: 25,
///                 itemBuilder: (BuildContext context, int index) {
///                   return ListTile(title: Text('Item $index'));
///                 },
///               ),
///             );
///           },
///         ),
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
class DraggableScrollableSheet extends StatefulWidget {
  /// Creates a widget that can be dragged and scrolled in a single gesture.
  ///
  /// The [builder], [initialChildSize], [minChildSize], [maxChildSize] and
  /// [expand] parameters must not be null.
  const DraggableScrollableSheet({
    super.key,
    this.initialChildSize = 0.5,
    this.minChildSize = 0.25,
    this.maxChildSize = 1.0,
    this.expand = true,
    this.snap = false,
    this.snapSizes,
    this.snapAnimationDuration,
    this.controller,
    required this.builder,
  })  : assert(minChildSize >= 0.0),
        assert(maxChildSize <= 1.0),
        assert(minChildSize <= initialChildSize),
        assert(initialChildSize <= maxChildSize),
        assert(snapAnimationDuration == null || snapAnimationDuration > Duration.zero);

  /// The initial fractional value of the parent container's height to use when
  /// displaying the widget.
  ///
  /// Rebuilding the sheet with a new [initialChildSize] will only move
  /// the sheet to the new value if the sheet has not yet been dragged since it
  /// was first built or since the last call to [DraggableScrollableActuator.reset].
  ///
  /// The default value is `0.5`.
  final double initialChildSize;

  /// The minimum fractional value of the parent container's height to use when
  /// displaying the widget.
  ///
  /// The default value is `0.25`.
  final double minChildSize;

  /// The maximum fractional value of the parent container's height to use when
  /// displaying the widget.
  ///
  /// The default value is `1.0`.
  final double maxChildSize;

  /// Whether the widget should expand to fill the available space in its parent
  /// or not.
  ///
  /// In most cases, this should be true. However, in the case of a parent
  /// widget that will position this one based on its desired size (such as a
  /// [Center]), this should be set to false.
  ///
  /// The default value is true.
  final bool expand;

  /// Whether the widget should snap between [snapSizes] when the user lifts
  /// their finger during a drag.
  ///
  /// If the user's finger was still moving when they lifted it, the widget will
  /// snap to the next snap size (see [snapSizes]) in the direction of the drag.
  /// If their finger was still, the widget will snap to the nearest snap size.
  ///
  /// Snapping is not applied when the sheet is programmatically moved by
  /// calling [DraggableScrollableController.animateTo] or [DraggableScrollableController.jumpTo].
  ///
  /// Rebuilding the sheet with snap newly enabled will immediately trigger a
  /// snap unless the sheet has not yet been dragged away from
  /// [initialChildSize] since first being built or since the last call to
  /// [DraggableScrollableActuator.reset].
  final bool snap;

  /// A list of target sizes that the widget should snap to.
  ///
  /// Snap sizes are fractional values of the parent container's height. They
  /// must be listed in increasing order and be between [minChildSize] and
  /// [maxChildSize].
  ///
  /// The [minChildSize] and [maxChildSize] are implicitly included in snap
  /// sizes and do not need to be specified here. For example, `snapSizes = [.5]`
  /// will result in a sheet that snaps between [minChildSize], `.5`, and
  /// [maxChildSize].
  ///
  /// Any modifications to the [snapSizes] list will not take effect until the
  /// `build` function containing this widget is run again.
  ///
  /// Rebuilding with a modified or new list will trigger a snap unless the
  /// sheet has not yet been dragged away from [initialChildSize] since first
  /// being built or since the last call to [DraggableScrollableActuator.reset].
  final List<double>? snapSizes;

  /// Defines a duration for the snap animations.
  ///
  /// If it's not set, then the animation duration is the distance to the snap
  /// target divided by the velocity of the widget.
  final Duration? snapAnimationDuration;

  /// A controller that can be used to programmatically control this sheet.
  final DraggableScrollableController? controller;

  /// The builder that creates a child to display in this widget, which will
  /// use the provided [ScrollController] to enable dragging and scrolling
  /// of the contents.
  final ScrollableWidgetBuilder builder;

  @override
  State<DraggableScrollableSheet> createState() => _DraggableScrollableSheetState();
}

/// A [Notification] related to the extent, which is the size, and scroll
/// offset, which is the position of the child list, of the
/// [DraggableScrollableSheet].
///
/// [DraggableScrollableSheet] widgets notify their ancestors when the size of
/// the sheet changes. When the extent of the sheet changes via a drag,
/// this notification bubbles up through the tree, which means a given
/// [NotificationListener] will receive notifications for all descendant
/// [DraggableScrollableSheet] widgets. To focus on notifications from the
/// nearest [DraggableScrollableSheet] descendant, check that the [depth]
/// property of the notification is zero.
///
/// When an extent notification is received by a [NotificationListener], the
/// listener will already have completed build and layout, and it is therefore
/// too late for that widget to call [State.setState]. Any attempt to adjust the
/// build or layout based on an extent notification would result in a layout
/// that lagged one frame behind, which is a poor user experience. Extent
/// notifications are used primarily to drive animations. The [Scaffold] widget
/// listens for extent notifications and responds by driving animations for the
/// [FloatingActionButton] as the bottom sheet scrolls up.
class DraggableScrollableNotification extends Notification with ViewportNotificationMixin {
  /// Creates a notification that the extent of a [DraggableScrollableSheet] has
  /// changed.
  ///
  /// All parameters are required. The [minExtent] must be >= 0. The [maxExtent]
  /// must be <= 1.0. The [extent] must be between [minExtent] and [maxExtent].
  DraggableScrollableNotification({
    required this.extent,
    required this.minExtent,
    required this.maxExtent,
    required this.initialExtent,
    required this.context,
  }) : assert(0.0 <= minExtent),
       assert(maxExtent <= 1.0),
       assert(minExtent <= extent),
       assert(minExtent <= initialExtent),
       assert(extent <= maxExtent),
       assert(initialExtent <= maxExtent);

  /// The current value of the extent, between [minExtent] and [maxExtent].
  final double extent;

  /// The minimum value of [extent], which is >= 0.
  final double minExtent;

  /// The maximum value of [extent].
  final double maxExtent;

  /// The initially requested value for [extent].
  final double initialExtent;

  /// The build context of the widget that fired this notification.
  ///
  /// This can be used to find the sheet's render objects to determine the size
  /// of the viewport, for instance. A listener can only assume this context
  /// is live when it first gets the notification.
  final BuildContext context;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('minExtent: $minExtent, extent: $extent, maxExtent: $maxExtent, initialExtent: $initialExtent');
  }
}

/// Manages state between [_DraggableScrollableSheetState],
/// [_DraggableScrollableSheetScrollController], and
/// [_DraggableScrollableSheetScrollPosition].
///
/// The State knows the pixels available along the axis the widget wants to
/// scroll, but expects to get a fraction of those pixels to render the sheet.
///
/// The ScrollPosition knows the number of pixels a user wants to move the sheet.
///
/// The [currentSize] will never be null.
/// The [availablePixels] will never be null, but may be `double.infinity`.
class _DraggableSheetExtent {
  _DraggableSheetExtent({
    required this.minSize,
    required this.maxSize,
    required this.snap,
    required this.snapSizes,
    required this.initialSize,
    this.snapAnimationDuration,
    ValueNotifier<double>? currentSize,
    bool? hasDragged,
    bool? hasChanged,
    this.activePositionCount = 0,
  })  : assert(minSize >= 0),
        assert(maxSize <= 1),
        assert(minSize <= initialSize),
        assert(initialSize <= maxSize),
        _currentSize = currentSize ?? ValueNotifier<double>(initialSize),
        availablePixels = double.infinity,
        hasDragged = hasDragged ?? false,
        hasChanged = hasChanged ?? false;

  VoidCallback? _cancelActivity;

  final double minSize;
  final double maxSize;
  final bool snap;
  final List<double> snapSizes;
  final Duration? snapAnimationDuration;
  final double initialSize;
  final ValueNotifier<double> _currentSize;
  double availablePixels;

  // Used to disable snapping until the user has dragged on the sheet.
  bool hasDragged;

  // Used to determine if the sheet should move to a new initial size when it
  // changes.
  // We need both `hasChanged` and `hasDragged` to achieve the following
  // behavior:
  //   1. The sheet should only snap following user drags (as opposed to
  //      programmatic sheet changes). See docs for `animateTo` and `jumpTo`.
  //   2. The sheet should move to a new initial child size on rebuild iff the
  //      sheet has not changed, either by drag or programmatic control. See
  //      docs for `initialChildSize`.
  bool hasChanged;

  int activePositionCount;

  bool get isAtMin => minSize >= _currentSize.value;
  bool get isAtMax => maxSize <= _currentSize.value;

  double get currentSize => _currentSize.value;
  double get currentPixels => sizeToPixels(_currentSize.value);

  List<double> get pixelSnapSizes => snapSizes.map(sizeToPixels).toList();

  /// Start an activity that affects the sheet and register a cancel call back
  /// that will be called if another activity starts.
  ///
  /// The `onCanceled` callback will get called even if the subsequent activity
  /// started after this one finished, so `onCanceled` must be safe to call at
  /// any time.
  void startActivity({required VoidCallback onCanceled}) {
    _cancelActivity?.call();
    _cancelActivity = onCanceled;
  }

  /// The scroll position gets inputs in terms of pixels, but the size is
  /// expected to be expressed as a number between 0..1.
  ///
  /// This should only be called to respond to a user drag. To update the
  /// size in response to a programmatic call, use [updateSize] directly.
  void addPixelDelta(double delta, BuildContext context) {
    // Stop any playing sheet animations.
    _cancelActivity?.call();
    _cancelActivity = null;
    // The user has interacted with the sheet, set `hasDragged` to true so that
    // we'll snap if applicable.
    hasDragged = true;
    hasChanged = true;
    if (availablePixels == 0) {
      return;
    }
    updateSize(currentSize + pixelsToSize(delta), context);
  }

  /// Set the size to the new value. [newSize] should be a number between
  /// [minSize] and [maxSize].
  ///
  /// This can be triggered by a programmatic (e.g. controller triggered) change
  /// or a user drag.
  void updateSize(double newSize, BuildContext context) {
    final double clampedSize = clampDouble(newSize, minSize, maxSize);
    if (_currentSize.value == clampedSize) {
      return;
    }
    _currentSize.value = clampedSize;
    DraggableScrollableNotification(
      minExtent: minSize,
      maxExtent: maxSize,
      extent: currentSize,
      initialExtent: initialSize,
      context: context,
    ).dispatch(context);
  }

  double pixelsToSize(double pixels) {
    return pixels / availablePixels * maxSize;
  }

  double sizeToPixels(double size) {
    return size / maxSize * availablePixels;
  }

  void dispose() {
    _currentSize.dispose();
  }

  _DraggableSheetExtent copyWith({
    required double minSize,
    required double maxSize,
    required bool snap,
    required List<double> snapSizes,
    required double initialSize,
    Duration? snapAnimationDuration,
  }) {
    return _DraggableSheetExtent(
      minSize: minSize,
      maxSize: maxSize,
      snap: snap,
      snapSizes: snapSizes,
      snapAnimationDuration: snapAnimationDuration,
      initialSize: initialSize,
      // Set the current size to the possibly updated initial size if the sheet
      // hasn't changed yet.
      currentSize: ValueNotifier<double>(hasChanged
          ? clampDouble(_currentSize.value, minSize, maxSize)
          : initialSize),
      hasDragged: hasDragged,
      hasChanged: hasChanged,
      activePositionCount: activePositionCount,
    );
  }
}

class _DraggableScrollableSheetState extends State<DraggableScrollableSheet> {
  late _DraggableScrollableSheetScrollController _scrollController;
  late _DraggableSheetExtent _extent;

  @override
  void initState() {
    super.initState();
    _extent = _DraggableSheetExtent(
      minSize: widget.minChildSize,
      maxSize: widget.maxChildSize,
      snap: widget.snap,
      snapSizes: _impliedSnapSizes(),
      snapAnimationDuration: widget.snapAnimationDuration,
      initialSize: widget.initialChildSize,
    );
    _scrollController = _DraggableScrollableSheetScrollController(extent: _extent);
    widget.controller?._attach(_scrollController);
  }

  List<double> _impliedSnapSizes() {
    for (int index = 0; index < (widget.snapSizes?.length ?? 0); index += 1) {
      final double snapSize = widget.snapSizes![index];
      assert(snapSize >= widget.minChildSize && snapSize <= widget.maxChildSize,
        '${_snapSizeErrorMessage(index)}\nSnap sizes must be between `minChildSize` and `maxChildSize`. ');
      assert(index == 0 || snapSize > widget.snapSizes![index - 1],
        '${_snapSizeErrorMessage(index)}\nSnap sizes must be in ascending order. ');
    }
    // Ensure the snap sizes start and end with the min and max child sizes.
    if (widget.snapSizes == null || widget.snapSizes!.isEmpty) {
      return <double>[
        widget.minChildSize,
        widget.maxChildSize,
      ];
    }
    return <double>[
      if (widget.snapSizes!.first != widget.minChildSize) widget.minChildSize,
      ...widget.snapSizes!,
      if (widget.snapSizes!.last != widget.maxChildSize) widget.maxChildSize,
    ];
  }

  @override
  void didUpdateWidget(covariant DraggableScrollableSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(_scrollController);
    }
    _replaceExtent(oldWidget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_InheritedResetNotifier.shouldReset(context)) {
      _scrollController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _extent._currentSize,
      builder: (BuildContext context, double currentSize, Widget? child) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          _extent.availablePixels = widget.maxChildSize * constraints.biggest.height;
          final Widget sheet = FractionallySizedBox(
            heightFactor: currentSize,
            alignment: Alignment.bottomCenter,
            child: child,
          );
          return widget.expand ? SizedBox.expand(child: sheet) : sheet;
        },
      ),
      child: widget.builder(context, _scrollController),
    );
  }

  @override
  void dispose() {
    widget.controller?._detach(disposeExtent: true);
    _scrollController.dispose();
    super.dispose();
  }

  void _replaceExtent(covariant DraggableScrollableSheet oldWidget) {
    final _DraggableSheetExtent previousExtent = _extent;
    _extent = previousExtent.copyWith(
      minSize: widget.minChildSize,
      maxSize: widget.maxChildSize,
      snap: widget.snap,
      snapSizes: _impliedSnapSizes(),
      snapAnimationDuration: widget.snapAnimationDuration,
      initialSize: widget.initialChildSize,
    );
    // Modify the existing scroll controller instead of replacing it so that
    // developers listening to the controller do not have to rebuild their listeners.
    _scrollController.extent = _extent;
    // If an external facing controller was provided, let it know that the
    // extent has been replaced.
    widget.controller?._onExtentReplaced(previousExtent);
    previousExtent.dispose();
    if (widget.snap
        && (widget.snap != oldWidget.snap || widget.snapSizes != oldWidget.snapSizes)
        && _scrollController.hasClients
    ) {
      // Trigger a snap in case snap or snapSizes has changed and there is a
      // scroll position currently attached. We put this in a post frame
      // callback so that `build` can update `_extent.availablePixels` before
      // this runs-we can't use the previous extent's available pixels as it may
      // have changed when the widget was updated.
      WidgetsBinding.instance.addPostFrameCallback((Duration timeStamp) {
        for (int index = 0; index < _scrollController.positions.length; index++) {
          final _DraggableScrollableSheetScrollPosition position =
            _scrollController.positions.elementAt(index) as _DraggableScrollableSheetScrollPosition;
          position.goBallistic(0);
        }
      });
    }
  }

  String _snapSizeErrorMessage(int invalidIndex) {
    final List<String> snapSizesWithIndicator = widget.snapSizes!.asMap().keys.map(
      (int index) {
        final String snapSizeString = widget.snapSizes![index].toString();
        if (index == invalidIndex) {
          return '>>> $snapSizeString <<<';
        }
        return snapSizeString;
      },
    ).toList();
    return "Invalid snapSize '${widget.snapSizes![invalidIndex]}' at index $invalidIndex of:\n"
        '  $snapSizesWithIndicator';
  }
}

/// A [ScrollController] suitable for use in a [ScrollableWidgetBuilder] created
/// by a [DraggableScrollableSheet].
///
/// If a [DraggableScrollableSheet] contains content that is exceeds the height
/// of its container, this controller will allow the sheet to both be dragged to
/// fill the container and then scroll the child content.
///
/// See also:
///
///  * [_DraggableScrollableSheetScrollPosition], which manages the positioning logic for
///    this controller.
///  * [PrimaryScrollController], which can be used to establish a
///    [_DraggableScrollableSheetScrollController] as the primary controller for
///    descendants.
class _DraggableScrollableSheetScrollController extends ScrollController {
  _DraggableScrollableSheetScrollController({
    required this.extent,
  });

  _DraggableSheetExtent extent;
  VoidCallback? onPositionDetached;

  @override
  _DraggableScrollableSheetScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _DraggableScrollableSheetScrollPosition(
      physics: const AlwaysScrollableScrollPhysics().applyTo(physics),
      context: context,
      oldPosition: oldPosition,
      getExtent: () => extent,
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('extent: $extent');
  }

  @override
  _DraggableScrollableSheetScrollPosition get position =>
      super.position as _DraggableScrollableSheetScrollPosition;

  void reset() {
    extent._cancelActivity?.call();
    extent.hasDragged = false;
    extent.hasChanged = false;
    // jumpTo can result in trying to replace semantics during build.
    // Just animate really fast.
    // Avoid doing it at all if the offset is already 0.0.
    if (offset != 0.0) {
      animateTo(
        0.0,
        duration: const Duration(milliseconds: 1),
        curve: Curves.linear,
      );
    }
    extent.updateSize(extent.initialSize, position.context.notificationContext!);
  }

  @override
  void detach(ScrollPosition position) {
    onPositionDetached?.call();
    super.detach(position);
  }
}

class _SheetBallisticScrollActivity extends BallisticScrollActivity {
  _SheetBallisticScrollActivity(
    _DraggableScrollableSheetScrollPosition scrollPosition,
    Simulation simulation,
  ) : super(scrollPosition, simulation, scrollPosition.context.vsync, false);

  @override
  _DraggableScrollableSheetScrollPosition get delegate =>
      super.delegate as _DraggableScrollableSheetScrollPosition;

  @override
  void applyNewDimensions() {
    // This is expected to happen continuously while scrolling the outer sheet.
  }

  @override
  bool applyMoveTo(double value){
    final _DraggableSheetExtent extent = delegate.extent;
    extent.updateSize(
        extent.pixelsToSize(value), delegate.context.notificationContext!);

    if ((velocity < 0.0 && extent.isAtMin) ||
        (velocity > 0.0 && extent.isAtMax)) {
      // Make sure we pass along enough velocity to keep scrolling - otherwise
      // we just "bounce" off the top making it look like the list doesn't have
      // more to scroll.
      delegate.goBallistic(velocity +
          delegate.physics.toleranceFor(delegate).velocity * velocity.sign);
    }

    return true;
  }
}

/// A scroll position that manages scroll activities for
/// [_DraggableScrollableSheetScrollController].
///
/// This class is a concrete subclass of [ScrollPosition] logic that handles a
/// single [ScrollContext], such as a [Scrollable]. An instance of this class
/// manages [ScrollActivity] instances, which changes the
/// [_DraggableSheetExtent.currentSize] or visible content offset in the
/// [Scrollable]'s [Viewport]
///
/// See also:
///
///  * [_DraggableScrollableSheetScrollController], which uses this as its [ScrollPosition].
class _DraggableScrollableSheetScrollPosition extends ScrollPositionWithSingleContext {
  _DraggableScrollableSheetScrollPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
    required this.getExtent,
  });

  final _DraggableSheetExtent Function() getExtent;
  bool get listShouldScroll => pixels > 0.0;
  bool get isActive => activity != null && activity is! IdleScrollActivity;

  _DraggableSheetExtent get extent => getExtent();

  @override
  void dispose() {
    if (isActive) {
      --extent.activePositionCount;
      assert(extent.activePositionCount >= 0);
      // If this position was absorbed into another, the activity was
      // transferred and is null here so we don't need to worry about it.
      // Otherwise all scroll positions start with null activity.
    }
    super.dispose();
  }

  @override
  void applyUserOffset(double delta) {
    if (!listShouldScroll &&
        (!(extent.isAtMin || extent.isAtMax) ||
          (extent.isAtMin && delta < 0) ||
          (extent.isAtMax && delta > 0))) {
      extent.addPixelDelta(-delta, context.notificationContext!);
    } else {
      super.applyUserOffset(delta);
    }
  }

  bool get _isAtSnapSize {
    return extent.snapSizes.any(
      (double snapSize) {
        return (extent.currentSize - snapSize).abs() <= extent.pixelsToSize(physics.toleranceFor(this).distance);
      },
    );
  }
  bool get _shouldSnap =>
      extent.snap &&
      extent.hasDragged &&
      !_isAtSnapSize &&
      // Only allow `goBallistic(0)` to snap if there are no active positions on
      // the extent or if this position itself is active.
      (extent.activePositionCount == 0 || isActive);

  @override
  void beginActivity(ScrollActivity? newActivity) {
    final bool wasActive = isActive;
    super.beginActivity(newActivity);
    if (newActivity == null) {
      return;
    }

    if (isActive != wasActive) {
      if (isActive) {
        ++extent.activePositionCount;
      } else {
        --extent.activePositionCount;
        assert(extent.activePositionCount >= 0);
      }
    }
  }

  @override
  void goBallistic(double velocity) {
    if ((velocity == 0.0 && !_shouldSnap) ||
        (velocity < 0.0 && listShouldScroll) ||
        (velocity > 0.0 && (extent.isAtMax ||
          // Go ballistic on inner scrollable if we're snapped, it's scrolled,
          // and it can be scrolled further. Otherwise, we'd try to use a
          // snapping simulation that would no-op and kill the momentum,
          // inconsistent with the velocity < 0.0 case.
          //
          // This differs from applyUserOffset, which always defers to
          // listShouldScroll. This means that in the non-snap case, dragging a
          // scrolled inner list upwards will first scroll the list, but upon
          // release (when it goes ballistic) will scroll the sheet. In the snap
          // case, this means that dragging an inner list scrolled to its end
          // upwards will first do nothing, but upon release with velocity will
          // scroll the sheet to the next snap point.
          (extent.snap && _isAtSnapSize &&
           listShouldScroll && pixels < maxScrollExtent))) ||
        // If we've already deferred to the inner scrollable, stick with it.
        // This can also prevent conflicts with activities on other scroll
        // positions, which could otherwise, if they resize the sheet, cause
        // this BallisticScrollActivity to goBalistic(velocity) and try to take
        // back control of the sheet (e.g. if we're no longer at max and the
        // inner list is ballistic with velocity > 0.0).
        //
        // It might be better to do this by splitting out a separate delegate
        // for the sheet vs. the inner scrollable, rather than testing
        // activity.runtimeType, but it's unclear whether it's worth the
        // complexity.
        (activity.runtimeType == BallisticScrollActivity)) {
      super.goBallistic(velocity);
      return;
    }

    final Simulation simulation;
    if (extent.snap) {
      // Snap is enabled, simulate snapping instead of clamping scroll.
      simulation = _SnappingSimulation(
        position: extent.currentPixels,
        initialVelocity: velocity,
        pixelSnapSize: extent.pixelSnapSizes,
        snapAnimationDuration: extent.snapAnimationDuration,
        tolerance: physics.toleranceFor(this),
      );
    } else {
      // The iOS bouncing simulation just isn't right here - once we delegate
      // the ballistic back to the ScrollView, it will use the right simulation.
      simulation = ClampingScrollSimulation(
        // Run the simulation in terms of pixels, not extent.
        position: extent.currentPixels,
        velocity: velocity,
        tolerance: physics.toleranceFor(this),
      );
    }

    beginActivity(_SheetBallisticScrollActivity(this, simulation));
  }
}

/// A widget that can notify a descendent [DraggableScrollableSheet] that it
/// should reset its position to the initial state.
///
/// The [Scaffold] uses this widget to notify a persistent bottom sheet that
/// the user has tapped back if the sheet has started to cover more of the body
/// than when at its initial position. This is important for users of assistive
/// technology, where dragging may be difficult to communicate.
///
/// This is just a wrapper on top of [DraggableScrollableController]. It is
/// primarily useful for controlling a sheet in a part of the widget tree that
/// the current code does not control (e.g. library code trying to affect a sheet
/// in library users' code). Generally, it's easier to control the sheet
/// directly by creating a controller and passing the controller to the sheet in
/// its constructor (see [DraggableScrollableSheet.controller]).
class DraggableScrollableActuator extends StatelessWidget {
  /// Creates a widget that can notify descendent [DraggableScrollableSheet]s
  /// to reset to their initial position.
  ///
  /// The [child] parameter is required.
  DraggableScrollableActuator({
    super.key,
    required this.child,
  });

  /// This child's [DraggableScrollableSheet] descendant will be reset when the
  /// [reset] method is applied to a context that includes it.
  ///
  /// Must not be null.
  final Widget child;

  final _ResetNotifier _notifier = _ResetNotifier();

  /// Notifies any descendant [DraggableScrollableSheet] that it should reset
  /// to its initial position.
  ///
  /// Returns `true` if a [DraggableScrollableActuator] is available and
  /// some [DraggableScrollableSheet] is listening for updates, `false`
  /// otherwise.
  static bool reset(BuildContext context) {
    final _InheritedResetNotifier? notifier = context.dependOnInheritedWidgetOfExactType<_InheritedResetNotifier>();
    if (notifier == null) {
      return false;
    }
    return notifier._sendReset();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedResetNotifier(notifier: _notifier, child: child);
  }
}

/// A [ChangeNotifier] to use with [InheritedResetNotifier] to notify
/// descendants that they should reset to initial state.
class _ResetNotifier extends ChangeNotifier {
  /// Whether someone called [sendReset] or not.
  ///
  /// This flag should be reset after checking it.
  bool _wasCalled = false;

  /// Fires a reset notification to descendants.
  ///
  /// Returns false if there are no listeners.
  bool sendReset() {
    if (!hasListeners) {
      return false;
    }
    _wasCalled = true;
    notifyListeners();
    return true;
  }
}

class _InheritedResetNotifier extends InheritedNotifier<_ResetNotifier> {
  /// Creates an [InheritedNotifier] that the [DraggableScrollableSheet] will
  /// listen to for an indication that it should reset itself back to [DraggableScrollableSheet.initialChildSize].
  ///
  /// The [child] and [notifier] properties must not be null.
  const _InheritedResetNotifier({
    required super.child,
    required _ResetNotifier super.notifier,
  });

  bool _sendReset() => notifier!.sendReset();

  /// Specifies whether the [DraggableScrollableSheet] should reset to its
  /// initial position.
  ///
  /// Returns true if the notifier requested a reset, false otherwise.
  static bool shouldReset(BuildContext context) {
    final InheritedWidget? widget = context.dependOnInheritedWidgetOfExactType<_InheritedResetNotifier>();
    if (widget == null) {
      return false;
    }
    assert(widget is _InheritedResetNotifier);
    final _InheritedResetNotifier inheritedNotifier = widget as _InheritedResetNotifier;
    final bool wasCalled = inheritedNotifier.notifier!._wasCalled;
    inheritedNotifier.notifier!._wasCalled = false;
    return wasCalled;
  }
}

class _SnappingSimulation extends Simulation {
  _SnappingSimulation({
    required this.position,
    required double initialVelocity,
    required List<double> pixelSnapSize,
    Duration? snapAnimationDuration,
    super.tolerance,
  }) {
    _pixelSnapSize = _getSnapSize(initialVelocity, pixelSnapSize);

    if (snapAnimationDuration != null && snapAnimationDuration.inMilliseconds > 0) {
       velocity = (_pixelSnapSize - position) * 1000 / snapAnimationDuration.inMilliseconds;
    }
    // Check the direction of the target instead of the sign of the velocity because
    // we may snap in the opposite direction of velocity if velocity is very low.
    else if (_pixelSnapSize < position) {
      velocity = math.min(-minimumSpeed, initialVelocity);
    } else {
      velocity = math.max(minimumSpeed, initialVelocity);
    }
  }

  final double position;
  late final double velocity;

  // A minimum speed to snap at. Used to ensure that the snapping animation
  // does not play too slowly.
  static const double minimumSpeed = 1600.0;

  late final double _pixelSnapSize;

  @override
  double dx(double time) {
    if (isDone(time)) {
      return 0;
    }
    return velocity;
  }

  @override
  bool isDone(double time) {
    return x(time) == _pixelSnapSize;
  }

  @override
  double x(double time) {
    final double newPosition = position + velocity * time;
    if ((velocity >= 0 && newPosition > _pixelSnapSize) ||
        (velocity < 0 && newPosition < _pixelSnapSize)) {
      // We're passed the snap size, return it instead.
      return _pixelSnapSize;
    }
    return newPosition;
  }

  // Find the closest snap sizes to the position. If the velocity is non-zero,
  // select the next size in the velocity's direction. Otherwise, the nearest
  // snap size.
  double _getSnapSize(double initialVelocity, List<double> pixelSnapSizes) {
    final int indexOfNextSize = pixelSnapSizes
        .indexWhere((double size) => size >= position);
    if (indexOfNextSize == 0) {
      return pixelSnapSizes.first;
    }
    final double nextSize = pixelSnapSizes[indexOfNextSize];
    final double previousSize = pixelSnapSizes[indexOfNextSize - 1];
    if (initialVelocity.abs() <= tolerance.velocity) {
      // If velocity is zero, snap to the nearest snap size with the minimum velocity.
      if (position - previousSize < nextSize - position) {
        return previousSize;
      } else {
        return nextSize;
      }
    }
    // Snap forward or backward depending on current velocity.
    if (initialVelocity < 0.0) {
      return previousSize;
    }
    if (initialVelocity > 0.0 &&
        position == nextSize &&
        indexOfNextSize + 1 < pixelSnapSizes.length) {
      return pixelSnapSizes[indexOfNextSize + 1];
    }
    return nextSize;
  }
}
