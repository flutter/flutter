import 'dart:math';

import '../image.dart';
import 'draw_line.dart';

/// Draw a rectangle in the image [dst] with the [color].
Image drawRect(Image dst, int x1, int y1, int x2, int y2, int color) {
  final x0 = min(x1, x2);
  final y0 = min(y1, y2);
  x1 = max(x1, x2);
  y1 = max(y1, y2);

  drawLine(dst, x0, y0, x1, y0, color);
  drawLine(dst, x1, y0, x1, y1, color);
  drawLine(dst, x0, y1, x1, y1, color);
  drawLine(dst, x0, y0, x0, y1, color);

  return dst;
}
