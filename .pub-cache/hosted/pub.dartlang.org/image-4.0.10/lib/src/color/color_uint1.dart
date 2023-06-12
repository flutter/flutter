import '../image/palette.dart';
import '../util/color_util.dart';
import 'channel.dart';
import 'channel_iterator.dart';
import 'color.dart';
import 'format.dart';

/// A 1-bit unsigned int color with channel values in the range \[0, 1\].
class ColorUint1 extends Iterable<num> implements Color {
  @override
  final int length;
  late int data;

  ColorUint1(this.length) : data = 0;

  ColorUint1.from(ColorUint1 other)
      : length = other.length,
        data = other.data;

  ColorUint1.fromList(List<int> color)
      : length = color.length,
        data = 0 {
    setRgba(length > 0 ? color[0] : 0, length > 1 ? color[1] : 0,
        length > 2 ? color[2] : 0, length > 3 ? color[3] : 0);
  }

  ColorUint1.rgb(int r, int g, int b)
      : length = 3,
        data = 0 {
    setRgb(r, g, b);
  }

  ColorUint1.rgba(int r, int g, int b, int a)
      : length = 4,
        data = 0 {
    setRgba(r, g, b, a);
  }

  @override
  ColorUint1 clone() => ColorUint1.from(this);

  @override
  Format get format => Format.uint1;

  @override
  num get maxChannelValue => 1;

  @override
  num get maxIndexValue => 1;

  @override
  bool get isLdrFormat => true;

  @override
  bool get isHdrFormat => false;

  @override
  bool get hasPalette => false;

  @override
  Palette? get palette => null;

  int _getChannel(int ci) => ci < length ? ((data >> (7 - ci)) & 0x1) : 0;

  void _setChannel(int ci, num value) {
    if (ci >= length) {
      return;
    }
    ci = 7 - ci;
    var v = data;
    if (value != 0) {
      v |= 1 << ci;
    } else {
      v &= ~((1 << ci) & 0xff);
    }
    data = v;
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
