import '../color.dart';
import '../image.dart';

/// Find the minimum and maximum color value in the image.
/// Returns a list as <[min], [max]>.
List<int> minMax(Image image) {
  var min = 255;
  var max = 0;
  final len = image.length;
  for (var i = 0; i < len; ++i) {
    final c = image[i];
    final r = getRed(c);
    final g = getGreen(c);
    final b = getBlue(c);

    if (r < min) {
      min = r;
    }
    if (r > max) {
      max = r;
    }
    if (g < min) {
      min = g;
    }
    if (g > max) {
      max = g;
    }
    if (b < min) {
      min = b;
    }
    if (b > max) {
      max = b;
    }
    if (image.channels == Channels.rgba) {
      final a = getAlpha(c);
      if (a < min) {
        min = a;
      }
      if (a > max) {
        max = a;
      }
    }
  }

  return [min, max];
}
