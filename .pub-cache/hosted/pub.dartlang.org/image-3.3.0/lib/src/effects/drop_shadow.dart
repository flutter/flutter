import '../color.dart';
import '../filter/gaussian_blur.dart';
import '../filter/remap_colors.dart';
import '../filter/scale_rgba.dart';
import '../image.dart';
import '../transform/copy_into.dart';

/// Create a drop-shadow effect for the image.
Image dropShadow(Image src, int hShadow, int vShadow, int blur,
    {int shadowColor = 0xa0000000}) {
  if (blur < 0) {
    blur = 0;
  }

  final shadowWidth = src.width + blur * 2;
  final shadowHeight = src.height + blur * 2;
  var shadowOffsetX = -blur;
  var shadowOffsetY = -blur;

  var newImageWidth = shadowWidth;
  var newImageHeight = shadowHeight;
  var imageOffsetX = 0;
  var imageOffsetY = 0;

  if (shadowOffsetX + hShadow < 0) {
    imageOffsetX = -(shadowOffsetX + hShadow);
    shadowOffsetX = -shadowOffsetX;
    newImageWidth = imageOffsetX;
  }

  if (shadowOffsetY + vShadow < 0) {
    imageOffsetY = -(shadowOffsetY + vShadow);
    shadowOffsetY = -shadowOffsetY;
    newImageHeight += imageOffsetY;
  }

  if (shadowWidth + shadowOffsetX + hShadow > newImageWidth) {
    newImageWidth = shadowWidth + shadowOffsetX + hShadow;
  }

  if (shadowHeight + shadowOffsetY + vShadow > newImageHeight) {
    newImageHeight = shadowHeight + shadowOffsetY + vShadow;
  }

  final dst = Image(newImageWidth, newImageHeight);
  dst.fill(0x00ffffff);

  copyInto(dst, src, dstX: shadowOffsetX, dstY: shadowOffsetY);

  remapColors(dst,
      red: Channel.alpha, green: Channel.alpha, blue: Channel.alpha);

  scaleRgba(dst, getRed(shadowColor), getGreen(shadowColor),
      getBlue(shadowColor), getAlpha(shadowColor));

  gaussianBlur(dst, blur);

  copyInto(dst, src, dstX: imageOffsetX, dstY: imageOffsetY);

  return dst;
}
