import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../color/format.dart';
import '../image/icc_profile.dart';
import '../image/image.dart';
import '../image/palette.dart';
import '../util/neural_quantizer.dart';
import '../util/output_buffer.dart';
import '../util/quantizer.dart';
import 'encoder.dart';
import 'png/png_info.dart';

enum PngFilter { none, sub, up, average, paeth }

/// Encode an image to the PNG format.
class PngEncoder extends Encoder {
  Quantizer? _globalQuantizer;

  PngEncoder({this.filter = PngFilter.paeth, this.level});

  int _numChannels(Image image) => image.hasPalette ? 1 : image.numChannels;

  void addFrame(Image image) {
    // PNG can't encode HDR formats, and can only encode formats with fewer
    // than 8 bits if they have a palette. In the case of incompatible
    // formats, convert them to uint8.
    if ((image.isHdrFormat && image.format != Format.uint16) ||
        (image.bitsPerChannel < 8 &&
            !image.hasPalette &&
            image.numChannels > 1)) {
      image = image.convert(format: Format.uint8);
    }

    if (output == null) {
      output = OutputBuffer(bigEndian: true);

      _writeHeader(image);

      if (image.iccProfile != null) {
        _writeICCPChunk(output, image.iccProfile!);
      }

      if (image.hasPalette) {
        if (_globalQuantizer != null) {
          _writePalette(_globalQuantizer!.palette);
        } else {
          _writePalette(image.palette!);
        }
      }

      if (isAnimated) {
        _writeAnimationControlChunk();
      }
    }

    final nc = _numChannels(image);

    final channelBytes = image.format == Format.uint16 ? 2 : 1;

    // Include room for the filter bytes (1 byte per row).
    final filteredImage = Uint8List(
        (image.width * image.height * nc * channelBytes) + image.height);

    _filter(image, filteredImage);

    final compressed = const ZLibEncoder().encode(filteredImage, level: level);

    if (image.textData != null) {
      for (var key in image.textData!.keys) {
        _writeTextChunk(key, image.textData![key]!);
      }
    }

    if (isAnimated) {
      _writeFrameControlChunk(image);
      sequenceNumber++;
    }

    if (sequenceNumber <= 1) {
      _writeChunk(output!, 'IDAT', compressed);
    } else {
      // fdAT chunk
      final fdat = OutputBuffer(bigEndian: true)
        ..writeUint32(sequenceNumber)
        ..writeBytes(compressed);
      _writeChunk(output!, 'fdAT', fdat.getBytes());

      sequenceNumber++;
    }
  }

  Uint8List? finish() {
    Uint8List? bytes;

    if (output == null) {
      return bytes;
    }

    _writeChunk(output!, 'IEND', []);

    sequenceNumber = 0;

    bytes = output!.getBytes();
    output = null;
    return bytes;
  }

  /// Does this encoder support animation?
  @override
  bool get supportsAnimation => true;

  /// Encode [image] to the PNG format.
  @override
  Uint8List encode(Image image, {bool singleFrame = false}) {
    if (!image.hasAnimation || singleFrame) {
      isAnimated = false;
      addFrame(image);
    } else {
      isAnimated = true;
      _frames = image.frames.length;
      repeat = image.loopCount;

      if (image.hasPalette) {
        final q = NeuralQuantizer(image);
        _globalQuantizer = q;
        for (final frame in image.frames) {
          if (frame != image) {
            q.addImage(frame);
          }
        }
      }

      for (final frame in image.frames) {
        if (_globalQuantizer != null) {
          final newImage = _globalQuantizer!.getIndexImage(frame);
          addFrame(newImage);
        } else {
          addFrame(frame);
        }
      }
    }
    return finish()!;
  }

  void _writeHeader(Image image) {
    // PNG file signature
    output!.writeBytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

    // IHDR chunk
    final chunk = OutputBuffer(bigEndian: true)
      ..writeUint32(image.width) // width
      ..writeUint32(image.height) // height
      ..writeByte(image.bitsPerChannel) // bit depth
      ..writeByte(image.hasPalette
          ? PngColorType.indexed
          : image.numChannels == 1
              ? PngColorType.grayscale
              : image.numChannels == 2
                  ? PngColorType.grayscaleAlpha
                  : image.numChannels == 3
                      ? PngColorType.rgb
                      : PngColorType.rgba)
      ..writeByte(0) // compression method: 0:deflate
      ..writeByte(0) // filter method: 0:adaptive
      ..writeByte(0); // interlace method: 0:no interlace
    _writeChunk(output!, 'IHDR', chunk.getBytes());
  }

