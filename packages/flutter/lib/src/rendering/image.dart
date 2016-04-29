// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show Image;

import 'box.dart';
import 'object.dart';

export 'package:flutter/painting.dart' show
  ImageFit,
  ImageRepeat;

/// An image in the render tree.
///
/// The render image attempts to find a size for itself that fits in the given
/// constraints and preserves the image's intrinisc aspect ratio.
class RenderImage extends RenderBox {
  RenderImage({
    ui.Image image,
    double width,
    double height,
    double scale: 1.0,
    Color color,
    ImageFit fit,
    FractionalOffset alignment,
    ImageRepeat repeat: ImageRepeat.noRepeat,
    Rect centerSlice
  }) : _image = image,
      _width = width,
      _height = height,
      _scale = scale,
      _color = color,
      _fit = fit,
      _alignment = alignment,
      _repeat = repeat,
      _centerSlice = centerSlice {
    _updateColorFilter();
  }

  /// The image to display.
  ui.Image get image => _image;
  ui.Image _image;
  set image (ui.Image value) {
    if (value == _image)
      return;
    _image = value;
    markNeedsPaint();
    if (_width == null || _height == null)
      markNeedsLayout();
  }

  /// If non-null, requires the image to have this width.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  double get width => _width;
  double _width;
  set width (double value) {
    if (value == _width)
      return;
    _width = value;
    markNeedsLayout();
  }

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  double get height => _height;
  double _height;
  set height (double value) {
    if (value == _height)
      return;
    _height = value;
    markNeedsLayout();
  }

  /// Specifies the image's scale.
  ///
  /// Used when determining the best display size for the image.
  double get scale => _scale;
  double _scale;
  set scale (double value) {
    assert(value != null);
    if (value == _scale)
      return;
    _scale = value;
    markNeedsLayout();
  }

  ColorFilter _colorFilter;

  // Should we make the transfer mode configurable?
  void _updateColorFilter() {
    if (_color == null)
      _colorFilter = null;
    else
      _colorFilter = new ColorFilter.mode(_color, TransferMode.srcIn);
  }

  /// If non-null, apply this color filter to the image before painting.
  Color get color => _color;
  Color _color;
  set color (Color value) {
    if (value == _color)
      return;
    _color = value;
    _updateColorFilter();
    markNeedsPaint();
  }

  /// How to inscribe the image into the place allocated during layout.
  ImageFit get fit => _fit;
  ImageFit _fit;
  set fit (ImageFit value) {
    if (value == _fit)
      return;
    _fit = value;
    markNeedsPaint();
  }

  /// How to align the image within its bounds.
  FractionalOffset get alignment => _alignment;
  FractionalOffset _alignment;
  set alignment (FractionalOffset value) {
    if (value == _alignment)
      return;
    _alignment = value;
    markNeedsPaint();
  }

  /// How to repeat this image if it doesn't fill its layout bounds.
  ImageRepeat get repeat => _repeat;
  ImageRepeat _repeat;
  set repeat (ImageRepeat value) {
    if (value == _repeat)
      return;
    _repeat = value;
    markNeedsPaint();
  }

  /// The center slice for a nine-patch image.
  ///
  /// The region of the image inside the center slice will be stretched both
  /// horizontally and vertically to fit the image into its destination. The
  /// region of the image above and below the center slice will be stretched
  /// only horizontally and the region of the image to the left and right of
  /// the center slice will be stretched only vertically.
  Rect get centerSlice => _centerSlice;
  Rect _centerSlice;
  set centerSlice (Rect value) {
    if (value == _centerSlice)
      return;
    _centerSlice = value;
    markNeedsPaint();
  }

  /// Find a size for the render image within the given constraints.
  ///
  ///  - The dimensions of the RenderImage must fit within the constraints.
  ///  - The aspect ratio of the RenderImage matches the instrinsic aspect
  ///    ratio of the image.
  ///  - The RenderImage's dimension are maximal subject to being smaller than
  ///    the intrinsic size of the image.
  Size _sizeForConstraints(BoxConstraints constraints) {
    // Folds the given |width| and |height| into |constraints| so they can all
    // be treated uniformly.
    constraints = new BoxConstraints.tightFor(
      width: _width,
      height: _height
    ).enforce(constraints);

    if (constraints.isTight || _image == null)
      return constraints.smallest;

    double width = _image.width.toDouble() / _scale;
    double height = _image.height.toDouble() / _scale;
    assert(width > 0.0);
    assert(height > 0.0);
    double aspectRatio = width / height;

    if (width > constraints.maxWidth) {
      width = constraints.maxWidth;
      height = width / aspectRatio;
    }

    if (height > constraints.maxHeight) {
      height = constraints.maxHeight;
      width = height * aspectRatio;
    }

    if (width < constraints.minWidth) {
      width = constraints.minWidth;
      height = width / aspectRatio;
    }

    if (height < constraints.minHeight) {
      height = constraints.minHeight;
      width = height * aspectRatio;
    }

    return constraints.constrain(new Size(width, height));
  }

  @override
  double getMinIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    if (_width == null && _height == null)
      return constraints.constrainWidth(0.0);
    return _sizeForConstraints(constraints).width;
  }

  @override
  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    return _sizeForConstraints(constraints).width;
  }

  @override
  double getMinIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    if (_width == null && _height == null)
      return constraints.constrainHeight(0.0);
    return _sizeForConstraints(constraints).height;
  }

  @override
  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    return _sizeForConstraints(constraints).height;
  }

  @override
  bool hitTestSelf(Point position) => true;

  @override
  void performLayout() {
    size = _sizeForConstraints(constraints);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_image == null)
      return;
    paintImage(
      canvas: context.canvas,
      rect: offset & size,
      image: _image,
      colorFilter: _colorFilter,
      fit: _fit,
      alignment: _alignment,
      centerSlice: _centerSlice,
      repeat: _repeat
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('image: $image');
    if (width != null)
      description.add('width: $width');
    if (height != null)
      description.add('height: $height');
    if (scale != 1.0)
      description.add('scale: $scale');
    if (color != null)
      description.add('color: $color');
    if (fit != null)
      description.add('fit: $fit');
    if (alignment != null)
      description.add('alignment: $alignment');
    if (repeat != ImageRepeat.noRepeat)
      description.add('repeat: $repeat');
    if (centerSlice != null)
      description.add('centerSlice: $centerSlice');
  }
}
