// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

enum CanvasKitVariant {
  /// The appropriate variant is chosen based on the browser.
  ///
  /// This is the default variant.
  auto,

  /// The full variant that can be used in any browser.
  full,

  /// The variant that is optimized for Chromium browsers.
  ///
  /// WARNING: In most cases, you should use [auto] instead of this variant. Using
  /// this variant in a non-Chromium browser will result in a broken app.
  chromium,
}

class CanvasKitRenderer implements Renderer {
  static CanvasKitRenderer get instance => _instance;
  static late CanvasKitRenderer _instance;

  Future<void>? _initialized;

  @override
  String get rendererTag => 'canvaskit';

  late final SkiaFontCollection _fontCollection = SkiaFontCollection();

  @override
  SkiaFontCollection get fontCollection => _fontCollection;

  /// The scene host, where the root canvas and overlay canvases are added to.
  DomElement? _sceneHost;
  DomElement? get sceneHost => _sceneHost;

  late Rasterizer rasterizer = Rasterizer();

  set resourceCacheMaxBytes(int bytes) => rasterizer.setSkiaResourceCacheMaxBytes(bytes);

  @override
  Future<void> initialize() async {
    _initialized ??= () async {
      if (windowFlutterCanvasKit != null) {
        canvasKit = windowFlutterCanvasKit!;
      } else {
        canvasKit = await downloadCanvasKit();
        windowFlutterCanvasKit = canvasKit;
      }
      _instance = this;
    }();
    return _initialized;
  }

  @override
  void reset(FlutterViewEmbedder embedder) {
    // CanvasKit uses a static scene element that never gets replaced, so it's
    // added eagerly during initialization here and never touched, unless the
    // system is reset due to hot restart or in a test.
    _sceneHost = createDomElement('flt-scene');
    embedder.addSceneToSceneHost(_sceneHost);
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
    indices: indices);

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
    indices: indices);

  @override
  ui.Canvas createCanvas(ui.PictureRecorder recorder, [ui.Rect? cullRect]) =>
    CanvasKitCanvas(recorder, cullRect);

  @override
  ui.Gradient createLinearGradient(
    ui.Offset from,
    ui.Offset to,
    List<ui.Color> colors, [
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    Float32List? matrix4
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
    List<ui.Color> colors,
    [List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    Float32List? matrix]
  ) => CkGradientConical(
    focal,
    focalRadius,
    center,
    radius,
    colors,
    colorStops,
    tileMode,
    matrix);

  @override
  ui.Gradient createSweepGradient(
    ui.Offset center,
    List<ui.Color> colors, [
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    double startAngle = 0.0,
    double endAngle = math.pi * 2,
    Float32List? matrix4
  ]) => CkGradientSweep(center, colors, colorStops, tileMode, startAngle, endAngle, matrix4);

  @override
  ui.PictureRecorder createPictureRecorder() => CkPictureRecorder();

  @override
  ui.SceneBuilder createSceneBuilder() => LayerSceneBuilder();

  @override
  ui.ImageFilter createBlurImageFilter({
    double sigmaX = 0.0,
    double sigmaY = 0.0,
    ui.TileMode tileMode = ui.TileMode.clamp
  }) => CkImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY, tileMode: tileMode);

  @override
  ui.ImageFilter createDilateImageFilter({double radiusX = 0.0, double radiusY = 0.0}) {
    // TODO(fzyzcjy): implement dilate. https://github.com/flutter/flutter/issues/101085
    throw UnimplementedError('ImageFilter.dilate not implemented for CanvasKit.');
  }

  @override
  ui.ImageFilter createErodeImageFilter({double radiusX = 0.0, double radiusY = 0.0}) {
    // TODO(fzyzcjy): implement erode. https://github.com/flutter/flutter/issues/101085
    throw UnimplementedError('ImageFilter.erode not implemented for CanvasKit.');
  }

  @override
  ui.ImageFilter createMatrixImageFilter(
    Float64List matrix4, {
    ui.FilterQuality filterQuality = ui.FilterQuality.low
  }) => CkImageFilter.matrix(matrix: matrix4, filterQuality: filterQuality);

  @override
  ui.ImageFilter composeImageFilters({required ui.ImageFilter outer, required ui.ImageFilter inner}) {
  // TODO(ferhat): add implementation
    throw UnimplementedError('ImageFilter.compose not implemented for CanvasKit.');
  }

  @override
  Future<ui.Codec> instantiateImageCodec(
    Uint8List list, {
    int? targetWidth,
    int? targetHeight,
    bool allowUpscaling = true
  }) async => skiaInstantiateImageCodec(
    list,
    targetWidth,
    targetHeight
  );

  @override
  Future<ui.Codec> instantiateImageCodecFromUrl(
    Uri uri, {
    WebOnlyImageCodecChunkCallback? chunkCallback
  }) => skiaInstantiateWebImageCodec(uri.toString(), chunkCallback);

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
    bool allowUpscaling = true
  }) => skiaDecodeImageFromPixels(
    pixels,
    width,
    height,
    format,
    callback,
    rowBytes: rowBytes,
    targetWidth: targetWidth,
    targetHeight: targetHeight,
    allowUpscaling: allowUpscaling
  );

  @override
  ui.ImageShader createImageShader(
    ui.Image image,
    ui.TileMode tmx,
    ui.TileMode tmy,
    Float64List matrix4,
    ui.FilterQuality? filterQuality
  ) => CkImageShader(image, tmx, tmy, matrix4, filterQuality);

  @override
  ui.Path createPath() => CkPath();

  @override
  ui.Path copyPath(ui.Path src) => CkPath.from(src as CkPath);

  @override
  ui.Path combinePaths(ui.PathOperation op, ui.Path path1, ui.Path path2) =>
    CkPath.combine(op, path1, path2);

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
    List<ui.FontVariation>? fontVariations
  }) => CkTextStyle(
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
    ui.Locale? locale
  }) => CkParagraphStyle(
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
    bool? forceStrutHeight
  }) => CkStrutStyle(
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
    CkParagraphBuilder(style);

  @override
  void renderScene(ui.Scene scene) {
    // "Build finish" and "raster start" happen back-to-back because we
    // render on the same thread, so there's no overhead from hopping to
    // another thread.
    //
    // CanvasKit works differently from the HTML renderer in that in HTML
    // we update the DOM in SceneBuilder.build, which is these function calls
    // here are CanvasKit-only.
    frameTimingsOnBuildFinish();
    frameTimingsOnRasterStart();

    rasterizer.draw((scene as LayerScene).layerTree);
    frameTimingsOnRasterFinish();
  }

  @override
  void clearFragmentProgramCache() {
    _programs.clear();
  }

  static final Map<String, Future<ui.FragmentProgram>> _programs = <String, Future<ui.FragmentProgram>>{};

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
    required int lineNumber
  }) => EngineLineMetrics(
    hardBreak: hardBreak,
    ascent: ascent,
    descent: descent,
    unscaledAscent: unscaledAscent,
    height: height,
    width: width,
    left: left,
    baseline: baseline,
    lineNumber: lineNumber
  );
}
