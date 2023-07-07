// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

library simple_gesture_detector;

import 'package:flutter/material.dart';

/// Callback signature for swipe gesture.
typedef void SwipeCallback(SwipeDirection direction);

/// Possible directions of swipe gesture.
enum SwipeDirection { left, right, up, down }

/// Easy to use, reliable gesture detection Widget. Exposes simple API for basic gestures.
class SimpleGestureDetector extends StatefulWidget {
  /// Widget to be augmented with gesture detection.
  final Widget child;

  /// Configuration for swipe gesture.
  final SimpleSwipeConfig swipeConfig;

  /// Behavior used for hit testing. Set to `HitTestBehavior.deferToChild` by default.
  final HitTestBehavior behavior;

  /// Callback to be run when Widget is swiped vertically. Provides `SwipeDirection`.
  final SwipeCallback? onVerticalSwipe;

  /// Callback to be run when Widget is swiped horizontally. Provides `SwipeDirection`.
  final SwipeCallback? onHorizontalSwipe;

  /// Callback to be run when Widget is tapped;
  final VoidCallback? onTap;

  /// Callback to be run when Widget is double-tapped;
  final VoidCallback? onDoubleTap;

  /// Callback to be run when Widget is long-pressed;
  final VoidCallback? onLongPress;

  /// Creates a [SimpleGestureDetector] widget.
  const SimpleGestureDetector({
    Key? key,
    required this.child,
    this.swipeConfig = const SimpleSwipeConfig(),
    this.behavior = HitTestBehavior.deferToChild,
    this.onVerticalSwipe,
    this.onHorizontalSwipe,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  _SimpleGestureDetectorState createState() => _SimpleGestureDetectorState();
}

class _SimpleGestureDetectorState extends State<SimpleGestureDetector> {
  Offset? _initialSwipeOffset;
  Offset? _finalSwipeOffset;
  SwipeDirection? _previousDirection;

  void _onVerticalDragStart(DragStartDetails details) {
    _initialSwipeOffset = details.globalPosition;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    _finalSwipeOffset = details.globalPosition;

    if (widget.swipeConfig.swipeDetectionBehavior ==
        SwipeDetectionBehavior.singularOnEnd) {
      return;
    }

    final initialOffset = _initialSwipeOffset;
    final finalOffset = _finalSwipeOffset;

    if (initialOffset != null && finalOffset != null) {
      final offsetDifference = initialOffset.dy - finalOffset.dy;

      if (offsetDifference.abs() > widget.swipeConfig.verticalThreshold) {
        _initialSwipeOffset = widget.swipeConfig.swipeDetectionBehavior ==
                SwipeDetectionBehavior.singular
            ? null
            : _finalSwipeOffset;

        final direction =
            offsetDifference > 0 ? SwipeDirection.up : SwipeDirection.down;

        if (widget.swipeConfig.swipeDetectionBehavior ==
                SwipeDetectionBehavior.continuous ||
            _previousDirection == null ||
            direction != _previousDirection) {
          _previousDirection = direction;
          widget.onVerticalSwipe!(direction);
        }
      }
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (widget.swipeConfig.swipeDetectionBehavior ==
        SwipeDetectionBehavior.singularOnEnd) {
      final initialOffset = _initialSwipeOffset;
      final finalOffset = _finalSwipeOffset;

      if (initialOffset != null && finalOffset != null) {
        final offsetDifference = initialOffset.dy - finalOffset.dy;

        if (offsetDifference.abs() > widget.swipeConfig.verticalThreshold) {
          final direction =
              offsetDifference > 0 ? SwipeDirection.up : SwipeDirection.down;
          widget.onVerticalSwipe!(direction);
        }
      }
    }

    _initialSwipeOffset = null;
    _previousDirection = null;
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _initialSwipeOffset = details.globalPosition;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _finalSwipeOffset = details.globalPosition;

    if (widget.swipeConfig.swipeDetectionBehavior ==
        SwipeDetectionBehavior.singularOnEnd) {
      return;
    }

    final initialOffset = _initialSwipeOffset;
    final finalOffset = _finalSwipeOffset;

    if (initialOffset != null && finalOffset != null) {
      final offsetDifference = initialOffset.dx - finalOffset.dx;

      if (offsetDifference.abs() > widget.swipeConfig.horizontalThreshold) {
        _initialSwipeOffset = widget.swipeConfig.swipeDetectionBehavior ==
                SwipeDetectionBehavior.singular
            ? null
            : _finalSwipeOffset;

        final direction =
            offsetDifference > 0 ? SwipeDirection.left : SwipeDirection.right;

        if (widget.swipeConfig.swipeDetectionBehavior ==
                SwipeDetectionBehavior.continuous ||
            _previousDirection == null ||
            direction != _previousDirection) {
          _previousDirection = direction;
          widget.onHorizontalSwipe!(direction);
        }
      }
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (widget.swipeConfig.swipeDetectionBehavior ==
        SwipeDetectionBehavior.singularOnEnd) {
      final initialOffset = _initialSwipeOffset;
      final finalOffset = _finalSwipeOffset;

      if (initialOffset != null && finalOffset != null) {
        final offsetDifference = initialOffset.dx - finalOffset.dx;

        if (offsetDifference.abs() > widget.swipeConfig.horizontalThreshold) {
          final direction =
              offsetDifference > 0 ? SwipeDirection.left : SwipeDirection.right;
          widget.onHorizontalSwipe!(direction);
        }
      }
    }

    _initialSwipeOffset = null;
    _previousDirection = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      child: widget.child,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onDoubleTap: widget.onDoubleTap,
      onVerticalDragStart:
          widget.onVerticalSwipe != null ? _onVerticalDragStart : null,
      onVerticalDragUpdate:
          widget.onVerticalSwipe != null ? _onVerticalDragUpdate : null,
      onVerticalDragEnd:
          widget.onVerticalSwipe != null ? _onVerticalDragEnd : null,
      onHorizontalDragStart:
          widget.onHorizontalSwipe != null ? _onHorizontalDragStart : null,
      onHorizontalDragUpdate:
          widget.onHorizontalSwipe != null ? _onHorizontalDragUpdate : null,
      onHorizontalDragEnd:
          widget.onHorizontalSwipe != null ? _onHorizontalDragEnd : null,
    );
  }
}

/// Behaviors describing swipe gesture detection.
enum SwipeDetectionBehavior {
  singular,
  singularOnEnd,
  continuous,
  continuousDistinct,
}

/// Configuration class for swipe gesture.
class SimpleSwipeConfig {
  /// Amount of offset after which vertical swipes get detected.
  final double verticalThreshold;

  /// Amount of offset after which horizontal swipes get detected.
  final double horizontalThreshold;

  /// Behavior used for swipe gesture detection.
  /// By default, `SwipeDetectionBehavior.singularOnEnd` is used, which runs callback after swipe is completed.
  /// Use `SwipeDetectionBehavior.continuous` for most reactive behavior but be careful with threshold values.
  ///
  /// * `SwipeDetectionBehavior.singular` - Runs callback a single time - when swipe movement is above set threshold.
  /// * `SwipeDetectionBehavior.singularOnEnd` - Runs callback a single time - when swipe is fully completed.
  /// * `SwipeDetectionBehavior.continuous` - Runs callback multiple times - whenever swipe movement is above set threshold. Make sure to set threshold values higher than usual!
  /// * `SwipeDetectionBehavior.continuousDistinct` - Runs callback multiple times - whenever swipe movement is above set threshold, but only on distinct `SwipeDirection`.
  final SwipeDetectionBehavior swipeDetectionBehavior;

  /// Creates a [SimpleSwipeConfig] object.
  const SimpleSwipeConfig({
    this.verticalThreshold = 50.0,
    this.horizontalThreshold = 50.0,
    this.swipeDetectionBehavior = SwipeDetectionBehavior.singularOnEnd,
  });
}
