// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

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
    ColorFilter colorFilter,
    ImageFit fit,
    FractionalOffset alignment,
    ImageRepeat repeat: ImageRepeat.noRepeat,
    Rect centerSlice
  }) : _image = image,
      _width = width,
      _height = height,
      _colorFilter = colorFilter,
      _fit = fit,
      _alignment = alignment,
      _repeat = repeat,
      _centerSlice = centerSlice;

  /// The image to display.
  ui.Image get image => _image;
  ui.Image _image;
  void set image (ui.Image value) {
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
  void set width (double value) {
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
  void set height (double value) {
    if (value == _height)
      return;
    _height = value;
    markNeedsLayout();
  }

  /// If non-null, apply this color filter to the image before painint.
  ColorFilter get colorFilter => _colorFilter;
  ColorFilter _colorFilter;
  void set colorFilter (ColorFilter value) {
    if (value == _colorFilter)
      return;
    _colorFilter = value;
    markNeedsPaint();
  }

  /// How to inscribe the image into the place allocated during layout.
  ImageFit get fit => _fit;
  ImageFit _fit;
  void set fit (ImageFit value) {
    if (value == _fit)
      return;
    _fit = value;
    markNeedsPaint();
  }

  /// How to align the image within its bounds.
  FractionalOffset get alignment => _alignment;
  FractionalOffset _alignment;
  void set alignment (FractionalOffset value) {
    if (value == _alignment)
      return;
    _alignment = value;
    markNeedsPaint();
  }

  /// How to repeat this image if it doesn't fill its layout bounds.
  ImageRepeat get repeat => _repeat;
  ImageRepeat _repeat;
  void set repeat (ImageRepeat value) {
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
  void set centerSlice (Rect value) {
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
    // Folds the given |width| and |height| into |cosntraints| so they can all
    // be treated uniformly.
    constraints = new BoxConstraints.tightFor(
      width: _width,
      height: _height
    ).enforce(constraints);

    if (constraints.isTight || _image == null)
      return constraints.smallest;

    double width = _image.width.toDouble();
    double height = _image.height.toDouble();
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

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    if (_width == null && _height == null)
      return constraints.constrainWidth(0.0);
    return _sizeForConstraints(constraints).width;
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    return _sizeForConstraints(constraints).width;
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    if (_width == null && _height == null)
      return constraints.constrainHeight(0.0);
    return _sizeForConstraints(constraints).height;
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    return _sizeForConstraints(constraints).height;
  }

  bool hitTestSelf(Point position) => true;

  void performLayout() {
    size = _sizeForConstraints(constraints);
  }

  void paint(PaintingContext context, Offset offset) {
    if (_image == null)
      return;
    paintImage(
      canvas: context.canvas,
      rect: offset & size,
      image: _image,
      colorFilter: _colorFilter,
      fit: _fit,
      alignX: _alignment?.x,
      alignY: _alignment?.y,
      centerSlice: _centerSlice,
      repeat: _repeat
    );
  }

  void debugDescribeSettings(List<String> settings) {
    super.debugDescribeSettings(settings);
    settings.add('width: $width');
    settings.add('height: $height');
  }
}
