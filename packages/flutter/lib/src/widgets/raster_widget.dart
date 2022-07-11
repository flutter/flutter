// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'media_query.dart';

// A delegate that paints the child widget as is.
class _RasterDefaultDelegate implements RasterWidgetDelegate {
  const _RasterDefaultDelegate();

  @override
  void paint(PaintingContext context, Rect area, ui.Image image, double pixelRatio) {
    final Rect src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final Rect dst = Rect.fromLTWH(0, 0, area.width, area.height);
    final Paint paint = Paint()
      ..filterQuality = FilterQuality.low;
    context.canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  bool shouldRepaint(covariant RasterWidgetDelegate oldDelegate) => false;

  @override
  void addListener(ui.VoidCallback listener) { }

  @override
  void dispose() { }

  @override
  bool get hasListeners => false;

  @override
  void notifyListeners() { }

  @override
  void removeListener(ui.VoidCallback listener) { }
}

/// A widget that replaces its child with a rasterized version of the child.
///
/// When the value of [rasterize] is true, this widget will convert the child scene into
/// an image. This image will be drawn in place of the children until [rasterize] is false.
///
/// How this image is drawn can be customized by providing a new subclass of [RasterWidgetDelegate]
/// to the [delegate] argument.
///
/// This widget is not supported on the HTML backend of flutter for the web.
class RasterWidget extends SingleChildRenderObjectWidget {
  /// Create a new [RasterWidget].
  const RasterWidget({
    super.key,
    this.delegate = const _RasterDefaultDelegate(),
    required this.rasterize,
    required super.child
  });

  /// A delegate that allows customization of how the image is painted.
  ///
  /// If not provided, defaults to a delegate which paints the child as is.
  final RasterWidgetDelegate delegate;

  /// Whether a rasterized version of this render objects child is drawn in
  /// place of the child.
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

/// A delegate used to draw the image representing the rasterized child.
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
  ///   final Rect src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
  ///   final Rect dst = Rect.fromLTWH(0, 0, area.width, area.height);
  ///   final Paint paint = Paint()
  ///     ..filterQuality = FilterQuality.low;
  ///   context.canvas.drawImageRect(image, src, dst, paint);
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
  ValueNotifier<bool> get rasterize => _rasterize;
  ValueNotifier<bool> _rasterize;
  set rasterize(ValueNotifier<bool> value) {
    if (value == rasterize) {
      return;
    }
    rasterize.removeListener(_onRasterValueChanged);
    final bool oldValue = rasterize.value;
    _rasterize = value;
    rasterize.addListener(_onRasterValueChanged);
    if (oldValue != rasterize.value) {
      _onRasterValueChanged();
    }
  }

  /// The delegate used to draw the image representing the child.
  RasterWidgetDelegate get delegate => _delegate;
  RasterWidgetDelegate _delegate;
  set delegate(RasterWidgetDelegate value) {
    if (value == delegate) {
      return;
    }
    delegate.removeListener(markNeedsPaint);
    final RasterWidgetDelegate oldDelegate = _delegate;
    _delegate = value;
    delegate.addListener(markNeedsPaint);
    if (delegate.shouldRepaint(oldDelegate)) {
      markNeedsPaint();
    }
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
