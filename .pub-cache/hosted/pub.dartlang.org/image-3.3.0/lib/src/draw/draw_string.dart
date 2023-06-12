import 'dart:typed_data';
import '../bitmap_font.dart';
import '../color.dart';
import '../image.dart';
import 'draw_pixel.dart';

var _r_lut = Uint8List(256);
var _g_lut = Uint8List(256);
var _b_lut = Uint8List(256);
var _a_lut = Uint8List(256);

/// Draw a string horizontally into [image] horizontally into [image] at position
/// [x],[y] with the given [color].
///
/// You can load your own font, or use one of the existing ones
/// such as: [arial_14], [arial_24], or [arial_48].
//  Fonts can be create with a tool such as: https://ttf2fnt.com/
Image drawString(Image image, BitmapFont font, int x, int y, String string,
    {int color = 0xffffffff, bool rightJustify = false}) {
  if (color != 0xffffffff) {
    final ca = getAlpha(color);
    if (ca == 0) {
      return image;
    }
    final num da = ca / 255.0;
    final num dr = getRed(color) / 255.0;
    final num dg = getGreen(color) / 255.0;
    final num db = getBlue(color) / 255.0;
    for (var i = 1; i < 256; ++i) {
      _r_lut[i] = (dr * i).toInt();
      _g_lut[i] = (dg * i).toInt();
      _b_lut[i] = (db * i).toInt();
      _a_lut[i] = (da * i).toInt();
    }
  }

  final int stringHeight = findStringHeight(font, string);
  final int origX = x;
  final substrings = string.split(new RegExp(r"[(\n|\r)]"));

  for (var ss in substrings) {
    var chars = ss.codeUnits;
    if (rightJustify == true) {
      for (var c in chars) {
        if (!font.characters.containsKey(c)) {
          x -= font.base ~/ 2;
          continue;
        }

        final ch = font.characters[c]!;
        x -= ch.xadvance;
      }
    }
    for (var c in chars) {
      if (!font.characters.containsKey(c)) {
        x += font.base ~/ 2;
        continue;
      }

      final ch = font.characters[c]!;

      final x2 = x + ch.width;
      final y2 = y + ch.height;
      var pi = 0;
      for (var yi = y; yi < y2; ++yi) {
        for (var xi = x; xi < x2; ++xi) {
          var p = ch.image[pi++];
          if (color != 0xffffffff) {
            p = getColor(_r_lut[getRed(p)], _g_lut[getGreen(p)],
                _b_lut[getBlue(p)], _a_lut[getAlpha(p)]);
          }
          drawPixel(image, xi + ch.xoffset, yi + ch.yoffset, p);
        }
      }

      x += ch.xadvance;
    }
    y = y+stringHeight;
    x = origX;
  }

  return image;
}

/// Same as drawString except the strings will wrap around to create multiple lines.
/// You can load your own font, or use one of the existing ones
/// such as: [arial_14], [arial_24], or [arial_48].
Image drawStringWrap(Image image, BitmapFont font, int x, int y, String string,
    {int color = 0xffffffff}) {

  var stringHeight = findStringHeight(font, string);
  var words = string.split(new RegExp(r"\s+"));
  var subString = "";
  var x2 = x;

  for (var w in words) {
    final ws = StringBuffer();
    ws.write(w);
    ws.write(' ');
    w = ws.toString();
    final chars = w.codeUnits;
    var wordWidth = 0;
    for (var c in chars) {
      if (!font.characters.containsKey(c)) {
        wordWidth += font.base ~/ 2;
        continue;
      }
      final ch = font.characters[c]!;
      wordWidth += ch.xadvance;
    }
    if ((x2 + wordWidth) > image.width) {
      // If there is a word that won't fit the starting x, stop drawing
      if ((x == x2) || (x + wordWidth > image.width)) {
        return image;
      }

      drawString(image, font, x, y, subString, color: color);

      subString = "";
      x2 = x;
      y += stringHeight;
      subString += w;
      x2 += wordWidth;
    } else {
      subString += w;
      x2 += wordWidth;
    }

    if (subString.length > 0) {
      drawString(image, font, x, y, subString, color: color);
    }
  }

  return image;
}

/// Draw a string horizontally into [image] at position
/// [x],[y] with the given [color].
/// If x is omitted text is automatically centered into [image]
/// If y is omitted text is automatically centered into [image].
/// If both x and y are provided it has the same behaviour of drawString method.
///
/// You can load your own font, or use one of the existing ones
/// such as: [arial_14], [arial_24], or [arial_48].
Image drawStringCentered(Image image, BitmapFont font, String string,
    {int? x, int? y, int color = 0xffffffff}) {
  var stringWidth = 0;
  var stringHeight = 0;

  if (x == null || y == null) {
    final chars = string.codeUnits;
    for (var c in chars) {
      if (!font.characters.containsKey(c)) {
        continue;
      }
      final ch = font.characters[c]!;
      stringWidth += ch.xadvance;
      if (ch.height + ch.yoffset > stringHeight) {
        stringHeight = ch.height + ch.yoffset;
      }
    }
  }

  int xPos, yPos;
  if (x == null) {
    xPos = (image.width / 2).round() - (stringWidth / 2).round();
  } else {
    xPos = x;
  }
  if (y == null) {
    yPos = (image.height / 2).round() - (stringHeight / 2).round();
  } else {
    yPos = y;
  }

  return drawString(image, font, xPos, yPos, string, color: color);
}

int findStringHeight(BitmapFont font, String string) {
  var stringHeight = 0;
  final chars = string.codeUnits;
  for (var c in chars) {
    if (!font.characters.containsKey(c)) {
      continue;
    }
    final ch = font.characters[c]!;
    if (ch.height + ch.yoffset > stringHeight) {
      stringHeight = ch.height + ch.yoffset;
    }
  }
  return (stringHeight * 1.05).round();
}
