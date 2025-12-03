// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'models.dart';

/// Tracks global rect of an [Element].
class ElementPositionTracker {
  ElementPositionTracker(this.element) {
    _register(this);
  }

  final BuildContext element;

  /// Returns current global rect for tracked element or `null` if not available.
  Rect? getGlobalRect() {
    final rect = _getGlobalRect();
    _lastReportedRect = rect;
    return rect;
  }

  /// Disposes this tracker causing it to stop providing updates. The tracker is
  /// automatically disposed when tracked element is unmounted.
  void dispose() {
    _unregister(this);
  }

  /// Callback invoked every time the global position of the tracked element changes
  /// compared to last result of [getGlobalRect].
  void Function(Rect rect)? onGlobalRectChange;

  static bool _persistentCallbackRegistered = false;
  static final _trackers = <ElementPositionTracker>[];

  static void _register(ElementPositionTracker tracker) {
    if (!_persistentCallbackRegistered) {
      _persistentCallbackRegistered = true;
      WidgetsBinding.instance.addPersistentFrameCallback((_) {
        _update();
      });
    }
    _trackers.add(tracker);
  }

  static void _unregister(ElementPositionTracker tracker) {
    _trackers.remove(tracker);
  }

  static void _update() {
    final trackersCopy = List<ElementPositionTracker>.from(
      _trackers,
      growable: false,
    );
    for (final tracker in trackersCopy) {
      tracker._updateSelf();
    }
  }

  Rect? _lastReportedRect;

  Rect? _getGlobalRect() {
    if (!element.mounted) {
      return null;
    }
    final renderBox = element.findRenderObject();
    if (renderBox is! RenderBox) {
      return null;
    }
    final transform = renderBox.getTransformTo(null);
    final rect = Offset.zero & renderBox.size;
    final globalRect = MatrixUtils.transformRect(transform, rect);
    return globalRect;
  }

  void _updateSelf() {
    final rect = _getGlobalRect();
    if (rect == null) {
      _unregister(this);
      return;
    }
    if (_lastReportedRect != rect) {
      _lastReportedRect = rect;
    }
    onGlobalRectChange?.call(rect);
  }
}

class TooltipButton extends StatefulWidget {
  const TooltipButton({super.key, required this.parentController});

  final BaseWindowController parentController;

  @override
  State<TooltipButton> createState() => _TooltipButtonState();
}

class _TooltipButtonState extends State<TooltipButton> {
  TooltipWindowController? _tooltipController;
  ElementPositionTracker? _tooltipTracker;
  final GlobalKey _tooltipButtonKey = GlobalKey();

  @override
  void dispose() {
    _tooltipTracker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WindowManager windowManager = WindowManagerAccessor.of(context);
    final WindowSettings windowSettings = WindowSettingsAccessor.of(context);

    return OutlinedButton(
      key: _tooltipButtonKey,
      onPressed: () {
        if (_tooltipController != null) {
          _tooltipController!.destroy();
          _tooltipTracker?.dispose();
          setState(() {
            _tooltipController = null;
            _tooltipTracker = null;
          });
        } else {
          // Tooltip is not shown, show it
          final tracker = ElementPositionTracker(
            _tooltipButtonKey.currentContext!,
          );
          final UniqueKey key = UniqueKey();
          final controller = TooltipWindowController(
            anchorRect: tracker.getGlobalRect()!,
            positioner: windowSettings.positioner,
            delegate: _TooltipWindowControllerDelegate(
              onDestroyed: () {
                windowManager.remove(key);
                tracker.dispose();
                if (mounted) {
                  setState(() {
                    _tooltipController = null;
                    _tooltipTracker = null;
                  });
                }
              },
            ),
            parent: widget.parentController,
          );
          if (windowSettings.tooltipTrackPosition) {
            tracker.onGlobalRectChange = (rect) {
              controller.updatePosition(anchorRect: rect);
            };
          }
          windowManager.add(KeyedWindow(key: key, controller: controller));
          setState(() {
            _tooltipController = controller;
            _tooltipTracker = tracker;
          });
        }
      },
      child: Text(_tooltipController != null ? 'Hide Tooltip' : 'Show Tooltip'),
    );
  }
}

class _TooltipWindowControllerDelegate extends TooltipWindowControllerDelegate {
  _TooltipWindowControllerDelegate({required this.onDestroyed});

  @override
  void onWindowDestroyed() {
    onDestroyed();
    super.onWindowDestroyed();
  }

  final VoidCallback onDestroyed;
}
