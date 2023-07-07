import 'dart:typed_data';

class JpegComponent {
  int hSamples;
  int vSamples;
  final List<Int16List?> quantizationTableList;
  int quantizationIndex;
  late int blocksPerLine;
  late int blocksPerColumn;
  late List<List<List<int>>> blocks;
  late List huffmanTableDC;
  late List huffmanTableAC;
  late int pred;

  JpegComponent(this.hSamples, this.vSamples, this.quantizationTableList,
      this.quantizationIndex);

  Int16List? get quantizationTable => quantizationTableList[quantizationIndex];
}
