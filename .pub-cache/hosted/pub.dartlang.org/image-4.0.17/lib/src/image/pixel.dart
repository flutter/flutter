import '../color/color.dart';
import 'image_data.dart';
import 'pixel_undefined.dart';

abstract class Pixel extends Iterator<Pixel> implements Color {
  /// [undefined] is used to represent an invalid pixel.
  static Pixel get undefined => PixelUndefined();

  /// The [ImageData] this pixel refers to.
  ImageData get image;

  /// True if this points to a valid pixel, otherwise false.
  bool get isValid;

  /// The width in pixels of the image data this pixel refers to.
  int get width;

  /// The height in pixels of the image data this pixel refers to.
  int get height;

  /// The x coordinate of the pixel.
  int get x;

  /// The y coordinate of the pixel.
  int get y;

  /// The normalized x coordinate of the pixel, in the range \[0, 1\].
  num get xNormalized;

  /// The normalized y coordinate of the pixel, in the range \[0, 1\].
  num get yNormalized;

  /// Set the coordinates of the pixel.
  void setPosition(int x, int y);

  /// Set the normalized coordinates of the pixel, in the range \[0, 1\].
  void setPositionNormalized(num x, num y);

  /// Move to the next pixel, returning false if it moved past the end of
  /// the image data.
  @override
  bool moveNext();

  /// The current pixel (this), for using Pixel as an iterator.
  @override
  Pixel get current;

  /// Tests if this pixel has the same values as the given pixel or color.
  @override
  bool operator ==(Object? other);

  /// Calculate the hash code for this pixel.
  @override
  int get hashCode;
}
