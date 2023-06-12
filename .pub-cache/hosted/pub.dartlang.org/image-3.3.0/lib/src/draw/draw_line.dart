import 'dart:math';

import '../image.dart';
import '../util/clip_line.dart';
import 'draw_circle.dart';
import 'draw_pixel.dart';

/// Draw a line into [image].
///
/// If [antialias] is true then the line is drawn with smooth edges.
/// [thickness] determines how thick the line should be drawn, in pixels.
Image drawLine(Image image, int x1, int y1, int x2, int y2, int color,
    {bool antialias = false, num thickness = 1}) {
  final line = [x1, y1, x2, y2];
  if (!clipLine(line, [0, 0, image.width - 1, image.height - 1])) {
    return image;
  }

  x1 = line[0];
  y1 = line[1];
  x2 = line[2];
  y2 = line[3];

  var dx = (x2 - x1);
  var dy = (y2 - y1);

  final radius = (thickness / 2.0).floor();

  // Drawing a single point.
  if (dx == 0 && dy == 0) {
    thickness == 1
        ? drawPixel(image, x1, y1, color)
        : fillCircle(image, x1, y1, radius, color);
    return image;
  }

  // Axis-aligned lines
  if (dx == 0) {
    if (dy < 0) {
      for (var y = y2; y <= y1; ++y) {
        if (thickness <= 1) {
          drawPixel(image, x1, y, color);
        } else {
          for (var i = 0; i < thickness; i++) {
            drawPixel(image, x1 - radius + i, y, color);
          }
        }
      }
    } else {
      for (var y = y1; y <= y2; ++y) {
        if (thickness <= 1) {
          drawPixel(image, x1, y, color);
        } else {
          for (var i = 0; i < thickness; i++) {
            drawPixel(image, x1 - radius + i, y, color);
          }
        }
      }
    }
    return image;
  } else if (dy == 0) {
    if (dx < 0) {
      for (var x = x2; x <= x1; ++x) {
        if (thickness <= 1) {
          drawPixel(image, x, y1, color);
        } else {
          for (var i = 0; i < thickness; i++) {
            drawPixel(image, x, y1 - radius + i, color);
          }
        }
      }
    } else {
      for (var x = x1; x <= x2; ++x) {
        if (thickness <= 1) {
          drawPixel(image, x, y1, color);
        } else {
          for (var i = 0; i < thickness; i++) {
            drawPixel(image, x, y1 - radius + i, color);
          }
        }
      }
    }
    return image;
  }

  // 16-bit unsigned int xor.
  int _xor(int n) => (~n + 0x10000) & 0xffff;

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
        drawPixel(image, x, w, color);
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
            drawPixel(image, x, w, color);
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
            drawPixel(image, x, w, color);
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
        drawPixel(image, w, y, color);
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
            drawPixel(image, w, y, color);
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
            drawPixel(image, w, y, color);
          }
        }
      }
    }

    return image;
  }

  // Antialias Line

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
      final wstart = (y - wid ~/ 2);
      for (var w = wstart; w < wstart + wid; w++) {
        drawPixel(image, x, w, color, (frac >> 8) & 0xff);
        drawPixel(image, x, w + 1, color, (_xor(frac) >> 8) & 0xff);
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
      final wstart = (x - wid ~/ 2);
      for (var w = wstart; w < wstart + wid; w++) {
        drawPixel(image, w, y, color, (frac >> 8) & 0xff);
        drawPixel(image, w + 1, y, color, (_xor(frac) >> 8) & 0xff);
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
