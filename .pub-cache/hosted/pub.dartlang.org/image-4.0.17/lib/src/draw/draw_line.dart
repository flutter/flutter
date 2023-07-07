import 'dart:math';

import '../color/channel.dart';
import '../color/color.dart';
import '../image/image.dart';
import '../util/clip_line.dart';
import 'draw_pixel.dart';
import 'fill_circle.dart';

/// Draw a line into [image].
///
/// If [antialias] is true then the line is drawn with smooth edges.
/// [thickness] determines how thick the line should be drawn, in pixels.
Image drawLine(Image image,
    {required int x1,
    required int y1,
    required int x2,
    required int y2,
    required Color color,
    bool antialias = false,
    num thickness = 1,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  final line = [x1, y1, x2, y2];
  if (!clipLine(line, [0, 0, image.width - 1, image.height - 1])) {
    return image;
  }

  x1 = line[0];
  y1 = line[1];
  x2 = line[2];
  y2 = line[3];

  var dx = x2 - x1;
  var dy = y2 - y1;

  final radius = (thickness / 2.0).floor();

  // Drawing a single point.
  if (dx == 0 && dy == 0) {
    thickness == 1
        ? drawPixel(image, x1, y1, color, mask: mask, maskChannel: maskChannel)
        : fillCircle(image,
            x: x1,
            y: y1,
            radius: radius,
            color: color,
            mask: mask,
            maskChannel: maskChannel);
    return image;
  }

  // Axis-aligned lines
  if (dx == 0) {
    if (dy < 0) {
      for (var y = y2; y <= y1; ++y) {
        if (thickness <= 1) {
          drawPixel(image, x1, y, color, mask: mask, maskChannel: maskChannel);
        } else {
          for (var i = 0; i < thickness; i++) {
            drawPixel(image, x1 - radius + i, y, color,
                mask: mask, maskChannel: maskChannel);
          }
        }
      }
    } else {
      for (var y = y1; y <= y2; ++y) {
        if (thickness <= 1) {
          drawPixel(image, x1, y, color, mask: mask, maskChannel: maskChannel);
        } else {
          for (var i = 0; i < thickness; i++) {
            drawPixel(image, x1 - radius + i, y, color,
                mask: mask, maskChannel: maskChannel);
          }
        }
      }
    }
    return image;
  } else if (dy == 0) {
    if (dx < 0) {
      for (var x = x2; x <= x1; ++x) {
        if (thickness <= 1) {
          drawPixel(image, x, y1, color, mask: mask, maskChannel: maskChannel);
        } else {
          for (var i = 0; i < thickness; i++) {
            drawPixel(image, x, y1 - radius + i, color,
                mask: mask, maskChannel: maskChannel);
          }
        }
      }
    } else {
      for (var x = x1; x <= x2; ++x) {
        if (thickness <= 1) {
          drawPixel(image, x, y1, color, mask: mask, maskChannel: maskChannel);
        } else {
          for (var i = 0; i < thickness; i++) {
            drawPixel(image, x, y1 - radius + i, color,
                mask: mask, maskChannel: maskChannel);
          }
        }
      }
    }
    return image;
  }

  // 16-bit unsigned int xor.
  int xor(int n) => (~n + 0x10000) & 0xffff;

  if (!antialias) {
    dx = dx.abs();
    dy = dy.abs();
    if (dy <= dx) {
      // More-or-less horizontal. use wid for vertical stroke
      final num ac = cos(atan2(dy, dx));
      int wid;
      if (ac != 0) {
        wid = thickness ~/ ac;
      } else {
        wid = 1;
      }

      if (wid == 0) {
        wid = 1;
      }

      var d = 2 * dy - dx;
      final incr1 = 2 * dy;
      final incr2 = 2 * (dy - dx);

      int x, y;
      int ydirflag;
      int xend;
      if (x1 > x2) {
        x = x2;
        y = y2;
        ydirflag = -1;
        xend = x1;
      } else {
        x = x1;
        y = y1;
        ydirflag = 1;
        xend = x2;
      }

      // Set up line thickness
      var wstart = (y - wid / 2).toInt();
      for (var w = wstart; w < wstart + wid; w++) {
        drawPixel(image, x, w, color, mask: mask, maskChannel: maskChannel);
      }

      if (((y2 - y1) * ydirflag) > 0) {
        while (x < xend) {
          x++;
          if (d < 0) {
            d += incr1;
          } else {
            y++;
            d += incr2;
          }
          wstart = (y - wid / 2).toInt();
          for (var w = wstart; w < wstart + wid; w++) {
            drawPixel(image, x, w, color, mask: mask, maskChannel: maskChannel);
          }
        }
      } else {
        while (x < xend) {
          x++;
          if (d < 0) {
            d += incr1;
          } else {
            y--;
            d += incr2;
          }
          wstart = (y - wid / 2).toInt();
          for (var w = wstart; w < wstart + wid; w++) {
            drawPixel(image, x, w, color, mask: mask, maskChannel: maskChannel);
          }
        }
      }
    } else {
      // More-or-less vertical. use wid for horizontal stroke
      final as = sin(atan2(dy, dx));
      int wid;
      if (as != 0) {
        wid = thickness ~/ as;
      } else {
        wid = 1;
      }
      if (wid == 0) {
        wid = 1;
      }

      var d = 2 * dx - dy;
      final incr1 = 2 * dx;
      final incr2 = 2 * (dx - dy);
      int x, y;
      int yend;
      int xdirflag;
      if (y1 > y2) {
        y = y2;
        x = x2;
        yend = y1;
        xdirflag = -1;
      } else {
        y = y1;
        x = x1;
        yend = y2;
        xdirflag = 1;
      }

      // Set up line thickness
      var wstart = (x - wid / 2).toInt();
      for (var w = wstart; w < wstart + wid; w++) {
        drawPixel(image, w, y, color, mask: mask, maskChannel: maskChannel);
      }

      if (((x2 - x1) * xdirflag) > 0) {
        while (y < yend) {
          y++;
          if (d < 0) {
            d += incr1;
          } else {
            x++;
            d += incr2;
          }
          wstart = (x - wid / 2).toInt();
          for (var w = wstart; w < wstart + wid; w++) {
            drawPixel(image, w, y, color, mask: mask, maskChannel: maskChannel);
          }
        }
      } else {
        while (y < yend) {
          y++;
          if (d < 0) {
            d += incr1;
          } else {
            x--;
            d += incr2;
          }
          wstart = (x - wid / 2).toInt();
          for (var w = wstart; w < wstart + wid; w++) {
            drawPixel(image, w, y, color, mask: mask, maskChannel: maskChannel);
          }
        }
      }
    }

    return image;
  }

  // Antialias Line
  if (thickness == 1) {
    return _drawLineWu(image, x1: x1, y1: y1, x2: x2, y2: y2, color: color);
  }

  final ag = (dy.abs() < dx.abs()) ? cos(atan2(dy, dx)) : sin(atan2(dy, dx));

  int wid;
  if (ag != 0.0) {
    wid = (thickness / ag).abs().toInt();
  } else {
    wid = 1;
  }
  if (wid == 0) {
    wid = 1;
  }

  if (dx.abs() > dy.abs()) {
    if (dx < 0) {
      var tmp = x1;
      x1 = x2;
      x2 = tmp;
      tmp = y1;
      y1 = y2;
      y2 = tmp;
      dx = x2 - x1;
      dy = y2 - y1;
    }

    var y = y1;
    final inc = (dy * 65536) ~/ dx;
    var frac = 0;

    for (var x = x1; x <= x2; x++) {
      final wstart = y - wid ~/ 2;
      for (var w = wstart; w < wstart + wid; w++) {
        drawPixel(image, x, w, color,
            alpha: ((frac >> 8) & 0xff) / 255,
            mask: mask,
            maskChannel: maskChannel);

        drawPixel(image, x, w + 1, color,
            alpha: ((xor(frac) >> 8) & 0xff) / 255,
            mask: mask,
            maskChannel: maskChannel);
      }

      frac += inc;
      if (frac >= 65536) {
        frac -= 65536;
        y++;
      } else if (frac < 0) {
        frac += 65536;
        y--;
      }
    }
  } else {
    if (dy < 0) {
      var tmp = x1;
      x1 = x2;
      x2 = tmp;
      tmp = y1;
      y1 = y2;
      y2 = tmp;
      dx = x2 - x1;
      dy = y2 - y1;
    }

    var x = x1;
    final inc = (dx * 65536) ~/ dy;
    var frac = 0;

    for (var y = y1; y <= y2; y++) {
      final wstart = x - wid ~/ 2;
      for (var w = wstart; w < wstart + wid; w++) {
        drawPixel(image, w, y, color,
            alpha: ((frac >> 8) & 0xff) / 255,
            mask: mask,
            maskChannel: maskChannel);

        drawPixel(image, w + 1, y, color,
            alpha: ((xor(frac) >> 8) & 0xff) / 255,
            mask: mask,
            maskChannel: maskChannel);
      }

      frac += inc;
      if (frac >= 65536) {
        frac -= 65536;
        x++;
      } else if (frac < 0) {
        frac += 65536;
        x--;
      }
    }
  }

  return image;
}

// Xiaolin Wu's line algorithm,
// https://en.wikipedia.org/wiki/Xiaolin_Wu's_line_algorithm
Image _drawLineWu(Image image,
    {required int x1,
    required int y1,
    required int x2,
    required int y2,
    required Color color,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  final bool steep = (y2 - y1).abs() > (x2 - x1).abs();
  if (steep) {
    var t = x1;
    x1 = y1;
    y1 = t;
    t = x2;
    x2 = y2;
    y2 = t;
  }
  if (x1 > x2) {
    var t = x1;
    x1 = x2;
    x2 = t;
    t = y1;
    y1 = y2;
    y2 = t;
  }

  final dx = x2 - x1;
  final dy = y2 - y1;

  final gradient = dx == 1 ? 1.0 : dy.toDouble() / dx.toDouble();

  // handle first endpoint
  var xend = (x1 + 0.5).floor();
  var yend = y1 + gradient * (xend - x1);
  var xgap = 1 - (x1 + 0.5 - (x1 + 0.5).floor());
  final xpxl1 = xend; // this will be used in the main loop
  final ypxl1 = yend.floor();

  if (steep) {
    drawPixel(image, ypxl1, xpxl1, color,
        alpha: (1 - (yend - yend.floor())) * xgap,
        mask: mask,
        maskChannel: maskChannel);

    drawPixel(image, ypxl1 + 1, xpxl1, color,
        alpha: (yend - yend.floor()) * xgap,
        mask: mask,
        maskChannel: maskChannel);
  } else {
    drawPixel(image, xpxl1, ypxl1, color,
        alpha: (1 - (yend - yend.floor())) * xgap,
        mask: mask,
        maskChannel: maskChannel);

    drawPixel(image, xpxl1, ypxl1 + 1, color,
        alpha: (yend - yend.floor()) * xgap,
        mask: mask,
        maskChannel: maskChannel);
  }

  var intery = yend + gradient; // first y-intersection for the main loop

  // handle second endpoint
  xend = (x2 + 0.5).floor();
  yend = y2 + gradient * (xend - x2);
  xgap = x2 + 0.5 - (x2 + 0.5).floor();
  final xpxl2 = xend; //this will be used in the main loop
  final ypxl2 = yend.floor();

  if (steep) {
    drawPixel(image, ypxl2, xpxl2, color,
        alpha: (1.0 - (yend - yend.floor())) * xgap,
        mask: mask,
        maskChannel: maskChannel);

    drawPixel(image, ypxl2 + 1, xpxl2, color,
        alpha: (yend - yend.floor()) * xgap,
        mask: mask,
        maskChannel: maskChannel);

    // main loop
    for (var x = xpxl1 + 1; x <= xpxl2 - 1; x++) {
      drawPixel(image, intery.floor(), x, color,
          alpha: 1.0 - (intery - intery.floor()),
          mask: mask,
          maskChannel: maskChannel);

      drawPixel(image, intery.floor() + 1, x, color,
          alpha: intery - intery.floor(), mask: mask, maskChannel: maskChannel);

      intery = intery + gradient;
    }
  } else {
    drawPixel(image, xpxl2, ypxl2, color,
        alpha: (1.0 - (yend - yend.floor())) * xgap,
        mask: mask,
        maskChannel: maskChannel);

    drawPixel(image, xpxl2, ypxl2 + 1, color,
        alpha: (yend - yend.floor()) * xgap,
        mask: mask,
        maskChannel: maskChannel);

    // main loop
    for (var x = xpxl1 + 1; x <= xpxl2 - 1; x++) {
      drawPixel(image, x, intery.floor(), color,
          alpha: 1.0 - (intery - intery.floor()),
          mask: mask,
          maskChannel: maskChannel);

      drawPixel(image, x, intery.floor() + 1, color,
          alpha: intery - intery.floor(), mask: mask, maskChannel: maskChannel);

      intery = intery + gradient;
    }
  }

  return image;
}
