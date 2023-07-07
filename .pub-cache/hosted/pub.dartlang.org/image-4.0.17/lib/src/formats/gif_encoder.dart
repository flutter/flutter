import 'dart:typed_data';

import '../filter/dither_image.dart';
import '../image/image.dart';
import '../util/image_exception.dart';
import '../util/neural_quantizer.dart';
import '../util/octree_quantizer.dart';
import '../util/output_buffer.dart';
import '../util/quantizer.dart';
import 'encoder.dart';

class GifEncoder extends Encoder {
  int delay;
  int repeat;
  int numColors;
  QuantizerType quantizerType;
  int samplingFactor;
  DitherKernel dither;
  bool ditherSerpentine;

  GifEncoder(
      {this.delay = 80,
      this.repeat = 0,
      this.numColors = 256,
      this.quantizerType = QuantizerType.neural,
      this.samplingFactor = 10,
      this.dither = DitherKernel.floydSteinberg,
      this.ditherSerpentine = false})
      : _encodedFrames = 0;

  /// This adds the frame passed to [image].
  /// After the last frame has been added, [finish] is required to be called.
  /// Optional frame [duration] is in 1/100 sec.
  void addFrame(Image image, {int? duration}) {
    if (output == null) {
      output = OutputBuffer();

      if (!image.hasPalette) {
        if (quantizerType == QuantizerType.neural) {
          _lastColorMap = NeuralQuantizer(image,
              numberOfColors: numColors, samplingFactor: samplingFactor);
        } else {
          _lastColorMap = OctreeQuantizer(image, numberOfColors: numColors);
        }

        _lastImage = ditherImage(image,
            quantizer: _lastColorMap!,
            kernel: dither,
            serpentine: ditherSerpentine);
      } else {
        _lastImage = image;
      }

      _lastImageDuration = duration;
      _width = image.width;
      _height = image.height;
      return;
    }

    if (_encodedFrames == 0) {
      _writeHeader(_width, _height);
      _writeApplicationExt();
    }

    _writeGraphicsCtrlExt(_lastImage!);

    _addImage(_lastImage!, _width, _height);
    _encodedFrames++;

    if (!image.hasPalette) {
      if (quantizerType == QuantizerType.neural) {
        _lastColorMap = NeuralQuantizer(image,
            numberOfColors: numColors, samplingFactor: samplingFactor);
      } else {
        _lastColorMap = OctreeQuantizer(image, numberOfColors: numColors);
      }

      _lastImage = ditherImage(image,
          quantizer: _lastColorMap!,
          kernel: dither,
          serpentine: ditherSerpentine);
    } else {
      _lastImage = image;
    }

    _lastImageDuration = duration;
  }

  /// Encode the images that were added with [addFrame].
  /// After this has been called (returning the finishes GIF),
  /// calling [addFrame] for a new animation or image is safe again.
  ///
  /// [addFrame] will not encode the first image passed and after that
  /// always encode the previous image. Hence, the last image needs to be
  /// encoded here.
  Uint8List? finish() {
    Uint8List? bytes;
    if (output == null) {
      return bytes;
    }

    if (_encodedFrames == 0) {
      _writeHeader(_width, _height);
      _writeApplicationExt();
    }
    _writeGraphicsCtrlExt(_lastImage!);

    _addImage(_lastImage!, _width, _height);

    output!.writeByte(_terminateRecordType);

    _lastImage = null;
    _lastColorMap = null;
    _encodedFrames = 0;

    bytes = output!.getBytes();
    output = null;
    return bytes;
  }

  /// Encode a single frame image.
  @override
  Uint8List encode(Image image, {bool singleFrame = false}) {
    if (!image.hasAnimation || singleFrame) {
      addFrame(image);
      return finish()!;
    }

    repeat = image.loopCount;
    for (var f in image.frames) {
      // Convert ms to 1/100 sec.
      addFrame(f, duration: f.frameDuration ~/ 10);
    }
    return finish()!;
  }

  /// Does this encoder support animation?
  @override
  bool get supportsAnimation => true;

