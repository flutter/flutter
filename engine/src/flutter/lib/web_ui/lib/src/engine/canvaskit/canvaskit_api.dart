// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Bindings for CanvasKit JavaScript API.
///
/// Prefer keeping the original CanvasKit names so it is easier to locate
/// the API behind these bindings in the Skia source code.
// ignore_for_file: non_constant_identifier_names
@JS()
library canvaskit_api;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// Entrypoint into the CanvasKit API.
late CanvasKit canvasKit;

bool get _enableCanvasKitChromiumInAutoMode => browserSupportsCanvaskitChromium;

/// Sets the [CanvasKit] object on `window` so we can use `@JS()` to bind to
/// static APIs.
///
/// See, e.g. [SkPaint].
///
/// This also acts as a cache of an initialized CanvasKit instance. We can use
/// this, for example, to perform a hot restart without needing to redownload
/// and reinitialize CanvasKit.
@JS('window.flutterCanvasKit')
external set windowFlutterCanvasKit(CanvasKit? value);

@JS('window.flutterCanvasKit')
external CanvasKit? get windowFlutterCanvasKit;

@JS('window.flutterCanvasKitLoaded')
external JSPromise<CanvasKit>? get windowFlutterCanvasKitLoaded;

extension type CanvasKit(JSObject _) implements JSObject {
  external SkBlendModeEnum get BlendMode;
  external SkPaintStyleEnum get PaintStyle;
  external SkStrokeCapEnum get StrokeCap;
  external SkStrokeJoinEnum get StrokeJoin;
  external SkBlurStyleEnum get BlurStyle;
  external SkTileModeEnum get TileMode;
  external SkFilterModeEnum get FilterMode;
  external SkMipmapModeEnum get MipmapMode;
  external SkFillTypeEnum get FillType;
  external SkAlphaTypeEnum get AlphaType;
  external SkColorTypeEnum get ColorType;
  external SkPathOpEnum get PathOp;
  external SkClipOpEnum get ClipOp;
  external SkPointModeEnum get PointMode;
  external SkVertexModeEnum get VertexMode;
  external SkRectHeightStyleEnum get RectHeightStyle;
  external SkRectWidthStyleEnum get RectWidthStyle;
  external SkAffinityEnum get Affinity;
  external SkTextAlignEnum get TextAlign;
  external SkTextHeightBehaviorEnum get TextHeightBehavior;
  external SkTextDirectionEnum get TextDirection;
  external SkFontWeightEnum get FontWeight;
  external SkFontSlantEnum get FontSlant;

  @JS('MakeAnimatedImageFromEncoded')
  external SkAnimatedImage? _MakeAnimatedImageFromEncoded(JSUint8Array imageData);
  SkAnimatedImage? MakeAnimatedImageFromEncoded(Uint8List imageData) =>
      _MakeAnimatedImageFromEncoded(imageData.toJS);

  external SkShaderNamespace get Shader;
  external SkMaskFilterNamespace get MaskFilter;
  external SkColorFilterNamespace get ColorFilter;
  external SkImageFilterNamespace get ImageFilter;
  external SkPathNamespace get Path;
  external SkTonalColors computeTonalColors(SkTonalColors inTonalColors);

  @JS('MakeVertices')
  external SkVertices _MakeVertices(
    SkVertexMode mode,
    JSFloat32Array positions,
    JSFloat32Array? textureCoordinates,
    JSUint32Array? colors,
    JSUint16Array? indices,
  );
  SkVertices MakeVertices(
    SkVertexMode mode,
    Float32List positions,
    Float32List? textureCoordinates,
    Uint32List? colors,
    Uint16List? indices,
  ) => _MakeVertices(mode, positions.toJS, textureCoordinates?.toJS, colors?.toJS, indices?.toJS);

  external BidiNamespace get Bidi;

  external CodeUnitsNamespace get CodeUnits;

  external SkParagraphBuilderNamespace get ParagraphBuilder;
  external SkParagraphStyle ParagraphStyle(SkParagraphStyleProperties properties);
  external SkTextStyle TextStyle(SkTextStyleProperties properties);
  external SkSurface MakeWebGLCanvasSurface(DomHTMLCanvasElement canvas);
  external SkSurface MakeSurface(double width, double height);

  @JS('getDataBytes')
  external JSUint8Array _getDataBytes(SkData skData);
  Uint8List getDataBytes(SkData skData) => _getDataBytes(skData).toDart;

  // Text decoration enum is embedded in the CanvasKit object itself.
  external double get NoDecoration;
  external double get UnderlineDecoration;
  external double get OverlineDecoration;
  external double get LineThroughDecoration;
  // End of text decoration enum.

  external SkTextDecorationStyleEnum get DecorationStyle;
  external SkTextBaselineEnum get TextBaseline;
  external SkPlaceholderAlignmentEnum get PlaceholderAlignment;

  external SkFontMgrNamespace get FontMgr;
  external TypefaceFontProviderNamespace get TypefaceFontProvider;
  external FontCollectionNamespace get FontCollection;
  external SkTypefaceFactory get Typeface;

  external double GetWebGLContext(DomHTMLCanvasElement canvas, SkWebGLContextOptions options);
  @JS('GetWebGLContext')
  external double GetOffscreenWebGLContext(
    DomOffscreenCanvas canvas,
    SkWebGLContextOptions options,
  );
  external SkGrContext? MakeGrContext(double glContext);
  external SkSurface? MakeOnScreenGLSurface(
    SkGrContext grContext,
    double width,
    double height,
    ColorSpace colorSpace,
    int sampleCount,
    int stencil,
  );

  external SkSurface? MakeRenderTarget(SkGrContext grContext, int width, int height);

  external SkSurface MakeSWCanvasSurface(DomHTMLCanvasElement canvas);

  @JS('MakeSWCanvasSurface')
  external SkSurface MakeOffscreenSWCanvasSurface(DomOffscreenCanvas canvas);

  /// Creates an image from decoded pixels represented as a list of bytes.
  ///
  /// The pixel data must be encoded according to the image info in [info].
  ///
  /// Typically pixel data is obtained using [SkImage.readPixels]. The
  /// parameters specified in [SkImageInfo] passed [SkImage.readPixels] must
  /// match [info].
  @JS('MakeImage')
  external SkImage? _MakeImage(SkImageInfo info, JSUint8Array pixels, double bytesPerRow);
  SkImage? MakeImage(SkImageInfo info, Uint8List pixels, double bytesPerRow) =>
      _MakeImage(info, pixels.toJS, bytesPerRow);

  @JS('MakeLazyImageFromTextureSource')
  external SkImage? _MakeLazyImageFromTextureSource2(JSAny src, SkPartialImageInfo info);

  @JS('MakeLazyImageFromTextureSource')
  external SkImage? _MakeLazyImageFromTextureSource3(
    JSAny src,
    int zeroSecondArgument,
    bool srcIsPremultiplied,
  );

  SkImage? MakeLazyImageFromTextureSourceWithInfo(Object src, SkPartialImageInfo info) {
    assert(
      !CanvasKitRenderer.instance.isSoftware,
      'Cannot use `MakeLazyImageFromTextureSourceWithInfo` in CPU-only mode.',
    );
    return _MakeLazyImageFromTextureSource2(src.toJSAnyShallow, info);
  }

  SkImage? MakeLazyImageFromImageBitmap(DomImageBitmap imageBitmap, bool hasPremultipliedAlpha) {
    assert(
      !CanvasKitRenderer.instance.isSoftware,
      'Cannot use `MakeLazyImageFromImageBitmap` in CPU-only mode.',
    );
    return _MakeLazyImageFromTextureSource3(imageBitmap, 0, hasPremultipliedAlpha);
  }

  external SkImage? MakeImageFromCanvasImageSource(JSAny src);
}

extension type CanvasKitModule(JSObject _) implements JSObject {
  @JS('default')
  external JSPromise<JSAny> defaultExport(CanvasKitInitOptions options);
}

typedef LocateFileCallback = String Function(String file, String unusedBase);

JSFunction createLocateFileCallback(LocateFileCallback callback) => callback.toJS;

extension type CanvasKitInitOptions._(JSObject _) implements JSObject {
  external CanvasKitInitOptions({required JSFunction locateFile});
}

@JS('window.flutterCanvasKit.ColorSpace.SRGB')
external ColorSpace get SkColorSpaceSRGB;

extension type ColorSpace(JSObject _) implements JSObject {}

extension type SkWebGLContextOptions._(JSObject _) implements JSObject {
  external factory SkWebGLContextOptions({
    required double antialias,
    // WebGL version: 1 or 2.
    required double majorVersion,
  });
}

@JS('window.flutterCanvasKit.Surface')
extension type SkSurface(JSObject _) implements JSObject {
  external SkCanvas getCanvas();
  external void flush();
  external double width();
  external double height();
  external void dispose();
  external SkImage makeImageSnapshot();
}

extension type SkGrContext(JSObject _) implements JSObject {
  external void setResourceCacheLimitBytes(double limit);
  external void releaseResourcesAndAbandonContext();
  external void delete();
}

extension type SkFontSlantEnum(JSObject _) implements JSObject {
  external SkFontSlant get Upright;
  external SkFontSlant get Italic;
}

@JS('window.flutterCanvasKit.FontSlant')
extension type SkFontSlant(JSObject _) implements JSObject {
  external double get value;
}

final List<SkFontSlant> _skFontSlants = <SkFontSlant>[
  canvasKit.FontSlant.Upright,
  canvasKit.FontSlant.Italic,
];

SkFontSlant toSkFontSlant(ui.FontStyle style) {
  return _skFontSlants[style.index];
}

extension type SkFontWeightEnum(JSObject _) implements JSObject {
  external SkFontWeight get Thin;
  external SkFontWeight get ExtraLight;
  external SkFontWeight get Light;
  external SkFontWeight get Normal;
  external SkFontWeight get Medium;
  external SkFontWeight get SemiBold;
  external SkFontWeight get Bold;
  external SkFontWeight get ExtraBold;
  external SkFontWeight get ExtraBlack;
}

extension type SkFontWeight(JSObject _) implements JSObject {
  external double get value;
}

final List<SkFontWeight> _skFontWeights = <SkFontWeight>[
  canvasKit.FontWeight.Thin,
  canvasKit.FontWeight.ExtraLight,
  canvasKit.FontWeight.Light,
  canvasKit.FontWeight.Normal,
  canvasKit.FontWeight.Medium,
  canvasKit.FontWeight.SemiBold,
  canvasKit.FontWeight.Bold,
  canvasKit.FontWeight.ExtraBold,
  canvasKit.FontWeight.ExtraBlack,
];

SkFontWeight toSkFontWeight(ui.FontWeight weight) {
  return _skFontWeights[weight.index];
}

extension type SkAffinityEnum(JSObject _) implements JSObject {
  external SkAffinity get Upstream;
  external SkAffinity get Downstream;
}

