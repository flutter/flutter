import 'dart:typed_data';

import '../image/palette.dart';
import '../util/color_util.dart';
import 'channel.dart';
import 'channel_iterator.dart';
import 'color.dart';
import 'format.dart';

/// An 8-bit unsigned int color with channel values in the range \[0, 255].
class ColorUint8 extends Iterable<num> implements Color {
  final Uint8List data;

  ColorUint8(int numChannels) : data = Uint8List(numChannels);

  ColorUint8.from(ColorUint8 other) : data = Uint8List.fromList(other.data);

  ColorUint8.fromList(List<int> color) : data = Uint8List.fromList(color);

  ColorUint8.rgb(int r, int g, int b) : data = Uint8List(3) {
    data[0] = r;
    data[1] = g;
    data[2] = b;
  }

  ColorUint8.rgba(int r, int g, int b, int a) : data = Uint8List(4) {
    data[0] = r;
    data[1] = g;
    data[2] = b;
    data[3] = a;
  }

  @override
  ColorUint8 clone() => ColorUint8.from(this);

  @override
  Format get format => Format.uint8;
  @override
  int get length => data.length;
  @override
  num get maxChannelValue => 255;
  @override
  num get maxIndexValue => 255;
  @override
  bool get isLdrFormat => true;
  @override
  bool get isHdrFormat => false;
  @override
  bool get hasPalette => false;
  @override
  Palette? get palette => null;

  @override
  num operator [](int index) => index < data.length ? data[index] : 0;
  @override
  void operator []=(int index, num value) {
    if (index < data.length) {
      data[index] = value.toInt();
    }
  }

  @override
  num get index => r;
  @override
  set index(num i) => r = i;

  @override
  num get r => data.isNotEmpty ? data[0] : 0;
  @override
  set r(num r) {
    if (data.isNotEmpty) {
      data[0] = r.toInt();
    }
  }

  @override
  num get g => data.length > 1 ? data[1] : 0;
  @override
  set g(num g) {
    if (data.length > 1) {
      data[1] = g.toInt();
    }
  }

  @override
  num get b => data.length > 2 ? data[2] : 0;
  @override
  set b(num b) {
    if (data.length > 2) {
      data[2] = b.toInt();
    }
  }

  @override
  num get a => data.length > 3 ? data[3] : 255;
  @override
  set a(num a) {
    if (data.length > 3) {
      data[3] = a.toInt();
    }
  }

  @override
  num get rNormalized => r / maxChannelValue;
  @override
  set rNormalized(num v) => r = v * maxChannelValue;

  @override
  num get gNormalized => g / maxChannelValue;
  @override
  set gNormalized(num v) => g = v * maxChannelValue;

  @override
  num get bNormalized => b / maxChannelValue;
  @override
  set bNormalized(num v) => b = v * maxChannelValue;

  @override
  num get aNormalized => a / maxChannelValue;
  @override
  set aNormalized(num v) => a = v * maxChannelValue;

  @override
  num get luminance => getLuminance(this);
  @override
  num get luminanceNormalized => getLuminanceNormalized(this);

  @override
  num getChannel(Channel channel) => channel == Channel.luminance
      ? luminance
      : channel.index < data.length
          ? data[channel.index]
          : 0;

  @override
  num getChannelNormalized(Channel channel) =>
      getChannel(channel) / maxChannelValue;

  @override
  void set(Color c) {
    r = c.r;
    g = c.g;
    b = c.b;
    a = c.a;
  }

  @override
  void setRgb(num r, num g, num b) {
    data[0] = r.toInt();
    final nc = data.length;
    if (nc > 1) {
      data[1] = g.toInt();
      if (nc > 2) {
        data[2] = b.toInt();
      }
    }
  }

  @override
  void setRgba(num r, num g, num b, num a) {
    data[0] = r.toInt();
    final nc = data.length;
    if (nc > 1) {
      data[1] = g.toInt();
      if (nc > 2) {
        data[2] = b.toInt();
        if (nc > 3) {
          data[3] = a.toInt();
        }
      }
    }
  }

  @override
  ChannelIterator get iterator => ChannelIterator(this);

  @override
  bool operator ==(Object? other) =>
      other is Color && other.length == length && other.hashCode == hashCode;

  @override
  int get hashCode => Object.hashAll(toList());

  @override
  Color convert({Format? format, int? numChannels, num? alpha}) =>
      convertColor(this,
          format: format, numChannels: numChannels, alpha: alpha);
}

class ColorRgb8 extends ColorUint8 {
  ColorRgb8(int r, int g, int b) : super.rgb(r, g, b);

  ColorRgb8.from(ColorUint8 other) : super(3) {
    data[0] = other[0] as int;
    data[1] = other[1] as int;
    data[2] = other[2] as int;
  }
}

class ColorRgba8 extends ColorUint8 {
  ColorRgba8(int r, int g, int b, int a) : super.rgba(r, g, b, a);

  ColorRgba8.from(ColorUint8 other) : super(4) {
    data[0] = other[0] as int;
    data[1] = other[1] as int;
    data[2] = other[2] as int;
    data[3] = other[3] as int;
  }
}
