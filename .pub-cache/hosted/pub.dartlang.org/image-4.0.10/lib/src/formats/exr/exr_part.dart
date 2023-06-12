import 'dart:math';
import 'dart:typed_data';

import '../../color/format.dart';
import '../../image/image.dart';
import '../../image/image_data.dart';
import '../../image/image_data_float16.dart';
import '../../image/image_data_float32.dart';
import '../../image/image_data_uint32.dart';
import '../../util/_internal.dart';
import '../../util/image_exception.dart';
import '../../util/input_buffer.dart';
import 'exr_attribute.dart';
import 'exr_channel.dart';
import 'exr_compressor.dart';

class ExrPart {
  final int index;

  /// The framebuffer for this exr part.
  Image? framebuffer;

  /// The channels present in this part.
  List<ExrChannel> channels = [];
  int numColorChannels = 0;

  /// The extra attributes read from the part header.
  Map<String, ExrAttribute> attributes = {};

  /// The display window (see the openexr documentation).
  List<int>? displayWindow;

  /// The data window (see the openexr documentation).
  late List<int> dataWindow;

  /// width of the data window
  int width = 0;

  /// Height of the data window
  int height = 0;
  double pixelAspectRatio = 1.0;
  double screenWindowCenterX = 0.0;
  double screenWindowCenterY = 0.0;
  double screenWindowWidth = 1.0;
  late Float32List chromaticities;

