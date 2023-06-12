import '../color.dart';
import '../image.dart';
import '../internal/clamp.dart';

/// Apply sepia tone to the image.
///
/// [amount] controls the strength of the effect, in the range 0.0 - 1.0.
Image sepia(Image src, {num amount = 1.0}) {
  if (amount == 0) {
    return src;
  }

  final p = src.getBytes();
  for (var i = 0, len = p.length; i < len; i += 4) {
    final r = p[i];
    final g = p[i + 1];
    final b = p[i + 2];
    final y = getLuminanceRgb(r, g, b);
    p[i] = clamp255(((amount * (y + 38)) + ((1.0 - amount) * r)).toInt());
    p[i + 1] = clamp255(((amount * (y + 18)) + ((1.0 - amount) * g)).toInt());
    p[i + 2] = clamp255(((amount * (y - 31)) + ((1.0 - amount) * b)).toInt());
  }

  return src;
}
