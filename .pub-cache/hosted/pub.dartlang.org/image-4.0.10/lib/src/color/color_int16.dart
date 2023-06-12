import 'dart:typed_data';

import '../image/palette.dart';
import '../util/color_util.dart';
import 'channel.dart';
import 'channel_iterator.dart';
import 'color.dart';
import 'format.dart';

/// A 16-bit integer color.
class ColorInt16 extends Iterable<num> implements Color {
  final Int16List data;

  ColorInt16(int numChannels) : data = Int16List(numChannels);

  ColorInt16.from(ColorInt16 other) : data = Int16List.fromList(other.data);

  ColorInt16.fromList(List<int> color) : data = Int16List.fromList(color);

  ColorInt16.rgb(int r, int g, int b) : data = Int16List(3) {
    data[0] = r;
    data[1] = g;
    data[2] = b;
  }

  ColorInt16.rgba(int r, int g, int b, int a) : data = Int16List(4) {
    data[0] = r;
    data[1] = g;
    data[2] = b;
    data[3] = a;
  }

  @override
  ColorInt16 clone() => ColorInt16.from(this);

  @override
  Format get format => Format.int16;
  @override
  int get length => data.length;
  @override
  num get maxChannelValue => 0x7fff;
  @override
  num get maxIndexValue => 0x7fff;
  @override
  bool get isLdrFormat => false;
  @override
  bool get isHdrFormat => true;
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
  set r(num r) => data.isNotEmpty ? data[0] = r.toInt() : 0;

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
  num get a => data.length > 3 ? data[3] : 0;
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
