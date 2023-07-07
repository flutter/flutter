import 'dart:typed_data';

import '../color/color_uint8.dart';
import '../image/image.dart';
import '../util/input_buffer.dart';
import 'decoder.dart';
import 'gif/gif_color_map.dart';
import 'gif/gif_image_desc.dart';
import 'gif/gif_info.dart';

/// A decoder for the GIF image format. This supports both single frame and
/// animated GIF files, and transparency.
class GifDecoder extends Decoder {
  GifInfo? info;

  GifDecoder([Uint8List? bytes]) {
    if (bytes != null) {
      startDecode(bytes);
    }
  }

  /// Is the given file a valid Gif image?
  @override
  bool isValidFile(Uint8List bytes) {
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
  GifInfo? startDecode(Uint8List bytes) {
    _input = InputBuffer(bytes);

    info = GifInfo();
    if (!_getInfo()) {
      return null;
    }

    try {
      while (!_input!.isEOS) {
        final recordType = _input!.readByte();
        switch (recordType) {
          case imageDescRecordType:
            final gifImage = _skipImage();
            if (gifImage == null) {
              return info;
            }
            gifImage
              ..duration = _duration
              ..clearFrame = _disposalMethod == 2;
            if (_transparentFlag != 0) {
              if (gifImage.colorMap == null && info!.globalColorMap != null) {
                gifImage.colorMap = GifColorMap.from(info!.globalColorMap!);
              }
              if (gifImage.colorMap != null) {
                gifImage.colorMap!.transparent = _transparent;
              }
            }
            info!.frames.add(gifImage);
            break;
          case extensionRecordType:
            final extCode = _input!.readByte();
            if (extCode == applicationExt) {
              _readApplicationExt(_input!);
            } else if (extCode == graphicControlExt) {
              _readGraphicsControlExt(_input!);
            } else {
              _skipRemainder();
            }
            break;
          case terminateRecordType:
            //_numFrames = info.numFrames;
            return info;
          default:
            break;
        }
      }
    } catch (error) {
      //
    }

    //_numFrames = info.numFrames;
    return info;
  }

  void _readApplicationExt(InputBuffer input) {
    final blockSize = input.readByte();
    final tag = input.readString(blockSize);
    if (tag == 'NETSCAPE2.0') {
      final b1 = input.readByte();
      final b2 = input.readByte();
      if (b1 == 0x03 && b2 == 0x01) {
        _repeat = input.readUint16();
      }
    } else {
      _skipRemainder();
    }
  }

  var _transparentFlag = 0;
  var _disposalMethod = 0;
  var _transparent = 0;
  var _duration = 0;

  void _readGraphicsControlExt(InputBuffer input) {
    /*int blockSize =*/ input.readByte();
    final b = input.readByte();
    _duration = input.readUint16();
    _transparent = input.readByte();
    /*int endBlock =*/ input.readByte();
    _disposalMethod = (b >> 2) & 0x7;
    //int userInput = (b >> 1) & 0x1;
    _transparentFlag = b & 0x1;

    final recordType = input.peekBytes(1)[0];
    if (recordType == imageDescRecordType) {
      input.skip(1);
      final gifImage = _skipImage();
      if (gifImage == null) {
        return;
      }

      gifImage
        ..duration = _duration
        ..clearFrame = _disposalMethod == 2;

      if (_transparentFlag != 0) {
        if (gifImage.colorMap == null && info!.globalColorMap != null) {
          gifImage.colorMap = GifColorMap.from(info!.globalColorMap!);
        }
        if (gifImage.colorMap != null) {
          gifImage.colorMap!.transparent = _transparent;
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
  Image? decode(Uint8List bytes, {int? frame}) {
    if (startDecode(bytes) == null) {
      return null;
    }

    if (info!.numFrames == 1 || frame != null) {
      return decodeFrame(frame ?? 0);
    }

    Image? firstImage;
    Image? lastImage;
    for (var i = 0; i < info!.numFrames; ++i) {
      final frame = info!.frames[i];
      final image = decodeFrame(i);
      if (image == null) {
        return null;
      }

      image.frameDuration = frame.duration * 10; // Convert to MS

      if (firstImage == null || lastImage == null) {
        firstImage = image;
        lastImage = image;
        image.loopCount = _repeat;
        continue;
      }

      if (image.width == lastImage.width &&
          image.height == lastImage.height &&
          frame.x == 0 &&
          frame.y == 0 &&
          frame.clearFrame) {
        lastImage = image;
        firstImage.addFrame(lastImage);
        continue;
      }

      if (frame.clearFrame) {
        final colorMap =
            (frame.colorMap != null) ? frame.colorMap! : info!.globalColorMap!;

        lastImage = Image(
            width: lastImage.width,
            height: lastImage.height,
            numChannels: 1,
            palette: colorMap.getPalette())
          ..clear(colorMap.color(info!.backgroundColor!.r as int));
      } else {
        lastImage = Image.from(lastImage);
      }

      lastImage.frameDuration = image.frameDuration;

      for (final p in image) {
        if (p.a != 0) {
          lastImage.setPixel(p.x + frame.x, p.y + frame.y, p);
        }
      }

      firstImage.addFrame(lastImage);
    }

    return firstImage;
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
    _lastCode = noSuchCode;
    _currentShiftState = 0;
    _currentShiftDWord = 0;
    _buffer![0] = 0;
    _prefix!.fillRange(0, _prefix!.length, noSuchCode);

    final width = gifImage.width;
    final height = gifImage.height;

    if (gifImage.x + width > info!.width ||
        gifImage.y + height > info!.height) {
      return null;
    }

    final colorMap = (gifImage.colorMap != null)
        ? gifImage.colorMap!
        : info!.globalColorMap!;

    _pixelCount = width * height;

    final image = Image(
        width: width,
        height: height,
        numChannels: 1,
        palette: colorMap.getPalette());

    final line = Uint8List(width);

    if (gifImage.interlaced) {
      final row = gifImage.y;
      for (var i = 0, j = 0; i < 4; ++i) {
        for (var y = row + interlacedOffset[i];
            y < row + height;
            y += interlacedJump[i], ++j) {
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
      final width = line.length;
      for (var x = 0; x < width; ++x) {
        image.setPixelRgb(x, y, line[x], 0, 0);
      }
    }
  }

  bool _getInfo() {
    final tag = _input!.readString(stampSize);
    if (tag != gif87Stamp && tag != gif89Stamp) {
      return false;
    }

    info!.width = _input!.readUint16();
    info!.height = _input!.readUint16();

    final b = _input!.readByte();
    info!.colorResolution = (((b & 0x70) + 1) >> 4) + 1;

    final bitsPerPixel = (b & 0x07) + 1;

    info!.backgroundColor = ColorUint8.fromList([_input!.readByte()]);

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

    info!.isGif89 = tag == gif89Stamp;

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
    if (_stackPtr > lzMaxCode) {
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
        for (var j = 0; j <= lzMaxCode; j++) {
          _prefix![j] = noSuchCode;
        }

        _runningCode = _eofCode + 1;
        _runningBits = _bitsPerPixel + 1;
        _maxCode1 = 1 << _runningBits;
        _lastCode = noSuchCode;
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
          if (_prefix![_currentCode!] == noSuchCode) {
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

          // Now (if image is O.K.) we should not get an noSuchCode
          // During the trace. As we might loop forever, in case of
          // defective image, we count the number of loops we trace
          // and stop if we got lzMaxCode. obviously we can not
          // loop more than that.
          var j = 0;
          while (j++ <= lzMaxCode &&
              currentPrefix! > _clearCode &&
              currentPrefix <= lzMaxCode) {
            _stack[_stackPtr++] = _suffix[currentPrefix];
            currentPrefix = _prefix![currentPrefix];
          }

          if (j >= lzMaxCode || currentPrefix! > lzMaxCode) {
            return false;
          }

          // Push the last character on stack:
          _stack[_stackPtr++] = currentPrefix;

          // Now lets pop all the stack into output:
          while (_stackPtr != 0 && i < lineLen) {
            line[i++] = _stack[--_stackPtr];
          }
        }

        if (_lastCode != noSuchCode &&
            _prefix![_runningCode - 2] == noSuchCode) {
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

    // The image can't contain more than lzBits per code.
    if (_runningBits > lzBits) {
      return null;
    }

    while (_currentShiftState < _runningBits) {
      // Needs to get more bytes from input stream for next code:
      final nextByte = _bufferedInput()!;

      _currentShiftDWord |= nextByte << _currentShiftState;
      _currentShiftState += 8;
    }

    code = _currentShiftDWord & codeMasks[_runningBits];

    _currentShiftDWord >>= _runningBits;
    _currentShiftState -= _runningBits;

    // If code cannot fit into RunningBits bits, must raise its size. Note
    // however that codes above 4095 are used for special signaling.
    // If we're using lzBits bits already and we're at the max code, just
    // keep using the table as it is, don't increment Private->RunningCode.
    if (_runningCode < lzMaxCode + 2 &&
        ++_runningCode > _maxCode1 &&
        _runningBits < lzBits) {
      _maxCode1 <<= 1;
      _runningBits++;
    }

    return code;
  }

  // Routine to trace the Prefixes linked list until we get a prefix which is
  // not code, but a pixel value (less than ClearCode). Returns that pixel
  // value. If image is defective, we might loop here forever, so we limit
  // the loops to the maximum possible if image O.k. - lzMaxCode times.
  int _getPrefixChar(Uint32List? prefix, int code, int clearCode) {
    var i = 0;
    while (code > clearCode && i++ <= lzMaxCode) {
      if (code > lzMaxCode) {
        return noSuchCode;
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
    _stack = Uint8List(lzMaxCode);
    _suffix = Uint8List(lzMaxCode + 1);
    _prefix = Uint32List(lzMaxCode + 1);
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

  static const stampSize = 6;
  static const String gif87Stamp = 'GIF87a';
  static const String gif89Stamp = 'GIF89a';

  static const imageDescRecordType = 0x2c;
  static const extensionRecordType = 0x21;
  static const terminateRecordType = 0x3b;

  static const graphicControlExt = 0xf9;
  static const applicationExt = 0xff;

  static const lzMaxCode = 4095;
  static const lzBits = 12;

  static const noSuchCode = 4098; // Impossible code, to signal empty.

  static const List<int> codeMasks = [
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

  static const List<int> interlacedOffset = [0, 4, 2, 1];
  static const List<int> interlacedJump = [8, 8, 4, 2];
}
