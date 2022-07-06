// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'media_query.dart';

/// Whether or not the application is currently using a hardware accelerated
/// backend.
bool isHardwareAccelerated() {
  final ui.SceneBuilder builder = ui.SceneBuilder();
  final ui.Scene scene = builder.build();
  late ui.Image image;
  try {
    image = scene.toGpuImage(1, 1);
  } on UnsupportedError {
    // Flutter Web HTML backend.
    return false;
  }
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);
  try {
    canvas.drawImage(image, Offset.zero, Paint());
  } on ui.PictureRasterizationException {
    // Software rendering backend on iOS, flutter_tester, or Android software rendering.
    return false;
  }
  image.dispose();
  return true;
}

/// A widget that replaces its child with a rasterized version of the child.
///
/// Not all backends support this rendering strategy, specifically the html backend of
/// flutter on the web, android emulators with --enable-software-rendering, and iOS
/// while backgrounded. If this widget is used in these cases, it will simply paint its
/// child as is. Whether or not this widget is supported can be detected at runtime with
/// [isHardwareAccelerated].
class RasterWidget extends SingleChildRenderObjectWidget {
  /// Create a new [RasterWidget].
  const RasterWidget({
    super.key,
    required this.delegate,
    super.child
  });

  /// The delegate used to draw the `ui.Image` representing the rasterized child widget.
  final RasterWidgetDelegate delegate;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderRasterWidget(
      delegate,
      MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderRasterWidget renderObject) {
    renderObject
      ..delegate = delegate
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
  RenderRasterWidget(this._delegate, this._devicePixelRatio);

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

  @override
  void attach(covariant PipelineOwner owner) {
    delegate.addListener(markNeedsPaint);
    super.attach(owner);
  }

  @override
  void detach() {
    delegate.removeListener(markNeedsPaint);
    _childRaster?.dispose();
    _childRaster = null;
    super.detach();
  }

  @override
  void dispose() {
    delegate.removeListener(markNeedsPaint);
    _childRaster?.dispose();
    _childRaster = null;
    super.dispose();
  }

  // Paint [child] with this painting context, then convert to a raster and detach all
  // children from this layer.
  ui.Image _paintAndDetachToGpuImage() {
    final OffsetLayer offsetLayer = layer! as OffsetLayer;
    final PaintingContext context = PaintingContext(offsetLayer, Offset.zero & size);
    super.paint(context, Offset.zero);
    // ignore: invalid_use_of_protected_member
    context.stopRecordingIfNeeded();
    final ui.Image image = offsetLayer.toGpuImage(Offset.zero & size, pixelRatio: devicePixelRatio);
    offsetLayer.removeAllChildren();
    return image;
  }

  @override
  bool get isRepaintBoundary => child != null;


  @override
  void paint(PaintingContext context, Offset offset) {
    _childRaster ??= _paintAndDetachToGpuImage();
    try {
      delegate.paint(context, offset & size, _childRaster!, devicePixelRatio);
    } on ui.PictureRasterizationException {
      super.paint(context, offset);
    }
  }
}
