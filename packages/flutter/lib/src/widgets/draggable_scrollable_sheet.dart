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

class _DraggableSheetExtent {
  _DraggableSheetExtent({
    @required this.minExtent,
    @required this.maxExtent,
    @required this.initialExtent,
    @required VoidCallback listener,
  }) : assert(minExtent != null),
       assert(maxExtent != null),
       assert(initialExtent != null),
       assert(minExtent >= 0),
       assert(maxExtent <= 1),
       assert(minExtent <= initialExtent),
       assert(initialExtent <= maxExtent),
       _currentExtent = ValueNotifier<double>(initialExtent)..addListener(listener),
       availablePixels = double.infinity;

  final double minExtent;
  final double maxExtent;
  final double initialExtent;
  final ValueNotifier<double> _currentExtent;
  double availablePixels;

  bool get isAtMin => minExtent >= _currentExtent.value;
  bool get isAtMax => maxExtent <= _currentExtent.value;

  set currentExtent(double value) {
    assert(value != null);
    _currentExtent.value = value.clamp(minExtent, maxExtent);
  }
  double get currentExtent => _currentExtent.value;

  void addPixelDelta(double delta) {
    currentExtent += delta / availablePixels;
  }
}

class _DraggableScrollableSheetState extends State<DraggableScrollableSheet> {
  _DraggableScrollableSheetScrollController _scrollController;
  _DraggableSheetExtent _extent;
  double _childSizePercentage;

  @override
  void initState() {
    super.initState();
    _extent = _DraggableSheetExtent(
      minExtent: widget.minChildSize,
      maxExtent: widget.maxChildSize,
      initialExtent: widget.initialChildSize,
      listener: _setExtent,
    );
    _childSizePercentage = _extent.availablePixels;
    _scrollController = _DraggableScrollableSheetScrollController(extent: _extent);
  }

  void _setExtent() {
    setState(() {
      _childSizePercentage = _extent.currentExtent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        switch (widget.axis) {
          case Axis.vertical:
            _extent.availablePixels = widget.maxChildSize * constraints.biggest.height;
            return SizedBox.expand(
              child: FractionallySizedBox(
                heightFactor: _extent.currentExtent,
                child: widget.builder(context, _scrollController),
                alignment: widget.alignment,
              ),
            );
            break;
          case Axis.horizontal:
            _extent.availablePixels = widget.maxChildSize * constraints.biggest.width;
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
  }) : assert(extent != null),
       super(
         debugLabel: debugLabel,
         initialScrollOffset: initialScrollOffset,
       );

  final _DraggableSheetExtent extent;

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
      extent: extent,
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('extent: $extent');
  }
}

/// A scroll position that manages scroll activities for
/// [_DraggableScrollableSheetScrollController].
///
/// This class is a concrete subclass of [ScrollPosition] logic that handles a
/// single [ScrollContext], such as a [Scrollable]. An instance of this class
/// manages [ScrollActivity] instances, which changes the
/// [_DraggableSheetExtent.currentExtent] or visible content offset in the
/// [Scrollable]'s [Viewport]
///
/// See also:
///
///  * [_DraggableScrollableSheetScrollController], which uses this as its [ScrollPosition].
class _DraggableScrollableSheetScrollPosition
    extends ScrollPositionWithSingleContext {
  _DraggableScrollableSheetScrollPosition({
    @required ScrollPhysics physics,
    @required ScrollContext context,
    double initialPixels = 0.0,
    bool keepScrollOffset = true,
    ScrollPosition oldPosition,
    String debugLabel,
    @required this.extent,
  })  : assert(extent != null),
        super(
          physics: physics,
          context: context,
          initialPixels: initialPixels,
          keepScrollOffset: keepScrollOffset,
          oldPosition: oldPosition,
          debugLabel: debugLabel,
        );

  VoidCallback _dragCancelCallback;
  final _DraggableSheetExtent extent;
  bool get listShouldScroll => pixels > 0.0;

  @override
  void applyUserOffset(double delta) {
    if (!listShouldScroll &&
        !(extent.isAtMin || extent.isAtMax) ||
         (extent.isAtMin && delta < 0) ||
         (extent.isAtMax && delta > 0)) {
      extent.addPixelDelta(-delta);
    } else {
      super.applyUserOffset(delta);
    }
  }

  @override
  void goBallistic(double velocity) {
    if (velocity == 0.0 ||
       (velocity < 0.0 && listShouldScroll) ||
       (velocity > 0.0 && extent.isAtMax)) {
      super.goBallistic(velocity);
      return;
    }
    // Scrollable expects that we will dispose of its current _dragCancelCallback
    _dragCancelCallback?.call();
    _dragCancelCallback = null;

    // The iOS bouncing simulation just isn't right here - once we delegate
    // the ballistic back to the ScrollView, it will use the right simulation.
    final Simulation simulation = ClampingScrollSimulation(
      position: extent.currentExtent,
      velocity: velocity,
      tolerance: physics.tolerance,
    );

    final AnimationController ballisticController = AnimationController.unbounded(
      debugLabel: '$runtimeType',
      vsync: context.vsync,
    );
    double lastDelta = 0;
    void _tick() {
      final double delta = ballisticController.value - lastDelta;
      lastDelta = ballisticController.value;
      extent.addPixelDelta(delta);
      if ((velocity > 0 && extent.isAtMax) || (velocity < 0 && extent.isAtMin)) {
        // Make sure we pass along enough velocity to keep scrolling - otherwise
        // we just "bounce" off the top making it look like the list doesn't
        // have more to scroll.
        velocity = ballisticController.velocity + (physics.tolerance.velocity * ballisticController.velocity.sign);
        super.goBallistic(velocity);
        ballisticController.stop();
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