extension type SkAffinity(JSObject _) implements JSObject {
  external double get value;
}

final List<SkAffinity> _skAffinitys = <SkAffinity>[
  canvasKit.Affinity.Upstream,
  canvasKit.Affinity.Downstream,
];

SkAffinity toSkAffinity(ui.TextAffinity affinity) {
  return _skAffinitys[affinity.index];
}

extension type SkTextDirectionEnum(JSObject _) implements JSObject {
  external SkTextDirection get RTL;
  external SkTextDirection get LTR;
}

extension type SkTextDirection(JSObject _) implements JSObject {
  external double get value;
}

// Flutter enumerates text directions as RTL, LTR, while CanvasKit
// enumerates them LTR, RTL.
final List<SkTextDirection> _skTextDirections = <SkTextDirection>[
  canvasKit.TextDirection.RTL,
  canvasKit.TextDirection.LTR,
];

SkTextDirection toSkTextDirection(ui.TextDirection direction) {
  return _skTextDirections[direction.index];
}

extension type SkTextAlignEnum(JSObject _) implements JSObject {
  external SkTextAlign get Left;
  external SkTextAlign get Right;
  external SkTextAlign get Center;
  external SkTextAlign get Justify;
  external SkTextAlign get Start;
  external SkTextAlign get End;
}

extension type SkTextAlign(JSObject _) implements JSObject {
  external double get value;
}

final List<SkTextAlign> _skTextAligns = <SkTextAlign>[
  canvasKit.TextAlign.Left,
  canvasKit.TextAlign.Right,
  canvasKit.TextAlign.Center,
  canvasKit.TextAlign.Justify,
  canvasKit.TextAlign.Start,
  canvasKit.TextAlign.End,
];

SkTextAlign toSkTextAlign(ui.TextAlign align) {
  return _skTextAligns[align.index];
}

extension type SkTextHeightBehaviorEnum(JSObject _) implements JSObject {
  external SkTextHeightBehavior get All;
  external SkTextHeightBehavior get DisableFirstAscent;
  external SkTextHeightBehavior get DisableLastDescent;
  external SkTextHeightBehavior get DisableAll;
}

extension type SkTextHeightBehavior(JSObject _) implements JSObject {
  external double get value;
}

final List<SkTextHeightBehavior> _skTextHeightBehaviors = <SkTextHeightBehavior>[
  canvasKit.TextHeightBehavior.All,
  canvasKit.TextHeightBehavior.DisableFirstAscent,
  canvasKit.TextHeightBehavior.DisableLastDescent,
  canvasKit.TextHeightBehavior.DisableAll,
];

SkTextHeightBehavior toSkTextHeightBehavior(ui.TextHeightBehavior behavior) {
  final int index =
      (behavior.applyHeightToFirstAscent ? 0 : 1 << 0) |
      (behavior.applyHeightToLastDescent ? 0 : 1 << 1);
  return _skTextHeightBehaviors[index];
}

extension type SkRectHeightStyleEnum(JSObject _) implements JSObject {
  external SkRectHeightStyle get Tight;
  external SkRectHeightStyle get Max;
  external SkRectHeightStyle get IncludeLineSpacingMiddle;
  external SkRectHeightStyle get IncludeLineSpacingTop;
  external SkRectHeightStyle get IncludeLineSpacingBottom;
  external SkRectHeightStyle get Strut;
}

extension type SkRectHeightStyle(JSObject _) implements JSObject {
  external double get value;
}

final List<SkRectHeightStyle> _skRectHeightStyles = <SkRectHeightStyle>[
  canvasKit.RectHeightStyle.Tight,
  canvasKit.RectHeightStyle.Max,
  canvasKit.RectHeightStyle.IncludeLineSpacingMiddle,
  canvasKit.RectHeightStyle.IncludeLineSpacingTop,
  canvasKit.RectHeightStyle.IncludeLineSpacingBottom,
  canvasKit.RectHeightStyle.Strut,
];

SkRectHeightStyle toSkRectHeightStyle(ui.BoxHeightStyle style) {
  return _skRectHeightStyles[style.index];
}

extension type SkRectWidthStyleEnum(JSObject _) implements JSObject {
  external SkRectWidthStyle get Tight;
  external SkRectWidthStyle get Max;
}

extension type SkRectWidthStyle(JSObject _) implements JSObject {
  external double get value;
}

final List<SkRectWidthStyle> _skRectWidthStyles = <SkRectWidthStyle>[
  canvasKit.RectWidthStyle.Tight,
  canvasKit.RectWidthStyle.Max,
];

SkRectWidthStyle toSkRectWidthStyle(ui.BoxWidthStyle style) {
  final int index = style.index;
  return _skRectWidthStyles[index < 2 ? index : 0];
}

extension type SkVertexModeEnum(JSObject _) implements JSObject {
  external SkVertexMode get Triangles;
  external SkVertexMode get TrianglesStrip;
  external SkVertexMode get TriangleFan;
}

extension type SkVertexMode(JSObject _) implements JSObject {
  external double get value;
}

final List<SkVertexMode> _skVertexModes = <SkVertexMode>[
  canvasKit.VertexMode.Triangles,
  canvasKit.VertexMode.TrianglesStrip,
  canvasKit.VertexMode.TriangleFan,
];

SkVertexMode toSkVertexMode(ui.VertexMode mode) {
  return _skVertexModes[mode.index];
}

extension type SkPointModeEnum(JSObject _) implements JSObject {
  external SkPointMode get Points;
  external SkPointMode get Lines;
  external SkPointMode get Polygon;
}

extension type SkPointMode(JSObject _) implements JSObject {
  external double get value;
}

final List<SkPointMode> _skPointModes = <SkPointMode>[
  canvasKit.PointMode.Points,
  canvasKit.PointMode.Lines,
  canvasKit.PointMode.Polygon,
];

SkPointMode toSkPointMode(ui.PointMode mode) {
  return _skPointModes[mode.index];
}

extension type SkClipOpEnum(JSObject _) implements JSObject {
  external SkClipOp get Difference;
  external SkClipOp get Intersect;
}

extension type SkClipOp(JSObject _) implements JSObject {
  external double get value;
}

final List<SkClipOp> _skClipOps = <SkClipOp>[
  canvasKit.ClipOp.Difference,
  canvasKit.ClipOp.Intersect,
];

SkClipOp toSkClipOp(ui.ClipOp clipOp) {
  return _skClipOps[clipOp.index];
}

extension type SkFillTypeEnum(JSObject _) implements JSObject {
  external SkFillType get Winding;
  external SkFillType get EvenOdd;
}

extension type SkFillType(JSObject _) implements JSObject {
  external double get value;
}

final List<SkFillType> _skFillTypes = <SkFillType>[
  canvasKit.FillType.Winding,
  canvasKit.FillType.EvenOdd,
];

SkFillType toSkFillType(ui.PathFillType fillType) {
  return _skFillTypes[fillType.index];
}

extension type SkPathOpEnum(JSObject _) implements JSObject {
  external SkPathOp get Difference;
  external SkPathOp get Intersect;
  external SkPathOp get Union;
  external SkPathOp get XOR;
  external SkPathOp get ReverseDifference;
}

extension type SkPathOp(JSObject _) implements JSObject {
  external double get value;
}

final List<SkPathOp> _skPathOps = <SkPathOp>[
  canvasKit.PathOp.Difference,
  canvasKit.PathOp.Intersect,
  canvasKit.PathOp.Union,
  canvasKit.PathOp.XOR,
  canvasKit.PathOp.ReverseDifference,
];

SkPathOp toSkPathOp(ui.PathOperation pathOp) {
  return _skPathOps[pathOp.index];
}

extension type SkBlurStyleEnum(JSObject _) implements JSObject {
  external SkBlurStyle get Normal;
  external SkBlurStyle get Solid;
  external SkBlurStyle get Outer;
  external SkBlurStyle get Inner;
}

extension type SkBlurStyle(JSObject _) implements JSObject {
  external double get value;
}

final List<SkBlurStyle> _skBlurStyles = <SkBlurStyle>[
  canvasKit.BlurStyle.Normal,
  canvasKit.BlurStyle.Solid,
  canvasKit.BlurStyle.Outer,
  canvasKit.BlurStyle.Inner,
];

SkBlurStyle toSkBlurStyle(ui.BlurStyle style) {
  return _skBlurStyles[style.index];
}

extension type SkStrokeCapEnum(JSObject _) implements JSObject {
  external SkStrokeCap get Butt;
  external SkStrokeCap get Round;
  external SkStrokeCap get Square;
}

extension type SkStrokeCap(JSObject _) implements JSObject {
  external double get value;
}

final List<SkStrokeCap> _skStrokeCaps = <SkStrokeCap>[
  canvasKit.StrokeCap.Butt,
  canvasKit.StrokeCap.Round,
  canvasKit.StrokeCap.Square,
];

SkStrokeCap toSkStrokeCap(ui.StrokeCap strokeCap) {
  return _skStrokeCaps[strokeCap.index];
}

extension type SkPaintStyleEnum(JSObject _) implements JSObject {
  external SkPaintStyle get Stroke;
  external SkPaintStyle get Fill;
}

extension type SkPaintStyle(JSObject _) implements JSObject {
  external double get value;
}

final List<SkPaintStyle> _skPaintStyles = <SkPaintStyle>[
  canvasKit.PaintStyle.Fill,
  canvasKit.PaintStyle.Stroke,
];

SkPaintStyle toSkPaintStyle(ui.PaintingStyle paintStyle) {
  return _skPaintStyles[paintStyle.index];
}

extension type SkBlendModeEnum(JSObject _) implements JSObject {
  external SkBlendMode get Clear;
  external SkBlendMode get Src;
  external SkBlendMode get Dst;
  external SkBlendMode get SrcOver;
  external SkBlendMode get DstOver;
  external SkBlendMode get SrcIn;
  external SkBlendMode get DstIn;
  external SkBlendMode get SrcOut;
  external SkBlendMode get DstOut;
  external SkBlendMode get SrcATop;
  external SkBlendMode get DstATop;
  external SkBlendMode get Xor;
  external SkBlendMode get Plus;
  external SkBlendMode get Modulate;
  external SkBlendMode get Screen;
  external SkBlendMode get Overlay;
  external SkBlendMode get Darken;
  external SkBlendMode get Lighten;
  external SkBlendMode get ColorDodge;
  external SkBlendMode get ColorBurn;
  external SkBlendMode get HardLight;
  external SkBlendMode get SoftLight;
  external SkBlendMode get Difference;
  external SkBlendMode get Exclusion;
  external SkBlendMode get Multiply;
  external SkBlendMode get Hue;
  external SkBlendMode get Saturation;
  external SkBlendMode get Color;
  external SkBlendMode get Luminosity;
}

extension type SkBlendMode(JSObject _) implements JSObject {
  external double get value;
}

