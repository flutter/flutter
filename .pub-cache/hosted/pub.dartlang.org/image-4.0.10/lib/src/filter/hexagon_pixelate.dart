import '../color/channel.dart';
import '../image/image.dart';
import '../util/math_util.dart';

/// Apply the hexagon pixelate filter to the image.
Image hexagonPixelate(Image src,
    {int? centerX,
    int? centerY,
    int size = 5,
    num amount = 1,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  for (final frame in src.frames) {
    final w = frame.width - 1;
    final h = frame.height - 1;
    final cntX = (centerX ?? frame.width ~/ 2) / w;
    final cntY = (centerY ?? frame.height ~/ 2) / h;
    final orig = frame.clone(noAnimation: true);

    for (final p in frame) {
      //final uvX = p.x / w;
      //final uvY = p.y / h;

      var texX = (p.x - cntX) / size;
      var texY = (p.y - cntY) / size;
      texY /= 0.866025404;
      texX -= texY * 0.5;

      num ax;
      num ay;
      if (texX + texY - texX.floor() - texY.floor() < 1) {
        ax = texX.floor();
        ay = texY.floor();
      } else {
        ax = texX.ceil();
        ay = texY.ceil();
      }

      final bx = texX.ceil();
      final by = texY.floor();
      final cx = texX.floor();
      final cy = texY.ceil();

      final tex2X = texX;
      final tex2Y = texY;
      final tex2Z = 1 - texX - texY;
      final a2x = ax;
      final a2y = ay;
      final a2z = 1 - ax - ay;
      final b2x = bx;
      final b2y = by;
      final b2z = 1 - bx - by;
      final c2x = cx;
      final c2y = cy;
      final c2z = 1 - cx - cy;

      final aLen = length3(tex2X - a2x, tex2Y - a2y, tex2Z - a2z);
      final bLen = length3(tex2X - b2x, tex2Y - b2y, tex2Z - b2z);
      final cLen = length3(tex2X - c2x, tex2Y - c2y, tex2Z - c2z);

      num choiceX;
      num choiceY;
      if (aLen < bLen) {
        if (aLen < cLen) {
          choiceX = ax;
          choiceY = ay;
        } else {
          choiceX = cx;
          choiceY = cy;
        }
      } else {
        if (bLen < cLen) {
          choiceX = bx;
          choiceY = by;
        } else {
          choiceX = cx;
          choiceY = cy;
        }
      }

      choiceX += choiceY * 0.5;
      choiceY *= 0.866025404;
      choiceX *= size / w;
      choiceY *= size / h;

      final nx = choiceX + cntX / w;
      final ny = choiceY + cntY / h;
      final x = (nx * w).clamp(0, w);
      final y = (ny * h).clamp(0, h);
      final newColor = orig.getPixel(x.floor(), y.floor());

      final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
      final mx = (msk ?? 1) * amount;

      p
        ..r = mix(p.r, newColor.r, mx)
        ..g = mix(p.g, newColor.g, mx)
        ..b = mix(p.b, newColor.b, mx);
    }
  }
  return src;
}
