import '../draw/draw_pixel.dart';
import '../image.dart';

/// Copies a rectangular portion of one image to another image. [dst] is the
/// destination image, [src] is the source image identifier.
///
/// In other words, copyInto will take an rectangular area from src of
/// width [src_w] and height [src_h] at position ([src_x],[src_y]) and place it
/// in a rectangular area of [dst] of width [dst_w] and height [dst_h] at
/// position ([dst_x],[dst_y]).
///
/// If the source and destination coordinates and width and heights differ,
/// appropriate stretching or shrinking of the image fragment will be performed.
/// The coordinates refer to the upper left corner. This function can be used to
/// copy regions within the same image (if [dst] is the same as [src])
/// but if the regions overlap the results will be unpredictable.
///
/// [dstX] and [dstY] represent the X and Y position where the [src] will start
/// printing.
///
/// if [center] is true, the [src] will be centered in [dst].
Image copyInto(
  Image dst,
  Image src, {
  int? dstX,
  int? dstY,
  int? srcX,
  int? srcY,
  int? srcW,
  int? srcH,
  bool blend = true,
  bool center = false,
}) {
  dstX ??= 0;
  dstY ??= 0;
  srcX ??= 0;
  srcY ??= 0;
  srcW ??= src.width;
  srcH ??= src.height;

  if (center) {
    {
      // if [src] is wider than [dst]
      var wdt = (dst.width - src.width);
      if (wdt < 0) wdt = 0;
      dstX = wdt ~/ 2;
    }
    {
      // if [src] is higher than [dst]
      var hight = (dst.height - src.height);
      if (hight < 0) hight = 0;
      dstY = hight ~/ 2;
    }
  }

  if (blend) {
    for (var y = 0; y < srcH; ++y) {
      for (var x = 0; x < srcW; ++x) {
        drawPixel(dst, dstX + x, dstY + y, src.getPixel(srcX + x, srcY + y));
      }
    }
  } else {
    for (var y = 0; y < srcH; ++y) {
      for (var x = 0; x < srcW; ++x) {
        dst.setPixel(dstX + x, dstY + y, src.getPixel(srcX + x, srcY + y));
      }
    }
  }

  return dst;
}