final List<SkBlendMode> _skBlendModes = <SkBlendMode>[
  canvasKit.BlendMode.Clear,
  canvasKit.BlendMode.Src,
  canvasKit.BlendMode.Dst,
  canvasKit.BlendMode.SrcOver,
  canvasKit.BlendMode.DstOver,
  canvasKit.BlendMode.SrcIn,
  canvasKit.BlendMode.DstIn,
  canvasKit.BlendMode.SrcOut,
  canvasKit.BlendMode.DstOut,
  canvasKit.BlendMode.SrcATop,
  canvasKit.BlendMode.DstATop,
  canvasKit.BlendMode.Xor,
  canvasKit.BlendMode.Plus,
  canvasKit.BlendMode.Modulate,
  canvasKit.BlendMode.Screen,
  canvasKit.BlendMode.Overlay,
  canvasKit.BlendMode.Darken,
  canvasKit.BlendMode.Lighten,
  canvasKit.BlendMode.ColorDodge,
  canvasKit.BlendMode.ColorBurn,
  canvasKit.BlendMode.HardLight,
  canvasKit.BlendMode.SoftLight,
  canvasKit.BlendMode.Difference,
  canvasKit.BlendMode.Exclusion,
  canvasKit.BlendMode.Multiply,
  canvasKit.BlendMode.Hue,
  canvasKit.BlendMode.Saturation,
  canvasKit.BlendMode.Color,
  canvasKit.BlendMode.Luminosity,
];

SkBlendMode toSkBlendMode(ui.BlendMode blendMode) {
  return _skBlendModes[blendMode.index];
}

extension type SkStrokeJoinEnum(JSObject _) implements JSObject {
  external SkStrokeJoin get Miter;
  external SkStrokeJoin get Round;
  external SkStrokeJoin get Bevel;
}

extension type SkStrokeJoin(JSObject _) implements JSObject {
  external double get value;
}

final List<SkStrokeJoin> _skStrokeJoins = <SkStrokeJoin>[
  canvasKit.StrokeJoin.Miter,
  canvasKit.StrokeJoin.Round,
  canvasKit.StrokeJoin.Bevel,
];

SkStrokeJoin toSkStrokeJoin(ui.StrokeJoin strokeJoin) {
  return _skStrokeJoins[strokeJoin.index];
}

extension type SkTileModeEnum(JSObject _) implements JSObject {
  external SkTileMode get Clamp;
  external SkTileMode get Repeat;
  external SkTileMode get Mirror;
  external SkTileMode get Decal;
}

extension type SkTileMode(JSObject _) implements JSObject {
  external double get value;
}

final List<SkTileMode> _skTileModes = <SkTileMode>[
  canvasKit.TileMode.Clamp,
  canvasKit.TileMode.Repeat,
  canvasKit.TileMode.Mirror,
  canvasKit.TileMode.Decal,
];

SkTileMode toSkTileMode(ui.TileMode? mode) {
  return mode == null ? canvasKit.TileMode.Clamp : _skTileModes[mode.index];
}

extension type SkFilterModeEnum(JSObject _) implements JSObject {
  external SkFilterMode get Nearest;
  external SkFilterMode get Linear;
}

extension type SkFilterMode(JSObject _) implements JSObject {
  external double get value;
}

SkFilterMode toSkFilterMode(ui.FilterQuality filterQuality) {
  return filterQuality == ui.FilterQuality.none
      ? canvasKit.FilterMode.Nearest
      : canvasKit.FilterMode.Linear;
}

extension type SkMipmapModeEnum(JSObject _) implements JSObject {
  external SkMipmapMode get None;
  external SkMipmapMode get Nearest;
  external SkMipmapMode get Linear;
}

extension type SkMipmapMode(JSObject _) implements JSObject {
  external double get value;
}

SkMipmapMode toSkMipmapMode(ui.FilterQuality filterQuality) {
  return filterQuality == ui.FilterQuality.medium
      ? canvasKit.MipmapMode.Linear
      : canvasKit.MipmapMode.None;
}

extension type SkAlphaTypeEnum(JSObject _) implements JSObject {
  external SkAlphaType get Opaque;
  external SkAlphaType get Premul;
  external SkAlphaType get Unpremul;
}

extension type SkAlphaType(JSObject _) implements JSObject {
  external double get value;
}

extension type SkColorTypeEnum(JSObject _) implements JSObject {
  external SkColorType get Alpha_8;
  external SkColorType get RGB_565;
  external SkColorType get ARGB_4444;
  external SkColorType get RGBA_8888;
  external SkColorType get RGB_888x;
  external SkColorType get BGRA_8888;
  external SkColorType get RGBA_1010102;
  external SkColorType get RGB_101010x;
  external SkColorType get Gray_8;
  external SkColorType get RGBA_F16;
  external SkColorType get RGBA_F32;
}

extension type SkColorType(JSObject _) implements JSObject {
  external double get value;
}

extension type SkAnimatedImage(JSObject _) implements JSObject {
  external double getFrameCount();

  external double getRepetitionCount();

  /// Returns duration in milliseconds.
  external double currentFrameDuration();

  /// Advances to the next frame and returns its duration in milliseconds.
  external double decodeNextFrame();

  external SkImage makeImageAtCurrentFrame();

  external double width();

  external double height();

  /// Deletes the C++ object.
  ///
  /// This object is no longer usable after calling this method.
  external void delete();

  external bool isDeleted();
}

extension type SkImage(JSObject _) implements JSObject {
  external void delete();

  external double width();

  external double height();

  @JS('makeShaderCubic')
  external SkShader _makeShaderCubic(
    SkTileMode tileModeX,
    SkTileMode tileModeY,
    double B,
    double C,
    JSFloat32Array? matrix, // 3x3 matrix
  );
  SkShader makeShaderCubic(
    SkTileMode tileModeX,
    SkTileMode tileModeY,
    double B,
    double C,
    Float32List? matrix, // 3x3 matrix
  ) => _makeShaderCubic(tileModeX, tileModeY, B, C, matrix?.toJS);

  @JS('makeShaderOptions')
  external SkShader _makeShaderOptions(
    SkTileMode tileModeX,
    SkTileMode tileModeY,
    SkFilterMode filterMode,
    SkMipmapMode mipmapMode,
    JSFloat32Array? matrix, // 3x3 matrix
  );
  SkShader makeShaderOptions(
    SkTileMode tileModeX,
    SkTileMode tileModeY,
    SkFilterMode filterMode,
    SkMipmapMode mipmapMode,
    Float32List? matrix, // 3x3 matrix
  ) => _makeShaderOptions(tileModeX, tileModeY, filterMode, mipmapMode, matrix?.toJS);

  @JS('readPixels')
  external JSUint8Array? _readPixels(double srcX, double srcY, SkImageInfo imageInfo);
  Uint8List? readPixels(double srcX, double srcY, SkImageInfo imageInfo) =>
      _readPixels(srcX, srcY, imageInfo)?.toDart;

  @JS('encodeToBytes')
  external JSUint8Array? _encodeToBytes();
  Uint8List? encodeToBytes() => _encodeToBytes()?.toDart;

  external bool isAliasOf(SkImage other);

  external bool isDeleted();
}

extension type SkShaderNamespace(JSObject _) implements JSObject {
  @JS('MakeLinearGradient')
  external SkShader _MakeLinearGradient(
    JSFloat32Array from, // 2-element array
    JSFloat32Array to, // 2-element array
    JSUint32Array colors,
    JSFloat32Array colorStops,
    SkTileMode tileMode,
    JSFloat32Array? matrix,
  );
  SkShader MakeLinearGradient(
    Float32List from, // 2-element array
    Float32List to, // 2-element array
    Uint32List colors,
    Float32List colorStops,
    SkTileMode tileMode,
    Float32List? matrix,
  ) =>
      _MakeLinearGradient(from.toJS, to.toJS, colors.toJS, colorStops.toJS, tileMode, matrix?.toJS);

  @JS('MakeRadialGradient')
  external SkShader _MakeRadialGradient(
    JSFloat32Array center, // 2-element array
    double radius,
    JSUint32Array colors,
    JSFloat32Array colorStops,
    SkTileMode tileMode,
    JSFloat32Array? matrix, // 3x3 matrix
    double flags,
  );
  SkShader MakeRadialGradient(
    Float32List center, // 2-element array
    double radius,
    Uint32List colors,
    Float32List colorStops,
    SkTileMode tileMode,
    Float32List? matrix, // 3x3 matrix
    double flags,
  ) => _MakeRadialGradient(
    center.toJS,
    radius,
    colors.toJS,
    colorStops.toJS,
    tileMode,
    matrix?.toJS,
    flags,
  );

  @JS('MakeTwoPointConicalGradient')
  external SkShader _MakeTwoPointConicalGradient(
    JSFloat32Array focal,
    double focalRadius,
    JSFloat32Array center,
    double radius,
    JSUint32Array colors,
    JSFloat32Array colorStops,
    SkTileMode tileMode,
    JSFloat32Array? matrix, // 3x3 matrix
    double flags,
  );
  SkShader MakeTwoPointConicalGradient(
    Float32List focal,
    double focalRadius,
    Float32List center,
    double radius,
    Uint32List colors,
    Float32List colorStops,
    SkTileMode tileMode,
    Float32List? matrix, // 3x3 matrix
    double flags,
  ) => _MakeTwoPointConicalGradient(
    focal.toJS,
    focalRadius,
    center.toJS,
    radius,
    colors.toJS,
    colorStops.toJS,
    tileMode,
    matrix?.toJS,
    flags,
  );

  @JS('MakeSweepGradient')
  external SkShader _MakeSweepGradient(
    double cx,
    double cy,
    JSUint32Array colors,
    JSFloat32Array colorStops,
    SkTileMode tileMode,
    JSFloat32Array? matrix, // 3x3 matrix
    double flags,
    double startAngle,
    double endAngle,
  );
  SkShader MakeSweepGradient(
    double cx,
    double cy,
    Uint32List colors,
    Float32List colorStops,
    SkTileMode tileMode,
    Float32List? matrix, // 3x3 matrix
    double flags,
    double startAngle,
    double endAngle,
  ) => _MakeSweepGradient(
    cx,
    cy,
    colors.toJS,
    colorStops.toJS,
    tileMode,
    matrix?.toJS,
    flags,
    startAngle,
    endAngle,
  );
}

extension type SkShader(JSObject _) implements JSObject {
  external void delete();
}

extension type SkMaskFilterNamespace(JSObject _) implements JSObject {
  // Creates a blur MaskFilter.
  //
  // Returns `null` if [sigma] is 0 or infinite.
  external SkMaskFilter? MakeBlur(SkBlurStyle blurStyle, double sigma, bool respectCTM);
}

// This needs to be bound to top-level because SkPaint is initialized
// with `new`. Also in Dart you can't write this:
//
//     external SkPaint SkPaint();
@JS('window.flutterCanvasKit.Paint')
extension type SkPaint._(JSObject _) implements JSObject {
  external SkPaint();

