// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of ui;

// ignore: unused_element, Used in Shader assert.
bool _offsetIsValid(Offset offset) {
  assert(offset != null, 'Offset argument was null.'); // ignore: unnecessary_null_comparison
  assert(!offset.dx.isNaN && !offset.dy.isNaN, 'Offset argument contained a NaN value.');
  return true;
}

// ignore: unused_element, Used in Shader assert.
bool _matrix4IsValid(Float32List matrix4) {
  assert(matrix4 != null, 'Matrix4 argument was null.'); // ignore: unnecessary_null_comparison
  assert(matrix4.length == 16, 'Matrix4 must have 16 entries.');
  return true;
}

void _validateColorStops(List<Color> colors, List<double>? colorStops) {
  if (colorStops == null) {
    if (colors.length != 2)
      throw ArgumentError('"colors" must have length 2 if "colorStops" is omitted.');
  } else {
    if (colors.length != colorStops.length)
      throw ArgumentError('"colors" and "colorStops" arguments must have equal length.');
  }
}

Color _scaleAlpha(Color a, double factor) {
  return a.withAlpha(engine.clampInt((a.alpha * factor).round(), 0, 255));
}

class Color {
  const Color(int value) : this.value = value & 0xFFFFFFFF;
  const Color.fromARGB(int a, int r, int g, int b)
      : value = (((a & 0xff) << 24) |
                ((r & 0xff) << 16) |
                ((g & 0xff) << 8) |
                ((b & 0xff) << 0)) &
            0xFFFFFFFF;
  const Color.fromRGBO(int r, int g, int b, double opacity)
      : value = ((((opacity * 0xff ~/ 1) & 0xff) << 24) |
                ((r & 0xff) << 16) |
                ((g & 0xff) << 8) |
                ((b & 0xff) << 0)) &
            0xFFFFFFFF;
  final int value;
  int get alpha => (0xff000000 & value) >> 24;
  double get opacity => alpha / 0xFF;
  int get red => (0x00ff0000 & value) >> 16;
  int get green => (0x0000ff00 & value) >> 8;
  int get blue => (0x000000ff & value) >> 0;
  Color withAlpha(int a) {
    return Color.fromARGB(a, red, green, blue);
  }

  Color withOpacity(double opacity) {
    assert(opacity >= 0.0 && opacity <= 1.0);
    return withAlpha((255.0 * opacity).round());
  }

  Color withRed(int r) {
    return Color.fromARGB(alpha, r, green, blue);
  }

  Color withGreen(int g) {
    return Color.fromARGB(alpha, red, g, blue);
  }

  Color withBlue(int b) {
    return Color.fromARGB(alpha, red, green, b);
  }

  // See <https://www.w3.org/TR/WCAG20/#relativeluminancedef>
  static double _linearizeColorComponent(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    }
    return math.pow((component + 0.055) / 1.055, 2.4) as double;
  }

  double computeLuminance() {
    // See <https://www.w3.org/TR/WCAG20/#relativeluminancedef>
    final double R = _linearizeColorComponent(red / 0xFF);
    final double G = _linearizeColorComponent(green / 0xFF);
    final double B = _linearizeColorComponent(blue / 0xFF);
    return 0.2126 * R + 0.7152 * G + 0.0722 * B;
  }

  static Color? lerp(Color? a, Color? b, double t) {
    assert(t != null); // ignore: unnecessary_null_comparison
    if (b == null) {
      if (a == null) {
        return null;
      } else {
        return _scaleAlpha(a, 1.0 - t);
      }
    } else {
      if (a == null) {
        return _scaleAlpha(b, t);
      } else {
        return Color.fromARGB(
          engine.clampInt(_lerpInt(a.alpha, b.alpha, t).toInt(), 0, 255),
          engine.clampInt(_lerpInt(a.red, b.red, t).toInt(), 0, 255),
          engine.clampInt(_lerpInt(a.green, b.green, t).toInt(), 0, 255),
          engine.clampInt(_lerpInt(a.blue, b.blue, t).toInt(), 0, 255),
        );
      }
    }
  }

  static Color alphaBlend(Color foreground, Color background) {
    final int alpha = foreground.alpha;
    if (alpha == 0x00) {
      // Foreground completely transparent.
      return background;
    }
    final int invAlpha = 0xff - alpha;
    int backAlpha = background.alpha;
    if (backAlpha == 0xff) {
      // Opaque background case
      return Color.fromARGB(
        0xff,
        (alpha * foreground.red + invAlpha * background.red) ~/ 0xff,
        (alpha * foreground.green + invAlpha * background.green) ~/ 0xff,
        (alpha * foreground.blue + invAlpha * background.blue) ~/ 0xff,
      );
    } else {
      // General case
      backAlpha = (backAlpha * invAlpha) ~/ 0xff;
      final int outAlpha = alpha + backAlpha;
      assert(outAlpha != 0x00);
      return Color.fromARGB(
        outAlpha,
        (foreground.red * alpha + background.red * backAlpha) ~/ outAlpha,
        (foreground.green * alpha + background.green * backAlpha) ~/ outAlpha,
        (foreground.blue * alpha + background.blue * backAlpha) ~/ outAlpha,
      );
    }
  }

  static int getAlphaFromOpacity(double opacity) {
    assert(opacity != null); // ignore: unnecessary_null_comparison
    return (opacity.clamp(0.0, 1.0) * 255).round();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is Color && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() {
    return 'Color(0x${value.toRadixString(16).padLeft(8, '0')})';
  }
}

