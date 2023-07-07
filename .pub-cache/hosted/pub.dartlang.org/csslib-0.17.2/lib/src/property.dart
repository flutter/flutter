// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Representations of CSS styles.

part of '../parser.dart';

// TODO(terry): Prune down this file we do need some of the code in this file
//              for darker, lighter, how to represent a Font, etc but alot of
//              the complexity can be removed.
//              See https://github.com/dart-lang/csslib/issues/7

/// Base for all style properties (e.g., Color, Font, Border, Margin, etc.)
abstract class _StyleProperty {
  /// Returns the expression part of a CSS declaration.  Declaration is:
  ///
  ///     property:expression;
  ///
  /// E.g., if property is color then expression could be rgba(255,255,0) the
  ///       CSS declaration would be 'color:rgba(255,255,0);'.
  ///
  /// then _cssExpression would return 'rgba(255,255,0)'.  See
  /// <http://www.w3.org/TR/CSS21/grammar.html>
  String? get cssExpression;
}

/// Base interface for Color, HSL and RGB.
abstract class ColorBase {
  /// Canonical form for color #rrggbb with alpha blending (0.0 == full
  /// transparency and 1.0 == fully opaque). If _argb length is 6 it's an
  /// rrggbb otherwise it's aarrggbb.
  String toHexArgbString();

  /// Return argb as a value (int).
  int get argbValue;
}

/// General purpose Color class.  Represent a color as an ARGB value that can be
/// converted to and from num, hex string, hsl, hsla, rgb, rgba and SVG pre-
/// defined color constant.
class Color implements _StyleProperty, ColorBase {
  // If _argb length is 6 it's an rrggbb otherwise it's aarrggbb.
  final String _argb;

  // TODO(terry): Look at reducing Rgba and Hsla classes as factories for
  //              converting from Color to an Rgba or Hsla for reading only.
  //              Usefulness of creating an Rgba or Hsla is limited.

  /// Create a color with an integer representing the rgb value of red, green,
  /// and blue.  The value 0xffffff is the color white #ffffff (CSS style).
  /// The [rgb] value of 0xffd700 would map to #ffd700 or the constant
  /// Color.gold, where ff is red intensity, d7 is green intensity, and 00 is
  /// blue intensity.
  Color(int rgb, [num? alpha]) : _argb = Color._rgbToArgbString(rgb, alpha);

  /// RGB takes three values. The [red], [green], and [blue] parameters are
  /// the intensity of those components where '0' is the least and '256' is the
  /// greatest.
  ///
  /// If [alpha] is provided, it is the level of translucency which ranges from
  /// '0' (completely transparent) to '1.0' (completely opaque).  It will
  /// internally be mapped to an int between '0' and '255' like the other color
  /// components.
  Color.createRgba(int red, int green, int blue, [num? alpha])
      : _argb = Color.convertToHexString(
            Color._clamp(red, 0, 255),
            Color._clamp(green, 0, 255),
            Color._clamp(blue, 0, 255),
            alpha != null ? Color._clamp(alpha, 0, 1) : alpha);

  /// Creates a new color from a CSS color string. For more information, see
  /// <https://developer.mozilla.org/en/CSS/color>.
  Color.css(String color) : _argb = Color._convertCssToArgb(color)!;

  // TODO(jmesserly): I found the use of percents a bit suprising.
  /// HSL takes three values.  The [hueDegree] degree on the color wheel; '0' is
  /// the least and '100' is the greatest.  The value '0' or '360' is red, '120'
  /// is green, '240' is blue. Numbers in between reflect different shades.
  /// The [saturationPercent] percentage; where'0' is the least and '100' is the
  /// greatest (100 represents full color).  The [lightnessPercent] percentage;
  /// where'0' is the least and '100' is the greatest.  The value 0 is dark or
  /// black, 100 is light or white and 50 is a medium lightness.
  ///
  /// If [alpha] is provided, it is the level of translucency which ranges from
  /// '0' (completely transparent foreground) to '1.0' (completely opaque
  /// foreground).
  Color.createHsla(num hueDegree, num saturationPercent, num lightnessPercent,
      [num? alpha])
      : _argb = Hsla(
                Color._clamp(hueDegree, 0, 360) / 360,
                Color._clamp(saturationPercent, 0, 100) / 100,
                Color._clamp(lightnessPercent, 0, 100) / 100,
                alpha != null ? Color._clamp(alpha, 0, 1) : alpha)
            .toHexArgbString();

  /// The hslaRaw takes three values.  The [hue] degree on the color wheel; '0'
  /// is the least and '1' is the greatest.  The value '0' or '1' is red, the
  /// ratio of 120/360 is green, and the ratio of 240/360 is blue.  Numbers in
  /// between reflect different shades.  The [saturation] is a percentage; '0'
  /// is the least and '1' is the greatest.  The value of '1' is equivalent to
  /// 100% (full colour).  The [lightness] is a percentage; '0' is the least and
  /// '1' is the greatest.  The value of '0' is dark (black), the value of '1'
  /// is light (white), and the value of '.50' is a medium lightness.
  ///
  /// The fourth optional parameter is:
  ///   [alpha]      level of translucency range of values is 0..1, zero is a
  ///                completely transparent foreground and 1 is a completely
  ///                opaque foreground.
  Color.hslaRaw(num hue, num saturation, num lightness, [num? alpha])
      : _argb = Hsla(
                Color._clamp(hue, 0, 1),
                Color._clamp(saturation, 0, 1),
                Color._clamp(lightness, 0, 1),
                alpha != null ? Color._clamp(alpha, 0, 1) : alpha)
            .toHexArgbString();

  /// Generate a real constant for pre-defined colors (no leading #).
  const Color.hex(this._argb);

  // TODO(jmesserly): this is needed by the example so leave it exposed for now.
  @override
  String toString() => cssExpression;