  external void setBlendMode(SkBlendMode blendMode);
  external void setStyle(SkPaintStyle paintStyle);
  external void setStrokeWidth(double width);
  external void setStrokeCap(SkStrokeCap cap);
  external void setStrokeJoin(SkStrokeJoin join);
  external void setAntiAlias(bool isAntiAlias);
  external void setColorInt(int color);
  external void setShader(SkShader? shader);
  external void setDither(bool isDither);
  external void setMaskFilter(SkMaskFilter? maskFilter);
  external void setColorFilter(SkColorFilter? colorFilter);
  external void setStrokeMiter(double miterLimit);
  external void setImageFilter(SkImageFilter? imageFilter);
  external void delete();
}

extension type CkFilterOptions(JSObject _) implements JSObject {}

extension type _CkCubicFilterOptions._(JSObject _) implements CkFilterOptions {
  external _CkCubicFilterOptions({required double B, required double C});
}

extension type _CkTransformFilterOptions._(JSObject _) implements CkFilterOptions {
  external _CkTransformFilterOptions({SkFilterMode filter, SkMipmapMode mipmap});
}

final Map<ui.FilterQuality, CkFilterOptions> _filterOptions = <ui.FilterQuality, CkFilterOptions>{
  ui.FilterQuality.none: _CkTransformFilterOptions(
    filter: canvasKit.FilterMode.Nearest,
    mipmap: canvasKit.MipmapMode.None,
  ),
  ui.FilterQuality.low: _CkTransformFilterOptions(
    filter: canvasKit.FilterMode.Linear,
    mipmap: canvasKit.MipmapMode.None,
  ),
  ui.FilterQuality.medium: _CkTransformFilterOptions(
    filter: canvasKit.FilterMode.Linear,
    mipmap: canvasKit.MipmapMode.Linear,
  ),
  ui.FilterQuality.high: _CkCubicFilterOptions(B: 1.0 / 3, C: 1.0 / 3),
};

CkFilterOptions toSkFilterOptions(ui.FilterQuality filterQuality) {
  return _filterOptions[filterQuality]!;
}

extension type SkMaskFilter(JSObject _) implements JSObject {
  external void delete();
}

extension type SkColorFilterNamespace(JSObject _) implements JSObject {
  @JS('MakeBlend')
  external SkColorFilter? _MakeBlend(JSFloat32Array color, SkBlendMode blendMode);
  SkColorFilter? MakeBlend(Float32List color, SkBlendMode blendMode) =>
      _MakeBlend(color.toJS, blendMode);

  @JS('MakeMatrix')
  external SkColorFilter _MakeMatrix(
    JSFloat32Array matrix, // 20-element matrix
  );
  SkColorFilter MakeMatrix(
    Float32List matrix, // 20-element matrix
  ) => _MakeMatrix(matrix.toJS);

  external SkColorFilter MakeLinearToSRGBGamma();
  external SkColorFilter MakeSRGBToLinearGamma();
  external SkColorFilter MakeCompose(SkColorFilter? outer, SkColorFilter inner);
}

extension type SkColorFilter(JSObject _) implements JSObject {
  external void delete();
}

extension type SkImageFilterNamespace(JSObject _) implements JSObject {
  external SkImageFilter MakeBlur(
    double sigmaX,
    double sigmaY,
    SkTileMode tileMode,
    void input, // we don't use this yet
  );

  @JS('MakeMatrixTransform')
  external SkImageFilter _MakeMatrixTransform(
    JSFloat32Array matrix, // 3x3 matrix
    CkFilterOptions filterOptions,
    void input, // we don't use this yet
  );
  SkImageFilter MakeMatrixTransform(
    Float32List matrix, // 3x3 matrix
    CkFilterOptions filterOptions,
    void input, // we don't use this yet
  ) => _MakeMatrixTransform(matrix.toJS, filterOptions, input);

  external SkImageFilter MakeColorFilter(
    SkColorFilter colorFilter,
    void input, // we don't use this yet
  );

  external SkImageFilter MakeCompose(SkImageFilter outer, SkImageFilter inner);

  external SkImageFilter MakeDilate(
    double radiusX,
    double radiusY,
    void input, // we don't use this yet
  );

  external SkImageFilter MakeErode(
    double radiusX,
    double radiusY,
    void input, // we don't use this yet
  );
}

extension type SkImageFilter(JSObject _) implements JSObject {
  external void delete();

  external bool isDeleted();

  @JS('getOutputBounds')
  external JSInt32Array _getOutputBounds(JSFloat32Array bounds);
  Int32List getOutputBounds(Float32List bounds) => _getOutputBounds(bounds.toJS).toDart;
}

extension type SkPathNamespace(JSObject _) implements JSObject {
  /// Creates an [SkPath] using commands obtained from [SkPath.toCmds].
  @JS('MakeFromCmds')
  external SkPath _MakeFromCmds(JSAny pathCommands);
  SkPath MakeFromCmds(List<dynamic> pathCommands) => _MakeFromCmds(pathCommands.toJSAnyShallow);

  /// Creates an [SkPath] by combining [path1] and [path2] using [pathOp].
  external SkPath MakeFromOp(SkPath path1, SkPath path2, SkPathOp pathOp);
}

/// Converts a 4x4 Flutter matrix (represented as a [Float32List] in
/// column major order) to an SkM44 which is a 4x4 matrix represented
/// as a [Float32List] in row major order.
Float32List toSkM44FromFloat32(Float32List matrix4) {
  final skM44 = Float32List(16);
  for (var r = 0; r < 4; r++) {
    for (var c = 0; c < 4; c++) {
      skM44[c * 4 + r] = matrix4[r * 4 + c];
    }
  }
  return skM44;
}

// Mappings from SkMatrix-index to input-index.
const List<int> _skMatrixIndexToMatrix4Index = <int>[
  0, 4, 12, // Row 1
  1, 5, 13, // Row 2
  3, 7, 15, // Row 3
];

/// Converts a 4x4 Flutter matrix (represented as a [Float32List]) to an
/// SkMatrix, which is a 3x3 transform matrix.
Float32List toSkMatrixFromFloat32(Float32List matrix4) {
  final skMatrix = Float32List(9);
  for (var i = 0; i < 9; ++i) {
    final int matrix4Index = _skMatrixIndexToMatrix4Index[i];
    if (matrix4Index < matrix4.length) {
      skMatrix[i] = matrix4[matrix4Index];
    } else {
      skMatrix[i] = 0.0;
    }
  }
  return skMatrix;
}

/// Converts a 4x4 Flutter matrix (represented as a [Float32List]) to an
/// SkMatrix, which is a 3x3 transform matrix.
Float32List toSkMatrixFromFloat64(Float64List matrix4) {
  final skMatrix = Float32List(9);
  for (var i = 0; i < 9; ++i) {
    final int matrix4Index = _skMatrixIndexToMatrix4Index[i];
    if (matrix4Index < matrix4.length) {
      skMatrix[i] = matrix4[matrix4Index];
    } else {
      skMatrix[i] = 0.0;
    }
  }
  return skMatrix;
}

/// Converts an [offset] into an `[x, y]` pair stored in a `Float32List`.
///
/// The returned list can be passed to CanvasKit API that take points.
Float32List toSkPoint(ui.Offset offset) {
  final point = Float32List(2);
  point[0] = offset.dx;
  point[1] = offset.dy;
  return point;
}

/// Color stops used when the framework specifies `null`.
final Float32List _kDefaultSkColorStops = Float32List(2)
  ..[0] = 0
  ..[1] = 1;

/// Converts a list of color stops into a Skia-compatible JS array or color stops.
///
/// In Flutter `null` means two color stops `[0, 1]` that in Skia must be specified explicitly.
Float32List toSkColorStops(List<double>? colorStops) {
  if (colorStops == null) {
    return _kDefaultSkColorStops;
  }

  final int len = colorStops.length;
  final skColorStops = Float32List(len);
  for (var i = 0; i < len; i++) {
    skColorStops[i] = colorStops[i];
  }
  return skColorStops;
}

extension type _NativeType(JSObject _) implements JSObject {}

@JS('Float32Array')
external _NativeType get _nativeFloat32ArrayType;

@JS('Uint32Array')
external _NativeType get _nativeUint32ArrayType;

@JS('window.flutterCanvasKit.Malloc')
external JSAny _malloc(_NativeType nativeType, int length);

/// Allocates a [Float32List] of [length] elements, backed by WASM memory,
/// managed by a [SkFloat32List].
///
/// To free the allocated array use [free].
SkFloat32List mallocFloat32List(int length) {
  return _malloc(_nativeFloat32ArrayType, length) as SkFloat32List;
}

/// Allocates a [Uint32List] of [length] elements, backed by WASM memory,
/// managed by a [SkUint32List].
///
/// To free the allocated array use [free].
SkUint32List mallocUint32List(int length) {
  return _malloc(_nativeUint32ArrayType, length) as SkUint32List;
}

/// Frees the WASM memory occupied by a [SkFloat32List] or [SkUint32List].
///
/// The [list] is no longer usable after calling this function.
///
/// Use this function to free lists owned by the engine.
@JS('window.flutterCanvasKit.Free')
external void free(MallocObj list);

extension type MallocObj(JSObject _) implements JSObject {}

/// Wraps a [Float32List] backed by WASM memory.
///
/// This wrapper is necessary because the raw [Float32List] will get detached
/// when WASM grows its memory. Call [toTypedArray] to get a new instance
/// that's attached to the current WASM memory block.
extension type SkFloat32List(JSObject _) implements MallocObj {
  /// The number of objects this pointer refers to.
  external double length;

  /// Returns the [Float32List] object backed by WASM memory.
  ///
  /// Do not reuse the returned array across multiple WASM function/method
  /// invocations that may lead to WASM memory to grow. When WASM memory
  /// grows, the returned [Float32List] object becomes "detached" and is no
  /// longer usable. Instead, call this method every time you need to read from
  /// or write to the list.
  @JS('toTypedArray')
  external JSFloat32Array _toTypedArray();
  Float32List toTypedArray() => _toTypedArray().toDart;
}

/// Wraps a [Uint32List] backed by WASM memory.
///
/// This wrapper is necessary because the raw [Uint32List] will get detached
/// when WASM grows its memory. Call [toTypedArray] to get a new instance
/// that's attached to the current WASM memory block.
extension type SkUint32List(JSObject _) implements MallocObj {
  /// The number of objects this pointer refers to.
  external double length;

  /// Returns the [Uint32List] object backed by WASM memory.
  ///
  /// Do not reuse the returned array across multiple WASM function/method
  /// invocations that may lead to WASM memory to grow. When WASM memory
  /// grows, the returned [Uint32List] object becomes "detached" and is no
  /// longer usable. Instead, call this method every time you need to read from
  /// or write to the list.
  @JS('toTypedArray')
  external JSUint32Array _toTypedArray();
  Uint32List toTypedArray() => _toTypedArray().toDart;
}

