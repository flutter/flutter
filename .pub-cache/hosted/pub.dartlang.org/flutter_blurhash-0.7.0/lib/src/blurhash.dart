import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

Future<Uint8List> blurHashDecode({
  required String blurHash,
  required int width,
  required int height,
  double punch = 1.0,
}) {
  _validateBlurHash(blurHash);

  final sizeFlag = _decode83(blurHash[0]);
  final numY = (sizeFlag / 9).floor() + 1;
  final numX = (sizeFlag % 9) + 1;

  final quantisedMaximumValue = _decode83(blurHash[1]);
  final maximumValue = (quantisedMaximumValue + 1) / 166;

  final colors = []..length = numX * numY;

  for (var i = 0; i < colors.length; i++) {
    if (i == 0) {
      final value = _decode83(blurHash.substring(2, 6));
      colors[i] = _decodeDC(value);
    } else {
      final value = _decode83(blurHash.substring(4 + i * 2, 6 + i * 2));
      colors[i] = _decodeAC(value, maximumValue * punch);
    }
  }

  final bytesPerRow = width * 4;
  final pixels = Uint8List(bytesPerRow * height);

  int p = 0;
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      var r = .0;
      var g = .0;
      var b = .0;

      for (int j = 0; j < numY; j++) {
        for (int i = 0; i < numX; i++) {
          final basis = cos((pi * x * i) / width) * cos((pi * y * j) / height);
          var color = colors[i + j * numX];
          r += color[0] * basis;
          g += color[1] * basis;
          b += color[2] * basis;
        }
      }

      final intR = _linearTosRGB(r);
      final intG = _linearTosRGB(g);
      final intB = _linearTosRGB(b);

      pixels[p++] = intR;
      pixels[p++] = intG;
      pixels[p++] = intB;
      pixels[p++] = 255;
    }
  }

  return Future.value(pixels);
}

Future<ui.Image> blurHashDecodeImage({
  required String blurHash,
  required int width,
  required int height,
  double punch = 1.0,
}) async {
  _validateBlurHash(blurHash);

  final completer = Completer<ui.Image>();

  if (kIsWeb) {
    // https://github.com/flutter/flutter/issues/45190
    final pixels = await blurHashDecode(blurHash: blurHash, width: width, height: height, punch: punch);
    completer.complete(_createBmp(pixels, width, height));
  } else {
    blurHashDecode(blurHash: blurHash, width: width, height: height, punch: punch).then((pixels) {
      ui.decodeImageFromPixels(pixels, width, height, ui.PixelFormat.rgba8888, completer.complete);
    });
  }

  return completer.future;
}

Future<ui.Image> _createBmp(Uint8List pixels, int width, int height) async {
  int size = (width * height * 4) + 122;
  final bmp = Uint8List(size);
  final ByteData header = bmp.buffer.asByteData();
  header.setUint8(0x0, 0x42);
  header.setUint8(0x1, 0x4d);
  header.setInt32(0x2, size, Endian.little);
  header.setInt32(0xa, 122, Endian.little);
  header.setUint32(0xe, 108, Endian.little);
  header.setUint32(0x12, width, Endian.little);
  header.setUint32(0x16, -height, Endian.little);
  header.setUint16(0x1a, 1, Endian.little);
  header.setUint32(0x1c, 32, Endian.little);
  header.setUint32(0x1e, 3, Endian.little);
  header.setUint32(0x22, width * height * 4, Endian.little);
  header.setUint32(0x36, 0x000000ff, Endian.little);
  header.setUint32(0x3a, 0x0000ff00, Endian.little);
  header.setUint32(0x3e, 0x00ff0000, Endian.little);
  header.setUint32(0x42, 0xff000000, Endian.little);
  bmp.setRange(122, size, pixels);
  final codec = await ui.instantiateImageCodec(bmp);
  final frame = await codec.getNextFrame();
  return frame.image;
}

double _sRGBToLinear(int value) {
  final v = value / 255;
  if (v <= 0.04045) {
    return v / 12.92;
  } else {
    return pow((v + 0.055) / 1.055, 2.4) as double;
  }
}

int _linearTosRGB(double value) {
  final v = max(0, min(1, value));
  if (v <= 0.0031308) {
    return (v * 12.92 * 255 + 0.5).round();
  } else {
    return ((1.055 * pow(v, 1 / 2.4) - 0.055) * 255 + 0.5).round();
  }
}

void _validateBlurHash(String blurHash) {
  if (blurHash.length < 6) {
    throw Exception('The blurhash string must be at least 6 characters');
  }

  final sizeFlag = _decode83(blurHash[0]);
  final numY = (sizeFlag / 9).floor() + 1;
  final numX = (sizeFlag % 9) + 1;

  if (blurHash.length != 4 + 2 * numX * numY) {
    throw Exception('blurhash length mismatch: length is ${blurHash.length} but '
        'it should be ${4 + 2 * numX * numY}');
  }
}

int _sign(double n) => (n < 0 ? -1 : 1);

num _signPow(double val, double exp) => _sign(val) * pow(val.abs(), exp);

int _decode83(String str) {
  var value = 0;
  final units = str.codeUnits;
  final digits = _digitCharacters.codeUnits;
  for (var i = 0; i < units.length; i++) {
    final code = units.elementAt(i);
    final digit = digits.indexOf(code);
    if (digit == -1) {
      throw ArgumentError.value(str, 'str');
    }
    value = value * 83 + digit;
  }
  return value;
}

List<double> _decodeDC(int value) {
  final intR = value >> 16;
  final intG = (value >> 8) & 255;
  final intB = value & 255;
  return [_sRGBToLinear(intR), _sRGBToLinear(intG), _sRGBToLinear(intB)];
}

List<double> _decodeAC(int value, double maximumValue) {
  final quantR = (value / (19 * 19)).floor();
  final quantG = (value / 19).floor() % 19;
  final quantB = value % 19;

  final rgb = [
    _signPow((quantR - 9) / 9, 2.0) * maximumValue,
    _signPow((quantG - 9) / 9, 2.0) * maximumValue,
    _signPow((quantB - 9) / 9, 2.0) * maximumValue
  ];

  return rgb;
}

bool validateBlurhash(String blurhash) {
  if (blurhash.isEmpty || blurhash.length < 6) {
    debugPrint('Blurhash should be at least 6 characters');
    return false;
  }

  final sizeFlag = _decode83(blurhash[0]);
  final y = ((sizeFlag / 9) + 1).floor();
  final x = (sizeFlag % 9) + 1;

  if (blurhash.length != 4 + 2 * x * y) {
    debugPrint("blurhash length mismatch: length is ${blurhash.length} but it should be ${4 + 2 * x * y}");
    return false;
  }

  return true;
}

const _digitCharacters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#\$%*+,-.:;=?@[]^_{|}~";

class Style {
  final String name;
  final List<ui.Color> colors;
  final ui.Color? stroke;
  final ui.Color? background;

  const Style({required this.name, required this.colors, this.stroke, this.background});
}

const styles = {
  'flourish': [
    Style(
      name: 'one',
      colors: [],
      stroke: null,
      background: null,
    )
  ]
};
