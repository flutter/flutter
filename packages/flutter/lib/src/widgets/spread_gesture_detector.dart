// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'scroll_controller.dart';

typedef SpreadChangeCallback = void Function(
  SpreadInsertionPoint point, {
  required bool isPastThreshold,
  required double spreadAmount,
});

typedef SpreadInsertCallback = void Function(SpreadInsertionPoint point);

typedef GetItemKeyCallback = GlobalKey Function(int index);

/// A gesture detector that recognizes spread/pinch gestures for inserting new items
/// between existing list items.
///
/// Works on both mobile (two-finger spread) and Mac (trackpad pinch gesture).
///
/// When users spread two fingers (or pinch out on trackpad) between list items,
/// this widget creates an animated gap that indicates where a new item will be
/// inserted. The gesture must exceed a threshold to trigger insertion.
class SpreadGestureDetector extends StatefulWidget {
  const SpreadGestureDetector({
    required this.child,
    required this.itemCount,
    required this.onGetItemKey,
    required this.onInsertItem,
    this.config = const SpreadConfig(),
    this.onSpreadChange,
    super.key,
  });

  /// The widget to detect spread gestures on
  final Widget child;

  /// Number of items in the list
  final int itemCount;

  /// Callback to get the GlobalKey for an item at a given index
  final GetItemKeyCallback onGetItemKey;

  /// Called when a new item should be inserted
  final SpreadInsertCallback onInsertItem;

  /// Called when the spread amount changes, for custom animations.
  /// The spreadAmount parameter represents the current spread distance.
  /// The isPastThreshold parameter indicates if the spread is past the
  /// threshold.
  final SpreadChangeCallback? onSpreadChange;

  /// Configuration for the spread gesture
  final SpreadConfig config;

  @override
  State<SpreadGestureDetector> createState() => _SpreadGestureDetectorState();
}

class _SpreadGestureDetectorState extends State<SpreadGestureDetector> {
  Map<int, Offset> _activePointers = {};
  double? _initialSpread;
  double? _initialScale;
  List<double> _itemMidpoints = [];
  double _lastSpreadAmount = 0;
  SpreadInsertionPoint? _insertionPoint;
  bool _wasPastThreshold = false;
  bool _isSpreadActive = false;

  // Spread amplification factor for mobile
  static const _spreadMultiplier = 1;

  // Spread amplification factor for Mac
  static const _scaleToSpreadMultiplier = 400.0;

  @override
  Widget build(BuildContext context) {
    // A custom pointer-based gesture detector is used on mobile for superior
    // UX. On Mac this isn't supported, so we use the "scale" gesture instead.
    return Platform.isMacOS
        ? GestureDetector(
            behavior: HitTestBehavior.translucent,
            onScaleEnd: _handleScaleEnd,
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            child: widget.child,
          )
        : Listener(
            behavior: HitTestBehavior.translucent,
            onPointerCancel: _handlePointerCancel,
            onPointerDown: _handlePointerDown,
            onPointerMove: _handlePointerMove,
            onPointerUp: _handlePointerUp,
            child: widget.child,
          );
  }