  ExrPart(this.index, this._tiled, InputBuffer input) {
    //_type = _tiled ? ExrPart._typeTile : ExrPart._typeScanline;

    var colorFormat = Format.float16;
    final extraChannels = <String, ImageData>{};

    while (true) {
      final name = input.readString();
      if (name.isEmpty) {
        break;
      }

      final type = input.readString();
      final size = input.readUint32();
      final value = input.readBytes(size);

      attributes[name] = ExrAttribute(name, type, size, value);

      switch (name) {
        case 'channels':
          while (true) {
            final channel = ExrChannel(value);
            if (!channel.isValid) {
              break;
            }
            if (channel.isColorChannel) {
              numColorChannels++;
              if (channel.dataType == ExrChannelType.half) {
                colorFormat = Format.float16;
              } else if (channel.dataType == ExrChannelType.float) {
                colorFormat = Format.float32;
              } else {
                colorFormat = Format.uint32;
              }
            } else {
              final name = channel.name;
              if (channel.dataType == ExrChannelType.half) {
                extraChannels[name] = ImageDataFloat16(width, height, 1);
              } else if (channel.dataType == ExrChannelType.float) {
                extraChannels[name] = ImageDataFloat32(width, height, 1);
              } else if (channel.dataType == ExrChannelType.uint) {
                extraChannels[name] = ImageDataUint32(width, height, 1);
              }
            }
            channels.add(channel);
          }
          break;
        case 'chromaticities':
          chromaticities = Float32List(8);
          chromaticities[0] = value.readFloat32();
          chromaticities[1] = value.readFloat32();
          chromaticities[2] = value.readFloat32();
          chromaticities[3] = value.readFloat32();
          chromaticities[4] = value.readFloat32();
          chromaticities[5] = value.readFloat32();
          chromaticities[6] = value.readFloat32();
          chromaticities[7] = value.readFloat32();
          break;
        case 'compression':
          _compressionType = ExrCompressorType.values[value.readByte()];
          break;
        case 'dataWindow':
          dataWindow = [
            value.readInt32(),
            value.readInt32(),
            value.readInt32(),
            value.readInt32()
          ];
          width = (dataWindow[2] - dataWindow[0]) + 1;
          height = (dataWindow[3] - dataWindow[1]) + 1;
          break;
        case 'displayWindow':
          displayWindow = [
            value.readInt32(),
            value.readInt32(),
            value.readInt32(),
            value.readInt32()
          ];
          break;
        case 'lineOrder':
          //_lineOrder = value.readByte();
          break;
        case 'pixelAspectRatio':
          pixelAspectRatio = value.readFloat32();
          break;
        case 'screenWindowCenter':
          screenWindowCenterX = value.readFloat32();
          screenWindowCenterY = value.readFloat32();
          break;
        case 'screenWindowWidth':
          screenWindowWidth = value.readFloat32();
          break;
        case 'tiles':
          _tileWidth = value.readUint32();
          _tileHeight = value.readUint32();
          final mode = value.readByte();
          _tileLevelMode = mode & 0xf;
          _tileRoundingMode = (mode >> 4) & 0xf;
          break;
        case 'type':
          final s = value.readString();
          if (s == 'deepscanline') {
            //this._type = TYPE_DEEP_SCANLINE;
          } else if (s == 'deeptile') {
            //this._type = TYPE_DEEP_TILE;
          } else {
            throw ImageException('EXR Invalid type: $s');
          }
          break;
        default:
          break;
      }
    }

    framebuffer = Image(
        width: width,
        height: height,
        numChannels: numColorChannels,
        format: colorFormat);

    for (var name in extraChannels.keys) {
      framebuffer!.setExtraChannel(name, extraChannels[name]!);
    }

    if (_tiled) {
      _numXLevels = _calculateNumXLevels(left, right, top, bottom);
      _numYLevels = _calculateNumYLevels(left, right, top, bottom);
      if (_tileLevelMode != _ripmapLevels) {
        _numYLevels = 1;
      }

      _numXTiles = _calculateNumTiles(
          _numXLevels!, left, right, _tileWidth, _tileRoundingMode);

      _numYTiles = _calculateNumTiles(
          _numYLevels!, top, bottom, _tileHeight, _tileRoundingMode);

      _bytesPerPixel = _calculateBytesPerPixel();
      _maxBytesPerTileLine = _bytesPerPixel * _tileWidth!;
      //_tileBufferSize = _maxBytesPerTileLine * _tileHeight;

      _compressor = ExrCompressor(
          _compressionType, this, _maxBytesPerTileLine, _tileHeight);

      var lx = 0;
      var ly = 0;
      _offsets = List<Uint32List>.generate(_numXLevels! * _numYLevels!, (l) {
        final result = Uint32List(_numXTiles![lx]! * _numYTiles![ly]!);
        ++lx;
        if (lx == _numXLevels) {
          lx = 0;
          ++ly;
        }
        return result;
      });
    } else {
      _bytesPerLine = Uint32List(height + 1);
      for (var ch in channels) {
        final nBytes = ch.dataSize * width ~/ ch.xSampling;
        for (var y = 0; y < height; ++y) {
          if ((y + top) % ch.ySampling == 0) {
            _bytesPerLine[y] += nBytes;
          }
        }
      }

      var maxBytesPerLine = 0;
      for (var y = 0; y < height; ++y) {
        maxBytesPerLine = max(maxBytesPerLine, _bytesPerLine[y]);
      }

      _compressor = ExrCompressor(_compressionType, this, maxBytesPerLine);

      _linesInBuffer = _compressor!.numScanLines();
      //_lineBufferSize = maxBytesPerLine * _linesInBuffer;

      _offsetInLineBuffer = Uint32List(_bytesPerLine.length);

      var offset = 0;
      for (var i = 0; i <= _bytesPerLine.length - 1; ++i) {
        if (i % _linesInBuffer == 0) {
          offset = 0;
        }
        _offsetInLineBuffer![i] = offset;
        offset += _bytesPerLine[i];
      }

      final numOffsets = ((height + _linesInBuffer) ~/ _linesInBuffer) - 1;
      _offsets = [Uint32List(numOffsets)];
    }
  }

  int get left => dataWindow[0];

  int get top => dataWindow[1];

  int get right => dataWindow[2];

  int get bottom => dataWindow[3];

  /// Was this part successfully decoded?
  bool get isValid => width > 0;

  int _calculateNumXLevels(int minX, int maxX, int minY, int maxY) {
    var num = 0;

    switch (_tileLevelMode) {
      case _oneLevel:
        num = 1;
        break;
      case _mipmapLevels:
        final w = maxX - minX + 1;
        final h = maxY - minY + 1;
        num = _roundLog2(max(w, h), _tileRoundingMode) + 1;
        break;
      case _ripmapLevels:
        final w = maxX - minX + 1;
        num = _roundLog2(w, _tileRoundingMode) + 1;
        break;
      default:
        throw ImageException('Unknown LevelMode format.');
    }

    return num;
  }

