// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(jonahwilliams): this is temporarily a private library until we determine
// a reasonable public API.
part of page_transitions_theme;

// Foundational widgets for the rasterized zoom page transition.

/// A delegate that controls what is painted during an animation in the [_AnimatedRaster]
/// widget.
@immutable
abstract class _AnimatedRasterDelegate {
  /// const constructor so that subclasses can be const.
  const _AnimatedRasterDelegate();

  /// Whether [paint] will paint anything on the current frame.
  ///
  /// This is used to optimize painting and delay rasterization if a child
  /// would not be painted. One example would be an animated opacity, if the
  /// first frame is fully transparent then rasterization can be delayed until
  /// the second frame.
  @protected
  bool useRaster(Animation<double> animation) => true;

  /// Paint the children of this render object.
  ///
  /// The provided [image] contains a GPU resident texture of the children of
  /// this render object.
  ///
  /// The [pixelRatio] is the ratio of pixels in [image] to logical pixels.
  @protected
  void paintRaster(PaintingContext context, ui.Image image, double pixelRatio, Animation<double> animation);

  /// Paint the children of this render object.
  @protected
  void paint(PaintingContext context, Animation<double> animation, Rect area, PaintingContextCallback callback);
}

/// A widget that replaces [child] with a rasterized version while an animation is active.
///
/// How that image is painted is controlled by providing an [_AnimatedRasterDelegate], which
/// can also incorporate the animation value. This is primarily used for efficient page
/// transitions.
///
/// This class depends on [Scene.toGpuImage] which is not supported on the html backend.
///
/// See also:
///  * [ZoomPageTransitionsBuilder], which uses this render object to implement the fade and
///    stretch effect efficiently.
class _AnimatedRaster extends SingleChildRenderObjectWidget {
  /// Create a new [_AnimatedRaster].
  const _AnimatedRaster({
    super.child,
    required this.animation,
    required this.delegate,
  });

  /// The animation that drives the [delegate].
  final Animation<double> animation;

  /// The delegate which controls how the child raster is painted.
  final _AnimatedRasterDelegate delegate;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderAnimatedRaster(animation, delegate, MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0);
  }

  @override
  void updateRenderObject(BuildContext context, covariant _RenderAnimatedRaster renderObject) {
    renderObject
      ..animation = animation
      ..delegate = delegate
      ..devicePixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
  }
}

/// A render object that converts its children to a [ui.Image].
///
/// This render object will create a GPU resident texture the first time that
/// [_AnimatedRasterDelegate.willPaint] returns true and and provide it to
/// [_AnimatedRasterDelegate.paintRaster]. This will be reused until `willPaint`
/// returns false. It is up to the implementor of the raster delegate to handle
/// painting both the rasterized and the non-rasterized child.
///
/// See also:
///  * [ZoomPageTransitionsBuilder], which uses this render object to implement the fade and
///    stretch effect efficiently.
class _RenderAnimatedRaster extends RenderProxyBox {
  /// Create a new [_RenderAnimatedRaster].
  _RenderAnimatedRaster(
    this._animation,
    this._delegate,
    this._devicePixelRatio,
  );

  /// The delegate that controls how the child raster is painted.
  _AnimatedRasterDelegate get delegate => _delegate;
  _AnimatedRasterDelegate _delegate;
  set delegate(_AnimatedRasterDelegate value) {
    if (value == delegate) {
      return;
    }
    _delegate = value;
    markNeedsPaint();
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

  /// The animation used to drive this render object.
  Animation<double> get animation => _animation;
  Animation<double> _animation;
  set animation(Animation<double> value) {
    if (value == animation) {
      return;
    }
    animation.removeListener(markNeedsPaint);
    _animation = value;
    animation.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  void dispose() {
    animation.removeListener(markNeedsPaint);
    _childImage?.dispose();
    _childImage = null;
    super.dispose();
  }

  @override
  void attach(covariant PipelineOwner owner) {
    animation.addListener(markNeedsPaint);
    super.attach(owner);
  }

  @override
  void detach() {
    animation.removeListener(markNeedsPaint);
    super.detach();
  }

  // Paint [child] with this painting context, then convert to a raster and detach all
  // children from this layer.
  ui.Image _paintAndDetachToGpuImage() {
    final OffsetLayer offsetLayer = layer! as OffsetLayer;
    final PaintingContext context = PaintingContext(offsetLayer, Offset.zero & size);
    context.paintChild(child!, Offset.zero);
    // ignore: invalid_use_of_protected_member
    context.stopRecordingIfNeeded();
    final ui.Image image = offsetLayer.toGpuImage(Offset.zero & size, pixelRatio: devicePixelRatio);
    offsetLayer.removeAllChildren();
    return image;
  }

  @override
  bool get isRepaintBoundary => child != null;

  ui.Image? _childImage;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      return;
    }
    final bool useRaster = delegate.useRaster(animation);
    if (!useRaster) {
      delegate.paint(
        context,
        animation,
        offset & size,
        super.paint,
      );
      _childImage?.dispose();
      _childImage = null;
      return;
    }
    _childImage ??= _paintAndDetachToGpuImage();
    delegate.paintRaster(
      context,
      _childImage!,
      devicePixelRatio,
      animation,
    );
  }
}
