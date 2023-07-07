import 'dart:math';
import 'dart:typed_data';

import '../color/channel_order.dart';
import '../color/color.dart';
import '../color/color_uint8.dart';
import '../color/format.dart';
import '../exif/exif_data.dart';
import '../util/color_util.dart';
import '../util/image_exception.dart';
import 'icc_profile.dart';
import 'image_data.dart';
import 'image_data_float16.dart';
import 'image_data_float32.dart';
import 'image_data_float64.dart';
import 'image_data_int16.dart';
import 'image_data_int32.dart';
import 'image_data_int8.dart';
import 'image_data_uint1.dart';
import 'image_data_uint16.dart';
import 'image_data_uint2.dart';
import 'image_data_uint32.dart';
import 'image_data_uint4.dart';
import 'image_data_uint8.dart';
import 'interpolation.dart';
import 'palette.dart';
import 'palette_float16.dart';
import 'palette_float32.dart';
import 'palette_float64.dart';
import 'palette_int16.dart';
import 'palette_int32.dart';
import 'palette_int8.dart';
import 'palette_uint16.dart';
import 'palette_uint32.dart';
import 'palette_uint8.dart';
import 'pixel.dart';

/// The type of image this frame represents. Multi-page formats, such as
/// Tiff, can represent the frames of an animation as pages in a document.
enum FrameType {
  /// The frames of this document are to be interpreted as animation.
  animation,

  /// The frames of this document are to be interpreted as pages of a document.
  page,

  /// The frames of this document are to be interpreted as a sequence of images.
  sequence
}

/// An Image is a container for [ImageData] and other various meta-data
/// representing an image in memory.
class Image extends Iterable<Pixel> {
  ImageData? data;

  /// Named non-color channels used by this image.
  Map<String, ImageData>? extraChannels;
  IccProfile? iccProfile;
  Map<String, String>? textData;
  ExifData? _exif;

  /// The suggested background color to clear the canvas with.
  Color? backgroundColor;

  /// How many times should the animation loop (0 means forever)?
  int loopCount;

  /// How should the frames be interpreted?  If [FrameType.animation], the
  /// frames are part of an animated sequence. If [FrameType.page], the frames
  /// are the pages of a document.
  FrameType frameType;

  /// The list of sub-frames for the image, if it's an animation. An image
  /// is considered animated if it has more than one frame, as the first
  /// frame will be the image itself.
  late List<Image> frames = [];

  /// How long this frame should be displayed, in milliseconds.
  /// A duration of 0 indicates no delay and the next frame will be drawn
  /// as quickly as it can.
  int frameDuration;

  /// Index of this image in the parent animations frame list.
  int frameIndex;

  /// Creates an image with the given dimensions and format.
  Image(
      {required int width,
      required int height,
      Format format = Format.uint8,
      int numChannels = 3,
      bool withPalette = false,
      Format paletteFormat = Format.uint8,
      Palette? palette,
      ExifData? exif,
      IccProfile? iccp,
      this.textData,
      this.loopCount = 0,
      this.frameType = FrameType.sequence,
      this.backgroundColor,
      this.frameDuration = 0,
      this.frameIndex = 0}) {
    frames.add(this);
    _initialize(width, height,
        format: format,
        numChannels: numChannels,
        withPalette: withPalette,
        paletteFormat: paletteFormat,
        palette: palette,
        exif: exif,
        iccp: iccp);
  }

  Image.fromResized(Image other,
      {required int width, required int height, bool noAnimation = false})
      : _exif = other._exif?.clone(),
        iccProfile = other.iccProfile?.clone(),
        frameType = other.frameType,
        loopCount = other.loopCount,
        backgroundColor = other.backgroundColor?.clone(),
        frameDuration = other.frameDuration,
        frameIndex = other.frameIndex {
    _createImageData(
        width, height, other.format, other.numChannels, other.palette);

    if (other.extraChannels != null) {
      extraChannels = Map<String, ImageData>.from(other.extraChannels!);
    }
    if (other.textData != null) {
      textData = Map<String, String>.from(other.textData!);
    }
    frames.add(this);

    if (!noAnimation) {
      final numFrames = other.numFrames;
      for (var fi = 1; fi < numFrames; ++fi) {
        final frame = other.frames[fi];
        addFrame(Image.fromResized(frame, width: width, height: height));
      }
    }
  }

