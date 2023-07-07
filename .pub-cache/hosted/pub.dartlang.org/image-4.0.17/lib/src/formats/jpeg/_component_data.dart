import 'dart:typed_data';

class ComponentData {
  int hSamples;
  int maxHSamples;
  int vSamples;
  int maxVSamples;
  List<Uint8List?> lines;
  int hScaleShift;
  int vScaleShift;
  ComponentData(this.hSamples, this.maxHSamples, this.vSamples,
      this.maxVSamples, this.lines)
      : hScaleShift = (hSamples == 1 && maxHSamples == 2) ? 1 : 0,
        vScaleShift = (vSamples == 1 && maxVSamples == 2) ? 1 : 0;
}
