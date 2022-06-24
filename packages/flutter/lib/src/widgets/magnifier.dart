// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A widget that magnifies a screen region relative to itself.
///
/// [Magnifier] may have a [child], which will be drawn over the lens. This is useful
/// for overlays like tinting the lens.
///
/// Some caveats for using the magnifier:
/// * [Magnifier] may only display widgets that come before it in the paint order; for example,
/// if magnifier comes before `widget A` in a column, then you will not be able to see `widget A`
/// in the magnifier.
/// *  If the magnifier points out of the bounds of the app, will have undefined behavior. This generally
/// results in
///
///
/// This widget's magnification does not lower resolution of the subject
/// in the [Magnifier].
///
///
///
/// See also:
/// * [BackdropFilter], which [Magnifier] uses along with [ImageFilter.matrix] to
/// Magnify a screen region.
/// * [Loupe], which uses [Magnifier] to magnify text.
class Magnifier extends SingleChildRenderObjectWidget {
  /// Construct a [Magnifier],
  Magnifier(
      {super.key,
      super.child,
      ShapeBorder? shape,
      this.magnificationScale = 1,
      this.focalPoint = Offset.zero})
      : clip = shape != null
            ? ShapeBorderClipper(
                shape: shape,
              )
            : null;

  ///  [focalPoint] of the magnifier is the area the center of the
  /// [Magnifier] points to, relative to the center of the magnifier.
  /// If left as [Offset.zero], the magnifier will magnify whatever is directly
  /// below it.
  final Offset focalPoint;

  /// The scale of the magnification.
  ///
  /// A [magnificationScale] of 1 means that the content magi
  final double magnificationScale;

  /// The shape of the magnifier is dictated by [clip], which clips
  /// the magnifier to the shape. If null, the shape will be rectangular.
  final ShapeBorderClipper? clip;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMagnification(focalPoint, magnificationScale, clip);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderMagnification renderObject) {
    renderObject
      ..focalPoint = focalPoint
      ..clip = clip
      ..magnificationScale = magnificationScale;
  }
}

class _RenderMagnification extends RenderProxyBox {
  _RenderMagnification(
    this._focalPoint,
    this._magnificationScale,
    this._clip, {
    RenderBox? child,
  }) : super(child);

  Offset get focalPoint => _focalPoint;
  Offset _focalPoint;
  set focalPoint(Offset value) {
    if (_focalPoint == value) {
      return;
    }
    _focalPoint = value;
    markNeedsLayout();
  }

  double get magnificationScale => _magnificationScale;
  double _magnificationScale;
  set magnificationScale(double value) {
    if (_magnificationScale == value) {
      return;
    }
    _magnificationScale = value;
    markNeedsLayout();
  }

  CustomClipper<Path>? get clip => _clip;
  CustomClipper<Path>? _clip;
  set clip(CustomClipper<Path>? value) {
    if (_clip == value) {
      return;
    }
    _clip = value;
    markNeedsLayout();
  }

  @override
  _MagnificationLayer? get layer => super.layer as _MagnificationLayer?;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (layer == null) {
      layer = _MagnificationLayer(
          size: size,
          globalPosition: offset,
          focalPoint: focalPoint,
          clip: clip,
          magnificationScale: magnificationScale);
    } else {
      layer!
        ..magnificationScale = magnificationScale
        ..size = size
        ..globalPosition = offset
        ..focalPoint = focalPoint;
    }

    context.pushLayer(layer!, super.paint, offset);
  }
}

class _MagnificationLayer extends ContainerLayer {
  _MagnificationLayer(
      {required this.size,
      required this.globalPosition,
      required this.clip,
      required this.focalPoint,
      required this.magnificationScale});

  Offset globalPosition;
  Size size;

  Offset focalPoint;
  double magnificationScale;

  CustomClipper<Path>? clip;

  @override
  void addToScene(SceneBuilder builder) {
    // If shape is null, can push the most optimized clip, a regular rectangle.
    if (clip == null) {
      builder.pushClipRect(globalPosition & size);
    } else {
      builder.pushClipPath(clip!.getClip(size).shift(globalPosition));
    }

    // Create and push transform.
    final Offset thisCenter = Alignment.center.alongSize(size) + globalPosition;
    final Matrix4 matrix = Matrix4.identity()
      ..translate(
          magnificationScale * (focalPoint.dx - thisCenter.dx) + thisCenter.dx,
          magnificationScale * (focalPoint.dy - thisCenter.dy) + thisCenter.dy)
      ..scale(magnificationScale);
    builder.pushBackdropFilter(ImageFilter.matrix(matrix.storage));
    builder.pop();

    super.addToScene(builder);
    builder.pop();
  }
}
