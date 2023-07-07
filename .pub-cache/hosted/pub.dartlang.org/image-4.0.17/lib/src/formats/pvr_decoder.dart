import 'dart:typed_data';

import '../image/image.dart';
import '../util/input_buffer.dart';
import 'decode_info.dart';
import 'decoder.dart';
import 'pvr/pvr_info.dart';
import 'pvr/pvr_packet.dart';

// Ported from Jeffrey Lim's PVRTC encoder/decoder,
// https://bitbucket.org/jthlim/pvrtccompressor
class PvrDecoder extends Decoder {
  Uint8List? _data;
  DecodeInfo? _info;

  @override
  bool isValidFile(Uint8List bytes) => startDecode(bytes) != null;

  @override
  DecodeInfo? startDecode(Uint8List bytes) {
    // Use a heuristic to detect potential apple PVRTC formats
    if (_countBits(bytes.length) == 1) {
      // very likely to be apple PVRTC
      final info = _decodeApplePvrtcHeader(bytes);
      if (info != null) {
        _data = bytes;
        return _info = info;
      }
    }

    var info = _decodePvr3Header(bytes);
    if (info != null) {
      _data = bytes;
      return _info = info;
    }

    info = _decodePvr2Header(bytes);
    if (info != null) {
      _data = bytes;
      return _info = info;
    }

    return null;
  }

  DecodeInfo? _decodePvr3Header(Uint8List bytes) {
    final input = InputBuffer(bytes);

    final size = input.readUint32();
    if (size != _pvrHeaderSize) {
      return null;
    }

    final version = input.readUint32();
    const pvr3Signature = 0x03525650;
    if (version != pvr3Signature) {
      return null;
    }

    final info = Pvr3Info()
      ..flags = input.readUint32()
      ..format = input.readUint32()
      ..order[0] = input.readByte()
      ..order[1] = input.readByte()
      ..order[2] = input.readByte()
      ..order[3] = input.readByte()
      ..colorSpace = input.readUint32()
      ..channelType = input.readUint32()
      ..height = input.readUint32()
      ..width = input.readUint32()
      ..depth = input.readUint32()
      ..numSurfaces = input.readUint32()
      ..numFaces = input.readUint32()
      ..mipCount = input.readUint32()
      ..metadataSize = input.readUint32();

    return info;
  }

  DecodeInfo? _decodePvr2Header(Uint8List bytes) {
    final input = InputBuffer(bytes);

    final size = input.readUint32();
    if (size != _pvrHeaderSize) {
      return null;
    }

    final info = Pvr2Info()
      ..height = input.readUint32()
      ..width = input.readUint32()
      ..mipCount = input.readUint32()
      ..flags = input.readUint32()
      ..texDataSize = input.readUint32()
      ..bitsPerPixel = input.readUint32()
      ..redMask = input.readUint32()
      ..greenMask = input.readUint32()
      ..blueMask = input.readUint32()
      ..alphaMask = input.readUint32()
      ..magic = input.readUint32()
      ..numTex = input.readUint32();

    const pvr2Signature = 0x21525650;
    if (info.magic != pvr2Signature) {
      return null;
    }

    return info;
  }

  DecodeInfo? _decodeApplePvrtcHeader(Uint8List bytes) {
    final fileSize = bytes.length;

    final input = InputBuffer(bytes);

    // Header
    final sz = input.readUint32();
    if (sz != 0) {
      return null;
    }

    final info = PvrAppleInfo()
      ..height = input.readUint32()
      ..width = input.readUint32()
      ..mipCount = input.readUint32()
      ..flags = input.readUint32()
      ..texDataSize = input.readUint32()
      ..bitsPerPixel = input.readUint32()
      ..redMask = input.readUint32()
      ..greenMask = input.readUint32()
      ..blueMask = input.readUint32()
      ..magic = input.readUint32();

    const appleSignature = 0x21525650;
    if (info.magic == appleSignature) {
      return null;
    }

    var mode = 1;
    var res = 8;

    // this is a tough one, could be 2bpp 8x8, 4bpp 8x8
    if (fileSize == 32) {
      // assume 4bpp, 8x8
      mode = 0;
      res = 8;
    } else {
      // Detect if it's 2bpp or 4bpp
      var shift = 0;
      const test2bpp = 0x40; // 16x16
      const test4bpp = 0x80; // 16x16

      while (shift < 10) {
        final s2 = shift << 1;

        if ((test2bpp << s2) & fileSize != 0) {
          res = 16 << shift;
          mode = 1;
          //format = PVRTC2;
          break;
        }

        if ((test4bpp << s2) & fileSize != 0) {
          res = 16 << shift;
          mode = 0;
          //format = PVRTC4;
          break;
        }

        ++shift;
      }

      if (shift == 10) {
        // no mode could be found.
        return null;
      }
    }

    // there is no reliable way to know if it's a 2bpp or 4bpp file. Assuming
    final width = res;
    final height = res;
    final bpp = (mode + 1) * 2;
    //int numMips = 0;

    if (bpp == 4) {
      // 2bpp is currently unsupported
      return null;
    }

    info
      ..width = width
      ..height = height
      ..bitsPerPixel = bpp;

    return info;
  }

