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

/// The return signature of [_ApplyUserOffsetToSize].
class _TopAndDeltaRemainder {
  const _TopAndDeltaRemainder({@required this.top, @required this.hasRemainder})
      : assert(top != null),
        assert(hasRemainder != null);

  /// Whether the operation consumed all of the delta or not.
  final bool hasRemainder;

  /// The new top percentage after the delta is applied.
  final double top;
}

/// The signature for a method that takes a delta from a scroll controller
/// and converts it to the proper ratio for the current layout constraints.
typedef _ApplyUserOffsetToSize = _TopAndDeltaRemainder Function(double delta);

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
  _DraggableScrollableSheetState createState() =>
      _DraggableScrollableSheetState();
}

class _DraggableScrollableSheetState extends State<DraggableScrollableSheet> {
  _DraggableScrollableSheetScrollController _scrollController;
  double _childSizePercentage;
  BoxConstraints _constraints = const BoxConstraints.expand();

  @override
  void initState() {
    super.initState();
    _scrollController = _DraggableScrollableSheetScrollController(
      context: context,
      initialTop: widget.initialChildSize,
      minTop: widget.minChildSize,
      maxTop: widget.maxChildSize,
      applyUserOffsetToSize: _setHeight,
    );
    _childSizePercentage = widget.initialChildSize;
  }

  _TopAndDeltaRemainder _setHeight(double delta) {
    assert(delta != null);
    assert(_constraints != null);
    final double percentage = delta / _constraints.biggest.height;
    final double sizePercentage = _childSizePercentage - percentage;
    final double newSizePercentage = sizePercentage.clamp(
      widget.minChildSize,
      widget.maxChildSize,
    );
    setState(() {
      _childSizePercentage = newSizePercentage;
    });
    return _TopAndDeltaRemainder(
      top: _childSizePercentage,
      hasRemainder: sizePercentage - newSizePercentage > 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    FractionallySizedBox box;
    switch (widget.axis) {
      case Axis.vertical:
        box = FractionallySizedBox(
          heightFactor: _childSizePercentage,
          child: widget.builder(context, _scrollController),
          alignment: widget.alignment,
        );
        break;
      case Axis.horizontal:
        box = FractionallySizedBox(
          widthFactor: _childSizePercentage,
          child: widget.builder(context, _scrollController),
          alignment: widget.alignment,
        );
        break;
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _constraints = constraints;
        return SizedBox.expand(child: box);
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
/// While the [top] value is between [minTop] and [maxTop], scroll events will
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
    this.initialTop = 0.5,
    String debugLabel,
    @required BuildContext context,
    @required this.maxTop,
    this.minTop = 0.0,
    @required this.applyUserOffsetToSize,
  })  : assert(initialTop != null),
        assert(context != null),
        assert(maxTop != null),
        assert(minTop != null),
        assert(0.0 < minTop &&
            minTop <= initialTop &&
            initialTop <= maxTop &&
            maxTop <= 1),
        assert(applyUserOffsetToSize != null),
        super(debugLabel: debugLabel, initialScrollOffset: initialScrollOffset);

  final _ApplyUserOffsetToSize applyUserOffsetToSize;

  /// The position that was originally requested as the top for this sheet.
  final double initialTop;
  final double minTop;
  final double maxTop;

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
      minTop: minTop,
      maxTop: maxTop,
      top: initialTop,
      applyUserOffsetToSize: applyUserOffsetToSize,
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('initialTop: $initialTop');
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
    this.minTop = 0.0,
    @required this.maxTop,
    @required this.top,
    @required this.applyUserOffsetToSize,
  })  : assert(applyUserOffsetToSize != null),
        assert(minTop != null),
        assert(maxTop != null),
        assert(top != null),
        super(
          physics: physics,
          context: context,
          initialPixels: initialPixels,
          keepScrollOffset: keepScrollOffset,
          oldPosition: oldPosition,
          debugLabel: debugLabel,
        );

  final _ApplyUserOffsetToSize applyUserOffsetToSize;

  VoidCallback _dragCancelCallback;

  final double minTop;
  final double maxTop;
  double top;

  bool _addDeltaToTop(double delta) {
    final _TopAndDeltaRemainder newDelta = applyUserOffsetToSize(delta);
    assert(minTop <= newDelta.top && newDelta.top <= maxTop);
    top = newDelta.top;
    return newDelta.hasRemainder;
  }

  bool get topIsAtMax => top >= maxTop;
  bool get listIsAtTop => pixels <= 0.0;

  @override
  void applyUserOffset(double delta) {
    // If we haven't gotten the top of the widget to the maximum top,
    // or we have gotten it there but the list is already scrolled up to the top.
    // This is called much more frequently where topIsAtMax, so check that first.
    if (!topIsAtMax || (topIsAtMax && listIsAtTop)) {
      if (_addDeltaToTop(delta)) {
        super.applyUserOffset(delta);
      }
    } else {
      super.applyUserOffset(delta);
    }
  }

  @override
  void goBallistic(double velocity) {
    if (velocity == 0.0 ||
        (velocity < 0.0 && !listIsAtTop) ||
        (velocity > 0.0 && topIsAtMax)) {
      super.goBallistic(velocity);
      return;
    }
    // Scrollable expects that we will dispose of its current _dragCancelCallback
    _dragCancelCallback?.call();
    _dragCancelCallback = null;

    Simulation simulation = physics.createBallisticSimulation(this, velocity);
    if (simulation == null) {
      // On Android, physics will think we have nothing left to scroll
      // and fail to give us a physical simulation - but we want one to finish
      // scrolling the top down to minTop.
      if (top != minTop) {
        simulation = ClampingScrollSimulation(
          position: pixels + velocity,
          velocity: velocity,
          tolerance: physics.tolerance,
        );
      } else {
        goIdle();
        return;
      }
    }

    final AnimationController ballisticController =
        AnimationController.unbounded(
      debugLabel: '$runtimeType',
      vsync: context.vsync,
    );
    void _tickUp() {
      if (_addDeltaToTop(-ballisticController.value) || topIsAtMax) {
        ballisticController.stop();
        super.goBallistic(velocity);
      }
    }

    void _tickDown() {
      if (_addDeltaToTop(ballisticController.value.abs()) || listIsAtTop) {
        ballisticController.stop();
        super.goBallistic(velocity);
      }
    }

    ballisticController
      ..addListener(velocity > 0.0 ? _tickUp : _tickDown)
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
