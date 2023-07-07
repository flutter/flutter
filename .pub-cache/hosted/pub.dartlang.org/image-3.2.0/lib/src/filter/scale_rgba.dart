import '../image.dart';

Image scaleRgba(Image src, int r, int g, int b, int a) {
  final num dr = r / 255.0;
  final num dg = g / 255.0;
  final num db = b / 255.0;
  final num da = a / 255.0;
  final bytes = src.getBytes();
  for (var i = 0, len = bytes.length; i < len; i += 4) {
    bytes[i] = (bytes[i] * dr).floor();
    bytes[i + 1] = (bytes[i + 1] * dg).floor();
    bytes[i + 2] = (bytes[i + 2] * db).floor();
    bytes[i + 3] = (bytes[i + 3] * da).floor();
  }
  return src;
}
