import 'dart:typed_data';

import '../../color.dart';
import '../../image.dart';
import '../../image_exception.dart';
import '../../internal/internal.dart';
import '../../util/input_buffer.dart';
import 'vp8l_bit_reader.dart';
import 'vp8l_color_cache.dart';
import 'vp8l_transform.dart';
import 'webp_huffman.dart';
import 'webp_info.dart';

// WebP lossless format.
class VP8L {
  InputBuffer input;
  VP8LBitReader br;
  WebPInfo webp;
  Image? image;

  VP8L(this.input, this.webp) : br = VP8LBitReader(input);

  bool decodeHeader() {
    final signature = br.readBits(8);
    if (signature != VP8L_MAGIC_BYTE) {
      return false;
    }

    webp.format = WebPInfo.FORMAT_LOSSLESS;
    webp.width = br.readBits(14) + 1;
    webp.height = br.readBits(14) + 1;
    webp.hasAlpha = br.readBits(1) != 0;
    final version = br.readBits(3);

    if (version != VP8L_VERSION) {
      return false;
    }

    return true;
  }

  Image? decode() {
    _lastPixel = 0;

    if (!decodeHeader()) {
      return null;
    }

    _decodeImageStream(webp.width, webp.height, true);

    _allocateInternalBuffers32b();

    image = Image(webp.width, webp.height);

    if (!_decodeImageData(
        _pixels!, webp.width, webp.height, webp.height, _processRows)) {
      return null;
    }

    return image;
  }

  bool _allocateInternalBuffers32b() {
    final numPixels = webp.width * webp.height;
    // Scratch buffer corresponding to top-prediction row for transforming the
    // first row in the row-blocks. Not needed for paletted alpha.
    final cacheTopPixels = webp.width;
    // Scratch buffer for temporary BGRA storage. Not needed for paletted alpha.
    final cachePixels = webp.width * _NUM_ARGB_CACHE_ROWS;
    final totalNumPixels = numPixels + cacheTopPixels + cachePixels;

    final pixels32 = Uint32List(totalNumPixels);
    _pixels = pixels32;
    _pixels8 = Uint8List.view(pixels32.buffer);
    _argbCache = numPixels + cacheTopPixels;

    return true;
  }

  bool _allocateInternalBuffers8b() {
    final totalNumPixels = webp.width * webp.height;
    _argbCache = 0;
    // pad the byteBuffer to a multiple of 4
    final n = totalNumPixels + (4 - (totalNumPixels % 4));
    _pixels8 = Uint8List(n);
    _pixels = Uint32List.view(_pixels8.buffer);
    return true;
  }

  bool _readTransform(List<int> transformSize) {
    var ok = true;

    final type = br.readBits(2);

    // Each transform type can only be present once in the stream.
    if ((_transformsSeen & (1 << type)) != 0) {
      return false;
    }
    _transformsSeen |= (1 << type);

    final transform = VP8LTransform();
    _transforms.add(transform);

    transform.type = type;
    transform.xsize = transformSize[0];
    transform.ysize = transformSize[1];

    switch (type) {
      case VP8LTransform.PREDICTOR_TRANSFORM:
      case VP8LTransform.CROSS_COLOR_TRANSFORM:
        transform.bits = br.readBits(3) + 2;
        transform.data = _decodeImageStream(
            _subSampleSize(transform.xsize, transform.bits),
            _subSampleSize(transform.ysize, transform.bits),
            false);
        break;
      case VP8LTransform.COLOR_INDEXING_TRANSFORM:
        final numColors = br.readBits(8) + 1;
        final bits = (numColors > 16)
            ? 0
            : (numColors > 4)
                ? 1
                : (numColors > 2)
                    ? 2
                    : 3;
        transformSize[0] = _subSampleSize(transform.xsize, bits);
        transform.bits = bits;
        transform.data = _decodeImageStream(numColors, 1, false);
        ok = _expandColorMap(numColors, transform);
        break;
      case VP8LTransform.SUBTRACT_GREEN:
        break;
      default:
        throw ImageException('Invalid WebP transform type: $type');
    }

    return ok;
  }

