import 'dart:math';

import '../color/channel.dart';
import '../color/color.dart';
import '../image/image.dart';
import '_draw_antialias_circle.dart';
import 'draw_line.dart';

/// Draw a rectangle in the image [dst] with the [color].
Image drawRect(Image dst,
    {required int x1,
    required int y1,
    required int x2,
    required int y2,
    required Color color,
    num thickness = 1,
    num radius = 0,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  final x0 = min(x1, x2);
  final y0 = min(y1, y2);
  x1 = max(x1, x2);
  y1 = max(y1, y2);

  // Draw a rounded rectangle
  if (radius > 0) {
    final rad = radius.round();
    drawLine(dst, x1: x0 + rad, y1: y0, x2: x1 - rad, y2: y0, color: color);
    drawLine(dst, x1: x1, y1: y0 + rad, x2: x1, y2: y1 - rad, color: color);
    drawLine(dst, x1: x0 + rad, y1: y1, x2: x1 - rad, y2: y1, color: color);
    drawLine(dst, x1: x0, y1: y0 + rad, x2: x0, y2: y1 - rad, color: color);

    final c1x = x0 + rad;
    final c1y = y0 + rad;
    final c2x = x1 - rad;
    final c2y = y0 + rad;
    final c3x = x1 - rad;
    final c3y = y1 - rad;
    final c4x = x0 + rad;
    final c4y = y1 - rad;

    drawAntialiasCircle(dst,
        x: c1x,
        y: c1y,
        radius: rad,
        color: color,
        maskChannel: maskChannel,
        mask: mask,
        quadrants: topLeftQuadrant);

    drawAntialiasCircle(dst,
        x: c2x,
        y: c2y,
        radius: rad,
        color: color,
        maskChannel: maskChannel,
        mask: mask,
        quadrants: topRightQuadrant);

    drawAntialiasCircle(dst,
        x: c3x,
        y: c3y,
        radius: rad,
        color: color,
        maskChannel: maskChannel,
        mask: mask,
        quadrants: bottomRightQuadrant);

    drawAntialiasCircle(dst,
        x: c4x,
        y: c4y,
        radius: rad,
        color: color,
        maskChannel: maskChannel,
        mask: mask,
        quadrants: bottomLeftQuadrant);

    return dst;
  }

  final ht = thickness / 2;

  drawLine(dst,
      x1: x0,
      y1: y0,
      x2: x1,
      y2: y0,
      color: color,
      thickness: thickness,
      mask: mask,
      maskChannel: maskChannel);

  drawLine(dst,
      x1: x0,
      y1: y1,
      x2: x1,
      y2: y1,
      color: color,
      thickness: thickness,
      mask: mask,
      maskChannel: maskChannel);

  final isEvenThickness = (ht - ht.toInt()) == 0;
  final dh = isEvenThickness ? 1 : 0;

  final by0 = (y0 + ht).ceil();
  final by1 = ((y1 - ht) - dh).floor();
  final bx0 = (x0 + ht).floor();
  final bx1 = ((x1 - ht) + dh).ceil();

  drawLine(dst,
      x1: bx0,
      y1: by0,
      x2: bx0,
      y2: by1,
      color: color,
      thickness: thickness,
      mask: mask,
      maskChannel: maskChannel);

  drawLine(dst,
      x1: bx1,
      y1: by0,
      x2: bx1,
      y2: by1,
      color: color,
      thickness: thickness,
      mask: mask,
      maskChannel: maskChannel);

  return dst;
}
