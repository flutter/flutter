import 'dart:typed_data';

import '../image/image.dart';
import '../util/image_exception.dart';
import '../util/output_buffer.dart';
import 'encoder.dart';
import 'pvr/pvr_bit_utility.dart';
import 'pvr/pvr_color.dart';
import 'pvr/pvr_color_bounding_box.dart';
import 'pvr/pvr_packet.dart';

enum PvrFormat { auto, rgb2, rgba2, rgb4, rgba4 }

// Ported from Jeffrey Lim's PVRTC encoder/decoder,
// https://bitbucket.org/jthlim/pvrtccompressor
class PvrEncoder extends Encoder {
  final PvrFormat format;

  PvrEncoder({this.format = PvrFormat.auto});

  @override
  Uint8List encode(Image image, {bool singleFrame = false}) {
    final output = OutputBuffer();

    var format = this.format;

    Uint8List pvrtc;
    switch (format) {
      case PvrFormat.auto:
        if (image.numChannels == 3) {
          pvrtc = encodeRgb4bpp(image);
          format = PvrFormat.rgb4;
        } else {
          pvrtc = encodeRgba4bpp(image);
          format = PvrFormat.rgba4;
        }
        break;
      case PvrFormat.rgb2:
        //pvrtc = encodeRgb2bpp(bitmap);
        pvrtc = encodeRgb4bpp(image);
        break;
      case PvrFormat.rgba2:
        //pvrtc = encodeRgba2bpp(bitmap);
        pvrtc = encodeRgba4bpp(image);
        break;
      case PvrFormat.rgb4:
        pvrtc = encodeRgb4bpp(image);
        break;
      case PvrFormat.rgba4:
        pvrtc = encodeRgba4bpp(image);
        break;
    }

    const version = 55727696;
    const flags = 0;
    final pixelFormat = format.index - 1;
    const channelOrder = 0;
    const colorSpace = 0;
    const channelType = 0;
    final height = image.height;
    final width = image.width;
    const depth = 1;
    const numSurfaces = 1;
    const numFaces = 1;
    const mipmapCount = 1;
    const metaDataSize = 0;

    output
      ..writeUint32(version)
      ..writeUint32(flags)
      ..writeUint32(pixelFormat)
      ..writeUint32(channelOrder)
      ..writeUint32(colorSpace)
      ..writeUint32(channelType)
      ..writeUint32(height)
      ..writeUint32(width)
      ..writeUint32(depth)
      ..writeUint32(numSurfaces)
      ..writeUint32(numFaces)
      ..writeUint32(mipmapCount)
      ..writeUint32(metaDataSize)
      ..writeBytes(pvrtc);

    return output.getBytes();
  }

