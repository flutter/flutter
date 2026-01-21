// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

bool get isExperimentalWebParagraph =>
    configuration.canvasKitVariant == CanvasKitVariant.experimentalWebParagraph;

class CanvasKitRenderer extends Renderer {
  static CanvasKitRenderer get instance => _instance;
  static late CanvasKitRenderer _instance;

  Future<void>? _initialized;

  @override
  String get rendererTag => 'canvaskit';

  /// Whether the renderer is using software rendering.
  bool get isSoftware => _pictureToImageSurface.isSoftware;

  late final FlutterFontCollection _fontCollection = isExperimentalWebParagraph
      ? WebFontCollection()
      : SkiaFontCollection();

  @override
  FlutterFontCollection get fontCollection => _fontCollection;

  static Rasterizer _createRasterizer() {
    if (configuration.canvasKitForceMultiSurfaceRasterizer || isSafari || isFirefox) {
      return MultiSurfaceRasterizer(
        (OnscreenCanvasProvider canvasProvider) => CkOnscreenSurface(canvasProvider),
      );
    }
    return OffscreenCanvasRasterizer(
      (OffscreenCanvasProvider canvasProvider) => CkOffscreenSurface(canvasProvider),
    );
  }

  @override
  void debugResetRasterizer() {
    rasterizer = _createRasterizer();
    _pictureToImageSurface = rasterizer.createPictureToImageSurface() as CkSurface;
  }

  @override
  Future<void> initialize() async {
    _initialized ??= () async {
      if (windowFlutterCanvasKit != null) {
        canvasKit = windowFlutterCanvasKit!;
      } else if (windowFlutterCanvasKitLoaded != null) {
        // CanvasKit is being preloaded by flutter.js. Wait for it to complete.
        canvasKit = await windowFlutterCanvasKitLoaded!.toDart;
      } else {
        canvasKit = await downloadCanvasKit();
        windowFlutterCanvasKit = canvasKit;
      }
      rasterizer = _createRasterizer();
      _pictureToImageSurface = rasterizer.createPictureToImageSurface() as CkSurface;
      _instance = this;
      await super.initialize();
    }();
    return _initialized;
  }

  @override
  ui.Paint createPaint() => CkPaint();

  @override
  ui.Vertices createVertices(
    ui.VertexMode mode,
    List<ui.Offset> positions, {
    List<ui.Offset>? textureCoordinates,
    List<ui.Color>? colors,
    List<int>? indices,
  }) => CkVertices(
    mode,
    positions,
    textureCoordinates: textureCoordinates,
    colors: colors,
    indices: indices,
  );

  @override
  ui.Vertices createVerticesRaw(
    ui.VertexMode mode,
    Float32List positions, {
    Float32List? textureCoordinates,
    Int32List? colors,
    Uint16List? indices,
  }) => CkVertices.raw(
    mode,
    positions,
    textureCoordinates: textureCoordinates,
    colors: colors,
    indices: indices,
  );

  @override
  ui.Canvas createCanvas(ui.PictureRecorder recorder, [ui.Rect? cullRect]) =>
      CkCanvas(recorder, cullRect);

  @override
  ui.Gradient createLinearGradient(
    ui.Offset from,
    ui.Offset to,
    List<ui.Color> colors, [
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    Float32List? matrix4,
  ]) => CkGradientLinear(from, to, colors, colorStops, tileMode, matrix4);

  @override
  ui.Gradient createRadialGradient(
    ui.Offset center,
    double radius,
    List<ui.Color> colors, [
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    Float32List? matrix4,
  ]) => CkGradientRadial(center, radius, colors, colorStops, tileMode, matrix4);

  @override
  ui.Gradient createConicalGradient(
    ui.Offset focal,
    double focalRadius,
    ui.Offset center,
    double radius,
    List<ui.Color> colors, [
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    Float32List? matrix,
  ]) => CkGradientConical(focal, focalRadius, center, radius, colors, colorStops, tileMode, matrix);

