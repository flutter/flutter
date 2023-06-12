import 'dart:typed_data';

import '../animation.dart';
import '../image.dart';
import '../transform/copy_into.dart';
import '../util/input_buffer.dart';
import 'decoder.dart';
import 'gif/gif_color_map.dart';
import 'gif/gif_image_desc.dart';
import 'gif/gif_info.dart';

/// A decoder for the GIF image format. This supports both single frame and
/// animated GIF files, and transparency.
class GifDecoder extends Decoder {
  GifInfo? info;

  GifDecoder([List<int>? bytes]) {
    if (bytes != null) {
      startDecode(bytes);
    }
  }

  /// Is the given file a valid Gif image?
  @override
  bool isValidFile(List<int> bytes) {
    _input = InputBuffer(bytes);
    info = GifInfo();
    return _getInfo();
  }

  /// How many frames are available to decode?
  ///
  /// You should have prepared the decoder by either passing the file bytes
  /// to the constructor, or calling getInfo.
  @override
  int numFrames() => (info != null) ? info!.numFrames : 0;

  /// Validate the file is a Gif image and get information about it.
  /// If the file is not a valid Gif image, null is returned.
  @override
  GifInfo? startDecode(List<int> bytes) {
    _input = InputBuffer(bytes);

    info = GifInfo();
    if (!_getInfo()) {
      return null;
    }

    try {
      while (!_input!.isEOS) {
        final recordType = _input!.readByte();
        switch (recordType) {
          case IMAGE_DESC_RECORD_TYPE:
            final gifImage = _skipImage();
            if (gifImage == null) {
              return info;
            }
            info!.frames.add(gifImage);
            break;
          case EXTENSION_RECORD_TYPE:
            final extCode = _input!.readByte();
            if (extCode == APPLICATION_EXT) {
              _readApplicationExt(_input!);
            } else if (extCode == GRAPHIC_CONTROL_EXT) {
              _readGraphicsControlExt(_input!);
            } else {
              _skipRemainder();
            }
            break;
          case TERMINATE_RECORD_TYPE:
            //_numFrames = info.numFrames;
            return info;
          default:
            break;
        }
      }
    } catch (error) {
      print(error);
    }

    //_numFrames = info.numFrames;
    return info;
  }

  void _readApplicationExt(InputBuffer _input) {
    final blockSize = _input.readByte();
    final tag = _input.readString(blockSize);
    if (tag == 'NETSCAPE2.0') {
      final b1 = _input.readByte();
      final b2 = _input.readByte();
      if (b1 == 0x03 && b2 == 0x01) {
        _repeat = _input.readUint16();
      }
    } else {
      _skipRemainder();
    }
  }

  void _readGraphicsControlExt(InputBuffer _input) {
    /*int blockSize =*/ _input.readByte();
    final b = _input.readByte();
    final duration = _input.readUint16();
    final transparent = _input.readByte();
    /*int endBlock =*/ _input.readByte();
    final disposalMethod = (b >> 2) & 0x7;
    //int userInput = (b >> 1) & 0x1;
    final transparentFlag = b & 0x1;

    final recordType = _input.peekBytes(1)[0];
    if (recordType == IMAGE_DESC_RECORD_TYPE) {
      _input.skip(1);
      final gifImage = _skipImage();
      if (gifImage == null) {
        return;
      }

      gifImage.duration = duration;
      gifImage.clearFrame = disposalMethod == 2;

      if (transparentFlag != 0) {
        if (gifImage.colorMap == null && info!.globalColorMap != null) {
          gifImage.colorMap = GifColorMap.from(info!.globalColorMap!);
        }
        if (gifImage.colorMap != null) {
          gifImage.colorMap!.transparent = transparent;
        }
      }

      info!.frames.add(gifImage);
    }
  }

  @override
  Image? decodeFrame(int frame) {
    if (_input == null || info == null) {
      return null;
    }

    if (frame >= info!.frames.length || frame < 0) {
      return null;
    }

    //_frame = frame;
    final gifImage = info!.frames[frame] as InternalGifImageDesc;
    _input!.offset = gifImage.inputPosition;

    return _decodeImage(info!.frames[frame]);
  }

  @override
  Image? decodeImage(List<int> bytes, {int frame = 0}) {
    if (startDecode(bytes) == null) {
      return null;
    }
    //_frame = 0;
    //_numFrames = 1;
    return decodeFrame(frame);
  }

