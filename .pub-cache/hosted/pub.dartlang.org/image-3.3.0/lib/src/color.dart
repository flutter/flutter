import 'dart:math';

import 'image_exception.dart';
import 'internal/clamp.dart';

enum Channel {
  /// Red channel of a color.
  red,

  /// Green channel of a color.
  green,

  /// Blue channel of a color.
  blue,

  /// Alpha channel of a color.
  alpha,

  /// Luminance (brightness) of a color.
  luminance
}

/// Image pixel colors are instantiated as an int object rather than an instance
/// of the Color class in order to reduce object allocations. Image pixels are
/// stored in 32-bit RGBA format (8 bits per channel). Internally in dart, this
/// will be stored in a "small integer" on 64-bit machines, or a
/// "medium integer" on 32-bit machines. In Javascript, this will be stored
/// in a 64-bit double.
///
/// The Color class is used as a namespace for color operations, in an attempt
/// to create a cleaner API for color operations.
class Color {
  /// Create a color value from RGB values in the range [0, 255].
  ///
  /// The channel order of a uint32 encoded color is BGRA.
  static int fromRgb(int red, int green, int blue) =>
      getColor(red, green, blue);

  /// Create a color value from RGBA values in the range [0, 255].
  ///
  /// The channel order of a uint32 encoded color is BGRA.
  static int fromRgba(int red, int green, int blue, int alpha) =>
      getColor(red, green, blue, alpha);

  /// Create a color value from HSL values in the range [0, 1].
  static int fromHsl(num hue, num saturation, num lightness) {
    final rgb = hslToRgb(hue, saturation, lightness);
    return getColor(rgb[0], rgb[1], rgb[2]);
  }

  /// Create a color value from HSV values in the range [0, 1].
  static int fromHsv(num hue, num saturation, num value) {
    final rgb = hsvToRgb(hue, saturation, value);
    return getColor(rgb[0], rgb[1], rgb[2]);
  }

  /// Create a color value from XYZ values.
  static int fromXyz(num x, num y, num z) {
    final rgb = xyzToRgb(x, y, z);
    return getColor(rgb[0], rgb[1], rgb[2]);
  }

  /// Create a color value from CIE-L*ab values.
  static int fromLab(num L, num a, num b) {
    final rgb = labToRgb(L, a, b);
    return getColor(rgb[0], rgb[1], rgb[2]);
  }

  /// Compare colors from a 3 or 4 dimensional color space
  static num distance(List<num> c1, List<num> c2, bool compareAlpha) {
    final d1 = c1[0] - c2[0];
    final d2 = c1[1] - c2[1];
    final d3 = c1[2] - c2[2];
    if (compareAlpha) {
      final dA = c1[3] - c2[3];
      return sqrt(max(d1 * d1, (d1 - dA) * (d1 - dA)) +
          max(d2 * d2, (d2 - dA) * (d2 - dA)) +
          max(d3 * d3, (d3 - dA) * (d3 - dA)));
    } else {
      return sqrt(d1 * d1 + d2 * d2 + d3 * d3);
    }
  }

  // DartAnalyzer doesn't like classes with only static members now, so
  // I added this member for now to avoid the warnings.
  var fixWarnings = 0;
}

/// Get the color with the given [r], [g], [b], and [a] components.
///
/// The channel order of a uint32 encoded color is RGBA.
int getColor(int r, int g, int b, [int a = 255]) =>
    // what we're doing here, is creating a 32 bit
    // integer by collecting the rgba in one integer.
    // we know for certain and we're also assuring that
    // all our variables' values are 255 at maximum,
    // which means that they can never be bigger than
    // 8 bits  so we can safely slide each one by 8 bits
    // for adding the other.
    (clamp255(a) << 24) |
    (clamp255(b) << 16) |
    (clamp255(g) << 8) |
    (clamp255(r));

/// Get the [channel] from the [color].
int getChannel(int color, Channel channel) => channel == Channel.red
    ? getRed(color)
    : channel == Channel.green
        ? getGreen(color)
        : channel == Channel.blue
            ? getBlue(color)
            : channel == Channel.alpha
                ? getAlpha(color)
                : getLuminance(color);

