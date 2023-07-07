//  Copyright (c) 2019 Aleksander Woźniak
//  Licensed under Apache License v2.0

library simple_gesture_detector;

import 'package:flutter/material.dart';

class SimpleGestureDetector extends StatefulWidget {
  final Widget child;
  final SimpleSwipeConfig swipeConfig;
  final HitTestBehavior? behavior;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const SimpleGestureDetector({
    Key? key,
    required this.child,
    this.swipeConfig = const SimpleSwipeConfig(),
    this.behavior,
    this.onSwipeUp,
    this.onSwipeDown,
    this.onSwipeLeft,
    this.onSwipeRight,
  }) : super(key: key);

  @override
  _SimpleGestureDetectorState createState() => _SimpleGestureDetectorState();
}

class _SimpleGestureDetectorState extends State<SimpleGestureDetector> {
  Offset? _initialSwipeOffset;
  late Offset _finalSwipeOffset;

  void _onVerticalDragStart(DragStartDetails details) {
    _initialSwipeOffset = details.globalPosition;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    _finalSwipeOffset = details.globalPosition;

    if (widget.swipeConfig.swipeDetectionMoment ==
        SwipeDetectionMoment.onUpdate) {
      if (_initialSwipeOffset != null) {
        final offsetDifference = _initialSwipeOffset!.dy - _finalSwipeOffset.dy;

        if (offsetDifference.abs() > widget.swipeConfig.verticalThreshold) {
          _initialSwipeOffset = null;
          final isSwipeUp = offsetDifference > 0;
          if (isSwipeUp) {
            widget.onSwipeUp!();
          } else {
            widget.onSwipeDown!();
          }
        }
      }
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (widget.swipeConfig.swipeDetectionMoment ==
        SwipeDetectionMoment.onUpdate) {
      return;
    }

    if (_initialSwipeOffset != null) {
      final offsetDifference = _initialSwipeOffset!.dy - _finalSwipeOffset.dy;

      if (offsetDifference.abs() > widget.swipeConfig.verticalThreshold) {
        _initialSwipeOffset = null;
        final isSwipeUp = offsetDifference > 0;
        if (isSwipeUp) {
          widget.onSwipeUp!();
        } else {
          widget.onSwipeDown!();
        }
      }
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _initialSwipeOffset = details.globalPosition;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _finalSwipeOffset = details.globalPosition;

    if (widget.swipeConfig.swipeDetectionMoment ==
        SwipeDetectionMoment.onUpdate) {
      if (_initialSwipeOffset != null) {
        final offsetDifference = _initialSwipeOffset!.dx - _finalSwipeOffset.dx;

        if (offsetDifference.abs() > widget.swipeConfig.horizontalThreshold) {
          _initialSwipeOffset = null;
          final isSwipeLeft = offsetDifference > 0;
          if (isSwipeLeft) {
            widget.onSwipeLeft!();
          } else {
            widget.onSwipeRight!();
          }
        }
      }
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (widget.swipeConfig.swipeDetectionMoment ==
        SwipeDetectionMoment.onUpdate) {
      return;
    }

    if (_initialSwipeOffset != null) {
      final offsetDifference = _initialSwipeOffset!.dx - _finalSwipeOffset.dx;

      if (offsetDifference.abs() > widget.swipeConfig.horizontalThreshold) {
        _initialSwipeOffset = null;
        final isSwipeLeft = offsetDifference > 0;
        if (isSwipeLeft) {
          widget.onSwipeLeft!();
        } else {
          widget.onSwipeRight!();
        }
      }
    }
  }

  bool _canSwipeVertically() {
    return widget.onSwipeUp != null || widget.onSwipeDown != null;
  }

  bool _canSwipeHorizontally() {
    return widget.onSwipeLeft != null || widget.onSwipeRight != null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      child: widget.child,
      onVerticalDragStart: _canSwipeVertically() ? _onVerticalDragStart : null,
      onVerticalDragUpdate:
          _canSwipeVertically() ? _onVerticalDragUpdate : null,
      onVerticalDragEnd: _canSwipeVertically() ? _onVerticalDragEnd : null,
      onHorizontalDragStart:
          _canSwipeHorizontally() ? _onHorizontalDragStart : null,
      onHorizontalDragUpdate:
          _canSwipeHorizontally() ? _onHorizontalDragUpdate : null,
      onHorizontalDragEnd:
          _canSwipeHorizontally() ? _onHorizontalDragEnd : null,
    );
  }
}

enum SwipeDetectionMoment { onEnd, onUpdate }

class SimpleSwipeConfig {
  final double verticalThreshold;
  final double horizontalThreshold;
  final SwipeDetectionMoment swipeDetectionMoment;

  const SimpleSwipeConfig({
    this.verticalThreshold = 50.0,
    this.horizontalThreshold = 50.0,
    this.swipeDetectionMoment = SwipeDetectionMoment.onEnd,
  });
}
