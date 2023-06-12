import 'dart:typed_data';

import '../color/color.dart';
import '../color/color_uint16.dart';
import '../color/format.dart';
import 'image_data.dart';
import 'pixel.dart';
import 'pixel_range_iterator.dart';
import 'pixel_uint16.dart';

class ImageDataUint16 extends ImageData {
  final Uint16List data;

  ImageDataUint16(int width, int height, int numChannels)
      : data = Uint16List(width * height * numChannels),
        super(width, height, numChannels);

  ImageDataUint16.from(ImageDataUint16 other, {bool skipPixels = false})
      : data = skipPixels
            ? Uint16List(other.data.length)
            : Uint16List.fromList(other.data),
        super(other.width, other.height, other.numChannels);

  @override
  ImageDataUint16 clone({bool noPixels = false}) =>
      ImageDataUint16.from(this, skipPixels: noPixels);

  @override
  Format get format => Format.uint16;

  @override
  FormatType get formatType => FormatType.uint;

  @override
  ByteBuffer get buffer => data.buffer;

  @override
  int get bitsPerChannel => 16;

  @override
  num get maxChannelValue => 0xffff;

  @override
  num get maxIndexValue => 0xffff;

  @override
  int get rowStride => width * numChannels * 2;

  @override
  PixelUint16 get iterator => PixelUint16.imageData(this);

  @override
  Iterator<Pixel> getRange(int x, int y, int width, int height) =>
      PixelRangeIterator(PixelUint16.imageData(this), x, y, width, height);

  @override
  int get lengthInBytes => data.lengthInBytes;

  @override
  int get length => data.lengthInBytes;

  @override
  bool get isHdrFormat => true;

  @override
  Color getColor(num r, num g, num b, [num? a]) => a == null
      ? ColorUint16.rgb(r.toInt(), g.toInt(), b.toInt())
      : ColorUint16.rgba(r.toInt(), g.toInt(), b.toInt(), a.toInt());

  @override
  Pixel getPixel(int x, int y, [Pixel? pixel]) {
    if (pixel == null || pixel is! PixelUint16 || pixel.image != this) {
      pixel = PixelUint16.imageData(this);
    }
    pixel.setPosition(x, y);
    return pixel;
  }

  @override
  void setPixelR(int x, int y, num i) {
    final index = y * width * numChannels + (x * numChannels);
    data[index] = i.toInt();
  }

  @override
  void setPixelRgb(int x, int y, num r, num g, num b) {
    final index = y * width * numChannels + (x * numChannels);
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
    final index = y * width * numChannels + (x * numChannels);
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
  String toString() => 'ImageDataUint16($width, $height, $numChannels)';

  @override
  void clear([Color? c]) {}
}
