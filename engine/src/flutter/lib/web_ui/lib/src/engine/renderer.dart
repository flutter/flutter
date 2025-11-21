// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart'
    if (dart.library.html) 'package:ui/src/engine/skwasm/skwasm_stub.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

final Renderer _renderer = Renderer._internal();
Renderer get renderer => _renderer;

/// This class is an abstraction over the rendering backend for the web engine.
/// Which backend is selected is based off of the `--web-renderer` command-line
/// argument passed to the flutter tool. It provides many of the rendering
/// primitives of the dart:ui library, as well as other backend-specific pieces
/// of functionality needed by the rest of the generic web engine code.
abstract class Renderer {
  // Abstract generative constructor to allow extending this renderer.
  Renderer();

  factory Renderer._internal() {
    if (FlutterConfiguration.flutterWebUseSkwasm) {
      return SkwasmRenderer();
    } else if (FlutterConfiguration.useSkia) {
      return CanvasKitRenderer();
    } else {
      throw StateError(
        'Wrong combination of configuration flags. Was expecting either CanvasKit or Skwasm to be '
        'selected.',
      );
    }
  }

  String get rendererTag;
  FlutterFontCollection get fontCollection;

  late Rasterizer rasterizer;

  /// Resets the [Rasterizer] to the default value. Used in tests.
  @visibleForTesting
  void debugResetRasterizer();

  /// Override the rasterizer with the given [_rasterizer]. Used in tests.
  @visibleForTesting
  void debugOverrideRasterizer(Rasterizer testRasterizer) {
    rasterizer = testRasterizer;
  }

  // Listens for view creation events from the view manager.
  late StreamSubscription<int> _onViewCreatedListener;
  // Listens for view disposal events from the view manager.
  late StreamSubscription<int> _onViewDisposedListener;

  /// Set the maximum number of bytes that can be held in the GPU resource cache.
  set resourceCacheMaxBytes(int bytes) => rasterizer.setResourceCacheMaxBytes(bytes);

  @mustCallSuper
  FutureOr<void> initialize() {
    // Views may have been registered before this renderer was initialized.
    // Create rasterizers for them and then start listening for new view
    // creation/disposal events.
    final FlutterViewManager viewManager = EnginePlatformDispatcher.instance.viewManager;
    for (final EngineFlutterView view in viewManager.views) {
      _onViewCreated(view.viewId);
    }
    _onViewCreatedListener = viewManager.onViewCreated.listen(_onViewCreated);
    _onViewDisposedListener = viewManager.onViewDisposed.listen(_onViewDisposed);
  }

  void _onViewCreated(int viewId) {
    final EngineFlutterView view = EnginePlatformDispatcher.instance.viewManager[viewId]!;
    rasterizers[view.viewId] = rasterizer.createViewRasterizer(view);
  }

  void _onViewDisposed(int viewId) {
    // The view has already been disposed.
    if (!rasterizers.containsKey(viewId)) {
      return;
    }
    final ViewRasterizer rasterizer = rasterizers.remove(viewId)!;
    rasterizer.dispose();
  }

  ui.Paint createPaint();

  ui.Vertices createVertices(
    ui.VertexMode mode,
    List<ui.Offset> positions, {
    List<ui.Offset>? textureCoordinates,
    List<ui.Color>? colors,
    List<int>? indices,
  });
  ui.Vertices createVerticesRaw(
    ui.VertexMode mode,
    Float32List positions, {
    Float32List? textureCoordinates,
    Int32List? colors,
    Uint16List? indices,
  });

  ui.PictureRecorder createPictureRecorder();
  ui.Canvas createCanvas(ui.PictureRecorder recorder, [ui.Rect? cullRect]);
  ui.SceneBuilder createSceneBuilder();

  ui.Gradient createLinearGradient(
    ui.Offset from,
    ui.Offset to,
    List<ui.Color> colors, [
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    Float32List? matrix4,
  ]);
  ui.Gradient createRadialGradient(
    ui.Offset center,
    double radius,
    List<ui.Color> colors, [
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    Float32List? matrix4,
  ]);
  ui.Gradient createConicalGradient(
    ui.Offset focal,
    double focalRadius,
    ui.Offset center,
    double radius,
    List<ui.Color> colors, [
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    Float32List? matrix,
  ]);
  ui.Gradient createSweepGradient(
    ui.Offset center,
    List<ui.Color> colors, [
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    double startAngle = 0.0,
    double endAngle = math.pi * 2,
    Float32List? matrix4,
  ]);

  ui.ImageFilter createBlurImageFilter({
    double sigmaX = 0.0,
    double sigmaY = 0.0,
    ui.TileMode? tileMode,
  });
  ui.ImageFilter createDilateImageFilter({double radiusX = 0.0, double radiusY = 0.0});
  ui.ImageFilter createErodeImageFilter({double radiusX = 0.0, double radiusY = 0.0});
  ui.ImageFilter createMatrixImageFilter(
    Float64List matrix4, {
    ui.FilterQuality filterQuality = ui.FilterQuality.low,
  });
  ui.ImageFilter composeImageFilters({
    required ui.ImageFilter outer,
    required ui.ImageFilter inner,
  });

