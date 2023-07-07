import '../../image_exception.dart';
import '../../util/input_buffer.dart';
import 'jpeg.dart';
import 'jpeg_component.dart';
import 'jpeg_frame.dart';

class JpegScan {
  InputBuffer input;
  JpegFrame frame;
  int? precision;
  int? samplesPerLine;
  int? scanLines;
  late int mcusPerLine;
  bool? progressive;
  int? maxH;
  int? maxV;
  List<JpegComponent> components;
  int? resetInterval;
  int spectralStart;
  int spectralEnd;
  int successivePrev;
  int successive;

  int bitsData = 0;
  int bitsCount = 0;
  int eobrun = 0;
  int successiveACState = 0;
  late int successiveACNextValue;

  JpegScan(
      this.input,
      this.frame,
      this.components,
      this.resetInterval,
      this.spectralStart,
      this.spectralEnd,
      this.successivePrev,
      this.successive) {
    precision = frame.precision;
    samplesPerLine = frame.samplesPerLine;
    scanLines = frame.scanLines;
    mcusPerLine = frame.mcusPerLine;
    progressive = frame.progressive;
    maxH = frame.maxHSamples;
    maxV = frame.maxVSamples;
  }

  void decode() {
    final componentsLength = components.length;
    JpegComponent? component;
    void Function(JpegComponent, List<int>) decodeFn;

    if (progressive!) {
      if (spectralStart == 0) {
        decodeFn = successivePrev == 0 ? _decodeDCFirst : _decodeDCSuccessive;
      } else {
        decodeFn = successivePrev == 0 ? _decodeACFirst : _decodeACSuccessive;
      }
    } else {
      decodeFn = _decodeBaseline;
    }

    var mcu = 0;

    int? mcuExpected;
    if (componentsLength == 1) {
      mcuExpected =
          (components[0].blocksPerLine * components[0].blocksPerColumn);
    } else {
      mcuExpected = (mcusPerLine * frame.mcusPerColumn);
    }

    if (resetInterval == null || resetInterval == 0) {
      resetInterval = mcuExpected;
    }

    int h, v;
    while (mcu < mcuExpected) {
      // reset interval stuff
      for (var i = 0; i < componentsLength; i++) {
        components[i].pred = 0;
      }
      eobrun = 0;

      if (componentsLength == 1) {
        component = components[0];
        for (var n = 0; n < resetInterval!; n++) {
          _decodeBlock(component, decodeFn, mcu);
          mcu++;
        }
      } else {
        for (var n = 0; n < resetInterval!; n++) {
          for (var i = 0; i < componentsLength; i++) {
            component = components[i];
            h = component.hSamples;
            v = component.vSamples;
            for (var j = 0; j < v; j++) {
              for (var k = 0; k < h; k++) {
                _decodeMcu(component, decodeFn, mcu, j, k);
              }
            }
          }
          mcu++;
        }
      }

      // find marker
      bitsCount = 0;
      final m1 = input[0];
      final m2 = input[1];
      if (m1 == 0xff) {
        if (m2 >= Jpeg.M_RST0 && m2 <= Jpeg.M_RST7) {
          input.offset += 2;
        } else {
          break;
        }
      }
    }
  }

  int? _readBit() {
    if (bitsCount > 0) {
      bitsCount--;
      return (bitsData >> bitsCount) & 1;
    }

    if (input.isEOS) {
      return null;
    }

    bitsData = input.readByte();
    if (bitsData == 0xff) {
      final nextByte = input.readByte();
      if (nextByte != 0) {
        throw ImageException(
            'unexpected marker: ${((bitsData << 8) | nextByte).toRadixString(16)}');
      }
    }

    bitsCount = 7;
    return (bitsData >> 7) & 1;
  }

  int? _decodeHuffman(List tree) {
    dynamic node = tree;
    int? bit;
    while ((bit = _readBit()) != null) {
      node = (node as List)[bit!];
      if (node is num) {
        return node.toInt();
      }
    }

    return null;
  }

  int? _receive(int length) {
    var n = 0;
    while (length > 0) {
      final bit = _readBit();
      if (bit == null) {
        return null;
      }
      n = ((n << 1) | bit);
      length--;
    }
    return n;
  }

  int _receiveAndExtend(int? length) {
    if (length == 1) {
      return _readBit() == 1 ? 1 : -1;
    }
    final n = _receive(length!)!;
    if (n >= (1 << (length - 1))) {
      return n;
    }
    return n + (-1 << length) + 1;
  }

