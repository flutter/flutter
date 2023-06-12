import 'dart:typed_data';

import '../../../image.dart';
import '_component_data.dart';
import 'jpeg_quantize_stub.dart'
    if (dart.library.io) '_jpeg_quantize_io.dart'
    if (dart.library.js) '_jpeg_quantize_html.dart';

class JpegData {
  late InputBuffer input;
  late JpegJfif jfif;
  JpegAdobe? adobe;
  JpegFrame? frame;
  int? resetInterval;
  String? comment;
  final exif = ExifData();
  final quantizationTables = List<Int16List?>.filled(Jpeg.NUM_QUANT_TBLS, null);
  final frames = <JpegFrame?>[];
  final huffmanTablesAC = <List?>[];
  final huffmanTablesDC = <List?>[];
  final components = <ComponentData>[];

  bool validate(List<int> bytes) {
    input = InputBuffer(bytes, bigEndian: true);

    // Some other formats have embedded jpeg, or jpeg-like data.
    // Only validate if the image starts with the StartOfImage tag.
    final soiCheck = input.peekBytes(2);
    if (soiCheck[0] != 0xff || soiCheck[1] != 0xd8) {
      return false;
    }

    var marker = _nextMarker();
    if (marker != Jpeg.M_SOI) {
      return false;
    }

    var hasSOF = false;
    var hasSOS = false;

    marker = _nextMarker();
    while (marker != Jpeg.M_EOI && !input.isEOS) {
      // EOI (End of image)
      final sectionByteSize = input.readUint16();
      if (sectionByteSize < 2) {
        // jpeg section consists of more than 2 bytes at least
        // return success only when SOF and SOS have already found (as a jpeg without EOF.)
        break;
      }
      input.offset += sectionByteSize - 2;

      switch (marker) {
        case Jpeg.M_SOF0: // SOF0 (Start of Frame, Baseline DCT)
        case Jpeg.M_SOF1: // SOF1 (Start of Frame, Extended DCT)
        case Jpeg.M_SOF2: // SOF2 (Start of Frame, Progressive DCT)
          hasSOF = true;
          break;
        case Jpeg.M_SOS: // SOS (Start of Scan)
          hasSOS = true;
          break;
        default:
      }

      marker = _nextMarker();
    }

    return hasSOF && hasSOS;
  }

  JpegInfo? readInfo(List<int> bytes) {
    input = InputBuffer(bytes, bigEndian: true);

    var marker = _nextMarker();
    if (marker != Jpeg.M_SOI) {
      return null;
    }

    final info = JpegInfo();

    var hasSOF = false;
    var hasSOS = false;

    marker = _nextMarker();
    while (marker != Jpeg.M_EOI && !input.isEOS) {
      // EOI (End of image)
      switch (marker) {
        case Jpeg.M_SOF0: // SOF0 (Start of Frame, Baseline DCT)
        case Jpeg.M_SOF1: // SOF1 (Start of Frame, Extended DCT)
        case Jpeg.M_SOF2: // SOF2 (Start of Frame, Progressive DCT)
          hasSOF = true;
          _readFrame(marker, _readBlock());
          break;
        case Jpeg.M_SOS: // SOS (Start of Scan)
          hasSOS = true;
          _skipBlock();
          break;
        default:
          _skipBlock();
          break;
      }

      marker = _nextMarker();
    }

    if (frame != null) {
      info.width = frame!.samplesPerLine!;
      info.height = frame!.scanLines!;
    }
    frame = null;
    frames.clear();

    return (hasSOF && hasSOS) ? info : null;
  }

  void read(List<int> bytes) {
    input = InputBuffer(bytes, bigEndian: true);
    _read();

    if (frames.length != 1) {
      throw ImageException('Only single frame JPEGs supported');
    }

    for (var i = 0; i < frame!.componentsOrder.length; ++i) {
      final component = frame!.components[frame!.componentsOrder[i]]!;
      components.add(ComponentData(
          component.hSamples,
          frame!.maxHSamples,
          component.vSamples,
          frame!.maxVSamples,
          _buildComponentData(frame, component)));
    }
  }

  int? get width => frame!.samplesPerLine;

  int? get height => frame!.scanLines;

  Image getImage() => getImageFromJpeg(this);

