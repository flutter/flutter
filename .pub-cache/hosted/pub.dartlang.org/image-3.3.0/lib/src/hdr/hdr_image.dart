import 'dart:typed_data';

import '../exif/exif_data.dart';
import '../image.dart';
import 'hdr_slice.dart';

/// A high dynamic range RGBA image stored in 16-bit or 32-bit floating-point
/// channels.
class HdrImage {
  static const UINT = 0;
  static const INT = 1;
  static const FLOAT = 3;

  /// Red value of a sample
  static const String R = 'R';

  /// Green value of a sample
  static const String G = 'G';

  /// Blue value of a sample
  static const String B = 'B';

  /// Alpha/opacity
  static const String A = 'A';

  /// Distance of the front of a sample from the viewer
  static const String Z = 'Z';

  /// A numerical identifier for the object represented by a sample.
  static const String ID = 'id';

  final Map<String?, HdrSlice> slices = {};
  HdrSlice? red;
  HdrSlice? green;
  HdrSlice? blue;
  HdrSlice? alpha;
  HdrSlice? depth;
  ExifData? exif;

  HdrImage();

  /// Create an RGB[A] image.
  HdrImage.create(
      int? width, int? height, int channels, int type, int bitsPerSample) {
    if (channels < 0 || channels > 4) {
      return;
    }
    const channelList = [R, G, B, A];
    for (var i = 0; i < channels; ++i) {
      addSlice(HdrSlice(channelList[i], width!, height!, type, bitsPerSample));
    }
  }

  /// Create a copy of the [other] HdrImage.
  HdrImage.from(HdrImage other) {
    for (final ch in other.slices.keys) {
      final slice = other.slices[ch]!;
      addSlice(HdrSlice.from(slice));
    }
  }

  /// Create an HDR image from a LDR [Image] by transforming the channel values
  /// to the range [0, 1].
  HdrImage.fromImage(Image other, {int type = FLOAT, int bitsPerSample = 16}) {
    addSlice(HdrSlice(R, other.width, other.height, type, bitsPerSample));
    addSlice(HdrSlice(G, other.width, other.height, type, bitsPerSample));
    addSlice(HdrSlice(B, other.width, other.height, type, bitsPerSample));
    if (other.channels == Channels.rgba) {
      addSlice(HdrSlice(A, other.width, other.height, type, bitsPerSample));
    }
    final rgb = other.getBytes();
    for (var y = 0, si = 0; y < other.height; ++y) {
      for (var x = 0; x < other.width; ++x) {
        red!.setFloat(x, y, rgb[si++] / 255.0);
        green!.setFloat(x, y, rgb[si++] / 255.0);
        blue!.setFloat(x, y, rgb[si++] / 255.0);
        if (alpha != null) {
          alpha!.setFloat(x, y, rgb[si++] / 255.0);
        }
      }
    }
  }

  /// Does the image have any color channels?
  bool get hasColor => red != null || green != null || blue != null;

  /// Does the image have an alpha channel?
  bool get hasAlpha => alpha != null;

  /// Does the image have a depth channel?
  bool get hasDepth => depth != null;

  /// The width of the framebuffer.
  int get width => slices.isEmpty ? 0 : slices.values.first.width;

  /// The height of the framebuffer.
  int get height => slices.isEmpty ? 0 : slices.values.first.height;

  /// Get the value of the red channel at the given pixel coordinates [x], [y].
  num getRed(int x, int y) => red != null
      ? red!.isFloat
          ? red!.getFloat(x, y)
          : red!.getInt(x, y)
      : 0;

  /// Set the value of the red channel at the given pixel coordinates [x], [y].
  void setRed(int x, int y, num c) {
    if (red != null) {
      if (red!.isFloat) {
        red!.setFloat(x, y, c);
      } else {
        red!.setInt(x, y, c as int);
      }
    }
  }

  void setRedInt(int x, int y, int c) {
    if (red != null) {
      red!.setInt(x, y, c);
    }
  }

  /// Get the value of the green channel at the given pixel coordinates [x], [y].
  num getGreen(int x, int y) => green != null
      ? green!.isFloat
          ? green!.getFloat(x, y)
          : green!.getInt(x, y)
      : 0;

