import 'dart:typed_data';

import '../color/channel.dart';
import '../color/channel_iterator.dart';
import '../color/color.dart';
import '../color/format.dart';
import '../util/color_util.dart';
import 'image.dart';
import 'image_data_uint8.dart';
import 'palette.dart';
import 'pixel.dart';

class PixelUint8 extends Iterable<num> implements Pixel {
  int _x;
  int _y;
  int _index;
  @override
  final ImageDataUint8 image;

  PixelUint8.imageData(this.image)
      : _x = -1,
        _y = 0,
        _index = -image.numChannels;

  PixelUint8.image(Image image)
      : _x = -1,
        _y = 0,
        _index = -image.numChannels,
        image = image.data is ImageDataUint8
            ? image.data as ImageDataUint8
            : ImageDataUint8(0, 0, 0);

  PixelUint8.from(PixelUint8 other)
      : _x = other.x,
        _y = other.y,
        _index = other._index,
        image = other.image;

  @override
  PixelUint8 clone() => PixelUint8.from(this);

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
  Format get format => Format.uint8;

  @override
  bool get isLdrFormat => image.isLdrFormat;

  @override
  bool get isHdrFormat => image.isHdrFormat;

  @override
  bool get isValid =>
      x >= 0 && x < (image.width - 1) && y >= 0 && y < (image.height - 1);

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
    _index = _y * image.width * image.numChannels + (_x * image.numChannels);
  }

  @override
  Pixel get current => this;

  @override
  bool moveNext() {
    _x++;
    if (_x == width) {
      _x = 0;
      _y++;
      if (_y == height) {
        return false;
      }
    }
    _index += palette == null ? numChannels : 1;
    return _index < image.data.length;
  }

  void updateCache() {}

  num get(int ci) => palette != null
      ? palette!.get(data[_index], ci)
      : ci < numChannels
          ? data[_index + ci]
          : 0;

  @override
  num operator [](int ci) => get(ci);

  @override
  void operator []=(int ci, num value) {
    if (ci < numChannels) {
      data[_index + ci] = value.clamp(0, 255).toInt();
    }
  }

  @override
  num get index => data[_index];
  @override
  set index(num i) => data[_index] = i.clamp(0, 255).toInt();

  @override
  num get r => palette == null
      ? numChannels > 0
          ? data[_index]
          : 0
      : palette!.getRed(data[_index]);

  @override
  set r(num r) {
    if (image.numChannels > 0) {
      data[_index] = r.clamp(0, 255).toInt();
    }
  }

  @override
  num get g => palette == null
      ? numChannels > 1
          ? data[_index + 1]
          : 0
      : palette!.getGreen(data[_index]);

  @override
  set g(num g) {
    if (image.numChannels > 1) {
      data[_index + 1] = g.clamp(0, 255).toInt();
    }
  }

  @override
  num get b => palette == null
      ? numChannels > 2
          ? data[_index + 2]
          : 0
      : palette!.getBlue(data[_index]);

  @override
  set b(num b) {
    if (image.numChannels > 2) {
      data[_index + 2] = b.clamp(0, 255).toInt();
    }
  }

  @override
  num get a => palette == null
      ? numChannels > 3
          ? data[_index + 3]
          : 255
      : palette!.getAlpha(data[_index]);

  @override
  set a(num a) {
    if (image.numChannels > 3) {
      data[_index + 3] = a.clamp(0, 255).toInt();
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
      : channel.index < numChannels
          ? data[_index + channel.index]
          : 0;

  @override
  num getChannelNormalized(Channel channel) =>
      getChannel(channel) / maxChannelValue;

  @override
  void set(Color c) {
    if (image.hasPalette) {
      index = c.index;
    } else {
      r = c.r;
      g = c.g;
      b = c.b;
      a = c.a;
    }
  }

  @override
  void setRgb(num r, num g, num b) {
    if (numChannels > 0) {
      data[_index] = r.toInt();
      if (numChannels > 1) {
        data[_index + 1] = g.toInt();
        if (numChannels > 2) {
          data[_index + 2] = b.toInt();
        }
      }
    }
  }

  @override
  void setRgba(num r, num g, num b, num a) {
    if (numChannels > 0) {
      data[_index] = r.toInt();
      if (numChannels > 1) {
        data[_index + 1] = g.toInt();
        if (numChannels > 2) {
          data[_index + 2] = b.toInt();
          if (numChannels > 3) {
            data[_index + 3] = a.toInt();
          }
        }
      }
    }
  }

  @override
  ChannelIterator get iterator => ChannelIterator(this);

  @override
  bool operator ==(Object? other) {
    if (other is PixelUint8) {
      return hashCode == other.hashCode;
    }
    if (other is List<int>) {
      final nc = palette != null ? palette!.numChannels : numChannels;
      if (other.length != nc) {
        return false;
      }
      if (get(0) != other[0]) {
        return false;
      }
      if (nc > 1) {
        if (get(1) != other[1]) {
          return false;
        }
        if (nc > 2) {
          if (get(2) != other[2]) {
            return false;
          }
          if (nc > 3) {
            if (get(3) != other[3]) {
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