  @override
  ui.Gradient createSweepGradient(
    ui.Offset center,
    List<ui.Color> colors, [
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    double startAngle = 0.0,
    double endAngle = math.pi * 2,
    Float32List? matrix4,
  ]) => CkGradientSweep(center, colors, colorStops, tileMode, startAngle, endAngle, matrix4);

  @override
  ui.PictureRecorder createPictureRecorder() => CkPictureRecorder();

  @override
  ui.SceneBuilder createSceneBuilder() => LayerSceneBuilder();

  @override
  ui.ImageFilter createBlurImageFilter({
    double sigmaX = 0.0,
    double sigmaY = 0.0,
    ui.TileMode? tileMode,
    ui.Rect? bounds,
  }) =>
      // TODO(dkwingsmt): `bounds` is currently not implemented in CanvasKit.
      // Fall back to unbounded blur.
      // https://github.com/flutter/flutter/issues/175899
      CkImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY, tileMode: tileMode);

  @override
  ui.ImageFilter createDilateImageFilter({double radiusX = 0.0, double radiusY = 0.0}) =>
      CkImageFilter.dilate(radiusX: radiusX, radiusY: radiusY);

  @override
  ui.ImageFilter createErodeImageFilter({double radiusX = 0.0, double radiusY = 0.0}) =>
      CkImageFilter.erode(radiusX: radiusX, radiusY: radiusY);

  @override
  ui.ImageFilter createMatrixImageFilter(
    Float64List matrix4, {
    ui.FilterQuality filterQuality = ui.FilterQuality.low,
  }) => CkImageFilter.matrix(matrix: matrix4, filterQuality: filterQuality);

  @override
  ui.ImageFilter composeImageFilters({
    required ui.ImageFilter outer,
    required ui.ImageFilter inner,
  }) {
    if (outer is EngineColorFilter) {
      final CkColorFilter colorFilter = createCkColorFilter(outer)!;
      outer = CkColorFilterImageFilter(colorFilter: colorFilter);
    }
    if (inner is EngineColorFilter) {
      final CkColorFilter colorFilter = createCkColorFilter(inner)!;
      inner = CkColorFilterImageFilter(colorFilter: colorFilter);
    }
    return CkImageFilter.compose(outer: outer as CkImageFilter, inner: inner as CkImageFilter);
  }

  @override
  Future<ui.Codec> instantiateImageCodec(
    Uint8List list, {
    int? targetWidth,
    int? targetHeight,
    bool allowUpscaling = true,
  }) async => skiaInstantiateImageCodec(list, targetWidth, targetHeight, allowUpscaling);

  @override
  Future<ui.Codec> instantiateImageCodecFromUrl(
    Uri uri, {
    ui_web.ImageCodecChunkCallback? chunkCallback,
  }) => skiaInstantiateWebImageCodec(uri.toString(), chunkCallback);

  @override
  ui.Image createImageFromImageBitmap(DomImageBitmap imageBitmap) {
    SkImage? skImage;
    if (isSoftware) {
      skImage = canvasKit.MakeImageFromCanvasImageSource(imageBitmap);
    } else {
      skImage = canvasKit.MakeLazyImageFromImageBitmap(imageBitmap, true);
    }
    if (skImage == null) {
      throw Exception('Failed to convert image bitmap to an SkImage.');
    }
    return CkImage(skImage, imageSource: ImageBitmapImageSource(imageBitmap));
  }

  @override
  FutureOr<ui.Image> createImageFromTextureSource(
    JSAny object, {
    required int width,
    required int height,
    required bool transferOwnership,
  }) async {
    if (!transferOwnership) {
      final DomImageBitmap bitmap = await createImageBitmap(object, (
        x: 0,
        y: 0,
        width: width,
        height: height,
      ));
      return createImageFromImageBitmap(bitmap);
    }
    SkImage? skImage;
    if (isSoftware) {
      if (object.isA<VideoFrame>()) {
        // If the object is a VideoFrame, we need to draw it to a canvas first to
        // avoid a bug in CanvasKit where MakeImageFromCanvasImageSource doesn't
        // work with VideoFrames.
        final DomHTMLCanvasElement canvas = createDomCanvasElement(width: width, height: height);
        final DomCanvasRenderingContext2D ctx = canvas.context2D;
        ctx.drawImage(object as VideoFrame, 0, 0);
        skImage = canvasKit.MakeImageFromCanvasImageSource(canvas);
      } else {
        skImage = canvasKit.MakeImageFromCanvasImageSource(object);
      }
    } else {
      skImage = canvasKit.MakeLazyImageFromTextureSourceWithInfo(
        object,
        SkPartialImageInfo(
          width: width.toDouble(),
          height: height.toDouble(),
          alphaType: canvasKit.AlphaType.Premul,
          colorType: canvasKit.ColorType.RGBA_8888,
          colorSpace: SkColorSpaceSRGB,
        ),
      );
    }

    if (skImage == null) {
      throw Exception('Failed to convert image bitmap to an SkImage.');
    }
    return CkImage(skImage);
  }

  @override
  void decodeImageFromPixels(
    Uint8List pixels,
    int width,
    int height,
    ui.PixelFormat format,
    ui.ImageDecoderCallback callback, {
    int? rowBytes,
    int? targetWidth,
    int? targetHeight,
    bool allowUpscaling = true,
  }) => skiaDecodeImageFromPixels(
    pixels,
    width,
    height,
    format,
    callback,
    rowBytes: rowBytes,
    targetWidth: targetWidth,
    targetHeight: targetHeight,
    allowUpscaling: allowUpscaling,
  );

  @override
  ui.ImageShader createImageShader(
    ui.Image image,
    ui.TileMode tmx,
    ui.TileMode tmy,
    Float64List matrix4,
    ui.FilterQuality? filterQuality,
  ) => CkImageShader(image, tmx, tmy, matrix4, filterQuality);

  CkPathConstructors pathConstructors = CkPathConstructors();

  @override
  ui.Path createPath() => LazyPath(pathConstructors);

  @override
  ui.Path copyPath(ui.Path src) => LazyPath.fromLazyPath(src as LazyPath);

  @override
  ui.Path combinePaths(ui.PathOperation op, ui.Path path1, ui.Path path2) =>
      LazyPath.combined(op, path1 as LazyPath, path2 as LazyPath);

  @override
  ui.TextStyle createTextStyle({
    ui.Color? color,
    ui.TextDecoration? decoration,
    ui.Color? decorationColor,
    ui.TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    ui.FontWeight? fontWeight,
    ui.FontStyle? fontStyle,
    ui.TextBaseline? textBaseline,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    double? fontSize,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
    ui.TextLeadingDistribution? leadingDistribution,
    ui.Locale? locale,
    ui.Paint? background,
    ui.Paint? foreground,
    List<ui.Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    List<ui.FontVariation>? fontVariations,
  }) => isExperimentalWebParagraph
      ? WebTextStyle(
          color: color,
          decoration: decoration,
          decorationColor: decorationColor,
          decorationStyle: decorationStyle,
          decorationThickness: decorationThickness,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          textBaseline: textBaseline,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
          fontSize: fontSize,
          letterSpacing: letterSpacing,
          wordSpacing: wordSpacing,
          height: height,
          leadingDistribution: leadingDistribution,
          locale: locale,
          background: background as CkPaint?,
          foreground: foreground as CkPaint?,
          shadows: shadows,
          fontFeatures: fontFeatures,
          fontVariations: fontVariations,
        )
      : CkTextStyle(
          color: color,
          decoration: decoration,
          decorationColor: decorationColor,
          decorationStyle: decorationStyle,
          decorationThickness: decorationThickness,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          textBaseline: textBaseline,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
          fontSize: fontSize,
          letterSpacing: letterSpacing,
          wordSpacing: wordSpacing,
          height: height,
          leadingDistribution: leadingDistribution,
          locale: locale,
          background: background as CkPaint?,
          foreground: foreground as CkPaint?,
          shadows: shadows,
          fontFeatures: fontFeatures,
          fontVariations: fontVariations,
        );

  @override
  ui.ParagraphStyle createParagraphStyle({
    ui.TextAlign? textAlign,
    ui.TextDirection? textDirection,
    int? maxLines,
    String? fontFamily,
    double? fontSize,
    double? height,
    ui.TextHeightBehavior? textHeightBehavior,
    ui.FontWeight? fontWeight,
    ui.FontStyle? fontStyle,
    ui.StrutStyle? strutStyle,
    String? ellipsis,
    ui.Locale? locale,
  }) => isExperimentalWebParagraph
      ? WebParagraphStyle(
          textAlign: textAlign,
          textDirection: textDirection,
          maxLines: maxLines,
          fontFamily: fontFamily,
          fontSize: fontSize,
          height: height,
          textHeightBehavior: textHeightBehavior,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          strutStyle: strutStyle as WebStrutStyle?,
          ellipsis: ellipsis,
          locale: locale,
        )
      : CkParagraphStyle(
          textAlign: textAlign,
          textDirection: textDirection,
          maxLines: maxLines,
          fontFamily: fontFamily,
          fontSize: fontSize,
          height: height,
          textHeightBehavior: textHeightBehavior,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          strutStyle: strutStyle,
          ellipsis: ellipsis,
          locale: locale,
        );

  @override
  ui.StrutStyle createStrutStyle({
    String? fontFamily,
    List<String>? fontFamilyFallback,
    double? fontSize,
    double? height,
    ui.TextLeadingDistribution? leadingDistribution,
    double? leading,
    ui.FontWeight? fontWeight,
    ui.FontStyle? fontStyle,
    bool? forceStrutHeight,
  }) => isExperimentalWebParagraph
      ? WebStrutStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
          fontSize: fontSize,
          height: height,
          leadingDistribution: leadingDistribution,
          leading: leading,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          forceStrutHeight: forceStrutHeight,
        )
      : CkStrutStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
          fontSize: fontSize,
          height: height,
          leadingDistribution: leadingDistribution,
          leading: leading,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          forceStrutHeight: forceStrutHeight,
        );

  @override
  ui.ParagraphBuilder createParagraphBuilder(ui.ParagraphStyle style) =>
      isExperimentalWebParagraph ? WebParagraphBuilder(style) : CkParagraphBuilder(style);

  @override
  void clearFragmentProgramCache() {
    _programs.clear();
  }

  static final Map<String, Future<ui.FragmentProgram>> _programs =
      <String, Future<ui.FragmentProgram>>{};

  @override
  Future<ui.FragmentProgram> createFragmentProgram(String assetKey) {
    if (_programs.containsKey(assetKey)) {
      return _programs[assetKey]!;
    }
    return _programs[assetKey] = ui_web.assetManager.load(assetKey).then((ByteData data) {
      return CkFragmentProgram.fromBytes(assetKey, data.buffer.asUint8List());
    });
  }

  @override
  ui.LineMetrics createLineMetrics({
    required bool hardBreak,
    required double ascent,
    required double descent,
    required double unscaledAscent,
    required double height,
    required double width,
    required double left,
    required double baseline,
    required int lineNumber,
  }) => EngineLineMetrics(
    hardBreak: hardBreak,
    ascent: ascent,
    descent: descent,
    unscaledAscent: unscaledAscent,
    height: height,
    width: width,
    left: left,
    baseline: baseline,
    lineNumber: lineNumber,
  );

  @override
  void dumpDebugInfo() {
    var i = 0;
    for (final ViewRasterizer viewRasterizer in rasterizers.values) {
      final Map<String, dynamic>? debugJson = viewRasterizer.dumpDebugInfo();
      if (debugJson != null) {
        downloadDebugInfo('flutter-scene$i', debugJson);
        i++;
      }
    }
  }

  late CkSurface _pictureToImageSurface;

  @override
  CkSurface get pictureToImageSurface => _pictureToImageSurface;
}