/// Writes [color] information into the given [skColor] buffer.
Float32List _populateSkColor(SkFloat32List skColor, ui.Color color) {
  final Float32List array = skColor.toTypedArray();
  array[0] = color.red / 255.0;
  array[1] = color.green / 255.0;
  array[2] = color.blue / 255.0;
  array[3] = color.alpha / 255.0;
  return array;
}

/// Unpacks the [color] into CanvasKit-compatible representation stored
/// in a shared memory location #1.
///
/// Use this only for passing transient data to CanvasKit. Because the
/// memory is shared the value will not persist.
Float32List toSharedSkColor1(ui.Color color) {
  return _populateSkColor(_sharedSkColor1, color);
}

final SkFloat32List _sharedSkColor1 = mallocFloat32List(4);

/// Unpacks the [color] into CanvasKit-compatible representation stored
/// in a shared memory location #2.
///
/// Use this only for passing transient data to CanvasKit. Because the
/// memory is shared the value will not persist.
Float32List toSharedSkColor2(ui.Color color) {
  return _populateSkColor(_sharedSkColor2, color);
}

final SkFloat32List _sharedSkColor2 = mallocFloat32List(4);

/// Unpacks the [color] into CanvasKit-compatible representation stored
/// in a shared memory location #3.
///
/// Use this only for passing transient data to CanvasKit. Because the
/// memory is shared the value will not persist.
Float32List toSharedSkColor3(ui.Color color) {
  return _populateSkColor(_sharedSkColor3, color);
}

final SkFloat32List _sharedSkColor3 = mallocFloat32List(4);

@JS('window.flutterCanvasKit.Path')
extension type SkPath._(JSObject _) implements JSObject {
  external void setFillType(SkFillType fillType);

  @JS('getBounds')
  external JSFloat32Array _getBounds();
  Float32List getBounds() => _getBounds().toDart;

  external bool contains(double x, double y);

  external String toSVGString();
  external bool isEmpty();
  external SkPath copy();

  /// Serializes the path into a list of commands.
  ///
  /// The list can be used to create a new [SkPath] using
  /// [CanvasKit.Path.MakeFromCmds].
  @JS('toCmds')
  external JSAny _toCmds();
  List<dynamic> toCmds() => _toCmds().toObjectShallow as List<dynamic>;

  external void delete();
}

@JS('window.flutterCanvasKit.PathBuilder')
extension type SkPathBuilder._(JSObject _) implements JSObject {
  external SkPathBuilder([SkPath skPath]);

  external void setFillType(SkFillType fillType);

  @JS('addArc')
  external void _addArc(JSFloat32Array oval, double startAngleDegrees, double sweepAngleDegrees);
  void addArc(Float32List oval, double startAngleDegrees, double sweepAngleDegrees) =>
      _addArc(oval.toJS, startAngleDegrees, sweepAngleDegrees);

  @JS('addOval')
  external void _addOval(JSFloat32Array oval, bool counterClockWise, double startIndex);
  void addOval(Float32List oval, bool counterClockWise, double startIndex) =>
      _addOval(oval.toJS, counterClockWise, startIndex);

  external void addPath(
    SkPath other,
    double scaleX,
    double skewX,
    double transX,
    double skewY,
    double scaleY,
    double transY,
    double pers0,
    double pers1,
    double pers2,
    bool extendPath,
  );

  @JS('addPolygon')
  external void _addPolygon(JSFloat32Array points, bool close);
  void addPolygon(Float32List points, bool close) => _addPolygon(points.toJS, close);

  @JS('addRRect')
  external void _addRRect(JSFloat32Array rrect, bool counterClockWise);
  void addRRect(Float32List rrect, bool counterClockWise) =>
      _addRRect(rrect.toJS, counterClockWise);

  @JS('addRect')
  external void _addRect(JSFloat32Array rect);
  void addRect(Float32List rect) => _addRect(rect.toJS);

  @JS('arcToOval')
  external void _arcToOval(
    JSFloat32Array oval,
    double startAngleDegrees,
    double sweepAngleDegrees,
    bool forceMoveTo,
  );
  void arcToOval(
    Float32List oval,
    double startAngleDegrees,
    double sweepAngleDegrees,
    bool forceMoveTo,
  ) => _arcToOval(oval.toJS, startAngleDegrees, sweepAngleDegrees, forceMoveTo);

  external void arcToRotated(
    double radiusX,
    double radiusY,
    double rotation,
    bool useSmallArc,
    bool counterClockWise,
    double x,
    double y,
  );

  external void close();
  external void conicTo(double x1, double y1, double x2, double y2, double w);
  external bool contains(double x, double y);
  external void cubicTo(double x1, double y1, double x2, double y2, double x3, double y3);

  @JS('getBounds')
  external JSFloat32Array _getBounds();
  Float32List getBounds() => _getBounds().toDart;

  external void lineTo(double x, double y);
  external void moveTo(double x, double y);
  external void quadTo(double x1, double y1, double x2, double y2);
  external void rArcTo(
    double x,
    double y,
    double rotation,
    bool useSmallArc,
    bool counterClockWise,
    double deltaX,
    double deltaY,
  );
  external void rConicTo(double x1, double y1, double x2, double y2, double w);
  external void rCubicTo(double x1, double y1, double x2, double y2, double x3, double y3);
  external void rLineTo(double x, double y);
  external void rMoveTo(double x, double y);
  external void rQuadTo(double x1, double y1, double x2, double y2);
  external void reset();

  external bool isEmpty();

  external void transform(
    double scaleX,
    double skewX,
    double transX,
    double skewY,
    double scaleY,
    double transY,
    double pers0,
    double pers1,
    double pers2,
  );

  external SkPath snapshot();

  external void delete();
}

@JS('window.flutterCanvasKit.ContourMeasureIter')
extension type SkContourMeasureIter._(JSObject _) implements JSObject {
  external SkContourMeasureIter(SkPath path, bool forceClosed, double resScale);

  external SkContourMeasure? next();
  external void delete();
}

extension type SkContourMeasure(JSObject _) implements JSObject {
  external SkPath getSegment(double start, double end, bool startWithMoveTo);

  @JS('getPosTan')
  external JSFloat32Array _getPosTan(double distance);
  Float32List getPosTan(double distance) => _getPosTan(distance).toDart;

  external bool isClosed();
  external double length();
  external void delete();
}

// TODO(hterkelsen): Use a shared malloc'ed array for performance.
Float32List toSkRect(ui.Rect rect) {
  final skRect = Float32List(4);
  skRect[0] = rect.left;
  skRect[1] = rect.top;
  skRect[2] = rect.right;
  skRect[3] = rect.bottom;
  return skRect;
}

ui.Rect fromSkRect(Float32List skRect) {
  return ui.Rect.fromLTRB(skRect[0], skRect[1], skRect[2], skRect[3]);
}

ui.Rect rectFromSkIRect(Int32List skIRect) {
  return ui.Rect.fromLTRB(
    skIRect[0].toDouble(),
    skIRect[1].toDouble(),
    skIRect[2].toDouble(),
    skIRect[3].toDouble(),
  );
}

// TODO(hterkelsen): Use a shared malloc'ed array for performance.
Float32List toSkRRect(ui.RRect rrect) {
  final skRRect = Float32List(12);
  skRRect[0] = rrect.left;
  skRRect[1] = rrect.top;
  skRRect[2] = rrect.right;
  skRRect[3] = rrect.bottom;
  skRRect[4] = rrect.tlRadiusX;
  skRRect[5] = rrect.tlRadiusY;
  skRRect[6] = rrect.trRadiusX;
  skRRect[7] = rrect.trRadiusY;
  skRRect[8] = rrect.brRadiusX;
  skRRect[9] = rrect.brRadiusY;
  skRRect[10] = rrect.blRadiusX;
  skRRect[11] = rrect.blRadiusY;
  return skRRect;
}

// TODO(hterkelsen): Use a shared malloc'ed array for performance.
Float32List toOuterSkRect(ui.RRect rrect) {
  final skRect = Float32List(4);
  skRect[0] = rrect.left;
  skRect[1] = rrect.top;
  skRect[2] = rrect.right;
  skRect[3] = rrect.bottom;
  return skRect;
}

/// Encodes a list of offsets to CanvasKit-compatible point array.
///
/// Uses `CanvasKit.Malloc` to allocate storage for the points in the WASM
/// memory to avoid unnecessary copying. Unless CanvasKit takes ownership of
/// the list the returned list must be explicitly freed using
/// [free].
SkFloat32List toMallocedSkPoints(List<ui.Offset> points) {
  final int len = points.length;
  final SkFloat32List skPoints = mallocFloat32List(len * 2);
  final Float32List list = skPoints.toTypedArray();
  for (var i = 0; i < len; i++) {
    list[2 * i] = points[i].dx;
    list[2 * i + 1] = points[i].dy;
  }
  return skPoints;
}

/// Converts a list of [ui.Offset] into a flat list of points.
Float32List toFlatSkPoints(List<ui.Offset> points) {
  final int len = points.length;
  final result = Float32List(len * 2);
  for (var i = 0; i < len; i++) {
    result[2 * i] = points[i].dx;
    result[2 * i + 1] = points[i].dy;
  }
  return result;
}

/// Converts a list of [ui.Color] into a flat list of ints.
Uint32List toFlatColors(List<ui.Color> colors) {
  final int len = colors.length;
  final result = Uint32List(len);
  for (var i = 0; i < len; i++) {
    result[i] = colors[i].value;
  }
  return result;
}

Uint16List toUint16List(List<int> ints) {
  final int len = ints.length;
  final result = Uint16List(len);
  for (var i = 0; i < len; i++) {
    result[i] = ints[i];
  }
  return result;
}

@JS('window.flutterCanvasKit.PictureRecorder')
extension type SkPictureRecorder._(JSObject _) implements JSObject {
  external SkPictureRecorder();

  @JS('beginRecording')
  external SkCanvas _beginRecording(JSFloat32Array bounds, bool computeBounds);
  SkCanvas beginRecording(Float32List bounds) => _beginRecording(bounds.toJS, true);

  external SkPicture finishRecordingAsPicture();
  external void delete();
}

/// We do not use the `delete` method (which may be removed in the future anyway).
///
/// By Skia coding convention raw pointers should always be treated as
/// "borrowed", i.e. their memory is managed by other objects. In the case of
/// [SkCanvas] it is managed by [SkPictureRecorder].
extension type SkCanvas(JSObject _) implements JSObject {
  @JS('clear')
  external void _clear(JSFloat32Array color);
  void clear(Float32List color) => _clear(color.toJS);

  @JS('clipPath')
  external void _clipPath(SkPath path, SkClipOp clipOp, bool doAntiAlias);
  void clipPath(SkPath path, SkClipOp clipOp, bool doAntiAlias) =>
      _clipPath(path, clipOp, doAntiAlias);