  Uint32List? _decodeImageStream(int xsize, int ysize, bool isLevel0) {
    var transformXsize = xsize;
    var transformYsize = ysize;
    var colorCacheBits = 0;

    // Read the transforms (may recurse).
    if (isLevel0) {
      while (br.readBits(1) != 0) {
        final sizes = [transformXsize, transformYsize];
        if (!_readTransform(sizes)) {
          throw ImageException('Invalid Transform');
        }
        transformXsize = sizes[0];
        transformYsize = sizes[1];
      }
    }

    // Color cache
    if (br.readBits(1) != 0) {
      colorCacheBits = br.readBits(4);
      final ok = (colorCacheBits >= 1 && colorCacheBits <= MAX_CACHE_BITS);
      if (!ok) {
        throw ImageException('Invalid Color Cache');
      }
    }

    // Read the Huffman codes (may recurse).
    if (!_readHuffmanCodes(
        transformXsize, transformYsize, colorCacheBits, isLevel0)) {
      throw ImageException('Invalid Huffman Codes');
    }

    // Finish setting up the color-cache
    if (colorCacheBits > 0) {
      _colorCacheSize = 1 << colorCacheBits;
      _colorCache = VP8LColorCache(colorCacheBits);
    } else {
      _colorCacheSize = 0;
    }

    webp.width = transformXsize;
    webp.height = transformYsize;
    final numBits = _huffmanSubsampleBits;
    _huffmanXsize = _subSampleSize(transformXsize, numBits);
    _huffmanMask = (numBits == 0) ? ~0 : (1 << numBits) - 1;

    if (isLevel0) {
      // Reset for future DECODE_DATA_FUNC() calls.
      _lastPixel = 0;
      return null;
    }

    final totalSize = transformXsize * transformYsize;
    final data = Uint32List(totalSize);

    // Use the Huffman trees to decode the LZ77 encoded data.
    if (!_decodeImageData(
        data, transformXsize, transformYsize, transformYsize, null)) {
      throw ImageException('Failed to decode image data.');
    }

    // Reset for future DECODE_DATA_FUNC() calls.
    _lastPixel = 0;

    return data;
  }

  bool _decodeImageData(
    Uint32List data,
    int width,
    int height,
    int lastRow,
    void Function(int)? processFunc,
  ) {
    var row = _lastPixel ~/ width;
    var col = _lastPixel % width;

    var htreeGroup = _getHtreeGroupForPos(col, row);

    var src = _lastPixel;
    var lastCached = src;
    final srcEnd = width * height; // End of data
    final srcLast = width * lastRow; // Last pixel to decode

    const lenCodeLimit = NUM_LITERAL_CODES + NUM_LENGTH_CODES;
    final colorCacheLimit = lenCodeLimit + _colorCacheSize;

    final colorCache = (_colorCacheSize > 0) ? _colorCache : null;
    final mask = _huffmanMask;

    while (!br.isEOS && src < srcLast) {
      // Only update when changing tile. Note we could use this test:
      // if "((((prev_col ^ col) | prev_row ^ row)) > mask)" -> tile changed
      // but that's actually slower and needs storing the previous col/row.
      if ((col & mask) == 0) {
        htreeGroup = _getHtreeGroupForPos(col, row);
      }

      br.fillBitWindow();
      final code = htreeGroup.htrees[_GREEN].readSymbol(br);

      if (code < NUM_LITERAL_CODES) {
        // Literal
        final red = htreeGroup.htrees[_RED].readSymbol(br);
        final green = code;
        br.fillBitWindow();
        final blue = htreeGroup.htrees[_BLUE].readSymbol(br);
        final alpha = htreeGroup.htrees[_ALPHA].readSymbol(br);

        final c = getColor(blue, green, red, alpha);
        data[src] = c;

        ++src;
        ++col;

        if (col >= width) {
          col = 0;
          ++row;
          if ((row % _NUM_ARGB_CACHE_ROWS == 0) && (processFunc != null)) {
            processFunc(row);
          }

          if (colorCache != null) {
            while (lastCached < src) {
              colorCache.insert(data[lastCached]);
              lastCached++;
            }
          }
        }
      } else if (code < lenCodeLimit) {
        // Backward reference
        final lengthSym = code - NUM_LITERAL_CODES;
        final length = _getCopyLength(lengthSym);
        final distSymbol = htreeGroup.htrees[_DIST].readSymbol(br);

        br.fillBitWindow();
        final distCode = _getCopyDistance(distSymbol);
        final dist = _planeCodeToDistance(width, distCode);

        if (src < dist || srcEnd - src < length) {
          return false;
        } else {
          final dst = src - dist;
          for (var i = 0; i < length; ++i) {
            data[src + i] = data[dst + i];
          }
          src += length;
        }
        col += length;
        while (col >= width) {
          col -= width;
          ++row;
          if ((row % _NUM_ARGB_CACHE_ROWS == 0) && (processFunc != null)) {
            processFunc(row);
          }
        }
        if (src < srcLast) {
          if ((col & mask) != 0) {
            htreeGroup = _getHtreeGroupForPos(col, row);
          }
          if (colorCache != null) {
            while (lastCached < src) {
              colorCache.insert(data[lastCached]);
              lastCached++;
            }
          }
        }
      } else if (code < colorCacheLimit) {
        // Color cache
        final key = code - lenCodeLimit;

        while (lastCached < src) {
          colorCache!.insert(data[lastCached]);
          lastCached++;
        }

        data[src] = colorCache!.lookup(key);

        ++src;
        ++col;

        if (col >= width) {
          col = 0;
          ++row;
          if ((row % _NUM_ARGB_CACHE_ROWS == 0) && (processFunc != null)) {
            processFunc(row);
          }

          while (lastCached < src) {
            colorCache.insert(data[lastCached]);
            lastCached++;
          }
        }
      } else {
        // Not reached
        return false;
      }
    }

    // Process the remaining rows corresponding to last row-block.
    if (processFunc != null) {
      processFunc(row);
    }

    if (br.isEOS && src < srcEnd) {
      return false;
    }

    _lastPixel = src;

    return true;
  }

