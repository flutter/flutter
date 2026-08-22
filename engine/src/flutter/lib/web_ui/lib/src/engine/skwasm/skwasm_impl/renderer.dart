// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

class SkwasmRenderer extends Renderer {
  @override
  bool get isMultiThreaded => skwasmIsMultiThreaded();

  @override
  bool get supportsResizingAnimatedImages => true;

  bool get isWimp => skwasmIsWimp();

  @override
  SkwasmPathConstructors pathConstructors = SkwasmPathConstructors();

  @override
  final SkwasmFontCollection fontCollection = SkwasmFontCollection();

  @override
  ui.Canvas createCanvas(ui.PictureRecorder recorder, [ui.Rect? cullRect]) {
    return SkwasmCanvas(recorder as SkwasmPictureRecorder, cullRect ?? ui.Rect.largest);
  }

  @override
  BackendImageFilter createBlurImageFilter({
    required double sigmaX,
    required double sigmaY,
    required ui.TileMode tileMode,
  }) {
    return SkwasmBlurImageFilter(sigmaX: sigmaX, sigmaY: sigmaY, tileMode: tileMode);
  }

  @override
  BackendImageFilter createDilateImageFilter({required double radiusX, required double radiusY}) {
    return SkwasmDilateImageFilter(radiusX: radiusX, radiusY: radiusY);
  }

  @override
  BackendImageFilter createErodeImageFilter({required double radiusX, required double radiusY}) {
    return SkwasmErodeImageFilter(radiusX: radiusX, radiusY: radiusY);
  }

  @override
  BackendImageFilter createMatrixImageFilter({
    required Float64List matrix,
    required ui.FilterQuality filterQuality,
  }) {
    return SkwasmMatrixImageFilter(matrix: matrix, filterQuality: filterQuality);
  }

  @override
  BackendImageFilter createComposeImageFilter({
    required BackendImageFilter outer,
    required BackendImageFilter inner,
  }) {
    return SkwasmComposeImageFilter(outer: outer, inner: inner);
  }

  @override
  BackendImageFilter createColorFilterImageFilter({required BackendColorFilter filter}) {
    return SkwasmColorFilterImageFilter(filter as SkwasmColorFilter);
  }

  @override
  BackendImageShader createImageShader(
    EngineImage image,
    ui.TileMode tmx,
    ui.TileMode tmy,
    Float64List? matrix4,
    ui.FilterQuality filterQuality,
  ) => SkwasmImageShader(image.backendImage as SkwasmImage, tmx, tmy, matrix4, filterQuality);

  @override
  BackendGradient createGradientLinear(
    Float32List endPoints,
    Uint32List colors,
    Float32List? colorStops,
    ui.TileMode tileMode,
    Float32List? matrix4,
  ) => SkwasmGradient.linear(endPoints, colors, colorStops, tileMode, matrix4);

  @override
  BackendGradient createGradientRadial(
    double centerX,
    double centerY,
    double radius,
    Uint32List colors,
    Float32List? colorStops,
    ui.TileMode tileMode,
    Float32List? matrix4,
  ) => SkwasmGradient.radial(centerX, centerY, radius, colors, colorStops, tileMode, matrix4);

  @override
  BackendGradient createGradientConical(
    double startX,
    double startY,
    double startRadius,
    double endX,
    double endY,
    double endRadius,
    Uint32List colors,
    Float32List? colorStops,
    ui.TileMode tileMode,
    Float32List? matrix4,
  ) => SkwasmGradient.conical(
    startX,
    startY,
    startRadius,
    endX,
    endY,
    endRadius,
    colors,
    colorStops,
    tileMode,
    matrix4,
  );

  @override
  BackendGradient createGradientSweep(
    double centerX,
    double centerY,
    Uint32List colors,
    Float32List? colorStops,
    ui.TileMode tileMode,
    double startAngle,
    double endAngle,
    Float32List? matrix4,
  ) => SkwasmGradient.sweep(
    centerX,
    centerY,
    colors,
    colorStops,
    tileMode,
    startAngle,
    endAngle,
    matrix4,
  );

  @override
  ui.Paint createPaint() => SkwasmPaint();

  @override
  BackendColorFilter createColorFilter(EngineColorFilter filter) => SkwasmColorFilter(filter);

  @override
  BackendMaskFilter createMaskFilter(EngineMaskFilter filter) => SkwasmMaskFilter(filter);

  @override
  ui.ParagraphBuilder createParagraphBuilder(ui.ParagraphStyle style) =>
      SkwasmParagraphBuilder(style as SkwasmParagraphStyle, fontCollection);

