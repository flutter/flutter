import 'dart:math' as math;
import '../image.dart';
import '../image_exception.dart';
import 'hdr_image.dart';

/// Convert a high dynamic range image to a low dynamic range image,
/// with optional exposure control.
Image hdrToImage(HdrImage hdr, {num? exposure}) {
  num _knee(num x, num f) => math.log(x * f + 1.0) / f;

  num _gamma(num h, num m) {
    var x = math.max(0, h * m);

    if (x > 1.0) {
      x = 1.0 + _knee(x - 1, 0.184874);
    }

    return math.pow(x, 0.4545) * 84.66;
  }

  final image = Image(hdr.width, hdr.height);
  final pixels = image.getBytes();

  if (!hdr.hasColor) {
    throw ImageException('Only RGB[A] images are currently supported.');
  }

  final m = (exposure != null)
      ? math.pow(2.0, (exposure + 2.47393).clamp(-20.0, 20.0))
      : 1.0;

  for (var y = 0, di = 0; y < hdr.height; ++y) {
    for (var x = 0; x < hdr.width; ++x) {
      var r = hdr.getRed(x, y);
      var g = hdr.numberOfChannels == 1 ? r : hdr.getGreen(x, y);
      var b = hdr.numberOfChannels == 1 ? r : hdr.getBlue(x, y);

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
        ri = _gamma(r, m);
        gi = _gamma(g, m);
        bi = _gamma(b, m);
      } else {
        ri = (r * 255.0);
        gi = (g * 255.0);
        bi = (b * 255.0);
      }

      // Normalize the color
      final mi = math.max(ri, math.max(gi, bi));
      if (mi > 255.0) {
        ri = 255.0 * (ri / mi);
        gi = 255.0 * (gi / mi);
        bi = 255.0 * (bi / mi);
      }

      pixels[di++] = ri.clamp(0, 255).toInt();
      pixels[di++] = gi.clamp(0, 255).toInt();
      pixels[di++] = bi.clamp(0, 255).toInt();

      if (hdr.alpha != null) {
        var a = hdr.alpha!.getFloat(x, y);
        if (a.isInfinite || a.isNaN) {
          a = 1.0;
        }
        pixels[di++] = (a * 255.0).clamp(0, 255).toInt();
      } else {
        pixels[di++] = 255;
      }
    }
  }

  return image;
}
