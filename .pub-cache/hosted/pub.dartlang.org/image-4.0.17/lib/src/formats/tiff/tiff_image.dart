import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../color/format.dart';
import '../../exif/exif_tag.dart';
import '../../exif/ifd_value.dart';
import '../../image/image.dart';
import '../../util/bit_utils.dart';
import '../../util/color_util.dart';
import '../../util/float16.dart';
import '../../util/image_exception.dart';
import '../../util/input_buffer.dart';
import '../jpeg_decoder.dart';
import 'tiff_bit_reader.dart';
import 'tiff_entry.dart';
import 'tiff_fax_decoder.dart';
import 'tiff_lzw_decoder.dart';

class TiffImage {
  Map<int, TiffEntry> tags = {};
  int width = 0;
  int height = 0;
  TiffPhotometricType photometricType = TiffPhotometricType.unknown;
  int compression = 1;
  int bitsPerSample = 1;
  int samplesPerPixel = 1;
  TiffFormat sampleFormat = TiffFormat.uint;
  TiffImageType imageType = TiffImageType.invalid;
  bool isWhiteZero = false;
  int predictor = 1;
  late int chromaSubH;
  late int chromaSubV;
  bool tiled = false;
  int tileWidth = 0;
  int tileHeight = 0;
  List<int>? tileOffsets;
  List<int>? tileByteCounts;
  late int tilesX;
  late int tilesY;
  int? tileSize;
  int? fillOrder = 1;
  int? t4Options = 0;
  int? t6Options = 0;
  int? extraSamples;
  int colorMapSamples = 0;
  List<int>? colorMap;
  // Starting index in the [colorMap] for the red channel.
  late int colorMapRed;
  // Starting index in the [colorMap] for the green channel.
  late int colorMapGreen;
  // Starting index in the [colorMap] for the blue channel.
  late int colorMapBlue;

