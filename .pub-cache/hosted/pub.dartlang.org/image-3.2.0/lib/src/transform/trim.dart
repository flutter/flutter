import '../color.dart';
import '../image.dart';
import '../transform/copy_into.dart';

class Trim {
  /// Trim the image down from the top.
  static const top = Trim._internal(1);

  /// Trim the image up from the bottom.
  static const bottom = Trim._internal(2);

  /// Trim the left edge of the image.
  static const left = Trim._internal(4);

  /// Trim the right edge of the image.
  static const right = Trim._internal(8);

  /// Trim all edges of the image.
  static const all = Trim._internal(1 | 2 | 4 | 8);

  final int _value;
  const Trim._internal(this._value);

  Trim operator |(Trim rhs) => Trim._internal(_value | rhs._value);
  bool operator &(Trim rhs) => (_value & rhs._value) != 0;
}

enum TrimMode {
  /// Trim an image to the top-left and bottom-right most non-transparent pixels
  transparent,

  /// Trim an image to the top-left and bottom-right most pixels that are not the
  /// same as the top-left most pixel of the image.
  topLeftColor,

  /// Trim an image to the top-left and bottom-right most pixels that are not the
  /// same as the bottom-right most pixel of the image.
  bottomRightColor
}

/// Find the crop area to be used by the trim function. Returns the
/// coordinates as [x, y, width, height]. You could pass these coordinates
/// to the [copyCrop] function to crop the image.
List<int> findTrim(Image src,
    {TrimMode mode = TrimMode.transparent, Trim sides = Trim.all}) {
  var h = src.height;
  var w = src.width;

  final bg = (mode == TrimMode.topLeftColor)
      ? src.getPixel(0, 0)
      : (mode == TrimMode.bottomRightColor)
          ? src.getPixel(w - 1, h - 1)
          : 0;

  var xmin = w;
  var xmax = 0;
  int? ymin;
  var ymax = 0;

  for (var y = 0; y < h; ++y) {
    var first = true;
    for (var x = 0; x < w; ++x) {
      final c = src.getPixel(x, y);
      if ((mode == TrimMode.transparent && getAlpha(c) != 0) ||
          (mode != TrimMode.transparent && (c != bg))) {
        if (xmin > x) {
          xmin = x;
        }
        if (xmax < x) {
          xmax = x;
        }
        ymin ??= y;

        ymax = y;

        if (first) {
          x = xmax;
          first = false;
        }
      }
    }
  }

  // A trim wasn't found
  if (ymin == null) {
    return [0, 0, w, h];
  }

  if (sides & Trim.top == false) {
    ymin = 0;
  }
  if (sides & Trim.bottom == false) {
    ymax = h - 1;
  }
  if (sides & Trim.left == false) {
    xmin = 0;
  }
  if (sides & Trim.right == false) {
    xmax = w - 1;
  }

  w = 1 + xmax - xmin; // Image width in pixels
  h = 1 + ymax - ymin; // Image height in pixels

  return [xmin, ymin, w, h];
}

/// Automatically crops the image by finding the corners of the image that
/// meet the [mode] criteria (not transparent or a different color).
///
/// [mode] can be either [TrimMode.transparent], [TrimMode.topLeftColor] or
/// [TrimMode.bottomRightColor].
///
/// [sides] can be used to control which sides of the image get trimmed,
/// and can be any combination of [Trim.top], [Trim.bottom], [Trim.left],
/// and [Trim.right].
Image trim(Image src,
    {TrimMode mode = TrimMode.transparent, Trim sides = Trim.all}) {
  if (mode == TrimMode.transparent && src.channels == Channels.rgb) {
    return Image.from(src);
  }

  final crop = findTrim(src, mode: mode, sides: sides);

  final dst = Image(crop[2], crop[3], exif: src.exif, iccp: src.iccProfile);

  copyInto(dst, src,
      srcX: crop[0], srcY: crop[1], srcW: crop[2], srcH: crop[3], blend: false);

  return dst;
}
