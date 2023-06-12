import 'dart:math';

import '../color/color.dart';
import '../color/color_float16.dart';
import '../color/color_float32.dart';
import '../color/color_float64.dart';
import '../color/color_int16.dart';
import '../color/color_int32.dart';
import '../color/color_int8.dart';
import '../color/color_uint1.dart';
import '../color/color_uint16.dart';
import '../color/color_uint2.dart';
import '../color/color_uint32.dart';
import '../color/color_uint4.dart';
import '../color/color_uint8.dart';
import '../color/format.dart';
import 'image_exception.dart';

int uint32ToRed(int c) => c & 0xff;

int uint32ToGreen(int c) => (c >> 8) & 0xff;

int uint32ToBlue(int c) => (c >> 16) & 0xff;

int uint32ToAlpha(int c) => (c >> 24) & 0xff;

int rgbaToUint32(int r, int g, int b, int a) =>
    r.clamp(0, 255) |
    (g.clamp(0, 255) << 8) |
    (b.clamp(0, 255) << 16) |
    (a.clamp(0, 255) << 24);

Color _convertColor(Color c, Color c2, num a) {
  final numChannels = c2.length;
  final format = c2.format;
  final fromFormat = c.palette?.format ?? c.format;
  final cl = c.length;
  if (numChannels == 1) {
    final g = c.length > 2 ? c.luminance : c[0];
    final gi = (c[0] is int) ? g.floor() : g;
    c2[0] = convertFormatValue(gi, fromFormat, format);
  } else if (numChannels <= cl) {
    for (var ci = 0; ci < numChannels; ++ci) {
      c2[ci] = convertFormatValue(c[ci], fromFormat, format);
    }
  } else {
    for (var ci = 0; ci < cl; ++ci) {
      c2[ci] = convertFormatValue(c[ci], fromFormat, format);
    }
    final v = cl == 1 ? c2[0] : 0;
    for (var ci = cl; ci < numChannels; ++ci) {
      c2[ci] = ci == 3 ? a : v;
    }
  }
  return c2;
}

Color convertColor(Color c,
    {Color? to, Format? format, int? numChannels, num? alpha}) {
  final fromFormat = c.palette?.format ?? c.format;
  format = to?.format ?? format ?? c.format;
  numChannels = to?.length ?? numChannels ?? c.length;
  alpha ??= 0;

  if (format == fromFormat && numChannels == c.length) {
    if (to == null) {
      return c.clone();
    }
    to.set(c);
    return to;
  }

  switch (format) {
    case Format.uint8:
      final c2 = to ?? ColorUint8(numChannels);
      return _convertColor(c, c2, alpha);
    case Format.uint1:
      final c2 = to ?? ColorUint1(numChannels);
      return _convertColor(c, c2, alpha);
    case Format.uint2:
      final c2 = to ?? ColorUint2(numChannels);
      return _convertColor(c, c2, alpha);
    case Format.uint4:
      final c2 = to ?? ColorUint4(numChannels);
      return _convertColor(c, c2, alpha);
    case Format.uint16:
      final c2 = to ?? ColorUint16(numChannels);
      return _convertColor(c, c2, alpha);
    case Format.uint32:
      final c2 = to ?? ColorUint32(numChannels);
      return _convertColor(c, c2, alpha);
    case Format.int8:
      final c2 = to ?? ColorInt8(numChannels);
      return _convertColor(c, c2, alpha);
    case Format.int16:
      final c2 = to ?? ColorInt16(numChannels);
      return _convertColor(c, c2, alpha);
    case Format.int32:
      final c2 = to ?? ColorInt32(numChannels);
      return _convertColor(c, c2, alpha);
    case Format.float16:
      final c2 = to ?? ColorFloat16(numChannels);
      return _convertColor(c, c2, alpha);
    case Format.float32:
      final c2 = to ?? ColorFloat32(numChannels);
      return _convertColor(c, c2, alpha);
    case Format.float64:
      final c2 = to ?? ColorFloat64(numChannels);
      return _convertColor(c, c2, alpha);
  }
}