  void _writeAnimationControlChunk() {
    final chunk = OutputBuffer(bigEndian: true)
      ..writeUint32(_frames) // number of frames
      ..writeUint32(repeat); // loop count
    _writeChunk(output!, 'acTL', chunk.getBytes());
  }

  void _writeFrameControlChunk(Image image) {
    final chunk = OutputBuffer(bigEndian: true)
      ..writeUint32(sequenceNumber)
      ..writeUint32(image.width)
      ..writeUint32(image.height)
      ..writeUint32(0) // xOffset
      ..writeUint32(0) // yOffset
      ..writeUint16(image.frameDuration)
      ..writeUint16(1000) // delay denominator
      ..writeByte(1) // dispose method 0: APNG_DISPOSE_OP_NONE
      ..writeByte(0); // blend method 0: APNG_BLEND_OP_SOURCE
    _writeChunk(output!, 'fcTL', chunk.getBytes());
  }

  void _writeTextChunk(String keyword, String text) {
    final chunk = OutputBuffer(bigEndian: true)
      ..writeBytes(latin1.encode(keyword))
      ..writeByte(0)
      ..writeBytes(latin1.encode(text));
    _writeChunk(output!, 'tEXt', chunk.getBytes());
  }

  void _writePalette(Palette palette) {
    if (palette.format == Format.uint8 &&
        palette.numChannels == 3 &&
        palette.numColors == 256) {
      _writeChunk(output!, 'PLTE', palette.toUint8List());
    } else {
      final chunk = OutputBuffer(size: palette.numColors * 3, bigEndian: true);
      final nc = palette.numColors;
      for (var i = 0; i < nc; ++i) {
        chunk
          ..writeByte(palette.getRed(i).toInt())
          ..writeByte(palette.getGreen(i).toInt())
          ..writeByte(palette.getBlue(i).toInt());
      }
      _writeChunk(output!, 'PLTE', chunk.getBytes());
    }

    if (palette.numChannels == 4) {
      final chunk = OutputBuffer(size: palette.numColors, bigEndian: true);
      final nc = palette.numColors;
      for (var i = 0; i < nc; ++i) {
        final a = palette.getAlpha(i).toInt();
        chunk.writeByte(a);
      }
      _writeChunk(output!, 'tRNS', chunk.getBytes());
    }
  }

  void _writeICCPChunk(OutputBuffer? out, IccProfile iccp) {
    final chunk = OutputBuffer(bigEndian: true)

      // name
      ..writeBytes(iccp.name.codeUnits)
      ..writeByte(0)

      // compression
      ..writeByte(0) // 0 - deflate

      // profile data
      ..writeBytes(iccp.compressed());

    _writeChunk(output!, 'iCCP', chunk.getBytes());
  }

  void _writeChunk(OutputBuffer out, String type, List<int> chunk) {
    out
      ..writeUint32(chunk.length)
      ..writeBytes(type.codeUnits)
      ..writeBytes(chunk);
    final crc = _crc(type, chunk);
    out.writeUint32(crc);
  }

  void _filter(Image image, Uint8List out) {
    var oi = 0;
    final filter = image.hasPalette ? PngFilter.none : this.filter;
    final buffer = image.buffer;
    final rowStride = image.data!.rowStride;
    final nc = _numChannels(image);
    final bpp = ((nc * image.bitsPerChannel) + 7) >> 3;
    final bpc = (image.bitsPerChannel + 7) >> 3;

    var rowOffset = 0;
    Uint8List? prevRow;
    for (var y = 0; y < image.height; ++y) {
      final rowBytes = Uint8List.view(buffer, rowOffset, rowStride);
      rowOffset += rowStride;

      switch (filter) {
        case PngFilter.sub:
          oi = _filterSub(rowBytes, bpc, bpp, out, oi);
          break;
        case PngFilter.up:
          oi = _filterUp(rowBytes, prevRow, bpc, out, oi);
          break;
        case PngFilter.average:
          oi = _filterAverage(rowBytes, prevRow, bpc, bpp, out, oi);
          break;
        case PngFilter.paeth:
          oi = _filterPaeth(rowBytes, prevRow, bpc, bpp, out, oi);
          break;
        default:
          oi = _filterNone(rowBytes, bpc, out, oi);
          break;
      }
      prevRow = rowBytes;
    }
  }

