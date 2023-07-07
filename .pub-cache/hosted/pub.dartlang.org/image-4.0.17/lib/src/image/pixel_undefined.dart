import '../color/channel.dart';
import '../color/channel_iterator.dart';
import '../color/color.dart';
import '../color/format.dart';
import 'image_data.dart';
import 'image_data_uint8.dart';
import 'palette.dart';
import 'pixel.dart';

/// Represents an invalid pixel.
class PixelUndefined extends Iterable<num> implements Pixel {
  static final nullImageData = ImageDataUint8(0, 0, 0);
  @override
  PixelUndefined clone() => PixelUndefined();
  @override
  ImageData get image => nullImageData;
  @override
  int get x => 0;
  @override
  int get y => 0;
  @override
  num get xNormalized => 0;
  @override
  num get yNormalized => 0;
  @override
  void setPositionNormalized(num x, num y) {}
  @override
  int get width => 0;
  @override
  int get height => 0;
  @override
  int get length => 0;
  @override
  num get maxChannelValue => 0;
  @override
  num get maxIndexValue => 0;
  @override
  Format get format => Format.uint8;
  @override
  bool get isLdrFormat => false;
  @override
  bool get isHdrFormat => false;
  @override
  bool get hasPalette => false;
  @override
  Palette? get palette => null;
  @override
  bool get isValid => false;
  @override
  num operator [](int index) => 0;
  @override
  void operator []=(int index, num value) {}
  @override
  num get index => 0;
  @override
  set index(num i) {}
  @override
  num get r => 0;
  @override
  set r(num r) {}
  @override
  num get g => 0;
  @override
  set g(num g) {}
  @override
  num get b => 0;
  @override
  set b(num b) {}
  @override
  num get a => 0;
  @override
  set a(num a) {}
  @override
  num get rNormalized => 0;
  @override
  set rNormalized(num v) {}
  @override
  num get gNormalized => 0;
  @override
  set gNormalized(num v) {}
  @override
  num get bNormalized => 0;
  @override
  set bNormalized(num v) {}
  @override
  num get aNormalized => 0;
  @override
  set aNormalized(num v) {}
  @override
  num get luminance => 0;
  @override
  num get luminanceNormalized => 0;
  @override
  num getChannel(Channel channel) => 0;
  @override
  num getChannelNormalized(Channel channel) => 0;
  @override
  void set(Color c) {}
  @override
  void setRgb(num r, num g, num b) {}
  @override
  void setRgba(num r, num g, num b, num a) {}
  @override
  void setPosition(int x, int y) {}
  @override
  Pixel get current => this;
  @override
  bool moveNext() => false;
  @override
  bool operator ==(Object? other) => other is PixelUndefined;
  @override
  int get hashCode => 0;
  @override
  ChannelIterator get iterator => ChannelIterator(this);
  @override
  Color convert({Format? format, int? numChannels, num? alpha}) => this;
}
