import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../color/color_uint8.dart';
import '../color/format.dart';
import '../draw/blend_mode.dart';
import '../draw/composite_image.dart';
import '../image/icc_profile.dart';
import '../image/image.dart';
import '../image/palette_uint8.dart';
import '../image/pixel.dart';
import '../util/image_exception.dart';
import '../util/input_buffer.dart';
import 'decode_info.dart';
import 'decoder.dart';
import 'png/png_frame.dart';
import 'png/png_info.dart';

/// Decode a PNG encoded image.
class PngDecoder extends Decoder {
  final _info = InternalPngInfo();

  /// Is the given file a valid PNG image?
  @override
  bool isValidFile(Uint8List data) {
    final input = InputBuffer(data, bigEndian: true);
    final bytes = input.readBytes(8);
    const pngHeader = [137, 80, 78, 71, 13, 10, 26, 10];
    for (var i = 0; i < 8; ++i) {
      if (bytes[i] != pngHeader[i]) {
        return false;
      }
    }
    return true;
  }

  PngInfo get info => _info;

  /// Start decoding the data as an animation sequence, but don't actually
  /// process the frames until they are requested with decodeFrame.
  @override
  DecodeInfo? startDecode(Uint8List data) {
    _input = InputBuffer(data, bigEndian: true);

    final pngHeader = _input.readBytes(8);
    const expectedHeader = [137, 80, 78, 71, 13, 10, 26, 10];
    for (var i = 0; i < 8; ++i) {
      if (pngHeader[i] != expectedHeader[i]) {
        return null;
      }
    }

    while (true) {
      final inputPos = _input.position;
      var chunkSize = _input.readUint32();
      final chunkType = _input.readString(4);
      switch (chunkType) {
        case 'tEXt':
          final txtData = _input.readBytes(chunkSize).toUint8List();
          final l = txtData.length;
          for (var i = 0; i < l; ++i) {
            if (txtData[i] == 0) {
              final key = latin1.decode(txtData.sublist(0, i));
              final text = latin1.decode(txtData.sublist(i + 1));
              _info.textData[key] = text;
              break;
            }
          }
          _input.skip(4); //crc
          break;
        case 'IHDR':
          final hdr = InputBuffer.from(_input.readBytes(chunkSize));
          final Uint8List hdrBytes = hdr.toUint8List();
          _info.width = hdr.readUint32();
          _info.height = hdr.readUint32();
          _info.bits = hdr.readByte();
          _info.colorType = hdr.readByte();
          _info.compressionMethod = hdr.readByte();
          _info.filterMethod = hdr.readByte();
          _info.interlaceMethod = hdr.readByte();

          // Validate some of the info in the header to make sure we support
          // the proposed image data.
          if (!PngColorType.isValid(_info.colorType)) {
            return null;
          }

          if (_info.filterMethod != 0) {
            return null;
          }

          switch (_info.colorType) {
            case PngColorType.grayscale:
              if (![1, 2, 4, 8, 16].contains(_info.bits)) {
                return null;
              }
              break;
            case PngColorType.rgb:
              if (![8, 16].contains(_info.bits)) {
                return null;
              }
              break;
            case PngColorType.indexed:
              if (![1, 2, 4, 8].contains(_info.bits)) {
                return null;
              }
              break;
            case PngColorType.grayscaleAlpha:
              if (![8, 16].contains(_info.bits)) {
                return null;
              }
              break;
            case PngColorType.rgba:
              if (![8, 16].contains(_info.bits)) {
                return null;
              }
              break;
          }

          final crc = _input.readUint32();
          final computedCrc = _crc(chunkType, hdrBytes);
          if (crc != computedCrc) {
            throw ImageException('Invalid $chunkType checksum');
          }
          break;
        case 'PLTE':
          _info.palette = _input.readBytes(chunkSize).toUint8List();
          final crc = _input.readUint32();
          final computedCrc = _crc(chunkType, _info.palette as List<int>);
          if (crc != computedCrc) {
            throw ImageException('Invalid $chunkType checksum');
          }
          break;
        case 'tRNS':
          _info.transparency = _input.readBytes(chunkSize).toUint8List();
          final crc = _input.readUint32();
          final computedCrc = _crc(chunkType, _info.transparency!);
          if (crc != computedCrc) {
            throw ImageException('Invalid $chunkType checksum');
          }
          break;
        case 'IEND':
          // End of the image.
          _input.skip(4); // CRC
          break;
        /*case 'eXif': // TODO: parse exif
          {
            final exifData = _input.readBytes(chunkSize);
            final exif = ExifData.fromInputBuffer(exifData);
            _input.skip(4); // CRC
            break;
          }*/
        case 'gAMA':
          if (chunkSize != 4) {
            throw ImageException('Invalid gAMA chunk');
          }
          final gammaInt = _input.readUint32();
          _input.skip(4); // CRC
          // A gamma of 1.0 doesn't have any affect, so pretend we didn't get
          // a gamma in that case.
          if (gammaInt != 100000) {
            _info.gamma = gammaInt / 100000.0;
          }
          break;
        case 'IDAT':
          _info.idat.add(inputPos);
          _input.skip(chunkSize);
          _input.skip(4); // CRC
          break;
        case 'acTL': // Animation control chunk
          _info.numFrames = _input.readUint32();
          _info.repeat = _input.readUint32();
          _input.skip(4); // CRC
          break;
        case 'fcTL': // Frame control chunk
          final frame = InternalPngFrame(
              sequenceNumber: _input.readUint32(),
              width: _input.readUint32(),
              height: _input.readUint32(),
              xOffset: _input.readUint32(),
              yOffset: _input.readUint32(),
              delayNum: _input.readUint16(),
              delayDen: _input.readUint16(),
              dispose: PngDisposeMode.values[_input.readByte()],
              blend: PngBlendMode.values[_input.readByte()]);
          _info.frames.add(frame);
          _input.skip(4); // CRC
          break;
        case 'fdAT':
          /*int sequenceNumber =*/ _input.readUint32();
          final frame = _info.frames.last as InternalPngFrame;
          frame.fdat.add(inputPos);
          _input.skip(chunkSize - 4);
          _input.skip(4); // CRC
          break;
        case 'bKGD':
          if (_info.colorType == PngColorType.indexed) {
            final paletteIndex = _input.readByte();
            chunkSize--;
            final p3 = paletteIndex * 3;
            final r = _info.palette![p3]!;
            final g = _info.palette![p3 + 1]!;
            final b = _info.palette![p3 + 2]!;
            if (_info.transparency != null) {
              final isTransparent = _info.transparency!.contains(paletteIndex);
              _info.backgroundColor =
                  ColorRgba8(r, g, b, isTransparent ? 0 : 255);
            } else {
              _info.backgroundColor = ColorRgb8(r, g, b);
            }
          } else if (_info.colorType == PngColorType.grayscale ||
              _info.colorType == PngColorType.grayscaleAlpha) {
            /*int gray =*/ _input.readUint16();
            chunkSize -= 2;
          } else if (_info.colorType == PngColorType.rgb ||
              _info.colorType == PngColorType.rgba) {
            /*int r =*/ _input
              ..readUint16()
              /*int g =*/
              ..readUint16()
              /*int b =*/
              ..readUint16();
            chunkSize -= 24;
          }
          if (chunkSize > 0) {
            _input.skip(chunkSize);
          }
          _input.skip(4); // CRC
          break;
        case 'iCCP':
          _info.iccpName = _input.readString();
          _info.iccpCompression = _input.readByte(); // 0: deflate
          chunkSize -= _info.iccpName.length + 2;
          final profile = _input.readBytes(chunkSize);
          _info.iccpData = profile.toUint8List();
          _input.skip(4); // CRC
          break;
        default:
          //print('Skipping $chunkType');
          _input.skip(chunkSize);
          _input.skip(4); // CRC
          break;
      }

      if (chunkType == 'IEND') {
        break;
      }

      if (_input.isEOS) {
        return null;
      }
    }

    return _info;
  }