  void _addImage(Image image, int width, int height) {
    if (!image.hasPalette) {
      throw ImageException('GIF can only encode palette images.');
    }

    final palette = image.palette!;
    final numColors = palette.numColors;

    final out = output!

      // Image desc
      ..writeByte(_imageDescRecordType)
      ..writeUint16(0) // image position x,y = 0,0
      ..writeUint16(0)
      ..writeUint16(width) // image size
      ..writeUint16(height);

    final paletteBytes = palette.toUint8List();

    // Local Color Map
    // (0x80: Use LCM, 0x07: Palette Size (7 = 8-bit))
    out.writeByte(0x87);

    final numChannels = palette.numChannels;
    if (numChannels == 3) {
      out.writeBytes(paletteBytes);
    } else if (numChannels == 4) {
      for (var i = 0, pi = 0; i < numColors; ++i, pi += 4) {
        out
          ..writeByte(paletteBytes[pi])
          ..writeByte(paletteBytes[pi + 1])
          ..writeByte(paletteBytes[pi + 2]);
      }
    } else if (numChannels == 1 || numChannels == 2) {
      for (var i = 0, pi = 0; i < numColors; ++i, pi += numChannels) {
        final g = paletteBytes[pi];
        out
          ..writeByte(g)
          ..writeByte(g)
          ..writeByte(g);
      }
    }

    for (var i = numColors; i < 256; ++i) {
      out
        ..writeByte(0)
        ..writeByte(0)
        ..writeByte(0);
    }

    _encodeLZW(image, width, height);
  }

  void _encodeLZW(Image image, int width, int height) {
    _curAccum = 0;
    _curBits = 0;
    _blockSize = 0;
    _block = Uint8List(256);

    const initCodeSize = 8;
    output!.writeByte(initCodeSize);

    final hTab = Int32List(_hSize);
    final codeTab = Int32List(_hSize);
    final pIter = image.iterator..moveNext();

    _initBits = initCodeSize + 1;
    _nBits = _initBits;
    _maxCode = (1 << _nBits) - 1;
    _clearCode = 1 << (_initBits - 1);
    _eofCode = _clearCode + 1;
    _clearFlag = false;
    _freeEnt = _clearCode + 2;
    var pFinished = false;

    int nextPixel() {
      if (pFinished) {
        return _eof;
      }
      final r = pIter.current.index as int;
      if (!pIter.moveNext()) {
        pFinished = true;
      }
      return r;
    }

    var ent = nextPixel();

    var hShift = 0;
    for (var fCode = _hSize; fCode < 65536; fCode *= 2) {
      hShift++;
    }
    hShift = 8 - hShift;

    const hSizeReg = _hSize;
    for (var i = 0; i < hSizeReg; ++i) {
      hTab[i] = -1;
    }

    _output(_clearCode);

    var outerLoop = true;
    while (outerLoop) {
      outerLoop = false;

      var c = nextPixel();
      while (c != _eof) {
        final fcode = (c << _bits) + ent;
        var i = (c << hShift) ^ ent; // xor hashing

        if (hTab[i] == fcode) {
          ent = codeTab[i];
          c = nextPixel();
          continue;
        } else if (hTab[i] >= 0) {
          // non-empty slot
          var disp = hSizeReg - i; // secondary hash (after G. Knott)
          if (i == 0) {
            disp = 1;
          }
          do {
            if ((i -= disp) < 0) {
              i += hSizeReg;
            }

            if (hTab[i] == fcode) {
              ent = codeTab[i];
              outerLoop = true;
              break;
            }
          } while (hTab[i] >= 0);
          if (outerLoop) {
            break;
          }
        }

        _output(ent);
        ent = c;

        if (_freeEnt < (1 << _bits)) {
          codeTab[i] = _freeEnt++; // code -> hashtable
          hTab[i] = fcode;
        } else {
          for (var i = 0; i < _hSize; ++i) {
            hTab[i] = -1;
          }
          _freeEnt = _clearCode + 2;
          _clearFlag = true;
          _output(_clearCode);
        }

        c = nextPixel();
      }
    }

    _output(ent);
    _output(_eofCode);

    output!.writeByte(0);
  }