enum StrokeCap {
  butt,
  round,
  square,
}

// These enum values must be kept in sync with SkPaint::Join.
enum StrokeJoin {
  miter,
  round,
  bevel,
}

enum PaintingStyle {
  fill,
  stroke,
}

enum BlendMode {
  // This list comes from Skia's SkXfermode.h and the values (order) should be
  // kept in sync.
  // See: https://skia.org/user/api/skpaint#SkXfermode
  clear,
  src,
  dst,
  srcOver,
  dstOver,
  srcIn,
  dstIn,
  srcOut,
  dstOut,
  srcATop,
  dstATop,
  xor,
  plus,
  modulate,

  // Following blend modes are defined in the CSS Compositing standard.
  screen, // The last coeff mode.
  overlay,
  darken,
  lighten,
  colorDodge,
  colorBurn,
  hardLight,
  softLight,
  difference,
  exclusion,
  multiply, // The last separable mode.
  hue,
  saturation,
  color,
  luminosity,
}

enum Clip {
  none,
  hardEdge,
  antiAlias,
  antiAliasWithSaveLayer,
}

abstract class Paint {
  factory Paint() => engine.useCanvasKit ? engine.CkPaint() : engine.SurfacePaint();
  static bool enableDithering = false;
  BlendMode get blendMode;
  set blendMode(BlendMode value);
  PaintingStyle get style;
  set style(PaintingStyle value);
  double get strokeWidth;
  set strokeWidth(double value);
  StrokeCap get strokeCap;
  set strokeCap(StrokeCap value);
  StrokeJoin get strokeJoin;
  set strokeJoin(StrokeJoin value);
  bool get isAntiAlias;
  set isAntiAlias(bool value);

  Color get color;
  set color(Color value);
  bool get invertColors;

  set invertColors(bool value);
  Shader? get shader;
  set shader(Shader? value);
  MaskFilter? get maskFilter;
  set maskFilter(MaskFilter? value);
  // TODO(ianh): verify that the image drawing methods actually respect this
  FilterQuality get filterQuality;
  set filterQuality(FilterQuality value);
  ColorFilter? get colorFilter;
  set colorFilter(ColorFilter? value);

  double get strokeMiterLimit;
  set strokeMiterLimit(double value);
  ImageFilter? get imageFilter;
  set imageFilter(ImageFilter? value);
}

abstract class Shader {
  Shader._();
}