  @JS('clipRRect')
  external void _clipRRect(JSFloat32Array rrect, SkClipOp clipOp, bool doAntiAlias);
  void clipRRect(Float32List rrect, SkClipOp clipOp, bool doAntiAlias) =>
      _clipRRect(rrect.toJS, clipOp, doAntiAlias);

  @JS('clipRect')
  external void _clipRect(JSFloat32Array rect, SkClipOp clipOp, bool doAntiAlias);
  void clipRect(Float32List rect, SkClipOp clipOp, bool doAntiAlias) =>
      _clipRect(rect.toJS, clipOp, doAntiAlias);

  @JS('getDeviceClipBounds')
  external JSInt32Array _getDeviceClipBounds();
  Int32List getDeviceClipBounds() => _getDeviceClipBounds().toDart;

  @JS('drawArc')
  external void _drawArc(
    JSFloat32Array oval,
    double startAngleDegrees,
    double sweepAngleDegrees,
    bool useCenter,
    SkPaint paint,
  );
  void drawArc(
    Float32List oval,
    double startAngleDegrees,
    double sweepAngleDegrees,
    bool useCenter,
    SkPaint paint,
  ) => _drawArc(oval.toJS, startAngleDegrees, sweepAngleDegrees, useCenter, paint);

  @JS('drawAtlas')
  external void _drawAtlas(
    SkImage image,
    JSFloat32Array rects,
    JSFloat32Array rstTransforms,
    SkPaint paint,
    SkBlendMode blendMode,
    JSUint32Array? colors,
  );
  void drawAtlas(
    SkImage image,
    Float32List rects,
    Float32List rstTransforms,
    SkPaint paint,
    SkBlendMode blendMode,
    Uint32List? colors,
  ) => _drawAtlas(image, rects.toJS, rstTransforms.toJS, paint, blendMode, colors?.toJS);

  external void drawCircle(double x, double y, double radius, SkPaint paint);
  external void drawColorInt(double color, SkBlendMode blendMode);

  @JS('drawDRRect')
  external void _drawDRRect(JSFloat32Array outer, JSFloat32Array inner, SkPaint paint);
  void drawDRRect(Float32List outer, Float32List inner, SkPaint paint) =>
      _drawDRRect(outer.toJS, inner.toJS, paint);

  external void drawImageCubic(
    SkImage image,
    double x,
    double y,
    double B,
    double C,
    SkPaint paint,
  );

  external void drawImageOptions(
    SkImage image,
    double x,
    double y,
    SkFilterMode filterMode,
    SkMipmapMode mipmapMode,
    SkPaint paint,
  );

  @JS('drawImageRectCubic')
  external void _drawImageRectCubic(
    SkImage image,
    JSFloat32Array src,
    JSFloat32Array dst,
    double B,
    double C,
    SkPaint paint,
  );
  void drawImageRectCubic(
    SkImage image,
    Float32List src,
    Float32List dst,
    double B,
    double C,
    SkPaint paint,
  ) => _drawImageRectCubic(image, src.toJS, dst.toJS, B, C, paint);

  @JS('drawImageRectOptions')
  external void _drawImageRectOptions(
    SkImage image,
    JSFloat32Array src,
    JSFloat32Array dst,
    SkFilterMode filterMode,
    SkMipmapMode mipmapMode,
    SkPaint paint,
  );
  void drawImageRectOptions(
    SkImage image,
    Float32List src,
    Float32List dst,
    SkFilterMode filterMode,
    SkMipmapMode mipmapMode,
    SkPaint paint,
  ) => _drawImageRectOptions(image, src.toJS, dst.toJS, filterMode, mipmapMode, paint);

  @JS('drawImageNine')
  external void _drawImageNine(
    SkImage image,
    JSFloat32Array center,
    JSFloat32Array dst,
    SkFilterMode filterMode,
    SkPaint paint,
  );
  void drawImageNine(
    SkImage image,
    Float32List center,
    Float32List dst,
    SkFilterMode filterMode,
    SkPaint paint,
  ) => _drawImageNine(image, center.toJS, dst.toJS, filterMode, paint);

  external void drawLine(double x1, double y1, double x2, double y2, SkPaint paint);

  @JS('drawOval')
  external void _drawOval(JSFloat32Array rect, SkPaint paint);
  void drawOval(Float32List rect, SkPaint paint) => _drawOval(rect.toJS, paint);

  external void drawPaint(SkPaint paint);
  external void drawPath(SkPath path, SkPaint paint);

  @JS('drawPoints')
  external void _drawPoints(SkPointMode pointMode, JSFloat32Array points, SkPaint paint);
  void drawPoints(SkPointMode pointMode, Float32List points, SkPaint paint) =>
      _drawPoints(pointMode, points.toJS, paint);

  @JS('drawRRect')
  external void _drawRRect(JSFloat32Array rrect, SkPaint paint);
  void drawRRect(Float32List rrect, SkPaint paint) => _drawRRect(rrect.toJS, paint);

  @JS('drawRect')
  external void _drawRect(JSFloat32Array rect, SkPaint paint);
  void drawRect(Float32List rect, SkPaint paint) => _drawRect(rect.toJS, paint);

  @JS('drawShadow')
  external void _drawShadow(
    SkPath path,
    JSFloat32Array zPlaneParams,
    JSFloat32Array lightPos,
    double lightRadius,
    JSFloat32Array ambientColor,
    JSFloat32Array spotColor,
    double flags,
  );
  void drawShadow(
    SkPath path,
    Float32List zPlaneParams,
    Float32List lightPos,
    double lightRadius,
    Float32List ambientColor,
    Float32List spotColor,
    double flags,
  ) => _drawShadow(
    path,
    zPlaneParams.toJS,
    lightPos.toJS,
    lightRadius,
    ambientColor.toJS,
    spotColor.toJS,
    flags,
  );

  external void drawVertices(SkVertices vertices, SkBlendMode blendMode, SkPaint paint);
  external double save();
  external double getSaveCount();

  @JS('saveLayer')
  external void _saveLayer(
    SkPaint? paint,
    JSFloat32Array? bounds,
    SkImageFilter? backdrop,
    int? flags,
    SkTileMode backdropTileMode,
  );
  void saveLayer(
    SkPaint? paint,
    Float32List? bounds,
    SkImageFilter? backdrop,
    int? flags,
    SkTileMode backdropTileMode,
  ) => _saveLayer(paint, bounds?.toJS, backdrop, flags, backdropTileMode);

  external void restore();
  external void restoreToCount(double count);
  external void rotate(double angleDegrees, double px, double py);
  external void scale(double x, double y);
  external void skew(double x, double y);

  @JS('concat')
  external void _concat(JSFloat32Array matrix);
  void concat(Float32List matrix) => _concat(matrix.toJS);

  external void translate(double x, double y);

  @JS('getLocalToDevice')
  external JSAny _getLocalToDevice();
  List<dynamic> getLocalToDevice() => _getLocalToDevice().toObjectShallow as List<dynamic>;

  @JS('quickReject')
  external bool _quickReject(JSFloat32Array rect);
  bool quickReject(Float32List rect) => _quickReject(rect.toJS);

  external void drawPicture(SkPicture picture);
  external void drawParagraph(SkParagraph paragraph, double x, double y);
}

extension type SkPicture(JSObject _) implements JSObject {
  external void delete();

  @JS('cullRect')
  external JSFloat32Array _cullRect();

  Float32List cullRect() => _cullRect().toDart;

  external int approximateBytesUsed();
}

extension type BidiRegion(JSObject _) implements JSObject {
  external int get start;
  external int get end;
  external int get level;
}

extension type BidiIndex(JSObject _) implements JSObject {
  external int get index;
}

extension type BidiNamespace(JSObject _) implements JSObject {
  @JS('getBidiRegions')
  // TODO(jlavrova): Use a JSInt32Array return type instead of `List<BidiIndex>`
  external JSArray<JSAny?> _getBidiRegions(String text, SkTextDirection dir);
  List<BidiRegion> getBidiRegions(String text, ui.TextDirection dir) =>
      _getBidiRegions(text, toSkTextDirection(dir)).toDart.cast<BidiRegion>();

  @JS('reorderVisual')
  // TODO(jlavrova): Use a JSInt32Array return type instead of `List<BidiIndex>`
  external JSArray<JSAny?> _reorderVisual(JSUint8Array visuals);
  List<BidiIndex> reorderVisual(Uint8List visuals) =>
      _reorderVisual(visuals.toJS).toDart.cast<BidiIndex>();
}

extension type CodeUnitInfo(JSObject _) implements JSObject {
  external int get flags;
}

extension type CodeUnitsNamespace(JSObject _) implements JSObject {
  @JS('compute')
  external JSArray<JSAny?> _compute(String text);
  List<CodeUnitInfo> compute(String text) => _compute(text).toDart.cast<CodeUnitInfo>();
}

extension type SkParagraphBuilderNamespace(JSObject _) implements JSObject {
  external SkParagraphBuilder MakeFromFontCollection(
    SkParagraphStyle paragraphStyle,
    SkFontCollection? fontCollection,
  );

  bool RequiresClientICU() {
    if (!has('RequiresClientICU')) {
      return false;
    }
    return callMethod<JSBoolean>('RequiresClientICU'.toJS).toDart;
  }
}

final bool _ckRequiresClientICU = canvasKit.ParagraphBuilder.RequiresClientICU();

extension type SkParagraphBuilder(JSObject _) implements JSObject {
  external void addText(String text);
  external void pushStyle(SkTextStyle textStyle);
  external void pushPaintStyle(SkTextStyle textStyle, SkPaint foreground, SkPaint background);
  external void pop();
  external void addPlaceholder(
    double width,
    double height,
    SkPlaceholderAlignment alignment,
    SkTextBaseline baseline,
    double offset,
  );

  @JS('getText')
  external String getTextUtf8();
  // SkParagraphBuilder.getText() returns a utf8 string, we need to decode it
  // into a utf16 string.
  String getText() => utf8.decode(getTextUtf8().codeUnits);

  /// Injects required ICU data into the [SkParagraphBuilder] instance if needed.
  ///
  /// This only works in the CanvasKit Chromium variant that's compiled
  /// without ICU data. In other variants, it's a no-op.
  void injectClientICUIfNeeded() {
    if (!_ckRequiresClientICU) {
      return;
    }

    final SegmentationResult result = segmentText(getText());
    setWordsUtf16(result.words);
    setGraphemeBreaksUtf16(result.graphemes);
    setLineBreaksUtf16(result.breaks);
  }

  @JS('setWordsUtf8')
  external void _setWordsUtf8(JSUint32Array words);
  void setWordsUtf8(Uint32List words) => _setWordsUtf8(words.toJS);

