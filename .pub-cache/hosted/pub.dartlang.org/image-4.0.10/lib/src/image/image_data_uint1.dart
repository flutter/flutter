import 'dart:math';
import 'dart:typed_data';

import '../color/color.dart';
import '../color/color_uint1.dart';
import '../color/format.dart';
import 'image_data.dart';
import 'palette.dart';
import 'pixel.dart';
import 'pixel_range_iterator.dart';
import 'pixel_uint1.dart';

class ImageDataUint1 extends ImageData {
  late final Uint8List data;
  @override
  final int rowStride;
  @override
  final Palette? palette;

  ImageDataUint1(int width, int height, int numChannels)
      : rowStride = ((width * numChannels) / 8).ceil(),
        palette = null,
        super(width, height, numChannels) {
    data = Uint8List(max(rowStride * height, 1));
  }

  ImageDataUint1.palette(int width, int height, this.palette)
      : rowStride = (width / 8).ceil(),
        super(width, height, 1) {
    data = Uint8List(max(rowStride * height, 1));
  }

  ImageDataUint1.from(ImageDataUint1 other, {bool skipPixels = false})
      : data = skipPixels
            ? Uint8List(other.data.length)
            : Uint8List.fromList(other.data),
        rowStride = other.rowStride,
        palette = other.palette?.clone(),
        super(other.width, other.height, other.numChannels);

  @override
  ImageDataUint1 clone({bool noPixels = false}) =>
      ImageDataUint1.from(this, skipPixels: noPixels);

  @override
  Format get format => Format.uint1;

  @override
  FormatType get formatType => FormatType.uint;

  @override
  int get lengthInBytes => data.lengthInBytes;

  @override
  int get length => data.lengthInBytes;

  @override
  num get maxChannelValue => palette?.maxChannelValue ?? 1;

  @override
  num get maxIndexValue => 1;

  @override
  bool get isHdrFormat => false;

  @override
  ByteBuffer get buffer => data.buffer;

  @override
  int get bitsPerChannel => 1;

  @override
  PixelUint1 get iterator => PixelUint1.imageData(this);

  @override
  Iterator<Pixel> getRange(int x, int y, int width, int height) =>
      PixelRangeIterator(PixelUint1.imageData(this), x, y, width, height);

  @override
  Color getColor(num r, num g, num b, [num? a]) => a == null
      ? ColorUint1.rgb(r.toInt(), g.toInt(), b.toInt())
      : ColorUint1.rgba(r.toInt(), g.toInt(), b.toInt(), a.toInt());

  @override
  Pixel getPixel(int x, int y, [Pixel? pixel]) {
    if (pixel == null || pixel is! PixelUint1 || pixel.image != this) {
      pixel = PixelUint1.imageData(this);
    }
    pixel.setPosition(x, y);
    return pixel;
  }

  PixelUint1? _pixel;

  @override
  void setPixelR(int x, int y, num i) {
    if (numChannels < 1) {
      return;
    }
    _pixel ??= PixelUint1.imageData(this);
    _pixel!.setPosition(x, y);
    _pixel!.index = i;
  }

  @override
  void setPixelRgb(int x, int y, num r, num g, num b) {
    if (numChannels < 1) {
      return;
    }
    _pixel ??= PixelUint1.imageData(this);
    _pixel!.setPosition(x, y);
    _pixel!.setRgb(r, g, b);
  }

  @override
  void setPixelRgba(int x, int y, num r, num g, num b, num a) {
    if (numChannels < 1) {
      return;
    }
    _pixel ??= PixelUint1.imageData(this);
    _pixel!.setPosition(x, y);
    _pixel!.setRgba(r, g, b, a);
  }

  @override
  String toString() => 'ImageDataUint1($width, $height, $numChannels)';

  @override
  void clear([Color? c]) {}
}
