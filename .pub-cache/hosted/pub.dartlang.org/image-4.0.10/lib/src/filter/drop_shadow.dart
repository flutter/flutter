import '../color/channel.dart';
import '../color/color.dart';
import '../color/color_uint8.dart';
import '../draw/composite_image.dart';
import '../image/image.dart';
import 'gaussian_blur.dart';
import 'remap_colors.dart';
import 'scale_rgba.dart';

/// Create a drop-shadow effect for the image.
Image dropShadow(Image src, int hShadow, int vShadow, int blur,
    {Color? shadowColor}) {
  if (blur < 0) {
    blur = 0;
  }

  shadowColor ??= ColorRgba8(0, 0, 0, 128);

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

  final dst =
      Image(width: newImageWidth, height: newImageHeight, numChannels: 4)
        ..clear(ColorRgba8(255, 255, 255, 0));

  compositeImage(dst, src, dstX: shadowOffsetX, dstY: shadowOffsetY);

  remapColors(dst,
      red: Channel.alpha, green: Channel.alpha, blue: Channel.alpha);

  scaleRgba(dst, scale: shadowColor);

  gaussianBlur(dst, radius: blur);

  compositeImage(dst, src, dstX: imageOffsetX, dstY: imageOffsetY);

  return dst;
}