  void _read() {
    var marker = _nextMarker();
    if (marker != Jpeg.M_SOI) {
      // SOI (Start of Image)
      throw ImageException('Start Of Image marker not found.');
    }

    marker = _nextMarker();
    while (marker != Jpeg.M_EOI && !input.isEOS) {
      final block = _readBlock();
      switch (marker) {
        case Jpeg.M_APP0:
        case Jpeg.M_APP1:
        case Jpeg.M_APP2:
        case Jpeg.M_APP3:
        case Jpeg.M_APP4:
        case Jpeg.M_APP5:
        case Jpeg.M_APP6:
        case Jpeg.M_APP7:
        case Jpeg.M_APP8:
        case Jpeg.M_APP9:
        case Jpeg.M_APP10:
        case Jpeg.M_APP11:
        case Jpeg.M_APP12:
        case Jpeg.M_APP13:
        case Jpeg.M_APP14:
        case Jpeg.M_APP15:
        case Jpeg.M_COM:
          _readAppData(marker, block);
          break;

        case Jpeg.M_DQT: // DQT (Define Quantization Tables)
          _readDQT(block);
          break;

        case Jpeg.M_SOF0: // SOF0 (Start of Frame, Baseline DCT)
        case Jpeg.M_SOF1: // SOF1 (Start of Frame, Extended DCT)
        case Jpeg.M_SOF2: // SOF2 (Start of Frame, Progressive DCT)
          _readFrame(marker, block);
          break;

        case Jpeg.M_SOF3:
        case Jpeg.M_SOF5:
        case Jpeg.M_SOF6:
        case Jpeg.M_SOF7:
        case Jpeg.M_JPG:
        case Jpeg.M_SOF9:
        case Jpeg.M_SOF10:
        case Jpeg.M_SOF11:
        case Jpeg.M_SOF13:
        case Jpeg.M_SOF14:
        case Jpeg.M_SOF15:
          throw ImageException(
              'Unhandled frame type ${marker.toRadixString(16)}');

        case Jpeg.M_DHT: // DHT (Define Huffman Tables)
          _readDHT(block);
          break;

        case Jpeg.M_DRI: // DRI (Define Restart Interval)
          _readDRI(block);
          break;

        case Jpeg.M_SOS: // SOS (Start of Scan)
          _readSOS(block);
          break;

        case 0xff: // Fill bytes
          if (input[0] != 0xff) {
            input.offset--;
          }
          break;

        default:
          if (input[-3] == 0xff && input[-2] >= 0xc0 && input[-2] <= 0xfe) {
            // could be incorrect encoding -- last 0xFF byte of the previous
            // block was eaten by the encoder
            input.offset -= 3;
            break;
          }

          if (marker != 0) {
            throw ImageException(
                'Unknown JPEG marker ${marker.toRadixString(16)}');
          }
          break;
      }

      marker = _nextMarker();
    }
  }

  void _skipBlock() {
    final length = input.readUint16();
    if (length < 2) {
      throw ImageException('Invalid Block');
    }
    input.offset += length - 2;
  }

  InputBuffer _readBlock() {
    final length = input.readUint16();
    if (length < 2) {
      throw ImageException('Invalid Block');
    }
    return input.readBytes(length - 2);
  }

  int _nextMarker() {
    var c = 0;
    if (input.isEOS) {
      return c;
    }

    do {
      do {
        c = input.readByte();
      } while (c != 0xff && !input.isEOS);

      if (input.isEOS) {
        return c;
      }

      do {
        c = input.readByte();
      } while (c == 0xff && !input.isEOS);
    } while (c == 0 && !input.isEOS);

    return c;
  }

  void _readExifData(InputBuffer block) {
    // Exif Header
    const exifSignature = 0x45786966; // Exif\0\0
    final signature = block.readUint32();
    if (signature != exifSignature) {
      return;
    }
    if (block.readUint16() != 0) {
      return;
    }

    exif.read(block);
  }