  /// Decode all of the frames of an animated gif. For single image gifs,
  /// this will return an animation with a single frame.
  @override
  Animation? decodeAnimation(List<int> bytes) {
    if (startDecode(bytes) == null) {
      return null;
    }

    final anim = Animation();
    anim.width = info!.width;
    anim.height = info!.height;
    anim.loopCount = _repeat;

    Image? lastImage = null;
    for (var i = 0; i < info!.numFrames; ++i) {
      final frame = info!.frames[i];
      final image = decodeFrame(i);
      if (image == null) {
        return null;
      }

      if (lastImage == null) {
        lastImage = image;
        lastImage.duration = frame.duration * 10; // Convert to MS
        anim.addFrame(lastImage);
        continue;
      }

      if (image.width == lastImage.width && image.height == lastImage.height &&
          frame.x == 0 && frame.y == 0 && frame.clearFrame) {
        lastImage = image;
        lastImage.duration = frame.duration * 10; // Convert to MS
        anim.addFrame(lastImage);
        continue;
      }

      if (frame.clearFrame) {
        lastImage = Image(lastImage.width, lastImage.height);
        final colorMap =
          (frame.colorMap != null) ? frame.colorMap : info!.globalColorMap;
        lastImage.fill(colorMap!.color(info!.backgroundColor));
      } else {
        lastImage = new Image.from(lastImage);
      }

      copyInto(lastImage, image, dstX: frame.x, dstY: frame.y);

      lastImage.duration = frame.duration * 10; // Convert 1/100 sec to ms.
      anim.addFrame(lastImage);
    }

    return anim;
  }

  InternalGifImageDesc? _skipImage() {
    if (_input!.isEOS) {
      return null;
    }
    final gifImage = InternalGifImageDesc(_input!);
    _input!.skip(1);
    _skipRemainder();
    return gifImage;
  }

  /*bool _skipExtension() {
    int extCode = _input.readByte();
    int b = _input.readByte();
    while (b != 0) {
      _input.skip(b);
      b = _input.readByte();
    }
    return true;
  }*/

  Image? _decodeImage(GifImageDesc gifImage) {
    if (_buffer == null) {
      _initDecode();
    }

    _bitsPerPixel = _input!.readByte();
    _clearCode = 1 << _bitsPerPixel;
    _eofCode = _clearCode + 1;
    _runningCode = _eofCode + 1;
    _runningBits = _bitsPerPixel + 1;
    _maxCode1 = 1 << _runningBits;
    _stackPtr = 0;
    _lastCode = NO_SUCH_CODE;
    _currentShiftState = 0;
    _currentShiftDWord = 0;
    _buffer![0] = 0;
    _prefix!.fillRange(0, _prefix!.length, NO_SUCH_CODE);

    final width = gifImage.width;
    final height = gifImage.height;

    if (gifImage.x + width > info!.width ||
        gifImage.y + height > info!.height) {
      return null;
    }

    final colorMap =
        (gifImage.colorMap != null) ? gifImage.colorMap : info!.globalColorMap;

    _pixelCount = width * height;

    final image = Image(width, height);
    final line = Uint8List(width);

    if (gifImage.interlaced) {
      final row = gifImage.y;
      for (var i = 0, j = 0; i < 4; ++i) {
        for (var y = row + INTERLACED_OFFSET[i];
            y < row + height;
            y += INTERLACED_JUMP[i], ++j) {
          if (!_getLine(line)) {
            return image;
          }
          _updateImage(image, y, colorMap, line);
        }
      }
    } else {
      for (var y = 0; y < height; ++y) {
        if (!_getLine(line)) {
          return image;
        }
        _updateImage(image, y, colorMap, line);
      }
    }

    return image;
  }

  void _updateImage(Image image, int y, GifColorMap? colorMap, Uint8List line) {
    if (colorMap != null) {
      for (var x = 0, width = line.length; x < width; ++x) {
        image.setPixel(x, y, colorMap.color(line[x]));
      }
    }
  }

  bool _getInfo() {
    final tag = _input!.readString(STAMP_SIZE);
    if (tag != GIF87_STAMP && tag != GIF89_STAMP) {
      return false;
    }

    info!.width = _input!.readUint16();
    info!.height = _input!.readUint16();

    final b = _input!.readByte();
    info!.colorResolution = (((b & 0x70) + 1) >> 4) + 1;

    final bitsPerPixel = (b & 0x07) + 1;

    info!.backgroundColor = _input!.readByte();

    _input!.skip(1);

    // Is there a global color map?
    if (b & 0x80 != 0) {
      info!.globalColorMap = GifColorMap(1 << bitsPerPixel);

      // Get the global color map:
      for (var i = 0; i < info!.globalColorMap!.numColors; ++i) {
        final r = _input!.readByte();
        final g = _input!.readByte();
        final b = _input!.readByte();
        info!.globalColorMap!.setColor(i, r, g, b);
      }
    }

    info!.isGif89 = tag == GIF89_STAMP;

    return true;
  }

  bool _getLine(Uint8List line) {
    _pixelCount = _pixelCount! - line.length;

    if (!_decompressLine(line)) {
      return false;
    }

    // Flush any remainder blocks.
    if (_pixelCount == 0) {
      _skipRemainder();
    }

    return true;
  }