  // TODO(terry): Regardless of how color is set (rgb, num, css or hsl) we'll
  //              always return a rgb or rgba loses fidelity when debugging in
  //              CSS if user uses hsl and would like to edit as hsl, etc.  If
  //              this is an issue we should keep the original value and not re-
  //              create the CSS from the normalized value.
  @override
  String get cssExpression {
    if (_argb.length == 6) {
      return '#$_argb'; // RGB only, no alpha blending.
    } else {
      num alpha = Color.hexToInt(_argb.substring(0, 2));
      var a = (alpha / 255).toStringAsPrecision(2);
      var r = Color.hexToInt(_argb.substring(2, 4));
      var g = Color.hexToInt(_argb.substring(4, 6));
      var b = Color.hexToInt(_argb.substring(6, 8));
      return 'rgba($r,$g,$b,$a)';
    }
  }

  Rgba get rgba {
    var nextIndex = 0;
    num? a;
    if (_argb.length == 8) {
      // Get alpha blending value 0..255
      var alpha = Color.hexToInt(_argb.substring(nextIndex, nextIndex + 2));
      // Convert to value from 0..1
      a = double.parse((alpha / 255).toStringAsPrecision(2));
      nextIndex += 2;
    }
    var r = Color.hexToInt(_argb.substring(nextIndex, nextIndex + 2));
    nextIndex += 2;
    var g = Color.hexToInt(_argb.substring(nextIndex, nextIndex + 2));
    nextIndex += 2;
    var b = Color.hexToInt(_argb.substring(nextIndex, nextIndex + 2));
    return Rgba(r, g, b, a);
  }

  Hsla get hsla => Hsla.fromRgba(rgba);

  @override
  int get argbValue => Color.hexToInt(_argb);

  @override
  bool operator ==(other) => Color.equal(this, other);

  @override
  String toHexArgbString() => _argb;

  Color darker(num amount) {
    var newRgba = Color._createNewTintShadeFromRgba(rgba, -amount);
    return Color.hex('${newRgba.toHexArgbString()}');
  }

  Color lighter(num amount) {
    var newRgba = Color._createNewTintShadeFromRgba(rgba, amount);
    return Color.hex('${newRgba.toHexArgbString()}');
  }

  static bool equal(ColorBase curr, other) {
    if (other is Color) {
      var o = other;
      return o.toHexArgbString() == curr.toHexArgbString();
    } else if (other is Rgba) {
      var rgb = other;
      return rgb.toHexArgbString() == curr.toHexArgbString();
    } else if (other is Hsla) {
      var hsla = other;
      return hsla.toHexArgbString() == curr.toHexArgbString();
    } else {
      return false;
    }
  }

  @override
  int get hashCode => _argb.hashCode;

  // Conversion routines:

  static String _rgbToArgbString(int rgba, num? alpha) {
    num? a;
    // If alpha is defined then adjust from 0..1 to 0..255 value, if not set
    // then a is left as undefined and passed to convertToHexString.
    if (alpha != null) {
      a = (Color._clamp(alpha, 0, 1) * 255).round();
    }

    var r = (rgba & 0xff0000) >> 0x10;
    var g = (rgba & 0xff00) >> 8;
    var b = rgba & 0xff;

    return Color.convertToHexString(r, g, b, a);
  }

  static const int _rgbCss = 1;
  static const int _rgbaCss = 2;
  static const int _hslCss = 3;
  static const int _hslaCss = 4;

  /// Parse CSS expressions of the from #rgb, rgb(r,g,b), rgba(r,g,b,a),
  /// hsl(h,s,l), hsla(h,s,l,a) and SVG colors (e.g., darkSlateblue, etc.) and
  /// convert to argb.
  static String? _convertCssToArgb(String value) {
    // TODO(terry): Better parser/regex for converting CSS properties.
    var color = value.trim().replaceAll('\\s', '');
    if (color[0] == '#') {
      var v = color.substring(1);
      Color.hexToInt(v); // Valid hexadecimal, throws if not.
      return v;
    } else if (color.isNotEmpty && color[color.length - 1] == ')') {
      int type;
      if (color.indexOf('rgb(') == 0 || color.indexOf('RGB(') == 0) {
        color = color.substring(4);
        type = _rgbCss;
      } else if (color.indexOf('rgba(') == 0 || color.indexOf('RGBA(') == 0) {
        type = _rgbaCss;
        color = color.substring(5);
      } else if (color.indexOf('hsl(') == 0 || color.indexOf('HSL(') == 0) {
        type = _hslCss;
        color = color.substring(4);
      } else if (color.indexOf('hsla(') == 0 || color.indexOf('HSLA(') == 0) {
        type = _hslaCss;
        color = color.substring(5);
      } else {
        throw UnsupportedError('CSS property not implemented');
      }

      color = color.substring(0, color.length - 1); // Strip close paren.

      var args = <num>[];
      var params = color.split(',');
      for (var param in params) {
        args.add(double.parse(param));
      }
      switch (type) {
        case _rgbCss:
          return Color.convertToHexString(
              args[0].toInt(), args[1].toInt(), args[2].toInt());
        case _rgbaCss:
          return Color.convertToHexString(
              args[0].toInt(), args[1].toInt(), args[2].toInt(), args[3]);
        case _hslCss:
          return Hsla(args[0], args[1], args[2]).toHexArgbString();
        case _hslaCss:
          return Hsla(args[0], args[1], args[2], args[3]).toHexArgbString();
        default:
          // Type not defined UnsupportedOperationException should have thrown.
          assert(false);
          break;
      }
    }
    return null;
  }

  static int hexToInt(String hex) => int.parse(hex, radix: 16);