  TiffImage(InputBuffer p) {
    final p3 = InputBuffer.from(p);

    final numDirEntries = p.readUint16();
    for (var i = 0; i < numDirEntries; ++i) {
      final tag = p.readUint16();
      final ti = p.readUint16();
      final type = IfdValueType.values[ti];
      final typeSize = ifdValueTypeSize[ti];
      final count = p.readUint32();
      var valueOffset = 0;
      // The value for the tag is either stored in another location,
      // or within the tag itself (if the size fits in 4 bytes).
      // We're not reading the data here, just storing offsets.
      if (count * typeSize > 4) {
        valueOffset = p.readUint32();
      } else {
        valueOffset = p.offset;
        p.skip(4);
      }

      final entry = TiffEntry(tag, type, count, p3, valueOffset);

      tags[entry.tag] = entry;

      if (tag == exifTagNameToID['ImageWidth']) {
        width = entry.read()?.toInt() ?? 0;
      } else if (tag == exifTagNameToID['ImageLength']) {
        height = entry.read()?.toInt() ?? 0;
      } else if (tag == exifTagNameToID['PhotometricInterpretation']) {
        final v = entry.read();
        final pt = v?.toInt() ?? TiffPhotometricType.values.length;
        if (pt < TiffPhotometricType.values.length) {
          photometricType = TiffPhotometricType.values[pt];
        } else {
          photometricType = TiffPhotometricType.unknown;
        }
      } else if (tag == exifTagNameToID['Compression']) {
        compression = entry.read()?.toInt() ?? 0;
      } else if (tag == exifTagNameToID['BitsPerSample']) {
        bitsPerSample = entry.read()?.toInt() ?? 0;
      } else if (tag == exifTagNameToID['SamplesPerPixel']) {
        samplesPerPixel = entry.read()?.toInt() ?? 0;
      } else if (tag == exifTagNameToID['Predictor']) {
        predictor = entry.read()?.toInt() ?? 0;
      } else if (tag == exifTagNameToID['SampleFormat']) {
        final v = entry.read()?.toInt() ?? 0;
        sampleFormat = TiffFormat.values[v];
      } else if (tag == exifTagNameToID['ColorMap']) {
        final v = entry.read();
        if (v != null) {
          colorMap = v.toData().buffer.asUint16List();
          colorMapRed = 0;
          colorMapGreen = colorMap!.length ~/ 3;
          colorMapBlue = colorMapGreen * 2;
        }
      }
    }

    if (colorMap != null && photometricType == TiffPhotometricType.palette) {
      // Only support RGB palettes.
      colorMapSamples = 3;
      samplesPerPixel = 1;
    }

    if (width == 0 || height == 0) {
      return;
    }

    if (colorMap != null && bitsPerSample == 8) {
      final cm = colorMap!;
      final len = cm.length;
      for (var i = 0; i < len; ++i) {
        cm[i] >>= 8;
      }
    }

    if (photometricType == TiffPhotometricType.whiteIsZero) {
      isWhiteZero = true;
    }

    if (hasTag(exifTagNameToID['TileOffsets']!)) {
      tiled = true;
      // Image is in tiled format
      tileWidth = _readTag(exifTagNameToID['TileWidth']!);
      tileHeight = _readTag(exifTagNameToID['TileLength']!);
      tileOffsets = _readTagList(exifTagNameToID['TileOffsets']!);
      tileByteCounts = _readTagList(exifTagNameToID['TileByteCounts']!);
    } else {
      tiled = false;

      tileWidth = _readTag(exifTagNameToID['TileWidth']!, width);
      if (!hasTag(exifTagNameToID['RowsPerStrip']!)) {
        tileHeight = _readTag(exifTagNameToID['TileLength']!, height);
      } else {
        final l = _readTag(exifTagNameToID['RowsPerStrip']!);
        var infinity = 1;
        infinity = (infinity << 32) - 1;
        if (l == infinity) {
          // 2^32 - 1 (effectively infinity, entire image is 1 strip)
          tileHeight = height;
        } else {
          tileHeight = l;
        }
      }

      tileOffsets = _readTagList(exifTagNameToID['StripOffsets']!);
      tileByteCounts = _readTagList(exifTagNameToID['StripByteCounts']!);
    }

    // Calculate number of tiles and the tileSize in bytes
    tilesX = (width + tileWidth - 1) ~/ tileWidth;
    tilesY = (height + tileHeight - 1) ~/ tileHeight;
    tileSize = tileWidth * tileHeight * samplesPerPixel;

    fillOrder = _readTag(exifTagNameToID['FillOrder']!, 1);
    t4Options = _readTag(exifTagNameToID['T4Options']!);
    t6Options = _readTag(exifTagNameToID['T6Options']!);
    extraSamples = _readTag(exifTagNameToID['ExtraSamples']!);

    // Determine which kind of image we are dealing with.
    switch (photometricType) {
      case TiffPhotometricType.whiteIsZero:
      case TiffPhotometricType.blackIsZero:
        if (bitsPerSample == 1 && samplesPerPixel == 1) {
          imageType = TiffImageType.bilevel;
        } else if (bitsPerSample == 4 && samplesPerPixel == 1) {
          imageType = TiffImageType.gray4bit;
        } else if (bitsPerSample % 8 == 0) {
          if (samplesPerPixel == 1) {
            imageType = TiffImageType.gray;
          } else if (samplesPerPixel == 2) {
            imageType = TiffImageType.grayAlpha;
          } else {
            imageType = TiffImageType.generic;
          }
        }
        break;
      case TiffPhotometricType.rgb:
        if (bitsPerSample % 8 == 0) {
          if (samplesPerPixel == 3) {
            imageType = TiffImageType.rgb;
          } else if (samplesPerPixel == 4) {
            imageType = TiffImageType.rgba;
          } else {
            imageType = TiffImageType.generic;
          }
        }
        break;
      case TiffPhotometricType.palette:
        if (samplesPerPixel == 1 &&
            colorMap != null &&
            (bitsPerSample == 4 || bitsPerSample == 8 || bitsPerSample == 16)) {
          imageType = TiffImageType.palette;
        }
        break;
      case TiffPhotometricType.transparencyMask: // Transparency mask
        if (bitsPerSample == 1 && samplesPerPixel == 1) {
          imageType = TiffImageType.bilevel;
        }
        break;
      case TiffPhotometricType.yCbCr:
        if (compression == TiffCompression.jpeg &&
            bitsPerSample == 8 &&
            samplesPerPixel == 3) {
          imageType = TiffImageType.rgb;
        } else {
          if (hasTag(exifTagNameToID['YCbCrSubSampling']!)) {
            final v = tags[exifTagNameToID['YCbCrSubSampling']!]!.read()!;
            chromaSubH = v.toInt();
            chromaSubV = v.toInt(1);
          } else {
            chromaSubH = 2;
            chromaSubV = 2;
          }

          if (chromaSubH * chromaSubV == 1) {
            imageType = TiffImageType.generic;
          } else if (bitsPerSample == 8 && samplesPerPixel == 3) {
            imageType = TiffImageType.yCbCrSub;
          }
        }
        break;
      default: // Other including CMYK, CIE L*a*b*, unknown.
        if (bitsPerSample % 8 == 0) {
          imageType = TiffImageType.generic;
        }
        break;
    }
  }

