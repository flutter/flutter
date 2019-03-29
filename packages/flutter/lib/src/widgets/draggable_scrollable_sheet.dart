// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';

import 'basic.dart';
import 'framework.dart';
import 'layout_builder.dart';
import 'scroll_context.dart';
import 'scroll_controller.dart';
import 'scroll_physics.dart';
import 'scroll_position.dart';
import 'scroll_position_with_single_context.dart';
import 'scroll_simulation.dart';

/// The signature of a method that provides a [BuildContext] and
/// [ScrollController] for building a widget that may overflow the draggable
/// [Axis] of the containing [DraggableScrollSheet].
///
/// Users should apply the [scrollController] to a [ScrollView] subclass, such
/// as a [SingleChildScrollView], [ListView] or [GridView], to have the whole
/// sheet be draggable.
typedef ScrollableWidgetBuilder = Widget Function(
  BuildContext context,
  ScrollController scrollController,
);

/// A widget that can be dragged along its [Axis] between its `minChildSize` and
/// `maxChildSize`, which are relative to the parent container.
///
/// The widget will initially be displayed at its `initialChildSize`. To enable
/// dragging of the widget, ensure that the `builder` creates a widget that
/// consumes the provided [ScrollController]. If the widget created by the
/// [ScrollableWidgetBuilder] does not consume the provided [ScrollController],
/// the sheet will remain at the `initialChildSize`.
class DraggableScrollableSheet extends StatefulWidget {
  /// Creates a widget that can be dragged and scrolled in a single gesture.
  ///
  /// The `builder`, `initialChildSize`, `maxChildSize`, `axis`, and `alignment`
  /// parameters must not be null.
  const DraggableScrollableSheet({
    Key key,
    this.initialChildSize = 0.5,
    this.minChildSize = 0.25,
    this.maxChildSize = 1.0,
    @required this.builder,
    this.axis = Axis.vertical,
    this.alignment = Alignment.bottomCenter,
  })  : assert(initialChildSize != null),
        assert(minChildSize != null),
        assert(maxChildSize != null),
        assert(builder != null),
        assert(axis != null),
        assert(alignment != null),
        super(key: key);

  /// The axis along which dragging and scrolling will occur for this widget.
  final Axis axis;

  /// The alignment to apply to the widget created by `builder`.
  final Alignment alignment;

  /// The initial fractional value of the parent container to use when
  /// displaying the widget.
  final double initialChildSize;

  /// The minimum fractional value of the parent container to use when
  /// displaying the widget.
  final double minChildSize;

  /// The maximum fractional value of the parent container to use when
  /// displaying the widget.
  final double maxChildSize;

  /// The builder that creates a child to display in this widget, which will
  /// consume the provided [ScrollController] to enable dragging and scrolling
  /// of the contents.
  final ScrollableWidgetBuilder builder;

  @override
  _DraggableScrollableSheetState createState() => _DraggableScrollableSheetState();
}

class _DraggableScrollableSheetState extends State<DraggableScrollableSheet> {
  _DraggableScrollableSheetScrollController _scrollController;
  double _childSizePercentage;
  double _maxSize;

  @override
  void initState() {
    super.initState();
    _scrollController = _DraggableScrollableSheetScrollController(
      extent: () => _maxSize,
      maxExtent: widget.maxChildSize,
      minExtent: widget.minChildSize,
      occupiedExtent: widget.initialChildSize,
      extentListener: _setExtent,
    );
    _childSizePercentage = widget.initialChildSize;
    _maxSize = double.infinity;
  }

  void _setExtent() {
    setState(() {
      _childSizePercentage = _scrollController.occupiedExtent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        switch (widget.axis) {
          case Axis.vertical:
            _maxSize = widget.maxChildSize * constraints.biggest.height;
            return SizedBox.expand(
              child: FractionallySizedBox(
                heightFactor: _childSizePercentage,
                child: widget.builder(context, _scrollController),
                alignment: widget.alignment,
              ),
            );
            break;
          case Axis.horizontal:
            _maxSize = widget.maxChildSize * constraints.biggest.width;
            return SizedBox.expand(
              child: FractionallySizedBox(
                widthFactor: _childSizePercentage,
                child: widget.builder(context, _scrollController),
                alignment: widget.alignment,
              ),
            );
            break;
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }
}

/// A [ScrollController] suitable for use in a [ScrollableWidgetBuilder] created
/// by a [DraggableScrollableSheet].
///
/// If a [DraggableScrollableSheet] contains content that is exceeds the height
/// of its container, this controller will allow the sheet to both be dragged to
/// fill the container and then scroll the child content.
///
/// While the [occupiedExtent] value is between [minTop] and [maxTop], scroll events will
/// drive [top]. Once it has reached [minTop] or [maxTop], scroll events will
/// drive [offset]. The [top] value is guaranteed to be clamped between
/// [minTop] and [maxTop]. The owner must manage the controllers lifetime and
/// call [dispose] when the controller is no longer needed.
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
    double initialScrollOffset = 0.0,
    String debugLabel,
    @required this.extent,
    @required this.minExtent,
    @required this.maxExtent,
    @required double occupiedExtent,
    @required VoidCallback extentListener,
  }) : assert(minExtent != null),
       assert(maxExtent != null),
       assert(extent != null),
       assert(occupiedExtent != null),
       assert(extentListener != null),
       assert(minExtent >= 0),
       assert(maxExtent >= 1),
       assert(minExtent <= occupiedExtent && occupiedExtent <= maxExtent),
       _extentValueNotifier = ValueNotifier<double>(occupiedExtent)..addListener(extentListener),
       super(
         debugLabel: debugLabel,
         initialScrollOffset: initialScrollOffset,
       );