  static String convertToHexString(int r, int g, int b, [num? a]) {
    var rHex = Color._numAs2DigitHex(Color._clamp(r, 0, 255));
    var gHex = Color._numAs2DigitHex(Color._clamp(g, 0, 255));
    var bHex = Color._numAs2DigitHex(Color._clamp(b, 0, 255));
    var aHex = (a != null)
        ? Color._numAs2DigitHex((Color._clamp(a, 0, 1) * 255).round())
        : '';

    // TODO(terry) 15.toRadixString(16) return 'F' on Dartium not f as in JS.
    //             bug: <http://code.google.com/p/dart/issues/detail?id=2670>
    return '$aHex$rHex$gHex$bHex'.toLowerCase();
  }

  static String _numAs2DigitHex(int v) => v.toRadixString(16).padLeft(2, '0');

  static T _clamp<T extends num>(T value, T min, T max) =>
      math.max(math.min(max, value), min);

  /// Change the tint (make color lighter) or shade (make color darker) of all
  /// parts of [rgba] (r, g and b).  The [amount] is percentage darker between
  /// -1 to 0 for darker and 0 to 1 for lighter; '0' is no change.  The [amount]
  /// will darken or lighten the rgb values; it will not change the alpha value.
  /// If [amount] is outside of the value -1 to +1 then [amount] is changed to
  /// either the min or max direction -1 or 1.
  ///
  /// Darker will approach the color #000000 (black) and lighter will approach
  /// the color #ffffff (white).
  static Rgba _createNewTintShadeFromRgba(Rgba rgba, num amount) {
    int r, g, b;
    var tintShade = Color._clamp(amount, -1, 1);
    if (amount < 0 && rgba.r == 255 && rgba.g == 255 && rgba.b == 255) {
      // TODO(terry): See TODO in _changeTintShadeColor; eliminate this test
      //              by converting to HSL and adjust lightness although this
      //              is fastest lighter/darker algorithm.
      // Darkening white special handling.
      r = Color._clamp((255 + (255 * tintShade)).round().toInt(), 0, 255);
      g = Color._clamp((255 + (255 * tintShade)).round().toInt(), 0, 255);
      b = Color._clamp((255 + (255 * tintShade)).round().toInt(), 0, 255);
    } else {
      // All other colors then darkening white go here.
      r = Color._changeTintShadeColor(rgba.r, tintShade).round().toInt();
      g = Color._changeTintShadeColor(rgba.g, tintShade).round().toInt();
      b = Color._changeTintShadeColor(rgba.b, tintShade).round().toInt();
    }
    return Rgba(r, g, b, rgba.a);
  }

  // TODO(terry): This does an okay lighter/darker; better would be convert to
  //              HSL then change the lightness.
  /// The parameter [v] is the color to change (r, g, or b) in the range '0' to
  /// '255'. The parameter [delta] is a number between '-1' and '1'.  A value
  /// between '-1' and '0' is darker and a value between '0' and '1' is lighter
  /// ('0' imples no change).
  static num _changeTintShadeColor(num v, num delta) =>
      Color._clamp(((1 - delta) * v + (delta * 255)).round(), 0, 255);