  void _readAppData(int marker, InputBuffer block) {
    final appData = block;

    if (marker == Jpeg.M_APP0) {
      // 'JFIF\0'
      if (appData[0] == 0x4A &&
          appData[1] == 0x46 &&
          appData[2] == 0x49 &&
          appData[3] == 0x46 &&
          appData[4] == 0) {
        jfif = JpegJfif();
        jfif.majorVersion = appData[5];
        jfif.minorVersion = appData[6];
        jfif.densityUnits = appData[7];
        jfif.xDensity = (appData[8] << 8) | appData[9];
        jfif.yDensity = (appData[10] << 8) | appData[11];
        jfif.thumbWidth = appData[12];
        jfif.thumbHeight = appData[13];
        final thumbSize = 3 * jfif.thumbWidth * jfif.thumbHeight;
        jfif.thumbData = appData.subset(14 + thumbSize, offset: 14);
      }
    } else if (marker == Jpeg.M_APP1) {
      // 'EXIF\0'
      _readExifData(appData);
    } else if (marker == Jpeg.M_APP14) {
      // 'Adobe\0'
      if (appData[0] == 0x41 &&
          appData[1] == 0x64 &&
          appData[2] == 0x6F &&
          appData[3] == 0x62 &&
          appData[4] == 0x65 &&
          appData[5] == 0) {
        adobe = JpegAdobe();
        adobe!.version = appData[6];
        adobe!.flags0 = (appData[7] << 8) | appData[8];
        adobe!.flags1 = (appData[9] << 8) | appData[10];
        adobe!.transformCode = appData[11];
      }
    } else if (marker == Jpeg.M_COM) {
      // Comment
      try {
        comment = appData.readStringUtf8();
      } catch (e, _) {
        // readString without 0x00 terminator causes exception. Technically
        // bad data, but no reason to abort the rest of the image decoding.
      }
    }
  }

  void _readDQT(InputBuffer block) {
    while (!block.isEOS) {
      var n = block.readByte();
      final prec = (n >> 4);
      n &= 0x0F;

      if (n >= Jpeg.NUM_QUANT_TBLS) {
        throw ImageException('Invalid number of quantization tables');
      }

      if (quantizationTables[n] == null) {
        quantizationTables[n] = Int16List(64);
      }

      final tableData = quantizationTables[n];
      for (var i = 0; i < Jpeg.DCTSIZE2; i++) {
        int tmp;
        if (prec != 0) {
          tmp = block.readUint16();
        } else {
          tmp = block.readByte();
        }

        tableData![Jpeg.dctZigZag[i]] = tmp;
      }
    }

    if (!block.isEOS) {
      throw ImageException('Bad length for DQT block');
    }
  }

  void _readFrame(int marker, InputBuffer block) {
    if (frame != null) {
      throw ImageException('Duplicate JPG frame data found.');
    }

    frame = JpegFrame();
    frame!.extended = (marker == Jpeg.M_SOF1);
    frame!.progressive = (marker == Jpeg.M_SOF2);
    frame!.precision = block.readByte();
    frame!.scanLines = block.readUint16();
    frame!.samplesPerLine = block.readUint16();

    final numComponents = block.readByte();

    for (var i = 0; i < numComponents; i++) {
      final componentId = block.readByte();
      final x = block.readByte();
      final h = (x >> 4) & 15;
      final v = x & 15;
      final qId = block.readByte();
      frame!.componentsOrder.add(componentId);
      frame!.components[componentId] =
          JpegComponent(h, v, quantizationTables, qId);
    }

    frame!.prepare();
    frames.add(frame);
  }

  void _readDHT(InputBuffer block) {
    while (!block.isEOS) {
      var index = block.readByte();

      final bits = Uint8List(16);
      var count = 0;
      for (var j = 0; j < 16; j++) {
        bits[j] = block.readByte();
        count += bits[j];
      }

      final huffmanValues = Uint8List(count);
      for (var j = 0; j < count; j++) {
        huffmanValues[j] = block.readByte();
      }

      List ht;
      if (index & 0x10 != 0) {
        // AC table definition
        index -= 0x10;
        ht = huffmanTablesAC;
      } else {
        // DC table definition
        ht = huffmanTablesDC;
      }

      if (ht.length <= index) {
        ht.length = index + 1;
      }

      ht[index] = _buildHuffmanTable(bits, huffmanValues);
    }
  }

  void _readDRI(InputBuffer block) {
    resetInterval = block.readUint16();
  }