  @override
  int numFrames() => 1;

  @override
  Image? decodeFrame(int frame) {
    if (_info == null || _data == null) {
      return null;
    }

    if (_info is PvrAppleInfo) {
      return _decodeRgba4bpp(_info!.width, _info!.height, _data!);
    } else if (_info is Pvr2Info) {
      return _decodePvr2(_data!);
    } else if (_info is Pvr3Info) {
      return _decodePvr3(_data!);
    }

    return null;
  }

  @override
  Image? decode(Uint8List bytes, {int? frame}) {
    if (startDecode(bytes) == null) {
      return null;
    }
    return decodeFrame(frame ?? 0);
  }

  Image? _decodePvr2(Uint8List data) {
    final length = data.length;

    const pvrTexCubemap = 1 << 12;
    const pvrPixelTypeMask = 0xff;
    const pvrTypeRgba4444 = 0x10;
    const pvrTypeRgba5551 = 0x11;
    const pvrTypeRgba8888 = 0x12;
    const pvrTypeRgb565 = 0x13;
    const pvrTypeRgb555 = 0x14;
    const pvrTypeRgb888 = 0x15;
    const pvrTypeI8 = 0x16;
    const pvrTypeAI8 = 0x17;
    const pvrTypePvrtc2 = 0x18;
    const pvrTypePvrtc4 = 0x19;

    if (length < _pvrHeaderSize || _info == null) {
      return null;
    }

    final info = _info! as Pvr2Info;

    final input = InputBuffer(data)..skip(_pvrHeaderSize);
    // Header

    var numTex = info.numTex;
    if (numTex < 1) {
      numTex = (info.flags & pvrTexCubemap) != 0 ? 6 : 1;
    }

    if (numTex != 1) {
      // only 1 surface supported currently
      return null;
    }

    if (info.width * info.height * info.bitsPerPixel / 8 >
        length - _pvrHeaderSize) {
      return null;
    }

    final pType = info.flags & pvrPixelTypeMask;

    switch (pType) {
      case pvrTypeRgba4444:
        final image =
            Image(width: info.width, height: info.height, numChannels: 4);
        for (final p in image) {
          final v1 = input.readByte();
          final v2 = input.readByte();
          final a = (v1 & 0x0f) << 4;
          final b = v1 & 0xf0;
          final g = (v2 & 0x0f) << 4;
          final r = v2 & 0xf0;

          p
            ..r = r
            ..g = g
            ..b = b
            ..a = a;
        }
        return image;
      case pvrTypeRgba5551:
        final image =
            Image(width: info.width, height: info.height, numChannels: 4);
        for (final p in image) {
          final v = input.readUint16();
          final r = (v & 0xf800) >> 8;
          final g = (v & 0x07c0) >> 3;
          final b = (v & 0x003e) << 2;
          final a = (v & 0x0001) != 0 ? 255 : 0;
          p
            ..r = r
            ..g = g
            ..b = b
            ..a = a;
        }
        return image;
      case pvrTypeRgba8888:
        final image =
            Image(width: info.width, height: info.height, numChannels: 4);
        for (final p in image) {
          p
            ..r = input.readByte()
            ..g = input.readByte()
            ..b = input.readByte()
            ..a = input.readByte();
        }
        return image;
      case pvrTypeRgb565:
        final image = Image(width: info.width, height: info.height);
        for (final p in image) {
          final v = input.readUint16();
          final b = (v & 0x001f) << 3;
          final g = (v & 0x07e0) >> 3;
          final r = (v & 0xf800) >> 8;
          p
            ..r = r
            ..g = g
            ..b = b;
        }
        return image;
      case pvrTypeRgb555:
        final image = Image(width: info.width, height: info.height);
        for (final p in image) {
          final v = input.readUint16();
          final r = (v & 0x001f) << 3;
          final g = (v & 0x03e0) >> 2;
          final b = (v & 0x7c00) >> 7;
          p
            ..r = r
            ..g = g
            ..b = b;
        }
        return image;
      case pvrTypeRgb888:
        final image = Image(width: info.width, height: info.height);
        for (final p in image) {
          p
            ..r = input.readByte()
            ..g = input.readByte()
            ..b = input.readByte();
        }
        return image;
      case pvrTypeI8:
        final image =
            Image(width: info.width, height: info.height, numChannels: 1);
        for (final p in image) {
          final i = input.readByte();
          p.r = i;
        }
        return image;
      case pvrTypeAI8:
        final image =
            Image(width: info.width, height: info.height, numChannels: 4);
        for (final p in image) {
          final a = input.readByte();
          final i = input.readByte();
          p
            ..r = i
            ..g = i
            ..b = i
            ..a = a;
        }
        return image;
      case pvrTypePvrtc2:
        // Currently unsupported
        return null;
      case pvrTypePvrtc4:
        return info.alphaMask == 0
            ? _decodeRgb4bpp(info.width, info.height, input.toUint8List())
            : _decodeRgba4bpp(info.width, info.height, input.toUint8List());
    }

    // Unknown format
    return null;
  }