  // Predefined CSS colors see <http://www.w3.org/TR/css3-color/>
  static final Color transparent = const Color.hex('00ffffff'); // Alpha 0.0
  static final Color aliceBlue = const Color.hex('0f08ff');
  static final Color antiqueWhite = const Color.hex('0faebd7');
  static final Color aqua = const Color.hex('00ffff');
  static final Color aquaMarine = const Color.hex('7fffd4');
  static final Color azure = const Color.hex('f0ffff');
  static final Color beige = const Color.hex('f5f5dc');
  static final Color bisque = const Color.hex('ffe4c4');
  static final Color black = const Color.hex('000000');
  static final Color blanchedAlmond = const Color.hex('ffebcd');
  static final Color blue = const Color.hex('0000ff');
  static final Color blueViolet = const Color.hex('8a2be2');
  static final Color brown = const Color.hex('a52a2a');
  static final Color burlyWood = const Color.hex('deb887');
  static final Color cadetBlue = const Color.hex('5f9ea0');
  static final Color chartreuse = const Color.hex('7fff00');
  static final Color chocolate = const Color.hex('d2691e');
  static final Color coral = const Color.hex('ff7f50');
  static final Color cornFlowerBlue = const Color.hex('6495ed');
  static final Color cornSilk = const Color.hex('fff8dc');
  static final Color crimson = const Color.hex('dc143c');
  static final Color cyan = const Color.hex('00ffff');
  static final Color darkBlue = const Color.hex('00008b');
  static final Color darkCyan = const Color.hex('008b8b');
  static final Color darkGoldenRod = const Color.hex('b8860b');
  static final Color darkGray = const Color.hex('a9a9a9');
  static final Color darkGreen = const Color.hex('006400');
  static final Color darkGrey = const Color.hex('a9a9a9');
  static final Color darkKhaki = const Color.hex('bdb76b');
  static final Color darkMagenta = const Color.hex('8b008b');
  static final Color darkOliveGreen = const Color.hex('556b2f');
  static final Color darkOrange = const Color.hex('ff8c00');
  static final Color darkOrchid = const Color.hex('9932cc');
  static final Color darkRed = const Color.hex('8b0000');
  static final Color darkSalmon = const Color.hex('e9967a');
  static final Color darkSeaGreen = const Color.hex('8fbc8f');
  static final Color darkSlateBlue = const Color.hex('483d8b');
  static final Color darkSlateGray = const Color.hex('2f4f4f');
  static final Color darkSlateGrey = const Color.hex('2f4f4f');
  static final Color darkTurquoise = const Color.hex('00ced1');
  static final Color darkViolet = const Color.hex('9400d3');
  static final Color deepPink = const Color.hex('ff1493');
  static final Color deepSkyBlue = const Color.hex('00bfff');
  static final Color dimGray = const Color.hex('696969');
  static final Color dimGrey = const Color.hex('696969');
  static final Color dodgerBlue = const Color.hex('1e90ff');
  static final Color fireBrick = const Color.hex('b22222');
  static final Color floralWhite = const Color.hex('fffaf0');
  static final Color forestGreen = const Color.hex('228b22');
  static final Color fuchsia = const Color.hex('ff00ff');
  static final Color gainsboro = const Color.hex('dcdcdc');
  static final Color ghostWhite = const Color.hex('f8f8ff');
  static final Color gold = const Color.hex('ffd700');
  static final Color goldenRod = const Color.hex('daa520');
  static final Color gray = const Color.hex('808080');
  static final Color green = const Color.hex('008000');
  static final Color greenYellow = const Color.hex('adff2f');
  static final Color grey = const Color.hex('808080');
  static final Color honeydew = const Color.hex('f0fff0');
  static final Color hotPink = const Color.hex('ff69b4');
  static final Color indianRed = const Color.hex('cd5c5c');
  static final Color indigo = const Color.hex('4b0082');
  static final Color ivory = const Color.hex('fffff0');
  static final Color khaki = const Color.hex('f0e68c');
  static final Color lavender = const Color.hex('e6e6fa');
  static final Color lavenderBlush = const Color.hex('fff0f5');
  static final Color lawnGreen = const Color.hex('7cfc00');
  static final Color lemonChiffon = const Color.hex('fffacd');
  static final Color lightBlue = const Color.hex('add8e6');
  static final Color lightCoral = const Color.hex('f08080');
  static final Color lightCyan = const Color.hex('e0ffff');
  static final Color lightGoldenRodYellow = const Color.hex('fafad2');
  static final Color lightGray = const Color.hex('d3d3d3');
  static final Color lightGreen = const Color.hex('90ee90');
  static final Color lightGrey = const Color.hex('d3d3d3');
  static final Color lightPink = const Color.hex('ffb6c1');
  static final Color lightSalmon = const Color.hex('ffa07a');
  static final Color lightSeaGreen = const Color.hex('20b2aa');
  static final Color lightSkyBlue = const Color.hex('87cefa');
  static final Color lightSlateGray = const Color.hex('778899');
  static final Color lightSlateGrey = const Color.hex('778899');
  static final Color lightSteelBlue = const Color.hex('b0c4de');
  static final Color lightYellow = const Color.hex('ffffe0');
  static final Color lime = const Color.hex('00ff00');
  static final Color limeGreen = const Color.hex('32cd32');
  static final Color linen = const Color.hex('faf0e6');
  static final Color magenta = const Color.hex('ff00ff');
  static final Color maroon = const Color.hex('800000');
  static final Color mediumAquaMarine = const Color.hex('66cdaa');
  static final Color mediumBlue = const Color.hex('0000cd');
  static final Color mediumOrchid = const Color.hex('ba55d3');
  static final Color mediumPurple = const Color.hex('9370db');
  static final Color mediumSeaGreen = const Color.hex('3cb371');
  static final Color mediumSlateBlue = const Color.hex('7b68ee');
  static final Color mediumSpringGreen = const Color.hex('00fa9a');
  static final Color mediumTurquoise = const Color.hex('48d1cc');
  static final Color mediumVioletRed = const Color.hex('c71585');
  static final Color midnightBlue = const Color.hex('191970');
  static final Color mintCream = const Color.hex('f5fffa');
  static final Color mistyRose = const Color.hex('ffe4e1');
  static final Color moccasin = const Color.hex('ffe4b5');
  static final Color navajoWhite = const Color.hex('ffdead');
  static final Color navy = const Color.hex('000080');
  static final Color oldLace = const Color.hex('fdf5e6');
  static final Color olive = const Color.hex('808000');
  static final Color oliveDrab = const Color.hex('6b8e23');
  static final Color orange = const Color.hex('ffa500');
  static final Color orangeRed = const Color.hex('ff4500');
  static final Color orchid = const Color.hex('da70d6');
  static final Color paleGoldenRod = const Color.hex('eee8aa');
  static final Color paleGreen = const Color.hex('98fb98');
  static final Color paleTurquoise = const Color.hex('afeeee');
  static final Color paleVioletRed = const Color.hex('db7093');
  static final Color papayaWhip = const Color.hex('ffefd5');
  static final Color peachPuff = const Color.hex('ffdab9');
  static final Color peru = const Color.hex('cd85ef');
  static final Color pink = const Color.hex('ffc0cb');
  static final Color plum = const Color.hex('dda0dd');
  static final Color powderBlue = const Color.hex('b0e0e6');
  static final Color purple = const Color.hex('800080');
  static final Color red = const Color.hex('ff0000');
  static final Color rosyBrown = const Color.hex('bc8f8f');
  static final Color royalBlue = const Color.hex('4169e1');
  static final Color saddleBrown = const Color.hex('8b4513');
  static final Color salmon = const Color.hex('fa8072');
  static final Color sandyBrown = const Color.hex('f4a460');
  static final Color seaGreen = const Color.hex('2e8b57');
  static final Color seashell = const Color.hex('fff5ee');
  static final Color sienna = const Color.hex('a0522d');
  static final Color silver = const Color.hex('c0c0c0');
  static final Color skyBlue = const Color.hex('87ceeb');
  static final Color slateBlue = const Color.hex('6a5acd');
  static final Color slateGray = const Color.hex('708090');
  static final Color slateGrey = const Color.hex('708090');
  static final Color snow = const Color.hex('fffafa');
  static final Color springGreen = const Color.hex('00ff7f');
  static final Color steelBlue = const Color.hex('4682b4');
  static final Color tan = const Color.hex('d2b48c');
  static final Color teal = const Color.hex('008080');
  static final Color thistle = const Color.hex('d8bfd8');
  static final Color tomato = const Color.hex('ff6347');
  static final Color turquoise = const Color.hex('40e0d0');
  static final Color violet = const Color.hex('ee82ee');
  static final Color wheat = const Color.hex('f5deb3');
  static final Color white = const Color.hex('ffffff');
  static final Color whiteSmoke = const Color.hex('f5f5f5');
  static final Color yellow = const Color.hex('ffff00');
  static final Color yellowGreen = const Color.hex('9acd32');
}