  Uint8List encodeRgb4bpp(Image bitmap) {
    if (bitmap.width != bitmap.height) {
      throw ImageException('PVRTC requires a square image.');
    }

    if (!PvrBitUtility.isPowerOf2(bitmap.width)) {
      throw ImageException('PVRTC requires a power-of-two sized image.');
    }

    final size = bitmap.width;
    final blocks = size ~/ 4;
    final blockMask = blocks - 1;

    // Allocate enough data for encoding the image.
    final outputData = Uint8List((bitmap.width * bitmap.height) ~/ 2);
    final packet = PvrPacket(outputData);
    final p0 = PvrPacket(outputData);
    final p1 = PvrPacket(outputData);
    final p2 = PvrPacket(outputData);
    final p3 = PvrPacket(outputData);

    for (var y = 0; y < blocks; ++y) {
      for (var x = 0; x < blocks; ++x) {
        final cbb = _calculateBoundingBoxRgb(bitmap, x, y);
        packet
          ..setBlock(x, y)
          ..usePunchthroughAlpha = false
          ..setColorRgbA(cbb.min as PvrColorRgb)
          ..setColorRgbB(cbb.max as PvrColorRgb);
      }
    }

    const factors = PvrPacket.bilinearFactors;

    for (var y = 0, y4 = 0; y < blocks; ++y, y4 += 4) {
      for (var x = 0, x4 = 0; x < blocks; ++x, x4 += 4) {
        var factorIndex = 0;
        var modulationData = 0;

        for (var py = 0; py < 4; ++py) {
          final yOffset = (py < 2) ? -1 : 0;
          final y0 = (y + yOffset) & blockMask;
          final y1 = (y0 + 1) & blockMask;

          for (var px = 0; px < 4; ++px) {
            final xOffset = (px < 2) ? -1 : 0;
            final x0 = (x + xOffset) & blockMask;
            final x1 = (x0 + 1) & blockMask;

            p0.setBlock(x0, y0);
            p1.setBlock(x1, y0);
            p2.setBlock(x0, y1);
            p3.setBlock(x1, y1);

            final ca = p0.getColorRgbA() * factors[factorIndex][0] +
                p1.getColorRgbA() * factors[factorIndex][1] +
                p2.getColorRgbA() * factors[factorIndex][2] +
                p3.getColorRgbA() * factors[factorIndex][3];

            final cb = p0.getColorRgbB() * factors[factorIndex][0] +
                p1.getColorRgbB() * factors[factorIndex][1] +
                p2.getColorRgbB() * factors[factorIndex][2] +
                p3.getColorRgbB() * factors[factorIndex][3];

            //final pi = pixelIndex + ((py * size + px) * 4);
            final pi = bitmap.getPixel(x4 + px, y4 + py);
            final r = pi.r.toInt();
            final g = pi.g.toInt();
            final b = pi.b.toInt();

            final d = cb - ca;
            final p = PvrColorRgb(r * 16, g * 16, b * 16);
            final v = p - ca;

            // PVRTC uses weightings of 0, 3/8, 5/8 and 1
            // The boundaries for these are 3/16, 1/2 (=8/16), 13/16
            final projection = v.dotProd(d) * 16;
            final lengthSquared = d.dotProd(d);
            if (projection > 3 * lengthSquared) {
              modulationData++;
            }
            if (projection > 8 * lengthSquared) {
              modulationData++;
            }
            if (projection > 13 * lengthSquared) {
              modulationData++;
            }

            modulationData = PvrBitUtility.rotateRight(modulationData, 2);

            factorIndex++;
          }
        }

        packet
          ..setBlock(x, y)
          ..modulationData = modulationData;
      }
    }

    return outputData;
  }