  @JS('setWordsUtf16')
  external void _setWordsUtf16(JSUint32Array words);
  void setWordsUtf16(Uint32List words) => _setWordsUtf16(words.toJS);

  @JS('setGraphemeBreaksUtf8')
  external void _setGraphemeBreaksUtf8(JSUint32Array graphemes);
  void setGraphemeBreaksUtf8(Uint32List graphemes) => _setGraphemeBreaksUtf8(graphemes.toJS);

  @JS('setGraphemeBreaksUtf16')
  external void _setGraphemeBreaksUtf16(JSUint32Array graphemes);
  void setGraphemeBreaksUtf16(Uint32List graphemes) => _setGraphemeBreaksUtf16(graphemes.toJS);

  @JS('setLineBreaksUtf8')
  external void _setLineBreaksUtf8(JSUint32Array lineBreaks);
  void setLineBreaksUtf8(Uint32List lineBreaks) => _setLineBreaksUtf8(lineBreaks.toJS);

  @JS('setLineBreaksUtf16')
  external void _setLineBreaksUtf16(JSUint32Array lineBreaks);
  void setLineBreaksUtf16(Uint32List lineBreaks) => _setLineBreaksUtf16(lineBreaks.toJS);

  external SkParagraph build();
  external void delete();
}

extension type SkParagraphStyle(JSObject _) implements JSObject {}

extension type SkParagraphStyleProperties._(JSObject _) implements JSObject {
  external SkParagraphStyleProperties({int dummyArgumentToCreateObjectLiteral});
  external set textAlign(SkTextAlign? value);
  external set textDirection(SkTextDirection? value);
  external set heightMultiplier(double? value);
  external set textHeightBehavior(SkTextHeightBehavior? value);
  external set maxLines(int? value);
  external set ellipsis(String? value);
  external set textStyle(SkTextStyleProperties? value);
  external set strutStyle(SkStrutStyleProperties? strutStyle);
  external set replaceTabCharacters(bool? bool);
  external set applyRoundingHack(bool applyRoundingHack);
}

extension type SkTextStyle(JSObject _) implements JSObject {}

extension type SkTextDecorationStyleEnum(JSObject _) implements JSObject {
  external SkTextDecorationStyle get Solid;
  external SkTextDecorationStyle get Double;
  external SkTextDecorationStyle get Dotted;
  external SkTextDecorationStyle get Dashed;
  external SkTextDecorationStyle get Wavy;
}

extension type SkTextDecorationStyle(JSObject _) implements JSObject {
  external double get value;
}

final List<SkTextDecorationStyle> _skTextDecorationStyles = <SkTextDecorationStyle>[
  canvasKit.DecorationStyle.Solid,
  canvasKit.DecorationStyle.Double,
  canvasKit.DecorationStyle.Dotted,
  canvasKit.DecorationStyle.Dashed,
  canvasKit.DecorationStyle.Wavy,
];

SkTextDecorationStyle toSkTextDecorationStyle(ui.TextDecorationStyle style) {
  return _skTextDecorationStyles[style.index];
}

extension type SkTextBaselineEnum(JSObject _) implements JSObject {
  external SkTextBaseline get Alphabetic;
  external SkTextBaseline get Ideographic;
}

extension type SkTextBaseline(JSObject _) implements JSObject {
  external double get value;
}

final List<SkTextBaseline> _skTextBaselines = <SkTextBaseline>[
  canvasKit.TextBaseline.Alphabetic,
  canvasKit.TextBaseline.Ideographic,
];

SkTextBaseline toSkTextBaseline(ui.TextBaseline baseline) {
  return _skTextBaselines[baseline.index];
}

extension type SkPlaceholderAlignmentEnum(JSObject _) implements JSObject {
  external SkPlaceholderAlignment get Baseline;
  external SkPlaceholderAlignment get AboveBaseline;
  external SkPlaceholderAlignment get BelowBaseline;
  external SkPlaceholderAlignment get Top;
  external SkPlaceholderAlignment get Bottom;
  external SkPlaceholderAlignment get Middle;
}

extension type SkPlaceholderAlignment(JSObject _) implements JSObject {
  external double get value;
}

final List<SkPlaceholderAlignment> _skPlaceholderAlignments = <SkPlaceholderAlignment>[
  canvasKit.PlaceholderAlignment.Baseline,
  canvasKit.PlaceholderAlignment.AboveBaseline,
  canvasKit.PlaceholderAlignment.BelowBaseline,
  canvasKit.PlaceholderAlignment.Top,
  canvasKit.PlaceholderAlignment.Bottom,
  canvasKit.PlaceholderAlignment.Middle,
];

SkPlaceholderAlignment toSkPlaceholderAlignment(ui.PlaceholderAlignment alignment) {
  return _skPlaceholderAlignments[alignment.index];
}

extension type SkTextStyleProperties._(JSObject _) implements JSObject {
  external SkTextStyleProperties({int dummyArgumentToCreateObjectLiteral});

  @JS('backgroundColor')
  external set _backgroundColor(JSFloat32Array? value);
  set backgroundColor(Float32List? value) => _backgroundColor = value?.toJS;

  @JS('color')
  external set _color(JSFloat32Array? value);
  set color(Float32List? value) => _color = value?.toJS;

  @JS('foregroundColor')
  external set _foregroundColor(JSFloat32Array? value);
  set foregroundColor(Float32List? value) => _foregroundColor = value?.toJS;

  external set decoration(int? value);
  external set decorationThickness(double? value);

  @JS('decorationColor')
  external set _decorationColor(JSFloat32Array? value);
  set decorationColor(Float32List? value) => _decorationColor = value?.toJS;

  external set decorationStyle(SkTextDecorationStyle? value);
  external set textBaseline(SkTextBaseline? value);
  external set fontSize(double? value);
  external set letterSpacing(double? value);
  external set wordSpacing(double? value);
  external set heightMultiplier(double? value);
  external set halfLeading(bool? value);
  external set locale(String? value);

  @JS('fontFamilies')
  external set _fontFamilies(JSAny? value);
  set fontFamilies(List<String>? value) => _fontFamilies = value?.toJSAnyShallow;

  external set fontStyle(SkFontStyle? value);

  @JS('shadows')
  external set _shadows(JSArray<JSAny?>? value);
  set shadows(List<SkTextShadow>? value) => _shadows = (value as List<JSAny>?)?.toJS;

  @JS('fontFeatures')
  external set _fontFeatures(JSArray<JSAny?>? value);
  set fontFeatures(List<SkFontFeature>? value) => _fontFeatures = (value as List<JSAny>?)?.toJS;

  @JS('fontVariations')
  external set _fontVariations(JSArray<JSAny?>? value);
  set fontVariations(List<SkFontVariation>? value) =>
      _fontVariations = (value as List<JSAny>?)?.toJS;
}

extension type SkStrutStyleProperties._(JSObject _) implements JSObject {
  external SkStrutStyleProperties({int dummyArgumentToCreateObjectLiteral});

  @JS('fontFamilies')
  external set _fontFamilies(JSAny? value);
  set fontFamilies(List<String>? value) => _fontFamilies = value?.toJSAnyShallow;

  external set fontStyle(SkFontStyle? value);
  external set fontSize(double? value);
  external set heightMultiplier(double? value);
  external set halfLeading(bool? value);
  external set leading(double? value);
  external set strutEnabled(bool? value);
  external set forceStrutHeight(bool? value);
}

extension type SkFontStyle._(JSObject _) implements JSObject {
  external SkFontStyle({int dummyArgumentToCreateObjectLiteral});

  external set weight(SkFontWeight? value);
  external set slant(SkFontSlant? value);
}

extension type SkTextShadow._(JSObject _) implements JSObject {
  external SkTextShadow({int dummyArgumentToCreateObjectLiteral});

  @JS('color')
  external set _color(JSFloat32Array? value);
  set color(Float32List? value) => _color = value?.toJS;

  @JS('offset')
  external set _offset(JSFloat32Array? value);
  set offset(Float32List? value) => _offset = value?.toJS;

  external set blurRadius(double? value);
}

extension type SkFontFeature._(JSObject _) implements JSObject {
  external SkFontFeature({int dummyArgumentToCreateObjectLiteral});

  external set name(String? value);
  external set value(int? v);
}

extension type SkFontVariation._(JSObject _) implements JSObject {
  external SkFontVariation({int dummyArgumentToCreateObjectLiteral});

  external set axis(String? value);
  external set value(double? v);
}

extension type SkTypeface(JSObject _) implements JSObject {}

@JS('window.flutterCanvasKit.Font')
extension type SkFont._(JSObject _) implements JSObject {
  external SkFont(SkTypeface typeface);

  @JS('getGlyphIDs')
  external JSUint16Array _getGlyphIDs(String text);
  Uint16List getGlyphIDs(String text) => _getGlyphIDs(text).toDart;

  @JS('getGlyphBounds')
  external void _getGlyphBounds(JSAny glyphs, SkPaint? paint, JSUint8Array? output);
  void getGlyphBounds(List<int> glyphs, SkPaint? paint, Uint8List? output) =>
      _getGlyphBounds(glyphs.toJSAnyShallow, paint, output?.toJS);
}

extension type SkFontMgr(JSObject _) implements JSObject {
  external String? getFamilyName(double fontId);

  external void delete();

  @JS('MakeTypefaceFromData')
  external SkTypeface? _MakeTypefaceFromData(JSUint8Array font);
  SkTypeface? MakeTypefaceFromData(Uint8List font) => _MakeTypefaceFromData(font.toJS);
}

@JS('window.flutterCanvasKit.TypefaceFontProvider')
extension type TypefaceFontProvider(JSObject _) implements SkFontMgr {
  @JS('registerFont')
  external void _registerFont(JSUint8Array font, String family);
  void registerFont(Uint8List font, String family) => _registerFont(font.toJS, family);
}

extension type SkFontCollection(JSObject _) implements JSObject {
  external void enableFontFallback();
  external void setDefaultFontManager(TypefaceFontProvider? fontManager);
  external void delete();
}

extension type SkLineMetrics(JSObject _) implements JSObject {
  external double get startIndex;
  external double get endIndex;
  external double get endExcludingWhitespaces;
  external double get endIncludingNewline;
  external bool get isHardBreak;
  external double get ascent;
  external double get descent;
  external double get height;
  external double get width;
  external double get left;
  external double get baseline;
  external double get lineNumber;
}

extension type SkGlyphClusterInfo(JSObject _) implements JSObject {
  @JS('graphemeLayoutBounds')
  external JSArray<JSAny?> get _bounds;

  @JS('dir')
  external SkTextDirection get _direction;

  @JS('graphemeClusterTextRange')
  external SkTextRange get _textRange;

