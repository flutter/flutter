// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart'
    // ignore: deprecated_web_configuration, https://github.com/dart-lang/sdk/issues/61464
    if (dart.library.html) 'package:ui/src/engine/skwasm/skwasm_stub.dart';
import 'package:ui/ui.dart';

import '../common/rendering.dart';

Picture drawPicture(void Function(Canvas) drawCommands) {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  drawCommands(canvas);
  return recorder.endRecording();
}

/// Draws with every [Canvas] method that takes a [Paint], and with paragraphs
/// whose styles have foreground and background paints.
///
/// [record] makes [canvasPaintDrawCount] draw calls that each take a [Paint].
///
/// Used to check that the native paints created for these draws are freed.
class PaintConsumers {
  PaintConsumers._(this._image, this._vertices, this._paragraphs);

  /// Creates the image, vertices and paragraphs that [record] draws.
  ///
  /// Building the paragraphs converts their foreground and background paints.
  static Future<PaintConsumers> create() async {
    final Image image = await drawPicture((Canvas canvas) {
      canvas.drawRect(const Rect.fromLTRB(0, 0, 4, 4), Paint()..color = const Color(0xFF00FF00));
    }).toImage(4, 4);
    final vertices = Vertices(VertexMode.triangles, const <Offset>[
      Offset.zero,
      Offset(10, 0),
      Offset(0, 10),
    ]);
    Paragraph paragraph(TextStyle style) {
      final builder = ParagraphBuilder(ParagraphStyle(fontFamily: 'Ahem', fontSize: 10))
        ..pushStyle(style)
        ..addText('Paint');
      return builder.build()..layout(const ParagraphConstraints(width: 100));
    }

    final paragraphs = <Paragraph>[
      paragraph(
        TextStyle(
          foreground: Paint()..color = const Color(0xFF00FF00),
          background: Paint()..color = const Color(0xFFFF0000),
        ),
      ),
      paragraph(TextStyle(foreground: Paint()..color = const Color(0xFF00FF00))),
      paragraph(TextStyle(background: Paint()..color = const Color(0xFFFF0000))),
    ];
    return PaintConsumers._(image, vertices, paragraphs);
  }

  /// The number of draw calls in [record] that take a [Paint].
  static const int canvasPaintDrawCount = 21;

  final Image _image;
  final Vertices _vertices;
  final List<Paragraph> _paragraphs;

  /// Records a picture that draws with a paint that sets every field a native
  /// paint is built from.
  Picture record() {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(10, 0)
      ..lineTo(10, 10)
      ..close();
    final paint = Paint()
      ..color = const Color(0xFF0000FF)
      ..strokeWidth = 2
      ..shader = Gradient.linear(Offset.zero, const Offset(10, 0), const <Color>[
        Color(0xFFFF0000),
        Color(0xFF00FF00),
      ])
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
      ..colorFilter = const ColorFilter.mode(Color(0x80FFFFFF), BlendMode.srcOver)
      ..invertColors = true
      ..imageFilter = ImageFilter.blur(sigmaX: 1, sigmaY: 1);
    const rect = Rect.fromLTRB(0, 0, 10, 10);
    return drawPicture((Canvas canvas) {
      canvas.drawLine(Offset.zero, const Offset(10, 10), paint);
      canvas.drawPaint(paint);
      canvas.drawRect(rect, paint);
      canvas.drawRRect(RRect.fromRectXY(rect, 2, 2), paint);
      canvas.drawRSuperellipse(RSuperellipse.fromRectXY(rect, 2, 2), paint);
      canvas.drawDRRect(
        RRect.fromRectXY(rect, 2, 2),
        RRect.fromRectXY(rect.deflate(3), 1, 1),
        paint,
      );
      canvas.drawOval(rect, paint);
      canvas.drawCircle(const Offset(5, 5), 5, paint);
      canvas.drawArc(rect, 0, 1, true, paint);
      canvas.drawPath(path, paint);
      canvas.drawImage(_image, Offset.zero, paint);
      canvas.drawImageRect(_image, const Rect.fromLTRB(0, 0, 4, 4), rect, paint);
      canvas.drawImageNine(_image, const Rect.fromLTRB(1, 1, 3, 3), rect, paint);
      canvas.drawAtlas(
        _image,
        <RSTransform>[RSTransform(1, 0, 0, 0)],
        const <Rect>[Rect.fromLTRB(0, 0, 4, 4)],
        const <Color>[Color(0xFFFFFFFF)],
        BlendMode.srcOver,
        null,
        paint,
      );
      canvas.drawVertices(_vertices, BlendMode.srcOver, paint);
      canvas.drawRawAtlas(
        _image,
        Float32List.fromList(<double>[1, 0, 0, 0]),
        Float32List.fromList(<double>[0, 0, 4, 4]),
        null,
        null,
        null,
        paint,
      );
      canvas.drawPoints(PointMode.points, const <Offset>[Offset(1, 1)], paint);
      canvas.drawRawPoints(PointMode.points, Float32List.fromList(<double>[1, 1]), paint);
      canvas.saveLayer(rect, paint);
      canvas.restore();
      canvas.saveLayer(null, paint);
      canvas.restore();
      (canvas as LayerCanvas).saveLayerWithFilter(
        rect,
        paint,
        ImageFilter.blur(sigmaX: 1, sigmaY: 1),
      );
      canvas.restore();
      for (final Paragraph paragraph in _paragraphs) {
        canvas.drawParagraph(paragraph, Offset.zero);
      }
    });
  }

