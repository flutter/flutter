// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

// TODO(jacksongardner): Actually implement skwasm renderer.
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
  ui.ImageFilter composeImageFilters({required ui.ImageFilter outer, required ui.ImageFilter inner}) {
    throw UnimplementedError('composeImageFilters not yet implemented');
  }

  @override
  ui.Path copyPath(ui.Path src) {
    return SkwasmPath.from(src as SkwasmPath);
  }

  @override
  ui.ImageFilter createBlurImageFilter({double sigmaX = 0.0, double sigmaY = 0.0, ui.TileMode tileMode = ui.TileMode.clamp}) {
    throw UnimplementedError('createBlurImageFilter not yet implemented');
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
  ui.ImageFilter createDilateImageFilter({double radiusX = 0.0, double radiusY = 0.0}) {
    throw UnimplementedError('createDilateImageFilter not yet implemented');
  }

  @override
  ui.ImageFilter createErodeImageFilter({double radiusX = 0.0, double radiusY = 0.0}) {
    throw UnimplementedError('createErodeImageFilter not yet implemented');
  }

  @override
  ui.ImageShader createImageShader(ui.Image image, ui.TileMode tmx, ui.TileMode tmy, Float64List matrix4, ui.FilterQuality? filterQuality) {
    throw UnimplementedError('createImageShader not yet implemented');
  }

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
  ui.ImageFilter createMatrixImageFilter(Float64List matrix4, {ui.FilterQuality filterQuality = ui.FilterQuality.low}) {
    throw UnimplementedError('createMatrixImageFilter not yet implemented');
  }

  @override
  ui.Paint createPaint() => SkwasmPaint();

  @override
  ui.ParagraphBuilder createParagraphBuilder(ui.ParagraphStyle style) => SkwasmParagraphBuilder();

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
  }) => SkwasmParagraphStyle();

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
  }) {
    throw UnimplementedError('createStrutStyle not yet implemented');
  }

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
  }) => SkwasmTextStyle();

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
  void decodeImageFromPixels(Uint8List pixels, int width, int height, ui.PixelFormat format, ui.ImageDecoderCallback callback, {int? rowBytes, int? targetWidth, int? targetHeight, bool allowUpscaling = true}) {
    throw UnimplementedError('decodeImageFromPixels not yet implemented');
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
  Future<ui.Codec> instantiateImageCodec(Uint8List list, {int? targetWidth, int? targetHeight, bool allowUpscaling = true}) {
    throw UnimplementedError('instantiateImageCodec not yet implemented');
  }

  @override
  Future<ui.Codec> instantiateImageCodecFromUrl(Uri uri, {WebOnlyImageCodecChunkCallback? chunkCallback}) {
    throw UnimplementedError('instantiateImageCodecFromUrl not yet implemented');
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
    return _programs[assetKey] = assetManager.load(assetKey).then((ByteData data) {
      return SkwasmFragmentProgram.fromBytes(assetKey, data.buffer.asUint8List());
    });
  }
}