  int _write(int bpc, Uint8List row, int ri, Uint8List out, int oi) {
    bpc--;
    while (bpc >= 0) {
      out[oi++] = row[ri + bpc];
      bpc--;
    }
    return oi;
  }

  int _filterNone(Uint8List rowBytes, int bpc, Uint8List out, int oi) {
    out[oi++] = PngFilter.none.index;
    if (bpc == 1) {
      final l = rowBytes.length;
      for (int i = 0; i < l; ++i) {
        out[oi++] = rowBytes[i];
      }
    } else {
      final l = rowBytes.length;
      for (int i = 0; i < l; i += bpc) {
        oi = _write(bpc, rowBytes, i, out, oi);
      }
    }
    return oi;
  }

  int _filterSub(Uint8List row, int bpc, int bpp, Uint8List out, int oi) {
    out[oi++] = PngFilter.sub.index;
    for (var x = 0; x < bpp; x += bpc) {
      oi = _write(bpc, row, x, out, oi);
    }
    final l = row.length;
    for (var x = bpp; x < l; x += bpc) {
      for (int c = 0, c2 = bpc - 1; c < bpc; ++c, --c2) {
        out[oi++] = (row[x + c2] - row[(x + c2) - bpp]) & 0xff;
      }
    }
    return oi;
  }

  int _filterUp(
      Uint8List row, Uint8List? prevRow, int bpc, Uint8List out, int oi) {
    out[oi++] = PngFilter.up.index;
    final l = row.length;
    for (var x = 0; x < l; x += bpc) {
      for (int c = 0, c2 = bpc - 1; c < bpc; ++c, --c2) {
        final b = prevRow != null ? prevRow[x + c2] : 0;
        out[oi++] = (row[x + c2] - b) & 0xff;
      }
    }
    return oi;
  }

  int _filterAverage(Uint8List row, Uint8List? prevRow, int bpc, int bpp,
      Uint8List out, int oi) {
    out[oi++] = PngFilter.average.index;
    final l = row.length;
    for (var x = 0; x < l; x += bpc) {
      for (int c = 0, c2 = bpc - 1; c < bpc; ++c, --c2) {
        final x2 = x + c2;
        final p1 = x2 < bpp ? 0 : row[x2 - bpp];
        final p2 = prevRow == null ? 0 : prevRow[x2];
        final p3 = row[x2];
        out[oi++] = p3 - ((p1 + p2) >> 1);
      }
    }
    return oi;
  }

  int _paethPredictor(int a, int b, int c) {
    final p = a + b - c;
    final pa = (p > a) ? p - a : a - p;
    final pb = (p > b) ? p - b : b - p;
    final pc = (p > c) ? p - c : c - p;
    if (pa <= pb && pa <= pc) {
      return a;
    } else if (pb <= pc) {
      return b;
    }
    return c;
  }

  int _filterPaeth(Uint8List row, Uint8List? prevRow, int bpc, int bpp,
      Uint8List out, int oi) {
    out[oi++] = PngFilter.paeth.index;
    final l = row.length;
    for (var x = 0; x < l; x += bpc) {
      for (int c = 0, c2 = bpc - 1; c < bpc; ++c, --c2) {
        final x2 = x + c2;
        final p0 = x2 < bpp ? 0 : row[x2 - bpp];
        final p1 = prevRow == null ? 0 : prevRow[x2];
        final p2 = x2 < bpp || prevRow == null ? 0 : prevRow[x2 - bpp];
        final p = row[x2];
        final pi = _paethPredictor(p0, p1, p2);
        out[oi++] = (p - pi) & 0xff;
      }
    }
    return oi;
  }

  // Return the CRC of the bytes
  int _crc(String type, List<int> bytes) {
    final crc = getCrc32(type.codeUnits);
    return getCrc32(bytes, crc);
  }

  PngFilter filter;
  int repeat = 0;
  int? level;
  late int _frames;
  int sequenceNumber = 0;
  bool isAnimated = false;
  OutputBuffer? output;
  Map<String, String>? textData;
}