  Image? _decodePvr3(Uint8List data) {
    if (_info is! Pvr3Info) {
      return null;
    }

    //const PVR3_PVRTC_2BPP_RGB = 0;
    //const PVR3_PVRTC_2BPP_RGBA = 1;
    const pvr3Pvrtc4bppRgb = 2;
    const pvr3Pvrtc4bppRgba = 3;
    /*const PVR3_PVRTC2_2BPP = 4;
    const PVR3_PVRTC2_4BPP = 5;
    const PVR3_ETC1 = 6;
    const PVR3_DXT1 = 7;
    const PVR3_DXT2 = 8;
    const PVR3_DXT3 = 9;
    const PVR3_DXT4 = 10;
    const PVR3_DXT5 = 11;
    const PVR3_BC1 = 7;
    const PVR3_BC2 = 9;
    const PVR3_BC3 = 11;
    const PVR3_BC4 = 12;
    const PVR3_BC5 = 13;
    const PVR3_BC6 = 14;
    const PVR3_BC7 = 15;
    const PVR3_UYVY = 16;
    const PVR3_YUY2 = 17;
    const PVR3_BW_1BPP = 18;
    const PVR3_R9G9B9E5 = 19;
    const PVR3_RGBG8888 = 20;
    const PVR3_GRGB8888 = 21;
    const PVR3_ETC2_RGB = 22;
    const PVR3_ETC2_RGBA = 23;
    const PVR3_ETC2_RGB_A1 = 24;
    const PVR3_EAC_R11_U = 25;
    const PVR3_EAC_R11_S = 26;
    const PVR3_EAC_RG11_U = 27;
    const PVR3_EAC_RG11_S = 28;*/

    final input = InputBuffer(data)..skip(_pvrHeaderSize);

    final info = _info as Pvr3Info;

    input.skip(info.metadataSize);

    if (info.order[0] == 0) {
      switch (info.format) {
        case pvr3Pvrtc4bppRgb:
          return _decodeRgb4bpp(info.width, info.height, input.toUint8List());
        case pvr3Pvrtc4bppRgba:
          return _decodeRgba4bpp(info.width, info.height, input.toUint8List());
        /*case PVR3_PVRTC_2BPP_RGB:
          return null;
        case PVR3_PVRTC_2BPP_RGBA:
          return null;
        case PVR3_PVRTC2_2BPP:
          return null;
        case PVR3_PVRTC2_4BPP:
          return null;
        case PVR3_ETC1:
          return null;
        case PVR3_DXT1:
          return null;
        case PVR3_DXT2:
          return null;
        case PVR3_DXT3:
          return null;
        case PVR3_DXT4:
          return null;
        case PVR3_DXT5:
          return null;
        case PVR3_BC1:
          return null;
        case PVR3_BC2:
          return null;
        case PVR3_BC3:
          return null;
        case PVR3_BC4:
          return null;
        case PVR3_BC5:
          return null;
        case PVR3_BC6:
          return null;
        case PVR3_BC7:
          return null;
        case PVR3_UYVY:
          return null;
        case PVR3_YUY2:
          return null;
        case PVR3_BW_1BPP:
          return null;
        case PVR3_R9G9B9E5:
          return null;
        case PVR3_RGBG8888:
          return null;
        case PVR3_GRGB8888:
          return null;
        case PVR3_ETC2_RGB:
          return null;
        case PVR3_ETC2_RGBA:
          return null;
        case PVR3_ETC2_RGB_A1:
          return null;
        case PVR3_EAC_R11_U:
          return null;
        case PVR3_EAC_R11_S:
          return null;
        case PVR3_EAC_RG11_U:
          return null;
        case PVR3_EAC_RG11_S:
          return null;*/
      }
    }

    return null;
  }