/// Returns the luminance (grayscale) value of the color.
num getLuminance(Color c) => 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;

/// Returns the normalized \[0, 1\] luminance (grayscale) value of the color.
num getLuminanceNormalized(Color c) =>
    0.299 * c.rNormalized + 0.587 * c.gNormalized + 0.114 * c.bNormalized;

/// Returns the luminance (grayscale) value of the color.
num getLuminanceRgb(num r, num g, num b) => 0.299 * r + 0.587 * g + 0.114 * b;

/// Convert an HSL color to RGB, where h is specified in normalized degrees
/// \[0, 1\] (where 1 is 360-degrees); s and l are in the range \[0, 1\].
/// Returns a list \[r, g, b\] with values in the range \[0, 255\].
List<int> hslToRgb(num hue, num saturation, num lightness) {
  if (saturation == 0) {
    final gray = (lightness * 255.0).toInt();
    return [gray, gray, gray];
  }

  num hue2rgb(num p, num q, num t) {
    if (t < 0.0) {
      t += 1.0;
    }
    if (t > 1) {
      t -= 1.0;
    }
    if (t < 1.0 / 6.0) {
      return p + (q - p) * 6.0 * t;
    }
    if (t < 1.0 / 2.0) {
      return q;
    }
    if (t < 2.0 / 3.0) {
      return p + (q - p) * (2.0 / 3.0 - t) * 6.0;
    }
    return p;
  }

  final q = lightness < 0.5
      ? lightness * (1.0 + saturation)
      : lightness + saturation - lightness * saturation;
  final p = 2.0 * lightness - q;

  final r = hue2rgb(p, q, hue + 1.0 / 3.0);
  final g = hue2rgb(p, q, hue);
  final b = hue2rgb(p, q, hue - 1.0 / 3.0);

  return [(r * 255.0).round(), (g * 255.0).round(), (b * 255.0).round()];
}

/// Convert an HSV color to RGB, where h is specified in normalized degrees
/// \[0, 1\] (where 1 is 360-degrees); s and l are in the range \[0, 1\].
/// Returns a list \[r, g, b\] with values in the range \[0, 255\].
List<int> hsvToRgb(num hue, num saturation, num brightness) {
  if (saturation == 0) {
    final gray = (brightness * 255.0).round();
    return [gray, gray, gray];
  }

  final num h = (hue - hue.floor()) * 6.0;
  final f = h - h.floor();
  final num p = brightness * (1.0 - saturation);
  final num q = brightness * (1.0 - saturation * f);
  final num t = brightness * (1.0 - (saturation * (1.0 - f)));

  switch (h.toInt()) {
    case 0:
      return [
        (brightness * 255.0).round(),
        (t * 255.0).round(),
        (p * 255.0).round()
      ];
    case 1:
      return [
        (q * 255.0).round(),
        (brightness * 255.0).round(),
        (p * 255.0).round()
      ];
    case 2:
      return [
        (p * 255.0).round(),
        (brightness * 255.0).round(),
        (t * 255.0).round()
      ];
    case 3:
      return [
        (p * 255.0).round(),
        (q * 255.0).round(),
        (brightness * 255.0).round()
      ];
    case 4:
      return [
        (t * 255.0).round(),
        (p * 255.0).round(),
        (brightness * 255.0).round()
      ];
    case 5:
      return [
        (brightness * 255.0).round(),
        (p * 255.0).round(),
        (q * 255.0).round()
      ];
    default:
      throw ImageException('invalid hue');
  }
}

/// Convert an RGB color to HSL, where r, g and b are in the range \[0, 255\].
/// Returns a list \[h, s, l\] with values in the range \[0, 1\].
List<num> rgbToHsl(num r, num g, num b) {
  r /= 255.0;
  g /= 255.0;
  b /= 255.0;
  final mx = max(r, max(g, b));
  final mn = min(r, min(g, b));
  num h;
  final l = (mx + mn) / 2.0;

  if (mx == mn) {
    return [0.0, 0.0, l];
  }

  final d = mx - mn;

  final s = l > 0.5 ? d / (2.0 - mx - mn) : d / (mx + mn);

  if (mx == r) {
    h = (g - b) / d + (g < b ? 6.0 : 0.0);
  } else if (mx == g) {
    h = (b - r) / d + 2.0;
  } else {
    h = (r - g) / d + 4.0;
  }

  h /= 6.0;

  return [h, s, l];
}

