import 'dart:typed_data';

import '../image/image.dart';
import '../image/palette.dart';
import '../util/input_buffer.dart';
import 'decode_info.dart';
import 'decoder.dart';
import 'tga/tga_info.dart';

/// Decode a TGA image. This only supports the 24-bit and 32-bit uncompressed
/// format.
class TgaDecoder extends Decoder {
  TgaInfo? info;
  late InputBuffer input;

  /// Is the given file a valid TGA image?
  @override
  bool isValidFile(Uint8List data) {
    final input = InputBuffer(data);

    info = TgaInfo();
    info!.read(input);
    return info!.isValid();
  }

  @override
  Image? decode(Uint8List bytes, {int? frame}) {
    if (startDecode(bytes) == null) {
      return null;
    }

    return decodeFrame(frame ?? 0);
  }

  @override
  DecodeInfo? startDecode(Uint8List bytes) {
    info = TgaInfo();
    input = InputBuffer(bytes);

    final header = input.readBytes(18);
    info!.read(header);
    if (!info!.isValid()) {
      return null;
    }

    input.skip(info!.idLength);

    // Decode colormap
    if (info!.hasColorMap) {
      final size = info!.colorMapLength * (info!.colorMapDepth >> 3);
      info!.colorMap = input.readBytes(size).toUint8List();
    }

    info!.imageOffset = input.offset;

    return info;
  }

  @override
  int numFrames() => info != null ? 1 : 0;

  @override
  Image? decodeFrame(int frame) {
    if (info == null) {
      return null;
    }

    if (info!.imageType == TgaImageType.rgb) {
      return _decodeRgb();
    } else if (info!.imageType == TgaImageType.rgbRle ||
        info!.imageType == TgaImageType.paletteRle) {
      return _decodeRle();
    } else if (info!.imageType == TgaImageType.palette) {
      return _decodeRgb();
    }

    return null;
  }

  void _decodeColorMap(Uint8List colorMap, Palette palette) {
    final cm = InputBuffer(colorMap);
    if (info!.colorMapDepth == 16) {
      final color = input.readUint16();
      final r = (color & 0x7c00) >> 7;
      final g = (color & 0x3e0) >> 2;
      final b = (color & 0x1f) << 3;
      final a = (color & 0x8000) != 0 ? 0 : 255;
      for (var i = 0; i < info!.colorMapLength; ++i) {
        palette
          ..setRed(i, r)
          ..setGreen(i, g)
          ..setBlue(i, b)
          ..setAlpha(i, a);
      }
    } else {
      final hasAlpha = info!.colorMapDepth == 32;
      for (var i = 0; i < info!.colorMapLength; ++i) {
        final b = cm.readByte();
        final g = cm.readByte();
        final r = cm.readByte();
        final a = hasAlpha ? cm.readByte() : 255;
        palette
          ..setRed(i, r)
          ..setGreen(i, g)
          ..setBlue(i, b)
          ..setAlpha(i, a);
      }
    }
  }