  bool get isValid => width != 0 && height != 0;

  Image decode(InputBuffer p) {
    final isFloat = sampleFormat == TiffFormat.float;
    final isInt = sampleFormat == TiffFormat.int;
    final format = bitsPerSample == 1
        ? Format.uint1
        : bitsPerSample == 2
            ? Format.uint2
            : bitsPerSample == 4
                ? Format.uint4
                : isFloat && bitsPerSample == 16
                    ? Format.float16
                    : isFloat && bitsPerSample == 32
                        ? Format.float32
                        : isFloat && bitsPerSample == 64
                            ? Format.float64
                            : isInt && bitsPerSample == 8
                                ? Format.int8
                                : isInt && bitsPerSample == 16
                                    ? Format.int16
                                    : isInt && bitsPerSample == 32
                                        ? Format.int32
                                        : bitsPerSample == 16
                                            ? Format.uint16
                                            : bitsPerSample == 32
                                                ? Format.uint32
                                                : Format.uint8;
    final hasPalette =
        colorMap != null && photometricType == TiffPhotometricType.palette;
    final numChannels = hasPalette ? 3 : samplesPerPixel;

    final image = Image(
        width: width,
        height: height,
        format: format,
        numChannels: numChannels,
        withPalette: hasPalette);

    if (hasPalette) {
      final p = image.palette!;
      final cm = colorMap!;
      const numChannels = 3; // Only support RGB palettes
      final numColors = cm.length ~/ numChannels;
      for (var i = 0; i < numColors; ++i) {
        p.setRgb(i, cm[colorMapRed + i], cm[colorMapGreen + i],
            cm[colorMapBlue + i]);
      }
    }

    for (var tileY = 0, ti = 0; tileY < tilesY; ++tileY) {
      for (var tileX = 0; tileX < tilesX; ++tileX, ++ti) {
        _decodeTile(p, image, tileX, tileY);
      }
    }

    return image;
  }

  bool hasTag(int tag) => tags.containsKey(tag);