  // Row-processing for the special case when alpha data contains only one
  // transform (color indexing), and trivial non-green literals.
  bool _is8bOptimizable() {
    if (_colorCacheSize > 0) {
      return false;
    }
    // When the Huffman tree contains only one symbol, we can skip the
    // call to ReadSymbol() for red/blue/alpha channels.
    for (var i = 0; i < _numHtreeGroups; ++i) {
      final htrees = _htreeGroups[i].htrees;
      if (htrees[_RED].numNodes > 1) {
        return false;
      }
      if (htrees[_BLUE].numNodes > 1) {
        return false;
      }
      if (htrees[_ALPHA].numNodes > 1) {
        return false;
      }
    }
    return true;
  }

  // Special row-processing that only stores the alpha data.
  void _extractAlphaRows(int row) {
    final numRows = row - _lastRow;
    if (numRows <= 0) {
      return; // Nothing to be done.
    }

    _applyInverseTransforms(numRows, webp.width * _lastRow);

    // Extract alpha (which is stored in the green plane).
    final width = webp.width; // the final width (!= dec->width_)
    final cachePixs = width * numRows;

    final di = width * _lastRow;
    final src = InputBuffer(_pixels!, offset: _argbCache!);

    for (var i = 0; i < cachePixs; ++i) {
      _opaque![di + i] = (src[i] >> 8) & 0xff;
    }

    _lastRow = row;
  }

  bool _decodeAlphaData(int width, int height, int lastRow) {
    var row = _lastPixel ~/ width;
    var col = _lastPixel % width;

    var htreeGroup = _getHtreeGroupForPos(col, row);
    var pos = _lastPixel; // current position
    final end = width * height; // End of data
    final last = width * lastRow; // Last pixel to decode
    const lenCodeLimit = NUM_LITERAL_CODES + NUM_LENGTH_CODES;
    final mask = _huffmanMask;

    while (!br.isEOS && pos < last) {
      // Only update when changing tile.
      if ((col & mask) == 0) {
        htreeGroup = _getHtreeGroupForPos(col, row);
      }

      br.fillBitWindow();

      final code = htreeGroup.htrees[_GREEN].readSymbol(br);
      if (code < NUM_LITERAL_CODES) {
        // Literal
        _pixels8[pos] = code;
        ++pos;
        ++col;
        if (col >= width) {
          col = 0;
          ++row;
          if (row % _NUM_ARGB_CACHE_ROWS == 0) {
            _extractPalettedAlphaRows(row);
          }
        }
      } else if (code < lenCodeLimit) {
        // Backward reference
        final lengthSym = code - NUM_LITERAL_CODES;
        final length = _getCopyLength(lengthSym);
        final distSymbol = htreeGroup.htrees[_DIST].readSymbol(br);

        br.fillBitWindow();

        final distCode = _getCopyDistance(distSymbol);
        final dist = _planeCodeToDistance(width, distCode);

        if (pos >= dist && end - pos >= length) {
          for (var i = 0; i < length; ++i) {
            _pixels8[pos + i] = _pixels8[pos + i - dist];
          }
        } else {
          _lastPixel = pos;
          return true;
        }

        pos += length;
        col += length;

        while (col >= width) {
          col -= width;
          ++row;
          if (row % _NUM_ARGB_CACHE_ROWS == 0) {
            _extractPalettedAlphaRows(row);
          }
        }

        if (pos < last && (col & mask) != 0) {
          htreeGroup = _getHtreeGroupForPos(col, row);
        }
      } else {
        // Not reached
        return false;
      }
    }

    // Process the remaining rows corresponding to last row-block.
    _extractPalettedAlphaRows(row);

    _lastPixel = pos;

    return true;
  }

