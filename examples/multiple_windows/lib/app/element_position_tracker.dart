// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Tracks the global rect of an [Element].
class ElementPositionTracker {
  ElementPositionTracker({required this.element}) {
    _ElementPositionTrackerManager.instance.add(this);
  }

  void dispose() {
    _ElementPositionTrackerManager.instance.remove(this);
  }

  /// Returns current global rect for the tracked element, or `null` if not available.
  Rect? getGlobalRect() {
    final Rect? rect = _getGlobalRect();
    _lastReportedRect = rect;
    return rect;
  }

  /// Callback invoked every time the global position of the tracked element changes
  /// compared to last result of [getGlobalRect].
  void Function(Rect rect)? onGlobalRectChange;

  final BuildContext element;
  Rect? _lastReportedRect;

  Rect? _getGlobalRect() {
    if (!element.mounted) {
      return null;
    }
    final RenderObject? renderBox = element.findRenderObject();
    if (renderBox is! RenderBox) {
      return null;
    }

    final Matrix4 transform = renderBox.getTransformTo(null);
    final Rect rect = Offset.zero & renderBox.size;
    final Rect globalRect = MatrixUtils.transformRect(transform, rect);
    return globalRect;
  }

  void _updateSelf() {
    final Rect? rect = _getGlobalRect();
    if (rect == null) {
      _ElementPositionTrackerManager.instance.remove(this);
      return;
    }
    if (_lastReportedRect != rect) {
      _lastReportedRect = rect;
      onGlobalRectChange?.call(rect);
    }
  }
}

/// Manages all [ElementPositionTracker] instances.
///
/// This class is a singleton because it needs to hook into the global frame
/// callbacks to update all registered trackers. This callback may only be
/// registered once, so we use a singleton to ensure that.
class _ElementPositionTrackerManager {
  _ElementPositionTrackerManager._() {
    WidgetsBinding.instance.addPersistentFrameCallback((_) {
      final trackersCopy = List<ElementPositionTracker>.from(_trackers, growable: false);
      for (final tracker in trackersCopy) {
        tracker._updateSelf();
      }
    });
  }

  static final _instance = _ElementPositionTrackerManager._();
  static _ElementPositionTrackerManager get instance => _instance;
  final List<ElementPositionTracker> _trackers = <ElementPositionTracker>[];

  void add(ElementPositionTracker tracker) {
    _trackers.add(tracker);
  }

  void remove(ElementPositionTracker tracker) {
    _trackers.remove(tracker);
  }
}