/// Convert a CIE-L*ab color to XYZ.
List<int> labToXyz(num l, num a, num b) {
  num y = (l + 16.0) / 116.0;
  num x = y + (a / 500.0);
  num z = y - (b / 200.0);
  if (pow(x, 3) > 0.008856) {
    x = pow(x, 3);
  } else {
    x = (x - 16.0 / 116) / 7.787;
  }
  if (pow(y, 3) > 0.008856) {
    y = pow(y, 3);
  } else {
    y = (y - 16.0 / 116.0) / 7.787;
  }
  if (pow(z, 3) > 0.008856) {
    z = pow(z, 3);
  } else {
    z = (z - 16.0 / 116.0) / 7.787;
  }

  return [(x * 95.047).toInt(), (y * 100.0).toInt(), (z * 108.883).toInt()];
}

/// Convert an XYZ color to RGB.
List<int> xyzToRgb(num x, num y, num z) {
  x /= 100;
  y /= 100;
  z /= 100;
  num r = (3.2406 * x) + (-1.5372 * y) + (-0.4986 * z);
  num g = (-0.9689 * x) + (1.8758 * y) + (0.0415 * z);
  num b = (0.0557 * x) + (-0.2040 * y) + (1.0570 * z);
  if (r > 0.0031308) {
    r = (1.055 * pow(r, 0.4166666667)) - 0.055;
  } else {
    r *= 12.92;
  }
  if (g > 0.0031308) {
    g = (1.055 * pow(g, 0.4166666667)) - 0.055;
  } else {
    g *= 12.92;
  }
  if (b > 0.0031308) {
    b = (1.055 * pow(b, 0.4166666667)) - 0.055;
  } else {
    b *= 12.92;
  }

  return [
    (r * 255).clamp(0, 255).toInt(),
    (g * 255).clamp(0, 255).toInt(),
    (b * 255).clamp(0, 255).toInt()
  ];
}

/// Convert a CMYK color to RGB, where c, m, y, k values are in the range
/// \[0, 255\]. Returns a list \[r, g, b\] with values in the range \[0, 255\].
List<int> cmykToRgb(num c, num m, num y, num k) {
  c /= 255.0;
  m /= 255.0;
  y /= 255.0;
  k /= 255.0;
  return [
    (255.0 * (1.0 - c) * (1.0 - k)).round(),
    (255.0 * (1.0 - m) * (1.0 - k)).round(),
    (255.0 * (1.0 - y) * (1.0 - k)).round()
  ];
}

/// Convert a CIE-L*ab color to RGB.
List<int> labToRgb(num l, num a, num b) {
  const refX = 95.047;
  const refY = 100.000;
  const refZ = 108.883;

  num y = (l + 16.0) / 116.0;
  num x = a / 500.0 + y;
  num z = y - b / 200.0;

  final y3 = pow(y, 3);
  if (y3 > 0.008856) {
    y = y3;
  } else {
    y = (y - 16 / 116) / 7.787;
  }

  final x3 = pow(x, 3);
  if (x3 > 0.008856) {
    x = x3;
  } else {
    x = (x - 16 / 116) / 7.787;
  }

  final z3 = pow(z, 3);
  if (z3 > 0.008856) {
    z = z3;
  } else {
    z = (z - 16 / 116) / 7.787;
  }

  x *= refX;
  y *= refY;
  z *= refZ;

  x /= 100.0;
  y /= 100.0;
  z /= 100.0;

  // xyz to rgb
  num R = x * 3.2406 + y * (-1.5372) + z * (-0.4986);
  num G = x * (-0.9689) + y * 1.8758 + z * 0.0415;
  num B = x * 0.0557 + y * (-0.2040) + z * 1.0570;

  if (R > 0.0031308) {
    R = 1.055 * (pow(R, 1.0 / 2.4)) - 0.055;
  } else {
    R = 12.92 * R;
  }

  if (G > 0.0031308) {
    G = 1.055 * (pow(G, 1.0 / 2.4)) - 0.055;
  } else {
    G = 12.92 * G;
  }

  if (B > 0.0031308) {
    B = 1.055 * (pow(B, 1.0 / 2.4)) - 0.055;
  } else {
    B = 12.92 * B;
  }

  return [
    (R * 255.0).clamp(0, 255).toInt(),
    (G * 255.0).clamp(0, 255).toInt(),
    (B * 255.0).clamp(0, 255).toInt()
  ];
}

