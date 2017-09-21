// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show Image;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'basic_types.dart';
import 'border.dart';
import 'box_fit.dart';
import 'fractional_offset.dart';

/// How to paint any portions of a box not covered by an image.
enum ImageRepeat {
  /// Repeat the image in both the x and y directions until the box is filled.
  repeat,

  /// Repeat the image in the x direction until the box is filled horizontally.
  repeatX,

  /// Repeat the image in the y direction until the box is filled vertically.
  repeatY,

  /// Leave uncovered poritions of the box transparent.
  noRepeat
}

/// An image for a box decoration.
///
/// The image is painted using [paintImage], which describes the meanings of the
/// various fields on this class in more detail.
@immutable
class DecorationImage {
  /// Creates an image to show in a [BoxDecoration].
  ///
  /// The [image] argument must not be null.
  const DecorationImage({
    @required this.image,
    this.colorFilter,
    this.fit,
    this.alignment,
    this.centerSlice,
    this.repeat: ImageRepeat.noRepeat,
  }) : assert(image != null);

  /// The image to be painted into the decoration.
  ///
  /// Typically this will be an [AssetImage] (for an image shipped with the
  /// application) or a [NetworkImage] (for an image obtained from the network).
  final ImageProvider image;

  /// A color filter to apply to the image before painting it.
  final ColorFilter colorFilter;

  /// How the image should be inscribed into the box.
  ///
  /// The default is [BoxFit.scaleDown] if [centerSlice] is null, and
  /// [BoxFit.fill] if [centerSlice] is not null.
  ///
  /// See the discussion at [paintImage] for more details.
  final BoxFit fit;

  /// How to align the image within its bounds.
  ///
  /// An alignment of (0.0, 0.0) aligns the image to the top-left corner of its
  /// layout bounds.  An alignment of (1.0, 0.5) aligns the image to the middle
  /// of the right edge of its layout bounds.
  ///
  /// Defaults to [FractionalOffset.center].
  final FractionalOffset alignment;

  /// The center slice for a nine-patch image.
  ///
  /// The region of the image inside the center slice will be stretched both
  /// horizontally and vertically to fit the image into its destination. The
  /// region of the image above and below the center slice will be stretched
  /// only horizontally and the region of the image to the left and right of
  /// the center slice will be stretched only vertically.
  ///
  /// The stretching will be applied in order to make the image fit into the box
  /// specified by [fit]. When [centerSlice] is not null, [fit] defaults to
  /// [BoxFit.fill], which distorts the destination image size relative to the
  /// image's original aspect ratio. Values of [BoxFit] which do not distort the
  /// destination image size will result in [centerSlice] having no effect
  /// (since the nine regions of the image will be rendered with the same
  /// scaling, as if it wasn't specified).
  final Rect centerSlice;

  /// How to paint any portions of the box that would not otherwise be covered
  /// by the image.
  final ImageRepeat repeat;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (runtimeType != other.runtimeType)
      return false;
    final DecorationImage typedOther = other;
    return image == typedOther.image
        && colorFilter == typedOther.colorFilter
        && fit == typedOther.fit
        && alignment == typedOther.alignment
        && centerSlice == typedOther.centerSlice
        && repeat == typedOther.repeat;
  }

  @override
  int get hashCode => hashValues(image, colorFilter, fit, alignment, centerSlice, repeat);

  @override
  String toString() {
    final List<String> properties = <String>[];
    properties.add('$image');
    if (colorFilter != null)
      properties.add('$colorFilter');
    if (fit != null &&
        !(fit == BoxFit.fill && centerSlice != null) &&
        !(fit == BoxFit.scaleDown && centerSlice == null))
      properties.add('$fit');
    if (alignment != null)
      properties.add('$alignment');
    if (centerSlice != null)
      properties.add('centerSlice: $centerSlice');
    if (repeat != ImageRepeat.noRepeat)
      properties.add('$repeat');
    return '$runtimeType(${properties.join(", ")})';
  }
}

