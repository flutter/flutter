import 'dart:typed_data';

import '../color/channel.dart';
import '../color/channel_iterator.dart';
import '../color/color.dart';
import '../color/format.dart';
import '../util/color_util.dart';
import 'image.dart';
import 'image_data_uint2.dart';
import 'palette.dart';
import 'pixel.dart';

class PixelUint2 extends Iterable<num> implements Pixel {
  int _x;
  int _y;
  int _index;
  int _bitIndex;
  int _rowOffset;
  @override
  final ImageDataUint2 image;

  PixelUint2.imageData(this.image)
      : _x = -1,
        _y = 0,
        _index = 0,
        _bitIndex = -2,
        _rowOffset = 0;

  PixelUint2.image(Image image)
      : _x = -1,
        _y = 0,
        _index = 0,
        _bitIndex = -2,
        _rowOffset = 0,
        image = image.data is ImageDataUint2
            ? image.data as ImageDataUint2
            : ImageDataUint2(0, 0, 0);

  PixelUint2.from(PixelUint2 other)
      : _x = other._x,
        _y = other._y,
        _index = other._index,
        _bitIndex = other._bitIndex,
        _rowOffset = other._rowOffset,
        image = other.image;

  @override
  PixelUint2 clone() => PixelUint2.from(this);

  @override
  int get length => palette?.numChannels ?? image.numChannels;

  int get numChannels => image.numChannels;

  @override
  bool get hasPalette => image.hasPalette;

  @override
  Palette? get palette => image.palette;

  @override
  int get width => image.width;

  @override
  int get height => image.height;

  Uint8List get data => image.data;

  @override
  num get maxChannelValue => image.maxChannelValue;

  @override
  num get maxIndexValue => image.maxIndexValue;

  @override
  Format get format => Format.uint2;

  @override
  bool get isLdrFormat => image.isLdrFormat;

  @override
  bool get isHdrFormat => image.isHdrFormat;

  @override
  bool get isValid =>
      x >= 0 && x < (image.width - 1) && y >= 0 && y < (image.height - 1);

  int get bitsPerPixel => image.palette != null ? 2 : image.numChannels << 1;

  @override
  int get x => _x;
  @override
  int get y => _y;

  /// The normalized x coordinate of the pixel, in the range \[0, 1\].
  @override
  num get xNormalized => width > 1 ? _x / (width - 1) : 0;

  /// The normalized y coordinate of the pixel, in the range \[0, 1\].
  @override
  num get yNormalized => height > 1 ? _y / (height - 1) : 0;

  /// Set the normalized coordinates of the pixel, in the range \[0, 1\].
  @override
  void setPositionNormalized(num x, num y) =>
      setPosition((x * (width - 1)).floor(), (y * (height - 1)).floor());

  @override
  void setPosition(int x, int y) {
    _x = x;
    _y = y;
    final bpp = bitsPerPixel;
    _rowOffset = _y * image.rowStride;
    _index = _rowOffset + ((_x * bpp) >> 3);
    _bitIndex = (_x * bpp) & 0x7;
  }

  @override
  Pixel get current => this;

  @override
  bool moveNext() {
    _x++;
    if (x == width) {
      _x = 0;
      _y++;
      _bitIndex = 0;
      _index++;
      _rowOffset += image.rowStride;
      return _y < height;
    }

    final nc = numChannels;
    if (palette != null || nc == 1) {
      _bitIndex += 2;
      if (_bitIndex > 7) {
        _bitIndex = 0;
        _index++;
      }
    } else {
      final bpp = bitsPerPixel;
      _bitIndex = (x * bpp) & 0x7;
      _index = _rowOffset + ((x * bpp) >> 3);
    }

    return _index < image.data.length;
  }

  int _get(int ci) {
    var i = _index;
    var bi = 6 - (_bitIndex + (ci << 1));
    if (bi < 0) {
      bi += 8;
      i++;
    }
    return (image.data[i] >> bi) & 0x3;
  }

  num _getChannel(int ci) => palette == null
      ? numChannels > ci
          ? _get(ci)
          : 0
      : palette!.get(_get(0), ci);

  void _setChannel(int ci, num value) {
    if (ci >= image.numChannels) {
      return;
    }

    var i = _index;
    var bi = 6 - (_bitIndex + (ci << 1));
    if (bi < 0) {
      i++;
      bi += 8;
    }

    var v = data[i];
    final vi = value.toInt().clamp(0, 3);
    const msk = [0xfc, 0xf3, 0xcf, 0x3f];
    final mask = msk[bi >> 1];
    v = (v & mask) | (vi << bi);
    data[i] = v;
  }

  @override
  num operator [](int i) => _getChannel(i);

  @override
  void operator []=(int i, num value) => _setChannel(i, value);

  @override
  num get index => _get(0);
  @override
  set index(num i) => _setChannel(0, i);

  @override
  num get r => _getChannel(0);
  @override
  set r(num r) => _setChannel(0, r);

  @override
  num get g => _getChannel(1);
  @override
  set g(num g) => _setChannel(1, g);

  @override
  num get b => _getChannel(2);
  @override
  set b(num b) => _setChannel(2, b);

  @override
  num get a => _getChannel(3);
  @override
  set a(num a) => _setChannel(3, a);

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
      : channel.index < numChannels
          ? _getChannel(channel.index)
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
    final nc = image.numChannels;
    if (nc > 0) {
      _setChannel(0, r);
      if (nc > 1) {
        _setChannel(1, g);
        if (nc > 2) {
          _setChannel(2, b);
        }
      }
    }
  }

  @override
  void setRgba(num r, num g, num b, num a) {
    final nc = image.numChannels;
    if (nc > 0) {
      _setChannel(0, r);
      if (nc > 1) {
        _setChannel(1, g);
        if (nc > 2) {
          _setChannel(2, b);
          if (nc > 3) {
            _setChannel(3, a);
          }
        }
      }
    }
  }

  @override
  ChannelIterator get iterator => ChannelIterator(this);

  @override
  bool operator ==(Object? other) {
    if (other is PixelUint2) {
      return hashCode == other.hashCode;
    }
    if (other is List<int>) {
      final nc = palette != null ? palette!.numChannels : numChannels;
      if (other.length != nc) {
        return false;
      }
      if (_getChannel(0) != other[0]) {
        return false;
      }
      if (nc > 1) {
        if (_getChannel(1) != other[1]) {
          return false;
        }
        if (nc > 2) {
          if (_getChannel(2) != other[2]) {
            return false;
          }
          if (nc > 3) {
            if (_getChannel(3) != other[3]) {
              return false;
            }
          }
        }
      }
      return true;
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(toList());

  @override
  Color convert({Format? format, int? numChannels, num? alpha}) =>
      convertColor(this,
          format: format, numChannels: numChannels, alpha: alpha);
}
