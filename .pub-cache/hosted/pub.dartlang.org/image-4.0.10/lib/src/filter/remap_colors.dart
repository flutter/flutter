import '../color/channel.dart';
import '../image/image.dart';
import '../util/color_util.dart';

/// Remap the color channels of the image.
/// [red], [green], [blue] and [alpha] should be set to one of the following:
/// [Channel.red], [Channel.green], [Channel.blue], [Channel.alpha], or
/// [Channel.luminance]. For example,
/// remapColors(src, red: Channel.green, green: Channel.red);
/// will swap the red and green channels of the image.
/// remapColors(src, alpha: Channel.luminance)
/// will set the alpha channel to the luminance (grayscale) of the image.
Image remapColors(Image src,
    {Channel red = Channel.red,
    Channel green = Channel.green,
    Channel blue = Channel.blue,
    Channel alpha = Channel.alpha}) {
  final List<num> l = [0, 0, 0, 0, 0];
  for (final frame in src.frames) {
    for (final p in frame) {
      l[0] = p.r;
      l[1] = p.g;
      l[2] = p.b;
      l[3] = p.a;
      if (red == Channel.luminance ||
          green == Channel.luminance ||
          blue == Channel.luminance ||
          alpha == Channel.luminance) {
        l[4] = getLuminanceRgb(l[0], l[1], l[2]);
      }
      p
        ..r = l[red.index]
        ..g = l[green.index]
        ..b = l[blue.index]
        ..a = l[alpha.index];
    }
  }
  return src;
}
