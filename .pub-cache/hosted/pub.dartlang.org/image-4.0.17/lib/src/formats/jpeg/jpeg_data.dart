import 'dart:typed_data';

import '../../exif/exif_data.dart';
import '../../image/image.dart';
import '../../util/_internal.dart';
import '../../util/image_exception.dart';
import '../../util/input_buffer.dart';
import '_component_data.dart';
import '_jpeg_huffman.dart';
import 'jpeg_adobe.dart';
import 'jpeg_component.dart';
import 'jpeg_frame.dart';
import 'jpeg_info.dart';
import 'jpeg_jfif.dart';
import 'jpeg_marker.dart';
import 'jpeg_quantize_stub.dart'
    if (dart.library.io) '_jpeg_quantize_io.dart'
    if (dart.library.js) '_jpeg_quantize_html.dart';
import 'jpeg_scan.dart';

@internal
class JpegData {
  static const dctZigZag = [
    0, 1, 8, 16, 9, 2, 3, 10,
    17, 24, 32, 25, 18, 11, 4, 5,
    12, 19, 26, 33, 40, 48, 41, 34,
    27, 20, 13, 6, 7, 14, 21, 28,
    35, 42, 49, 56, 57, 50, 43, 36,
    29, 22, 15, 23, 30, 37, 44, 51,
    58, 59, 52, 45, 38, 31, 39, 46,
    53, 60, 61, 54, 47, 55, 62, 63,
    63, 63, 63, 63, 63, 63, 63, 63, // extra entries for safety in decoder
    63, 63, 63, 63, 63, 63, 63, 63
  ];

  static const dctSize = 8; // The basic DCT block is 8x8 samples
  static const dctSize2 = 64; // DCTSIZE squared; # of elements in a block
  static const numQuantizationTables = 4; // Quantization tables are 0..3
  static const numHuffmanTables = 4; // Huffman tables are numbered 0..3
  static const numArithTables = 16; // Arith-coding tables are numbered 0..15
  static const maxCompsInScan = 4; // JPEG limit on # of components in one scan
  static const maxSamplingFactor = 4; // JPEG limit on sampling factors

  late InputBuffer input;
  late JpegJfif jfif;
  JpegAdobe? adobe;
  JpegFrame? frame;
  int? resetInterval;
  String? comment;
  final exif = ExifData();
  final quantizationTables =
      List<Int16List?>.filled(numQuantizationTables, null);
  final frames = <JpegFrame?>[];
  final huffmanTablesAC = List<List<HuffmanNode?>?>.empty(growable: true);
  final huffmanTablesDC = List<List<HuffmanNode?>?>.empty(growable: true);
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
    if (marker != JpegMarker.soi) {
      return false;
    }

    var hasSOF = false;
    var hasSOS = false;