  final ValueNotifier<double> _extentValueNotifier;
  final ValueGetter<double> extent;
  final double minExtent;
  final double maxExtent;

  double get occupiedExtent => _extentValueNotifier.value;

  @override
  _DraggableScrollableSheetScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition oldPosition,
  ) {
    return _DraggableScrollableSheetScrollPosition(
      physics: physics,
      context: context,
      oldPosition: oldPosition,
      extentValueNotifier: _extentValueNotifier,
      extent: extent,
      minExtent: minExtent,
      maxExtent: maxExtent,
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('minExtent: $minExtent');
    description.add('occupiedExtent: $occupiedExtent');
    description.add('maxExtent: $maxExtent');
    description.add('extent: ${extent()}');
  }
}

/// A scroll position that manages scroll activities for
/// [_DraggableScrollableSheetScrollController], which delegates its [top]
/// member to this class.
///
/// This class is a concrete subclass of [ScrollPosition] logic that handles a
/// single [ScrollContext], such as a [Scrollable]. An instance of this class
/// manages [ScrollActivity] instances, which changes the
/// [_DraggableScrollableSheetScrollController.top] or visible content offset in the
/// [Scrollable]'s [Viewport].
///
/// See also:
///
///  * [_DraggableScrollableSheetScrollController], which uses this as its [ScrollPosition].
class _DraggableScrollableSheetScrollPosition
    extends ScrollPositionWithSingleContext {
  /// Creates a new [_DraggableScrollableSheetScrollPosition].
  ///
  /// The [context], and [minTop] parameters
  /// must not be null.  If [maxTop] is null, it will be defaulted to
  /// [double.maxFinite].  The [minTop] and [maxTop] values must be positive
  /// numbers.
  _DraggableScrollableSheetScrollPosition({
    @required ScrollPhysics physics,
    @required ScrollContext context,
    double initialPixels = 0.0,
    bool keepScrollOffset = true,
    ScrollPosition oldPosition,
    String debugLabel,
    @required this.extentValueNotifier,
    @required this.extent,
    @required this.minExtent,
    @required this.maxExtent,
  })  : assert(minExtent != null),
        assert(maxExtent != null),
        assert(minExtent >= 0),
        assert(maxExtent <= 1),
        assert(minExtent < maxExtent),
        assert(extent != null),
        super(
          physics: physics,
          context: context,
          initialPixels: initialPixels,
          keepScrollOffset: keepScrollOffset,
          oldPosition: oldPosition,
          debugLabel: debugLabel,
        );

  final ValueNotifier<double> extentValueNotifier;
  VoidCallback _dragCancelCallback;
  final ValueGetter<double> extent;
  final double minExtent;
  final double maxExtent;
  bool get isAtMin => minExtent >= extentValueNotifier.value;
  bool get isAtMax => maxExtent <= extentValueNotifier.value;
  bool get listIsAtTop => pixels <= 0.0;

  @override
  void applyUserOffset(double delta) {
    if (listIsAtTop &&
        !(isAtMin || isAtMax) ||
         (isAtMin && delta < 0) ||
         (isAtMax && delta > 0)) {
      extentValueNotifier.value = (extentValueNotifier.value - delta / extent()).clamp(
        minExtent,
        maxExtent,
      );
    } else {
      super.applyUserOffset(delta);
    }
  }

  @override
  void goBallistic(double velocity) {
    if (velocity == 0.0 ||
       (velocity < 0.0 && !listIsAtTop) ||
       (velocity > 0.0 && isAtMax)) {
      super.goBallistic(velocity);
      return;
    }
    // Scrollable expects that we will dispose of its current _dragCancelCallback
    _dragCancelCallback?.call();
    _dragCancelCallback = null;

    // The iOS bouncing simulation just isn't right here - once we delegate
    // the ballistic back to the ScrollView, it will use the right simulation.
    final Simulation simulation = ClampingScrollSimulation(
      position: extentValueNotifier.value,
      velocity: velocity,
      tolerance: physics.tolerance,
    );

    final AnimationController ballisticController = AnimationController.unbounded(
      debugLabel: '$runtimeType',
      vsync: context.vsync,
    );
    double lastDelta = 0;
    void _tick() {
      final double delta = ballisticController.value / extent();
      extentValueNotifier.value = (extentValueNotifier.value + delta - lastDelta).clamp(
        minExtent,
        maxExtent,
      );
      lastDelta = delta;
      if ((velocity > 0 && isAtMax) || (velocity < 0 && isAtMin)) {
        velocity = ballisticController.velocity;
        ballisticController.stop();
        super.goBallistic(velocity);
      }
    }

    ballisticController
      ..addListener(_tick)
      ..animateWith(simulation).whenCompleteOrCancel(
        ballisticController.dispose,
      );
  }

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    // Save this so we can call it later if we have to [goBallistic] on our own.
    _dragCancelCallback = dragCancelCallback;
    return super.drag(details, dragCancelCallback);
  }
}