  void _extractPalettedAlphaRows(int row) {
    final numRows = row - _lastRow;
    final pIn = InputBuffer(_pixels8, offset: webp.width * _lastRow);
    if (numRows > 0) {
      _applyInverseTransformsAlpha(numRows, pIn);
    }
    _lastRow = row;
  }

  // Special method for paletted alpha data.
  void _applyInverseTransformsAlpha(int numRows, InputBuffer rows) {
    final startRow = _lastRow;
    final endRow = startRow + numRows;
    final rowsOut = InputBuffer(_opaque!, offset: _ioWidth! * startRow);
    final transform = _transforms[0];

    transform.colorIndexInverseTransformAlpha(startRow, endRow, rows, rowsOut);
  }

  // Processes (transforms, scales & color-converts) the rows decoded after the
  // last call.
  //static int __count = 0;
  void _processRows(int row) {
    final rows = webp.width * _lastRow; // offset into _pixels
    final numRows = row - _lastRow;

    if (numRows <= 0) {
      return; // Nothing to be done.
    }

    _applyInverseTransforms(numRows, rows);

    //int count = 0;
    //int di = rows;
    for (var y = 0, pi = _argbCache!, dy = _lastRow; y < numRows; ++y, ++dy) {
      for (var x = 0; x < webp.width; ++x, ++pi) {
        final c = _pixels![pi];
        final r = getRed(c);
        final g = getGreen(c);
        final b = getBlue(c);
        final a = getAlpha(c);
        // rearrange the ARGB webp color to RGBA image color.
        image!.setPixel(x, dy, getColor(b, g, r, a));
      }
    }

    _lastRow = row;
  }

  void _applyInverseTransforms(int numRows, int rows) {
    var n = _transforms.length;
    final cachePixs = webp.width * numRows;
    final startRow = _lastRow;
    final endRow = startRow + numRows;
    var rowsIn = rows;
    final rowsOut = _argbCache!;

    // Inverse transforms.
    _pixels!.setRange(rowsOut, rowsOut + cachePixs, _pixels!, rowsIn);

    while (n-- > 0) {
      final transform = _transforms[n];
      transform.inverseTransform(
          startRow, endRow, _pixels!, rowsIn, _pixels!, rowsOut);
      rowsIn = rowsOut;
    }
  }

