import 'dart:math';

import '../image.dart';
import '../internal/clamp.dart';
import 'grayscale.dart';

/// Apply Sobel edge detection filtering to the [src] Image.
Image sobel(Image src, {num amount = 1.0}) {
  final num invAmount = 1.0 - amount;
  final orig = grayscale(Image.from(src));
  final origRGBA = orig.getBytes();
  final rowSize = src.width * 4;
  final List<int> rgba = src.getBytes();
  final rgbaLen = rgba.length;
  for (var y = 0, pi = 0; y < src.height; ++y) {
    for (var x = 0; x < src.width; ++x, pi += 4) {
      final bl = pi + rowSize - 4;
      final b = pi + rowSize;
      final br = pi + rowSize + 4;
      final l = pi - 4;
      final r = pi + 4;
      final tl = pi - rowSize - 4;
      final t = pi - rowSize;
      final tr = pi - rowSize + 4;

      final num tlInt = tl < 0 ? 0.0 : origRGBA[tl] / 255.0;
      final num tInt = t < 0 ? 0.0 : origRGBA[t] / 255.0;
      final num trInt = tr < 0 ? 0.0 : origRGBA[tr] / 255.0;
      final num lInt = l < 0 ? 0.0 : origRGBA[l] / 255.0;
      final num rInt = r < rgbaLen ? origRGBA[r] / 255.0 : 0.0;
      final num blInt = bl < rgbaLen ? origRGBA[bl] / 255.0 : 0.0;
      final num bInt = b < rgbaLen ? origRGBA[b] / 255.0 : 0.0;
      final num brInt = br < rgbaLen ? origRGBA[br] / 255.0 : 0.0;

      final num h = -tlInt - 2.0 * tInt - trInt + blInt + 2.0 * bInt + brInt;
      final num v = -blInt - 2.0 * lInt - tlInt + brInt + 2.0 * rInt + trInt;

      final mag = clamp255((sqrt(h * h + v * v) * 255.0).toInt());

      rgba[pi] = clamp255((mag * amount + rgba[pi] * invAmount).toInt());
      rgba[pi + 1] =
          clamp255((mag * amount + rgba[pi + 1] * invAmount).toInt());
      rgba[pi + 2] =
          clamp255((mag * amount + rgba[pi + 2] * invAmount).toInt());
    }
  }

  return src;
}