abstract class Gradient extends Shader {
  factory Gradient.linear(
    Offset from,
    Offset to,
    List<Color> colors, [
    List<double>? colorStops,
    TileMode tileMode = TileMode.clamp,
    Float64List? matrix4,
  ]) => engine.useCanvasKit
    ? engine.CkGradientLinear(from, to, colors, colorStops, tileMode, matrix4)
    : engine.GradientLinear(from, to, colors, colorStops, tileMode, matrix4);
  factory Gradient.radial(
    Offset center,
    double radius,
    List<Color> colors, [
    List<double>? colorStops,
    TileMode tileMode = TileMode.clamp,
    Float64List? matrix4,
    Offset? focal,
    double focalRadius = 0.0,
  ]) {
    _validateColorStops(colors, colorStops);
    // If focal is null or focal radius is null, this should be treated as a regular radial gradient
    // If focal == center and the focal radius is 0.0, it's still a regular radial gradient
    final Float32List? matrix32 = matrix4 != null ? engine.toMatrix32(matrix4) : null;
    if (focal == null || (focal == center && focalRadius == 0.0)) {
      return engine.useCanvasKit
          ? engine.CkGradientRadial(center, radius, colors, colorStops, tileMode, matrix32)
          : engine.GradientRadial(center, radius, colors, colorStops, tileMode, matrix32);
    } else {
      assert(center != Offset.zero ||
          focal != Offset.zero); // will result in exception(s) in Skia side
      return engine.useCanvasKit
          ? engine.CkGradientConical(
              focal, focalRadius, center, radius, colors, colorStops, tileMode, matrix32)
          : engine.GradientConical(
              focal, focalRadius, center, radius, colors, colorStops, tileMode, matrix32);
    }
  }
  factory Gradient.sweep(
    Offset center,
    List<Color> colors, [
    List<double>? colorStops,
    TileMode tileMode = TileMode.clamp,
    double startAngle = 0.0,
    double endAngle = math.pi * 2,
    Float64List? matrix4,
  ]) => engine.useCanvasKit
    ? engine.CkGradientSweep(center, colors, colorStops, tileMode, startAngle,
          endAngle, matrix4 != null ? engine.toMatrix32(matrix4) : null)
    : engine.GradientSweep(center, colors, colorStops, tileMode, startAngle,
          endAngle, matrix4 != null ? engine.toMatrix32(matrix4) : null);
}

abstract class Image {
  int get width;
  int get height;
  Future<ByteData?> toByteData({ImageByteFormat format = ImageByteFormat.rawRgba});
  void dispose();
  bool get debugDisposed;

  Image clone() => this;

  bool isCloneOf(Image other) => other == this;

  List<StackTrace>? debugGetOpenHandleStackTraces() => null;

  @override
  String toString() => '[$width\u00D7$height]';
}

abstract class ColorFilter {
  const factory ColorFilter.mode(Color color, BlendMode blendMode) = engine.EngineColorFilter.mode;
  const factory ColorFilter.matrix(List<double> matrix) = engine.EngineColorFilter.matrix;
  const factory ColorFilter.linearToSrgbGamma() = engine.EngineColorFilter.linearToSrgbGamma;
  const factory ColorFilter.srgbToLinearGamma() = engine.EngineColorFilter.srgbToLinearGamma;
}

// These enum values must be kept in sync with SkBlurStyle.
enum BlurStyle {
  // These mirror SkBlurStyle and must be kept in sync.
  normal,
  solid,
  outer,
  inner,
}

class MaskFilter {
  const MaskFilter.blur(
    this._style,
    this._sigma,
  )   : assert(_style != null), // ignore: unnecessary_null_comparison
        assert(_sigma != null); // ignore: unnecessary_null_comparison

  final BlurStyle _style;
  final double _sigma;
  double get webOnlySigma => _sigma;
  BlurStyle get webOnlyBlurStyle => _style;

  @override
  bool operator ==(Object other) {
    return other is MaskFilter
        && other._style == _style
        && other._sigma == _sigma;
  }

  @override
  int get hashCode => hashValues(_style, _sigma);

  @override
  String toString() => 'MaskFilter.blur($_style, ${_sigma.toStringAsFixed(1)})';
}

enum FilterQuality {
  // This list comes from Skia's SkFilterQuality.h and the values (order) should
  // be kept in sync.
  none,
  low,
  medium,
  high,
}