  int _countBits(int x) {
    x = (x - ((x >> 1) & 0x55555555)) & 0xffffffff;
    x = ((x & 0x33333333) + ((x >> 2) & 0x33333333)) & 0xffffffff;
    x = (x + (x >> 4)) & 0xffffffff;
    x &= 0xf0f0f0f;
    x = ((x * 0x01010101) & 0xffffffff) >> 24;
    return x;
  }

  Image _decodeRgb4bpp(int width, int height, TypedData data) {
    final result = Image(width: width, height: height);

    final blocks = width ~/ 4;
    final blockMask = blocks - 1;

    final packet = PvrPacket(data);
    final p0 = PvrPacket(data);
    final p1 = PvrPacket(data);
    final p2 = PvrPacket(data);
    final p3 = PvrPacket(data);
    const factors = PvrPacket.bilinearFactors;
    const weights = PvrPacket.weights;

    for (var y = 0, y4 = 0; y < blocks; ++y, y4 += 4) {
      for (var x = 0, x4 = 0; x < blocks; ++x, x4 += 4) {
        packet.setBlock(x, y);

        var mod = packet.modulationData;
        final weightIndex = packet.usePunchthroughAlpha ? 4 : 0;
        var factorIndex = 0;

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

            final w = weights[weightIndex + mod & 3];

            final r = (ca.r * w[0] + cb.r * w[1]) >> 7;
            final g = (ca.g * w[0] + cb.g * w[1]) >> 7;
            final b = (ca.b * w[0] + cb.b * w[1]) >> 7;
            result.setPixelRgb(px + x4, py + y4, r, g, b);

            mod >>= 2;
            factorIndex++;
          }
        }
      }
    }

    return result;
  }

  Image _decodeRgba4bpp(int width, int height, TypedData data) {
    final result = Image(width: width, height: height, numChannels: 4);

    final blocks = width ~/ 4;
    final blockMask = blocks - 1;

    final packet = PvrPacket(data);
    final p0 = PvrPacket(data);
    final p1 = PvrPacket(data);
    final p2 = PvrPacket(data);
    final p3 = PvrPacket(data);
    const factors = PvrPacket.bilinearFactors;
    const weights = PvrPacket.weights;

    for (var y = 0, y4 = 0; y < blocks; ++y, y4 += 4) {
      for (var x = 0, x4 = 0; x < blocks; ++x, x4 += 4) {
        packet.setBlock(x, y);

        var mod = packet.modulationData;
        final weightIndex = packet.usePunchthroughAlpha ? 4 : 0;
        var factorIndex = 0;

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

            final w = weights[weightIndex + mod & 3];

            final r = (ca.r * w[0] + cb.r * w[1]) >> 7;
            final g = (ca.g * w[0] + cb.g * w[1]) >> 7;
            final b = (ca.b * w[0] + cb.b * w[1]) >> 7;
            final a = (ca.a * w[2] + cb.a * w[3]) >> 7;
            result.setPixelRgba(px + x4, py + y4, r, g, b, a);

            mod >>= 2;
            factorIndex++;
          }
        }
      }
    }

    return result;
  }

  static const _pvrHeaderSize = 52;
}
