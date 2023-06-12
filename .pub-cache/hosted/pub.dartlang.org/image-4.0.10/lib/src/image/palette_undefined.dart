import 'dart:typed_data';

import '../color/format.dart';
import 'palette.dart';

class PaletteUndefined extends Palette {
  PaletteUndefined() : super(0, 0);
  @override
  PaletteUndefined clone() => PaletteUndefined();
  @override
  int get lengthInBytes => 0;
  @override
  Format get format => Format.uint8;
  @override
  int get maxChannelValue => 0;
  @override
  ByteBuffer get buffer => Uint8List(0).buffer;
  @override
  void set(int index, int channel, num value) {}
  @override
  void setRgb(int index, num r, num g, num b) {}
  @override
  void setRgba(int index, num r, num g, num b, num a) {}
  @override
  num get(int index, int channel) => 0;
  @override
  num getRed(int index) => 0;
  @override
  num getGreen(int index) => 0;
  @override
  num getBlue(int index) => 0;
  @override
  num getAlpha(int index) => 0;
  @override
  void setRed(int index, num value) {}
  @override
  void setGreen(int index, num value) {}
  @override
  void setBlue(int index, num value) {}
  @override
  void setAlpha(int index, num value) {}
}