  // Continue to get the image code in compressed form. This routine should be
  // called until NULL block is returned.
  // The block should NOT be freed by the user (not dynamically allocated).
  bool _skipRemainder() {
    if (_input!.isEOS) {
      return true;
    }
    var b = _input!.readByte();
    while (b != 0 && !_input!.isEOS) {
      _input!.skip(b);
      if (_input!.isEOS) {
        return true;
      }
      b = _input!.readByte();
    }
    return true;
  }

  // The LZ decompression routine:
  // This version decompress the given gif file into Line of length LineLen.
  // This routine can be called few times (one per scan line, for example), in
  // order the complete the whole image.
  bool _decompressLine(Uint8List line) {
    if (_stackPtr > LZ_MAX_CODE) {
      return false;
    }

    final lineLen = line.length;
    var i = 0;

    if (_stackPtr != 0) {
      // Let pop the stack off before continuing to read the gif file:
      while (_stackPtr != 0 && i < lineLen) {
        line[i++] = _stack[--_stackPtr];
      }
    }

    int? currentPrefix;

    // Decode LineLen items.
    while (i < lineLen) {
      _currentCode = _decompressInput();
      if (_currentCode == null) {
        return false;
      }

      if (_currentCode == _eofCode) {
        // Note however that usually we will not be here as we will stop
        // decoding as soon as we got all the pixel, or EOF code will
        // not be read at all, and DGifGetLine/Pixel clean everything.
        return false;
      }

      if (_currentCode == _clearCode) {
        // We need to start over again:
        for (var j = 0; j <= LZ_MAX_CODE; j++) {
          _prefix![j] = NO_SUCH_CODE;
        }

        _runningCode = _eofCode + 1;
        _runningBits = _bitsPerPixel + 1;
        _maxCode1 = 1 << _runningBits;
        _lastCode = NO_SUCH_CODE;
      } else {
        // Its regular code - if in pixel range simply add it to output
        // stream, otherwise trace to codes linked list until the prefix
        // is in pixel range:
        if (_currentCode! < _clearCode) {
          // This is simple - its pixel scalar, so add it to output:
          line[i++] = _currentCode!;
        } else {
          // Its a code to needed to be traced: trace the linked list
          // until the prefix is a pixel, while pushing the suffix
          // pixels on our stack. If we done, pop the stack in reverse
          // (thats what stack is good for!) order to output. */
          if (_prefix![_currentCode!] == NO_SUCH_CODE) {
            // Only allowed if CrntCode is exactly the running code:
            // In that case CrntCode = XXXCode, CrntCode or the
            // prefix code is last code and the suffix char is
            // exactly the prefix of last code!
            if (_currentCode == _runningCode - 2) {
              currentPrefix = _lastCode;
              _suffix[_runningCode - 2] = _stack[_stackPtr++] =
                  _getPrefixChar(_prefix, _lastCode, _clearCode);
            } else {
              return false;
            }
          } else {
            currentPrefix = _currentCode;
          }

          // Now (if image is O.K.) we should not get an NO_SUCH_CODE
          // During the trace. As we might loop forever, in case of
          // defective image, we count the number of loops we trace
          // and stop if we got LZ_MAX_CODE. obviously we can not
          // loop more than that.
          var j = 0;
          while (j++ <= LZ_MAX_CODE &&
              currentPrefix! > _clearCode &&
              currentPrefix <= LZ_MAX_CODE) {
            _stack[_stackPtr++] = _suffix[currentPrefix];
            currentPrefix = _prefix![currentPrefix];
          }

          if (j >= LZ_MAX_CODE || currentPrefix! > LZ_MAX_CODE) {
            return false;
          }

          // Push the last character on stack:
          _stack[_stackPtr++] = currentPrefix;

          // Now lets pop all the stack into output:
          while (_stackPtr != 0 && i < lineLen) {
            line[i++] = _stack[--_stackPtr];
          }
        }

        if (_lastCode != NO_SUCH_CODE &&
            _prefix![_runningCode - 2] == NO_SUCH_CODE) {
          _prefix![_runningCode - 2] = _lastCode;

          if (_currentCode == _runningCode - 2) {
            // Only allowed if CrntCode is exactly the running code:
            // In that case CrntCode = XXXCode, CrntCode or the
            // prefix code is last code and the suffix char is
            // exactly the prefix of last code!
            _suffix[_runningCode - 2] =
                _getPrefixChar(_prefix, _lastCode, _clearCode);
          } else {
            _suffix[_runningCode - 2] =
                _getPrefixChar(_prefix, _currentCode!, _clearCode);
          }
        }

        _lastCode = _currentCode!;
      }
    }

    return true;
  }

