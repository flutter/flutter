import 'dart:math';

import '../color/channel.dart';
import '../color/color.dart';
import '../image/image.dart';
import '../util/math_util.dart';
import 'draw_pixel.dart';

const topLeftQuadrant = 1;
const topRightQuadrant = 2;
const bottomLeftQuadrant = 4;
const bottomRightQuadrant = 8;
const allQuadrants = topLeftQuadrant |
    topRightQuadrant |
    bottomLeftQuadrant |
    bottomRightQuadrant;

Image drawAntialiasCircle(Image image,
    {required int x,
    required int y,
    required int radius,
    required Color color,
    int quadrants = allQuadrants,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  void drawPixel4(int x, int y, int dx, int dy, num alpha) {
    // bottom right
    if (quadrants & bottomRightQuadrant != 0) {
      drawPixel(image, x + dx, y + dy, color,
          alpha: alpha, mask: mask, maskChannel: maskChannel);
    }

    // bottom left
    if (quadrants & bottomLeftQuadrant != 0) {
      drawPixel(image, x - dx, y + dy, color,
          alpha: alpha, mask: mask, maskChannel: maskChannel);
    }

    // upper right
    if (quadrants & topRightQuadrant != 0) {
      drawPixel(image, x + dx, y - dy, color,
          alpha: alpha, mask: mask, maskChannel: maskChannel);
    }

    // upper left
    if (quadrants & topLeftQuadrant != 0) {
      drawPixel(image, x - dx, y - dy, color,
          alpha: alpha, mask: mask, maskChannel: maskChannel);
    }
  }

  final radiusSqr = radius * radius;

  final quarter = (radius / sqrt2).round();
  for (var i = 0; i <= quarter; ++i) {
    final j = sqrt(radiusSqr - (i * i));
    final frc = fract(j);
    final frc2 = frc * ((i == quarter) ? 0.25 : 1);
    final flr = j.floor();
    drawPixel4(x, y, i, flr, 1 - frc);
    drawPixel4(x, y, i, flr + 1, frc2);
    drawPixel4(x, y, flr, i, 1 - frc);
    drawPixel4(x, y, flr + 1, i, frc2);
  }

  return image;
}
