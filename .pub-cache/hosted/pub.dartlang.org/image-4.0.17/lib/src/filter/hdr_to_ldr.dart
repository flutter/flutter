import 'dart:math' as math;

import '../image/image.dart';

/// Convert a high dynamic range image to a low dynamic range image,
/// with optional exposure control.
Image hdrToLdr(Image hdr, {num? exposure}) {
  num knee(num x, num f) => math.log(x * f + 1.0) / f;

  num gamma(num h, num m) {
    var x = math.max(0, h * m);

    if (x > 1.0) {
      x = 1.0 + knee(x - 1, 0.184874);
    }

    return math.pow(x, 0.4545) * 84.66;
  }

  final image =
      Image(width: hdr.width, height: hdr.height, numChannels: hdr.numChannels);

  final m = (exposure != null)
      ? math.pow(2.0, (exposure + 2.47393).clamp(-20.0, 20.0))
      : 1.0;

  final nc = hdr.numChannels;

  for (var y = 0; y < hdr.height; ++y) {
    for (var x = 0; x < hdr.width; ++x) {
      final hp = hdr.getPixel(x, y);

      var r = hp.rNormalized;
      var g = nc == 1 ? r : hp.gNormalized;
      var b = nc == 1 ? r : hp.bNormalized;

      if (r.isInfinite || r.isNaN) {
        r = 0.0;
      }
      if (g.isInfinite || g.isNaN) {
        g = 0.0;
      }
      if (b.isInfinite || b.isNaN) {
        b = 0.0;
      }

      num ri, gi, bi;
      if (exposure != null) {
        ri = gamma(r, m);
        gi = gamma(g, m);
        bi = gamma(b, m);
      } else {
        ri = r.clamp(0, 1) * 255.0;
        gi = g.clamp(0, 1) * 255.0;
        bi = b.clamp(0, 1) * 255.0;
      }

      // Normalize the color
      final mi = math.max(ri, math.max(gi, bi));
      if (mi > 255.0) {
        ri = 255.0 * (ri / mi);
        gi = 255.0 * (gi / mi);
        bi = 255.0 * (bi / mi);
      }

      if (hdr.numChannels > 3) {
        var a = hp.a;
        if (a.isInfinite || a.isNaN) {
          a = 1.0;
        }
        image.setPixelRgba(
            x,
            y,
            ri.clamp(0, 255).toInt(),
            gi.clamp(0, 255).toInt(),
            bi.clamp(0, 255).toInt(),
            (a * 255.0).clamp(0, 255).toInt());
      } else {
        image.setPixelRgb(x, y, ri.clamp(0, 255).toInt(),
            gi.clamp(0, 255).toInt(), bi.clamp(0, 255).toInt());
      }
    }
  }

  return image;
}
