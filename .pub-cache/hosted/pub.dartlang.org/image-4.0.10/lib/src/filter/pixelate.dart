import '../color/channel.dart';
import '../image/image.dart';
import '../util/math_util.dart';

enum PixelateMode {
  /// Use the top-left pixel of a block for the block color.
  upperLeft,

  /// Use the average of the pixels within a block for the block color.
  average
}

/// Pixelate the [src] image.
///
/// [size] determines the size of the pixelated blocks.
/// If [mode] is [PixelateMode.upperLeft] then the upper-left corner of the
/// block will be used for the block color. Otherwise if [mode] is
/// [PixelateMode.average], the average of all the pixels in the block will be
/// used for the block color.
Image pixelate(Image src,
    {required int size,
    PixelateMode mode = PixelateMode.upperLeft,
    num amount = 1,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  if (size <= 1) {
    return src;
  }

  for (final frame in src.frames) {
    final w = frame.width;
    final h = frame.height;
    switch (mode) {
      case PixelateMode.upperLeft:
        for (final p in frame) {
          final x2 = (p.x ~/ size) * size;
          final y2 = (p.y ~/ size) * size;
          final p2 = frame.getPixel(x2, y2);
          final msk =
              mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
          final mx = (msk ?? 1) * amount;
          if (mx == 1) {
            p.set(p2);
          } else {
            p
              ..r = mix(p.r, p2.r, mx)
              ..g = mix(p.g, p2.g, mx)
              ..b = mix(p.b, p2.b, mx)
              ..a = mix(p.a, p2.a, mx);
          }
        }
        break;
      case PixelateMode.average:
        num r = 0;
        num g = 0;
        num b = 0;
        num a = 0;
        var lx = -1;
        var ly = -1;
        for (final p in frame) {
          final x2 = (p.x ~/ size) * size;
          final y2 = (p.y ~/ size) * size;
          final msk =
              mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
          final mx = (msk ?? 1) * amount;
          if (x2 != lx || y2 <= ly) {
            lx = x2;
            ly = y2;
            r = 0;
            g = 0;
            b = 0;
            a = 0;
            for (var by = 0, by2 = y2; by < size && by2 < h; ++by, ++by2) {
              for (var bx = 0, bx2 = x2; bx < size && bx2 < w; ++bx, ++bx2) {
                final p2 = frame.getPixel(bx2, by2);
                r += p2.r;
                g += p2.g;
                b += p2.b;
                a += p2.a;
              }
            }
            final total = size * size;
            r /= total;
            g /= total;
            b /= total;
            a /= total;
          }

          p
            ..r = mix(p.r, r, mx)
            ..g = mix(p.g, g, mx)
            ..b = mix(p.b, b, mx)
            ..a = mix(p.a, a, mx);
        }
        break;
    }
  }
  return src;
}