  /// The number of frames that can be decoded.
  @override
  int numFrames() => _info.numFrames;

  /// Decode the frame (assuming [startDecode] has already been called).
  @override
  Image? decodeFrame(int frame) {
    Uint8List imageData;

    int? width = _info.width;
    int? height = _info.height;

    if (!_info.isAnimated || frame == 0) {
      final dataBlocks = <Uint8List>[];
      var totalSize = 0;
      final len = _info.idat.length;
      for (var i = 0; i < len; ++i) {
        _input.offset = _info.idat[i];
        final chunkSize = _input.readUint32();
        final chunkType = _input.readString(4);
        final data = _input.readBytes(chunkSize).toUint8List();
        totalSize += data.length;
        dataBlocks.add(data);
        final crc = _input.readUint32();
        final computedCrc = _crc(chunkType, data);
        if (crc != computedCrc) {
          throw ImageException('Invalid $chunkType checksum');
        }
      }
      imageData = Uint8List(totalSize);
      var offset = 0;
      for (var data in dataBlocks) {
        imageData.setAll(offset, data);
        offset += data.length;
      }
    } else {
      if (frame < 0 || frame >= _info.frames.length) {
        throw ImageException('Invalid Frame Number: $frame');
      }

      final f = _info.frames[frame] as InternalPngFrame;
      width = f.width;
      height = f.height;
      var totalSize = 0;
      final dataBlocks = <Uint8List>[];
      for (var i = 0; i < f.fdat.length; ++i) {
        _input.offset = f.fdat[i];
        final chunkSize = _input.readUint32();
        _input
          ..readString(4) // fDat chunk header
          ..skip(4); // sequence number
        final data = _input.readBytes(chunkSize - 4).toUint8List();
        totalSize += data.length;
        dataBlocks.add(data);
      }
      imageData = Uint8List(totalSize);
      var offset = 0;
      for (var data in dataBlocks) {
        imageData.setAll(offset, data);
        offset += data.length;
      }
    }

    var numChannels = _info.colorType == PngColorType.indexed
        ? 1
        : _info.colorType == PngColorType.grayscale
            ? 1
            : _info.colorType == PngColorType.grayscaleAlpha
                ? 2
                : _info.colorType == PngColorType.rgba
                    ? 4
                    : 3;

    List<int> uncompressed;
    try {
      uncompressed = const ZLibDecoder().decodeBytes(imageData);
    } catch (error) {
      //print(error);
      return null;
    }

    // input is the decompressed data.
    final input = InputBuffer(uncompressed, bigEndian: true);
    _resetBits();

    PaletteUint8? palette;

    // Non-indexed PNGs may have a palette, but it only provides a suggested
    // set of colors to which an RGB color can be quantized if not displayed
    // directly. In this case, just ignore the palette.
    if (_info.colorType == PngColorType.indexed) {
      if (_info.palette != null) {
        final p = _info.palette!;
        final numColors = p.length ~/ 3;
        final t = _info.transparency;
        final tl = t != null ? t.length : 0;
        final nc = t != null ? 4 : 3;
        palette = PaletteUint8(numColors, nc);
        for (var i = 0, pi = 0; i < numColors; ++i, pi += 3) {
          var a = 255;
          if (nc == 4 && i < tl) {
            a = t![i];
          }
          palette.setRgba(i, p[pi]!, p[pi + 1]!, p[pi + 2]!, a);
        }
      }
    }

    // grayscale images with no palette but with transparency, get
    // converted to a indexed palette image.
    if (_info.colorType == PngColorType.grayscale &&
        _info.transparency != null &&
        palette == null &&
        _info.bits <= 8) {
      final t = _info.transparency!;
      final nt = t.length;
      final numColors = 1 << _info.bits;
      palette = PaletteUint8(numColors, 4);
      // palette color are 8-bit, so convert the grayscale bit value to the
      // 8-bit palette value.
      final to8bit = _info.bits == 1
          ? 255
          : _info.bits == 2
              ? 85
              : _info.bits == 4
                  ? 17
                  : 1;
      for (var i = 0; i < numColors; ++i) {
        final g = i * to8bit;
        palette.setRgba(i, g, g, g, 255);
      }
      for (var i = 0; i < nt; i += 2) {
        final ti = ((t[i] & 0xff) << 8) | (t[i + 1] & 0xff);
        if (ti < numColors) {
          palette.set(ti, 3, 0);
        }
      }
    }

    final format = _info.bits == 1
        ? Format.uint1
        : _info.bits == 2
            ? Format.uint2
            : _info.bits == 4
                ? Format.uint4
                : _info.bits == 16
                    ? Format.uint16
                    : Format.uint8;

    if (_info.colorType == PngColorType.grayscale &&
        _info.transparency != null &&
        _info.bits > 8) {
      numChannels = 4;
    }

    if (_info.colorType == PngColorType.rgb && _info.transparency != null) {
      numChannels = 4;
    }

    final image = Image(
        width: width,
        height: height,
        numChannels: numChannels,
        palette: palette,
        format: format);

    final origW = _info.width;
    final origH = _info.height;
    _info
      ..width = width
      ..height = height;

    final w = width;
    final h = height;
    _progressY = 0;
    if (_info.interlaceMethod != 0) {
      _processPass(input, image, 0, 0, 8, 8, (w + 7) >> 3, (h + 7) >> 3);
      _processPass(input, image, 4, 0, 8, 8, (w + 3) >> 3, (h + 7) >> 3);
      _processPass(input, image, 0, 4, 4, 8, (w + 3) >> 2, (h + 3) >> 3);
      _processPass(input, image, 2, 0, 4, 4, (w + 1) >> 2, (h + 3) >> 2);
      _processPass(input, image, 0, 2, 2, 4, (w + 1) >> 1, (h + 1) >> 2);
      _processPass(input, image, 1, 0, 2, 2, w >> 1, (h + 1) >> 1);
      _processPass(input, image, 0, 1, 1, 2, w, h >> 1);
    } else {
      _process(input, image);
    }

    _info
      ..width = origW
      ..height = origH;

    if (_info.iccpData != null) {
      image.iccProfile = IccProfile(
          _info.iccpName, IccProfileCompression.deflate, _info.iccpData!);
    }

    if (_info.textData.isNotEmpty) {
      image.addTextData(_info.textData);
    }

    return image;
  }

