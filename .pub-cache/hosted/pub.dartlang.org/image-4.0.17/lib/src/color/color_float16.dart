import 'dart:typed_data';

import '../image/palette.dart';
import '../util/color_util.dart';
import '../util/float16.dart';
import 'channel.dart';
import 'channel_iterator.dart';
import 'color.dart';
import 'format.dart';

/// A 16-bit floating point color.
class ColorFloat16 extends Iterable<num> implements Color {
  final Uint16List data;

  ColorFloat16(int numChannels) : data = Uint16List(numChannels);

  ColorFloat16.from(ColorFloat16 other)
      : data = Uint16List.fromList(other.data);

  ColorFloat16.fromList(List<double> color) : data = Uint16List(color.length) {
    final l = color.length;
    for (var i = 0; i < l; ++i) {
      data[i] = Float16.doubleToFloat16(color[i]);
    }
  }

  ColorFloat16.rgb(num r, num g, num b) : data = Uint16List(3) {
    data[0] = Float16.doubleToFloat16(r.toDouble());
    data[1] = Float16.doubleToFloat16(g.toDouble());
    data[2] = Float16.doubleToFloat16(b.toDouble());
  }

  ColorFloat16.rgba(num r, num g, num b, num a) : data = Uint16List(4) {
    data[0] = Float16.doubleToFloat16(r.toDouble());
    data[1] = Float16.doubleToFloat16(g.toDouble());
    data[2] = Float16.doubleToFloat16(b.toDouble());
    data[3] = Float16.doubleToFloat16(a.toDouble());
  }

  @override
  ColorFloat16 clone() => ColorFloat16.from(this);

  @override
  Format get format => Format.float16;

  @override
  int get length => data.length;

  @override
  num get maxChannelValue => 1.0;

  @override
  num get maxIndexValue => 1.0;

  @override
  bool get isLdrFormat => false;

  @override
  bool get isHdrFormat => true;

  @override
  bool get hasPalette => false;

  @override
  Palette? get palette => null;

  @override
  num operator [](int index) =>
      index < data.length ? Float16.float16ToDouble(data[index]) : 0;

  @override
  void operator []=(int index, num value) {
    if (index < data.length) {
      data[index] = Float16.doubleToFloat16(value.toDouble());
    }
  }

  @override
  num get index => r;
  @override
  set index(num i) => r = i;

  @override
  num get r => data.isNotEmpty ? Float16.float16ToDouble(data[0]) : 0;
  @override
  set r(num v) {
    if (data.isNotEmpty) {
      data[0] = Float16.doubleToFloat16(v.toDouble());
    }
  }

  @override
  num get g => data.length > 1 ? Float16.float16ToDouble(data[1]) : 0;
  @override
  set g(num v) {
    if (data.length > 1) {
      data[1] = Float16.doubleToFloat16(v.toDouble());
    }
  }

  @override
  num get b => data.length > 2 ? Float16.float16ToDouble(data[2]) : 0;
  @override
  set b(num v) {
    if (data.length > 2) {
      data[2] = Float16.doubleToFloat16(v.toDouble());
    }
  }

  @override
  num get a => data.length > 3 ? Float16.float16ToDouble(data[3]) : 0;
  @override
  set a(num v) {
    if (data.length > 3) {
      data[3] = Float16.doubleToFloat16(v.toDouble());
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
          ? Float16.float16ToDouble(data[channel.index])
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
    data[0] = Float16.doubleToFloat16(r.toDouble());
    final nc = data.length;
    if (nc > 1) {
      data[1] = Float16.doubleToFloat16(g.toDouble());
      if (nc > 2) {
        data[2] = Float16.doubleToFloat16(b.toDouble());
      }
    }
  }

  @override
  void setRgba(num r, num g, num b, num a) {
    data[0] = Float16.doubleToFloat16(r.toDouble());
    final nc = data.length;
    if (nc > 1) {
      data[1] = Float16.doubleToFloat16(g.toDouble());
      if (nc > 2) {
        data[2] = Float16.doubleToFloat16(b.toDouble());
        if (nc > 3) {
          data[3] = Float16.doubleToFloat16(a.toDouble());
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