  int _calculateNumYLevels(int minX, int maxX, int minY, int maxY) {
    var num = 0;

    switch (_tileLevelMode) {
      case _oneLevel:
        num = 1;
        break;
      case _mipmapLevels:
        final w = (maxX - minX) + 1;
        final h = (maxY - minY) + 1;
        num = _roundLog2(max(w, h), _tileRoundingMode) + 1;
        break;
      case _ripmapLevels:
        final h = (maxY - minY) + 1;
        num = _roundLog2(h, _tileRoundingMode) + 1;
        break;
      default:
        throw ImageException('Unknown LevelMode format.');
    }

    return num;
  }

  int _roundLog2(int x, int? rmode) =>
      (rmode == _roundDown) ? _floorLog2(x) : _ceilLog2(x);

  int _floorLog2(int x) {
    var y = 0;

    while (x > 1) {
      y += 1;
      x >>= 1;
    }

    return y;
  }

  int _ceilLog2(int x) {
    var y = 0;
    var r = 0;

    while (x > 1) {
      if (x & 1 != 0) {
        r = 1;
      }

      y += 1;
      x >>= 1;
    }

    return y + r;
  }

  int _calculateBytesPerPixel() {
    var bytesPerPixel = 0;

    for (var ch in channels) {
      bytesPerPixel += ch.dataSize;
    }

    return bytesPerPixel;
  }

  List<int> _calculateNumTiles(
          int numLevels, int min, int max, int? size, int? rmode) =>
      List<int>.generate(numLevels,
          (i) => (_levelSize(min, max, i, rmode) + size! - 1) ~/ size,
          growable: false);

  int _levelSize(int mn, int mx, int l, int? rmode) {
    if (l < 0) {
      throw ImageException('Argument not in valid range.');
    }

    final a = (mx - mn) + 1;
    final b = 1 << l;
    var size = a ~/ b;

    if (rmode == _roundUp && size * b < a) {
      size += 1;
    }

    return max(size, 1);
  }

  //static const _typeScanline = 0;
  //static const _typeTile = 1;
  //static const _typeDeepScanline = 2;
  //static const _typeDeepTile = 3;

  //static const _increasingY = 0;
  //static const _decreasingY = 1;
  //static const _randomY = 2;

  static const _oneLevel = 0;
  static const _mipmapLevels = 1;
  static const _ripmapLevels = 2;

  static const _roundDown = 0;
  static const _roundUp = 1;

  //int _type;
  //int _lineOrder = _increasingY;
  ExrCompressorType _compressionType = ExrCompressorType.none;
  List<Uint32List?>? _offsets;

  late Uint32List _bytesPerLine;
  ExrCompressor? _compressor;
  int _linesInBuffer = 0;

  //int _lineBufferSize;
  Uint32List? _offsetInLineBuffer;

  final bool _tiled;
  int? _tileWidth;
  int? _tileHeight;
  int? _tileLevelMode;
  int? _tileRoundingMode;
  List<int?>? _numXTiles;
  List<int?>? _numYTiles;
  int? _numXLevels;
  int? _numYLevels;
  late int _bytesPerPixel;
  int? _maxBytesPerTileLine;
  //int _tileBufferSize;
}

@internal
class InternalExrPart extends ExrPart {
  InternalExrPart(int index, bool tiled, InputBuffer input)
      : super(index, tiled, input);

  List<Uint32List?>? get offsets => _offsets;

  ExrCompressor? get compressor => _compressor;

  int get linesInBuffer => _linesInBuffer;

  Uint32List? get offsetInLineBuffer => _offsetInLineBuffer;

  bool get tiled => _tiled;

  int? get tileWidth => _tileWidth;

  int? get tileHeight => _tileHeight;

  List<int?>? get numXTiles => _numXTiles;

  List<int?>? get numYTiles => _numYTiles;

  int? get numXLevels => _numXLevels;

  int? get numYLevels => _numYLevels;

  void readOffsets(InputBuffer input) {
    if (_tiled) {
      for (var i = 0; i < _offsets!.length; ++i) {
        for (var j = 0; j < _offsets![i]!.length; ++j) {
          _offsets![i]![j] = input.readUint64();
        }
      }
    } else {
      final numOffsets = _offsets![0]!.length;
      for (var i = 0; i < numOffsets; ++i) {
        _offsets![0]![i] = input.readUint64();
      }
    }
  }
}
