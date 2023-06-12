import 'dart:typed_data';

import '../../../image.dart';
import '../../color.dart';

class GifColorMap {
  int bitsPerPixel;
  int numColors;
  int? transparent;
  final Uint8List colors;

  GifColorMap(this.numColors)
      : colors = Uint8List(numColors * 3),
        bitsPerPixel = _bitSize(numColors);

  GifColorMap.from(GifColorMap other)
    : bitsPerPixel = other.bitsPerPixel
    , numColors = other.numColors
    , transparent = other.transparent
    , colors = Uint8List.fromList(other.colors);

  int operator [](int index) => colors[index];

  operator []=(int index, int value) => colors[index] = value;

  int color(int index) {
    final ci = index * 3;
    final a = (index == transparent) ? 0 : 255;
    return getColor(colors[ci], colors[ci + 1], colors[ci + 2], a);
  }

  void setColor(int index, int r, int g, int b) {
    final ci = index * 3;
    colors[ci] = r;
    colors[ci + 1] = g;
    colors[ci + 2] = b;
  }

  int red(int color) => colors[color * 3];

  int green(int color) => colors[color * 3 + 1];

  int blue(int color) => colors[color * 3 + 2];

  int alpha(int color) => (color == transparent) ? 0 : 255;

  static int _bitSize(int n) {
    for (var i = 1; i <= 8; i++) {
      if ((1 << i) >= n) {
        return i;
      }
    }
    return 0;
  }
}
