// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

class SkwasmRenderer implements Renderer {
  late DomCanvasElement sceneElement;
  late SkwasmSurface surface;
  ui.Size? surfaceSize;

  @override
  final SkwasmFontCollection fontCollection = SkwasmFontCollection();

  @override
  ui.Path combinePaths(ui.PathOperation op, ui.Path path1, ui.Path path2) {
    return SkwasmPath.combine(op, path1 as SkwasmPath, path2 as SkwasmPath);
  }

  @override
  ui.Path copyPath(ui.Path src) {
    return SkwasmPath.from(src as SkwasmPath);
  }

  @override
  ui.Canvas createCanvas(ui.PictureRecorder recorder, [ui.Rect? cullRect]) {
    return SkwasmCanvas(recorder as SkwasmPictureRecorder, cullRect ?? ui.Rect.largest);
  }

  @override
  ui.Gradient createConicalGradient(
    ui.Offset focal,
    double focalRadius,
    ui.Offset center,
    double radius,
    List<ui.Color> colors, [
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    Float32List? matrix]) => SkwasmGradient.conical(
      focal: focal,
      focalRadius: focalRadius,
      center: center,
      centerRadius: radius,
      colors: colors,
      colorStops: colorStops,
      tileMode: tileMode,
      matrix4: matrix,
    );

  @override
  ui.ImageFilter createBlurImageFilter({
    double sigmaX = 0.0,
    double sigmaY = 0.0,
    ui.TileMode tileMode = ui.TileMode.clamp
  }) => SkwasmImageFilter.blur(
    sigmaX: sigmaX,
    sigmaY: sigmaY,
    tileMode: tileMode
  );

  @override
  ui.ImageFilter createDilateImageFilter({
    double radiusX = 0.0,
    double radiusY = 0.0
  }) => SkwasmImageFilter.dilate(
    radiusX: radiusX,
    radiusY: radiusY,
  );

  @override
  ui.ImageFilter createErodeImageFilter({
    double radiusX = 0.0,
    double radiusY = 0.0
  }) => SkwasmImageFilter.erode(
    radiusX: radiusX,
    radiusY: radiusY,
  );

  @override
  ui.ImageFilter composeImageFilters({
    required ui.ImageFilter outer,
    required ui.ImageFilter inner
  }) => SkwasmImageFilter.compose(
    SkwasmImageFilter.fromUiFilter(outer),
    SkwasmImageFilter.fromUiFilter(inner),
  );

  @override
  ui.ImageFilter createMatrixImageFilter(
    Float64List matrix4, {
    ui.FilterQuality filterQuality = ui.FilterQuality.low
  }) => SkwasmImageFilter.matrix(
    matrix4,
    filterQuality: filterQuality
  );

  @override
  ui.ImageShader createImageShader(
    ui.Image image,
    ui.TileMode tmx,
    ui.TileMode tmy,
    Float64List matrix4,
    ui.FilterQuality? filterQuality
  ) => SkwasmImageShader.imageShader(
    image as SkwasmImage,
    tmx,
    tmy,
    matrix4,
    filterQuality
  );

  @override
  ui.Gradient createLinearGradient(
    ui.Offset from,
    ui.Offset to,
    List<ui.Color> colors, [
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    Float32List? matrix4
  ]) => SkwasmGradient.linear(
    from: from,
    to: to,
    colors: colors,
    colorStops: colorStops,
    tileMode: tileMode,
    matrix4: matrix4,
  );


  @override
  ui.Paint createPaint() => SkwasmPaint();

  @override
  ui.ParagraphBuilder createParagraphBuilder(ui.ParagraphStyle style) =>
    SkwasmParagraphBuilder(style as SkwasmParagraphStyle, fontCollection);

