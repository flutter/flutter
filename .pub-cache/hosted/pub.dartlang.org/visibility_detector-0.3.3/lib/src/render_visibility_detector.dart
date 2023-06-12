// Copyright 2018 the Dart project authors.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'visibility_detector.dart';
import 'visibility_detector_layer.dart';

/// The [RenderObject] corresponding to the [VisibilityDetector] widget.
///
/// [RenderVisibilityDetector] is a bridge between [VisibilityDetector] and
/// [VisibilityDetectorLayer].
class RenderVisibilityDetector extends RenderProxyBox {
  /// Constructor.  See the corresponding properties for parameter details.
  RenderVisibilityDetector({
    RenderBox? child,
    required this.key,
    required VisibilityChangedCallback? onVisibilityChanged,
  })  : assert(key != null),
        _onVisibilityChanged = onVisibilityChanged,
        super(child);

  /// The key for the corresponding [VisibilityDetector] widget.
  final Key key;

  VisibilityChangedCallback? _onVisibilityChanged;

  /// See [VisibilityDetector.onVisibilityChanged].
  VisibilityChangedCallback? get onVisibilityChanged => _onVisibilityChanged;

  /// Used by [VisibilityDetector.updateRenderObject].
  set onVisibilityChanged(VisibilityChangedCallback? value) {
    _onVisibilityChanged = value;
    markNeedsCompositingBitsUpdate();
    markNeedsPaint();
  }

  // See [RenderObject.alwaysNeedsCompositing].
  @override
  bool get alwaysNeedsCompositing => onVisibilityChanged != null;

  /// See [RenderObject.paint].
  @override
  void paint(PaintingContext context, Offset offset) {
    if (onVisibilityChanged == null) {
      // No need to create a [VisibilityDetectorLayer].  However, in case one
      // already exists, remove all cached data for it so that we won't fire
      // visibility callbacks when the layer is removed.
      VisibilityDetectorLayer.forget(key);
      super.paint(context, offset);
      return;
    }

    final layer = VisibilityDetectorLayer(
        key: key,
        widgetOffset: Offset.zero,
        widgetSize: semanticBounds.size,
        paintOffset: offset,
        onVisibilityChanged: onVisibilityChanged!);
    context.pushLayer(layer, super.paint, offset);
  }
}