  void _readSOS(InputBuffer block) {
    final n = block.readByte();
    if (n < 1 || n > Jpeg.MAX_COMPS_IN_SCAN) {
      throw ImageException('Invalid SOS block');
    }

    final components = List<JpegComponent>.generate(n, (i) {
      final id = block.readByte();
      final c = block.readByte();

      if (!frame!.components.containsKey(id)) {
        throw ImageException('Invalid Component in SOS block');
      }

      final component = frame!.components[id]!;

      final dc_tbl_no = (c >> 4) & 15;
      final ac_tbl_no = c & 15;

      if (dc_tbl_no < huffmanTablesDC.length) {
        component.huffmanTableDC = huffmanTablesDC[dc_tbl_no]!;
      }
      if (ac_tbl_no < huffmanTablesAC.length) {
        component.huffmanTableAC = huffmanTablesAC[ac_tbl_no]!;
      }

      return component;
    });

    final spectralStart = block.readByte();
    final spectralEnd = block.readByte();
    final successiveApproximation = block.readByte();

    final Ah = (successiveApproximation >> 4) & 15;
    final Al = successiveApproximation & 15;

    JpegScan(input, frame!, components, resetInterval, spectralStart,
            spectralEnd, Ah, Al)
        .decode();
  }

  List? _buildHuffmanTable(Uint8List codeLengths, Uint8List values) {
    var k = 0;
    final code = <_JpegHuffman>[];
    var length = 16;

    while (length > 0 && (codeLengths[length - 1] == 0)) {
      length--;
    }

    code.add(_JpegHuffman());

    var p = code[0];
    _JpegHuffman q;

    for (var i = 0; i < length; i++) {
      for (var j = 0; j < codeLengths[i]; j++) {
        p = code.removeLast();
        if (p.children.length <= p.index) {
          p.children.length = p.index + 1;
        }
        p.children[p.index] = values[k];
        while (p.index > 0) {
          p = code.removeLast();
        }
        p.index++;
        code.add(p);
        while (code.length <= i) {
          q = _JpegHuffman();
          code.add(q);
          if (p.children.length <= p.index) {
            p.children.length = p.index + 1;
          }
          p.children[p.index] = q.children;
          p = q;
        }
        k++;
      }

      if ((i + 1) < length) {
        // p here points to last code
        q = _JpegHuffman();
        code.add(q);
        if (p.children.length <= p.index) {
          p.children.length = p.index + 1;
        }
        p.children[p.index] = q.children;
        p = q;
      }
    }

    return code[0].children;
  }

  List<Uint8List?> _buildComponentData(
      JpegFrame? frame, JpegComponent component) {
    final blocksPerLine = component.blocksPerLine;
    final blocksPerColumn = component.blocksPerColumn;
    final samplesPerLine = (blocksPerLine << 3);
    final R = Int32List(64);
    final r = Uint8List(64);
    final lines = List<Uint8List?>.filled(blocksPerColumn * 8, null);

    var l = 0;
    for (var blockRow = 0; blockRow < blocksPerColumn; blockRow++) {
      final scanLine = (blockRow << 3);
      for (var i = 0; i < 8; i++) {
        lines[l++] = Uint8List(samplesPerLine);
      }

      for (var blockCol = 0; blockCol < blocksPerLine; blockCol++) {
        quantizeAndInverse(component.quantizationTable!,
            component.blocks[blockRow][blockCol] as Int32List, r, R);

        var offset = 0;
        final sample = (blockCol << 3);
        for (var j = 0; j < 8; j++) {
          final line = lines[scanLine + j];
          for (var i = 0; i < 8; i++) {
            line![sample + i] = r[offset++];
          }
        }
      }
    }

    return lines;
  }

  static int toFix(double val) {
    const FIXED_POINT = 20;
    const ONE = 1 << FIXED_POINT;
    return (val * ONE).toInt() & 0xffffffff;
  }

