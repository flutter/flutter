import 'dart:convert';

import '../../../image.dart';
import '../../internal/bit_operators.dart';

enum BitmapCompression { BI_BITFIELDS, NONE }

class BitmapFileHeader {
  static const fileHeaderSize = 14;

  late int fileLength;
  late int offset;

  BitmapFileHeader(InputBuffer b) {
    if (!isValidFile(b)) {
      throw ImageException('Not a bitmap file.');
    }
    b.skip(2);

    fileLength = b.readInt32();
    b.skip(4); // skip reserved space

    offset = b.readInt32();
  }

  static bool isValidFile(InputBuffer b) {
    if (b.length < 2) {
      return false;
    }
    final type = InputBuffer.from(b).readUint16();
    return type == BMP_HEADER_FILETYPE;
  }

  static const BMP_HEADER_FILETYPE = (0x42) + (0x4D << 8); // BM

  Map<String, int> toJson() => {
        'offset': offset,
        'fileLength': fileLength,
        'fileType': BMP_HEADER_FILETYPE
      };
}

class BmpInfo extends DecodeInfo {
  @override
  int get numFrames => 1;
  final BitmapFileHeader file;

  final int _height;
  @override
  final int width;

  final int headerSize;
  final int planes;
  final int bpp;
  final BitmapCompression compression;
  final int imageSize;
  final int xppm;
  final int yppm;
  final int totalColors;
  final int importantColors;

  int? v5redMask;
  int? v5greenMask;
  int? v5blueMask;
  int? v5alphaMask;

  // BITMAPINFOHEADER should (probably) ignore alpha channel altogether.
  // This is the behavior in gimp (?)
  // https://gitlab.gnome.org/GNOME/gimp/-/issues/461#note_208715
  bool get ignoreAlphaChannel =>
      headerSize == 40 ||
      // BITMAPV5HEADER with null alpha mask.
      headerSize == 124 && v5alphaMask == 0;

  bool get readBottomUp => !_height.isNegative;

  @override
  int get height => _height.abs();

  List<int>? colorPalette;

  BmpInfo(InputBuffer p, {BitmapFileHeader? fileHeader})
      : file = fileHeader ?? BitmapFileHeader(p),
        headerSize = p.readUint32(),
        width = p.readInt32(),
        _height = p.readInt32(),
        planes = p.readUint16(),
        bpp = p.readUint16(),
        compression = _intToCompressions(p.readUint32()),
        imageSize = p.readUint32(),
        xppm = p.readInt32(),
        yppm = p.readInt32(),
        totalColors = p.readUint32(),
        importantColors = p.readUint32() {
    if ([1, 4, 8].contains(bpp)) {
      readPalette(p);
    }
    if (headerSize == 124) {
      // BITMAPV5HEADER
      v5redMask = p.readUint32();
      v5greenMask = p.readUint32();
      v5blueMask = p.readUint32();
      v5alphaMask = p.readUint32();
    }
  }

  void readPalette(InputBuffer p) {
    final colors = totalColors == 0 ? 1 << bpp : totalColors;
    final colorBytes = headerSize == 12 ? 3 : 4;
    colorPalette = Iterable.generate(
            colors, (i) => _readRgba(p, aDefault: colorBytes == 3 ? 100 : null))
        .toList();
  }

  static BitmapCompression _intToCompressions(int compIndex) {
    final map = <int, BitmapCompression>{
      0: BitmapCompression.NONE,
      // 1: BitmapCompression.RLE_8,
      // 2: BitmapCompression.RLE_4,
      3: BitmapCompression.BI_BITFIELDS,
    };
    final compression = map[compIndex];
    if (compression == null) {
      throw ImageException(
          'Bitmap compression $compIndex is not supported yet.');
    }
    return compression;
  }

  int _readRgba(InputBuffer input, {int? aDefault}) {
    if (readBottomUp) {
      final b = input.readByte();
      final g = input.readByte();
      final r = input.readByte();
      final a = aDefault ?? input.readByte();
      return getColor(r, g, b, ignoreAlphaChannel ? 255 : a);
    } else {
      final r = input.readByte();
      final b = input.readByte();
      final g = input.readByte();
      final a = aDefault ?? input.readByte();
      return getColor(r, b, g, ignoreAlphaChannel ? 255 : a);
    }
  }

  void decodeRgba(InputBuffer input, void Function(int color) pixel) {
    if (colorPalette != null) {
      if (bpp == 1) {
        final b = input.readByte().toRadixString(2).padLeft(8, '0');
        for (int i = 0; i < 8; i++) {
          pixel(colorPalette![int.parse(b[i])]);
        }
        return;
      } else if (bpp == 4) {
        final b = input.readByte();
        final left = b >> 4;
        final right = b & 0x0f;
        pixel(colorPalette![left]);
        pixel(colorPalette![right]);
        return;
      } else if (bpp == 8) {
        final b = input.readByte();
        pixel(colorPalette![b]);
        return;
      }
    }
    if (compression == BitmapCompression.BI_BITFIELDS && bpp == 32) {
      return pixel(_readRgba(input));
    } else if (bpp == 32 && compression == BitmapCompression.NONE) {
      return pixel(_readRgba(input));
    } else if (bpp == 24) {
      return pixel(_readRgba(input, aDefault: 255));
    }
    // else if (bpp == 16) {
    //   return _rgbaFrom16(input);
    // }
    else {
      throw ImageException(
          'Unsupported bpp ($bpp) or compression ($compression).');
    }
  }

  // TODO: finish decoding for 16 bit
  // List<int> _rgbaFrom16(InputBuffer input) {
  //   final maskRed = 0x7C00;
  //   final maskGreen = 0x3E0;
  //   final maskBlue = 0x1F;
  //   final pixel = input.readUint16();
  //   return [(pixel & maskRed), (pixel & maskGreen), (pixel & maskBlue), 0];
  // }

  String _compToString() {
    switch (compression) {
      case BitmapCompression.BI_BITFIELDS:
        return 'BI_BITFIELDS';
      case BitmapCompression.NONE:
        return 'none';
    }
  }

  @override
  String toString() {
    const json = JsonEncoder.withIndent(' ');
    return json.convert({
      'headerSize': headerSize,
      'width': width,
      'height': height,
      'planes': planes,
      'bpp': bpp,
      'file': file.toJson(),
      'compression': _compToString(),
      'imageSize': imageSize,
      'xppm': xppm,
      'yppm': yppm,
      'totalColors': totalColors,
      'importantColors': importantColors,
      'readBottomUp': readBottomUp,
      'v5redMask': debugBits32(v5redMask),
      'v5greenMask': debugBits32(v5greenMask),
      'v5blueMask': debugBits32(v5blueMask),
      'v5alphaMask': debugBits32(v5alphaMask),
    });
  }
}
