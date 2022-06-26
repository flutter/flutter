// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

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
abstract class RenderAnimatedRaster extends RenderProxyBox {
  /// Create a new [RenderAnimatedRaster].
  RenderAnimatedRaster(Animation<double> animation)
    : _animation = animation {
    animation.addListener(markNeedsPaint);
    animation.addStatusListener(_updateStatus);
    _updateStatus(animation.status);
  }

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
  void paintImage(PaintingContext context, ui.Image image, Rect area, Animation<double> animation);

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

  void _paintChildIntoLayer(Offset offset) {
    final PaintingContext context = PaintingContext(layer!, offset & size);
    super.paint(context, Offset.zero);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
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
    final bool updateImage = willPaint(animation);
    if (_childImage == null && updateImage) {
      _paintChildIntoLayer(offset);
      _childImage = (layer! as OffsetLayer).toGpuImage(offset & size);
    }
    if (updateImage) {
      paintImage(context, _childImage!, offset & size, animation);
    }
  }
}