  static const CRR = [
    -179,
    -178,
    -177,
    -175,
    -174,
    -172,
    -171,
    -170,
    -168,
    -167,
    -165,
    -164,
    -163,
    -161,
    -160,
    -158,
    -157,
    -156,
    -154,
    -153,
    -151,
    -150,
    -149,
    -147,
    -146,
    -144,
    -143,
    -142,
    -140,
    -139,
    -137,
    -136,
    -135,
    -133,
    -132,
    -130,
    -129,
    -128,
    -126,
    -125,
    -123,
    -122,
    -121,
    -119,
    -118,
    -116,
    -115,
    -114,
    -112,
    -111,
    -109,
    -108,
    -107,
    -105,
    -104,
    -102,
    -101,
    -100,
    -98,
    -97,
    -95,
    -94,
    -93,
    -91,
    -90,
    -88,
    -87,
    -86,
    -84,
    -83,
    -81,
    -80,
    -79,
    -77,
    -76,
    -74,
    -73,
    -72,
    -70,
    -69,
    -67,
    -66,
    -64,
    -63,
    -62,
    -60,
    -59,
    -57,
    -56,
    -55,
    -53,
    -52,
    -50,
    -49,
    -48,
    -46,
    -45,
    -43,
    -42,
    -41,
    -39,
    -38,
    -36,
    -35,
    -34,
    -32,
    -31,
    -29,
    -28,
    -27,
    -25,
    -24,
    -22,
    -21,
    -20,
    -18,
    -17,
    -15,
    -14,
    -13,
    -11,
    -10,
    -8,
    -7,
    -6,
    -4,
    -3,
    -1,
    0,
    1,
    3,
    4,
    6,
    7,
    8,
    10,
    11,
    13,
    14,
    15,
    17,
    18,
    20,
    21,
    22,
    24,
    25,
    27,
    28,
    29,
    31,
    32,
    34,
    35,
    36,
    38,
    39,
    41,
    42,
    43,
    45,
    46,
    48,
    49,
    50,
    52,
    53,
    55,
    56,
    57,
    59,
    60,
    62,
    63,
    64,
    66,
    67,
    69,
    70,
    72,
    73,
    74,
    76,
    77,
    79,
    80,
    81,
    83,
    84,
    86,
    87,
    88,
    90,
    91,
    93,
    94,
    95,
    97,
    98,
    100,
    101,
    102,
    104,
    105,
    107,
    108,
    109,
    111,
    112,
    114,
    115,
    116,
    118,
    119,
    121,
    122,
    123,
    125,
    126,
    128,
    129,
    130,
    132,
    133,
    135,
    136,
    137,
    139,
    140,
    142,
    143,
    144,
    146,
    147,
    149,
    150,
    151,
    153,
    154,
    156,
    157,
    158,
    160,
    161,
    163,
    164,
    165,
    167,
    168,
    170,
    171,
    172,
    174,
    175,
    177,
    178
  ];

  static const CRG = [
    5990656,
    5943854,
    5897052,
    5850250,
    5803448,
    5756646,
    5709844,
    5663042,
    5616240,
    5569438,
    5522636,
    5475834,
    5429032,
    5382230,
    5335428,
    5288626,
    5241824,
    5195022,
    5148220,
    5101418,
    5054616,
    5007814,
    4961012,
    4914210,
    4867408,
    4820606,
    4773804,
    4727002,
    4680200,
    4633398,
    4586596,
    4539794,
    4492992,
    4446190,
    4399388,
    4352586,
    4305784,
    4258982,
    4212180,
    4165378,
    4118576,
    4071774,
    4024972,
    3978170,
    3931368,
    3884566,
    3837764,
    3790962,
    3744160,
    3697358,
    3650556,
    3603754,
    3556952,
    3510150,
    3463348,
    3416546,
    3369744,
    3322942,
    3276140,
    3229338,
    3182536,
    3135734,
    3088932,
    3042130,
    2995328,
    2948526,
    2901724,
    2854922,
    2808120,
    2761318,
    2714516,
    2667714,
    2620912,
    2574110,
    2527308,
    2480506,
    2433704,
    2386902,
    2340100,
    2293298,
    2246496,
    2199694,
    2152892,
    2106090,
    2059288,
    2012486,
    1965684,
    1918882,
    1872080,
    1825278,
    1778476,
    1731674,
    1684872,
    1638070,
    1591268,
    1544466,
    1497664,
    1450862,
    1404060,
    1357258,
    1310456,
    1263654,
    1216852,
    1170050,
    1123248,
    1076446,
    1029644,
    982842,
    936040,
    889238,
    842436,
    795634,
    748832,
    702030,
    655228,
    608426,
    561624,
    514822,
    468020,
    421218,
    374416,
    327614,
    280812,
    234010,
    187208,
    140406,
    93604,
    46802,
    0,
    -46802,
    -93604,
    -140406,
    -187208,
    -234010,
    -280812,
    -327614,
    -374416,
    -421218,
    -468020,
    -514822,
    -561624,
    -608426,
    -655228,
    -702030,
    -748832,
    -795634,
    -842436,
    -889238,
    -936040,
    -982842,
    -1029644,
    -1076446,
    -1123248,
    -1170050,
    -1216852,
    -1263654,
    -1310456,
    -1357258,
    -1404060,
    -1450862,
    -1497664,
    -1544466,
    -1591268,
    -1638070,
    -1684872,
    -1731674,
    -1778476,
    -1825278,
    -1872080,
    -1918882,
    -1965684,
    -2012486,
    -2059288,
    -2106090,
    -2152892,
    -2199694,
    -2246496,
    -2293298,
    -2340100,
    -2386902,
    -2433704,
    -2480506,
    -2527308,
    -2574110,
    -2620912,
    -2667714,
    -2714516,
    -2761318,
    -2808120,
    -2854922,
    -2901724,
    -2948526,
    -2995328,
    -3042130,
    -3088932,
    -3135734,
    -3182536,
    -3229338,
    -3276140,
    -3322942,
    -3369744,
    -3416546,
    -3463348,
    -3510150,
    -3556952,
    -3603754,
    -3650556,
    -3697358,
    -3744160,
    -3790962,
    -3837764,
    -3884566,
    -3931368,
    -3978170,
    -4024972,
    -4071774,
    -4118576,
    -4165378,
    -4212180,
    -4258982,
    -4305784,
    -4352586,
    -4399388,
    -4446190,
    -4492992,
    -4539794,
    -4586596,
    -4633398,
    -4680200,
    -4727002,
    -4773804,
    -4820606,
    -4867408,
    -4914210,
    -4961012,
    -5007814,
    -5054616,
    -5101418,
    -5148220,
    -5195022,
    -5241824,
    -5288626,
    -5335428,
    -5382230,
    -5429032,
    -5475834,
    -5522636,
    -5569438,
    -5616240,
    -5663042,
    -5709844,
    -5756646,
    -5803448,
    -5850250,
    -5897052,
    -5943854
  ];

