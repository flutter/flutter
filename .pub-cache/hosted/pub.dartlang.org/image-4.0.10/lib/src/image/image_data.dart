import 'dart:typed_data';

import '../color/channel_order.dart';
import '../color/color.dart';
import '../color/format.dart';
import 'palette.dart';
import 'pixel.dart';

abstract class ImageData extends Iterable<Pixel> {
  final int width;
  final int height;
  final int numChannels;

  ImageData(this.width, this.height, this.numChannels);

  ImageData clone({bool noPixels = false});

  /// The channel [Format] of the image.
  Format get format;

  /// Whether th image has uint, int, or float data.
  FormatType get formatType;

  /// True if the image format is "high dynamic range." HDR formats include:
  /// float16, float32, float64, int8, int16, and int32.
  bool get isHdrFormat;

  /// True if the image format is "low dynamic range." LDR formats include:
  /// uint1, uint2, uint4, and uint8.
  bool get isLdrFormat => !isHdrFormat;

  /// The number of bits per color channel. Can be 1, 2, 4, 8, 16, 32, or 64.
  int get bitsPerChannel;

  /// The maximum value of a pixel channel, based on the [format] of the image.
  /// If the image has a [palette], this will be the maximum value of a palette
  /// color channel. Float format images will have a maxChannelValue of 1.0,
  /// though they can have values above that.
  num get maxChannelValue;

  /// The maximum value of a palette index, based on the [format] of the image.
  /// This differs from [maxChannelValue] in that it will not be affected by
  /// the format of the [palette].
  num get maxIndexValue;

  /// True if the image has a palette. If the image has a palette, then the
  /// image data has 1 channel for the palette index of the pixel.
  bool get hasPalette => palette != null;

  /// The [Palette] of the image, or null if the image does not have one.
  Palette? get palette => null;

  /// The size of the image data in bytes
  int get lengthInBytes;

  /// The size of the image data in bytes.
  @override
  int get length;

  /// The [ByteBuffer] storage of the image.
  ByteBuffer get buffer;

  /// The storage data of the image.
  Uint8List toUint8List() => buffer.asUint8List();

  /// Similar to toUint8List, but will convert the channels of the image pixels
  /// to the given [order]. If that happens, the returned bytes will be a copy
  /// and not a direct view of the image data.
  Uint8List getBytes({ChannelOrder? order}) {
    if (order == null) {
      return toUint8List();
    }

    if (numChannels == 4) {
      if (order == ChannelOrder.abgr ||
          order == ChannelOrder.argb ||
          order == ChannelOrder.bgra) {
        final tempImage = clone();
        if (order == ChannelOrder.abgr) {
          for (final p in tempImage) {
            final r = p.r;
            final g = p.g;
            final b = p.b;
            final a = p.a;
            p
              ..r = a
              ..g = b
              ..b = g
              ..a = r;
          }
        } else if (order == ChannelOrder.argb) {
          for (final p in tempImage) {
            final r = p.r;
            final g = p.g;
            final b = p.b;
            final a = p.a;
            p
              ..r = a
              ..g = r
              ..b = g
              ..a = b;
          }
        } else if (order == ChannelOrder.bgra) {
          for (final p in tempImage) {
            final r = p.r;
            final g = p.g;
            final b = p.b;
            final a = p.a;
            p
              ..r = b
              ..g = g
              ..b = r
              ..a = a;
          }
        }
        return tempImage.toUint8List();
      }
    } else if (numChannels == 3) {
      if (order == ChannelOrder.bgr) {
        final tempImage = clone();
        for (final p in tempImage) {
          final r = p.r;
          p
            ..r = p.b
            ..b = r;
        }
        return tempImage.toUint8List();
      }
    }

    return toUint8List();
  }

  /// The size, in bytes, of a row if pixels in the data.
  int get rowStride;

  /// Returns a pixel iterator for iterating over a rectangular range of pixels
  /// in the image.
  Iterator<Pixel> getRange(int x, int y, int width, int height);

  /// Create a [Color] object with the format and number of channels of the
  /// image.
  Color getColor(num r, num g, num b, [num? a]);

  /// Return the [Pixel] at the given coordinates. If [pixel] is provided,
  /// it will be updated and returned rather than allocating a new [Pixel].
  Pixel getPixel(int x, int y, [Pixel? pixel]);

  /// Set the color of the pixel at the given coordinates to the color of the
  /// given Color [c].
  void setPixel(int x, int y, Color c) {
    setPixelRgba(x, y, c.r, c.g, c.b, c.a);
  }

  /// Set the red channel of the pixel, or the index value for palette images.
  void setPixelR(int x, int y, num i);

  /// Set the color of the [Pixel] at the given coordinates to the given
  /// color values [r], [g], [b].
  void setPixelRgb(int x, int y, num r, num g, num b);

  /// Set the color of the [Pixel] at the given coordinates to the given
  /// color values [r], [g], [b], and [a].
  void setPixelRgba(int x, int y, num r, num g, num b, num a);

  /// Calls setPixelRgb, but ensures [x] and [y] are within the extents
  /// of the image, otherwise it returns without setting the pixel.
  void setPixelRgbSafe(int x, int y, num r, num g, num b) {
    if (x < 0 || x >= width || y < 0 || y >= height) {
      return;
    }
    setPixelRgb(x, y, r, g, b);
  }

  /// Calls setPixelRgba, but ensures [x] and [y] are within the extents
  /// of the image, otherwise it returns without setting the pixel.
  void setPixelRgbaSafe(int x, int y, num r, num g, num b, num a) {
    if (x < 0 || x >= width || y < 0 || y >= height) {
      return;
    }
    setPixelRgba(x, y, r, g, b, a);
  }

  /// Set all of the pixels to the Color [c], or all values to 0 if [c] is not
  /// given.
  void clear([Color? c]);
}
