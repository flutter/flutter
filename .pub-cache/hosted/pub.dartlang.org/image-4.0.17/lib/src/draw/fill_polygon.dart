import 'dart:math';

import '../color/channel.dart';
import '../color/color.dart';
import '../draw/draw_line.dart';
import '../draw/draw_pixel.dart';
import '../image/image.dart';
import '../util/point.dart';

/// Fill a polygon defined by the given [vertices].
Image fillPolygon(Image src,
    {required List<Point> vertices,
    required Color color,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  if (color.a == 0) {
    return src;
  }

  final numVertices = vertices.length;

  if (numVertices == 0) {
    return src;
  }

  if (numVertices == 1) {
    return drawPixel(src, vertices[0].xi, vertices[0].yi, color,
        mask: mask, maskChannel: maskChannel);
  }

  if (numVertices == 2) {
    return drawLine(src,
        x1: vertices[0].xi,
        y1: vertices[0].yi,
        x2: vertices[1].xi,
        y2: vertices[1].yi,
        color: color,
        mask: mask,
        maskChannel: maskChannel);
  }

  var xMin = 0;
  var yMin = 0;
  var xMax = 0;
  var yMax = 0;
  var first = true;
  for (final vertex in vertices) {
    if (first) {
      xMin = vertex.xi;
      yMin = vertex.yi;
      xMax = vertex.xi;
      yMax = vertex.yi;
      first = false;
    } else {
      xMin = min(xMin, vertex.xi);
      yMin = min(yMin, vertex.yi);
      xMax = max(xMax, vertex.xi);
      yMax = max(yMax, vertex.yi);
    }
  }

  xMin = max(xMin, 0);
  yMin = max(yMin, 0);
  xMax = min(xMax, src.width - 1);
  yMax = min(yMax, src.height - 1);

  final inter = List<num>.filled(40, 0);
  final vi =
      List<int>.generate(numVertices + 1, (i) => i < numVertices ? i : 0);

  for (var yi = yMin, y = yMin + 0.5; yi <= yMax; ++yi, ++y) {
    var c = 0;
    for (var i = 0; i < numVertices; ++i) {
      final v1 = vertices[vi[i]];
      final v2 = vertices[vi[i + 1]];

      var x1 = v1.x;
      var y1 = v1.y;
      var x2 = v2.x;
      var y2 = v2.y;
      if (y2 < y1) {
        var temp = x1;
        x1 = x2;
        x2 = temp;
        temp = y1;
        y1 = y2;
        y2 = temp;
      }

      if (y <= y2 && y >= y1) {
        num x = 0;
        if ((y1 - y2) == 0) {
          x = x1;
        } else {
          x = ((x2 - x1) * (y - y1)) / (y2 - y1);
          x = x + x1;
        }
        if (x <= xMax && x >= xMin) {
          inter[c++] = x;
        }
      }
    }

    for (var i = 0; i < c; i += 2) {
      var x1f = inter[i];
      var x2f = inter[i + 1];
      if (x1f > x2f) {
        final t = x1f;
        x1f = x2f;
        x2f = t;
      }
      final x1 = x1f.floor();
      final x2 = x2f.ceil();
      for (var x = x1; x <= x2; ++x) {
        drawPixel(src, x, yi, color, mask: mask, maskChannel: maskChannel);
      }
    }
  }

  /*for (var i = 0; i < numVertices; ++i) {
    final v1 = vertices[vi[i]];
    final v2 = vertices[vi[i + 1]];
    drawLine(src, x1: v1.xi, y1: v1.yi, x2: v2.xi, y2: v2.yi,
        color: color, mask: mask, maskChannel: maskChannel, thickness: 1);
  }*/

  return src;
}
