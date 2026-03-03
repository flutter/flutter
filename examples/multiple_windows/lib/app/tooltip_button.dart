// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'models.dart';

/// Manages all [_ElementPositionTracker] instances.
///
/// This class is a singleton because it needs to hook into the global frame
/// callbacks to update all registered trackers. This callback may only be
/// registered once, so we use a singleton to ensure that.
class _ElementPositionTrackerManager {
  _ElementPositionTrackerManager._() {
    WidgetsBinding.instance.addPersistentFrameCallback((_) {
      final trackersCopy = List<_ElementPositionTracker>.from(
        _trackers,
        growable: false,
      );
      for (final tracker in trackersCopy) {
        tracker._updateSelf();
      }
    });
  }

  static final _instance = _ElementPositionTrackerManager._();
  static _ElementPositionTrackerManager get instance => _instance;
  final List<_ElementPositionTracker> _trackers = <_ElementPositionTracker>[];

  void add(_ElementPositionTracker tracker) {
    _trackers.add(tracker);
  }

  void remove(_ElementPositionTracker tracker) {
    _trackers.remove(tracker);
  }
}

/// Tracks global rect of an [Element].
class _ElementPositionTracker {
  _ElementPositionTracker({required this.element});

  final BuildContext element;
  Rect? _lastReportedRect;

  /// Returns current global rect for tracked element or `null` if not available.
  Rect? getGlobalRect() {
    final rect = _getGlobalRect();
    _lastReportedRect = rect;
    return rect;
  }

  /// Callback invoked every time the global position of the tracked element changes
  /// compared to last result of [getGlobalRect].
  void Function(Rect rect)? onGlobalRectChange;

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
      _ElementPositionTrackerManager.instance.remove(this);
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
  _ElementPositionTracker? _tooltipTracker;
  final GlobalKey _tooltipButtonKey = GlobalKey();

  @override
  void dispose() {
    if (_tooltipTracker != null) {
      _ElementPositionTrackerManager.instance.remove(_tooltipTracker!);
    }
    super.dispose();
  }

  void _onPressed(
    final WindowManager windowManager,
    final WindowSettings windowSettings,
  ) {
    // Toggle tooltip visibility.
    if (_tooltipController != null) {
      _tooltipController!.destroy();
      if (_tooltipTracker != null) {
        _ElementPositionTrackerManager.instance.remove(_tooltipTracker!);
      }
      setState(() {
        _tooltipController = null;
        _tooltipTracker = null;
      });
    } else {
      // Tooltip is not shown, show it.
      final tracker = _ElementPositionTracker(
        element: _tooltipButtonKey.currentContext!,
      );
      _ElementPositionTrackerManager.instance.add(tracker);
      final UniqueKey key = UniqueKey();
      final controller = TooltipWindowController(
        anchorRect: tracker.getGlobalRect()!,
        positioner: windowSettings.positioner,
        delegate: _TooltipWindowControllerDelegate(
          onDestroyed: () {
            windowManager.remove(key);
            _ElementPositionTrackerManager.instance.remove(tracker);
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
      tracker.onGlobalRectChange = (rect) {
        controller.updatePosition(anchorRect: rect);
      };
      windowManager.add(KeyedWindow(key: key, controller: controller));
      setState(() {
        _tooltipController = controller;
        _tooltipTracker = tracker;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final WindowManager windowManager = WindowManagerAccessor.of(context);
    final WindowSettings windowSettings = WindowSettingsAccessor.of(context);

    return OutlinedButton(
      key: _tooltipButtonKey,
      onPressed: () => _onPressed(windowManager, windowSettings),
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