/// Rgba class for users that want to interact with a color as a RGBA value.
class Rgba implements _StyleProperty, ColorBase {
  // TODO(terry): Consider consolidating rgba to a single 32-bit int, make sure
  //              it works under JS and Dart VM.
  final int r;
  final int g;
  final int b;
  final num? a;

  Rgba(int red, int green, int blue, [num? alpha])
      : r = Color._clamp(red, 0, 255),
        g = Color._clamp(green, 0, 255),
        b = Color._clamp(blue, 0, 255),
        a = (alpha != null) ? Color._clamp(alpha, 0, 1) : alpha;

  factory Rgba.fromString(String hexValue) =>
      Color.css('#${Color._convertCssToArgb(hexValue)}').rgba;

  factory Rgba.fromColor(Color color) => color.rgba;

  factory Rgba.fromArgbValue(num value) {
    return Rgba(
        ((value.toInt() & 0xff000000) >> 0x18), // a
        ((value.toInt() & 0xff0000) >> 0x10), // r
        ((value.toInt() & 0xff00) >> 8), // g
        ((value.toInt() & 0xff))); // b
  }

  factory Rgba.fromHsla(Hsla hsla) {
    // Convert to Rgba.
    // See site <http://easyrgb.com/index.php?X=MATH> for good documentation
    // and color conversion routines.

    var h = hsla.hue;
    var s = hsla.saturation;
    var l = hsla.lightness;
    var a = hsla.alpha;

    int r;
    int g;
    int b;

    if (s == 0) {
      r = (l * 255).round().toInt();
      g = r;
      b = r;
    } else {
      num var2;

      if (l < 0.5) {
        var2 = l * (1 + s);
      } else {
        var2 = (l + s) - (s * l);
      }
      var var1 = 2 * l - var2;

      r = (255 * Rgba._hueToRGB(var1, var2, h + (1 / 3))).round().toInt();
      g = (255 * Rgba._hueToRGB(var1, var2, h)).round().toInt();
      b = (255 * Rgba._hueToRGB(var1, var2, h - (1 / 3))).round().toInt();
    }

    return Rgba(r, g, b, a);
  }

  static num _hueToRGB(num v1, num v2, num vH) {
    if (vH < 0) {
      vH += 1;
    }

    if (vH > 1) {
      vH -= 1;
    }

    if ((6 * vH) < 1) {
      return (v1 + (v2 - v1) * 6 * vH);
    }

    if ((2 * vH) < 1) {
      return v2;
    }

    if ((3 * vH) < 2) {
      return (v1 + (v2 - v1) * ((2 / 3 - vH) * 6));
    }

    return v1;
  }

  @override
  bool operator ==(other) => Color.equal(this, other);

  @override
  String get cssExpression {
    if (a == null) {
      return '#${Color.convertToHexString(r, g, b)}';
    } else {
      return 'rgba($r,$g,$b,$a)';
    }
  }

  @override
  String toHexArgbString() => Color.convertToHexString(r, g, b, a);

  @override
  int get argbValue {
    var value = 0;
    if (a != null) {
      value = (a!.toInt() << 0x18);
    }
    value += (r << 0x10);
    value += (g << 0x08);
    value += b;
    return value;
  }

  Color get color => Color.createRgba(r, g, b, a);
  Hsla get hsla => Hsla.fromRgba(this);

  Rgba darker(num amount) => Color._createNewTintShadeFromRgba(this, -amount);
  Rgba lighter(num amount) => Color._createNewTintShadeFromRgba(this, amount);

  @override
  int get hashCode => toHexArgbString().hashCode;
}

/// Hsl class support to interact with a color as a hsl with hue, saturation,
/// and lightness with optional alpha blending.  The hue is a ratio of 360
/// degrees 360° = 1 or 0, (1° == (1/360)), saturation and lightness is a 0..1
/// fraction (1 == 100%) and alpha is a 0..1 fraction.
class Hsla implements _StyleProperty, ColorBase {
  final num _h; // Value from 0..1
  final num _s; // Value from 0..1
  final num _l; // Value from 0..1
  final num? _a; // Value from 0..1

  /// [hue] is a 0..1 fraction of 360 degrees (360 == 0).
  /// [saturation] is a 0..1 fraction (100% == 1).
  /// [lightness] is a 0..1 fraction (100% == 1).
  /// [alpha] is a 0..1 fraction, alpha blending between 0..1, 1 == 100% opaque.
  Hsla(num hue, num saturation, num lightness, [num? alpha])
      : _h = (hue == 1) ? 0 : Color._clamp(hue, 0, 1),
        _s = Color._clamp(saturation, 0, 1),
        _l = Color._clamp(lightness, 0, 1),
        _a = (alpha != null) ? Color._clamp(alpha, 0, 1) : alpha;

  factory Hsla.fromString(String hexValue) {
    var rgba = Color.css('#${Color._convertCssToArgb(hexValue)}').rgba;
    return _createFromRgba(rgba.r, rgba.g, rgba.b, rgba.a);
  }

  factory Hsla.fromColor(Color color) {
    var rgba = color.rgba;
    return _createFromRgba(rgba.r, rgba.g, rgba.b, rgba.a);
  }

  factory Hsla.fromArgbValue(num value) {
    num a = (value.toInt() & 0xff000000) >> 0x18;
    var r = (value.toInt() & 0xff0000) >> 0x10;
    var g = (value.toInt() & 0xff00) >> 8;
    var b = value.toInt() & 0xff;

    // Convert alpha to 0..1 from (0..255).
    a = double.parse((a / 255).toStringAsPrecision(2));

    return _createFromRgba(r, g, b, a);
  }