  /// Creates a copy of the given Image [other].
  Image.from(Image other, {bool noAnimation = false, bool noPixels = false})
      : data = other.data?.clone(noPixels: noPixels),
        _exif = other._exif?.clone(),
        iccProfile = other.iccProfile?.clone(),
        frameType = other.frameType,
        loopCount = other.loopCount,
        backgroundColor = other.backgroundColor?.clone(),
        frameDuration = other.frameDuration,
        frameIndex = other.frameIndex {
    if (other.extraChannels != null) {
      extraChannels = Map<String, ImageData>.from(other.extraChannels!);
    }
    if (other.textData != null) {
      textData = Map<String, String>.from(other.textData!);
    }
    frames.add(this);
    if (!noAnimation && other.hasAnimation) {
      final numFrames = other.numFrames;
      for (var fi = 1; fi < numFrames; ++fi) {
        final frame = other.frames[fi];
        addFrame(Image.from(frame));
      }
    }
  }

  /// Creates an empty image.
  Image.empty()
      : loopCount = 0,
        frameType = FrameType.sequence,
        frameDuration = 0,
        frameIndex = 0;

  /// Create an image from raw data in [bytes].
  ///
  /// [format] defines the order of color channels in [bytes].
  /// An HTML canvas element stores colors in Format.rgba format; a Flutter
  /// Image object stores colors in Format.rgba format.
  ///
  /// [rowStride] is the row stride, in bytes, of the source data [bytes].
  /// This may be different than the rowStride of the [Image], as some data
  /// sources align rows to different byte alignments and include padding.
  ///
  /// [order] can be used if the source [bytes] has a different channel order
  /// than RGBA. [ChannelOrder].bgra will rearrange the color channels from
  /// BGRA to what Image wants, RGBA.
  ///
  /// If [numChannels] and [order] are not provided, a default of 3 for
  /// [numChannels] and [ChannelOrder].rgba for [order] will be assumed.
  ///
  /// For example, given an Html Canvas, you could create an image:
  /// var bytes = canvas.getContext('2d').getImageData(0, 0,
  ///   canvas.width, canvas.height).data;
  /// var image = Image.fromBytes(width: canvas.width, height: canvas.height,
  ///     bytes: canvasBytes, numChannels: 4);
  Image.fromBytes(
      {required int width,
      required int height,
      required ByteBuffer bytes,
      int bytesOffset = 0,
      Format format = Format.uint8,
      int? numChannels,
      int? rowStride,
      bool withPalette = false,
      Format paletteFormat = Format.uint8,
      Palette? palette,
      ExifData? exif,
      IccProfile? iccp,
      ChannelOrder? order,
      this.textData,
      this.loopCount = 0,
      this.frameType = FrameType.sequence,
      this.backgroundColor,
      this.frameDuration = 0,
      this.frameIndex = 0}) {
    frames.add(this);

    numChannels ??= order != null ? channelOrderLength[order] : 3;

    if (numChannels! < 0 || numChannels > 4) {
      throw ImageException('An Image can only have 1-4 channels.');
    }

    order ??= numChannels == 3
        ? ChannelOrder.rgb
        : numChannels == 4
            ? ChannelOrder.rgba
            : numChannels == 1
                ? ChannelOrder.red
                : ChannelOrder.grayAlpha;

    if (numChannels == 1) {
      // There is only one channel order
      order = ChannelOrder.red;
    } else if (numChannels == 2) {
      // There is only one channel order
      order = ChannelOrder.grayAlpha;
    } else if (numChannels == 3) {
      if (order != ChannelOrder.rgb && order != ChannelOrder.bgr) {
        // The user asked for a channel order that conflicts with the number
        // of channels.
        order = ChannelOrder.rgb;
      }
    } else if (numChannels == 4) {
      if (order != ChannelOrder.bgra &&
          order != ChannelOrder.rgba &&
          order != ChannelOrder.abgr &&
          order != ChannelOrder.argb) {
        // The user asked for a channel order that conflicts with the number
        // of channels.
        order = ChannelOrder.rgba;
      }
    }

    _initialize(width, height,
        format: format,
        numChannels: numChannels,
        withPalette: withPalette,
        paletteFormat: paletteFormat,
        palette: palette,
        exif: exif,
        iccp: iccp);

    if (data == null) {
      return;
    }

    final toBytes = data!.toUint8List();
    final fromBytes = Uint8List.view(bytes, bytesOffset);

    rowStride ??= getRowStride(width, numChannels, format);
    final dataStride = data!.rowStride;
    final stride = min(rowStride, dataStride);

    var dOff = 0;
    var bOff = 0;
    for (int y = 0; y < height; ++y, bOff += rowStride, dOff += dataStride) {
      final bRow = fromBytes.getRange(bOff, bOff + stride);
      toBytes.setRange(dOff, dOff + dataStride, bRow);
    }

    if (numChannels == 3 && order == ChannelOrder.bgr) {
      for (final p in this) {
        final r = p.r;
        p
          ..r = p.b
          ..b = r;
      }
    } else if (numChannels == 4 && order == ChannelOrder.abgr) {
      for (final p in this) {
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
    } else if (numChannels == 4 && order == ChannelOrder.argb) {
      for (final p in this) {
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
    } else if (numChannels == 4 && order == ChannelOrder.bgra) {
      for (final p in this) {
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
  }

  /// An image is considered animated if it has more than one frame, as the
  /// first image in the frames list is the image itself.
  bool get hasAnimation => frames.length > 1;

  /// The number of frames in this Image. An Image will have at least one
  /// frame, itself, so it's considered animated if it has more than one
  /// frame.
  int get numFrames => frames.length;

  /// Get a frame from this image. If the Image is not animated, this
  /// Image will be returned; otherwise the particular frame Image will
  /// be returned.
  Image getFrame(int index) => frames[index];

  /// Add a frame to the animation of this Image.
  Image addFrame([Image? image]) {
    image ??= Image.from(this, noAnimation: true, noPixels: true);
    image.frameIndex = frames.length;
    if (frames.last != image) {
      frames.add(image);
    }
    return image;
  }

  void _initialize(int width, int height,
      {Format format = Format.uint8,
      int numChannels = 3,
      bool withPalette = false,
      Format paletteFormat = Format.uint8,
      Palette? palette,
      ExifData? exif,
      IccProfile? iccp}) {
    if (numChannels < 1 || numChannels > 4) {
      throw ImageException('Invalid number of channels for image $numChannels.'
          ' Must be between 1 and 4.');
    }
    iccProfile = iccp;
    if (exif != null) {
      _exif = ExifData.from(exif);
    }
    if (palette == null && withPalette && supportsPalette) {
      palette = _createPalette(paletteFormat, numChannels);
    }

    _createImageData(width, height, format, numChannels, palette);
  }

  void _createImageData(
      int width, int height, Format format, int numChannels, Palette? palette) {
    switch (format) {
      case Format.uint1:
        if (palette == null) {
          data = ImageDataUint1(width, height, numChannels);
        } else {
          data = ImageDataUint1.palette(width, height, palette);
        }
        break;
      case Format.uint2:
        if (palette == null) {
          data = ImageDataUint2(width, height, numChannels);
        } else {
          data = ImageDataUint2.palette(width, height, palette);
        }
        break;
      case Format.uint4:
        if (palette == null) {
          data = ImageDataUint4(width, height, numChannels);
        } else {
          data = ImageDataUint4.palette(width, height, palette);
        }
        break;
      case Format.uint8:
        if (palette == null) {
          data = ImageDataUint8(width, height, numChannels);
        } else {
          data = ImageDataUint8.palette(width, height, palette);
        }
        break;
      case Format.uint16:
        data = ImageDataUint16(width, height, numChannels);
        break;
      case Format.uint32:
        data = ImageDataUint32(width, height, numChannels);
        break;
      case Format.int8:
        data = ImageDataInt8(width, height, numChannels);
        break;
      case Format.int16:
        data = ImageDataInt16(width, height, numChannels);
        break;
      case Format.int32:
        data = ImageDataInt32(width, height, numChannels);
        break;
      case Format.float16:
        data = ImageDataFloat16(width, height, numChannels);
        break;
      case Format.float32:
        data = ImageDataFloat32(width, height, numChannels);
        break;
      case Format.float64:
        data = ImageDataFloat64(width, height, numChannels);
        break;
    }
  }

  /// Create a copy of this image.
  Image clone({bool noAnimation = false, bool noPixels = false}) =>
      Image.from(this, noAnimation: noAnimation, noPixels: noPixels);

  /// String representation of the image.
  @override
  String toString() => 'Image($width, $height, ${format.name}, $numChannels)';

  /// The width of the image in pixels.
  int get width => data?.width ?? 0;

  /// The height of the image in pixels.
  int get height => data?.height ?? 0;

  /// The format of the image pixels.
  Format get format => data?.format ?? Format.uint8;

  /// The general type of the format, whether it's Uint data, Int data, or
  /// Float data (regardless of precision).
  FormatType get formatType => data?.formatType ?? FormatType.uint;

  bool get hasExif => _exif != null;

  /// The exif metadata for the image. If an ExifData hasn't been created
  /// for the image yet, one will be added.
  ExifData get exif {
    _exif ??= ExifData();
    return _exif!;
  }

  set exif(ExifData exif) => _exif = exif;

  bool hasExtraChannel(String name) =>
      extraChannels != null && extraChannels!.containsKey(name);

  ImageData? getExtraChannel(String name) =>
      extraChannels != null ? extraChannels![name] : null;

  void setExtraChannel(String name, ImageData? data) {
    if (extraChannels == null && data == null) {
      return;
    }

    extraChannels ??= {};

    if (data == null) {
      extraChannels!.remove(name);
    } else {
      extraChannels![name] = data;
    }

    if (extraChannels!.isEmpty) {
      extraChannels = null;
    }
  }

  /// Returns a pixel iterator for iterating over all of the pixels in the
  /// image.
  @override
  Iterator<Pixel> get iterator => data!.iterator;

  /// Returns a pixel iterator for iterating over a rectangular range of pixels
  /// in the image.
  Iterator<Pixel> getRange(int x, int y, int width, int height) =>
      data!.getRange(x, y, width, height);

  /// Is true if the image is valid and has data.
  bool get isValid => data != null && width > 0 && height > 0;

  /// The [ByteBuffer] of the image storage data.
  ByteBuffer get buffer => data?.buffer ?? Uint8List(0).buffer;

  /// Get a Uint8List view of the image storage data.
  Uint8List toUint8List() => data?.toUint8List() ?? buffer.asUint8List();

  /// Similar to toUint8List, but will convert the channels of the image pixels
  /// to the given [order]. If that happens, the returned bytes will be a copy
  /// and not a direct view of the image data.
  Uint8List getBytes({ChannelOrder? order}) =>
      data?.getBytes(order: order) ?? toUint8List();

  /// The length in bytes of the image data buffer.
  int get lengthInBytes => data?.buffer.lengthInBytes ?? 0;

  /// The length in bytes of a row of pixels in the image buffer.
  int get rowStride => data?.rowStride ?? 0;

  /// The number of color channels for the image.
  int get numChannels => palette?.numChannels ?? data?.numChannels ?? 0;

  /// Is true if the image format is a low dynamic range (regular) image.
  bool get isLdrFormat => data?.isLdrFormat ?? false;

  /// Is true if the image is a high dynamic range image.
  bool get isHdrFormat => data?.isHdrFormat ?? false;

  /// Is true if the image has a palette.
  bool get hasPalette => data?.palette != null;

  /// The palette if the image has one, null otherwise.
  Palette? get palette => data?.palette;

  /// The number of bits per color channel.
  int get bitsPerChannel => data?.bitsPerChannel ?? 0;

  /// True if the Image has an alpha channel.
  bool get hasAlpha => numChannels == 4;

  /// Remap the color channels to the given [order]. Normally Image color
  /// channels are stored in rgba order for 4 channel images, and
  /// rgb order for 3 channel images. This method lets you re-arrange the
  /// color channels in-place without needing to clone the image for preparing
  /// image data for external usage that requires alternative channel ordering.
  void remapChannels(ChannelOrder order) {
    if (numChannels == 4) {
      if (order == ChannelOrder.abgr ||
          order == ChannelOrder.argb ||
          order == ChannelOrder.bgra) {
        if (order == ChannelOrder.abgr) {
          for (final p in this) {
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
          for (final p in this) {
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
          for (final p in this) {
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
      }
    } else if (numChannels == 3) {
      if (order == ChannelOrder.bgr) {
        for (final p in this) {
          final r = p.r;
          p
            ..r = p.b
            ..b = r;
        }
      }
    }
  }

  /// Returns true if the given pixel coordinates is within the dimensions
  /// of the image.
  bool isBoundsSafe(num x, num y) =>
      x >= 0 && y >= 0 && x < width && y < height;

  /// Create a [Color] object with the format and number of channels of the
  /// image.
  Color getColor(num r, num g, num b, [num? a]) =>
      data?.getColor(r, g, b, a) ?? ColorUint8(0);

  /// Return the [Pixel] at the given coordinates. If [pixel] is provided,
  /// it will be updated and returned rather than allocating a new [Pixel].
  Pixel getPixel(int x, int y, [Pixel? pixel]) =>
      data?.getPixel(x, y, pixel) ?? Pixel.undefined;

  /// Get the pixel from the given [x], [y] coordinate. If the pixel coordinates
  /// are out of bounds, PixelUndefined is returned.
  Pixel getPixelSafe(int x, int y, [Pixel? pixel]) {
    if (x < 0 || x >= width || y < 0 || y >= height) {
      return Pixel.undefined;
    }
    return getPixel(x, y, pixel);
  }

  /// Get the pixel from the given [x], [y] coordinate. If the pixel coordinates
  /// are out of range of the image, they will be clamped to the resolution.
  Pixel getPixelClamped(int x, int y, [Pixel? pixel]) {
    x = x.clamp(0, width - 1);
    y = y.clamp(0, height - 1);
    return getPixel(x, y, pixel);
  }

  int getPixelIndex(int x, int y) => data?.getPixel(x, y).index.toInt() ?? 0;

  /// Get the pixel using the given [interpolation] type for non-integer pixel
  /// coordinates.
  Color getPixelInterpolate(num fx, num fy,
      {Interpolation interpolation = Interpolation.linear}) {
    switch (interpolation) {
      case Interpolation.nearest:
        return getPixelSafe(fx.toInt(), fy.toInt());
      case Interpolation.linear:
      case Interpolation.average:
        return getPixelLinear(fx, fy);
      case Interpolation.cubic:
        return getPixelCubic(fx, fy);
    }
  }

  /// Get the pixel using linear interpolation for non-integer pixel
  /// coordinates.
  Color getPixelLinear(num fx, num fy) {
    final x = fx.toInt() - (fx >= 0 ? 0 : 1);
    final nx = x + 1;
    final y = fy.toInt() - (fy >= 0 ? 0 : 1);
    final ny = y + 1;
    final dx = fx - x;
    final dy = fy - y;

    num linear(num icc, num inc, num icn, num inn) =>
        icc +
        dx * (inc - icc + dy * (icc + inn - icn - inc)) +
        dy * (icn - icc);

    final icc = getPixelSafe(x, y);
    final icn = ny >= height ? icc : getPixelSafe(x, ny);
    final inc = nx >= width ? icc : getPixelSafe(nx, y);
    final inn = nx >= width || ny >= height ? icc : getPixelSafe(nx, ny);

    return getColor(
        linear(icc.r, inc.r, icn.r, inn.r),
        linear(icc.g, inc.g, icn.g, inn.g),
        linear(icc.b, inc.b, icn.b, inn.b),
        linear(icc.a, inc.a, icn.a, inn.a));
  }

  /// Get the pixel using cubic interpolation for non-integer pixel
  /// coordinates.
  Color getPixelCubic(num fx, num fy) {
    final x = fx.toInt() - (fx >= 0.0 ? 0 : 1);
    final px = x - 1;
    final nx = x + 1;
    final ax = x + 2;
    final y = fy.toInt() - (fy >= 0.0 ? 0 : 1);
    final py = y - 1;
    final ny = y + 1;
    final ay = y + 2;

    final dx = fx - x;
    final dy = fy - y;

    num cubic(num dx, num ipp, num icp, num inp, num iap) =>
        icp +
        0.5 *
            (dx * (-ipp + inp) +
                dx * dx * (2 * ipp - 5 * icp + 4 * inp - iap) +
                dx * dx * dx * (-ipp + 3 * icp - 3 * inp + iap));

    final icc = getPixelSafe(x, y);

    final ipp = px < 0 || py < 0 ? icc : getPixelSafe(px, py);
    final icp = px < 0 ? icc : getPixelSafe(x, py);
    final inp = py < 0 || nx >= width ? icc : getPixelSafe(nx, py);
    final iap = ax >= width || py < 0 ? icc : getPixelSafe(ax, py);

    final ip0 = cubic(dx, ipp.r, icp.r, inp.r, iap.r);
    final ip1 = cubic(dx, ipp.g, icp.g, inp.g, iap.g);
    final ip2 = cubic(dx, ipp.b, icp.b, inp.b, iap.b);
    final ip3 = cubic(dx, ipp.a, icp.a, inp.a, iap.a);

    final ipc = px < 0 ? icc : getPixelSafe(px, y);
    final inc = nx >= width ? icc : getPixelSafe(nx, y);
    final iac = ax >= width ? icc : getPixelSafe(ax, y);

    final ic0 = cubic(dx, ipc.r, icc.r, inc.r, iac.r);
    final ic1 = cubic(dx, ipc.g, icc.g, inc.g, iac.g);
    final ic2 = cubic(dx, ipc.b, icc.b, inc.b, iac.b);
    final ic3 = cubic(dx, ipc.a, icc.a, inc.a, iac.a);

    final ipn = px < 0 || ny >= height ? icc : getPixelSafe(px, ny);
    final icn = ny >= height ? icc : getPixelSafe(x, ny);
    final inn = nx >= width || ny >= height ? icc : getPixelSafe(nx, ny);
    final ian = ax >= width || ny >= height ? icc : getPixelSafe(ax, ny);

    final in0 = cubic(dx, ipn.r, icn.r, inn.r, ian.r);
    final in1 = cubic(dx, ipn.g, icn.g, inn.g, ian.g);
    final in2 = cubic(dx, ipn.b, icn.b, inn.b, ian.b);
    final in3 = cubic(dx, ipn.a, icn.a, inn.a, ian.a);

    final ipa = px < 0 || ay >= height ? icc : getPixelSafe(px, ay);
    final ica = ay >= height ? icc : getPixelSafe(x, ay);
    final ina = nx >= width || ay >= height ? icc : getPixelSafe(nx, ay);
    final iaa = ax >= width || ay >= height ? icc : getPixelSafe(ax, ay);

    final ia0 = cubic(dx, ipa.r, ica.r, ina.r, iaa.r);
    final ia1 = cubic(dx, ipa.g, ica.g, ina.g, iaa.g);
    final ia2 = cubic(dx, ipa.b, ica.b, ina.b, iaa.b);
    final ia3 = cubic(dx, ipa.a, ica.a, ina.a, iaa.a);

    final c0 = cubic(dy, ip0, ic0, in0, ia0);
    final c1 = cubic(dy, ip1, ic1, in1, ia1);
    final c2 = cubic(dy, ip2, ic2, in2, ia2);
    final c3 = cubic(dy, ip3, ic3, in3, ia3);

    return getColor(c0.toInt(), c1.toInt(), c2.toInt(), c3.toInt());
  }

  /// Set the color of the pixel at the given coordinates to the color of the
  /// given Color [c].
  void setPixel(int x, int y, Color c) {
    if (c is Pixel) {
      if (c.image.hasPalette) {
        if (hasPalette) {
          data?.setPixelRgb(x, y, c.index, 0, 0);
          return;
        }
      }
    }
    data?.setPixelRgba(x, y, c.r, c.g, c.b, c.a);
  }

  /// Set the index value for palette images, or the red channel otherwise.
  void setPixelIndex(int x, int y, num i) => data?.setPixelR(x, y, i);

  /// Set the red (or index) color channel of a pixel.
  void setPixelR(int x, int y, num i) => data?.setPixelR(x, y, i);

  /// Set the color of the [Pixel] at the given coordinates to the given
  /// color values [r], [g], [b].
  void setPixelRgb(int x, int y, num r, num g, num b) =>
      data?.setPixelRgb(x, y, r, g, b);

  /// Set the color of the [Pixel] at the given coordinates to the given
  /// color values [r], [g], [b], and [a].
  void setPixelRgba(int x, int y, num r, num g, num b, num a) =>
      data?.setPixelRgba(x, y, r, g, b, a);

  /// The maximum value of a pixel channel, based on the [format] of the image.
  /// If the image has a [palette], this will be the maximum value of a palette
  /// color channel. Float format images will have a maxChannelValue of 1.0,
  /// though they can have values above that.
  num get maxChannelValue => data?.maxChannelValue ?? 0;

  /// The maximum value of a palette index, based on the [format] of the image.
  /// This differs from [maxChannelValue] in that it will not be affected by
  /// the format of the [palette].
  num get maxIndexValue => data?.maxIndexValue ?? 0;

  /// Is true if this image format supports using a palette.
  bool get supportsPalette =>
      format == Format.uint1 ||
      format == Format.uint2 ||
      format == Format.uint4 ||
      format == Format.uint8;

  /// Set all pixels in the image to the given [color]. If no color is provided
  /// the image will be initialized to 0.
  void clear([Color? color]) => data?.clear(color);

  /// Convert this image to a new [format] or number of channels, [numChannels].
  /// If the new number of channels is 4 and the current image does
  /// not have an alpha channel, then the given [alpha] value will be used
  /// to set the new alpha channel. If [alpha] is not provided, then the
  /// [maxChannelValue] will be used to set the alpha. If [withPalette] is
  /// true, and to target format and numChannels has fewer than 256 colors,
  /// then the new image will be converted to use a palette.
  Image convert(
      {Format? format,
      int? numChannels,
      num? alpha,
      bool withPalette = false,
      bool noAnimation = false}) {
    format ??= this.format;
    numChannels ??= this.numChannels;
    alpha ??= formatMaxValue[format];

    if (withPalette &&
            (numChannels >= 4 ||
                !(format == Format.uint1 ||
                    format == Format.uint2 ||
                    format == Format.uint4 ||
                    (format == Format.uint8 && numChannels == 1))) ||
        (format.index < Format.uint8.index &&
            this.format.index >= Format.uint8.index)) {
      withPalette = false;
    }

    if (format == this.format &&
        numChannels == this.numChannels &&
        ((!withPalette && palette == null) ||
            (withPalette && palette != null))) {
      // Same format and number of channels
      return Image.from(this);
    }

    Image? firstFrame;
    for (final frame in frames) {
      final newImage = Image(
          width: frame.width,
          height: frame.height,
          format: format,
          numChannels: numChannels,
          withPalette: withPalette,
          exif: frame._exif?.clone(),
          iccp: frame.iccProfile?.clone(),
          backgroundColor: frame.backgroundColor?.clone(),
          frameType: frame.frameType,
          loopCount: frame.loopCount,
          frameDuration: frame.frameDuration)
        ..textData = frame.textData != null
            ? Map<String, String>.from(frame.textData!)
            : null;

      if (firstFrame != null) {
        firstFrame.addFrame(newImage);
      } else {
        firstFrame = newImage;
      }

      final pal = newImage.palette;
      final f = newImage.palette?.format ?? format;
      if (pal != null) {
        final usedColors = <int, int>{};
        var numColors = 0;
        final op = frame.getPixel(0, 0);
        Color? c;
        for (final np in newImage) {
          final nr = (op.rNormalized * 255).floor();
          final ng = (op.gNormalized * 255).floor();
          final nb = (op.bNormalized * 255).floor();
          final h = rgbaToUint32(nr, ng, nb, 0);
          if (usedColors.containsKey(h)) {
            np.index = usedColors[h]!;
          } else {
            usedColors[h] = numColors;
            np.index = numColors;
            c = convertColor(op,
                to: c, format: f, numChannels: numChannels, alpha: alpha);
            pal.setRgb(numColors, c.r, c.g, c.b);
            numColors++;
          }
          op.moveNext();
        }
      } else {
        final op = frame.getPixel(0, 0);
        for (final np in newImage) {
          convertColor(op, to: np, alpha: alpha);
          op.moveNext();
        }
      }

      if (noAnimation) {
        break;
      }
    }

    return firstFrame!;
  }

  /// Add text metadata to the image.
  void addTextData(Map<String, String> data) {
    textData ??= {};
    for (final key in data.keys) {
      textData![key] = data[key]!;
    }
  }

  int get _numPixelColors => format == Format.uint1
      ? 2
      : format == Format.uint2
          ? 4
          : format == Format.uint4
              ? 16
              : format == Format.uint8
                  ? 256
                  : 0;

  Palette? _createPalette(Format paletteFormat, int numChannels) {
    switch (paletteFormat) {
      case Format.uint1:
        return null;
      case Format.uint2:
        return null;
      case Format.uint4:
        return null;
      case Format.uint8:
        return PaletteUint8(_numPixelColors, numChannels);
      case Format.uint16:
        return PaletteUint16(_numPixelColors, numChannels);
      case Format.uint32:
        return PaletteUint32(_numPixelColors, numChannels);
      case Format.int8:
        return PaletteInt8(_numPixelColors, numChannels);
      case Format.int16:
        return PaletteInt16(_numPixelColors, numChannels);
      case Format.int32:
        return PaletteInt32(_numPixelColors, numChannels);
      case Format.float16:
        return PaletteFloat16(_numPixelColors, numChannels);
      case Format.float32:
        return PaletteFloat32(_numPixelColors, numChannels);
      case Format.float64:
        return PaletteFloat64(_numPixelColors, numChannels);
    }
  }
}
