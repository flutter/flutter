// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'media_query.dart';

/// Controls how the [SnapshotWidget] paints its child via the [SnapshotWidgetController].
enum SnapshotMode {
  /// the child is snapshotted, but only if all descendants can be snapshotted.
  ///
  /// This setting is the default state of the [SnapshotWidgetController].
  ///
  /// If there is a platform view in the children of a raster widget, the
  /// snapshot will not be used and the child will be rendered as normal.
  permissive,

  /// The child is snapshotted and any child platform views are ignored.
  ///
  /// In this state a [RasterWidgetFallbackDelegate] is never used. Generally this
  /// can be useful if there is a platform view descendant that does not need to
  /// be included in the raster.
  forced,
}

/// A controller for the [SnapshotWidget] that controls when the child image is displayed
/// and when to regenerated the child image.
///
/// When the value of [enabled] is true, the [SnapshotWidget] will paint the child
/// widgets based on the [SnapshotMode] of the raster widget.
///
/// To force [SnapshotWidget] to recreate the child image, call [clear].
class SnapshotWidgetController extends ChangeNotifier {
  /// Create a new [SnapshotWidgetController].
  ///
  /// By default, [enabled] is `false` and cannot be `null`.
  SnapshotWidgetController({
    bool enabled = false,
  }) : _enabled = enabled;

  /// Reset the snapshot held by any listening [SnapshotWidget].
  ///
  /// This has no effect if [enabled] is `false`.
  void clear() {
    notifyListeners();
  }

  /// Whether a snapshot of this child widget is drawn in its place.
  bool get enabled => _enabled;
  bool _enabled;
  set enabled(bool value) {
    if (value == enabled) {
      return;
    }
    _enabled = value;
    notifyListeners();
  }
}

/// A widget that replaces its child with a rasterized version of the child.
///
/// By default, the child is drawn as is. The default [delegate] simply scales
/// down the image by the current device pixel ratio and paints it into the
/// canvas. How this image is drawn can be customized by providing a new
/// subclass of [RasterWidgetDelegate] to the [delegate] argument.
///
/// Caveats:
///
/// The contents of platform views cannot be captured by a raster
/// widget. If a platform view is encountered, then the raster widget will
/// determine how to render its children based on the [SnapshotMode]. This
/// defaults to [SnapshotMode.enabled] which will throw an exception if a platform
/// view is encountered.
///
/// This widget is not supported on the HTML backend of Flutter for the web.
class SnapshotWidget extends SingleChildRenderObjectWidget {
  /// Create a new [SnapshotWidget].
  ///
  /// The [controller] and [child] arguments are required.
  const SnapshotWidget({
    super.key,
    this.mode = SnapshotMode.permissive,
    required this.controller,
    required super.child
  });

  /// The controller that determines when to display the children as an image.
  final SnapshotWidgetController controller;

  /// Configuration that controls how the raster widget decides to draw its children.
  ///
  /// Defaults to [SnapshotMode.enabled], which throws an error when a platform view
  /// or other un-rasterizable view is encountered.
  ///
  /// See [SnapshotMode] for more information.
  final SnapshotMode mode;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSnapshotWidget(
      controller: controller,
      mode: mode,
      devicePixelRatio: MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderSnapshotWidget renderObject) {
    renderObject
      ..controller = controller
      ..mode = mode
      ..devicePixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
  }
}

/// A render object that draws its child as a [ui.Image].
class RenderSnapshotWidget extends RenderProxyBox {
  /// Create a new [RenderSnapshotWidget].
  RenderSnapshotWidget({
    required double devicePixelRatio,
    required SnapshotWidgetController controller,
    required SnapshotMode mode,
  }) : _devicePixelRatio = devicePixelRatio,
       _controller = controller,
       _mode = mode;

  /// The device pixel ratio used to create the child image.
  double get devicePixelRatio => _devicePixelRatio;
  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == devicePixelRatio) {
      return;
    }
    _devicePixelRatio = value;
    markNeedsPaint();
  }

  /// Whether a rasterized version of this render objects child is drawn in
  /// place of the child.
  SnapshotWidgetController get controller => _controller;
  SnapshotWidgetController _controller;
  set controller(SnapshotWidgetController value) {
    if (value == controller) {
      return;
    }
    controller.removeListener(_onRasterValueChanged);
    final bool oldValue = controller.enabled;
    _controller = value;
    if (attached) {
      controller.addListener(_onRasterValueChanged);
      if (oldValue != controller.enabled) {
        _onRasterValueChanged();
      }
    }
  }

  /// How the raster widget will handle platform views in child layers.
  SnapshotMode get mode => _mode;
  SnapshotMode _mode;
  set mode(SnapshotMode value) {
    if (value == _mode) {
      return;
    }
    _mode = value;
    markNeedsPaint();
  }

  ui.Image? _childRaster;

  @override
  void attach(covariant PipelineOwner owner) {
    controller.addListener(_onRasterValueChanged);
    super.attach(owner);
  }

  @override
  void detach() {
    controller.removeListener(_onRasterValueChanged);
    _childRaster?.dispose();
    _childRaster = null;
    super.detach();
  }

  @override
  void dispose() {
    controller.removeListener(_onRasterValueChanged);
    _childRaster?.dispose();
    _childRaster = null;
    super.dispose();
  }

  void _onRasterValueChanged() {
    _childRaster?.dispose();
    _childRaster = null;
    markNeedsPaint();
  }

  // Paint [child] with this painting context, then convert to a raster and detach all
  // children from this layer.
  ui.Image? _paintAndDetachToImage() {
    final OffsetLayer offsetLayer = OffsetLayer();
    final PaintingContext context = PaintingContext(offsetLayer, Offset.zero & size);
    super.paint(context, Offset.zero);
    // This ignore is here because this method is protected by the `PaintingContext`. Adding a new
    // method that performs the work of `_paintAndDetachToImage` would avoid the need for this, but
    // that would conflict with our goals of minimizing painting context.
    // ignore: invalid_use_of_protected_member
    context.stopRecordingIfNeeded();
    if (mode != SnapshotMode.forced && !offsetLayer.supportsRasterization()) {
      return null;
    }
    final ui.Image image = offsetLayer.toImageSync(Offset.zero & size, pixelRatio: devicePixelRatio);
    offsetLayer.dispose();
    return image;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (size.isEmpty) {
      _childRaster?.dispose();
      _childRaster = null;
      return;
    }
    if (controller.enabled) {
      _childRaster ??= _paintAndDetachToImage();
      if (_childRaster == null) {
        super.paint(context, offset);
      } else {
        _paintRaster(context, offset, size, _childRaster!, devicePixelRatio);
      }
      return;
    }
    _childRaster?.dispose();
    _childRaster = null;
    super.paint(context, offset);
  }

  void _paintRaster(PaintingContext context, Offset offset, Size size, ui.Image image, double pixelRatio) {
    final Rect src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final Rect dst = Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
    final Paint paint = Paint()
      ..filterQuality = FilterQuality.low;
    context.canvas.drawImageRect(image, src, dst, paint);
  }
}
