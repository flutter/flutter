// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';

import 'window_content.dart';
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

class PopupButton extends StatefulWidget {
  const PopupButton({super.key, required this.parentController});

  final BaseWindowController parentController;

  @override
  State<PopupButton> createState() => _PopupButtonState();
}

class _PopupButtonState extends State<PopupButton> {
  PopupWindowController? _popupController;
  _ElementPositionTracker? _popupTracker;
  final GlobalKey _popupButtonKey = GlobalKey();

  @override
  void dispose() {
    if (_popupTracker != null) {
      _ElementPositionTrackerManager.instance.remove(_popupTracker!);
    }
    super.dispose();
  }

  void _onPressed(
    final KeyedWindowManager windowManager,
    final WindowSettings windowSettings,
  ) {
    // Toggle popup visibility.
    if (_popupController != null) {
      _popupController!.destroy();
      if (_popupTracker != null) {
        _ElementPositionTrackerManager.instance.remove(_popupTracker!);
      }
      setState(() {
        _popupWindow = null;
        _popupController = null;
        _popupTracker = null;
      });
    } else {
      // Popup is not shown, show it.
      final tracker = _ElementPositionTracker(
        element: _popupButtonKey.currentContext!,
      );
      _ElementPositionTrackerManager.instance.add(tracker);
      final UniqueKey key = UniqueKey();
      final controller = PopupWindowController(
        anchorRect: tracker.getGlobalRect()!,
        positioner: windowSettings.positioner,
        delegate: _PopupWindowControllerDelegate(
          onDestroyed: () {
            windowManager.remove(key);
            _ElementPositionTrackerManager.instance.remove(tracker);
            if (mounted) {
              setState(() {
                _popupController = null;
                _popupTracker = null;
              });
            }
          },
        ),
        parent: widget.parentController,
      );
      tracker.onGlobalRectChange = (rect) {
        controller.updatePosition(anchorRect: rect);
      };
      setState(() {
        _popupWindow = WindowContent(
          windowKey: _windowKey,
          controller: controller,
          onDestroyed: () {},
          onError: () {},
        );
        _popupController = controller;
        _popupTracker = tracker;
      });
    }
  }

  final _windowKey = GlobalKey();
  final _viewAnchorKey = GlobalKey();
  Widget? _popupWindow;

  @override
  Widget build(BuildContext context) {
    final KeyedWindowManager windowManager = KeyedWindowManagerAccessor.of(
      context,
    );
    final WindowSettings windowSettings = WindowSettingsAccessor.of(context);

    return ViewAnchor(
      key: _viewAnchorKey,
      view: _popupWindow,
      child: OutlinedButton(
        key: _popupButtonKey,
        onPressed: () => _onPressed(windowManager, windowSettings),
        child: Text(_popupController != null ? 'Hide Popup' : 'Show Popup'),
      ),
    );
  }
}

class _PopupWindowControllerDelegate extends PopupWindowControllerDelegate {
  _PopupWindowControllerDelegate({required this.onDestroyed});

  @override
  void onWindowDestroyed() {
    onDestroyed();
    super.onWindowDestroyed();
  }

  final VoidCallback onDestroyed;
}
