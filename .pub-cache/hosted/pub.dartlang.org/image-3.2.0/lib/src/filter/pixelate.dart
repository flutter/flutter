import '../color.dart';
import '../draw/fill_rect.dart';
import '../image.dart';

enum PixelateMode {
  /// Use the top-left pixel of a block for the block color.
  upperLeft,

  /// Use the average of the pixels within a block for the block color.
  average
}

/// Pixelate the [src] image.
///
/// [blockSize] determines the size of the pixelated blocks.
/// If [mode] is [PixelateMode.upperLeft] then the upper-left corner of the block
/// will be used for the block color. Otherwise if [mode] is [PixelateMode.average],
/// the average of all the pixels in the block will be used for the block color.
Image pixelate(Image src, int blockSize,
    {PixelateMode mode = PixelateMode.upperLeft}) {
  if (blockSize <= 1) {
    return src;
  }

  final bs = blockSize - 1;

  switch (mode) {
    case PixelateMode.upperLeft:
      for (var y = 0; y < src.height; y += blockSize) {
        for (var x = 0; x < src.width; x += blockSize) {
          if (src.boundsSafe(x, y)) {
            final c = src.getPixel(x, y);
            fillRect(src, x, y, x + bs, y + bs, c);
          }
        }
      }
      break;
    case PixelateMode.average:
      for (var y = 0; y < src.height; y += blockSize) {
        for (var x = 0; x < src.width; x += blockSize) {
          var a = 0;
          var r = 0;
          var g = 0;
          var b = 0;
          var total = 0;

          for (var cy = 0; cy < blockSize; ++cy) {
            for (var cx = 0; cx < blockSize; ++cx) {
              if (!src.boundsSafe(x + cx, y + cy)) {
                continue;
              }
              final c = src.getPixel(x + cx, y + cy);
              a += getAlpha(c);
              r += getRed(c);
              g += getGreen(c);
              b += getBlue(c);
              total++;
            }
          }

          if (total > 0) {
            final c = getColor(r ~/ total, g ~/ total, b ~/ total, a ~/ total);
            fillRect(src, x, y, x + bs, y + bs, c);
          }
        }
      }
      break;
  }

  return src;
}