  void _captureItemPositions() {
    final midpoints = <double>[];
    for (var i = 0; i < widget.itemCount; i += 1) {
      final key = widget.onGetItemKey(i);
      final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;
        midpoints.add(position.dy + (size.height / 2));
      }
    }
    _itemMidpoints = midpoints;
  }

  SpreadInsertionPoint _calculateInsertionPoint(double coordinate) {
    if (_itemMidpoints.isEmpty) {
      return SpreadInsertionPoint(coordinate: coordinate, index: 0);
    }

    // Handle before first item
    final firstMidpoint = _itemMidpoints.firstOrNull;
    if (firstMidpoint != null && coordinate < firstMidpoint) {
      return SpreadInsertionPoint(coordinate: coordinate, index: 0);
    }

    // Handle after last item
    final lastMidpoint = _itemMidpoints.lastOrNull;
    if (lastMidpoint != null && coordinate >= lastMidpoint) {
      return SpreadInsertionPoint(
        coordinate: coordinate,
        index: widget.itemCount,
      );
    }

    // Find the gap where the coordinate falls
    for (var i = 0; i < _itemMidpoints.length - 1; i += 1) {
      final currentMidpoint = _itemMidpoints.elementAtOrNull(i);
      final nextMidpoint = _itemMidpoints.elementAtOrNull(i + 1);

      if (currentMidpoint != null &&
          nextMidpoint != null &&
          coordinate >= currentMidpoint &&
          coordinate < nextMidpoint) {
        return SpreadInsertionPoint(coordinate: coordinate, index: i + 1);
      }
    }

    return SpreadInsertionPoint(coordinate: coordinate, index: 0);
  }

  void _startSpreadGesture() {
    if (_isSpreadActive) {
      return;
    }

    _isSpreadActive = true;
    widget.config.onSpreadStart?.call();
  }

  void _handleSpreadUpdate({
    required SpreadInsertionPoint insertionPoint,
    required double spreadAmount,
  }) {
    final isPastThreshold = spreadAmount > widget.config.minSpreadThreshold;
    if (isPastThreshold != _wasPastThreshold) {
      // In vendored implementation this calls FeedbackProvider.spreadToAddThresholdCrossed()
      // but we can't have that dependency in Flutter framework
      _wasPastThreshold = isPastThreshold;
    }

    final scrollController = widget.config.scrollController;
    if (scrollController?.hasClients ?? false) {
      final deltaSpread = spreadAmount - _lastSpreadAmount;
      final newOffset = (scrollController?.offset ?? 0) + (deltaSpread / 2);
      scrollController?.jumpTo(newOffset);
    }

    _lastSpreadAmount = spreadAmount;

    if (spreadAmount > 0) {
      widget.onSpreadChange?.call(
        insertionPoint,
        spreadAmount: spreadAmount,
        isPastThreshold: isPastThreshold,
      );
    }
  }

  void _handleSpreadEnd(SpreadInsertionPoint insertionPoint) {
    if (_lastSpreadAmount > widget.config.minSpreadThreshold) {
      // In vendored implementation this calls FeedbackProvider.spreadToAddActionTriggered()
      // but we can't have that dependency in Flutter framework
      widget.onInsertItem(insertionPoint);
    } else {
      widget.onSpreadChange?.call(
        insertionPoint,
        spreadAmount: 0,
        isPastThreshold: false,
      );
    }
    _resetState();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointers = {
      ..._activePointers,
      event.pointer: event.position,
    };

    if (_activePointers.length == 2) {
      final points = _activePointers.values.toList();
      final point0 = points.firstOrNull;
      final point1 = points.elementAtOrNull(1);

      if (point0 != null && point1 != null) {
        _initialSpread = (point0.dy - point1.dy).abs();
        final midpointY = (point0.dy + point1.dy) / 2;
        _captureItemPositions();
        _insertionPoint = _calculateInsertionPoint(midpointY);
        _startSpreadGesture();
      }
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    _activePointers = {
      ..._activePointers,
      event.pointer: event.position,
    };

    if (_activePointers.length == 2 &&
        _initialSpread != null &&
        _insertionPoint != null) {
      final points = _activePointers.values.toList();
      final point0 = points.firstOrNull;
      final point1 = points.elementAtOrNull(1);

      if (point0 != null && point1 != null) {
        final initialSpread = _initialSpread;
        if (initialSpread != null) {
          final insertionPoint = _insertionPoint;
          if (insertionPoint != null) {
            final currentSpread = (point0.dy - point1.dy).abs();
            final rawSpreadAmount = currentSpread - initialSpread;
            final spreadAmount = (rawSpreadAmount * _spreadMultiplier)
                .clamp(0.0, widget.config.maxGapHeight);
            _handleSpreadUpdate(
              insertionPoint: insertionPoint,
              spreadAmount: spreadAmount,
            );
          }
        }
      }
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _activePointers = Map.fromEntries(
      _activePointers.entries.where((e) => e.key != event.pointer),
    );
    final currentInsertionPoint = _insertionPoint;
    if (_activePointers.isEmpty && currentInsertionPoint != null) {
      _handleSpreadEnd(currentInsertionPoint);
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    final oldValue = _activePointers[event.pointer];
    _activePointers = Map.fromEntries(
      _activePointers.entries.where((e) => e.key != event.pointer),
    );
    final currentInsertionPoint = _insertionPoint;
    if (oldValue != null &&
        _activePointers.isEmpty &&
        currentInsertionPoint != null) {
      _handleSpreadEnd(currentInsertionPoint);
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (!Platform.isMacOS) {
      return;
    }

    final renderBox = context.findRenderObject();
    if (renderBox is! RenderBox) {
      return;
    }

    final globalPosition = renderBox.localToGlobal(details.localFocalPoint);

    _initialScale = 1.0;
    _captureItemPositions();
    _insertionPoint = _calculateInsertionPoint(globalPosition.dy);
    _startSpreadGesture();
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (!Platform.isMacOS || _initialScale == null || _insertionPoint == null) {
      return;
    }

    final initialScale = _initialScale;
    final insertionPoint = _insertionPoint;
    if (initialScale == null || insertionPoint == null) {
      return;
    }

    final scaleDelta =
        (details.scale - initialScale) * _scaleToSpreadMultiplier;
    final spreadAmount = scaleDelta.clamp(0.0, widget.config.maxGapHeight);

    _handleSpreadUpdate(
      insertionPoint: insertionPoint,
      spreadAmount: spreadAmount,
    );
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (!Platform.isMacOS) {
      return;
    }

    final currentInsertionPoint = _insertionPoint;
    if (currentInsertionPoint != null) {
      _handleSpreadEnd(currentInsertionPoint);
    }
  }

  void _resetState() {
    if (_isSpreadActive) {
      _isSpreadActive = false;
      widget.config.onSpreadEnd?.call();
      if (_lastSpreadAmount <= widget.config.minSpreadThreshold) {
        widget.config.onSpreadCancelled?.call();
      }
    }
    _activePointers = {};
    _initialSpread = null;
    _initialScale = null;
    _lastSpreadAmount = 0;
    _itemMidpoints = [];
    _insertionPoint = null;
    _wasPastThreshold = false;
  }
}

/// Configuration for the spread gesture animation and behavior
class SpreadConfig {
  const SpreadConfig({
    this.maxGapHeight = 200.0,
    this.minSpreadThreshold = 100.0,
    this.onSpreadCancelled,
    this.onSpreadEnd,
    this.onSpreadStart,
    this.scrollController,
  });

  final double minSpreadThreshold;
  final double maxGapHeight;
  final ScrollController? scrollController;
  final VoidCallback? onSpreadStart;
  final VoidCallback? onSpreadEnd;

  /// Called when spread is cancelled (released before threshold)
  final VoidCallback? onSpreadCancelled;
}

/// Data about where to insert a new item
class SpreadInsertionPoint {
  const SpreadInsertionPoint({
    required this.coordinate,
    required this.index,
  });

  final int index;
  final double coordinate;
}