  @override
  ui.ParagraphStyle createParagraphStyle({
    ui.TextAlign? textAlign,
    ui.TextDirection? textDirection,
    int? maxLines, String? fontFamily,
    double? fontSize,
    double? height,
    ui.TextHeightBehavior? textHeightBehavior,
    ui.FontWeight? fontWeight,
    ui.FontStyle? fontStyle,
    ui.StrutStyle? strutStyle,
    String? ellipsis,
    ui.Locale? locale
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
  );

  @override
  ui.Path createPath() => SkwasmPath();

  @override
  ui.PictureRecorder createPictureRecorder() => SkwasmPictureRecorder();

  @override
  ui.Gradient createRadialGradient(
    ui.Offset center,
    double radius,
    List<ui.Color> colors, [
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    Float32List? matrix4
  ]) => SkwasmGradient.radial(
    center: center,
    radius: radius,
    colors: colors,
    colorStops: colorStops,
    tileMode: tileMode,
    matrix4: matrix4
  );

  @override
  ui.SceneBuilder createSceneBuilder() => SkwasmSceneBuilder();

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
  ui.Gradient createSweepGradient(
    ui.Offset center,
    List<ui.Color> colors, [
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    double startAngle = 0.0,
    double endAngle = math.pi * 2,
    Float32List? matrix4
  ]) => SkwasmGradient.sweep(
    center: center,
    colors: colors,
    colorStops: colorStops,
    tileMode: tileMode,
    startAngle: startAngle,
    endAngle: endAngle,
    matrix4: matrix4
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
    List<ui.FontVariation>? fontVariations
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
  ui.Vertices createVertices(
    ui.VertexMode mode,
    List<ui.Offset> positions,
    {
      List<ui.Offset>? textureCoordinates,
      List<ui.Color>? colors,
      List<int>? indices
    }) =>
    SkwasmVertices(
      mode,
      positions,
      textureCoordinates: textureCoordinates,
      colors: colors,
      indices: indices
    );

  @override
  ui.Vertices createVerticesRaw(
    ui.VertexMode mode,
    Float32List positions,
    {
      Float32List? textureCoordinates,
      Int32List? colors,
      Uint16List? indices
    }) =>
    SkwasmVertices.raw(
      mode,
      positions,
      textureCoordinates: textureCoordinates,
      colors: colors,
      indices: indices
    );

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
  }) {
    final SkwasmImage pixelImage = SkwasmImage.fromPixels(
      pixels,
      width,
      height,
      format
    );
    final ui.Image scaledImage = scaleImageIfNeeded(
      pixelImage,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      allowUpscaling: allowUpscaling,
    );
    callback(scaledImage);
  }

  @override
  FutureOr<void> initialize() {
    // TODO(jacksongardner): This is very basic and doesn't work for element
    // embedding or with platform views. We need to update this at some point
    // to deal with those cases.
    sceneElement = createDomCanvasElement();
    sceneElement.id = 'flt-scene';
    domDocument.body!.appendChild(sceneElement);
    surface = SkwasmSurface('#flt-scene');
    domDocument.body!.removeChild(sceneElement);
  }

  @override
  Future<ui.Codec> instantiateImageCodec(
    Uint8List list, {
    int? targetWidth,
    int? targetHeight,
    bool allowUpscaling = true
  }) async {
    final String? contentType = detectContentType(list);
    if (contentType == null) {
      throw Exception('Could not determine content type of image from data');
    }
    final ui.Codec baseDecoder = SkwasmImageDecoder(
      contentType: contentType,
      dataSource: list.toJS,
      debugSource: 'encoded image bytes',
    );
    if (targetWidth == null && targetHeight == null) {
      return baseDecoder;
    }
    return ResizingCodec(
      baseDecoder,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      allowUpscaling: allowUpscaling
    );
  }

  @override
  Future<ui.Codec> instantiateImageCodecFromUrl(
    Uri uri, {
    WebOnlyImageCodecChunkCallback? chunkCallback
  }) async {
    final DomResponse response = await rawHttpGet(uri.toString());
    final String? contentType = response.headers.get('Content-Type');
    if (contentType == null) {
      throw Exception('Could not determine content type of image at url $uri');
    }
    return SkwasmImageDecoder(
      contentType: contentType,
      dataSource: response.body as JSAny,
      debugSource: uri.toString(),
    );
  }

  @override
  Future<void> renderScene(ui.Scene scene) async {
    final ui.Size frameSize = ui.window.physicalSize;
    if (frameSize != surfaceSize) {
      final double logicalWidth = frameSize.width.ceil() / window.devicePixelRatio;
      final double logicalHeight = frameSize.height.ceil() / window.devicePixelRatio;
      final DomCSSStyleDeclaration style = sceneElement.style;
      style.width = '${logicalWidth}px';
      style.height = '${logicalHeight}px';

      surface.setSize(frameSize.width.ceil(), frameSize.height.ceil());
      surfaceSize = frameSize;
    }
    final SkwasmPicture picture = (scene as SkwasmScene).picture as SkwasmPicture;
    await surface.renderPicture(picture);
  }

  @override
  String get rendererTag => 'skwasm';

  @override
  void reset(FlutterViewEmbedder embedder) {
    embedder.addSceneToSceneHost(sceneElement);
  }

  static final Map<String, Future<ui.FragmentProgram>> _programs = <String, Future<ui.FragmentProgram>>{};

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
    required int lineNumber
  }) => SkwasmLineMetrics(
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
