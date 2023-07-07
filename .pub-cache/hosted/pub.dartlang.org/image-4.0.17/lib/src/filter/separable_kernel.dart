import '../color/channel.dart';
import '../image/image.dart';
import '../util/math_util.dart';

/// A kernel object to use with separableConvolution filtering.
class SeparableKernel {
  final List<num> coefficients;
  final int size;

  /// Create a separable convolution kernel for the given [size].
  SeparableKernel(this.size) : coefficients = List<num>.filled(2 * size + 1, 0);

  /// Get the number of coefficients in the kernel.
  int get length => coefficients.length;

  /// Get a coefficient from the kernel.
  num operator [](int index) => coefficients[index];

  /// Set a coefficient in the kernel.
  void operator []=(int index, num c) {
    coefficients[index] = c;
  }

  /// Apply the kernel to the [src] image, storing the results in [dst],
  /// for a single dimension. If [horizontal is true, the filter will be
  /// applied to the horizontal axis, otherwise it will be applied to the
  /// vertical axis.
  void apply(Image src, Image dst,
      {bool horizontal = true,
      Image? mask,
      Channel maskChannel = Channel.luminance}) {
    if (horizontal) {
      for (var y = 0; y < src.height; ++y) {
        _applyCoefficientsLine(
            src, dst, y, src.width, horizontal, mask, maskChannel);
      }
    } else {
      for (var x = 0; x < src.width; ++x) {
        _applyCoefficientsLine(
            src, dst, x, src.height, horizontal, mask, maskChannel);
      }
    }
  }

  /// Scale all of the coefficients by [s].
  void scaleCoefficients(num s) {
    for (var i = 0; i < coefficients.length; ++i) {
      coefficients[i] = coefficients[i] * s;
    }
  }

  int _reflect(int max, int x) {
    if (x < 0) {
      return -x;
    }
    if (x >= max) {
      return max - (x - max) - 1;
    }
    return x;
  }

  void _applyCoefficientsLine(Image src, Image dst, int y, int width,
      bool horizontal, Image? mask, Channel maskChannel) {
    for (var x = 0; x < width; x++) {
      num r = 0.0;
      num g = 0.0;
      num b = 0.0;
      num a = 0.0;

      for (var j = -size, j2 = 0; j <= size; ++j, ++j2) {
        final c = coefficients[j2];
        final gr = _reflect(width, x + j);

        final sc = horizontal ? src.getPixel(gr, y) : src.getPixel(y, gr);

        r += c * sc.r;
        g += c * sc.g;
        b += c * sc.b;
        a += c * sc.a;
      }

      final p = horizontal ? dst.getPixel(x, y) : dst.getPixel(y, x);

      final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
      if (msk == null) {
        p.setRgba(r, g, b, a);
      } else {
        p
          ..r = mix(p.r, r, msk)
          ..g = mix(p.g, g, msk)
          ..b = mix(p.b, b, msk)
          ..a = mix(p.a, a, msk);
      }
    }
  }
}