  bool _readHuffmanCodes(
      int xsize, int ysize, int colorCacheBits, bool allowRecursion) {
    Uint32List? huffmanImage;
    var numHtreeGroups = 1;

    if (allowRecursion && br.readBits(1) != 0) {
      // use meta Huffman codes.
      final huffmanPrecision = br.readBits(3) + 2;
      final huffmanXsize = _subSampleSize(xsize, huffmanPrecision);
      final huffmanYsize = _subSampleSize(ysize, huffmanPrecision);
      final huffmanPixs = huffmanXsize * huffmanYsize;

      huffmanImage = _decodeImageStream(huffmanXsize, huffmanYsize, false);

      _huffmanSubsampleBits = huffmanPrecision;

      for (var i = 0; i < huffmanPixs; ++i) {
        // The huffman data is stored in red and green bytes.
        final group = (huffmanImage![i] >> 8) & 0xffff;
        huffmanImage[i] = group;
        if (group >= numHtreeGroups) {
          numHtreeGroups = group + 1;
        }
      }
    }

    assert(numHtreeGroups <= 0x10000);

    final htreeGroups = List<HTreeGroup>.generate(
        numHtreeGroups, (_) => HTreeGroup(),
        growable: false);
    for (var i = 0; i < numHtreeGroups; ++i) {
      for (var j = 0; j < HUFFMAN_CODES_PER_META_CODE; ++j) {
        var alphabetSize = ALPHABET_SIZE[j];
        if (j == 0 && colorCacheBits > 0) {
          alphabetSize += 1 << colorCacheBits;
        }

        if (!_readHuffmanCode(alphabetSize, htreeGroups[i].htrees[j])) {
          return false;
        }
      }
    }

    // All OK. Finalize pointers and return.
    _huffmanImage = huffmanImage;
    _numHtreeGroups = numHtreeGroups;
    _htreeGroups = htreeGroups;

    return true;
  }

  bool _readHuffmanCode(int alphabetSize, HuffmanTree tree) {
    var ok = false;
    final simpleCode = br.readBits(1);

    // Read symbols, codes & code lengths directly.
    if (simpleCode != 0) {
      final symbols = [0, 0];
      final codes = [0, 0];
      final codeLengths = [0, 0];

      final numSymbols = br.readBits(1) + 1;
      final firstSymbolLenCode = br.readBits(1);

      // The first code is either 1 bit or 8 bit code.
      symbols[0] = br.readBits((firstSymbolLenCode == 0) ? 1 : 8);
      codes[0] = 0;
      codeLengths[0] = numSymbols - 1;

      // The second code (if present), is always 8 bit long.
      if (numSymbols == 2) {
        symbols[1] = br.readBits(8);
        codes[1] = 1;
        codeLengths[1] = numSymbols - 1;
      }

      ok = tree.buildExplicit(
          codeLengths, codes, symbols, alphabetSize, numSymbols);
    } else {
      // Decode Huffman-coded code lengths.
      final codeLengthCodeLengths = Int32List(_NUM_CODE_LENGTH_CODES);

      final numCodes = br.readBits(4) + 4;
      if (numCodes > _NUM_CODE_LENGTH_CODES) {
        return false;
      }

      final codeLengths = Int32List(alphabetSize);

      for (var i = 0; i < numCodes; ++i) {
        codeLengthCodeLengths[_CODE_LENGTH_CODE_ORDER[i]] = br.readBits(3);
      }

      ok = _readHuffmanCodeLengths(
          codeLengthCodeLengths, alphabetSize, codeLengths);

      if (ok) {
        ok = tree.buildImplicit(codeLengths, alphabetSize);
      }
    }

    return ok;
  }

  bool _readHuffmanCodeLengths(
      List<int> codeLengthCodeLengths, int numSymbols, List<int> codeLengths) {
    //bool ok = false;
    int symbol;
    int max_symbol;
    var prev_code_len = DEFAULT_CODE_LENGTH;
    final tree = HuffmanTree();

    if (!tree.buildImplicit(codeLengthCodeLengths, _NUM_CODE_LENGTH_CODES)) {
      return false;
    }

    if (br.readBits(1) != 0) {
      // use length
      final length_nbits = 2 + 2 * br.readBits(3);
      max_symbol = 2 + br.readBits(length_nbits);
      if (max_symbol > numSymbols) {
        return false;
      }
    } else {
      max_symbol = numSymbols;
    }

    symbol = 0;
    while (symbol < numSymbols) {
      int code_len;
      if (max_symbol-- == 0) {
        break;
      }

      br.fillBitWindow();

      code_len = tree.readSymbol(br);

      if (code_len < _CODE_LENGTH_LITERALS) {
        codeLengths[symbol++] = code_len;
        if (code_len != 0) {
          prev_code_len = code_len;
        }
      } else {
        final usePrev = (code_len == _CODE_LENGTH_REPEAT_CODE);
        final slot = code_len - _CODE_LENGTH_LITERALS;
        final extra_bits = _CODE_LENGTH_EXTRA_BITS[slot];
        final repeat_offset = _CODE_LENGTH_REPEAT_OFFSETS[slot];
        var repeat = br.readBits(extra_bits) + repeat_offset;

        if (symbol + repeat > numSymbols) {
          return false;
        } else {
          final length = usePrev ? prev_code_len : 0;
          while (repeat-- > 0) {
            codeLengths[symbol++] = length;
          }
        }
      }
    }

    return true;
  }

