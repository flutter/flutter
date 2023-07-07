import 'dart:typed_data';

import '../color/format.dart';
import 'palette.dart';

class PaletteInt32 extends Palette {
  final Int32List data;

  PaletteInt32(int numColors, int numChannels)
      : data = Int32List(numColors * numChannels),
        super(numColors, numChannels);

  PaletteInt32.from(PaletteInt32 other)
      : data = Int32List.fromList(other.data),
        super(other.numColors, other.numChannels);

  @override
  PaletteInt32 clone() => PaletteInt32.from(this);

  @override
  int get lengthInBytes => data.lengthInBytes;
  @override
  ByteBuffer get buffer => data.buffer;
  @override
  Format get format => Format.int32;
  @override
  num get maxChannelValue => 0x7fffffff;

  @override
  void set(int index, int channel, num value) {
    if (channel < numChannels) {
      index *= numChannels;
      data[index + channel] = value.toInt();
    }
  }

  @override
  void setRgb(int index, num r, num g, num b) {
    index *= numChannels;
    data[index] = r.toInt();
    if (numChannels > 1) {
      data[index + 1] = g.toInt();
      if (numChannels > 2) {
        data[index + 2] = b.toInt();
      }
    }
  }

  @override
  void setRgba(int index, num r, num g, num b, num a) {
    index *= numChannels;
    data[index] = r.toInt();
    if (numChannels > 1) {
      data[index + 1] = g.toInt();
      if (numChannels > 2) {
        data[index + 2] = b.toInt();
        if (numChannels > 3) {
          data[index + 3] = a.toInt();
        }
      }
    }
  }

  @override
  num get(int index, int channel) =>
      channel < numChannels ? data[index * numChannels + channel] : 0;

  @override
  num getRed(int index) {
    index *= numChannels;
    return data[index];
  }

  @override
  num getGreen(int index) {
    if (numChannels < 2) {
      return 0;
    }
    index *= numChannels;
    return data[index + 1];
  }

  @override
  num getBlue(int index) {
    if (numChannels < 3) {
      return 0;
    }
    index *= numChannels;
    return data[index + 2];
  }

  @override
  num getAlpha(int index) {
    if (numChannels < 4) {
      return 0;
    }
    index *= numChannels;
    return data[index + 3];
  }

  @override
  void setRed(int index, num value) => set(index, 0, value);
  @override
  void setGreen(int index, num value) => set(index, 1, value);
  @override
  void setBlue(int index, num value) => set(index, 2, value);
  @override
  void setAlpha(int index, num value) => set(index, 3, value);
}
