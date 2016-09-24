// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'basic_types.dart';

/// How an image should be inscribed into a box.
///
/// See also [applyImageFit], which applies the sizing semantics of these values
/// (though not the alignment semantics).
enum ImageFit {
  /// Fill the box by distorting the image's aspect ratio.
  fill,

  /// As large as possible while still containing the image entirely within the box.
  contain,

  /// As small as possible while still covering the entire box.
  cover,

  /// Make sure the full width of the image is shown, regardless of
  /// whether this means the image overflows the box vertically.
  fitWidth,

  /// Make sure the full height of the image is shown, regardless of
  /// whether this means the image overflows the box horizontally.
  fitHeight,

  /// Center the image within the box and discard any portions of the image that
  /// lie outside the box.
  none,

  /// Center the image within the box and, if necessary, scale the image down to
  /// ensure that the image fits within the box.
  scaleDown
}

/// The pair of sizes returned by [applyImageFit].
class FittedSizes {
  /// Creates an object to store a pair of sizes,
  /// as would be returned by [applyImageFit].
  const FittedSizes(this.source, this.destination);

  /// The size of the part of the input to show on the output.
  final Size source;

  /// The size of the part of the output on which to show the input.
  final Size destination;
}

/// Apply an [ImageFit] value.
///
/// The arguments to this method, in addition to the [ImageFit] value to apply,
/// are two sizes, ostensibly the sizes of an input image and an output canvas.
/// Specifically, the `inputSize` argument gives the size of the complete image
/// that is being fitted, and the `outputSize` gives the size of the rectangle
/// into which the image is to be drawn.
///
/// This function then returns two sizes, combined into a single [FittedSizes]
/// object.
///
/// The [FittedSizes.source] size is the subpart of the `inputSize` that is to
/// be shown. If the entire input image is shown, then this will equal the
/// `inputSize`, but if the input image is to be cropped down, this may be
/// smaller.
///
/// The [FittedSizes.destination] size is the subpart of the `outputSize` in
/// which to paint the (possibly cropped) input image. If the
/// [FittedSizes.destination] size is smaller than the `outputSize` then the
/// input image is being letterboxed (or pillarboxed).
///
/// This method does not express an opinion regarding the alignment of the
/// source and destination sizes within the input and output rectangles.
/// Typically they are centered (this is what [BoxDecoration] does, for
/// instance, and is how [ImageFit] is defined). The [FractionalOffset] class
/// provides a convenience function, [FractionalOffset.inscribe], for resolving
/// the sizes to rects, as shown in the example below.
///
/// == Example ==
///
/// This example paints an [Image] `image` onto the [Rect] `outputRect` on a
/// [Canvas] `canvas`, using a [Paint] paint, applying the [ImageFit] algorithm
/// `fit`:
///
/// ```dart
/// final Size imageSize = new Size(image.width.toDouble(), image.height.toDouble());
/// final FittedSizes sizes = applyImageFit(fit, imageSize, outputRect.size);
/// final Rect inputSubrect = FractionalOffset.center.inscribe(sizes.source, Point.origin & imageSize);
/// final Rect outputSubrect = FractionalOffset.center.inscribe(sizes.destination, outputRect);
/// canvas.drawImageRect(image, inputSubrect, outputSubrect, paint);
/// ```
FittedSizes applyImageFit(ImageFit fit, Size inputSize, Size outputSize) {
  Size sourceSize, destinationSize;
  switch (fit) {
    case ImageFit.fill:
      sourceSize = inputSize;
      destinationSize = outputSize;
      break;
    case ImageFit.contain:
      sourceSize = inputSize;
      if (outputSize.width / outputSize.height > sourceSize.width / sourceSize.height)
        destinationSize = new Size(sourceSize.width * outputSize.height / sourceSize.height, outputSize.height);
      else
        destinationSize = new Size(outputSize.width, sourceSize.height * outputSize.width / sourceSize.width);
      break;
    case ImageFit.cover:
      if (outputSize.width / outputSize.height > inputSize.width / inputSize.height) {
        sourceSize = new Size(inputSize.width, inputSize.width * outputSize.height / outputSize.width);
      } else {
        sourceSize = new Size(inputSize.height * outputSize.width / outputSize.height, inputSize.height);
      }
      destinationSize = outputSize;
      break;
    case ImageFit.fitWidth:
      sourceSize = new Size(inputSize.width, inputSize.width * outputSize.height / outputSize.width);
      destinationSize = new Size(outputSize.width, sourceSize.height * outputSize.width / sourceSize.width);
      break;
    case ImageFit.fitHeight:
      sourceSize = new Size(inputSize.height * outputSize.width / outputSize.height, inputSize.height);
      destinationSize = new Size(sourceSize.width * outputSize.height / sourceSize.height, outputSize.height);
      break;
    case ImageFit.none:
      sourceSize = new Size(math.min(inputSize.width, outputSize.width),
                            math.min(inputSize.height, outputSize.height));
      destinationSize = sourceSize;
      break;
    case ImageFit.scaleDown:
      sourceSize = inputSize;
      destinationSize = inputSize;
      final double aspectRatio = inputSize.width / inputSize.height;
      if (destinationSize.height > outputSize.height)
        destinationSize = new Size(outputSize.height * aspectRatio, outputSize.height);
      if (destinationSize.width > outputSize.width)
        destinationSize = new Size(outputSize.width, outputSize.width / aspectRatio);
      break;
  }
  return new FittedSizes(sourceSize, destinationSize);
}