  factory Hsla.fromRgba(Rgba rgba) =>
      _createFromRgba(rgba.r, rgba.g, rgba.b, rgba.a);

  static Hsla _createFromRgba(num r, num g, num b, num? a) {
    // Convert RGB to hsl.
    // See site <http://easyrgb.com/index.php?X=MATH> for good documentation
    // and color conversion routines.
    r /= 255;
    g /= 255;
    b /= 255;

    // Hue, saturation and lightness.
    num h;
    num s;
    num l;

    var minRgb = math.min(r, math.min(g, b));
    var maxRgb = math.max(r, math.max(g, b));
    l = (maxRgb + minRgb) / 2;
    if (l <= 0) {
      return Hsla(0, 0, l); // Black;
    }

    var vm = maxRgb - minRgb;
    s = vm;
    if (s > 0) {
      s /= (l < 0.5) ? (maxRgb + minRgb) : (2 - maxRgb - minRgb);
    } else {
      return Hsla(0, 0, l); // White
    }

    num r2, g2, b2;
    r2 = (maxRgb - r) / vm;
    g2 = (maxRgb - g) / vm;
    b2 = (maxRgb - b) / vm;
    if (r == maxRgb) {
      h = (g == minRgb) ? 5.0 + b2 : 1 - g2;
    } else if (g == maxRgb) {
      h = (b == minRgb) ? 1 + r2 : 3 - b2;
    } else {
      h = (r == minRgb) ? 3 + g2 : 5 - r2;
    }
    h /= 6;

    return Hsla(h, s, l, a);
  }

  /// Returns 0..1 fraction (ratio of 360°, e.g. 1° == 1/360).
  num get hue => _h;

  /// Returns 0..1 fraction (1 == 100%)
  num get saturation => _s;

  /// Returns 0..1 fraction (1 == 100%).
  num get lightness => _l;

  /// Returns number as degrees 0..360.
  num get hueDegrees => (_h * 360).round();

  /// Returns number as percentage 0..100
  num get saturationPercentage => (_s * 100).round();

  /// Returns number as percentage 0..100.
  num get lightnessPercentage => (_l * 100).round();

  /// Returns number as 0..1
  num? get alpha => _a;

  @override
  bool operator ==(other) => Color.equal(this, other);

  @override
  String get cssExpression => (_a == null)
      ? 'hsl($hueDegrees,$saturationPercentage,$lightnessPercentage)'
      : 'hsla($hueDegrees,$saturationPercentage,$lightnessPercentage,$_a)';

  @override
  String toHexArgbString() => Rgba.fromHsla(this).toHexArgbString();

  @override
  int get argbValue => Color.hexToInt(toHexArgbString());

  Color get color => Color.createHsla(_h, _s, _l, _a);
  Rgba get rgba => Rgba.fromHsla(this);

  Hsla darker(num amount) => Hsla.fromRgba(Rgba.fromHsla(this).darker(amount));

  Hsla lighter(num amount) =>
      Hsla.fromRgba(Rgba.fromHsla(this).lighter(amount));

  @override
  int get hashCode => toHexArgbString().hashCode;
}

/// X,Y position.
class PointXY implements _StyleProperty {
  final num x, y;
  const PointXY(this.x, this.y);

  @override
  String? get cssExpression {
    // TODO(terry): TBD
    return null;
  }
}

// TODO(terry): Implement style and color.
/// Supports border for measuring with layout.
class Border implements _StyleProperty {
  final int? top, left, bottom, right;

  // TODO(terry): Just like CSS, 1-arg -> set all properties, 2-args -> top and
  //               bottom are first arg, left and right are second, 3-args, and
  //               4-args -> tlbr or trbl.
  const Border([this.top, this.left, this.bottom, this.right]);

  // TODO(terry): Consider using Size or width and height.
  Border.uniform(int amount)
      : top = amount,
        left = amount,
        bottom = amount,
        right = amount;

  int get width => left! + right!;
  int get height => top! + bottom!;

  @override
  String get cssExpression {
    return (top == left && bottom == right && top == right)
        ? '${left}px'
        : "${top != null ? '$top' : '0'}px "
            "${right != null ? '$right' : '0'}px "
            "${bottom != null ? '$bottom' : '0'}px "
            "${left != null ? '$left' : '0'}px";
  }
}

/// Font style constants.
class FontStyle {
  /// Font style [normal] default.
  static const String normal = 'normal';

  /// Font style [italic] use explicity crafted italic font otherwise inclined
  /// on the fly like oblique.
  static const String italic = 'italic';

  /// Font style [oblique] is rarely used. The normal style of a font is
  /// inclined on the fly to the right by 8-12 degrees.
  static const String oblique = 'oblique';
}

/// Font variant constants.
class FontVariant {
  /// Font style [normal] default.
  static const String normal = 'normal';

  /// Font variant [smallCaps].
  static const String smallCaps = 'small-caps';
}

/// Font weight constants values 100, 200, 300, 400, 500, 600, 700, 800, 900.
class FontWeight {
  /// Font weight normal [default]
  static const int normal = 400;

  /// Font weight bold
  static const int bold = 700;

  static const int wt100 = 100;
  static const int wt200 = 200;
  static const int wt300 = 300;
  static const int wt400 = 400;
  static const int wt500 = 500;
  static const int wt600 = 600;
  static const int wt700 = 700;
  static const int wt800 = 800;
  static const int wt900 = 900;
}

/// Generic font family names.
class FontGeneric {
  /// Generic family sans-serif font (w/o serifs).
  static const String sansSerif = 'sans-serif';

  /// Generic family serif font.
  static const String serif = 'serif';

  /// Generic family fixed-width font.
  static const monospace = 'monospace';

  /// Generic family emulate handwriting font.
  static const String cursive = 'cursive';

  /// Generic family decorative font.
  static const String fantasy = 'fantasy';
}

