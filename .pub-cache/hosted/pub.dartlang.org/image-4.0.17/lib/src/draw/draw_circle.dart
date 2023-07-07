import '../color/channel.dart';
import '../color/color.dart';
import '../image/image.dart';
import '_calculate_circumference.dart';
import '_draw_antialias_circle.dart';
import 'draw_pixel.dart';

/// Draw a circle into the [image] with a center of [x],[y] and
/// the given [radius] and [color].
Image drawCircle(Image image,
    {required int x,
    required int y,
    required int radius,
    required Color color,
    bool antialias = false,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  if (antialias) {
    return drawAntialiasCircle(image,
        x: x,
        y: y,
        radius: radius,
        color: color,
        mask: mask,
        maskChannel: maskChannel);
  }

  final points = calculateCircumference(image, x, y, radius);
  for (final pt in points) {
    drawPixel(image, pt.xi, pt.yi, color, mask: mask, maskChannel: maskChannel);
  }
  return image;
}
