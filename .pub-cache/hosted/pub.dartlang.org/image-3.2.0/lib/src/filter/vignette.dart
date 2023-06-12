import 'dart:math';

import '../image.dart';
import '../internal/clamp.dart';

num _smoothStep(num edge0, num edge1, num x) {
  x = ((x - edge0) / (edge1 - edge0));
  if (x < 0.0) {
    x = 0.0;
  }
  if (x > 1.0) {
    x = 1.0;
  }
  return x * x * (3.0 - 2.0 * x);
}

Image vignette(Image src, {num start = 0.3, num end = 0.75, num amount = 0.8}) {
  final h = src.height - 1;
  final w = src.width - 1;
  final num invAmt = 1.0 - amount;
  final p = src.getBytes();
  for (var y = 0, i = 0; y <= h; ++y) {
    final num dy = 0.5 - (y / h);
    for (var x = 0; x <= w; ++x, i += 4) {
      final num dx = 0.5 - (x / w);

      num d = sqrt(dx * dx + dy * dy);
      d = _smoothStep(end, start, d);

      p[i] = clamp255((amount * p[i] * d + invAmt * p[i]).toInt());
      p[i + 1] = clamp255((amount * p[i + 1] * d + invAmt * p[i + 1]).toInt());
      p[i + 2] = clamp255((amount * p[i + 2] * d + invAmt * p[i + 2]).toInt());
    }
  }

  return src;
}
