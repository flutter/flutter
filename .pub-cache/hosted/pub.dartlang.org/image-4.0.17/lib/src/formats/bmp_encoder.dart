import 'dart:typed_data';

import '../color/format.dart';
import '../image/image.dart';
import '../image/palette_uint8.dart';
import '../util/output_buffer.dart';
import 'bmp/bmp_info.dart';
import 'encoder.dart';

/// Encode a BMP image.
class BmpEncoder extends Encoder {
  /*int _roundToMultiple(int x) {
    final y = x & 0x3;
    if (y == 0) {
      return x;
    }
    return x + 4 - y;
  }*/

  @override
  Uint8List encode(Image image, {bool singleFrame = false}) {
    final out = OutputBuffer();

    final nc = image.numChannels;
    var palette = image.palette;
    final format = image.format;

    if (format == Format.uint1 && nc == 1 && palette == null) {
      // add palette
      palette = PaletteUint8(2, 3)
        ..setRgb(0, 0, 0, 0)
        ..setRgb(1, 255, 255, 255);
    } else if (format == Format.uint1 && nc == 2) {
      // => uint2 palette
      image = image.convert(
          format: Format.uint2, numChannels: 1, withPalette: true);
      palette = image.palette;
    } else if (format == Format.uint1 && nc == 3 && palette == null) {
      // => uint4 palette
      image = image.convert(format: Format.uint4, withPalette: true);
      palette = image.palette;
    } else if (format == Format.uint1 && nc == 4) {
      // => uint8,4 - only 32bpp supports alpha
      image = image.convert(format: Format.uint8, numChannels: 4);
    } else if (format == Format.uint2 && nc == 1 && palette == null) {
      // => uint2 palette
      image = image.convert(format: Format.uint2, withPalette: true);
      palette = image.palette;
    } else if (format == Format.uint2 && nc == 2) {
      // => uint8 palette
      image = image.convert(format: Format.uint8, withPalette: true);
      palette = image.palette;
    } else if (format == Format.uint2 && nc == 3 && palette == null) {
      // => uint8 palette
      image = image.convert(format: Format.uint8, withPalette: true);
      palette = image.palette;
    } else if (format == Format.uint2 && nc == 4) {
      // => uint8 palette
      image = image.convert(format: Format.uint8, withPalette: true);
      palette = image.palette;
    } else if (format == Format.uint4 && nc == 1 && palette == null) {
      // => uint8 palette
      image = image.convert(format: Format.uint8, withPalette: true);
      palette = image.palette;
    } else if (format == Format.uint4 && nc == 2) {
      // => uint8,3
      image = image.convert(format: Format.uint8, numChannels: 3);
    } else if (format == Format.uint4 && nc == 3 && palette == null) {
      // => uint8,3
      image = image.convert(format: Format.uint8, numChannels: 3);
    } else if (format == Format.uint4 && nc == 4) {
      // => uint8,4
      image = image.convert(format: Format.uint8, numChannels: 4);
    } else if (format == Format.uint8 && nc == 1 && palette == null) {
      // => uint8 palette
      image = image.convert(format: Format.uint8, withPalette: true);
    } else if (format == Format.uint8 && nc == 2) {
      // => uint8,3
      image.convert(format: Format.uint8, numChannels: 3);
    } else if (image.isHdrFormat) {
      // => uint8,[3,4]
      image = image.convert(format: Format.uint8);
    } else if (image.hasPalette && image.numChannels == 4) {
      image = image.convert(numChannels: 4);
    }

    var bpp = image.bitsPerChannel * image.data!.numChannels;
    if (bpp == 12) {
      bpp = 16;
    }

    final compression =
        bpp > 8 ? BmpCompression.bitfields : BmpCompression.none;

    final imageStride = image.rowStride;
    final fileStride = ((image.width * bpp + 31) ~/ 32) * 4;
    final rowPaddingSize = fileStride - imageStride;
    final rowPadding =
        rowPaddingSize > 0 ? List<int>.filled(rowPaddingSize, 0xff) : null;

    final imageFileSize = fileStride * image.height;
    final headerInfoSize = bpp > 8 ? 124 : 40;
    final headerSize = headerInfoSize + 14;
    final paletteSize = (image.palette?.numColors ?? 0) * 4;
    final origImageOffset = headerSize + paletteSize;
    final imageOffset = origImageOffset;
    //final imageOffset = _roundToMultiple(origImageOffset);
    final gapSize = imageOffset - origImageOffset;
    final fileSize = imageFileSize + headerSize + paletteSize + gapSize;

    const sRgb = 0x73524742;

    out
      ..writeUint16(BmpFileHeader.signature)
      ..writeUint32(fileSize)
      ..writeUint32(0) // reserved
      ..writeUint32(imageOffset) // offset to image data
      ..writeUint32(headerInfoSize)
      ..writeUint32(image.width)
      ..writeUint32(image.height)
      ..writeUint16(1) // planes
      ..writeUint16(bpp) // bits per pixel
      ..writeUint32(compression.index) // compression
      ..writeUint32(imageFileSize)
      ..writeUint32(11811) // hr
      ..writeUint32(11811) // vr
      ..writeUint32(bpp == 8 ? 255 : 0) // totalColors
      ..writeUint32(bpp == 8 ? 255 : 0); // importantColors

    if (bpp > 8) {
      final blueMask = bpp == 16 ? 0xf : 0xff;
      final greenMask = bpp == 16 ? 0xf0 : 0xff00;
      final redMask = bpp == 16 ? 0xf00 : 0xff0000;
      final alphaMask = bpp == 16 ? 0xf000 : 0xff000000;

      out
        ..writeUint32(redMask) // redMask
        ..writeUint32(greenMask) // greenMask
        ..writeUint32(blueMask) // blueMask
        ..writeUint32(alphaMask) // alphaMask
        ..writeUint32(sRgb) // CSType
        ..writeUint32(0) // endpoints.red.x
        ..writeUint32(0) // endpoints.red.y
        ..writeUint32(0) // endpoints.red.z
        ..writeUint32(0) // endpoints.green.x
        ..writeUint32(0) // endpoints.green.y
        ..writeUint32(0) // endpoints.green.z
        ..writeUint32(0) // endpoints.blue.x
        ..writeUint32(0) // endpoints.blue.y
        ..writeUint32(0) // endpoints.blue.z
        ..writeUint32(0) // gammaRed
        ..writeUint32(0) // gammaGreen
        ..writeUint32(0) // gammaBlue
        ..writeUint32(2) // intent LCS_GM_GRAPHICS
        ..writeUint32(0) // profileData
        ..writeUint32(0) // profileSize
        ..writeUint32(0); // reserved
    }

    if (bpp == 1 || bpp == 2 || bpp == 4 || bpp == 8) {
      if (palette != null) {
        //final palette = image.palette!;
        final l = palette.numColors;
        for (var pi = 0; pi < l; ++pi) {
          out
            ..writeByte(palette.getBlue(pi).toInt())
            ..writeByte(palette.getGreen(pi).toInt())
            ..writeByte(palette.getRed(pi).toInt())
            ..writeByte(0);
        }
      } else {
        if (bpp == 1) {
          out
            ..writeByte(0)
            ..writeByte(0)
            ..writeByte(0)
            ..writeByte(0)
            ..writeByte(255)
            ..writeByte(255)
            ..writeByte(255)
            ..writeByte(0);
        } else if (bpp == 2) {
          for (var pi = 0; pi < 4; ++pi) {
            final v = pi * 85;
            out
              ..writeByte(v)
              ..writeByte(v)
              ..writeByte(v)
              ..writeByte(0);
          }
        } else if (bpp == 4) {
          for (var pi = 0; pi < 16; ++pi) {
            final v = pi * 17;
            out
              ..writeByte(v)
              ..writeByte(v)
              ..writeByte(v)
              ..writeByte(0);
          }
        } else if (bpp == 8) {
          for (var pi = 0; pi < 256; ++pi) {
            out
              ..writeByte(pi)
              ..writeByte(pi)
              ..writeByte(pi)
              ..writeByte(0);
          }
        }
      }
    }

    // image data must be aligned to a 4 byte alignment. Pad the remaining
    // bytes until the image starts.
    var gap1 = gapSize;
    while (gap1-- > 0) {
      out.writeByte(0);
    }

    // Write image data
    if (bpp == 1 || bpp == 2 || bpp == 4 || bpp == 8) {
      var offset = image.lengthInBytes - imageStride;
      final h = image.height;
      for (var y = 0; y < h; ++y) {
        final bytes = Uint8List.view(image.buffer, offset, imageStride);

        if (bpp == 1) {
          out.writeBytes(bytes);
        } else if (bpp == 2) {
          final l = bytes.length;
          for (var xi = 0; xi < l; ++xi) {
            final b = bytes[xi];
            final left = b >> 4;
            final right = b & 0x0f;
            final rb = (right << 4) | left;
            out.writeByte(rb);
          }
        } else if (bpp == 4) {
          final l = bytes.length;
          for (var xi = 0; xi < l; ++xi) {
            final b = bytes[xi];
            final b1 = b >> 4;
            final b2 = b & 0x0f;
            final rb = (b1 << 4) | b2;
            out.writeByte(rb);
          }
        } else {
          out.writeBytes(bytes);
        }

        if (rowPadding != null) {
          out.writeBytes(rowPadding);
        }

        offset -= imageStride;
      }

      return out.getBytes();
    }

    final hasAlpha = image.numChannels == 4;
    final h = image.height;
    final w = image.width;
    if (bpp == 16) {
      for (var y = h - 1; y >= 0; --y) {
        for (var x = 0; x < w; ++x) {
          final p = image.getPixel(x, y);
          out
            ..writeByte((p.g.toInt() << 4) | p.b.toInt())
            ..writeByte((p.a.toInt() << 4) | p.r.toInt());
        }
        if (rowPadding != null) {
          out.writeBytes(rowPadding);
        }
      }
    } else {
      for (var y = h - 1; y >= 0; --y) {
        for (var x = 0; x < w; ++x) {
          final p = image.getPixel(x, y);
          out
            ..writeByte(p.b.toInt())
            ..writeByte(p.g.toInt())
            ..writeByte(p.r.toInt());
          if (hasAlpha) {
            out.writeByte(p.a.toInt());
          }
        }
        if (rowPadding != null) {
          out.writeBytes(rowPadding);
        }
      }
    }

    return out.getBytes();
  }
}
