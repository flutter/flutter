import 'dart:math';
import 'dart:typed_data';

import '../../color/color.dart';
import '../../util/float16.dart';
import '../../util/image_exception.dart';
import '../../util/input_buffer.dart';
import '../decode_info.dart';
import 'exr_channel.dart';
import 'exr_part.dart';

class ExrImage implements DecodeInfo {
  @override
  int width = 0;
  @override
  int height = 0;

  /// An EXR image has one or more parts, each of which contains a framebuffer.
  final List<ExrPart> _parts = [];

  ExrImage(Uint8List bytes) {
    final input = InputBuffer(bytes);
    final magic = input.readUint32();
    if (magic != signature) {
      throw ImageException('File is not an OpenEXR image file.');
    }

    version = input.readByte();
    if (version != exrVersion) {
      throw ImageException('Cannot read version $version image files.');
    }

    flags = input.readUint24();
    if (!_supportsFlags(flags)) {
      throw ImageException('The file format version number\'s flag field '
          'contains unrecognized flags.');
    }

    if (!_isMultiPart) {
      final ExrPart part = InternalExrPart(_parts.length, _isTiled, input);
      if (part.isValid) {
        _parts.add(part as InternalExrPart);
      }
    } else {
      while (true) {
        final ExrPart part = InternalExrPart(_parts.length, _isTiled, input);
        if (!part.isValid) {
          break;
        }
        _parts.add(part as InternalExrPart);
      }
    }

    if (_parts.isEmpty) {
      throw ImageException('Error reading image header');
    }

    for (final part in _parts) {
      (part as InternalExrPart).readOffsets(input);
    }

    _readImage(input);
  }

  @override
  Color? get backgroundColor => null;

  List<ExrPart> get parts => _parts;

  @override
  int get numFrames => 1;

  /// Parse just enough of the file to identify that it's an EXR image.
  static bool isValidFile(List<int> bytes) {
    final input = InputBuffer(bytes);

    final magic = input.readUint32();
    if (magic != signature) {
      return false;
    }

    final version = input.readByte();
    if (version != exrVersion) {
      return false;
    }

    final flags = input.readUint24();
    if (!_supportsFlags(flags)) {
      return false;
    }

    return true;
  }

  ExrPart getPart(int i) => _parts[i];

  int get numParts => _parts.length;

  bool get _isTiled => (flags & tiledFlag) != 0;

  bool get _isMultiPart => flags & multiPartFileFlag != 0;

  //bool get _isNonImage => flags & nonImageFlag != 0;

  static bool _supportsFlags(int flags) => (flags & ~allFlags) == 0;

  void _readImage(InputBuffer input) {
    //final bool multiPart = _isMultiPart();
    for (final part in _parts) {
      final p = part as InternalExrPart;
      width = max(width, part.width);
      height = max(height, part.height);
      if (p.tiled) {
        _readTiledPart(p, input);
      } else {
        _readScanlinePart(p, input);
      }
    }
  }

