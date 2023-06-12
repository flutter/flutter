import 'dart:typed_data';

import '../animation.dart';
import '../image.dart';
import '../util/dither_pixels.dart';
import '../util/neural_quantizer.dart';
import '../util/output_buffer.dart';
import 'encoder.dart';

class GifEncoder extends Encoder {
  int delay, repeat, samplingFactor;
  DitherKernel dither;
  bool ditherSerpentine;

  GifEncoder(
      {this.delay = 80,
      this.repeat = 0,
      this.samplingFactor = 10,
      this.dither = DitherKernel.FloydSteinberg,
      this.ditherSerpentine = false})
      : _encodedFrames = 0;

  /// This adds the frame passed to [image].
  /// After the last frame has been added, [finish] is required to be called.
  /// Optional frame [duration] is in 1/100 sec.
  void addFrame(Image image, {int? duration}) {
    if (output == null) {
      output = OutputBuffer();

      _lastColorMap = NeuralQuantizer(image, samplingFactor: samplingFactor);
      _lastImage =
          ditherPixels(image, _lastColorMap!, dither, ditherSerpentine);
      _lastImageDuration = duration;

      _width = image.width;
      _height = image.height;
      return;
    }

    if (_encodedFrames == 0) {
      _writeHeader(_width, _height);
      _writeApplicationExt();
    }

    _writeGraphicsCtrlExt();

    _addImage(_lastImage, _width, _height, _lastColorMap!.colorMap, 256);
    _encodedFrames++;

    _lastColorMap = NeuralQuantizer(image, samplingFactor: samplingFactor);
    _lastImage = ditherPixels(image, _lastColorMap!, dither, ditherSerpentine);
    _lastImageDuration = duration;
  }

  /// Encode the images that were added with [addFrame].
  /// After this has been called (returning the finishes GIF),
  /// calling [addFrame] for a new animation or image is safe again.
  ///
  /// [addFrame] will not encode the first image passed and after that
  /// always encode the previous image. Hence, the last image needs to be
  /// encoded here.
  List<int>? finish() {
    List<int>? bytes;
    if (output == null) {
      return bytes;
    }

    if (_encodedFrames == 0) {
      _writeHeader(_width, _height);
      _writeApplicationExt();
    } else {
      _writeGraphicsCtrlExt();
    }

    _addImage(_lastImage, _width, _height, _lastColorMap!.colorMap, 256);

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
  List<int> encodeImage(Image image) {
    addFrame(image);
    return finish()!;
  }

  /// Does this encoder support animation?
  @override
  bool get supportsAnimation => true;

  /// Encode an animation.
  @override
  List<int>? encodeAnimation(Animation anim) {
    repeat = anim.loopCount;
    for (var f in anim) {
      addFrame(
        f,
        duration: f.duration ~/ 10, // Convert ms to 1/100 sec.
      );
    }
    return finish();
  }

  void _addImage(Uint8List? image, int width, int height, Uint8List colorMap,
      int numColors) {
    // Image desc
    output!.writeByte(_imageDescRecordType);
    output!.writeUint16(0); // image position x,y = 0,0
    output!.writeUint16(0);
    output!.writeUint16(width); // image size
    output!.writeUint16(height);

    // Local Color Map
    // (0x80: Use LCM, 0x07: Palette Size (7 = 8-bit))
    output!.writeByte(0x87);
    output!.writeBytes(colorMap);
    for (var i = numColors; i < 256; ++i) {
      output!.writeByte(0);
      output!.writeByte(0);
      output!.writeByte(0);
    }

    _encodeLZW(image, width, height);
  }

  void _encodeLZW(Uint8List? image, int width, int height) {
    _curAccum = 0;
    _curBits = 0;
    _blockSize = 0;
    _block = Uint8List(256);

    const initCodeSize = 8;
    output!.writeByte(initCodeSize);

    final hTab = Int32List(_hsize);
    final codeTab = Int32List(_hsize);
    var remaining = width * height;
    var curPixel = 0;

    _initBits = initCodeSize + 1;
    _nBits = _initBits;
    _maxCode = (1 << _nBits) - 1;
    _clearCode = 1 << (_initBits - 1);
    _EOFCode = _clearCode + 1;
    _clearFlag = false;
    _freeEnt = _clearCode + 2;

    int _nextPixel() {
      if (remaining == 0) {
        return _eof;
      }
      --remaining;
      return image![curPixel++] & 0xff;
    }

    var ent = _nextPixel();

    var hshift = 0;
    for (var fcode = _hsize; fcode < 65536; fcode *= 2) {
      hshift++;
    }
    hshift = 8 - hshift;

    const hSizeReg = _hsize;
    for (var i = 0; i < hSizeReg; ++i) {
      hTab[i] = -1;
    }

    _output(_clearCode);

    var outerLoop = true;
    while (outerLoop) {
      outerLoop = false;

      var c = _nextPixel();
      while (c != _eof) {
        final fcode = (c << _bits) + ent;
        var i = (c << hshift) ^ ent; // xor hashing

        if (hTab[i] == fcode) {
          ent = codeTab[i];
          c = _nextPixel();
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
          for (var i = 0; i < _hsize; ++i) {
            hTab[i] = -1;
          }
          _freeEnt = _clearCode + 2;
          _clearFlag = true;
          _output(_clearCode);
        }

        c = _nextPixel();
      }
    }

    _output(ent);
    _output(_EOFCode);

    output!.writeByte(0);
  }

  void _output(int? code) {
    _curAccum &= _masks[_curBits];

    if (_curBits > 0) {
      _curAccum |= (code! << _curBits);
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

    if (code == _EOFCode) {
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

  void _writeGraphicsCtrlExt() {
    output!.writeByte(_extensionRecordType);
    output!.writeByte(_graphicControlExt);
    output!.writeByte(4); // data block size

    const transparency = 0;
    const dispose = 0; // dispose = no action

    // packed fields
    output!.writeByte(0 | // 1:3 reserved
        dispose | // 4:6 disposal
        0 | // 7   user input - 0 = none
        transparency); // 8   transparency flag

    output!.writeUint16(_lastImageDuration ?? delay); // delay x 1/100 sec
    output!.writeByte(0); // transparent color index
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

  Uint8List? _lastImage;
  int? _lastImageDuration;
  NeuralQuantizer? _lastColorMap;
  late int _width;
  late int _height;
  int _encodedFrames;

  int _curAccum = 0;
  int _curBits = 0;
  int _nBits = 0;
  int _initBits = 0;
  int _EOFCode = 0;
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
  static const _hsize = 5003; // 80% occupancy
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
