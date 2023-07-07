import 'dart:typed_data';

import '../color/color.dart';
import '../color/color_float64.dart';
import '../color/format.dart';
import 'image_data.dart';
import 'pixel.dart';
import 'pixel_float64.dart';
import 'pixel_range_iterator.dart';

class ImageDataFloat64 extends ImageData {
  final Float64List data;

  ImageDataFloat64(int width, int height, int numChannels)
      : data = Float64List(width * height * 4 * numChannels),
        super(width, height, numChannels);

  ImageDataFloat64.from(ImageDataFloat64 other, {bool skipPixels = false})
      : data = skipPixels
            ? Float64List(other.data.length)
            : Float64List.fromList(other.data),
        super(other.width, other.height, other.numChannels);

  @override
  ImageDataFloat64 clone({bool noPixels = false}) =>
      ImageDataFloat64.from(this, skipPixels: noPixels);

  @override
  Format get format => Format.float64;

  @override
  FormatType get formatType => FormatType.float;

  @override
  ByteBuffer get buffer => data.buffer;

  @override
  int get length => data.lengthInBytes;

  @override
  int get bitsPerChannel => 64;

  @override
  PixelFloat64 get iterator => PixelFloat64.imageData(this);

  @override
  Iterator<Pixel> getRange(int x, int y, int width, int height) =>
      PixelRangeIterator(PixelFloat64.imageData(this), x, y, width, height);

  @override
  int get lengthInBytes => data.lengthInBytes;

  @override
  num get maxChannelValue => 1.0;

  @override
  num get maxIndexValue => 1.0;

  @override
  int get rowStride => width * numChannels * 8;

  @override
  bool get isHdrFormat => true;

  @override
  Color getColor(num r, num g, num b, [num? a]) =>
      a == null ? ColorFloat64.rgb(r, g, b) : ColorFloat64.rgba(r, g, b, a);

  @override
  Pixel getPixel(int x, int y, [Pixel? pixel]) {
    if (pixel == null || pixel is! PixelFloat64 || pixel.image != this) {
      pixel = PixelFloat64.imageData(this);
    }
    pixel.setPosition(x, y);
    return pixel;
  }

  @override
  void setPixelR(int x, int y, num i) {
    final index = y * width * numChannels + (x * numChannels);
    data[index] = i.toDouble();
  }

  @override
  void setPixelRgb(int x, int y, num r, num g, num b) {
    final index = y * width * numChannels + (x * numChannels);
    data[index] = r.toDouble();
    if (numChannels > 1) {
      data[index + 1] = g.toDouble();
      if (numChannels > 2) {
        data[index + 2] = b.toDouble();
      }
    }
  }

  @override
  void setPixelRgba(int x, int y, num r, num g, num b, num a) {
    final index = y * width * numChannels + (x * numChannels);
    data[index] = r.toDouble();
    if (numChannels > 1) {
      data[index + 1] = g.toDouble();
      if (numChannels > 2) {
        data[index + 2] = b.toDouble();
        if (numChannels > 3) {
          data[index + 3] = a.toDouble();
        }
      }
    }
  }

  @override
  String toString() => 'ImageDataFloat64($width, $height, $numChannels)';

  @override
  void clear([Color? c]) {}
}
