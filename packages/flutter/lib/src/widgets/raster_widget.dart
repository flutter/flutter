// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'media_query.dart';

/// A widget that replaces its child with a rasterized version of the child.
///
class RasterWidget extends SingleChildRenderObjectWidget {
  /// Create a new [RasterWidget].
  const RasterWidget({
    super.key,
    required this.delegate,
    required this.rasterize,
    required super.child
  });

  /// The delegate used to draw the `ui.Image` representing the rasterized child widget.
  final RasterWidgetDelegate delegate;
  final ValueNotifier<bool> rasterize;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderRasterWidget(
      delegate: delegate,
      rasterize: rasterize,
      devicePixelRatio: MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderRasterWidget renderObject) {
    renderObject
      ..delegate = delegate
      ..rasterize = rasterize
      ..devicePixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
  }
}

/// A delegate used to draw the `ui.Image` representing the rasterized child widget.
abstract class RasterWidgetDelegate extends ChangeNotifier {
  /// Called whenever the [image] that represents a [RasterWidget]s child should be painted.
  ///
  /// The image is rasterized at the physical pixel resolution and should be scaled down by
  /// [pixelRatio] to account for device independent pixels.
  ///
  /// There is no offset given in this paint method, as the parent is an [OffsetLayer] all
  /// offsets are `Offset.zero`.
  ///
  /// Example:
  ///
  /// ```dart
  /// void paint(PaintingContext context, Rect area, ui.Image image, double pixelRatio) {
  ///   var src = Rect.fromLTWH(0, 0, image.width, image.height);
  ///   var dst = Rect.fromLTWH(0, 0, area.width, area.height);
  ///   context.canvas.drawImageRect(image, src, dst);
  /// }
  ///
  /// ```
  void paint(PaintingContext context, Rect area, ui.Image image, double pixelRatio);

  /// Called whenever a new instance of the custom painter delegate class is
  /// provided to the [RenderRasterWidget] object, or any time that a new
  /// [RasterWidgetDelegate] object is created with a new instance of the custom painter
  /// delegate class (which amounts to the same thing, because the latter is
  /// implemented in terms of the former).
  ///
  /// If the new instance represents different information than the old
  /// instance, then the method should return true, otherwise it should return
  /// false.
  ///
  /// If the method returns false, then the [paint] call might be optimized
  /// away.
  ///
  /// It's possible that the [paint] method will get called even if
  /// [shouldRepaint] returns false (e.g. if an ancestor or descendant needed to
  /// be repainted). It's also possible that the [paint] method will get called
  /// without [shouldRepaint] being called at all (e.g. if the box changes
  /// size).
  ///
  /// The `oldDelegate` argument will never be null.
  bool shouldRepaint(covariant RasterWidgetDelegate oldDelegate);
}

/// A render object that draws its child as a [ui.Image].
class RenderRasterWidget extends RenderProxyBox {
  /// Create a new [RenderRasterWidget].
  RenderRasterWidget({
    required RasterWidgetDelegate delegate,
    required double devicePixelRatio,
    required ValueNotifier<bool> rasterize,
  }) : _delegate = delegate,
       _devicePixelRatio = devicePixelRatio,
       _rasterize = rasterize {
    _currentlyRepaintBoundary = rasterize.value;
  }

  /// The device pixel ratio used to create the child raster.
  double get devicePixelRatio => _devicePixelRatio;
  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == devicePixelRatio) {
      return;
    }
    _devicePixelRatio = value;
    markNeedsPaint();
  }

  ValueNotifier<bool> get rasterize => _rasterize;
  ValueNotifier<bool> _rasterize;
  set rasterize(ValueNotifier<bool> value) {
    if (value == rasterize) {
      return;
    }
    rasterize.removeListener(_onRasterValueChanged);
    _rasterize = value;
    rasterize.addListener(_onRasterValueChanged);
  }

  /// The delegate used to draw the `ui.Image` representing the rasterized child widget.
  RasterWidgetDelegate get delegate => _delegate;
  RasterWidgetDelegate _delegate;
  set delegate(RasterWidgetDelegate value) {
    if (!value.shouldRepaint(delegate)) {
      return;
    }
    delegate.removeListener(markNeedsPaint);
    _delegate = value;
    delegate.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  ui.Image? _childRaster;
  bool _currentlyRepaintBoundary = false;

  @override
  void attach(covariant PipelineOwner owner) {
    delegate.addListener(markNeedsPaint);
    rasterize.addListener(_onRasterValueChanged);
    super.attach(owner);
  }

  @override
  void detach() {
    delegate.removeListener(markNeedsPaint);
    rasterize.removeListener(_onRasterValueChanged);
    _childRaster?.dispose();
    _childRaster = null;
    super.detach();
  }

  @override
  void dispose() {
    delegate.removeListener(markNeedsPaint);
    rasterize.removeListener(_onRasterValueChanged);
    _childRaster?.dispose();
    _childRaster = null;
    super.dispose();
  }

  void _onRasterValueChanged() {
    final bool wasRepaintBoundary = _currentlyRepaintBoundary;
    _currentlyRepaintBoundary = rasterize.value;
    if (_currentlyRepaintBoundary != wasRepaintBoundary) {
      markNeedsCompositingBitsUpdate();
    }
    markNeedsPaint();
  }

  // Paint [child] with this painting context, then convert to a raster and detach all
  // children from this layer.
  ui.Image _paintAndDetachToGpuImage() {
    final OffsetLayer offsetLayer = layer! as OffsetLayer;
    final PaintingContext context = PaintingContext(offsetLayer, Offset.zero & size);
    super.paint(context, Offset.zero);
    // ignore: invalid_use_of_protected_member
    context.stopRecordingIfNeeded();
    final ui.Image image = offsetLayer.toImageSync(Offset.zero & size, pixelRatio: devicePixelRatio);
    offsetLayer.removeAllChildren();
    return image;
  }

  @override
  bool get isRepaintBoundary => child != null && _currentlyRepaintBoundary;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (rasterize.value) {
      _childRaster ??= _paintAndDetachToGpuImage();
      delegate.paint(context, offset & size, _childRaster!, devicePixelRatio);
      return;
    }
    _childRaster?.dispose();
    _childRaster = null;
    super.paint(context, offset);
  }
}