/// Paints an image into the given rectangle on the canvas.
///
///  * `canvas`: The canvas onto which the image will be painted.
///  * `rect`: The region of the canvas into which the image will be painted.
///    The image might not fill the entire rectangle (e.g., depending on the
///    `fit`). If `rect` is empty, nothing is painted.
///  * `image`: The image to paint onto the canvas.
///  * `colorFilter`: If non-null, the color filter to apply when painting the
///    image.
///  * `fit`: How the image should be inscribed into `rect`. If null, the
///    default behavior depends on `centerSlice`. If `centerSlice` is also null,
///    the default behavior is [BoxFit.scaleDown]. If `centerSlice` is
///    non-null, the default behavior is [BoxFit.fill]. See [BoxFit] for
///    details.
///  * `repeat`: If the image does not fill `rect`, whether and how the image
///    should be repeated to fill `rect`. By default, the image is not repeated.
///    See [ImageRepeat] for details.
///  * `centerSlice`: The image is drawn in nine portions described by splitting
///    the image by drawing two horizontal lines and two vertical lines, where
///    `centerSlice` describes the rectangle formed by the four points where
///    these four lines intersect each other. (This forms a 3-by-3 grid
///    of regions, the center region being described by `centerSlice`.)
///    The four regions in the corners are drawn, without scaling, in the four
///    corners of the destination rectangle defined by applying `fit`. The
///    remaining five regions are drawn by stretching them to fit such that they
///    exactly cover the destination rectangle while maintaining their relative
///    positions.
///  * `alignment`: How the destination rectangle defined by applying `fit` is
///    aligned within `rect`. For example, if `fit` is [BoxFit.contain] and
///    `alignment` is [FractionalOffset.bottomRight], the image will be as large
///    as possible within `rect` and placed with its bottom right corner at the
///    bottom right corner of `rect`.
///
/// See also:
///
///  * [paintBorder], which paints a border around a rectangle on a canvas.
///  * [DecorationImage], which holds a configuration for calling this function.
///  * [BoxDecoration], which uses this function to paint a [DecorationImage].
void paintImage({
  @required Canvas canvas,
  @required Rect rect,
  @required ui.Image image,
  ColorFilter colorFilter,
  BoxFit fit,
  FractionalOffset alignment,
  Rect centerSlice,
  ImageRepeat repeat: ImageRepeat.noRepeat,
}) {
  assert(canvas != null);
  assert(image != null);
  if (rect.isEmpty)
    return;
  Size outputSize = rect.size;
  Size inputSize = new Size(image.width.toDouble(), image.height.toDouble());
  Offset sliceBorder;
  if (centerSlice != null) {
    sliceBorder = new Offset(
      centerSlice.left + inputSize.width - centerSlice.right,
      centerSlice.top + inputSize.height - centerSlice.bottom
    );
    outputSize -= sliceBorder;
    inputSize -= sliceBorder;
  }
  fit ??= centerSlice == null ? BoxFit.scaleDown : BoxFit.fill;
  assert(centerSlice == null || (fit != BoxFit.none && fit != BoxFit.cover));
  final FittedSizes fittedSizes = applyBoxFit(fit, inputSize, outputSize);
  final Size sourceSize = fittedSizes.source;
  Size destinationSize = fittedSizes.destination;
  if (centerSlice != null) {
    outputSize += sliceBorder;
    destinationSize += sliceBorder;
    // We don't have the ability to draw a subset of the image at the same time
    // as we apply a nine-patch stretch.
    assert(sourceSize == inputSize, 'centerSlice was used with a BoxFit that does not guarantee that the image is fully visible.');
  }
  if (repeat != ImageRepeat.noRepeat && destinationSize == outputSize) {
    // There's no need to repeat the image because we're exactly filling the
    // output rect with the image.
    repeat = ImageRepeat.noRepeat;
  }
  final Paint paint = new Paint()..isAntiAlias = false;
  if (colorFilter != null)
    paint.colorFilter = colorFilter;
  if (sourceSize != destinationSize) {
    // Use the "low" quality setting to scale the image, which corresponds to
    // bilinear interpolation, rather than the default "none" which corresponds
    // to nearest-neighbor.
    paint.filterQuality = FilterQuality.low;
  }
  final double dx = (outputSize.width - destinationSize.width) * (alignment?.dx ?? 0.5);
  final double dy = (outputSize.height - destinationSize.height) * (alignment?.dy ?? 0.5);
  final Offset destinationPosition = rect.topLeft.translate(dx, dy);
  final Rect destinationRect = destinationPosition & destinationSize;
  if (repeat != ImageRepeat.noRepeat) {
    canvas.save();
    canvas.clipRect(rect);
  }
  if (centerSlice == null) {
    final Rect sourceRect = (alignment ?? FractionalOffset.center).inscribe(
      fittedSizes.source, Offset.zero & inputSize
    );
    for (Rect tileRect in _generateImageTileRects(rect, destinationRect, repeat))
      canvas.drawImageRect(image, sourceRect, tileRect, paint);
  } else {
    for (Rect tileRect in _generateImageTileRects(rect, destinationRect, repeat))
      canvas.drawImageNine(image, centerSlice, tileRect, paint);
  }
  if (repeat != ImageRepeat.noRepeat)
    canvas.restore();
}

Iterable<Rect> _generateImageTileRects(Rect outputRect, Rect fundamentalRect, ImageRepeat repeat) sync* {
  if (repeat == ImageRepeat.noRepeat) {
    yield fundamentalRect;
    return;
  }

  int startX = 0;
  int startY = 0;
  int stopX = 0;
  int stopY = 0;
  final double strideX = fundamentalRect.width;
  final double strideY = fundamentalRect.height;

  if (repeat == ImageRepeat.repeat || repeat == ImageRepeat.repeatX) {
    startX = ((outputRect.left - fundamentalRect.left) / strideX).floor();
    stopX = ((outputRect.right - fundamentalRect.right) / strideX).ceil();
  }

  if (repeat == ImageRepeat.repeat || repeat == ImageRepeat.repeatY) {
    startY = ((outputRect.top - fundamentalRect.top) / strideY).floor();
    stopY = ((outputRect.bottom - fundamentalRect.bottom) / strideY).ceil();
  }

  for (int i = startX; i <= stopX; ++i) {
    for (int j = startY; j <= stopY; ++j)
      yield fundamentalRect.shift(new Offset(i * strideX, j * strideY));
  }
}