class ImageFilter {
  factory ImageFilter.blur({double sigmaX = 0.0, double sigmaY = 0.0}) {
    if (engine.useCanvasKit) {
      return engine.CkImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY);
    }
    return engine.EngineImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY);
  }

  ImageFilter.matrix(Float64List matrix4, {FilterQuality filterQuality = FilterQuality.low}) {
    // TODO(flutter_web): add implementation.
    throw UnimplementedError('ImageFilter.matrix not implemented for web platform.');
    //    if (matrix4.length != 16)
    //      throw ArgumentError('"matrix4" must have 16 entries.');
  }

  ImageFilter.compose({required ImageFilter outer, required ImageFilter inner}) {
     // TODO(flutter_web): add implementation.
    throw UnimplementedError(
        'ImageFilter.compose not implemented for web platform.');
  }
}

enum ImageByteFormat {
  rawRgba,
  rawUnmodified,
  png,
}

enum PixelFormat {
  rgba8888,
  bgra8888,
}

typedef ImageDecoderCallback = void Function(Image result);

abstract class FrameInfo {
  FrameInfo._();
  Duration get duration => Duration(milliseconds: _durationMillis);
  int get _durationMillis => 0;
  Image get image;
}

class Codec {
  Codec._();
  int get frameCount => 0;
  int get repetitionCount => 0;
  Future<FrameInfo> getNextFrame() {
    return engine.futurize<FrameInfo>(_getNextFrame);
  }

  String? _getNextFrame(engine.Callback<FrameInfo> callback) => null;
  void dispose() {}
}

Future<Codec> instantiateImageCodec(
  Uint8List list, {
  int? targetWidth,
  int? targetHeight,
  bool allowUpscaling = true,
}) {
  return _futurize<Codec>((engine.Callback<Codec> callback) =>
      // TODO: Implement targetWidth and targetHeight support.
      _instantiateImageCodec(list, callback));
}

String? _instantiateImageCodec(Uint8List list, engine.Callback<Codec> callback) {
  if (engine.useCanvasKit) {
    engine.skiaInstantiateImageCodec(list, callback);
    return null;
  }
  final html.Blob blob = html.Blob(<dynamic>[list.buffer]);
  callback(engine.HtmlBlobCodec(blob));
  return null;
}

Future<Codec> webOnlyInstantiateImageCodecFromUrl(Uri uri,
  {engine.WebOnlyImageCodecChunkCallback? chunkCallback}) {
  if (engine.useCanvasKit) {
    return engine.skiaInstantiateWebImageCodec(
      uri.toString(), chunkCallback);
  } else {
    return _futurize<Codec>((engine.Callback<Codec> callback) =>
      _instantiateImageCodecFromUrl(uri, chunkCallback, callback));
  }
}

String? _instantiateImageCodecFromUrl(
  Uri uri,
  engine.WebOnlyImageCodecChunkCallback? chunkCallback,
  engine.Callback<Codec> callback,
) {
  callback(engine.HtmlCodec(uri.toString(), chunkCallback: chunkCallback));
  return null;
}

void decodeImageFromList(Uint8List list, ImageDecoderCallback callback) {
  _decodeImageFromListAsync(list, callback);
}