  void _decodeTile(InputBuffer p, Image image, int tileX, int tileY) {
    // Read the data, uncompressing as needed. There are four cases:
    // bilevel, palette-RGB, 4-bit grayscale, and everything else.
    if (imageType == TiffImageType.bilevel) {
      _decodeBilevelTile(p, image, tileX, tileY);
      return;
    }

    final tileIndex = tileY * tilesX + tileX;
    p.offset = tileOffsets![tileIndex];

    final outX = tileX * tileWidth;
    final outY = tileY * tileHeight;

    final byteCount = tileByteCounts![tileIndex];
    var bytesInThisTile = tileWidth * tileHeight * samplesPerPixel;
    if (bitsPerSample == 16) {
      bytesInThisTile *= 2;
    } else if (bitsPerSample == 32) {
      bytesInThisTile *= 4;
    }

    InputBuffer byteData;
    if (bitsPerSample == 8 ||
        bitsPerSample == 16 ||
        bitsPerSample == 32 ||
        bitsPerSample == 64) {
      if (compression == TiffCompression.none) {
        byteData = p;
      } else if (compression == TiffCompression.lzw) {
        byteData = InputBuffer(Uint8List(bytesInThisTile));
        final decoder = LzwDecoder();
        try {
          decoder.decode(
              InputBuffer.from(p, length: byteCount), byteData.buffer);
        } catch (e) {
          //print(e);
        }
        // Horizontal Differencing Predictor
        if (predictor == 2) {
          int count;
          for (var j = 0; j < tileHeight; j++) {
            count = samplesPerPixel * (j * tileWidth + 1);
            final len = tileWidth * samplesPerPixel;
            for (var i = samplesPerPixel; i < len; i++) {
              byteData[count] += byteData[count - samplesPerPixel];
              count++;
            }
          }
        }
      } else if (compression == TiffCompression.packBits) {
        byteData = InputBuffer(Uint8List(bytesInThisTile));
        _decodePackBits(p, bytesInThisTile, byteData.buffer);
      } else if (compression == TiffCompression.deflate) {
        final data = p.toList(0, byteCount);
        final outData = Inflate(data).getBytes();
        byteData = InputBuffer(outData);
      } else if (compression == TiffCompression.zip) {
        final data = p.toList(0, byteCount);
        final outData = const ZLibDecoder().decodeBytes(data);
        byteData = InputBuffer(outData);
      } else if (compression == TiffCompression.oldJpeg) {
        final data = p.toList(0, byteCount);
        final tile = JpegDecoder().decode(data as Uint8List);
        if (tile != null) {
          _jpegToImage(tile, image, outX, outY, tileWidth, tileHeight);
        }
        return;
      } else {
        throw ImageException('Unsupported Compression Type: $compression');
      }

      for (var y = 0, py = outY; y < tileHeight && py < height; ++y, ++py) {
        for (var x = 0, px = outX; x < tileWidth && px < width; ++x, ++px) {
          if (samplesPerPixel == 1) {
            if (sampleFormat == TiffFormat.float) {
              num sample = 0;
              if (bitsPerSample == 32) {
                sample = byteData.readFloat32();
              } else if (bitsPerSample == 64) {
                sample = byteData.readFloat64();
              } else if (bitsPerSample == 16) {
                sample = Float16.float16ToDouble(byteData.readUint16());
              }
              image.setPixelR(px, py, sample);
            } else {
              var sample = 0;
              if (bitsPerSample == 8) {
                sample = sampleFormat == TiffFormat.int
                    ? byteData.readInt8()
                    : byteData.readByte();
              } else if (bitsPerSample == 16) {
                sample = sampleFormat == TiffFormat.int
                    ? byteData.readInt16()
                    : byteData.readUint16();
              } else if (bitsPerSample == 32) {
                sample = sampleFormat == TiffFormat.int
                    ? byteData.readInt32()
                    : byteData.readUint32();
              }

              if (photometricType == TiffPhotometricType.whiteIsZero) {
                final mx = image.maxChannelValue as int;
                sample = mx - sample;
              }

              image.setPixelR(px, py, sample);
            }
          } else if (samplesPerPixel == 2) {
            var gray = 0;
            var alpha = 0;
            if (bitsPerSample == 8) {
              gray = sampleFormat == TiffFormat.int
                  ? byteData.readInt8()
                  : byteData.readByte();
              alpha = sampleFormat == TiffFormat.int
                  ? byteData.readInt8()
                  : byteData.readByte();
            } else if (bitsPerSample == 16) {
              gray = sampleFormat == TiffFormat.int
                  ? byteData.readInt16()
                  : byteData.readUint16();
              alpha = sampleFormat == TiffFormat.int
                  ? byteData.readInt16()
                  : byteData.readUint16();
            } else if (bitsPerSample == 32) {
              gray = sampleFormat == TiffFormat.int
                  ? byteData.readInt32()
                  : byteData.readUint32();
              alpha = sampleFormat == TiffFormat.int
                  ? byteData.readInt32()
                  : byteData.readUint32();
            }

            image.setPixelRgb(px, py, gray, alpha, 0);
          } else if (samplesPerPixel == 3) {
            if (sampleFormat == TiffFormat.float) {
              var r = 0.0;
              var g = 0.0;
              var b = 0.0;
              if (bitsPerSample == 32) {
                r = byteData.readFloat32();
                g = byteData.readFloat32();
                b = byteData.readFloat32();
              } else if (bitsPerSample == 64) {
                r = byteData.readFloat64();
                g = byteData.readFloat64();
                b = byteData.readFloat64();
              } else if (bitsPerSample == 16) {
                r = Float16.float16ToDouble(byteData.readUint16());
                g = Float16.float16ToDouble(byteData.readUint16());
                b = Float16.float16ToDouble(byteData.readUint16());
              }
              image.setPixelRgb(px, py, r, g, b);
            } else {
              var r = 0;
              var g = 0;
              var b = 0;
              if (bitsPerSample == 8) {
                r = sampleFormat == TiffFormat.int
                    ? byteData.readInt8()
                    : byteData.readByte();
                g = sampleFormat == TiffFormat.int
                    ? byteData.readInt8()
                    : byteData.readByte();
                b = sampleFormat == TiffFormat.int
                    ? byteData.readInt8()
                    : byteData.readByte();
              } else if (bitsPerSample == 16) {
                r = sampleFormat == TiffFormat.int
                    ? byteData.readInt16()
                    : byteData.readUint16();
                g = sampleFormat == TiffFormat.int
                    ? byteData.readInt16()
                    : byteData.readUint16();
                b = sampleFormat == TiffFormat.int
                    ? byteData.readInt16()
                    : byteData.readUint16();
              } else if (bitsPerSample == 32) {
                r = sampleFormat == TiffFormat.int
                    ? byteData.readInt32()
                    : byteData.readUint32();
                g = sampleFormat == TiffFormat.int
                    ? byteData.readInt32()
                    : byteData.readUint32();
                b = sampleFormat == TiffFormat.int
                    ? byteData.readInt32()
                    : byteData.readUint32();
              }

              image.setPixelRgb(px, py, r, g, b);
            }
          } else if (samplesPerPixel >= 4) {
            if (sampleFormat == TiffFormat.float) {
              var r = 0.0;
              var g = 0.0;
              var b = 0.0;
              var a = 0.0;
              if (bitsPerSample == 32) {
                r = byteData.readFloat32();
                g = byteData.readFloat32();
                b = byteData.readFloat32();
                a = byteData.readFloat32();
              } else if (bitsPerSample == 64) {
                r = byteData.readFloat64();
                g = byteData.readFloat64();
                b = byteData.readFloat64();
                a = byteData.readFloat64();
              } else if (bitsPerSample == 16) {
                r = Float16.float16ToDouble(byteData.readUint16());
                g = Float16.float16ToDouble(byteData.readUint16());
                b = Float16.float16ToDouble(byteData.readUint16());
                a = Float16.float16ToDouble(byteData.readUint16());
              }
              image.setPixelRgba(px, py, r, g, b, a);
            } else {
              var r = 0;
              var g = 0;
              var b = 0;
              var a = 0;
              if (bitsPerSample == 8) {
                r = sampleFormat == TiffFormat.int
                    ? byteData.readInt8()
                    : byteData.readByte();
                g = sampleFormat == TiffFormat.int
                    ? byteData.readInt8()
                    : byteData.readByte();
                b = sampleFormat == TiffFormat.int
                    ? byteData.readInt8()
                    : byteData.readByte();
                a = sampleFormat == TiffFormat.int
                    ? byteData.readInt8()
                    : byteData.readByte();
              } else if (bitsPerSample == 16) {
                r = sampleFormat == TiffFormat.int
                    ? byteData.readInt16()
                    : byteData.readUint16();
                g = sampleFormat == TiffFormat.int
                    ? byteData.readInt16()
                    : byteData.readUint16();
                b = sampleFormat == TiffFormat.int
                    ? byteData.readInt16()
                    : byteData.readUint16();
                a = sampleFormat == TiffFormat.int
                    ? byteData.readInt16()
                    : byteData.readUint16();
              } else if (bitsPerSample == 32) {
                r = sampleFormat == TiffFormat.int
                    ? byteData.readInt32()
                    : byteData.readUint32();
                g = sampleFormat == TiffFormat.int
                    ? byteData.readInt32()
                    : byteData.readUint32();
                b = sampleFormat == TiffFormat.int
                    ? byteData.readInt32()
                    : byteData.readUint32();
                a = sampleFormat == TiffFormat.int
                    ? byteData.readInt32()
                    : byteData.readUint32();
              }

              if (photometricType == TiffPhotometricType.cmyk) {
                final rgba = cmykToRgb(r, g, b, a);
                r = rgba[0];
                g = rgba[1];
                b = rgba[2];
                a = image.maxChannelValue as int;
              }

              image.setPixelRgba(px, py, r, g, b, a);
            }
          }
        }
      }
    } else {
      throw ImageException('Unsupported bitsPerSample: $bitsPerSample');
    }
  }