  @override
  WebParagraphPainter createWebParagraphPainter(WebParagraph paragraph) {
    throw UnimplementedError('WebParagraph is not supported on Skwasm');
  }

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
    ui.Hyphens? hyphens,
  }) => SkwasmParagraphStyle(
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
    hyphens: hyphens,
  );

  @override
  ui.PictureRecorder createPictureRecorder() => SkwasmPictureRecorder();

  @override
  ui.SceneBuilder createSceneBuilder() => LayerSceneBuilder();

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
  }) => SkwasmStrutStyle(
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
  }) => SkwasmTextStyle(
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
    background: background,
    foreground: foreground,
    shadows: shadows,
    fontFeatures: fontFeatures,
    fontVariations: fontVariations,
  );

  @override
  BackendVertices createVertices(
    ui.VertexMode mode,
    Float32List positions, {
    Float32List? textureCoordinates,
    Int32List? colors,
    Uint16List? indices,
  }) => SkwasmVertices(
    mode,
    positions,
    textureCoordinates: textureCoordinates,
    colors: colors,
    indices: indices,
  );

  @override
  BackendImage decodeBackendImageFromPixels(
    Uint8List pixels, {
    required int width,
    required int height,
    required ui.PixelFormat format,
    int? rowBytes,
  }) => createSkwasmImageFromPixels(pixels, width, height, format, rowBytes: rowBytes);

  @override
  FutureOr<void> initialize() {
    rasterizer = OffscreenCanvasRasterizer(
      (OffscreenCanvasProvider canvasProvider) => SkwasmSurface(canvasProvider),
    );
    return super.initialize();
  }

  @override
  BackendAnimatedImage createAnimatedImage(Uint8List bytes, {int? targetWidth, int? targetHeight}) {
    return SkwasmAnimatedImageDecoder(bytes, targetWidth, targetHeight);
  }

  @override
  BackendImage createImageFromImageSource(ImageSource source) {
    final ImageHandle handle = imageCreateFromTextureSource(
      source.canvasImageSource as JSObject,
      source.width,
      source.height,
      (pictureToImageSurface as SkwasmSurface).handle,
    );
    return SkwasmImage(handle);
  }

  @override
  String get rendererTag => 'skwasm';

  static final Map<String, Future<ui.FragmentProgram>> _programs =
      <String, Future<ui.FragmentProgram>>{};

  @override
  void clearFragmentProgramCache() {
    _programs.clear();
  }

  @override
  Future<ui.FragmentProgram> createFragmentProgram(String assetKey) {
    if (_programs.containsKey(assetKey)) {
      return _programs[assetKey]!;
    }
    return _programs[assetKey] = ui_web.assetManager.load(assetKey).then((ByteData data) {
      return SkwasmFragmentProgram.fromBytes(assetKey, data.buffer.asUint8List());
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
  }) => SkwasmLineMetrics(
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
    if (kDebugMode) {
      withStackScope((StackScope scope) {
        final Pointer<Uint32> counts = scope.allocUint32Array(28);
        skwasmGetLiveObjectCounts(counts);
        final countsJson = <String, dynamic>{
          'lineBreakBufferCount': counts[0],
          'unicodePositionBufferCount': counts[1],
          'lineMetricsCount': counts[2],
          'textBoxListCount': counts[3],
          'paragraphBuilderCount': counts[4],
          'paragraphCount': counts[5],
          'strutStyleCount': counts[6],
          'textStyleCount': counts[7],
          'animatedImageCount': counts[8],
          'countourMeasureIterCount': counts[9],
          'countourMeasureCount': counts[10],
          'dataCount': counts[11],
          'colorFilterCount': counts[12],
          'imageFilterCount': counts[13],
          'maskFilterCount': counts[14],
          'typefaceCount': counts[15],
          'fontCollectionCount': counts[16],
          'imageCount': counts[17],
          'paintCount': counts[18],
          'pathCount': counts[19],
          'pictureCount': counts[20],
          'pictureRecorderCount': counts[21],
          'shaderCount': counts[22],
          'runtimeEffectCount': counts[23],
          'stringCount': counts[24],
          'string16Count': counts[25],
          'surfaceCount': counts[26],
          'verticesCount': counts[27],
        };
        downloadDebugInfo('live_object_counts', countsJson);
      });

      var i = 0;
      for (final ViewRasterizer viewRasterizer in rasterizers.values) {
        final Map<String, dynamic>? debugJson = viewRasterizer.dumpDebugInfo();
        if (debugJson != null) {
          downloadDebugInfo('flutter-scene$i', debugJson);
          i++;
        }
      }
    }
  }

  @override
  void debugResetRasterizer() {
    rasterizer = OffscreenCanvasRasterizer(
      (OffscreenCanvasProvider canvasProvider) => SkwasmSurface(canvasProvider),
    );
  }

  @override
  Surface get pictureToImageSurface => (rasterizer as OffscreenCanvasRasterizer).offscreenSurface;
}