  int _getCopyDistance(int distanceSymbol) {
    if (distanceSymbol < 4) {
      return distanceSymbol + 1;
    }
    final extraBits = (distanceSymbol - 2) >> 1;
    final offset = (2 + (distanceSymbol & 1)) << extraBits;
    return offset + br.readBits(extraBits) + 1;
  }

  int _getCopyLength(int lengthSymbol) => _getCopyDistance(lengthSymbol);

  int _planeCodeToDistance(int xsize, int planeCode) {
    if (planeCode > _CODE_TO_PLANE_CODES) {
      return planeCode - _CODE_TO_PLANE_CODES;
    } else {
      final distCode = _CODE_TO_PLANE[planeCode - 1];
      final yoffset = distCode >> 4;
      final xoffset = 8 - (distCode & 0xf);
      final dist = yoffset * xsize + xoffset;
      // dist<1 can happen if xsize is very small
      return (dist >= 1) ? dist : 1;
    }
  }

  // Computes sampled size of 'size' when sampling using 'sampling bits'.
  static int _subSampleSize(int size, int samplingBits) =>
      (size + (1 << samplingBits) - 1) >> samplingBits;

  // For security reason, we need to remap the color map to span
  // the total possible bundled values, and not just the num_colors.
  bool _expandColorMap(int numColors, VP8LTransform transform) {
    final finalNumColors = 1 << (8 >> transform.bits);
    final newColorMap = Uint32List(finalNumColors);
    final data = Uint8List.view(transform.data!.buffer);
    final newData = Uint8List.view(newColorMap.buffer);

    newColorMap[0] = transform.data![0];

    var len = 4 * numColors;

    int i;
    for (i = 4; i < len; ++i) {
      // Equivalent to AddPixelEq(), on a byte-basis.
      newData[i] = (data[i] + newData[i - 4]) & 0xff;
    }

    for (len = 4 * finalNumColors; i < len; ++i) {
      newData[i] = 0;
    }

    transform.data = newColorMap;

    return true;
  }

  int _getMetaIndex(Uint32List? image, int xsize, int bits, int x, int y) {
    if (bits == 0) {
      return 0;
    }
    return image![xsize * (y >> bits) + (x >> bits)];
  }

  HTreeGroup _getHtreeGroupForPos(int x, int y) {
    final metaIndex = _getMetaIndex(
        _huffmanImage, _huffmanXsize, _huffmanSubsampleBits, x, y);
    return _htreeGroups[metaIndex];
  }

  static const _GREEN = 0;
  static const _RED = 1;
  static const _BLUE = 2;
  static const _ALPHA = 3;
  static const _DIST = 4;

  static const _NUM_ARGB_CACHE_ROWS = 16;

  static const _NUM_CODE_LENGTH_CODES = 19;

  static const _CODE_LENGTH_CODE_ORDER = <int>[
    17,
    18,
    0,
    1,
    2,
    3,
    4,
    5,
    16,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15
  ];

  static const _CODE_TO_PLANE_CODES = 120;
  static const _CODE_TO_PLANE = <int>[
    0x18,
    0x07,
    0x17,
    0x19,
    0x28,
    0x06,
    0x27,
    0x29,
    0x16,
    0x1a,
    0x26,
    0x2a,
    0x38,
    0x05,
    0x37,
    0x39,
    0x15,
    0x1b,
    0x36,
    0x3a,
    0x25,
    0x2b,
    0x48,
    0x04,
    0x47,
    0x49,
    0x14,
    0x1c,
    0x35,
    0x3b,
    0x46,
    0x4a,
    0x24,
    0x2c,
    0x58,
    0x45,
    0x4b,
    0x34,
    0x3c,
    0x03,
    0x57,
    0x59,
    0x13,
    0x1d,
    0x56,
    0x5a,
    0x23,
    0x2d,
    0x44,
    0x4c,
    0x55,
    0x5b,
    0x33,
    0x3d,
    0x68,
    0x02,
    0x67,
    0x69,
    0x12,
    0x1e,
    0x66,
    0x6a,
    0x22,
    0x2e,
    0x54,
    0x5c,
    0x43,
    0x4d,
    0x65,
    0x6b,
    0x32,
    0x3e,
    0x78,
    0x01,
    0x77,
    0x79,
    0x53,
    0x5d,
    0x11,
    0x1f,
    0x64,
    0x6c,
    0x42,
    0x4e,
    0x76,
    0x7a,
    0x21,
    0x2f,
    0x75,
    0x7b,
    0x31,
    0x3f,
    0x63,
    0x6d,
    0x52,
    0x5e,
    0x00,
    0x74,
    0x7c,
    0x41,
    0x4f,
    0x10,
    0x20,
    0x62,
    0x6e,
    0x30,
    0x73,
    0x7d,
    0x51,
    0x5f,
    0x40,
    0x72,
    0x7e,
    0x61,
    0x6f,
    0x50,
    0x71,
    0x7f,
    0x60,
    0x70
  ];