  void _jpegToImage(Image tile, Image image, int outX, int outY, int tileWidth,
      int tileHeight) {
    final width = tileWidth;
    final height = tileHeight;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        image.setPixel(x + outX, y + outY, tile.getPixel(x, y));
      }
    }
    /*Uint8List data = jpeg.getData(width, height);
    List components = jpeg.components;

    int i = 0;
    int j = 0;
    switch (components.length) {
      case 1: // Luminance
        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            int Y = data[i++];
            image.setPixel(x + outX, y + outY, getColor(Y, Y, Y, 255));
          }
        }
        break;
      case 3: // RGB
        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            int R = data[i++];
            int G = data[i++];
            int B = data[i++];

            int c = getColor(R, G, B, 255);
            image.setPixel(x + outX, y + outY, c);
          }
        }
        break;
      case 4: // CMYK
        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            int C = data[i++];
            int M = data[i++];
            int Y = data[i++];
            int K = data[i++];

            int R = 255 - _clamp(C * (1 - K ~/ 255) + K);
            int G = 255 - _clamp(M * (1 - K ~/ 255) + K);
            int B = 255 - _clamp(Y * (1 - K ~/ 255) + K);

            image.setPixel(x + outX, y + outY, getColor(R, G, B, 255));
          }
        }
        break;
      default:
        throw 'Unsupported color mode';
    }*/
  }

  void _decodeBilevelTile(InputBuffer p, Image image, int tileX, int tileY) {
    final tileIndex = tileY * tilesX + tileX;
    p.offset = tileOffsets![tileIndex];

    final outX = tileX * tileWidth;
    final outY = tileY * tileHeight;

    final byteCount = tileByteCounts![tileIndex];

    InputBuffer byteData;
    if (compression == TiffCompression.packBits) {
      // Since the decompressed data will still be packed
      // 8 pixels into 1 byte, calculate bytesInThisTile
      int bytesInThisTile;
      if ((tileWidth % 8) == 0) {
        bytesInThisTile = (tileWidth ~/ 8) * tileHeight;
      } else {
        bytesInThisTile = (tileWidth ~/ 8 + 1) * tileHeight;
      }
      byteData = InputBuffer(Uint8List(tileWidth * tileHeight));
      _decodePackBits(p, bytesInThisTile, byteData.buffer);
    } else if (compression == TiffCompression.lzw) {
      byteData = InputBuffer(Uint8List(tileWidth * tileHeight));

      LzwDecoder()
          .decode(InputBuffer.from(p, length: byteCount), byteData.buffer);

      // Horizontal Differencing Predictor
      if (predictor == 2) {
        int count;
        for (var j = 0; j < height; j++) {
          count = samplesPerPixel * (j * width + 1);
          for (var i = samplesPerPixel; i < width * samplesPerPixel; i++) {
            byteData[count] += byteData[count - samplesPerPixel];
            count++;
          }
        }
      }
    } else if (compression == TiffCompression.ccittRle) {
      byteData = InputBuffer(Uint8List(tileWidth * tileHeight));
      try {
        TiffFaxDecoder(fillOrder, tileWidth, tileHeight)
            .decode1D(byteData, p, 0, tileHeight);
      } catch (_) {}
    } else if (compression == TiffCompression.ccittFax3) {
      byteData = InputBuffer(Uint8List(tileWidth * tileHeight));
      try {
        TiffFaxDecoder(fillOrder, tileWidth, tileHeight)
            .decode2D(byteData, p, 0, tileHeight, t4Options!);
      } catch (_) {}
    } else if (compression == TiffCompression.ccittFax4) {
      byteData = InputBuffer(Uint8List(tileWidth * tileHeight));
      try {
        TiffFaxDecoder(fillOrder, tileWidth, tileHeight)
            .decodeT6(byteData, p, 0, tileHeight, t6Options!);
      } catch (_) {}
    } else if (compression == TiffCompression.zip) {
      final data = p.toList(0, byteCount);
      final outData = const ZLibDecoder().decodeBytes(data);
      byteData = InputBuffer(outData);
    } else if (compression == TiffCompression.deflate) {
      final data = p.toList(0, byteCount);
      final outData = Inflate(data).getBytes();
      byteData = InputBuffer(outData);
    } else if (compression == TiffCompression.none) {
      byteData = p;
    } else {
      throw ImageException('Unsupported Compression Type: $compression');
    }

    final br = TiffBitReader(byteData);
    final mx = image.maxChannelValue;
    final black = isWhiteZero ? mx : 0;
    final white = isWhiteZero ? 0 : mx;

    for (var y = 0, py = outY; y < tileHeight; ++y, ++py) {
      for (var x = 0, px = outX; x < tileWidth; ++x, ++px) {
        if (py >= image.height || px >= image.width) {
          break;
        }
        if (br.readBits(1) == 0) {
          image.setPixelRgb(px, py, black, 0, 0);
        } else {
          image.setPixelRgb(px, py, white, 0, 0);
        }
      }
      br.flushByte();
    }
  }

  // Uncompress packBits compressed image data.
  void _decodePackBits(InputBuffer data, int arraySize, List<int> dst) {
    var srcCount = 0;
    var dstCount = 0;

    while (dstCount < arraySize) {
      final b = uint8ToInt8(data[srcCount++]);
      if (b >= 0 && b <= 127) {
        // literal run packet
        for (var i = 0; i < (b + 1); ++i) {
          dst[dstCount++] = data[srcCount++];
        }
      } else if (b <= -1 && b >= -127) {
        // 2 byte encoded run packet
        final repeat = data[srcCount++];
        for (var i = 0; i < (-b + 1); ++i) {
          dst[dstCount++] = repeat;
        }
      } else {
        // no-op packet. Do nothing
        srcCount++;
      }
    }
  }

  int _readTag(int type, [int defaultValue = 0]) {
    if (!hasTag(type)) {
      return defaultValue;
    }
    return tags[type]!.read()?.toInt() ?? 0;
  }

  List<int>? _readTagList(int type) {
    if (!hasTag(type)) {
      return null;
    }
    final tag = tags[type]!;
    final value = tag.read()!;
    return List<int>.generate(tag.count, value.toInt);
  }
}