/// Convert a RGB color to XYZ.
List<num> rgbToXyz(num r, num g, num b) {
  r = r / 255.0;
  g = g / 255.0;
  b = b / 255.0;

  if (r > 0.04045) {
    r = pow((r + 0.055) / 1.055, 2.4);
  } else {
    r = r / 12.92;
  }
  if (g > 0.04045) {
    g = pow((g + 0.055) / 1.055, 2.4);
  } else {
    g = g / 12.92;
  }
  if (b > 0.04045) {
    b = pow((b + 0.055) / 1.055, 2.4);
  } else {
    b = b / 12.92;
  }

  r = r * 100.0;
  g = g * 100.0;
  b = b * 100.0;

  return [
    r * 0.4124 + g * 0.3576 + b * 0.1805,
    r * 0.2126 + g * 0.7152 + b * 0.0722,
    r * 0.0193 + g * 0.1192 + b * 0.9505
  ];
}

/// Convert a XYZ color to CIE-L*ab.
List<num> xyzToLab(num x, num y, num z) {
  x = x / 95.047;
  y = y / 100.0;
  z = z / 108.883;

  if (x > 0.008856) {
    x = pow(x, 1 / 3.0);
  } else {
    x = (7.787 * x) + (16 / 116.0);
  }
  if (y > 0.008856) {
    y = pow(y, 1 / 3.0);
  } else {
    y = (7.787 * y) + (16 / 116.0);
  }
  if (z > 0.008856) {
    z = pow(z, 1 / 3.0);
  } else {
    z = (7.787 * z) + (16 / 116.0);
  }

  return [(116.0 * y) - 16, 500.0 * (x - y), 200.0 * (y - z)];
}

/// Convert a RGB color to CIE-L*ab.
List<num> rgbToLab(num r, num g, num b) {
  r = r / 255.0;
  g = g / 255.0;
  b = b / 255.0;

  if (r > 0.04045) {
    r = pow((r + 0.055) / 1.055, 2.4);
  } else {
    r = r / 12.92;
  }
  if (g > 0.04045) {
    g = pow((g + 0.055) / 1.055, 2.4);
  } else {
    g = g / 12.92;
  }
  if (b > 0.04045) {
    b = pow((b + 0.055) / 1.055, 2.4);
  } else {
    b = b / 12.92;
  }

  r = r * 100.0;
  g = g * 100.0;
  b = b * 100.0;

  num x = r * 0.4124 + g * 0.3576 + b * 0.1805;
  num y = r * 0.2126 + g * 0.7152 + b * 0.0722;
  num z = r * 0.0193 + g * 0.1192 + b * 0.9505;

  x = x / 95.047;
  y = y / 100.0;
  z = z / 108.883;

  if (x > 0.008856) {
    x = pow(x, 1 / 3.0);
  } else {
    x = (7.787 * x) + (16 / 116.0);
  }
  if (y > 0.008856) {
    y = pow(y, 1 / 3.0);
  } else {
    y = (7.787 * y) + (16 / 116.0);
  }
  if (z > 0.008856) {
    z = pow(z, 1 / 3.0);
  } else {
    z = (7.787 * z) + (16 / 116.0);
  }

  return [(116.0 * y) - 16, 500.0 * (x - y), 200.0 * (y - z)];
}
