import 'dart:typed_data';

import '../image/palette.dart';
import '../util/color_util.dart';
import 'channel.dart';
import 'channel_iterator.dart';
import 'color.dart';
import 'format.dart';

/// A 4-bit unsigned int color with channel values in the range \[0, 15].
class ColorUint4 extends Iterable<num> implements Color {
  @override
  final int length;
  Uint8List data;

  ColorUint4(this.length) : data = Uint8List(length < 3 ? 1 : 2);

  ColorUint4.from(ColorUint4 other)
      : length = other.length,
        data = Uint8List.fromList(other.data);

  ColorUint4.fromList(List<int> color)
      : length = color.length,
        data = Uint8List(color.length < 3 ? 1 : 2) {
    setRgba(length > 0 ? color[0] : 0, length > 1 ? color[1] : 0,
        length > 2 ? color[2] : 0, length > 3 ? color[3] : 0);
  }

  ColorUint4.rgb(int r, int g, int b)
      : length = 3,
        data = Uint8List(2) {
    setRgb(r, g, b);
  }

  ColorUint4.rgba(int r, int g, int b, int a)
      : length = 4,
        data = Uint8List(2) {
    setRgba(r, g, b, a);
  }

  @override
  ColorUint4 clone() => ColorUint4.from(this);

  @override
  Format get format => Format.uint4;
  @override
  num get maxChannelValue => 15;
  @override
  num get maxIndexValue => 15;
  @override
  bool get isLdrFormat => true;
  @override
  bool get isHdrFormat => false;
  @override
  bool get hasPalette => false;
  @override
  Palette? get palette => null;

  int _getChannel(int ci) => ci < 0 || ci >= length
      ? 0
      : ci < 2
          ? (data[0] >> (4 - (ci << 2))) & 0xf
          : (data[1] >> (4 - ((ci & 0x1) << 2)) & 0xf);

  void _setChannel(int ci, num value) {
    if (ci >= length) {
      return;
    }
    final vi = value.toInt().clamp(0, 15);
    int i = 0;
    if (ci > 1) {
      ci &= 0x1;
      i = 1;
    }
    if (ci == 0) {
      data[i] = (data[i] & 0xf) | (vi << 4);
    } else if (ci == 1) {
      data[i] = (data[i] & 0xf0) | vi;
    }
  }

  @override
  num operator [](int index) => _getChannel(index);

  @override
  void operator []=(int index, num value) => _setChannel(index, value);

  @override
  num get index => r;

  @override
  set index(num i) => r = i;

  @override
  num get r => _getChannel(0);

  @override
  set r(num v) => _setChannel(0, v);

  @override
  num get g => _getChannel(1);

  @override
  set g(num v) => _setChannel(1, v);

  @override
  num get b => _getChannel(2);

  @override
  set b(num v) => _setChannel(2, v);

  @override
  num get a => _getChannel(3);

  @override
  set a(num v) => _setChannel(3, v);

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
  num getChannel(Channel channel) =>
      channel == Channel.luminance ? luminance : _getChannel(channel.index);

  @override
  num getChannelNormalized(Channel channel) =>
      getChannel(channel) / maxChannelValue;

  @override
  void set(Color c) {
    setRgba(c.r, c.g, c.b, c.a);
  }

  @override
  void setRgb(num r, num g, num b) {
    this.r = r;
    this.g = g;
    this.b = b;
  }

  @override
  void setRgba(num r, num g, num b, num a) {
    this.r = r;
    this.g = g;
    this.b = b;
    this.a = a;
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
