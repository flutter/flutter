import 'dart:typed_data';

import '../color/color.dart';
import '../color/color_int8.dart';
import '../color/format.dart';
import 'image_data.dart';
import 'pixel.dart';
import 'pixel_int8.dart';
import 'pixel_range_iterator.dart';

class ImageDataInt8 extends ImageData {
  final Int8List data;

  ImageDataInt8(int width, int height, int numChannels)
      : data = Int8List(width * height * numChannels),
        super(width, height, numChannels);

  ImageDataInt8.from(ImageDataInt8 other, {bool skipPixels = false})
      : data = skipPixels
            ? Int8List(other.data.length)
            : Int8List.fromList(other.data),
        super(other.width, other.height, other.numChannels);

  @override
  ImageDataInt8 clone({bool noPixels = false}) =>
      ImageDataInt8.from(this, skipPixels: noPixels);

  @override
  Format get format => Format.int8;

  @override
  FormatType get formatType => FormatType.int;

  @override
  ByteBuffer get buffer => data.buffer;

  @override
  int get rowStride => width * numChannels;

  @override
  PixelInt8 get iterator => PixelInt8.imageData(this);

  @override
  Iterator<Pixel> getRange(int x, int y, int width, int height) =>
      PixelRangeIterator(PixelInt8.imageData(this), x, y, width, height);

  @override
  int get lengthInBytes => data.lengthInBytes;

  @override
  int get length => data.lengthInBytes;

  @override
  num get maxChannelValue => 0x7f;

  @override
  num get maxIndexValue => 0x7f;

  @override
  bool get isHdrFormat => true;

  @override
  int get bitsPerChannel => 8;

  @override
  Color getColor(num r, num g, num b, [num? a]) => a == null
      ? ColorInt8.rgb(r.toInt(), g.toInt(), b.toInt())
      : ColorInt8.rgba(r.toInt(), g.toInt(), b.toInt(), a.toInt());

  @override
  Pixel getPixel(int x, int y, [Pixel? pixel]) {
    if (pixel == null || pixel is! PixelInt8 || pixel.image != this) {
      pixel = PixelInt8.imageData(this);
    }
    pixel.setPosition(x, y);
    return pixel;
  }

  @override
  void setPixelR(int x, int y, num i) {
    final index = y * rowStride + (x * numChannels);
    data[index] = i.toInt();
  }

  @override
  void setPixelRgb(int x, int y, num r, num g, num b) {
    final index = y * rowStride + (x * numChannels);
    data[index] = r.toInt();
    if (numChannels > 1) {
      data[index + 1] = g.toInt();
      if (numChannels > 2) {
        data[index + 2] = b.toInt();
      }
    }
  }

  @override
  void setPixelRgba(int x, int y, num r, num g, num b, num a) {
    final index = y * rowStride + (x * numChannels);
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
  String toString() => 'ImageDataInt8($width, $height, $numChannels)';

  @override
  void clear([Color? c]) {}
}