  @override
  Image? decode(Uint8List bytes, {int? frame}) {
    if (startDecode(bytes) == null) {
      return null;
    }

    if (!_info.isAnimated || frame != null) {
      return decodeFrame(frame ?? 0)!;
    }

    Image? firstImage;
    Image? lastImage;
    for (var i = 0; i < _info.numFrames; ++i) {
      final frame = _info.frames[i];
      final image = decodeFrame(i);
      if (image == null) {
        continue;
      }

      if (firstImage == null || lastImage == null) {
        firstImage = image;
        lastImage = image
          // Convert to MS
          ..frameDuration = (frame.delay * 1000).toInt();
        continue;
      }

      if (image.width == lastImage.width &&
          image.height == lastImage.height &&
          frame.xOffset == 0 &&
          frame.yOffset == 0 &&
          frame.blend == PngBlendMode.source) {
        lastImage = image
          // Convert to MS
          ..frameDuration = (frame.delay * 1000).toInt();
        firstImage.addFrame(lastImage);
        continue;
      }

      final dispose = frame.dispose;
      if (dispose == PngDisposeMode.background) {
        lastImage = Image.from(lastImage)..clear(_info.backgroundColor);
      } else if (dispose == PngDisposeMode.previous) {
        lastImage = Image.from(lastImage);
      } else {
        lastImage = Image.from(lastImage);
      }

      // Convert to MS
      lastImage.frameDuration = (frame.delay * 1000).toInt();

      compositeImage(lastImage, image,
          dstX: frame.xOffset,
          dstY: frame.yOffset,
          blend: frame.blend == PngBlendMode.over
              ? BlendMode.alpha
              : BlendMode.direct);

      firstImage.addFrame(lastImage);
    }

    return firstImage;
  }

