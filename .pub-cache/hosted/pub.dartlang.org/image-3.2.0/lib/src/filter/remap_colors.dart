import '../color.dart';
import '../image.dart';

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
  final l = [0, 0, 0, 0, 0];
  final p = src.getBytes();
  for (var i = 0, len = p.length; i < len; i += 4) {
    l[0] = p[i];
    l[1] = p[i + 1];
    l[2] = p[i + 2];
    l[3] = p[i + 3];
    if (red == Channel.luminance ||
        green == Channel.luminance ||
        blue == Channel.luminance ||
        alpha == Channel.luminance) {
      l[4] = getLuminanceRgb(l[0], l[1], l[2]);
    }
    p[i] = l[red.index];
    p[i + 1] = l[green.index];
    p[i + 2] = l[blue.index];
    p[i + 3] = l[alpha.index];
  }

  return src;
}