    marker = _nextMarker();
    while (marker != JpegMarker.eoi && !input.isEOS) {
      // EOI (End of image)
      final sectionByteSize = input.readUint16();
      if (sectionByteSize < 2) {
        // jpeg section consists of more than 2 bytes at least
        // return success only when SOF and SOS have already found (as a jpeg
        // without EOF.)
        break;
      }
      input.offset += sectionByteSize - 2;

      switch (marker) {
        case JpegMarker.sof0: // SOF0 (Start of Frame, Baseline DCT)
        case JpegMarker.sof1: // SOF1 (Start of Frame, Extended DCT)
        case JpegMarker.sof2: // SOF2 (Start of Frame, Progressive DCT)
          hasSOF = true;
          break;
        case JpegMarker.sos: // SOS (Start of Scan)
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
    if (marker != JpegMarker.soi) {
      return null;
    }

    final info = JpegInfo();

    var hasSOF = false;
    var hasSOS = false;

    marker = _nextMarker();
    while (marker != JpegMarker.eoi && !input.isEOS) {
      // EOI (End of image)
      switch (marker) {
        case JpegMarker.sof0: // SOF0 (Start of Frame, Baseline DCT)
        case JpegMarker.sof1: // SOF1 (Start of Frame, Extended DCT)
        case JpegMarker.sof2: // SOF2 (Start of Frame, Progressive DCT)
          hasSOF = true;
          _readFrame(marker, _readBlock());
          break;
        case JpegMarker.sos: // SOS (Start of Scan)
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
      info
        ..width = frame!.samplesPerLine!
        ..height = frame!.scanLines!;
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
    if (marker != JpegMarker.soi) {
      // SOI (Start of Image)
      throw ImageException('Start Of Image marker not found.');
    }

    marker = _nextMarker();
    while (marker != JpegMarker.eoi && !input.isEOS) {
      final block = _readBlock();
      switch (marker) {
        case JpegMarker.app0:
        case JpegMarker.app1:
        case JpegMarker.app2:
        case JpegMarker.app3:
        case JpegMarker.app4:
        case JpegMarker.app5:
        case JpegMarker.app6:
        case JpegMarker.app7:
        case JpegMarker.app8:
        case JpegMarker.app9:
        case JpegMarker.app10:
        case JpegMarker.app11:
        case JpegMarker.app12:
        case JpegMarker.app13:
        case JpegMarker.app14:
        case JpegMarker.app15:
        case JpegMarker.com:
          _readAppData(marker, block);
          break;

        case JpegMarker.dqt: // DQT (Define Quantization Tables)
          _readDQT(block);
          break;

        case JpegMarker.sof0: // SOF0 (Start of Frame, Baseline DCT)
        case JpegMarker.sof1: // SOF1 (Start of Frame, Extended DCT)
        case JpegMarker.sof2: // SOF2 (Start of Frame, Progressive DCT)
          _readFrame(marker, block);
          break;

        case JpegMarker.sof3:
        case JpegMarker.sof5:
        case JpegMarker.sof6:
        case JpegMarker.sof7:
        case JpegMarker.jpg:
        case JpegMarker.sof9:
        case JpegMarker.sof10:
        case JpegMarker.sof11:
        case JpegMarker.sof13:
        case JpegMarker.sof14:
        case JpegMarker.sof15:
          throw ImageException(
              'Unhandled frame type ${marker.toRadixString(16)}');

        case JpegMarker.dht: // DHT (Define Huffman Tables)
          _readDHT(block);
          break;

        case JpegMarker.dri: // DRI (Define Restart Interval)
          _readDRI(block);
          break;

        case JpegMarker.sos: // SOS (Start of Scan)
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

    if (marker == JpegMarker.app0) {
      // 'JFIF\0'
      if (appData[0] == 0x4A &&
          appData[1] == 0x46 &&
          appData[2] == 0x49 &&
          appData[3] == 0x46 &&
          appData[4] == 0) {
        jfif = JpegJfif()
          ..majorVersion = appData[5]
          ..minorVersion = appData[6]
          ..densityUnits = appData[7]
          ..xDensity = (appData[8] << 8) | appData[9]
          ..yDensity = (appData[10] << 8) | appData[11]
          ..thumbWidth = appData[12]
          ..thumbHeight = appData[13];
        final thumbSize = 3 * jfif.thumbWidth * jfif.thumbHeight;
        jfif.thumbData = appData.subset(14 + thumbSize, offset: 14);
      }
    } else if (marker == JpegMarker.app1) {
      // 'EXIF\0'
      _readExifData(appData);
    } else if (marker == JpegMarker.app14) {
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
    } else if (marker == JpegMarker.com) {
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
      final prec = n >> 4;
      n &= 0x0F;

      if (n >= numQuantizationTables) {
        throw ImageException('Invalid number of quantization tables');
      }

      if (quantizationTables[n] == null) {
        quantizationTables[n] = Int16List(64);
      }

      final tableData = quantizationTables[n];
      for (var i = 0; i < dctSize2; i++) {
        int tmp;
        if (prec != 0) {
          tmp = block.readUint16();
        } else {
          tmp = block.readByte();
        }

        tableData![dctZigZag[i]] = tmp;
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
    frame!.extended = marker == JpegMarker.sof1;
    frame!.progressive = marker == JpegMarker.sof2;
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

      final huffmanValues = block.readBytes(count).toUint8List();

      List<List<HuffmanNode?>?> ht;
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
    if (n < 1 || n > maxCompsInScan) {
      throw ImageException('Invalid SOS block');
    }

    final components = List<JpegComponent>.generate(n, (i) {
      final id = block.readByte();
      final c = block.readByte();

      if (!frame!.components.containsKey(id)) {
        throw ImageException('Invalid Component in SOS block');
      }

      final component = frame!.components[id]!;

      final dcTblNo = (c >> 4) & 15;
      final acTblNo = c & 15;

      if (dcTblNo < huffmanTablesDC.length) {
        component.huffmanTableDC = huffmanTablesDC[dcTblNo]!;
      }
      if (acTblNo < huffmanTablesAC.length) {
        component.huffmanTableAC = huffmanTablesAC[acTblNo]!;
      }

      return component;
    });

    final spectralStart = block.readByte();
    final spectralEnd = block.readByte();
    final successiveApproximation = block.readByte();

    final ah = (successiveApproximation >> 4) & 15;
    final al = successiveApproximation & 15;

    JpegScan(input, frame!, components, resetInterval, spectralStart,
            spectralEnd, ah, al)
        .decode();
  }

  List<HuffmanNode?> _buildHuffmanTable(
      Uint8List codeLengths, Uint8List values) {
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
        p.children[p.index] = HuffmanValue(values[k]);
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
          p.children[p.index] = HuffmanParent(q.children);
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
        p.children[p.index] = HuffmanParent(q.children);
        p = q;
      }
    }

    return code[0].children;
  }

  List<Uint8List?> _buildComponentData(
      JpegFrame? frame, JpegComponent component) {
    final blocksPerLine = component.blocksPerLine;
    final blocksPerColumn = component.blocksPerColumn;
    final samplesPerLine = blocksPerLine << 3;
    final R = Int32List(64);
    final r = Uint8List(64);
    final lines = List<Uint8List?>.filled(blocksPerColumn * 8, null);

    var l = 0;
    for (var blockRow = 0; blockRow < blocksPerColumn; blockRow++) {
      final scanLine = blockRow << 3;
      for (var i = 0; i < 8; i++) {
        lines[l++] = Uint8List(samplesPerLine);
      }

      for (var blockCol = 0; blockCol < blocksPerLine; blockCol++) {
        quantizeAndInverse(component.quantizationTable!,
            component.blocks[blockRow][blockCol] as Int32List, r, R);

        var offset = 0;
        final sample = blockCol << 3;
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
    const fixedPoint = 20;
    const one = 1 << fixedPoint;
    return (val * one).toInt() & 0xffffffff;
  }
}

class _JpegHuffman {
  final children = <HuffmanNode?>[];
  int index = 0;
}
