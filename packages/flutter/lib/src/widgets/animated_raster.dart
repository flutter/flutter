// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'media_query.dart';

/// A delegate that controls what is painted during an animation in the [AnimatedRaster]
/// widget.
@immutable
abstract class AnimatedRasterDelegate {
  /// const constructor so that subclasses can be const.
  const AnimatedRasterDelegate();

  /// Whether [paintImage] will paint anything on the current frame.
  ///
  /// This is used to optimize painting and delay rasterization if a child
  /// would not be painted. One example would be an animated opacity, if the
  /// first frame is fully transparent then rasterization can be delayed until
  /// the second frame.
  @protected
  bool willPaint(Animation<double> animation) => true;

  /// Paint the children of this render object.
  ///
  /// The provided [image] contains a GPU resident texture of the children of
  /// this render object.
  @protected
  void paintImage(PaintingContext context, ui.Image image, Rect area, double pixelRatio, Animation<double> animation);
}

/// A widget that replaces [child] with a rasterized version while an animation is active.
///
/// How that image is painted is controlled by providing an [AnimatedRasterDelegate], which
/// can also incorporate the animation value. This is primarily used for efficient page
/// transitions.
///
/// This class depends on [Scene.toGpuImage] which is not supported on the html backend.
///
/// See also:
///  * [ZoomPageTransitionsBuilder], which uses this render object to implement the fade and
///    stretch effect efficiently.
class AnimatedRaster extends SingleChildRenderObjectWidget {
  /// Create a new [AnimatedRaster].
  const AnimatedRaster({
    super.key,
    super.child,
    required this.animation,
    required this.delegate,
  });

  /// The animation that drives the [delegate].
  final Animation<double> animation;

  /// The delegate which controls how the child raster is painted.
  final AnimatedRasterDelegate delegate;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderAnimatedRaster(animation, delegate, MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0);
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderAnimatedRaster renderObject) {
    renderObject
      ..animation = animation
      ..delegate = delegate
      ..devicePixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
  }
}

/// A render object that converts its children to a [ui.Image] while animating.
///
/// While the status of [animation] is [AnimationStatus.completed] or
/// [AnimationStatus.dismissed], children are painted normally. When the status
/// is [AnimationStatus.forward] or [AnimationStatus.reverse], this render object
/// will create a GPU resident texture the first time that [willPaint] returns true
/// and provide it to [paintImage].
///
/// See also:
///  * [ZoomPageTransitionsBuilder], which uses this render object to implement the fade and
///    stretch effect efficiently.
class RenderAnimatedRaster extends RenderProxyBox {
  /// Create a new [RenderAnimatedRaster].
  RenderAnimatedRaster(this._animation, this._delegate, this._devicePixelRatio) {
    animation.addListener(markNeedsPaint);
    animation.addStatusListener(_updateStatus);
    _updateStatus(animation.status);
  }

  AnimationStatus _status = AnimationStatus.completed;

  void _updateStatus(AnimationStatus newStatus, [bool painting = false]) {
    if (newStatus == _status) {
      return;
    }
    _childImage?.dispose();
    _childImage = null;
    _status = newStatus;
    assert(_status == animation.status);
    if (!painting) {
      markNeedsPaint();
    }
  }

  /// The delegate that controls how the child raster is painted.
  AnimatedRasterDelegate get delegate => _delegate;
  AnimatedRasterDelegate _delegate;
  set delegate(AnimatedRasterDelegate value) {
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
    animation.removeStatusListener(_updateStatus);
    _animation = value;
    animation.addStatusListener(_updateStatus);
    animation.addListener(markNeedsPaint);
    _updateStatus(animation.status);
    markNeedsPaint();
  }

  @override
  void dispose() {
    animation.removeListener(markNeedsPaint);
    animation.removeStatusListener(_updateStatus);
    _childImage?.dispose();
    _childImage = null;
    super.dispose();
  }

  @override
  void attach(covariant PipelineOwner owner) {
    animation.addListener(markNeedsPaint);
    animation.addStatusListener(_updateStatus);
    _updateStatus(animation.status);
    super.attach(owner);
  }

  @override
  void detach() {
    animation.removeListener(markNeedsPaint);
    animation.removeStatusListener(_updateStatus);
    super.detach();
  }

  @override
  bool get isRepaintBoundary => child != null;

  ui.Image? _childImage;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      return;
    }
    _updateStatus(animation.status, true);
    switch (_status) {
      case AnimationStatus.dismissed:
      case AnimationStatus.completed:
        super.paint(context, offset);
        return;
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        break;
    }
    final bool updateImage = delegate.willPaint(animation);
    if (_childImage == null && updateImage) {
      _childImage = PaintingContext.paintAndDetachToGpuImage(
        layer! as OffsetLayer,
        estimatedBounds: offset & size,
        child: child!,
        pixelRatio: devicePixelRatio,
        offset: offset,
      );
    }
    if (updateImage) {
      final Rect src = offset & size;
      delegate.paintImage(
        context,
        _childImage!,
        Rect.fromLTWH(src.left, src.top, src.width * devicePixelRatio, src.height * devicePixelRatio),
        devicePixelRatio,
        animation,
      );
    }
  }
}