Future<void> _decodeImageFromListAsync(Uint8List list, ImageDecoderCallback callback) async {
  final Codec codec = await instantiateImageCodec(list);
  final FrameInfo frameInfo = await codec.getNextFrame();
  callback(frameInfo.image);
}
Future<Codec> _createBmp(
  Uint8List pixels,
  int width,
  int height,
  int rowBytes,
  PixelFormat format,
) {
  // See https://en.wikipedia.org/wiki/BMP_file_format for format examples.
  final int bufferSize = 0x36 + (width * height * 4);
  final ByteData bmpData = ByteData(bufferSize);
  // 'BM' header
  bmpData.setUint8(0x00, 0x42);
  bmpData.setUint8(0x01, 0x4D);
  // Size of data
  bmpData.setUint32(0x02, bufferSize, Endian.little);
  // Offset where pixel array begins
  bmpData.setUint32(0x0A, 0x36, Endian.little);
  // Bytes in DIB header
  bmpData.setUint32(0x0E, 0x28, Endian.little);
  // width
  bmpData.setUint32(0x12, width, Endian.little);
  // height
  bmpData.setUint32(0x16, height, Endian.little);
  // Color panes
  bmpData.setUint16(0x1A, 0x01, Endian.little);
  // 32 bpp
  bmpData.setUint16(0x1C, 0x20, Endian.little);
  // no compression
  bmpData.setUint32(0x1E, 0x00, Endian.little);
  // raw bitmap data size
  bmpData.setUint32(0x22, width * height, Endian.little);
  // print DPI width
  bmpData.setUint32(0x26, width, Endian.little);
  // print DPI height
  bmpData.setUint32(0x2A, height, Endian.little);
  // colors in the palette
  bmpData.setUint32(0x2E, 0x00, Endian.little);
  // important colors
  bmpData.setUint32(0x32, 0x00, Endian.little);


  int pixelDestinationIndex = 0;
  late bool swapRedBlue;
  switch (format) {
    case PixelFormat.bgra8888:
      swapRedBlue = true;
      break;
    case PixelFormat.rgba8888:
      swapRedBlue = false;
      break;
  }
  for (int pixelSourceIndex = 0; pixelSourceIndex < pixels.length; pixelSourceIndex += 4) {
    final int r = swapRedBlue ? pixels[pixelSourceIndex + 2] : pixels[pixelSourceIndex];
    final int b = swapRedBlue ? pixels[pixelSourceIndex]     : pixels[pixelSourceIndex + 2];
    final int g = pixels[pixelSourceIndex + 1];
    final int a = pixels[pixelSourceIndex + 3];

    // Set the pixel past the header data.
    bmpData.setUint8(pixelDestinationIndex + 0x36, r);
    bmpData.setUint8(pixelDestinationIndex + 0x37, g);
    bmpData.setUint8(pixelDestinationIndex + 0x38, b);
    bmpData.setUint8(pixelDestinationIndex + 0x39, a);
    pixelDestinationIndex += 4;
    if (rowBytes != width && pixelSourceIndex % width == 0) {
      pixelSourceIndex += rowBytes - width;
    }
  }

  final Completer<Codec> codecCompleter = Completer<Codec>();
  _instantiateImageCodec(
    bmpData.buffer.asUint8List(),
    (Codec codec) => codecCompleter.complete(codec),
  );
  return codecCompleter.future;
}

void decodeImageFromPixels(
  Uint8List pixels,
  int width,
  int height,
  PixelFormat format,
  ImageDecoderCallback callback, {
  int? rowBytes,
  int? targetWidth,
  int? targetHeight,
  bool allowUpscaling = true,
}) {
  if (engine.useCanvasKit) {
    engine.skiaInstantiateImageCodec(
      pixels,
      (Codec codec) {
        codec.getNextFrame().then((FrameInfo info) {
          callback(info.image);
        });
      },
      width,
      height,
      format.index,
      rowBytes,
    );
    return;
  }

  void Function(Codec) callbacker = (Codec codec) {
    codec.getNextFrame().then((FrameInfo frameInfo) {
      callback(frameInfo.image);
    });
  };
  _createBmp(pixels, width, height, rowBytes ?? width, format).then(callbacker);

}

class Shadow {
  const Shadow({
    this.color = const Color(_kColorDefault),
    this.offset = Offset.zero,
    this.blurRadius = 0.0,
  })  : assert(color != null, 'Text shadow color was null.'), // ignore: unnecessary_null_comparison
        assert(offset != null, 'Text shadow offset was null.'), // ignore: unnecessary_null_comparison
        assert(blurRadius >= 0.0, 'Text shadow blur radius should be non-negative.');

  static const int _kColorDefault = 0xFF000000;
  final Color color;
  final Offset offset;
  final double blurRadius;
  // See SkBlurMask::ConvertRadiusToSigma().
  // <https://github.com/google/skia/blob/bb5b77db51d2e149ee66db284903572a5aac09be/src/effects/SkBlurMask.cpp#L23>
  static double convertRadiusToSigma(double radius) {
    return radius * 0.57735 + 0.5;
  }