  ui.GlyphInfo get _glyphInfo {
    final List<JSNumber> list = _bounds.toDart.cast<JSNumber>();
    final bounds = ui.Rect.fromLTRB(
      list[0].toDartDouble,
      list[1].toDartDouble,
      list[2].toDartDouble,
      list[3].toDartDouble,
    );
    final textRange = ui.TextRange(start: _textRange.start.toInt(), end: _textRange.end.toInt());
    return ui.GlyphInfo(bounds, textRange, ui.TextDirection.values[_direction.value.toInt()]);
  }
}

extension type SkRectWithDirection(JSObject _) implements JSObject {
  @JS('rect')
  external JSFloat32Array get _rect;
  Float32List get rect => _rect.toDart;

  @JS('rect')
  external set _rect(JSFloat32Array rect);
  set rect(Float32List r) => _rect = r.toJS;

  external SkTextDirection dir;
}

extension type SkParagraph(JSObject _) implements JSObject {
  external double getAlphabeticBaseline();
  external bool didExceedMaxLines();
  external double getHeight();
  external double getIdeographicBaseline();

  @JS('getLineMetrics')
  external JSArray<JSAny?> _getLineMetrics();
  List<SkLineMetrics> getLineMetrics() => _getLineMetrics().toDart.cast<SkLineMetrics>();

  external SkLineMetrics? getLineMetricsAt(double index);
  external double getNumberOfLines();
  external double getLineNumberAt(double index);
  external double getLongestLine();
  external double getMaxIntrinsicWidth();
  external double getMinIntrinsicWidth();
  external double getMaxWidth();

  @JS('getRectsForRange')
  external JSArray<JSAny?> _getRectsForRange(
    double start,
    double end,
    SkRectHeightStyle heightStyle,
    SkRectWidthStyle widthStyle,
  );
  List<SkRectWithDirection> getRectsForRange(
    double start,
    double end,
    SkRectHeightStyle heightStyle,
    SkRectWidthStyle widthStyle,
  ) => _getRectsForRange(start, end, heightStyle, widthStyle).toDart.cast<SkRectWithDirection>();

  @JS('getRectsForPlaceholders')
  external JSArray<JSAny?> _getRectsForPlaceholders();
  List<SkRectWithDirection> getRectsForPlaceholders() =>
      _getRectsForPlaceholders().toDart.cast<SkRectWithDirection>();

  external SkTextPosition getGlyphPositionAtCoordinate(double x, double y);

  @JS('getGlyphInfoAt')
  external SkGlyphClusterInfo? _getGlyphInfoAt(double position);
  ui.GlyphInfo? getGlyphInfoAt(double position) => _getGlyphInfoAt(position)?._glyphInfo;

  @JS('getClosestGlyphInfoAtCoordinate')
  external SkGlyphClusterInfo? _getClosestGlyphInfoAtCoordinate(double x, double y);
  ui.GlyphInfo? getClosestGlyphInfoAt(double x, double y) =>
      _getClosestGlyphInfoAtCoordinate(x, y)?._glyphInfo;

  external SkTextRange getWordBoundary(double position);
  external void layout(double width);
  external void delete();
}

extension type SkTextPosition(JSObject _) implements JSObject {
  external SkAffinity get affinity;
  external double get pos;
}

extension type SkTextRange(JSObject _) implements JSObject {
  external double get start;
  external double get end;
}

extension type SkVertices(JSObject _) implements JSObject {
  external void delete();
}

extension type SkTonalColors._(JSObject _) implements JSObject {
  factory SkTonalColors({required Float32List ambient, required Float32List spot}) =>
      SkTonalColors.make(ambient: ambient.toJS, spot: spot.toJS);
  external SkTonalColors.make({required JSFloat32Array ambient, required JSFloat32Array spot});

  @JS('ambient')
  external JSFloat32Array get _ambient;
  Float32List get ambient => _ambient.toDart;

  @JS('spot')
  external JSFloat32Array get _spot;
  Float32List get spot => _spot.toDart;
}

extension type SkFontMgrNamespace(JSObject _) implements JSObject {
  // TODO(yjbanov): can this be made non-null? It returns null in our unit-tests right now.
  @JS('FromData')
  external SkFontMgr? _FromData(JSAny fonts);
  SkFontMgr? FromData(List<Uint8List> fonts) => _FromData(fonts.toJSAnyShallow);
}

extension type TypefaceFontProviderNamespace(JSObject _) implements JSObject {
  external TypefaceFontProvider Make();
}

extension type FontCollectionNamespace(JSObject _) implements JSObject {
  external SkFontCollection Make();
}

extension type SkTypefaceFactory(JSObject _) implements JSObject {
  @JS('MakeFreeTypeFaceFromData')
  external SkTypeface? _MakeFreeTypeFaceFromData(JSArrayBuffer fontData);
  SkTypeface? MakeFreeTypeFaceFromData(ByteBuffer fontData) =>
      _MakeFreeTypeFaceFromData(fontData.toJS);
}

/// Any Skia object that has a `delete` method.
extension type SkDeletable(JSObject _) implements JSObject {
  /// Deletes the C++ side object.
  external void delete();

  /// Returns whether the corresponding C++ object has been deleted.
  external bool isDeleted();

  /// Returns the JavaScript constructor for this object.
  ///
  /// This is useful for debugging.
  external JsConstructor get constructor;
}

extension type JsConstructor(JSObject _) implements JSObject {
  /// The name of the "constructor", typically the function name called with
  /// the `new` keyword, or the ES6 class name.
  ///
  /// This is useful for debugging.
  external bool get name;
}

extension type SkData(JSObject _) implements JSObject {
  external double size();

  external bool isEmpty();

  @JS('bytes')
  external JSUint8Array _bytes();
  Uint8List bytes() => _bytes().toDart;

  external void delete();
}

extension type SkImageInfo._(JSObject _) implements JSObject {
  external SkImageInfo({
    required double width,
    required double height,
    required SkColorType colorType,
    required SkAlphaType alphaType,
    required ColorSpace colorSpace,
  });

  external SkAlphaType get alphaType;
  external ColorSpace get colorSpace;
  external SkColorType get colorType;

  external double get height;
  external double get width;
  external bool get isEmpty;
  external bool get isOpaque;

  @JS('bounds')
  external JSFloat32Array get _bounds;
  Float32List get bounds => _bounds.toDart;

  external SkImageInfo makeAlphaType(SkAlphaType alphaType);
  external SkImageInfo makeColorSpace(ColorSpace colorSpace);
  external SkImageInfo makeColorType(SkColorType colorType);
  external SkImageInfo makeWH(double width, double height);
}

extension type SkPartialImageInfo._(JSObject _) implements JSObject {
  external SkPartialImageInfo({
    required double width,
    required double height,
    required SkColorType colorType,
    required SkAlphaType alphaType,
    required ColorSpace colorSpace,
  });

  external SkAlphaType get alphaType;
  external ColorSpace get colorSpace;
  external SkColorType get colorType;

  external double get height;

  external double get width;
}

@JS('window.flutterCanvasKit.RuntimeEffect')
extension type SkRuntimeEffect(JSObject _) implements JSObject {
  @JS('makeShader')
  external SkShader? _makeShader(JSAny uniforms);
  SkShader? makeShader(SkFloat32List uniforms) => _makeShader(uniforms.toJSAnyShallow);

  @JS('makeShaderWithChildren')
  external SkShader? _makeShaderWithChildren(JSAny uniforms, JSAny children);
  SkShader? makeShaderWithChildren(SkFloat32List uniforms, List<Object?> children) =>
      _makeShaderWithChildren(uniforms.toJSAnyShallow, children.toJSAnyShallow);
}

@JS('window.flutterCanvasKit.RuntimeEffect.Make')
external SkRuntimeEffect? _MakeRuntimeEffect(String program);
SkRuntimeEffect? MakeRuntimeEffect(String program) => _MakeRuntimeEffect(program);

const String _kFullCanvasKitJsFileName = 'canvaskit.js';
const String _kChromiumCanvasKitJsFileName = 'chromium/canvaskit.js';
const String _kWebParagraphCanvasKitJsFileName = 'experimental_webparagraph/canvaskit.js';

String get _canvasKitBaseUrl => configuration.canvasKitBaseUrl;

@visibleForTesting
List<String> getCanvasKitJsFileNames(CanvasKitVariant variant) {
  return switch (variant) {
    CanvasKitVariant.auto => <String>[
      if (_enableCanvasKitChromiumInAutoMode) _kChromiumCanvasKitJsFileName,
      _kFullCanvasKitJsFileName,
    ],
    CanvasKitVariant.full => <String>[_kFullCanvasKitJsFileName],
    CanvasKitVariant.chromium => <String>[_kChromiumCanvasKitJsFileName],
    CanvasKitVariant.experimentalWebParagraph => <String>[_kWebParagraphCanvasKitJsFileName],
  };
}

Iterable<String> get _canvasKitJsUrls {
  return getCanvasKitJsFileNames(
    configuration.canvasKitVariant,
  ).map((String filename) => '$_canvasKitBaseUrl$filename');
}

@visibleForTesting
String canvasKitWasmModuleUrl(String file, String canvasKitBase) => canvasKitBase + file;

/// Download and initialize the CanvasKit module.
///
/// Downloads the CanvasKit JavaScript, then calls `CanvasKitInit` to download
/// and intialize the CanvasKit wasm.
Future<CanvasKit> downloadCanvasKit() async {
  final CanvasKitModule canvasKitModule = await _downloadOneOf(_canvasKitJsUrls);

  final canvasKit =
      (await canvasKitModule
              .defaultExport(
                CanvasKitInitOptions(locateFile: createLocateFileCallback(canvasKitWasmModuleUrl)),
              )
              .toDart)
          as CanvasKit;

  if (canvasKit.ParagraphBuilder.RequiresClientICU() && !browserSupportsCanvaskitChromium) {
    throw Exception(
      'The CanvasKit variant you are using only works on Chromium browsers. '
      'Please use a different CanvasKit variant, or use a Chromium browser.',
    );
  }

  return canvasKit;
}

/// Finds the first URL in [urls] that can be downloaded successfully, and
/// downloads it.
///
/// If none of the URLs can be downloaded, throws an [Exception].
Future<CanvasKitModule> _downloadOneOf(Iterable<String> urls) async {
  for (final url in urls) {
    try {
      return await _downloadCanvasKitJs(url);
    } catch (_) {
      continue;
    }
  }

  // Reaching this point means that all URLs failed to download.
  throw Exception('Failed to download any of the following CanvasKit URLs: $urls');
}

String _resolveUrl(String url) {
  return createDomURL(url, domWindow.document.baseUri).toJSString();
}

/// Downloads the CanvasKit JavaScript file at [url].
///
/// Returns a [Future] that completes with `true` if the CanvasKit JavaScript
/// file was successfully downloaded, or `false` if it failed.
Future<CanvasKitModule> _downloadCanvasKitJs(String url) async {
  final JSAny scriptUrl = createTrustedScriptUrl(_resolveUrl(url));
  return (await importModule(scriptUrl).toDart) as CanvasKitModule;
}
