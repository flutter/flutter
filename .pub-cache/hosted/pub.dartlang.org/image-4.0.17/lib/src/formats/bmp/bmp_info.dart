import '../../color/color.dart';
import '../../image/palette_uint8.dart';
import '../../util/bit_utils.dart';
import '../../util/image_exception.dart';
import '../../util/input_buffer.dart';
import '../decode_info.dart';

enum BmpCompression {
  none,
  rle8,
  rle4,
  bitfields,
  jpeg,
  png,
  alphaBitfields,
  reserved7,
  reserved8,
  reserved9,
  reserved10,
  cmyk,
  cmykRle8,
  cmykRle4
}

class BmpFileHeader {
  static const fileHeaderSize = 14;

  late int fileLength;
  late int imageOffset;

  BmpFileHeader(InputBuffer b) {
    if (!isValidFile(b)) {
      throw ImageException('Not a bitmap file.');
    }
    b.skip(2);

    fileLength = b.readInt32();
    b.skip(4); // skip reserved space

    imageOffset = b.readInt32();
  }

  static bool isValidFile(InputBuffer b) {
    if (b.length < 2) {
      return false;
    }
    final type = InputBuffer.from(b).readUint16();
    return type == signature;
  }

  static const signature = 0x4d42; // BM
}

class BmpInfo implements DecodeInfo {
  final BmpFileHeader header;
  @override
  final int width;
  final int _height;
  final int headerSize;
  final int planes;
  final int bitsPerPixel;
  final BmpCompression compression;
  final int imageSize;
  final int xppm;
  final int yppm;
  final int totalColors;
  final int importantColors;
  late int redMask;
  late int greenMask;
  late int blueMask;
  late int alphaMask;
  PaletteUint8? palette;
  late int _redShift;
  late num _redScale;
  late int _greenShift;
  late num _greenScale;
  late int _blueShift;
  late num _blueScale;
  late int _alphaShift;
  late num _alphaScale;

  final int _startPos;

  BmpInfo(InputBuffer p, {BmpFileHeader? fileHeader})
      : header = fileHeader ?? BmpFileHeader(p),
        _startPos = p.offset,
        headerSize = p.readUint32(),
        width = p.readInt32(),
        _height = p.readInt32(),
        planes = p.readUint16(),
        bitsPerPixel = p.readUint16(),
        compression = BmpCompression.values[p.readUint32()],
        imageSize = p.readUint32(),
        xppm = p.readInt32(),
        yppm = p.readInt32(),
        totalColors = p.readUint32(),
        importantColors = p.readUint32() {
    // BMP allows > 4 bit per channel for 16bpp, so we have to scale it
    // up to 8-bit
    const maxChannelValue = 255.0;

    if (headerSize > 40 ||
        compression == BmpCompression.bitfields ||
        compression == BmpCompression.alphaBitfields) {
      redMask = p.readUint32();
      _redShift = countTrailingZeroBits(redMask);
      final redDepth = redMask >> _redShift;
      _redScale = redDepth > 0 ? maxChannelValue / redDepth : 0;

      greenMask = p.readUint32();
      _greenShift = countTrailingZeroBits(greenMask);
      final greenDepth = greenMask >> _greenShift;
      _greenScale = redDepth > 0 ? maxChannelValue / greenDepth : 0;

      blueMask = p.readUint32();
      _blueShift = countTrailingZeroBits(blueMask);
      final blueDepth = blueMask >> _blueShift;
      _blueScale = redDepth > 0 ? maxChannelValue / blueDepth : 0;

      if (headerSize > 40 || compression == BmpCompression.alphaBitfields) {
        alphaMask = p.readUint32();
        _alphaShift = countTrailingZeroBits(alphaMask);
        final alphaDepth = alphaMask >> _alphaShift;
        _alphaScale = alphaDepth > 0 ? maxChannelValue / alphaDepth : 0;
      } else {
        if (bitsPerPixel == 16) {
          alphaMask = 0xff000000;
          _alphaShift = 24;
          _alphaScale = 1.0;
        } else {
          alphaMask = 0xff000000;
          _alphaShift = 24;
          _alphaScale = 1.0;
        }
      }
    } else {
      if (bitsPerPixel == 16) {
        redMask = 0x7c00;
        _redShift = 10;
        final redDepth = redMask >> _redShift;
        _redScale = redDepth > 0 ? maxChannelValue / redDepth : 0;

        greenMask = 0x03e0;
        _greenShift = 5;
        final greenDepth = greenMask >> _greenShift;
        _greenScale = redDepth > 0 ? maxChannelValue / greenDepth : 0;

        blueMask = 0x001f;
        _blueShift = 0;
        final blueDepth = blueMask >> _blueShift;
        _blueScale = redDepth > 0 ? maxChannelValue / blueDepth : 0;

        alphaMask = 0x00000000;
        _alphaShift = 0;
        _alphaScale = 0.0;
      } else {
        redMask = 0x00ff0000;
        _redShift = 16;
        _redScale = 1.0;

        greenMask = 0x0000ff00;
        _greenShift = 8;
        _greenScale = 1.0;

        blueMask = 0x000000ff;
        _blueShift = 0;
        _blueScale = 1.0;

        alphaMask = 0xff000000;
        _alphaShift = 24;
        _alphaScale = 1.0;
      }
    }

    final headerRead = p.offset - _startPos;

    final remainingHeaderBytes = headerSize - headerRead;
    p.skip(remainingHeaderBytes);

    if (bitsPerPixel <= 8) {
      readPalette(p);
    }
  }