  Future<ui.Codec> instantiateImageCodec(
    Uint8List list, {
    int? targetWidth,
    int? targetHeight,
    bool allowUpscaling = true,
  });

  Future<ui.Codec> instantiateImageCodecFromUrl(
    Uri uri, {
    ui_web.ImageCodecChunkCallback? chunkCallback,
  });

  FutureOr<ui.Image> createImageFromImageBitmap(DomImageBitmap imageSource);

  FutureOr<ui.Image> createImageFromTextureSource(
    JSAny object, {
    required int width,
    required int height,
    required bool transferOwnership,
  });

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
  });

  ui.ImageShader createImageShader(
    ui.Image image,
    ui.TileMode tmx,
    ui.TileMode tmy,
    Float64List matrix4,
    ui.FilterQuality? filterQuality,
  );

  void clearFragmentProgramCache();
  Future<ui.FragmentProgram> createFragmentProgram(String assetKey);

  ui.Path createPath();
  ui.Path copyPath(ui.Path src);
  ui.Path combinePaths(ui.PathOperation op, ui.Path path1, ui.Path path2);

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
  });

  ui.TextStyle createTextStyle({
    required ui.Color? color,
    required ui.TextDecoration? decoration,
    required ui.Color? decorationColor,
    required ui.TextDecorationStyle? decorationStyle,
    required double? decorationThickness,
    required ui.FontWeight? fontWeight,
    required ui.FontStyle? fontStyle,
    required ui.TextBaseline? textBaseline,
    required String? fontFamily,
    required List<String>? fontFamilyFallback,
    required double? fontSize,
    required double? letterSpacing,
    required double? wordSpacing,
    required double? height,
    required ui.TextLeadingDistribution? leadingDistribution,
    required ui.Locale? locale,
    required ui.Paint? background,
    required ui.Paint? foreground,
    required List<ui.Shadow>? shadows,
    required List<ui.FontFeature>? fontFeatures,
    required List<ui.FontVariation>? fontVariations,
  });

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
  });

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
  });

  ui.ParagraphBuilder createParagraphBuilder(ui.ParagraphStyle style);

  /// Map from view id to the associated [ViewRasterizer] for that view.
  final Map<int, ViewRasterizer> rasterizers = <int, ViewRasterizer>{};

  Future<void> renderScene(ui.Scene scene, EngineFlutterView view) async {
    assert(
      rasterizers.containsKey(view.viewId),
      "Unable to render to a view which hasn't been registered",
    );
    final ViewRasterizer rasterizer = rasterizers[view.viewId]!;
    final RenderQueue renderQueue = rasterizer.queue;
    final FrameTimingRecorder? recorder = FrameTimingRecorder.frameTimingsEnabled
        ? FrameTimingRecorder()
        : null;
    if (renderQueue.current != null) {
      // If a scene is already queued up, drop it and queue this one up instead
      // so that the scene view always displays the most recently requested scene.
      renderQueue.next?.completer.complete();
      final Completer<void> completer = Completer<void>();
      renderQueue.next = (scene: scene, completer: completer, recorder: recorder);
      return completer.future;
    }
    final Completer<void> completer = Completer<void>();
    renderQueue.current = (scene: scene, completer: completer, recorder: recorder);
    unawaited(_kickRenderLoop(rasterizer));
    return completer.future;
  }

  Future<void> _kickRenderLoop(ViewRasterizer rasterizer) async {
    final RenderQueue renderQueue = rasterizer.queue;
    final RenderRequest current = renderQueue.current!;
    try {
      await _renderScene(current.scene, rasterizer, current.recorder);
      current.completer.complete();
    } catch (error, stackTrace) {
      current.completer.completeError(error, stackTrace);
    }
    renderQueue.current = renderQueue.next;
    renderQueue.next = null;
    if (renderQueue.current == null) {
      return;
    } else {
      return _kickRenderLoop(rasterizer);
    }
  }

  Future<void> _renderScene(
    ui.Scene scene,
    ViewRasterizer rasterizer,
    FrameTimingRecorder? recorder,
  ) async {
    await rasterizer.draw((scene as LayerScene).layerTree, recorder);
    recorder?.submitTimings();
  }

  void dumpDebugInfo();

  /// Disposes this renderer.
  @mustCallSuper
  void dispose() {
    _onViewCreatedListener.cancel();
    _onViewDisposedListener.cancel();
    for (final ViewRasterizer rasterizer in rasterizers.values) {
      rasterizer.dispose();
    }
    rasterizers.clear();
    rasterizer.dispose();
  }

  /// Clears the state of this renderer. Used in tests.
  @mustCallSuper
  void debugClear() {
    for (final ViewRasterizer rasterizer in rasterizers.values) {
      rasterizer.debugClear();
    }
  }
}
