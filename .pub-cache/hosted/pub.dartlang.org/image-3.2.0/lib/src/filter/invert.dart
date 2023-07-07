import '../image.dart';

/// Invert the colors of the [src] image.
Image invert(Image src) {
  final p = src.getBytes();
  for (var i = 0, len = p.length; i < len; i += 4) {
    p[i] = 255 - p[i];
    p[i + 1] = 255 - p[i + 1];
    p[i + 2] = 255 - p[i + 2];
  }
  return src;
}