  void _readTiledPart(InternalExrPart part, InputBuffer input) {
    final multiPart = _isMultiPart;
    final framebuffer = part.framebuffer!;
    final compressor = part.compressor;
    final offsets = part.offsets;
    //Uint32List fbi = Uint32List(part.channels.length);

    final imgData = InputBuffer.from(input);
    for (var ly = 0, l = 0; ly < part.numYLevels!; ++ly) {
      for (var lx = 0; lx < part.numXLevels!; ++lx, ++l) {
        for (var ty = 0, oi = 0; ty < part.numYTiles![ly]!; ++ty) {
          for (var tx = 0; tx < part.numXTiles![lx]!; ++tx, ++oi) {
            // TODO support sub-levels (for rip/mip-mapping).
            if (l != 0) {
              break;
            }
            final offset = offsets![l]![oi];
            imgData.offset = offset;

            if (multiPart) {
              final p = imgData.readUint32();
              if (p != part.index) {
                throw ImageException('Invalid Image Data');
              }
            }

            final tileX = imgData.readUint32();
            final tileY = imgData.readUint32();
            imgData
              ..readUint32() // levelX
              ..readUint32(); // levelY
            final dataSize = imgData.readUint32();
            final data = imgData.readBytes(dataSize);

            var ty = tileY * part.tileHeight!;
            final tx = tileX * part.tileWidth!;

            var tileWidth = compressor!.decodedWidth;
            var tileHeight = compressor.decodedHeight;

            if (tx + tileWidth > width) {
              tileWidth = width - tx;
            }
            if (ty + tileHeight > height) {
              tileHeight = height - ty;
            }

            final uncompressedData = InputBuffer(compressor.uncompress(
                data, tx, ty, part.tileWidth, part.tileHeight));
            tileWidth = compressor.decodedWidth;
            tileHeight = compressor.decodedHeight;

            var si = 0;
            final len = uncompressedData.length;
            final numChannels = part.channels.length;
            for (var yi = 0; yi < tileHeight && ty < height; ++yi, ++ty) {
              for (var ci = 0; ci < numChannels; ++ci) {
                if (si >= len) {
                  break;
                }

                final ch = part.channels[ci];

                var tx = tileX * part.tileWidth!;
                for (var xx = 0; xx < tileWidth; ++xx, ++tx) {
                  num v;
                  switch (ch.dataType) {
                    case ExrChannelType.half:
                      v = Float16.float16ToDouble(
                          uncompressedData.readUint16());
                      break;
                    case ExrChannelType.float:
                      v = uncompressedData.readUint16();
                      break;
                    case ExrChannelType.uint:
                      v = uncompressedData.readUint32();
                      break;
                  }
                  si += ch.dataSize;
                  if (ch.isColorChannel) {
                    final p = framebuffer.getPixel(tx, ty);
                    p[ch.nameType.index] = v;
                  } else {
                    final slice = framebuffer.getExtraChannel(ch.name);
                    slice?.setPixelRgb(tx, ty, v, 0, 0);
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  void _readScanlinePart(InternalExrPart part, InputBuffer input) {
    final multiPart = _isMultiPart;
    final framebuffer = part.framebuffer!;
    final compressor = part.compressor;
    final offsets = part.offsets![0]!;

    //var scanLineMin = part.top;
    //var scanLineMax = part.bottom;
    final linesInBuffer = part.linesInBuffer;

    //var minY = part.top;
    //var maxY = minY + part.linesInBuffer - 1;

    //final fbi = Uint32List(part.channels.length);
    //var total = 0;

    //var xx = 0;
    var yy = 0;

    final imgData = InputBuffer.from(input);
    for (var offset in offsets) {
      imgData.offset = offset;

      if (multiPart) {
        final p = imgData.readUint32();
        if (p != pi) {
          throw ImageException('Invalid Image Data');
        }
      }

      imgData.readInt32(); // y
      final dataSize = imgData.readInt32();
      final data = imgData.readBytes(dataSize);

      InputBuffer uncompressedData;
      if (compressor != null) {
        uncompressedData = InputBuffer(compressor.uncompress(data, 0, yy));
      } else {
        uncompressedData = data;
      }

      var si = 0;
      final len = uncompressedData.length;
      final numChannels = part.channels.length;
      for (var yi = 0; yi < linesInBuffer && yy < height; ++yi, ++yy) {
        si = part.offsetInLineBuffer![yy];
        if (si >= len) {
          break;
        }

        for (var ci = 0; ci < numChannels; ++ci) {
          if (si >= len) {
            break;
          }

          final ch = part.channels[ci];
          final pw = part.width;
          for (var xx = 0; xx < pw; ++xx) {
            num v;
            switch (ch.dataType) {
              case ExrChannelType.half:
                v = Float16.float16ToDouble(uncompressedData.readUint16());
                break;
              case ExrChannelType.float:
                v = uncompressedData.readUint16();
                break;
              case ExrChannelType.uint:
                v = uncompressedData.readUint32();
                break;
            }
            si += ch.dataSize;

            if (ch.isColorChannel) {
              final p = framebuffer.getPixel(xx, yy);
              final ci = ch.nameType.index;
              p[ci] = v;
            } else {
              final slice = framebuffer.getExtraChannel(ch.name);
              slice?.setPixelRgb(xx, yy, v, 0, 0);
            }
          }
        }
      }
    }
  }

  int? version;
  late int flags;

  /// The signature number is stored in the first four bytes of every
  /// OpenEXR image file. This can be used to quickly test whether
  /// a given file is an OpenEXR image file (see isImfMagic(), below).
  static const signature = 20000630;

  /// Value that goes into VERSION_NUMBER_FIELD.
  static const exrVersion = 2;

  /// File is tiled
  static const tiledFlag = 0x000002;

  /// File contains long attribute or channel names
  static const longNamesFlag = 0x000004;

  /// File has at least one part which is not a regular scanline image or
  /// regular tiled image (that is, it is a deep format).
  static const nonImageFlag = 0x000008;

  /// File has multiple parts.
  static const multiPartFileFlag = 0x000010;

  /// Bitwise OR of all supported flags.
  static const allFlags = tiledFlag | longNamesFlag;
}