  bool get ignoreAlphaChannel =>
      // Gimp and Photoshop ignore the alpha channel for BITMAPINFOHEADER.
      headerSize == 40 ||
      // BITMAPV5HEADER with null alpha mask.
      headerSize == 124 && alphaMask == 0;

  bool get readBottomUp => !_height.isNegative;

  @override
  int get height => _height.abs();

  @override
  int get numFrames => 1;

  @override
  Color? get backgroundColor => null;

  void readPalette(InputBuffer input) {
    final numColors = totalColors == 0 ? 1 << bitsPerPixel : totalColors;
    const numChannels = 3;
    palette = PaletteUint8(numColors, numChannels);
    for (var i = 0; i < numColors; ++i) {
      final b = input.readByte();
      final g = input.readByte();
      final r = input.readByte();
      final a = input.readByte(); // ignored
      palette!.setRgba(i, r, g, b, a);
    }
  }

  void decodePixel(
      InputBuffer input, void Function(num r, num g, num b, num a) pixel) {
    if (palette != null) {
      if (bitsPerPixel == 1) {
        final bi = input.readByte();
        for (var i = 7; i >= 0; --i) {
          final b = (bi >> i) & 0x1;
          pixel(b, 0, 0, 0);
        }
        return;
      } else if (bitsPerPixel == 2) {
        final bi = input.readByte();
        for (var i = 6; i >= 0; i -= 2) {
          final b = (bi >> i) & 0x2;
          pixel(b, 0, 0, 0);
        }
      } else if (bitsPerPixel == 4) {
        final bi = input.readByte();
        final b1 = (bi >> 4) & 0xf;
        pixel(b1, 0, 0, 0);
        final b2 = bi & 0xf;
        pixel(b2, 0, 0, 0);
        return;
      } else if (bitsPerPixel == 8) {
        final b = input.readByte();
        pixel(b, 0, 0, 0);
        return;
      }
    }

    if (compression == BmpCompression.bitfields && bitsPerPixel == 32) {
      final p = input.readUint32();
      final r = (((p & redMask) >> _redShift) * _redScale).toInt();
      final g = (((p & greenMask) >> _greenShift) * _greenScale).toInt();
      final b = (((p & blueMask) >> _blueShift) * _blueScale).toInt();
      final a = ignoreAlphaChannel
          ? 255
          : (((p & alphaMask) >> _alphaShift) * _alphaScale).toInt();
      return pixel(r, g, b, a);
    } else if (bitsPerPixel == 32 && compression == BmpCompression.none) {
      final b = input.readByte();
      final g = input.readByte();
      final r = input.readByte();
      final a = input.readByte();
      return pixel(r, g, b, ignoreAlphaChannel ? 255 : a);
    } else if (bitsPerPixel == 24) {
      final b = input.readByte();
      final g = input.readByte();
      final r = input.readByte();
      return pixel(r, g, b, 255);
    } else if (bitsPerPixel == 16) {
      final p = input.readUint16();
      final r = (((p & redMask) >> _redShift) * _redScale).toInt();
      final g = (((p & greenMask) >> _greenShift) * _greenScale).toInt();
      final b = (((p & blueMask) >> _blueShift) * _blueScale).toInt();
      final a = ignoreAlphaChannel
          ? 255
          : (((p & alphaMask) >> _alphaShift) * _alphaScale).toInt();
      return pixel(r, g, b, a);
    } else {
      throw ImageException('Unsupported bitsPerPixel ($bitsPerPixel) or'
          ' compression ($compression).');
    }
  }
}
