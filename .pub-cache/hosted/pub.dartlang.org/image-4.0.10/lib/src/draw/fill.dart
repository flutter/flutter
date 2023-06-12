import '../color/channel.dart';
import '../color/color.dart';
import '../image/image.dart';
import '../util/math_util.dart';

/// Set all of the pixels of an [image] to the given [color].
Image fill(Image image,
    {required Color color,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  if (mask == null) {
    return image..clear(color);
  }

  for (final p in image) {
    final maskValue = mask.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
    p
      ..r = mix(p.r, color.r, maskValue)
      ..g = mix(p.g, color.g, maskValue)
      ..b = mix(p.b, color.b, maskValue)
      ..a = mix(p.a, color.a, maskValue);
  }

  return image;
}