  /// Disposes the image, vertices and paragraphs created by [create].
  void dispose() {
    for (final Paragraph paragraph in _paragraphs) {
      paragraph.dispose();
    }
    _vertices.dispose();
    _image.dispose();
  }
}

/// A fake [BackendImage] from another renderer, rejected by backend canvases.
class ForeignBackendImage implements BackendImage {
  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ForeignBackendImageFilter implements BackendImageFilter {
  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// An [EngineImageFilter] whose backend delegate belongs to another renderer.
class ForeignImageFilter extends EngineImageFilter {
  @override
  BackendImageFilter getBackendFilter({required TileMode defaultBlurTileMode}) =>
      _ForeignBackendImageFilter();
}

class _ForeignBackendPath implements BackendPath {
  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// An [EnginePath] whose backend delegate belongs to another renderer.
class ForeignPath implements EnginePath {
  @override
  BackendPath get backendPath => _ForeignBackendPath();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ForeignBackendVertices implements BackendVertices {
  @override
  void dispose() {}
}

/// An [EngineVertices] whose backend delegate belongs to another renderer.
class ForeignVertices implements EngineVertices {
  @override
  bool get debugDisposed => false;

  @override
  BackendVertices? get delegate => _ForeignBackendVertices();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A [BackendCanvas] whose [drawPath] throws after [translate] succeeds.
class ThrowingBackendCanvas implements BackendCanvas {
  @override
  void translate(double dx, double dy) {}

  @override
  void drawPath(BackendPath path, BackendPaint paint) {
    throw StateError('drawPath failed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Draws the [Picture]. This is in preparation for a golden test.
Future<void> drawPictureUsingCurrentRenderer(Picture picture) async {
  final sb = SceneBuilder();
  sb.pushOffset(0, 0);
  sb.addPicture(Offset.zero, picture);
  await renderScene(sb.build());
}

// Sends a platform message to create a Platform View with the given id and viewType.
Future<void> createPlatformView(int id, String viewType) {
  final completer = Completer<void>();
  const MethodCodec codec = StandardMethodCodec();
  PlatformDispatcher.instance.sendPlatformMessage(
    'flutter/platform_views',
    codec.encodeMethodCall(MethodCall('create', <String, dynamic>{'id': id, 'viewType': viewType})),
    (dynamic _) => completer.complete(),
  );
  return completer.future;
}

/// Disposes of the platform view with the given [id].
Future<void> disposePlatformView(int id) {
  final completer = Completer<void>();
  const MethodCodec codec = StandardMethodCodec();
  PlatformDispatcher.instance.sendPlatformMessage(
    'flutter/platform_views',
    codec.encodeMethodCall(MethodCall('dispose', id)),
    (dynamic _) => completer.complete(),
  );
  return completer.future;
}

Future<bool> matchImage(Image left, Image right) async {
  if (left.width != right.width || left.height != right.height) {
    return false;
  }
  int getPixel(ByteData data, int x, int y) => data.getUint32((x + y * left.width) * 4);
  final ByteData leftData = (await left.toByteData())!;
  final ByteData rightData = (await right.toByteData())!;
  for (var y = 0; y < left.height; y++) {
    for (var x = 0; x < left.width; x++) {
      if (getPixel(leftData, x, y) != getPixel(rightData, x, y)) {
        return false;
      }
    }
  }
  return true;
}

/// Convenience getter for the implicit view.
FlutterView get implicitView => EnginePlatformDispatcher.instance.implicitView!;

/// Returns [true] if this test is running in the CanvasKit renderer.
bool get isCanvasKit => renderer is CanvasKitRenderer;

bool get isSkwasm => renderer is SkwasmRenderer;

bool get isWimp => isSkwasm && (renderer as SkwasmRenderer).isWimp;

bool get isMultiThreaded => isSkwasm && (renderer as SkwasmRenderer).isMultiThreaded;
