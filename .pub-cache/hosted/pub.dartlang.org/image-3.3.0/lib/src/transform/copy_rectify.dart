import '../image.dart';
import '../util/point.dart';

/// Returns a copy of the [src] image, where the given rectangle
/// has been mapped to the full image.
Image copyRectify(Image src,
    {required Point topLeft,
    required Point topRight,
    required Point bottomLeft,
    required Point bottomRight,
    Image? toImage}) {
  final dst = toImage ?? Image.from(src);
  for (var y = 0; y < dst.height; ++y) {
    final v = y / (dst.height - 1);
    for (var x = 0; x < dst.width; ++x) {
      final u = x / (dst.width - 1);
      // bilinear interpolation
      final srcPixelCoord = topLeft * (1 - u) * (1 - v) +
          topRight * (u) * (1 - v) +
          bottomLeft * (1 - u) * (v) +
          bottomRight * (u) * (v);
      final srcPixel = src.getPixel(srcPixelCoord.xi, srcPixelCoord.yi);
      dst.setPixel(x, y, srcPixel);
    }
  }
  return dst;
}