/// List of most common font families across different platforms.  Use the
/// collection names in the Font class (e.g., Font.SANS_SERIF, Font.FONT_SERIF,
/// Font.MONOSPACE, Font.CURSIVE or Font.FANTASY).  These work best on all
/// platforms using the fonts that best match availability on each platform.
/// See <http://www.angelfire.com/al4/rcollins/style/fonts.html> for a good
/// description of fonts available between platforms and browsers.
class FontFamily {
  /// Sans-Serif font for Windows similar to Helvetica on Mac bold/italic.
  static const String arial = 'arial';

  /// Sans-Serif font for Windows less common already bolded.
  static const String arialBlack = 'arial black';

  /// Sans-Serif font for Mac since 1984, similar to Arial/Helvetica.
  static const String geneva = 'geneva';

  /// Sans-Serif font for Windows most readable sans-serif font for displays.
  static const String verdana = 'verdana';

  /// Sans-Serif font for Mac since 1984 is identical to Arial.
  static const String helvetica = 'helvetica';

  /// Serif font for Windows traditional font with “old-style” numerals.
  static const String georgia = 'georgia';

  /// Serif font for Mac. PCs may have the non-scalable Times use Times New
  /// Roman instead.  Times is more compact than Times New Roman.
  static const String times = 'times';

  /// Serif font for Windows most common serif font and default serif font for
  /// most browsers.
  static const String timesNewRoman = 'times new roman';

  /// Monospace font for Mac/Windows most common. Scalable on Mac not scalable
  /// on Windows.
  static const String courier = 'courier';

  /// Monospace font for Mac/Windows scalable on both platforms.
  static const String courierNew = 'courier new';

  /// Cursive font for Windows and default cursive font for IE.
  static const String comicSansMs = 'comic sans ms';

  /// Cursive font for Mac on Macs 2000 and newer.
  static const String textile = 'textile';

  /// Cursive font for older Macs.
  static const String appleChancery = 'apple chancery';

  /// Cursive font for some PCs.
  static const String zaphChancery = 'zaph chancery';

  /// Fantasy font on most Mac/Windows/Linux platforms.
  static const String impact = 'impact';

  /// Fantasy font for Windows.
  static const String webdings = 'webdings';
}

class LineHeight {
  final num height;
  final bool inPixels;
  const LineHeight(this.height, {this.inPixels = true});
}

// TODO(terry): Support @font-face fule.
/// Font style support for size, family, weight, style, variant, and lineheight.
class Font implements _StyleProperty {
  /// Collection of most common sans-serif fonts in order.
  static const List<String> sansSerif = [
    FontFamily.arial,
    FontFamily.verdana,
    FontFamily.geneva,
    FontFamily.helvetica,
    FontGeneric.sansSerif
  ];

  /// Collection of most common serif fonts in order.
  static const List<String> serif = [
    FontFamily.georgia,
    FontFamily.timesNewRoman,
    FontFamily.times,
    FontGeneric.serif
  ];

  /// Collection of most common monospace fonts in order.
  static const List<String> monospace = [
    FontFamily.courierNew,
    FontFamily.courier,
    FontGeneric.monospace
  ];

  /// Collection of most common cursive fonts in order.
  static const List<String> cursive = [
    FontFamily.textile,
    FontFamily.appleChancery,
    FontFamily.zaphChancery,
    FontGeneric.fantasy
  ];

  /// Collection of most common fantasy fonts in order.
  static const List<String> fantasy = [
    FontFamily.comicSansMs,
    FontFamily.impact,
    FontFamily.webdings,
    FontGeneric.fantasy
  ];

  // TODO(terry): Should support the values xx-small, small, large, xx-large,
  //              etc. (mapped to a pixel sized font)?
  /// Font size in pixels.
  final num? size;

  // TODO(terry): _family should be an immutable list, wrapper class to do this
  //              should exist in Dart.
  /// Family specifies a list of fonts, the browser will sequentially select the
  /// the first known/supported font.  There are two types of font families the
  /// family-name (e.g., arial, times, courier, etc) or the generic-family
  /// (e.g., serif, sans-seric, etc.)
  final List<String>? family;

  /// Font weight from 100, 200, 300, 400, 500, 600, 700, 800, 900
  final int? weight;

  /// Style of a font normal, italic, oblique.
  final String? style;

  /// Font variant NORMAL (default) or SMALL_CAPS.  Different set of font glyph
  /// lower case letters designed to have to fit within the font-height and
  /// weight of the corresponding lowercase letters.
  final String? variant;

  final LineHeight? lineHeight;

  // TODO(terry): Size and computedLineHeight are in pixels.  Need to figure out
  //              how to handle in other units (specified in other units) like
  //              points, inches, etc.  Do we have helpers like Units.Points(12)
  //              where 12 is in points and that's converted to pixels?
  // TODO(terry): lineHeight is computed as 1.2 although CSS_RESET is 1.0 we
  //              need to be consistent some browsers use 1 others 1.2.
  // TODO(terry): There is a school of thought "Golden Ratio Typography".
  // Where width to display the text is also important in computing the line
  // height.  Classic typography suggest the ratio be 1.5.  See
  // <http://www.pearsonified.com/2011/12/golden-ratio-typography.php> and
  // <http://meyerweb.com/eric/thoughts/2008/05/06/line-height-abnormal/>.
  /// Create a font using [size] of font in pixels, [family] name of font(s)
  /// using [FontFamily], [style] of the font using [FontStyle], [variant] using
  /// [FontVariant], and [lineHeight] extra space (leading) around the font in
  /// pixels, if not specified it's 1.2 the font size.
  const Font(
      {this.size,
      this.family,
      this.weight,
      this.style,
      this.variant,
      this.lineHeight});

  /// Merge the two fonts and return the result. See [Style.merge] for
  /// more information.
  static Font? merge(Font? a, Font? b) {
    if (a == null) return b;
    if (b == null) return a;
    return Font._merge(a, b);
  }