  static const CBG = [
    2919680,
    2897126,
    2874572,
    2852018,
    2829464,
    2806910,
    2784356,
    2761802,
    2739248,
    2716694,
    2694140,
    2671586,
    2649032,
    2626478,
    2603924,
    2581370,
    2558816,
    2536262,
    2513708,
    2491154,
    2468600,
    2446046,
    2423492,
    2400938,
    2378384,
    2355830,
    2333276,
    2310722,
    2288168,
    2265614,
    2243060,
    2220506,
    2197952,
    2175398,
    2152844,
    2130290,
    2107736,
    2085182,
    2062628,
    2040074,
    2017520,
    1994966,
    1972412,
    1949858,
    1927304,
    1904750,
    1882196,
    1859642,
    1837088,
    1814534,
    1791980,
    1769426,
    1746872,
    1724318,
    1701764,
    1679210,
    1656656,
    1634102,
    1611548,
    1588994,
    1566440,
    1543886,
    1521332,
    1498778,
    1476224,
    1453670,
    1431116,
    1408562,
    1386008,
    1363454,
    1340900,
    1318346,
    1295792,
    1273238,
    1250684,
    1228130,
    1205576,
    1183022,
    1160468,
    1137914,
    1115360,
    1092806,
    1070252,
    1047698,
    1025144,
    1002590,
    980036,
    957482,
    934928,
    912374,
    889820,
    867266,
    844712,
    822158,
    799604,
    777050,
    754496,
    731942,
    709388,
    686834,
    664280,
    641726,
    619172,
    596618,
    574064,
    551510,
    528956,
    506402,
    483848,
    461294,
    438740,
    416186,
    393632,
    371078,
    348524,
    325970,
    303416,
    280862,
    258308,
    235754,
    213200,
    190646,
    168092,
    145538,
    122984,
    100430,
    77876,
    55322,
    32768,
    10214,
    -12340,
    -34894,
    -57448,
    -80002,
    -102556,
    -125110,
    -147664,
    -170218,
    -192772,
    -215326,
    -237880,
    -260434,
    -282988,
    -305542,
    -328096,
    -350650,
    -373204,
    -395758,
    -418312,
    -440866,
    -463420,
    -485974,
    -508528,
    -531082,
    -553636,
    -576190,
    -598744,
    -621298,
    -643852,
    -666406,
    -688960,
    -711514,
    -734068,
    -756622,
    -779176,
    -801730,
    -824284,
    -846838,
    -869392,
    -891946,
    -914500,
    -937054,
    -959608,
    -982162,
    -1004716,
    -1027270,
    -1049824,
    -1072378,
    -1094932,
    -1117486,
    -1140040,
    -1162594,
    -1185148,
    -1207702,
    -1230256,
    -1252810,
    -1275364,
    -1297918,
    -1320472,
    -1343026,
    -1365580,
    -1388134,
    -1410688,
    -1433242,
    -1455796,
    -1478350,
    -1500904,
    -1523458,
    -1546012,
    -1568566,
    -1591120,
    -1613674,
    -1636228,
    -1658782,
    -1681336,
    -1703890,
    -1726444,
    -1748998,
    -1771552,
    -1794106,
    -1816660,
    -1839214,
    -1861768,
    -1884322,
    -1906876,
    -1929430,
    -1951984,
    -1974538,
    -1997092,
    -2019646,
    -2042200,
    -2064754,
    -2087308,
    -2109862,
    -2132416,
    -2154970,
    -2177524,
    -2200078,
    -2222632,
    -2245186,
    -2267740,
    -2290294,
    -2312848,
    -2335402,
    -2357956,
    -2380510,
    -2403064,
    -2425618,
    -2448172,
    -2470726,
    -2493280,
    -2515834,
    -2538388,
    -2560942,
    -2583496,
    -2606050,
    -2628604,
    -2651158,
    -2673712,
    -2696266,
    -2718820,
    -2741374,
    -2763928,
    -2786482,
    -2809036,
    -2831590
  ];

