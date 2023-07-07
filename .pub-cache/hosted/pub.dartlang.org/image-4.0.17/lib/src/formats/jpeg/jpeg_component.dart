import 'dart:typed_data';

import '_jpeg_huffman.dart';

class JpegComponent {
  int hSamples;
  int vSamples;
  final List<Int16List?> quantizationTableList;
  int quantizationIndex;
  late int blocksPerLine;
  late int blocksPerColumn;
  late List<List<List<int>>> blocks;
  late List<HuffmanNode?> huffmanTableDC;
  late List<HuffmanNode?> huffmanTableAC;
  late int pred;

  JpegComponent(this.hSamples, this.vSamples, this.quantizationTableList,
      this.quantizationIndex);

  Int16List? get quantizationTable => quantizationTableList[quantizationIndex];
}
