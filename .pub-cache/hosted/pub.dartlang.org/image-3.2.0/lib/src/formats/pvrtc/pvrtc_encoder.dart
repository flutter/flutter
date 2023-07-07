import 'dart:typed_data';

import '../../color.dart';
import '../../image.dart';
import '../../image_exception.dart';
import '../../util/output_buffer.dart';
import 'pvrtc_bit_utility.dart';
import 'pvrtc_color.dart';
import 'pvrtc_color_bounding_box.dart';
import 'pvrtc_packet.dart';

// Ported from Jeffrey Lim's PVRTC encoder/decoder,
// https://bitbucket.org/jthlim/pvrtccompressor
class PvrtcEncoder {
  // PVR Format
  static const PVR_AUTO = -1;
  static const PVR_RGB_2BPP = 0;
  static const PVR_RGBA_2BPP = 1;
  static const PVR_RGB_4BPP = 2;
  static const PVR_RGBA_4BPP = 3;

  Uint8List encodePvr(Image bitmap, {int format = PVR_AUTO}) {
    final output = OutputBuffer();

    late dynamic pvrtc;
    if (format == PVR_AUTO) {
      if (bitmap.channels == Channels.rgb) {
        pvrtc = encodeRgb4Bpp(bitmap);
        format = PVR_RGB_4BPP;
      } else {
        pvrtc = encodeRgba4Bpp(bitmap);
        format = PVR_RGBA_4BPP;
      }
    } else if (format == PVR_RGB_2BPP) {
      //pvrtc = encodeRgb2Bpp(bitmap);
      pvrtc = encodeRgb4Bpp(bitmap);
    } else if (format == PVR_RGBA_2BPP) {
      //pvrtc = encodeRgba2Bpp(bitmap);
      pvrtc = encodeRgba4Bpp(bitmap);
    } else if (format == PVR_RGB_4BPP) {
      pvrtc = encodeRgb4Bpp(bitmap);
    } else if (format == PVR_RGBA_4BPP) {
      pvrtc = encodeRgba4Bpp(bitmap);
    }

    const version = 55727696;
    const flags = 0;
    final pixelFormat = format;
    const channelOrder = 0;
    const colorSpace = 0;
    const channelType = 0;
    final height = bitmap.height;
    final width = bitmap.width;
    const depth = 1;
    const numSurfaces = 1;
    const numFaces = 1;
    const mipmapCount = 1;
    const metaDataSize = 0;

    output.writeUint32(version);
    output.writeUint32(flags);
    output.writeUint32(pixelFormat);
    output.writeUint32(channelOrder);
    output.writeUint32(colorSpace);
    output.writeUint32(channelType);
    output.writeUint32(height);
    output.writeUint32(width);
    output.writeUint32(depth);
    output.writeUint32(numSurfaces);
    output.writeUint32(numFaces);
    output.writeUint32(mipmapCount);
    output.writeUint32(metaDataSize);

    output.writeBytes(pvrtc as List<int>);

    return output.getBytes() as Uint8List;
  }