/// Returns a new color, where the given [color]'s [channel] has been
/// replaced with the given [value].
int setChannel(int color, Channel channel, int value) => channel == Channel.red
    ? setRed(color, value)
    : channel == Channel.green
        ? setGreen(color, value)
        : channel == Channel.blue
            ? setBlue(color, value)
            : channel == Channel.alpha
                ? setAlpha(color, value)
                : color;

/// check if [color] is white
bool isWhite(int color) => ((color) & 0xffffff == 0xffffff);

/// check if [color] is white
bool isBlack(int color) => ((color) & 0xffffff == 0x0);

/// Get the red channel from the [color].
int getRed(int color) => (color) & 0xff;

/// Returns a new color where the red channel of [color] has been replaced
/// by [value].
int setRed(int color, int value) => (color & 0xffffff00) | (clamp255(value));

/// Get the green channel from the [color].
int getGreen(int color) => (color >> 8) & 0xff;

/// Returns a new color where the green channel of [color] has been replaced
/// by [value].
int setGreen(int color, int value) =>
    (color & 0xffff00ff) | (clamp255(value) << 8);

/// Get the blue channel from the [color].
int getBlue(int color) => (color >> 16) & 0xff;

/// Returns a new color where the blue channel of [color] has been replaced
/// by [value].
int setBlue(int color, int value) =>
    (color & 0xff00ffff) | (clamp255(value) << 16);

/// Get the alpha channel from the [color].
int getAlpha(int color) => (color >> 24) & 0xff;

/// Returns a new color where the alpha channel of [color] has been replaced
/// by [value].
int setAlpha(int color, int value) =>
    (color & 0x00ffffff) | (clamp255(value) << 24);

/// Returns a new color of [src] alpha-blended onto [dst]. The opacity of [src]
/// is additionally scaled by [fraction] / 255.
int alphaBlendColors(int dst, int src, [int fraction = 0xff]) {
  final srcAlpha = getAlpha(src);
  if (srcAlpha == 255 && fraction == 0xff) {
    // src is fully opaque, nothing to blend
    return src;
  }
  if (srcAlpha == 0 && fraction == 0xff) {
    // src is fully transparent, nothing to blend
    return dst;
  }
  var a = (srcAlpha / 255.0);
  if (fraction != 0xff) {
    a *= (fraction / 255.0);
  }

  final sr = (getRed(src) * a).round();
  final sg = (getGreen(src) * a).round();
  final sb = (getBlue(src) * a).round();
  final sa = (srcAlpha * a).round();

  final dr = (getRed(dst) * (1.0 - a)).round();
  final dg = (getGreen(dst) * (1.0 - a)).round();
  final db = (getBlue(dst) * (1.0 - a)).round();
  final da = (getAlpha(dst) * (1.0 - a)).round();

  return getColor(sr + dr, sg + dg, sb + db, sa + da);
}

/// Returns the luminance (grayscale) value of the [color].
int getLuminance(int color) {
  final r = getRed(color);
  final g = getGreen(color);
  final b = getBlue(color);
  return getLuminanceRgb(r, g, b);
}

/// Returns the luminance (grayscale) value of the color.
int getLuminanceRgb(int r, int g, int b) =>
    (0.299 * r + 0.587 * g + 0.114 * b).round();

/// Convert an HSL color to RGB, where h is specified in normalized degrees
/// [0, 1] (where 1 is 360-degrees); s and l are in the range [0, 1].
/// Returns a list [r, g, b] with values in the range [0, 255].
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
/// [0, 1] (where 1 is 360-degrees); s and l are in the range [0, 1].
/// Returns a list [r, g, b] with values in the range [0, 255].
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

/// Convert an RGB color to HSL, where r, g and b are in the range [0, 255].
/// Returns a list [h, s, l] with values in the range [0, 1].
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
/// [0, 255]. Returns a list [r, g, b] with values in the range [0, 255].
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
  const ref_x = 95.047;
  const ref_y = 100.000;
  const ref_z = 108.883;

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

  x *= ref_x;
  y *= ref_y;
  z *= ref_z;

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
