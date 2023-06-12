// Copyright 2018 the Dart project authors.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd

import 'dart:async' show Timer;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'visibility_detector.dart';
import 'visibility_detector_controller.dart';

/// Returns a sequence containing the specified [Layer] and all of its
/// ancestors.  The returned sequence is in [parent, child] order.
Iterable<Layer> _getLayerChain(Layer start) {
  final layerChain = <Layer>[];
  for (Layer? layer = start; layer != null; layer = layer.parent) {
    layerChain.add(layer);
  }
  return layerChain.reversed;
}

/// Returns the accumulated transform from the specified sequence of [Layer]s.
/// The sequence must be in [parent, child] order.  The sequence must not be
/// null.
Matrix4 _accumulateTransforms(Iterable<Layer> layerChain) {
  assert(layerChain != null);

  final transform = Matrix4.identity();
  if (layerChain.isNotEmpty) {
    var parent = layerChain.first;
    for (final child in layerChain.skip(1)) {
      (parent as ContainerLayer).applyTransform(child, transform);
      parent = child;
    }
  }
  return transform;
}

/// Converts a [Rect] in local coordinates of the specified [Layer] to a new
/// [Rect] in global coordinates.
Rect _localRectToGlobal(Layer layer, Rect localRect) {
  final layerChain = _getLayerChain(layer);

  // Skip the root layer which transforms from logical pixels to physical
  // device pixels.
  assert(layerChain.isNotEmpty);
  assert(layerChain.first is TransformLayer);
  final transform = _accumulateTransforms(layerChain.skip(1));
  return MatrixUtils.transformRect(transform, localRect);
}

/// The [Layer] corresponding to a [VisibilityDetector] widget.
///
/// We use a [Layer] because we can directly determine visibility by virtue of
/// being added to the [SceneBuilder].
class VisibilityDetectorLayer extends ContainerLayer {
  /// Constructor.  See the corresponding properties for parameter details.
  VisibilityDetectorLayer(
      {required this.key,
      required this.widgetOffset,
      required this.widgetSize,
      required this.paintOffset,
      required this.onVisibilityChanged})
      : assert(key != null),
        assert(paintOffset != null),
        assert(widgetSize != null),
        assert(onVisibilityChanged != null);

  /// Timer used by [_scheduleUpdate].
  static Timer? _timer;

  /// Keeps track of [VisibilityDetectorLayer] objects that have been recently
  /// updated and that might need to report visibility changes.
  ///
  /// Additionally maps [VisibilityDetector] keys to the most recently added
  /// [VisibilityDetectorLayer] that corresponds to it; this mapping is
  /// necessary in case a layout change causes a new layer to be instantiated
  /// for an existing key.
  static final _updated = <Key, VisibilityDetectorLayer>{};

  /// Keeps track of the last known visibility state of a [VisibilityDetector].
  ///
  /// This is used to suppress extraneous callbacks when visibility hasn't
  /// changed.  Stores entries only for visible [VisibilityDetector] objects;
  /// entries for non-visible ones are actively removed.  See [_fireCallback].
  static final _lastVisibility = <Key, VisibilityInfo>{};

  /// Keeps track of the last known bounds of a [VisibilityDetector], in global
  /// coordinates.
  static Map<Key, Rect> get widgetBounds => _lastBounds;
  static final _lastBounds = <Key, Rect>{};

  /// The key for the corresponding [VisibilityDetector] widget.
  final Key key;

  /// Offset to the start of the widget, in local coordinates.
  ///
  /// This is zero for box widgets. For sliver widget, this offset points to
  /// the start of the widget which may be outside the viewport.
  final Offset widgetOffset;

  /// The size of the corresponding [VisibilityDetector] widget.
  final Size widgetSize;

  /// The offset supplied to [RenderVisibilityDetector.paint] method.
  final Offset paintOffset;

  /// See [VisibilityDetector.onVisibilityChanged].
  ///
  /// Do not invoke this directly; call [_fireCallback] instead.
  final VisibilityChangedCallback onVisibilityChanged;

  /// Computes the bounds for the corresponding [VisibilityDetector] widget, in
  /// global coordinates.
  Rect _computeWidgetBounds() {
    return _localRectToGlobal(this, paintOffset + widgetOffset & widgetSize);
  }

  /// Computes the accumulated clipping bounds, in global coordinates.
  Rect _computeClipRect() {
    assert(RendererBinding.instance.renderView != null);
    var clipRect = Offset.zero & RendererBinding.instance.renderView.size;

    var parentLayer = parent;
    while (parentLayer != null) {
      Rect? curClipRect;
      if (parentLayer is ClipRectLayer) {
        curClipRect = parentLayer.clipRect;
      } else if (parentLayer is ClipRRectLayer) {
        curClipRect = parentLayer.clipRRect!.outerRect;
      } else if (parentLayer is ClipPathLayer) {
        curClipRect = parentLayer.clipPath!.getBounds();
      }

      if (curClipRect != null) {
        // This is O(n^2) WRT the depth of the tree since `_localRectToGlobal`
        // also walks up the tree.  In practice there probably will be a small
        // number of clipping layers in the chain, so it might not be a problem.
        // Alternatively we could cache transformations and clipping rectangles.
        curClipRect = _localRectToGlobal(parentLayer, curClipRect);
        clipRect = clipRect.intersect(curClipRect);
      }

      parentLayer = parentLayer.parent;
    }

    return clipRect;
  }