  // The LZ decompression input routine:
  // This routine is responsible for the decompression of the bit stream from
  // 8 bits (bytes) packets, into the real codes.
  int? _decompressInput() {
    int code;

    // The image can't contain more than LZ_BITS per code.
    if (_runningBits > LZ_BITS) {
      return null;
    }

    while (_currentShiftState < _runningBits) {
      // Needs to get more bytes from input stream for next code:
      final nextByte = _bufferedInput()!;

      _currentShiftDWord |= nextByte << _currentShiftState;
      _currentShiftState += 8;
    }

    code = _currentShiftDWord & CODE_MASKS[_runningBits];

    _currentShiftDWord >>= _runningBits;
    _currentShiftState -= _runningBits;

    // If code cannot fit into RunningBits bits, must raise its size. Note
    // however that codes above 4095 are used for special signaling.
    // If we're using LZ_BITS bits already and we're at the max code, just
    // keep using the table as it is, don't increment Private->RunningCode.
    if (_runningCode < LZ_MAX_CODE + 2 &&
        ++_runningCode > _maxCode1 &&
        _runningBits < LZ_BITS) {
      _maxCode1 <<= 1;
      _runningBits++;
    }

    return code;
  }

  // Routine to trace the Prefixes linked list until we get a prefix which is
  // not code, but a pixel value (less than ClearCode). Returns that pixel value.
  // If image is defective, we might loop here forever, so we limit the loops to
  // the maximum possible if image O.k. - LZ_MAX_CODE times.
  int _getPrefixChar(Uint32List? prefix, int code, int clearCode) {
    var i = 0;
    while (code > clearCode && i++ <= LZ_MAX_CODE) {
      if (code > LZ_MAX_CODE) {
        return NO_SUCH_CODE;
      }
      code = prefix![code];
    }
    return code;
  }

  // This routines read one gif data block at a time and buffers it internally
  // so that the decompression routine could access it.
  // The routine returns the next byte from its internal buffer (or read next
  // block in if buffer empty) and returns null on failure.
  int? _bufferedInput() {
    int nextByte;
    if (_buffer![0] == 0) {
      // Needs to read the next buffer - this one is empty:
      _buffer![0] = _input!.readByte();

      // There shouldn't be any empty data blocks here as the LZW spec
      // says the LZW termination code should come first. Therefore we
      // shouldn't be inside this routine at that point.
      if (_buffer![0] == 0) {
        return null;
      }

      _buffer!.setRange(
          1, 1 + _buffer![0], _input!.readBytes(_buffer![0]).toUint8List());

      nextByte = _buffer![1];
      _buffer![1] = 2; // We use now the second place as last char read!
      _buffer![0]--;
    } else {
      nextByte = _buffer![_buffer![1]++];
      _buffer![0]--;
    }

    return nextByte;
  }

  void _initDecode() {
    _buffer = Uint8List(256);
    _stack = Uint8List(LZ_MAX_CODE);
    _suffix = Uint8List(LZ_MAX_CODE + 1);
    _prefix = Uint32List(LZ_MAX_CODE + 1);
  }

  InputBuffer? _input;
  //int _frame;
  //int _numFrames;
  int _repeat = 0;
  Uint8List? _buffer;
  late Uint8List _stack;
  late Uint8List _suffix;
  Uint32List? _prefix;
  int _bitsPerPixel = 0;
  int? _pixelCount;
  int _currentShiftDWord = 0;
  int _currentShiftState = 0;
  int _stackPtr = 0;
  int? _currentCode;
  int _lastCode = 0;
  int _maxCode1 = 0;
  int _runningBits = 0;
  int _runningCode = 0;
  int _eofCode = 0;
  int _clearCode = 0;

  static const STAMP_SIZE = 6;
  static const String GIF87_STAMP = 'GIF87a';
  static const String GIF89_STAMP = 'GIF89a';

  static const IMAGE_DESC_RECORD_TYPE = 0x2c;
  static const EXTENSION_RECORD_TYPE = 0x21;
  static const TERMINATE_RECORD_TYPE = 0x3b;

  static const GRAPHIC_CONTROL_EXT = 0xf9;
  static const APPLICATION_EXT = 0xff;

  static const LZ_MAX_CODE = 4095;
  static const LZ_BITS = 12;

  static const NO_SUCH_CODE = 4098; // Impossible code, to signal empty.

  static const List<int> CODE_MASKS = [
    0x0000,
    0x0001,
    0x0003,
    0x0007,
    0x000f,
    0x001f,
    0x003f,
    0x007f,
    0x00ff,
    0x01ff,
    0x03ff,
    0x07ff,
    0x0fff
  ];

  static const List<int> INTERLACED_OFFSET = [0, 4, 2, 1];
  static const List<int> INTERLACED_JUMP = [8, 8, 4, 2];
}