  Uint8List encodeRgba4bpp(Image bitmap) {
    if (bitmap.width != bitmap.height) {
      throw ImageException('PVRTC requires a square image.');
    }

    if (!PvrBitUtility.isPowerOf2(bitmap.width)) {
      throw ImageException('PVRTC requires a power-of-two sized image.');
    }

    final size = bitmap.width;
    final blocks = size ~/ 4;
    final blockMask = blocks - 1;

    // Allocate enough data for encoding the image.
    final outputData = Uint8List((bitmap.width * bitmap.height) ~/ 2);
    final packet = PvrPacket(outputData);
    final p0 = PvrPacket(outputData);
    final p1 = PvrPacket(outputData);
    final p2 = PvrPacket(outputData);
    final p3 = PvrPacket(outputData);

    for (var y = 0, y4 = 0; y < blocks; ++y, y4 += 4) {
      for (var x = 0, x4 = 0; x < blocks; ++x, x4 += 4) {
        final cbb = _calculateBoundingBoxRgba(bitmap, x4, y4);
        packet
          ..setBlock(x, y)
          ..usePunchthroughAlpha = false
          ..setColorRgbaA(cbb.min as PvrColorRgba)
          ..setColorRgbaB(cbb.max as PvrColorRgba);
      }
    }

    const factors = PvrPacket.bilinearFactors;

    for (var y = 0, y4 = 0; y < blocks; ++y, y4 += 4) {
      for (var x = 0, x4 = 0; x < blocks; ++x, x4 += 4) {
        var factorIndex = 0;
        var modulationData = 0;

        for (var py = 0; py < 4; ++py) {
          final yOffset = (py < 2) ? -1 : 0;
          final y0 = (y + yOffset) & blockMask;
          final y1 = (y0 + 1) & blockMask;

          for (var px = 0; px < 4; ++px) {
            final xOffset = (px < 2) ? -1 : 0;
            final x0 = (x + xOffset) & blockMask;
            final x1 = (x0 + 1) & blockMask;

            p0.setBlock(x0, y0);
            p1.setBlock(x1, y0);
            p2.setBlock(x0, y1);
            p3.setBlock(x1, y1);

            final ca = p0.getColorRgbaA() * factors[factorIndex][0] +
                p1.getColorRgbaA() * factors[factorIndex][1] +
                p2.getColorRgbaA() * factors[factorIndex][2] +
                p3.getColorRgbaA() * factors[factorIndex][3];

            final cb = p0.getColorRgbaB() * factors[factorIndex][0] +
                p1.getColorRgbaB() * factors[factorIndex][1] +
                p2.getColorRgbaB() * factors[factorIndex][2] +
                p3.getColorRgbaB() * factors[factorIndex][3];

            //final pi = pixelIndex + ((py * size + px) * 4);
            final bp = bitmap.getPixel(x4 + px, y4 + py);
            final r = bp.r as int;
            final g = bp.g as int;
            final b = bp.b as int;
            final a = bp.a as int;

            final d = cb - ca;
            final p = PvrColorRgba(r * 16, g * 16, b * 16, a * 16);
            final v = p - ca;

            // PVRTC uses weightings of 0, 3/8, 5/8 and 1
            // The boundaries for these are 3/16, 1/2 (=8/16), 13/16
            final projection = v.dotProd(d) * 16;
            final lengthSquared = d.dotProd(d);

            if (projection > 3 * lengthSquared) {
              modulationData++;
            }
            if (projection > 8 * lengthSquared) {
              modulationData++;
            }
            if (projection > 13 * lengthSquared) {
              modulationData++;
            }

            modulationData = PvrBitUtility.rotateRight(modulationData, 2);

            factorIndex++;
          }
        }

        packet
          ..setBlock(x, y)
          ..modulationData = modulationData;
      }
    }

    return outputData;
  }

  static PvrColorBoundingBox _calculateBoundingBoxRgb(
      Image bitmap, int blockX, int blockY) {
    PvrColorRgb pixel(int x, int y) {
      final p = bitmap.getPixel(blockX + x, blockY + y);
      return PvrColorRgb(p.r as int, p.g as int, p.b as int);
    }

    final cbb = PvrColorBoundingBox(pixel(0, 0), pixel(0, 0))
      ..add(pixel(1, 0))
      ..add(pixel(2, 0))
      ..add(pixel(3, 0))
      ..add(pixel(0, 1))
      ..add(pixel(1, 1))
      ..add(pixel(1, 2))
      ..add(pixel(1, 3))
      ..add(pixel(2, 0))
      ..add(pixel(2, 1))
      ..add(pixel(2, 2))
      ..add(pixel(2, 3))
      ..add(pixel(3, 0))
      ..add(pixel(3, 1))
      ..add(pixel(3, 2))
      ..add(pixel(3, 3));

    return cbb;
  }

  static PvrColorBoundingBox _calculateBoundingBoxRgba(
      Image bitmap, int blockX, int blockY) {
    PvrColorRgba pixel(int x, int y) {
      final p = bitmap.getPixel(blockX + x, blockY + y);
      return PvrColorRgba(p.r as int, p.g as int, p.b as int, p.a as int);
    }

    final cbb = PvrColorBoundingBox(pixel(0, 0), pixel(0, 0))
      ..add(pixel(1, 0))
      ..add(pixel(2, 0))
      ..add(pixel(3, 0))
      ..add(pixel(0, 1))
      ..add(pixel(1, 1))
      ..add(pixel(1, 2))
      ..add(pixel(1, 3))
      ..add(pixel(2, 0))
      ..add(pixel(2, 1))
      ..add(pixel(2, 2))
      ..add(pixel(2, 3))
      ..add(pixel(3, 0))
      ..add(pixel(3, 1))
      ..add(pixel(3, 2))
      ..add(pixel(3, 3));

    return cbb;
  }
}
