import 'dart:math';

import '../image.dart';
import 'separable_convolution.dart';
import 'separable_kernel.dart';

Map<int, SeparableKernel> _gaussianKernelCache = {};

/// Apply gaussian blur to the [src] image. [radius] determines how many pixels
/// away from the current pixel should contribute to the blur, where 0 is no
/// blur and the larger the radius, the stronger the blur.
Image gaussianBlur(Image src, int radius) {
  if (radius <= 0) {
    return src;
  }

  SeparableKernel kernel;

  if (_gaussianKernelCache.containsKey(radius)) {
    kernel = _gaussianKernelCache[radius]!;
  } else {
    // Compute coefficients
    final num sigma = radius * (2.0 / 3.0);
    final num s = 2.0 * sigma * sigma;

    kernel = SeparableKernel(radius);

    num sum = 0.0;
    for (var x = -radius; x <= radius; ++x) {
      final num c = exp(-(x * x) / s);
      sum += c;
      kernel[x + radius] = c;
    }
    // Normalize the coefficients
    kernel.scaleCoefficients(1.0 / sum);

    // Cache the kernel for this radius so we don't have to recompute it
    // next time.
    _gaussianKernelCache[radius] = kernel;
  }

  return separableConvolution(src, kernel);
}