  double get blurSigma => convertRadiusToSigma(blurRadius);
  Paint toPaint() {
    return Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
  }

  Shadow scale(double factor) {
    return Shadow(
      color: color,
      offset: offset * factor,
      blurRadius: blurRadius * factor,
    );
  }

  static Shadow? lerp(Shadow? a, Shadow? b, double t) {
    assert(t != null); // ignore: unnecessary_null_comparison
    if (b == null) {
      if (a == null) {
        return null;
      } else {
        return a.scale(1.0 - t);
      }
    } else {
      if (a == null) {
        return b.scale(t);
      } else {
        return Shadow(
          color: Color.lerp(a.color, b.color, t)!,
          offset: Offset.lerp(a.offset, b.offset, t)!,
          blurRadius: _lerpDouble(a.blurRadius, b.blurRadius, t),
        );
      }
    }
  }

  static List<Shadow>? lerpList(List<Shadow>? a, List<Shadow>? b, double t) {
    assert(t != null); // ignore: unnecessary_null_comparison
    if (a == null && b == null) {
      return null;
    }
    a ??= <Shadow>[];
    b ??= <Shadow>[];
    final List<Shadow> result = <Shadow>[];
    final int commonLength = math.min(a.length, b.length);
    for (int i = 0; i < commonLength; i += 1)
      result.add(Shadow.lerp(a[i], b[i], t)!);
    for (int i = commonLength; i < a.length; i += 1)
      result.add(a[i].scale(1.0 - t));
    for (int i = commonLength; i < b.length; i += 1) {
      result.add(b[i].scale(t));
    }
    return result;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Shadow &&
        other.color == color &&
        other.offset == offset &&
        other.blurRadius == blurRadius;
  }

  @override
  int get hashCode => hashValues(color, offset, blurRadius);

  @override
  String toString() => 'TextShadow($color, $offset, $blurRadius)';
}

class ImageShader extends Shader {
  factory ImageShader(Image image, TileMode tmx, TileMode tmy, Float64List matrix4) {
    if (engine.useCanvasKit) {
      return engine.CkImageShader(image, tmx, tmy, matrix4);
    }
    throw UnsupportedError('ImageShader not implemented for web platform.');
  }
}

class ImmutableBuffer {
  ImmutableBuffer._(this.length);
  static Future<ImmutableBuffer> fromUint8List(Uint8List list) async {
    final ImmutableBuffer instance = ImmutableBuffer._(list.length);
    instance._list = list;
    return instance;
  }

  Uint8List? _list;
  final int length;
  void dispose() => _list = null;
}

class ImageDescriptor {
  ImageDescriptor._()
      : _width = null,
        _height = null,
        _rowBytes = null,
        _format = null;
  static Future<ImageDescriptor> encoded(ImmutableBuffer buffer) async {
    final ImageDescriptor descriptor = ImageDescriptor._();
    descriptor._data = buffer._list;
    return descriptor;
  }

  // Not async because there's no expensive work to do here.
  ImageDescriptor.raw(
    ImmutableBuffer buffer, {
    required int width,
    required int height,
    int? rowBytes,
    required PixelFormat pixelFormat,
  })   : _width = width,
        _height = height,
        _rowBytes = rowBytes,
        _format = pixelFormat {
    _data = buffer._list;
  }

  Uint8List? _data;
  final int? _width;
  final int? _height;
  final int? _rowBytes;
  final PixelFormat? _format;

  Never _throw(String parameter) {
    throw UnsupportedError('ImageDescriptor.$parameter is not supported on web.');
  }

  int get width => _width ?? _throw('width');
  int get height => _height ?? _throw('height');
  int get bytesPerPixel =>
      throw UnsupportedError('ImageDescriptor.bytesPerPixel is not supported on web.');
  void dispose() => _data = null;
  Future<Codec> instantiateCodec({int? targetWidth, int? targetHeight}) async {
    if (_data == null) {
      throw StateError('Object is disposed');
    }
    if (_width == null) {
      return await instantiateImageCodec(
        _data!,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        allowUpscaling: false,
      );
    }

    return await _createBmp(_data!, width, height, _rowBytes ?? width, _format!);
  }
}
