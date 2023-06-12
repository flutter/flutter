import '../color/channel.dart';
import '../color/color.dart';
import '../draw/draw_line.dart';
import '../draw/draw_pixel.dart';
import '../image/image.dart';
import '../util/point.dart';

/// Fill a polygon defined by the given [vertices].
Image drawPolygon(Image src,
    {required List<Point> vertices,
    required Color color,
    bool antialias = false,
    num thickness = 1,
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
        antialias: antialias,
        thickness: thickness,
        mask: mask,
        maskChannel: maskChannel);
  }

  for (var i = 0; i < numVertices - 1; ++i) {
    drawLine(src,
        x1: vertices[i].xi,
        y1: vertices[i].yi,
        x2: vertices[i + 1].xi,
        y2: vertices[i + 1].yi,
        color: color,
        antialias: antialias,
        thickness: thickness,
        mask: mask,
        maskChannel: maskChannel);
  }

  drawLine(src,
      x1: vertices[numVertices - 1].xi,
      y1: vertices[numVertices - 1].yi,
      x2: vertices[0].xi,
      y2: vertices[0].yi,
      color: color,
      antialias: antialias,
      thickness: thickness,
      mask: mask,
      maskChannel: maskChannel);

  return src;
}
