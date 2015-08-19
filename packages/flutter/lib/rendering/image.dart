// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/painting/box_painter.dart';
import 'package:sky/rendering/object.dart';
import 'package:sky/rendering/box.dart';

class RenderImage extends RenderBox {
  RenderImage({
    sky.Image image,
    double width,
    double height,
    sky.ColorFilter colorFilter,
    fit: ImageFit.scaleDown,
    repeat: ImageRepeat.noRepeat
  }) : _image = image,
      _width = width,
      _height = height,
      _colorFilter = colorFilter,
      _fit = fit,
      _repeat = repeat;

  sky.Image _image;
  sky.Image get image => _image;
  void set image (sky.Image value) {
    if (value == _image)
      return;
    _image = value;
    markNeedsPaint();
    if (_width == null || _height == null)
      markNeedsLayout();
  }

  double _width;
  double get width => _width;
  void set width (double value) {
    if (value == _width)
      return;
    _width = value;
    markNeedsLayout();
  }

  double _height;
  double get height => _height;
  void set height (double value) {
    if (value == _height)
      return;
    _height = value;
    markNeedsLayout();
  }

  sky.ColorFilter _colorFilter;
  sky.ColorFilter get colorFilter => _colorFilter;
  void set colorFilter (sky.ColorFilter value) {
    if (value == _colorFilter)
      return;
    _colorFilter = value;
    markNeedsPaint();
  }

  ImageFit _fit;
  ImageFit get fit => _fit;
  void set fit (ImageFit value) {
    if (value == _fit)
      return;
    _fit = value;
    markNeedsPaint();
  }

  ImageRepeat _repeat;
  ImageRepeat get repeat => _repeat;
  void set repeat (ImageRepeat value) {
    if (value == _repeat)
      return;
    _repeat = value;
    markNeedsPaint();
  }

  Size _sizeForConstraints(BoxConstraints constraints) {
    // Folds the given |width| and |height| into |cosntraints| so they can all
    // be treated uniformly.
    constraints = new BoxConstraints.tightFor(
      width: _width,
      height: _height
    ).apply(constraints);

    if (constraints.isTight || _image == null)
      return constraints.smallest;

    // This algorithm attempts to find a size for the RenderImage that fits in
    // the given constraints and preserves the image's intrinisc aspect ratio.
    // Its goals as follow:
    //
    //  - The dimensions of the RenderImage fit within the constraints.
    //  - The aspect ratio of the RenderImage matches the instrinsic aspect
    //    ratio of the image.
    //  - The RenderImage's dimension are maximal subject to being smaller than
    //    the intrinsic size of the image.

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
    if (_width == null && _height == null)
      return constraints.constrainWidth(0.0);
    return _sizeForConstraints(constraints).width;
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    return _sizeForConstraints(constraints).width;
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    if (_width == null && _height == null)
      return constraints.constrainHeight(0.0);
    return _sizeForConstraints(constraints).height;
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return _sizeForConstraints(constraints).height;
  }

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
      repeat: _repeat
    );
  }

  String debugDescribeSettings(String prefix) => '${super.debugDescribeSettings(prefix)}${prefix}width: ${width}\n${prefix}height: ${height}\n';
}