  // Process a pass of an interlaced image.
  void _processPass(InputBuffer input, Image image, int xOffset, int yOffset,
      int xStep, int yStep, int passWidth, int passHeight) {
    final channels = (_info.colorType == PngColorType.grayscaleAlpha)
        ? 2
        : (_info.colorType == PngColorType.rgb)
            ? 3
            : (_info.colorType == PngColorType.rgba)
                ? 4
                : 1;

    final pixelDepth = channels * _info.bits;
    final bpp = (pixelDepth + 7) >> 3;
    final rowBytes = (pixelDepth * passWidth + 7) >> 3;

    final inData = <Uint8List?>[null, null];

    final pixel = [0, 0, 0, 0];

    for (var srcY = 0, dstY = yOffset, ri = 0;
        srcY < passHeight;
        ++srcY, dstY += yStep, ri = 1 - ri, _progressY++) {
      final filterType = PngFilterType.values[input.readByte()];
      inData[ri] = input.readBytes(rowBytes).toUint8List();

      final row = inData[ri];
      final prevRow = inData[1 - ri];

      // Before the image is compressed, it was filtered to improve compression.
      // Reverse the filter now.
      _unfilter(filterType, bpp, row!, prevRow);

      // Scanlines are always on byte boundaries, so for bit depths < 8,
      // reset the bit stream counter.
      _resetBits();

      final rowInput = InputBuffer(row, bigEndian: true);

      final blockHeight = xStep;
      final blockWidth = xStep - xOffset;

      for (var srcX = 0, dstX = xOffset;
          srcX < passWidth;
          ++srcX, dstX += xStep) {
        _readPixel(rowInput, pixel);
        _setPixel(image.getPixel(dstX, dstY), pixel);

        if (blockWidth > 1 || blockHeight > 1) {
          for (var i = 0; i < blockHeight; ++i) {
            for (var j = 0; j < blockWidth; ++j) {
              _setPixel(image.getPixelSafe(dstX + j, dstY + i), pixel);
            }
          }
        }
      }
    }
  }