  void _decodeBaseline(JpegComponent component, List zz) {
    final t = _decodeHuffman(component.huffmanTableDC);
    final diff = t == 0 ? 0 : _receiveAndExtend(t);
    component.pred += diff;
    zz[0] = component.pred;

    var k = 1;
    while (k < 64) {
      final rs = _decodeHuffman(component.huffmanTableAC)!;
      var s = rs & 15;
      final r = rs >> 4;
      if (s == 0) {
        if (r < 15) {
          break;
        }
        k += 16;
        continue;
      }

      k += r;

      s = _receiveAndExtend(s);

      final z = Jpeg.dctZigZag[k];
      zz[z] = s;
      k++;
    }
  }

  void _decodeDCFirst(JpegComponent component, List zz) {
    final t = _decodeHuffman(component.huffmanTableDC);
    final diff = (t == 0) ? 0 : (_receiveAndExtend(t) << successive);
    component.pred += diff;
    zz[0] = component.pred;
  }

  void _decodeDCSuccessive(JpegComponent component, List<int> zz) {
    zz[0] = (zz[0] | (_readBit()! << successive));
  }

  void _decodeACFirst(JpegComponent component, List zz) {
    if (eobrun > 0) {
      eobrun--;
      return;
    }
    var k = spectralStart;
    final e = spectralEnd;
    while (k <= e) {
      final rs = _decodeHuffman(component.huffmanTableAC)!;
      final s = rs & 15;
      final r = rs >> 4;
      if (s == 0) {
        if (r < 15) {
          eobrun = (_receive(r)! + (1 << r) - 1);
          break;
        }
        k += 16;
        continue;
      }
      k += r;
      final z = Jpeg.dctZigZag[k];
      zz[z] = (_receiveAndExtend(s) * (1 << successive));
      k++;
    }
  }

  void _decodeACSuccessive(JpegComponent component, List<int> zz) {
    var k = spectralStart;
    final e = spectralEnd;
    var s = 0;
    var r = 0;
    while (k <= e) {
      final z = Jpeg.dctZigZag[k];
      switch (successiveACState) {
        case 0: // initial state
          final rs = _decodeHuffman(component.huffmanTableAC);
          if (rs == null) throw ImageException('Invalid progressive encoding');
          s = rs & 15;
          r = rs >> 4;
          if (s == 0) {
            if (r < 15) {
              eobrun = (_receive(r)! + (1 << r));
              successiveACState = 4;
            } else {
              r = 16;
              successiveACState = 1;
            }
          } else {
            if (s != 1) {
              throw ImageException('invalid ACn encoding');
            }
            successiveACNextValue = _receiveAndExtend(s);
            successiveACState = r != 0 ? 2 : 3;
          }
          continue;
        case 1: // skipping r zero items
        case 2:
          if (zz[z] != 0) {
            zz[z] += (_readBit()! << successive);
          } else {
            r--;
            if (r == 0) {
              successiveACState = successiveACState == 2 ? 3 : 0;
            }
          }
          break;
        case 3: // set value for a zero item
          if (zz[z] != 0) {
            zz[z] += (_readBit()! << successive);
          } else {
            zz[z] = (successiveACNextValue << successive);
            successiveACState = 0;
          }
          break;
        case 4: // eob
          if (zz[z] != 0) {
            zz[z] += (_readBit()! << successive);
          }
          break;
      }
      k++;
    }
    if (successiveACState == 4) {
      eobrun--;
      if (eobrun == 0) {
        successiveACState = 0;
      }
    }
  }

  void _decodeMcu(
      JpegComponent component,
      void Function(JpegComponent, List<int>) decodeFn,
      int mcu,
      int row,
      int col) {
    final mcuRow = (mcu ~/ mcusPerLine);
    final mcuCol = mcu % mcusPerLine;
    final blockRow = mcuRow * component.vSamples + row;
    final blockCol = mcuCol * component.hSamples + col;
    if (blockRow >= component.blocks.length) {
      return;
    }
    final numCols = component.blocks[blockRow].length;
    if (blockCol >= numCols) {
      return;
    }
    decodeFn(component, component.blocks[blockRow][blockCol]);
  }

  void _decodeBlock(JpegComponent component,
      void Function(JpegComponent, List<int>) decodeFn, int mcu) {
    final blockRow = mcu ~/ component.blocksPerLine;
    final blockCol = mcu % component.blocksPerLine;
    decodeFn(component, component.blocks[blockRow][blockCol]);
  }
}