  Font._merge(Font a, Font b)
      : size = _mergeVal(a.size, b.size),
        family = _mergeVal(a.family, b.family),
        weight = _mergeVal(a.weight, b.weight),
        style = _mergeVal(a.style, b.style),
        variant = _mergeVal(a.variant, b.variant),
        lineHeight = _mergeVal(a.lineHeight, b.lineHeight);

  /// Shorthand CSS format for font is:
  ///
  ///    font-style font-variant font-weight font-size/line-height font-family
  ///
  /// The font-size and font-family values are required. If any of the other
  /// values are missing the default value is used.
  @override
  String get cssExpression {
    // TODO(jimhug): include variant, style, other options
    if (weight != null) {
      // TODO(jacobr): is this really correct for lineHeight?
      if (lineHeight != null) {
        return '$weight ${size}px/$lineHeightInPixels $_fontsAsString';
      }
      return '$weight ${size}px $_fontsAsString';
    }

    return '${size}px $_fontsAsString';
  }

  Font scale(num ratio) => Font(
      size: size! * ratio,
      family: family,
      weight: weight,
      style: style,
      variant: variant);

  /// The lineHeight, provides an indirect means to specify the leading. The
  /// leading is the difference between the font-size height and the (used)
  /// value of line height in pixels.  If lineHeight is not specified it's
  /// automatically computed as 1.2 of the font size.  Firefox is 1.2, Safari is
  /// ~1.2, and CSS suggest a ration from 1 to 1.2 of the font-size when
  /// computing line-height. The Font class constructor has the computation for
  /// _lineHeight.
  num? get lineHeightInPixels {
    if (lineHeight != null) {
      if (lineHeight!.inPixels) {
        return lineHeight!.height;
      } else {
        return (size != null) ? lineHeight!.height * size! : null;
      }
    } else {
      return (size != null) ? size! * 1.2 : null;
    }
  }

  @override
  int get hashCode {
    // TODO(jimhug): Lot's of potential collisions here. List of fonts, etc.
    return size!.toInt() % family![0].hashCode;
  }

  @override
  bool operator ==(other) {
    if (other is! Font) return false;
    return other.size == size &&
        other.family == family &&
        other.weight == weight &&
        other.lineHeight == lineHeight &&
        other.style == style &&
        other.variant == variant;
  }

  // TODO(terry): This is fragile should probably just iterate through the list
  //              of fonts construction the font-family string.
  /// Return fonts as a comma seperated list sans the square brackets.
  String get _fontsAsString {
    var fonts = family.toString();
    return fonts.length > 2 ? fonts.substring(1, fonts.length - 1) : '';
  }
}

/// This class stores the sizes of the box edges in the CSS [box model][]. Each
/// edge area is placed around the sides of the content box. The innermost area
/// is the [Style.padding] area which has a background and surrounds the
/// content.  The content and padding area is surrounded by the [Style.border],
/// which itself is surrounded by the transparent [Style.margin]. This box
/// represents the eges of padding, border, or margin depending on which
/// accessor was used to retrieve it.
///
/// [box model]: https://developer.mozilla.org/en/CSS/box_model
class BoxEdge {
  /// The size of the left edge, or null if the style has no edge.
  final num? left;

  /// The size of the top edge, or null if the style has no edge.
  final num? top;

  /// The size of the right edge, or null if the style has no edge.
  final num? right;

  /// The size of the bottom edge, or null if the style has no edge.
  final num? bottom;

  /// Creates a box edge with the specified [left], [top], [right], and
  /// [bottom] width.
  const BoxEdge([this.left, this.top, this.right, this.bottom]);

  /// Creates a box edge with the specified [top], [right], [bottom], and
  /// [left] width. This matches the typical CSS order:
  /// <https://developer.mozilla.org/en/CSS/margin>
  /// <https://developer.mozilla.org/en/CSS/border-width>
  /// <https://developer.mozilla.org/en/CSS/padding>.
  const BoxEdge.clockwiseFromTop(this.top, this.right, this.bottom, this.left);

  /// This is a helper to creates a box edge with the same [left], [top]
  /// [right], and [bottom] widths.
  const BoxEdge.uniform(num size)
      : top = size,
        left = size,
        bottom = size,
        right = size;

  /// Takes a possibly null box edge, with possibly null metrics, and fills
  /// them in with 0 instead.
  factory BoxEdge.nonNull(BoxEdge? other) {
    if (other == null) return const BoxEdge(0, 0, 0, 0);
    var left = other.left;
    var top = other.top;
    var right = other.right;
    var bottom = other.bottom;
    var make = false;
    if (left == null) {
      make = true;
      left = 0;
    }
    if (top == null) {
      make = true;
      top = 0;
    }
    if (right == null) {
      make = true;
      right = 0;
    }
    if (bottom == null) {
      make = true;
      bottom = 0;
    }
    return make ? BoxEdge(left, top, right, bottom) : other;
  }

  /// Merge the two box edge sizes and return the result. See [Style.merge] for
  /// more information.
  static BoxEdge? merge(BoxEdge? x, BoxEdge? y) {
    if (x == null) return y;
    if (y == null) return x;
    return BoxEdge._merge(x, y);
  }

  BoxEdge._merge(BoxEdge x, BoxEdge y)
      : left = _mergeVal(x.left, y.left),
        top = _mergeVal(x.top, y.top),
        right = _mergeVal(x.right, y.right),
        bottom = _mergeVal(x.bottom, y.bottom);

  /// The total size of the horizontal edges. Equal to [left] + [right], where
  /// null is interpreted as 0px.
  num get width => (left ?? 0) + (right ?? 0);

  /// The total size of the vertical edges. Equal to [top] + [bottom], where
  /// null is interpreted as 0px.
  num get height => (top ?? 0) + (bottom ?? 0);
}

T _mergeVal<T>(T x, T y) => y ?? x;
