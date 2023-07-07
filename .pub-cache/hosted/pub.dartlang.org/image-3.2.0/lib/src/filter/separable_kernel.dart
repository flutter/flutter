import '../color.dart';
import '../image.dart';

/// A kernel object to use with [separableConvolution] filtering.
class SeparableKernel {
  final List<num> coefficients;
  final int size;

  /// Create a separable convolution kernel for the given [radius].
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
  /// applied to the horizontal axis, otherwise it will be appied to the
  /// vertical axis.
  void apply(Image src, Image dst, {bool horizontal = true}) {
    if (horizontal) {
      for (var y = 0; y < src.height; ++y) {
        _applyCoeffsLine(src, dst, y, src.width, horizontal);
      }
    } else {
      for (var x = 0; x < src.width; ++x) {
        _applyCoeffsLine(src, dst, x, src.height, horizontal);
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

  void _applyCoeffsLine(
      Image src, Image dst, int y, int width, bool horizontal) {
    for (var x = 0; x < width; x++) {
      num r = 0.0;
      num g = 0.0;
      num b = 0.0;
      num a = 0.0;

      for (var j = -size, j2 = 0; j <= size; ++j, ++j2) {
        final coeff = coefficients[j2];
        final gr = _reflect(width, x + j);

        final sc = (horizontal) ? src.getPixel(gr, y) : src.getPixel(y, gr);

        r += coeff * getRed(sc);
        g += coeff * getGreen(sc);
        b += coeff * getBlue(sc);
        a += coeff * getAlpha(sc);
      }

      final c = getColor(
          (r > 255.0 ? 255.0 : r).toInt(),
          (g > 255.0 ? 255.0 : g).toInt(),
          (b > 255.0 ? 255.0 : b).toInt(),
          (a > 255.0 ? 255.0 : a).toInt());

      if (horizontal) {
        dst.setPixel(x, y, c);
      } else {
        dst.setPixel(y, x, c);
      }
    }
  }
}
