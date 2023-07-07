import '../image.dart';
import 'draw_pixel.dart';

/// Draw the image [src] onto the image [dst].
///
/// In other words, drawImage will take an rectangular area from src of
/// width [src_w] and height [src_h] at position ([src_x],[src_y]) and place it
/// in a rectangular area of [dst] of width [dst_w] and height [dst_h] at
/// position ([dst_x],[dst_y]).
///
/// If the source and destination coordinates and width and heights differ,
/// appropriate stretching or shrinking of the image fragment will be performed.
/// The coordinates refer to the upper left corner. This function can be used to
/// copy regions within the same image (if [dst] is the same as [src])
/// but if the regions overlap the results will be unpredictable.
Image drawImage(Image dst, Image src,
    {int? dstX,
    int? dstY,
    int? dstW,
    int? dstH,
    int? srcX,
    int? srcY,
    int? srcW,
    int? srcH,
    bool blend = true}) {
  dstX ??= 0;
  dstY ??= 0;
  srcX ??= 0;
  srcY ??= 0;
  srcW ??= src.width;
  srcH ??= src.height;
  dstW ??= (dst.width < src.width) ? dstW = dst.width : src.width;
  dstH ??= (dst.height < src.height) ? dst.height : src.height;

  if (blend) {
    for (var y = 0; y < dstH; ++y) {
      for (var x = 0; x < dstW; ++x) {
        final stepX = (x * (srcW / dstW)).toInt();
        final stepY = (y * (srcH / dstH)).toInt();
        final srcPixel = src.getPixel(srcX + stepX, srcY + stepY);
        drawPixel(dst, dstX + x, dstY + y, srcPixel);
      }
    }
  } else {
    for (var y = 0; y < dstH; ++y) {
      for (var x = 0; x < dstW; ++x) {
        final stepX = (x * (srcW / dstW)).toInt();
        final stepY = (y * (srcH / dstH)).toInt();
        final srcPixel = src.getPixel(srcX + stepX, srcY + stepY);
        dst.setPixel(dstX + x, dstY + y, srcPixel);
      }
    }
  }

  return dst;
}