  void _output(int? code) {
    _curAccum &= _masks[_curBits];

    if (_curBits > 0) {
      _curAccum |= code! << _curBits;
    } else {
      _curAccum = code!;
    }

    _curBits += _nBits;

    while (_curBits >= 8) {
      _addToBlock(_curAccum & 0xff);
      _curAccum >>= 8;
      _curBits -= 8;
    }

    // If the next entry is going to be too big for the code size,
    // then increase it, if possible.
    if (_freeEnt > _maxCode || _clearFlag) {
      if (_clearFlag) {
        _nBits = _initBits;
        _maxCode = (1 << _nBits) - 1;
        _clearFlag = false;
      } else {
        ++_nBits;
        if (_nBits == _bits) {
          _maxCode = 1 << _bits;
        } else {
          _maxCode = (1 << _nBits) - 1;
        }
      }
    }

    if (code == _eofCode) {
      // At EOF, write the rest of the buffer.
      while (_curBits > 0) {
        _addToBlock(_curAccum & 0xff);
        _curAccum >>= 8;
        _curBits -= 8;
      }
      _writeBlock();
    }
  }

  void _writeBlock() {
    if (_blockSize > 0) {
      output!.writeByte(_blockSize);
      output!.writeBytes(_block, _blockSize);
      _blockSize = 0;
    }
  }

  void _addToBlock(int c) {
    _block[_blockSize++] = c;
    if (_blockSize >= 254) {
      _writeBlock();
    }
  }

  void _writeApplicationExt() {
    output!.writeByte(_extensionRecordType);
    output!.writeByte(_applicationExt);
    output!.writeByte(11); // data block size
    output!.writeBytes('NETSCAPE2.0'.codeUnits); // app identifier
    output!.writeBytes([0x03, 0x01]);
    output!.writeUint16(repeat); // loop count
    output!.writeByte(0); // block terminator
  }

  void _writeGraphicsCtrlExt(Image image) {
    output!.writeByte(_extensionRecordType);
    output!.writeByte(_graphicControlExt);
    output!.writeByte(4); // data block size

    var transparentIndex = 0;
    var hasTransparency = 0;
    final palette = image.palette!;
    final nc = palette.numChannels;
    final pa = nc - 1;
    if (nc == 4 || nc == 2) {
      final p = palette.toUint8List();
      final l = palette.numColors;
      for (var i = 0, pi = pa; i < l; ++i, pi += nc) {
        final a = p[pi];
        if (a == 0) {
          hasTransparency = 1;
          transparentIndex = i;
          break;
        }
      }
    }

    const dispose = 2; // dispose: 0 = no action, 2 = clear
    final fields = 0 | // 1:3 reserved
        (dispose << 2) | // 4:6 disposal
        0 | // 7   user input - 0 = none
        hasTransparency; // 8   transparency flag

    // packed fields
    output!.writeByte(fields);

    output!.writeUint16(_lastImageDuration ?? delay); // delay x 1/100 sec
    output!.writeByte(transparentIndex); // transparent color index
    output!.writeByte(0); // block terminator
  }

  // GIF header and Logical Screen Descriptor
  void _writeHeader(int width, int height) {
    output!.writeBytes(_gif89Id.codeUnits);
    output!.writeUint16(width);
    output!.writeUint16(height);
    output!.writeByte(0); // global color map parameters (not being used).
    output!.writeByte(0); // background color index.
    output!.writeByte(0); // aspect
  }

  Image? _lastImage;
  int? _lastImageDuration;
  Quantizer? _lastColorMap;
  late int _width;
  late int _height;
  int _encodedFrames;

  int _curAccum = 0;
  int _curBits = 0;
  int _nBits = 0;
  int _initBits = 0;
  int _eofCode = 0;
  int _maxCode = 0;
  int _clearCode = 0;
  int _freeEnt = 0;
  bool _clearFlag = false;
  late Uint8List _block;
  int _blockSize = 0;

  OutputBuffer? output;

  static const _gif89Id = 'GIF89a';

  static const _imageDescRecordType = 0x2c;
  static const _extensionRecordType = 0x21;
  static const _terminateRecordType = 0x3b;

  static const _applicationExt = 0xff;
  static const _graphicControlExt = 0xf9;

  static const _eof = -1;
  static const _bits = 12;
  static const _hSize = 5003; // 80% occupancy
  static const _masks = [
    0x0000,
    0x0001,
    0x0003,
    0x0007,
    0x000F,
    0x001F,
    0x003F,
    0x007F,
    0x00FF,
    0x01FF,
    0x03FF,
    0x07FF,
    0x0FFF,
    0x1FFF,
    0x3FFF,
    0x7FFF,
    0xFFFF
  ];
}
