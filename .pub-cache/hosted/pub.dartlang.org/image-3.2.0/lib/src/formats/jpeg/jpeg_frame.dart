import 'dart:math';
import 'dart:typed_data';

import 'jpeg_component.dart';

class JpegFrame {
  bool? extended;
  bool? progressive;
  int? precision;
  int? scanLines;
  int? samplesPerLine;
  int maxHSamples = 0;
  int maxVSamples = 0;
  late int mcusPerLine;
  late int mcusPerColumn;
  final components = <int, JpegComponent>{};
  final List<int> componentsOrder = <int>[];

  void prepare() {
    for (var componentId in components.keys) {
      final component = components[componentId]!;
      maxHSamples = max(maxHSamples, component.hSamples);
      maxVSamples = max(maxVSamples, component.vSamples);
    }

    mcusPerLine = (samplesPerLine! / 8 / maxHSamples).ceil();
    mcusPerColumn = (scanLines! / 8 / maxVSamples).ceil();

    for (var componentId in components.keys) {
      final component = components[componentId]!;
      final blocksPerLine =
          ((samplesPerLine! / 8).ceil() * component.hSamples / maxHSamples)
              .ceil();
      final blocksPerColumn =
          ((scanLines! / 8).ceil() * component.vSamples / maxVSamples).ceil();
      final blocksPerLineForMcu = mcusPerLine * component.hSamples;
      final blocksPerColumnForMcu = mcusPerColumn * component.vSamples;

      final blocks = List.generate(
          blocksPerColumnForMcu,
          (_) => List<Int32List>.generate(
              blocksPerLineForMcu, (_) => Int32List(64),
              growable: false),
          growable: false);

      component.blocksPerLine = blocksPerLine;
      component.blocksPerColumn = blocksPerColumn;
      component.blocks = blocks;
    }
  }
}
