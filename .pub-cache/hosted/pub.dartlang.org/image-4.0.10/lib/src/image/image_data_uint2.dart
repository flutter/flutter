import 'dart:math';
import 'dart:typed_data';

import '../color/color.dart';
import '../color/color_uint2.dart';
import '../color/format.dart';
import 'image_data.dart';
import 'palette.dart';
import 'pixel.dart';
import 'pixel_range_iterator.dart';
import 'pixel_uint2.dart';

class ImageDataUint2 extends ImageData {
  late final Uint8List data;
  @override
  final int rowStride;
  @override
  final Palette? palette;

  ImageDataUint2(int width, int height, int numChannels)
      : rowStride = ((width * (numChannels << 1)) / 8).ceil(),
        palette = null,
        super(width, height, numChannels) {
    data = Uint8List(max(rowStride * height, 1));
  }

  ImageDataUint2.palette(int width, int height, this.palette)
      : rowStride = (width / 4).ceil(),
        super(width, height, 1) {
    data = Uint8List(max(rowStride * height, 1));
  }

  ImageDataUint2.from(ImageDataUint2 other, {bool skipPixels = false})
      : data = skipPixels
            ? Uint8List(other.data.length)
            : Uint8List.fromList(other.data),
        rowStride = other.rowStride,
        palette = other.palette?.clone(),
        super(other.width, other.height, other.numChannels);

  @override
  ImageDataUint2 clone({bool noPixels = false}) =>
      ImageDataUint2.from(this, skipPixels: noPixels);

  @override
  Format get format => Format.uint2;

  @override
  FormatType get formatType => FormatType.uint;

  @override
  int get bitsPerChannel => 2;

  @override
  ByteBuffer get buffer => data.buffer;

  @override
  PixelUint2 get iterator => PixelUint2.imageData(this);

  @override
  Iterator<Pixel> getRange(int x, int y, int width, int height) =>
      PixelRangeIterator(PixelUint2.imageData(this), x, y, width, height);

  @override
  int get lengthInBytes => data.lengthInBytes;

  @override
  int get length => data.lengthInBytes;

  @override
  num get maxChannelValue => palette?.maxChannelValue ?? 3;

  @override
  num get maxIndexValue => 3;

  @override
  bool get isHdrFormat => false;

  @override
  Color getColor(num r, num g, num b, [num? a]) => a == null
      ? ColorUint2.rgb(r.toInt(), g.toInt(), b.toInt())
      : ColorUint2.rgba(r.toInt(), g.toInt(), b.toInt(), a.toInt());

  @override
  Pixel getPixel(int x, int y, [Pixel? pixel]) {
    if (pixel == null || pixel is! PixelUint2 || pixel.image != this) {
      pixel = PixelUint2.imageData(this);
    }
    pixel.setPosition(x, y);
    return pixel;
  }

  PixelUint2? _pixel;

  @override
  void setPixelR(int x, int y, num i) {
    if (numChannels < 1) {
      return;
    }
    _pixel ??= PixelUint2.imageData(this);
    _pixel!.setPosition(x, y);
    _pixel!.index = i;
  }

  @override
  void setPixelRgb(int x, int y, num r, num g, num b) {
    if (numChannels < 1) {
      return;
    }
    _pixel ??= PixelUint2.imageData(this);
    _pixel!.setPosition(x, y);
    _pixel!.setRgb(r, g, b);
  }

  @override
  void setPixelRgba(int x, int y, num r, num g, num b, num a) {
    if (numChannels < 1) {
      return;
    }
    _pixel ??= PixelUint2.imageData(this);
    _pixel!.setPosition(x, y);
    _pixel!.setRgba(r, g, b, a);
  }

  @override
  String toString() => 'ImageDataUint2($width, $height, $numChannels)';

  @override
  void clear([Color? c]) {}
}