  static const _CODE_LENGTH_LITERALS = 16;
  static const _CODE_LENGTH_REPEAT_CODE = 16;
  static const List<int> _CODE_LENGTH_EXTRA_BITS = [2, 3, 7];
  static const List<int> _CODE_LENGTH_REPEAT_OFFSETS = [3, 3, 11];

  static const List<int> ALPHABET_SIZE = [
    NUM_LITERAL_CODES + NUM_LENGTH_CODES,
    NUM_LITERAL_CODES,
    NUM_LITERAL_CODES,
    NUM_LITERAL_CODES,
    NUM_DISTANCE_CODES
  ];

  static const VP8L_MAGIC_BYTE = 0x2f;
  static const VP8L_VERSION = 0;

  int _lastPixel = 0;
  int _lastRow = 0;

  int _colorCacheSize = 0;
  VP8LColorCache? _colorCache;

  int _huffmanMask = 0;
  int _huffmanSubsampleBits = 0;
  int _huffmanXsize = 0;
  Uint32List? _huffmanImage;
  int _numHtreeGroups = 0;
  List<HTreeGroup> _htreeGroups = [];
  final List<VP8LTransform> _transforms = [];
  int _transformsSeen = 0;

  Uint32List? _pixels;
  late Uint8List _pixels8;
  int? _argbCache;

  Uint8List? _opaque;

  int? _ioWidth;
  int? _ioHeight;

  static const ARGB_BLACK = 0xff000000;
  static const MAX_CACHE_BITS = 11;
  static const HUFFMAN_CODES_PER_META_CODE = 5;

  static const DEFAULT_CODE_LENGTH = 8;
  static const MAX_ALLOWED_CODE_LENGTH = 15;

  static const NUM_LITERAL_CODES = 256;
  static const NUM_LENGTH_CODES = 24;
  static const NUM_DISTANCE_CODES = 40;
  static const CODE_LENGTH_CODES = 19;
}

@internal
class InternalVP8L extends VP8L {
  InternalVP8L(InputBuffer input, WebPInfo webp) : super(input, webp);

  List<VP8LTransform> get transforms => _transforms;

  Uint32List? get pixels => _pixels;

  Uint8List? get opaque => _opaque;

  set opaque(Uint8List? value) => _opaque = value;

  int? get ioWidth => _ioWidth;

  set ioWidth(int? width) => _ioWidth = width;

  int? get ioHeight => _ioHeight;

  set ioHeight(int? height) => _ioHeight = height;

  bool decodeImageData(Uint32List data, int width, int height, int lastRow,
          void Function(int) processFunc) =>
      _decodeImageData(data, width, height, lastRow, processFunc);

  Uint32List? decodeImageStream(int xsize, int ysize, bool isLevel0) =>
      _decodeImageStream(xsize, ysize, isLevel0);

  bool allocateInternalBuffers32b() => _allocateInternalBuffers32b();

  bool allocateInternalBuffers8b() => _allocateInternalBuffers8b();

  bool decodeAlphaData(int width, int height, int lastRow) =>
      _decodeAlphaData(width, height, lastRow);

  bool is8bOptimizable() => _is8bOptimizable();

  void extractAlphaRows(int row) => _extractAlphaRows(row);

  static int subSampleSize(int size, int samplingBits) =>
      VP8L._subSampleSize(size, samplingBits);
}