enum TiffFormat { invalid, uint, int, float }

enum TiffPhotometricType {
  whiteIsZero, // = 0
  blackIsZero, // = 1
  rgb, // = 2
  palette, // = 3
  transparencyMask, // = 4
  cmyk, // = 5
  yCbCr, // = 6
  reserved7, // = 7
  cieLab, // = 8
  iccLab, // = 9
  ituLab, // = 10
  logL, // = 32844
  logLuv, // = 32845
  colorFilterArray, // = 32803
  linearRaw, // = 34892
  depth, // = 51177
  unknown
}

enum TiffImageType {
  bilevel,
  gray4bit,
  gray,
  grayAlpha,
  palette,
  rgb,
  rgba,
  yCbCrSub,
  generic,
  invalid
}

class TiffCompression {
  static const none = 1;
  static const ccittRle = 2;
  static const ccittFax3 = 3;
  static const ccittFax4 = 4;
  static const lzw = 5;
  static const oldJpeg = 6;
  static const jpeg = 7;
  static const next = 32766;
  static const ccittRlew = 32771;
  static const packBits = 32773;
  static const thunderScan = 32809;
  static const it8ctpad = 32895;
  static const tt8lw = 32896;
  static const it8mp = 32897;
  static const it8bl = 32898;
  static const pixarFilm = 32908;
  static const pixarLog = 32909;
  static const deflate = 32946;
  static const zip = 8;
  static const dcs = 32947;
  static const jbig = 34661;
  static const sgiLog = 34676;
  static const sgiLog24 = 34677;
  static const jp2000 = 34712;

  const TiffCompression(this.value);
  final int value;
}