  void _process(InputBuffer input, Image image) {
    final channels = (_info.colorType == PngColorType.grayscaleAlpha)
        ? 2
        : (_info.colorType == PngColorType.rgb)
            ? 3
            : (_info.colorType == PngColorType.rgba)
                ? 4
                : 1;

    final pixelDepth = channels * _info.bits;

    final w = _info.width;
    final h = _info.height;

    final rowBytes = (w * pixelDepth + 7) >> 3;
    final bpp = (pixelDepth + 7) >> 3;

    final line = List<int>.filled(rowBytes, 0);
    final inData = [line, line];

    final pixel = [0, 0, 0, 0];

    final pIter = image.iterator..moveNext();
    for (var y = 0, ri = 0; y < h; ++y, ri = 1 - ri) {
      final filterType = PngFilterType.values[input.readByte()];
      inData[ri] = input.readBytes(rowBytes).toUint8List();

      final row = inData[ri];
      final prevRow = inData[1 - ri];

      // Before the image is compressed, it was filtered to improve compression.
      // Reverse the filter now.
      _unfilter(filterType, bpp, row, prevRow);

      // Scanlines are always on byte boundaries, so for bit depths < 8,
      // reset the bit stream counter.
      _resetBits();

      final rowInput = InputBuffer(inData[ri], bigEndian: true);

      for (var x = 0; x < w; ++x) {
        _readPixel(rowInput, pixel);
        _setPixel(pIter.current, pixel);
        pIter.moveNext();
      }
    }
  }

  void _unfilter(
      PngFilterType filterType, int bpp, List<int> row, List<int>? prevRow) {
    final rowBytes = row.length;

    switch (filterType) {
      case PngFilterType.none:
        break;
      case PngFilterType.sub:
        for (var x = bpp; x < rowBytes; ++x) {
          row[x] = (row[x] + row[x - bpp]) & 0xff;
        }
        break;
      case PngFilterType.up:
        for (var x = 0; x < rowBytes; ++x) {
          final b = prevRow != null ? prevRow[x] : 0;
          row[x] = (row[x] + b) & 0xff;
        }
        break;
      case PngFilterType.average:
        for (var x = 0; x < rowBytes; ++x) {
          final a = x < bpp ? 0 : row[x - bpp];
          final b = prevRow != null ? prevRow[x] : 0;
          row[x] = (row[x] + ((a + b) >> 1)) & 0xff;
        }
        break;
      case PngFilterType.paeth:
        for (var x = 0; x < rowBytes; ++x) {
          final a = x < bpp ? 0 : row[x - bpp];
          final b = prevRow != null ? prevRow[x] : 0;
          final c = x < bpp || prevRow == null ? 0 : prevRow[x - bpp];

          final p = a + b - c;

          final pa = (p - a).abs();
          final pb = (p - b).abs();
          final pc = (p - c).abs();

          var paeth = 0;
          if (pa <= pb && pa <= pc) {
            paeth = a;
          } else if (pb <= pc) {
            paeth = b;
          } else {
            paeth = c;
          }

          row[x] = (row[x] + paeth) & 0xff;
        }
        break;
      default:
        throw ImageException('Invalid filter value: $filterType');
    }
  }