  Uint8List encodeRgb4Bpp(Image bitmap) {
    if (bitmap.width != bitmap.height) {
      throw ImageException('PVRTC requires a square image.');
    }

    if (!BitUtility.isPowerOf2(bitmap.width)) {
      throw ImageException('PVRTC requires a power-of-two sized image.');
    }

    final size = bitmap.width;
    final blocks = size ~/ 4;
    final blockMask = blocks - 1;

    final bitmapData = bitmap.getBytes();

    // Allocate enough data for encoding the image.
    final outputData = Uint8List((bitmap.width * bitmap.height) ~/ 2);
    final packet = PvrtcPacket(outputData);
    final p0 = PvrtcPacket(outputData);
    final p1 = PvrtcPacket(outputData);
    final p2 = PvrtcPacket(outputData);
    final p3 = PvrtcPacket(outputData);

    for (var y = 0; y < blocks; ++y) {
      for (var x = 0; x < blocks; ++x) {
        packet.setBlock(x, y);
        packet.usePunchthroughAlpha = 0;
        final cbb = _calculateBoundingBoxRgb(bitmap, x, y);
        packet.setColorRgbA(cbb.min as PvrtcColorRgb);
        packet.setColorRgbB(cbb.max as PvrtcColorRgb);
      }
    }

    const factors = PvrtcPacket.BILINEAR_FACTORS;

    for (var y = 0; y < blocks; ++y) {
      for (var x = 0; x < blocks; ++x) {
        var factorIndex = 0;
        final pixelIndex = (y * 4 * size + x * 4) * 4;

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

            final pi = pixelIndex + ((py * size + px) * 4);
            final r = bitmapData[pi];
            final g = bitmapData[pi + 1];
            final b = bitmapData[pi + 2];

            final d = cb - ca;
            final p = PvrtcColorRgb(r * 16, g * 16, b * 16);
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

            modulationData = BitUtility.rotateRight(modulationData, 2);

            factorIndex++;
          }
        }

        packet.setBlock(x, y);
        packet.modulationData = modulationData;
      }
    }

    return outputData;
  }

  Uint8List encodeRgba4Bpp(Image bitmap) {
    if (bitmap.width != bitmap.height) {
      throw ImageException('PVRTC requires a square image.');
    }

    if (!BitUtility.isPowerOf2(bitmap.width)) {
      throw ImageException('PVRTC requires a power-of-two sized image.');
    }

    final size = bitmap.width;
    final blocks = size ~/ 4;
    final blockMask = blocks - 1;

    final bitmapData = bitmap.getBytes();

    // Allocate enough data for encoding the image.
    final outputData = Uint8List((bitmap.width * bitmap.height) ~/ 2);
    final packet = PvrtcPacket(outputData);
    final p0 = PvrtcPacket(outputData);
    final p1 = PvrtcPacket(outputData);
    final p2 = PvrtcPacket(outputData);
    final p3 = PvrtcPacket(outputData);

    for (var y = 0; y < blocks; ++y) {
      for (var x = 0; x < blocks; ++x) {
        packet.setBlock(x, y);
        packet.usePunchthroughAlpha = 0;
        final cbb = _calculateBoundingBoxRgba(bitmap, x, y);
        packet.setColorRgbaA(cbb.min as PvrtcColorRgba);
        packet.setColorRgbaB(cbb.max as PvrtcColorRgba);
      }
    }

    const factors = PvrtcPacket.BILINEAR_FACTORS;

    for (var y = 0; y < blocks; ++y) {
      for (var x = 0; x < blocks; ++x) {
        var factorIndex = 0;
        final pixelIndex = (y * 4 * size + x * 4) * 4;

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

            final pi = pixelIndex + ((py * size + px) * 4);
            final r = bitmapData[pi];
            final g = bitmapData[pi + 1];
            final b = bitmapData[pi + 2];
            final a = bitmapData[pi + 3];

            final d = cb - ca;
            final p = PvrtcColorRgba(r * 16, g * 16, b * 16, a * 16);
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

            modulationData = BitUtility.rotateRight(modulationData, 2);

            factorIndex++;
          }
        }

        packet.setBlock(x, y);
        packet.modulationData = modulationData;
      }
    }

    return outputData;
  }

  static PvrtcColorBoundingBox _calculateBoundingBoxRgb(
      Image bitmap, int blockX, int blockY) {
    final size = bitmap.width;
    final pi = (blockY * 4 * size + blockX * 4);

    PvrtcColorRgb _pixel(int i) {
      final c = bitmap[pi + i];
      return PvrtcColorRgb(getRed(c), getGreen(c), getBlue(c));
    }

    final cbb = PvrtcColorBoundingBox(_pixel(0), _pixel(0));
    cbb.add(_pixel(1));
    cbb.add(_pixel(2));
    cbb.add(_pixel(3));

    cbb.add(_pixel(size));
    cbb.add(_pixel(size + 1));
    cbb.add(_pixel(size + 2));
    cbb.add(_pixel(size + 3));

    cbb.add(_pixel(2 * size));
    cbb.add(_pixel(2 * size + 1));
    cbb.add(_pixel(2 * size + 2));
    cbb.add(_pixel(2 * size + 3));

    cbb.add(_pixel(3 * size));
    cbb.add(_pixel(3 * size + 1));
    cbb.add(_pixel(3 * size + 2));
    cbb.add(_pixel(3 * size + 3));

    return cbb;
  }

  static PvrtcColorBoundingBox _calculateBoundingBoxRgba(
      Image bitmap, int blockX, int blockY) {
    final size = bitmap.width;
    final pi = (blockY * 4 * size + blockX * 4);

    PvrtcColorRgba _pixel(int i) {
      final c = bitmap[pi + i];
      return PvrtcColorRgba(getRed(c), getGreen(c), getBlue(c), getAlpha(c));
    }

    final cbb = PvrtcColorBoundingBox(_pixel(0), _pixel(0));
    cbb.add(_pixel(1));
    cbb.add(_pixel(2));
    cbb.add(_pixel(3));

    cbb.add(_pixel(size));
    cbb.add(_pixel(size + 1));
    cbb.add(_pixel(size + 2));
    cbb.add(_pixel(size + 3));

    cbb.add(_pixel(2 * size));
    cbb.add(_pixel(2 * size + 1));
    cbb.add(_pixel(2 * size + 2));
    cbb.add(_pixel(2 * size + 3));

    cbb.add(_pixel(3 * size));
    cbb.add(_pixel(3 * size + 1));
    cbb.add(_pixel(3 * size + 2));
    cbb.add(_pixel(3 * size + 3));

    return cbb;
  }

  static const MODULATION_LUT = [
    0,
    0,
    0,
    1,
    1,
    1,
    1,
    1,
    2,
    2,
    2,
    2,
    2,
    3,
    3,
    3
  ];
}
