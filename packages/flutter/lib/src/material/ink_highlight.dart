// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'material.dart';

const Duration _kHighlightFadeDuration = const Duration(milliseconds: 200);

/// A visual emphasis on a part of a [Material] receiving user interaction.
///
/// This object is rarely created directly. Instead of creating an ink highlight
/// directly, consider using an [InkResponse] or [InkWell] widget, which uses
/// gestures (such as tap and long-press) to trigger ink highlights.
///
/// See also:
///
///  * [InkResponse], which uses gestures to trigger ink highlights and ink
///    splashes in the parent [Material].
///  * [InkWell], which is a rectangular [InkResponse] (the most common type of
///    ink response).
///  * [Material], which is the widget on which the ink highlight is painted.
///  * [InkSplash], which is an ink feature that shows a reaction to user input
///    on a [Material].
class InkHighlight extends InkFeature {
  /// Begin a highlight animation.
  ///
  /// The [controller] argument is typically obtained via
  /// `Material.of(context)`.
  ///
  /// If a `rectCallback` is given, then it provides the highlight rectangle,
  /// otherwise, the highlight rectangle is coincident with the [referenceBox].
  ///
  /// When the highlight is removed, `onRemoved` will be called.
  InkHighlight({
    @required MaterialInkController controller,
    @required RenderBox referenceBox,
    @required Color color,
    BoxShape shape: BoxShape.rectangle,
    BorderRadius borderRadius,
    RectCallback rectCallback,
    VoidCallback onRemoved,
  }) : assert(color != null),
       assert(shape != null),
       _color = color,
       _shape = shape,
       _borderRadius = borderRadius ?? BorderRadius.zero,
       _rectCallback = rectCallback,
       super(controller: controller, referenceBox: referenceBox, onRemoved: onRemoved) {
    _alphaController = new AnimationController(duration: _kHighlightFadeDuration, vsync: controller.vsync)
      ..addListener(controller.markNeedsPaint)
      ..addStatusListener(_handleAlphaStatusChanged)
      ..forward();
    _alpha = new IntTween(
      begin: 0,
      end: color.alpha
    ).animate(_alphaController);

    controller.addInkFeature(this);
  }

  final BoxShape _shape;
  final BorderRadius _borderRadius;
  final RectCallback _rectCallback;

  Animation<int> _alpha;
  AnimationController _alphaController;

  /// The color of the ink used to emphasize part of the material.
  Color get color => _color;
  Color _color;
  set color(Color value) {
    if (value == _color)
      return;
    _color = value;
    controller.markNeedsPaint();
  }

  /// Whether this part of the material is being visually emphasized.
  bool get active => _active;
  bool _active = true;

  /// Start visually emphasizing this part of the material.
  void activate() {
    _active = true;
    _alphaController.forward();
  }

  /// Stop visually emphasizing this part of the material.
  void deactivate() {
    _active = false;
    _alphaController.reverse();
  }

  void _handleAlphaStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && !_active)
      dispose();
  }

  @override
  void dispose() {
    _alphaController.dispose();
    super.dispose();
  }

  void _paintHighlight(Canvas canvas, Rect rect, Paint paint) {
    assert(_shape != null);
    switch (_shape) {
      case BoxShape.circle:
        canvas.drawCircle(rect.center, Material.defaultSplashRadius, paint);
        break;
      case BoxShape.rectangle:
        if (_borderRadius != BorderRadius.zero) {
          final RRect clipRRect = new RRect.fromRectAndCorners(
            rect,
            topLeft: _borderRadius.topLeft, topRight: _borderRadius.topRight,
            bottomLeft: _borderRadius.bottomLeft, bottomRight: _borderRadius.bottomRight,
          );
          canvas.drawRRect(clipRRect, paint);
        } else {
          canvas.drawRect(rect, paint);
        }
        break;
    }
  }

  @override
  void paintFeature(Canvas canvas, Matrix4 transform) {
    final Paint paint = new Paint()..color = color.withAlpha(_alpha.value);
    final Offset originOffset = MatrixUtils.getAsTranslation(transform);
    final Rect rect = (_rectCallback != null ? _rectCallback() : Offset.zero & referenceBox.size);
    if (originOffset == null) {
      canvas.save();
      canvas.transform(transform.storage);
      _paintHighlight(canvas, rect, paint);
      canvas.restore();
    } else {
      _paintHighlight(canvas, rect.shift(originOffset), paint);
    }
  }
}