  // Return the CRC of the bytes
  int _crc(String type, List<int> bytes) {
    final crc = getCrc32(type.codeUnits);
    return getCrc32(bytes, crc);
  }

  int _bitBuffer = 0;
  int _bitBufferLen = 0;

  void _resetBits() {
    _bitBuffer = 0;
    _bitBufferLen = 0;
  }

  // Read a number of bits from the input stream.
  int _readBits(InputBuffer input, int numBits) {
    if (numBits == 0) {
      return 0;
    }

    if (numBits == 8) {
      return input.readByte();
    }

    if (numBits == 16) {
      return input.readUint16();
    }

    // not enough buffer
    while (_bitBufferLen < numBits) {
      if (input.isEOS) {
        throw ImageException('Invalid PNG data.');
      }

      // input byte
      final octet = input.readByte();

      // concat octet
      _bitBuffer = octet << _bitBufferLen;
      _bitBufferLen += 8;
    }

    // output byte
    final mask = (numBits == 1)
        ? 1
        : (numBits == 2)
            ? 3
            : (numBits == 4)
                ? 0xf
                : (numBits == 8)
                    ? 0xff
                    : (numBits == 16)
                        ? 0xffff
                        : 0;

    final octet = (_bitBuffer >> (_bitBufferLen - numBits)) & mask;

    _bitBufferLen -= numBits;

    return octet;
  }

  // Read the next pixel from the input stream.
  void _readPixel(InputBuffer input, List<int> pixel) {
    switch (_info.colorType) {
      case PngColorType.grayscale:
        pixel[0] = _readBits(input, _info.bits);
        return;
      case PngColorType.rgb:
        pixel[0] = _readBits(input, _info.bits);
        pixel[1] = _readBits(input, _info.bits);
        pixel[2] = _readBits(input, _info.bits);
        return;
      case PngColorType.indexed:
        pixel[0] = _readBits(input, _info.bits);
        return;
      case PngColorType.grayscaleAlpha:
        pixel[0] = _readBits(input, _info.bits);
        pixel[1] = _readBits(input, _info.bits);
        return;
      case PngColorType.rgba:
        pixel[0] = _readBits(input, _info.bits);
        pixel[1] = _readBits(input, _info.bits);
        pixel[2] = _readBits(input, _info.bits);
        pixel[3] = _readBits(input, _info.bits);
        return;
    }

    throw ImageException('Invalid color type: ${_info.colorType}.');
  }

  // Get the color with the list of components.
  void _setPixel(Pixel p, List<int> raw) {
    switch (_info.colorType) {
      case PngColorType.grayscale:
        if (_info.transparency != null && _info.bits > 8) {
          final t = _info.transparency!;
          final a = ((t[0] & 0xff) << 24) | (t[1] & 0xff);
          final g = raw[0];
          p.setRgba(g, g, g, g != a ? p.maxChannelValue : 0);
          return;
        }
        p.setRgb(raw[0], 0, 0);
        return;
      case PngColorType.rgb:
        final r = raw[0];
        final g = raw[1];
        final b = raw[2];

        if (_info.transparency != null) {
          final t = _info.transparency!;
          final tr = ((t[0] & 0xff) << 8) | (t[1] & 0xff);
          final tg = ((t[2] & 0xff) << 8) | (t[3] & 0xff);
          final tb = ((t[4] & 0xff) << 8) | (t[5] & 0xff);
          if (raw[0] != tr || raw[1] != tg || raw[2] != tb) {
            p.setRgba(r, g, b, p.maxChannelValue);
            return;
          }
        }

        p.setRgb(r, g, b);
        return;
      case PngColorType.indexed:
        p.index = raw[0];
        return;
      case PngColorType.grayscaleAlpha:
        p.setRgb(raw[0], raw[1], 0);
        return;
      case PngColorType.rgba:
        p.setRgba(raw[0], raw[1], raw[2], raw[3]);
        return;
    }

    throw ImageException('Invalid color type: ${_info.colorType}.');
  }

  late InputBuffer _input;
  int _progressY = 0;
}