  static const CBB = [
    -227,
    -225,
    -223,
    -222,
    -220,
    -218,
    -216,
    -214,
    -213,
    -211,
    -209,
    -207,
    -206,
    -204,
    -202,
    -200,
    -198,
    -197,
    -195,
    -193,
    -191,
    -190,
    -188,
    -186,
    -184,
    -183,
    -181,
    -179,
    -177,
    -175,
    -174,
    -172,
    -170,
    -168,
    -167,
    -165,
    -163,
    -161,
    -159,
    -158,
    -156,
    -154,
    -152,
    -151,
    -149,
    -147,
    -145,
    -144,
    -142,
    -140,
    -138,
    -136,
    -135,
    -133,
    -131,
    -129,
    -128,
    -126,
    -124,
    -122,
    -120,
    -119,
    -117,
    -115,
    -113,
    -112,
    -110,
    -108,
    -106,
    -105,
    -103,
    -101,
    -99,
    -97,
    -96,
    -94,
    -92,
    -90,
    -89,
    -87,
    -85,
    -83,
    -82,
    -80,
    -78,
    -76,
    -74,
    -73,
    -71,
    -69,
    -67,
    -66,
    -64,
    -62,
    -60,
    -58,
    -57,
    -55,
    -53,
    -51,
    -50,
    -48,
    -46,
    -44,
    -43,
    -41,
    -39,
    -37,
    -35,
    -34,
    -32,
    -30,
    -28,
    -27,
    -25,
    -23,
    -21,
    -19,
    -18,
    -16,
    -14,
    -12,
    -11,
    -9,
    -7,
    -5,
    -4,
    -2,
    0,
    2,
    4,
    5,
    7,
    9,
    11,
    12,
    14,
    16,
    18,
    19,
    21,
    23,
    25,
    27,
    28,
    30,
    32,
    34,
    35,
    37,
    39,
    41,
    43,
    44,
    46,
    48,
    50,
    51,
    53,
    55,
    57,
    58,
    60,
    62,
    64,
    66,
    67,
    69,
    71,
    73,
    74,
    76,
    78,
    80,
    82,
    83,
    85,
    87,
    89,
    90,
    92,
    94,
    96,
    97,
    99,
    101,
    103,
    105,
    106,
    108,
    110,
    112,
    113,
    115,
    117,
    119,
    120,
    122,
    124,
    126,
    128,
    129,
    131,
    133,
    135,
    136,
    138,
    140,
    142,
    144,
    145,
    147,
    149,
    151,
    152,
    154,
    156,
    158,
    159,
    161,
    163,
    165,
    167,
    168,
    170,
    172,
    174,
    175,
    177,
    179,
    181,
    183,
    184,
    186,
    188,
    190,
    191,
    193,
    195,
    197,
    198,
    200,
    202,
    204,
    206,
    207,
    209,
    211,
    213,
    214,
    216,
    218,
    220,
    222,
    223,
    225
  ];
}

class _JpegHuffman {
  final children = <dynamic>[];
  int index = 0;
}