  Image? _decodeRle() {
    final bpp = info!.pixelDepth;
    final hasAlpha = bpp == 16 || bpp == 32;
    final image = Image(
        width: info!.width,
        height: info!.height,
        numChannels: hasAlpha ? 4 : 3,
        withPalette: info!.hasColorMap);

    const rleBit = 0x80;
    const rleMask = 0x7f;

    if (image.palette != null) {
      _decodeColorMap(info!.colorMap!, image.palette!);
    }

    final w = image.width;
    final h = image.height;
    var y = h - 1;
    var x = 0;
    while (!input.isEOS && y >= 0) {
      final c = input.readByte();
      final count = (c & rleMask) + 1;

      if ((c & rleBit) != 0) {
        if (bpp == 8) {
          final r = input.readByte();
          for (var i = 0; i < count; ++i) {
            image.setPixelR(x++, y, r);
            if (x >= w) {
              x = 0;
              y--;
              if (y < 0) {
                break;
              }
            }
          }
        } else if (bpp == 16) {
          final color = input.readUint16();
          final r = (color & 0x7c00) >> 7;
          final g = (color & 0x3e0) >> 2;
          final b = (color & 0x1f) << 3;
          final a = (color & 0x8000) != 0 ? 0 : 255;
          for (var i = 0; i < count; ++i) {
            image.setPixelRgba(x++, y, r, g, b, a);
            if (x >= w) {
              x = 0;
              y--;
              if (y < 0) {
                break;
              }
            }
          }
        } else {
          final b = input.readByte();
          final g = input.readByte();
          final r = input.readByte();
          final a = hasAlpha ? input.readByte() : 255;
          for (var i = 0; i < count; ++i) {
            image.setPixelRgba(x++, y, r, g, b, a);
            if (x >= w) {
              x = 0;
              y--;
              if (y < 0) {
                break;
              }
            }
          }
        }
      } else {
        if (bpp == 8) {
          for (var i = 0; i < count; ++i) {
            final r = input.readByte();
            image.setPixelR(x++, y, r);
            if (x >= w) {
              x = 0;
              y--;
              if (y < 0) {
                break;
              }
            }
          }
        } else if (bpp == 16) {
          for (var i = 0; i < count; ++i) {
            final color = input.readUint16();
            final r = (color & 0x7c00) >> 7;
            final g = (color & 0x3e0) >> 2;
            final b = (color & 0x1f) << 3;
            final a = (color & 0x8000) != 0 ? 0 : 255;
            image.setPixelRgba(x++, y, r, g, b, a);
            if (input.isEOS) {
              break;
            }
            if (x >= w) {
              x = 0;
              y--;
              if (y < 0) {
                break;
              }
            }
          }
        } else {
          for (var i = 0; i < count; ++i) {
            final b = input.readByte();
            final g = input.readByte();
            final r = input.readByte();
            final a = hasAlpha ? input.readByte() : 255;
            image.setPixelRgba(x++, y, r, g, b, a);
            if (x >= w) {
              x = 0;
              y--;
              if (y < 0) {
                break;
              }
            }
          }
        }
      }

      if (x >= w) {
        x = 0;
        y--;
        if (y < 0) {
          break;
        }
      }
    }

    return image;
  }

  Image? _decodeRgb() {
    input.offset = info!.imageOffset;

    final bpp = info!.pixelDepth;
    final hasAlpha = bpp == 16 ||
        bpp == 32 ||
        (info!.hasColorMap &&
            (info!.colorMapDepth == 16 || info!.colorMapDepth == 32));

    final image = Image(
        width: info!.width,
        height: info!.height,
        numChannels: hasAlpha ? 4 : 3,
        withPalette: info!.hasColorMap);

    if (info!.hasColorMap) {
      _decodeColorMap(info!.colorMap!, image.palette!);
    }

    if (bpp == 8) {
      for (var y = image.height - 1; y >= 0; --y) {
        for (var x = 0; x < image.width; ++x) {
          final index = input.readByte();
          image.setPixelR(x, y, index);
        }
      }
    } else if (bpp == 16) {
      for (var y = image.height - 1; y >= 0; --y) {
        for (var x = 0; x < image.width; ++x) {
          final color = input.readUint16();
          final r = (color & 0x7c00) >> 7;
          final g = (color & 0x3e0) >> 2;
          final b = (color & 0x1f) << 3;
          final a = (color & 0x8000) != 0 ? 0 : 255;
          image.setPixelRgba(x, y, r, g, b, a);
        }
      }
    } else {
      for (var y = image.height - 1; y >= 0; --y) {
        for (var x = 0; x < image.width; ++x) {
          final b = input.readByte();
          final g = input.readByte();
          final r = input.readByte();
          final a = hasAlpha ? input.readByte() : 255;
          image.setPixelRgba(x, y, r, g, b, a);
        }
      }
    }

    return image;
  }
}