  /// Schedules a timer to invoke the visibility callbacks.  The timer is used
  /// to throttle and coalesce updates.
  void _scheduleUpdate() {
    final isFirstUpdate = _updated.isEmpty;
    _updated[key] = this;

    final updateInterval = VisibilityDetectorController.instance.updateInterval;
    if (updateInterval == Duration.zero) {
      // Even with [Duration.zero], we still want to defer callbacks to the end
      // of the frame so that they're processed from a consistent state.  This
      // also ensures that they don't mutate the widget tree while we're in the
      // middle of a frame.
      if (isFirstUpdate) {
        // We're about to render a frame, so a post-frame callback is guaranteed
        // to fire and will give us the better immediacy than `scheduleTask<T>`.
        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          _processCallbacks();
        });
      }
    } else if (_timer == null) {
      // We use a normal [Timer] instead of a [RestartableTimer] so that changes
      // to the update duration will be picked up automatically.
      _timer = Timer(updateInterval, _handleTimer);
    } else {
      assert(_timer!.isActive);
    }
  }

  /// [Timer] callback.  Defers visibility callbacks to execute after the next
  /// frame.
  static void _handleTimer() {
    _timer = null;

    // Ensure that work is done between frames so that calculations are
    // performed from a consistent state.  We use `scheduleTask<T>` here instead
    // of `addPostFrameCallback` or `scheduleFrameCallback` so that work will
    // be done even if a new frame isn't scheduled and without unnecessarily
    // scheduling a new frame.
    SchedulerBinding.instance
        .scheduleTask<void>(_processCallbacks, Priority.touch);
  }

  /// See [VisibilityDetectorController.notifyNow].
  static void notifyNow() {
    _timer?.cancel();
    _timer = null;
    _processCallbacks();
  }

  /// Removes entries corresponding to the specified [Key] from our internal
  /// caches.
  static void forget(Key key) {
    _updated.remove(key);
    _lastVisibility.remove(key);
    _lastBounds.remove(key);

    if (_updated.isEmpty) {
      _timer?.cancel();
      _timer = null;
    }
  }

  /// Executes visibility callbacks for all updated [VisibilityDetectorLayer]
  /// instances.
  static void _processCallbacks() {
    for (final layer in _updated.values) {
      if (!layer.attached) {
        layer._fireCallback(VisibilityInfo(
            key: layer.key, size: _lastVisibility[layer.key]?.size));
        continue;
      }

      final widgetBounds = layer._computeWidgetBounds();
      _lastBounds[layer.key] = widgetBounds;

      final info = VisibilityInfo.fromRects(
          key: layer.key,
          widgetBounds: widgetBounds,
          clipRect: layer._computeClipRect());
      layer._fireCallback(info);
    }
    _updated.clear();
  }

  /// Invokes the visibility callback if [VisibilityInfo] hasn't meaningfully
  /// changed since the last time we invoked it.
  void _fireCallback(VisibilityInfo info) {
    assert(info != null);

    final oldInfo = _lastVisibility[key];
    final visible = !info.visibleBounds.isEmpty;

    if (oldInfo == null) {
      if (!visible) {
        return;
      }
    } else if (info.matchesVisibility(oldInfo)) {
      return;
    }

    if (visible) {
      _lastVisibility[key] = info;
    } else {
      // Track only visible items so that the maps don't grow unbounded.
      _lastVisibility.remove(key);
      _lastBounds.remove(key);
    }

    onVisibilityChanged(info);
  }

  /// See [Layer.addToScene].
  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    // TODO(goderbauer): Remove unused layerOffset parameter once
    //     https://github.com/flutter/flutter/pull/91753 is in stable.
    assert(layerOffset == Offset.zero);
    _scheduleUpdate();
    super.addToScene(builder);
  }

  /// See [AbstractNode.attach].
  @override
  void attach(Object owner) {
    super.attach(owner);
    _scheduleUpdate();
  }

  /// See [AbstractNode.detach].
  @override
  void detach() {
    super.detach();

    // The Layer might no longer be visible.  We'll figure out whether it gets
    // re-attached later.
    _scheduleUpdate();
  }

  /// See [Diagnosticable.debugFillProperties].
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties
      ..add(DiagnosticsProperty<Key>('key', key))
      ..add(DiagnosticsProperty<Rect>('widgetRect', _computeWidgetBounds()))
      ..add(DiagnosticsProperty<Rect>('clipRect', _computeClipRect()));
  }
}