  /// Set the value of the green channel at the given pixel coordinates [x], [y].
  void setGreen(int x, int y, num c) {
    if (green != null) {
      if (red!.isFloat) {
        green!.setFloat(x, y, c);
      } else {
        green!.setInt(x, y, c as int);
      }
    }
  }

  void setGreenInt(int x, int y, int c) {
    if (green != null) {
      green!.setInt(x, y, c);
    }
  }

  /// Get the value of the blue channel at the given pixel coordinates [x], [y].
  num getBlue(int x, int y) => blue != null
      ? blue!.isFloat
          ? blue!.getFloat(x, y)
          : blue!.getInt(x, y)
      : 0;

  /// Set the value of the blue channel at the given pixel coordinates [x], [y].
  void setBlue(int x, int y, num c) {
    if (green != null) {
      if (blue!.isFloat) {
        blue!.setFloat(x, y, c);
      } else {
        blue!.setInt(x, y, c as int);
      }
    }
  }

  void setBlueInt(int x, int y, int c) {
    if (blue != null) {
      blue!.setInt(x, y, c);
    }
  }

  /// Get the value of the alpha channel at the given pixel coordinates [x], [y].
  num getAlpha(int x, int y) => alpha != null
      ? alpha!.isFloat
          ? alpha!.getFloat(x, y)
          : alpha!.getInt(x, y)
      : 0;

  /// Set the value of the alpha channel at the given pixel coordinates [x], [y].
  void setAlpha(int x, int y, num c) {
    if (alpha != null) {
      if (alpha!.isFloat) {
        alpha!.setFloat(x, y, c);
      } else {
        alpha!.setInt(x, y, c as int);
      }
    }
  }

  void setAlphaInt(int x, int y, int c) {
    if (alpha != null) {
      alpha!.setInt(x, y, c);
    }
  }

  /// Get the value of the depth channel at the given pixel coordinates [x], [y].
  num getDepth(int x, int y) => depth != null
      ? depth!.isFloat
          ? depth!.getFloat(x, y)
          : depth!.getInt(x, y)
      : 0;

  /// Set the value of the depth channel at the given pixel coordinates [x], [y].
  void setDepth(int x, int y, num c) {
    if (depth != null) {
      if (depth!.isFloat) {
        depth!.setFloat(x, y, c);
      } else {
        depth!.setInt(x, y, c as int);
      }
    }
  }

  /// The number of bits per sample.
  int get bitsPerSample => red != null
      ? red!.bitsPerSample
      : slices.isEmpty
          ? 0
          : slices[slices.keys.first]!.bitsPerSample;

  int get sampleFormat => red != null
      ? red!.type
      : slices.isEmpty
          ? 0
          : slices[slices.keys.first]!.type;

  /// The number of channels used by the image
  int get numberOfChannels => slices.length;

  /// Does this image contain the given channel?
  bool hasChannel(String? ch) => slices.containsKey(ch);

  /// Access a framebuffer slice by name.
  HdrSlice? operator [](String? ch) => slices[ch];

  /// Add a channel [slice] to the
  void addSlice(HdrSlice slice) {
    final ch = slice.name;
    slices[ch] = slice;
    switch (ch) {
      case R:
        red = slice;
        break;
      case G:
        green = slice;
        break;
      case B:
        blue = slice;
        break;
      case A:
        alpha = slice;
        break;
      case Z:
        depth = slice;
        break;
    }
  }

  /// Convert the framebuffer to an floating-point image, as a sequence of
  /// floats in RGBA order.
  Float32List toFloatRgba() {
    final rgba = Float32List(width * height * 4);
    final w = width;
    final h = height;
    for (var y = 0, di = 0; y < h; ++y) {
      for (var x = 0; x < w; ++x) {
        rgba[di++] = red == null ? 0.0 : red!.getFloat(x, y);
        rgba[di++] = green == null ? 0.0 : green!.getFloat(x, y);
        rgba[di++] = blue == null ? 0.0 : blue!.getFloat(x, y);
        rgba[di++] = alpha == null ? 1.0 : alpha!.getFloat(x, y);
      }
    }

    return rgba;
  }
}
