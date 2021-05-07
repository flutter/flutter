// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:js_util' as js_util;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart' hide TextStyle, ImageShader;
import 'package:ui/src/engine.dart';

import 'package:web_engine_tester/golden_tester.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() async {
  const double screenWidth = 600.0;
  const double screenHeight = 800.0;
  const Rect screenRect = Rect.fromLTWH(0, 0, screenWidth, screenHeight);

  // Commit a recording canvas to a bitmap, and compare with the expected
  Future<void> _checkScreenshot(RecordingCanvas rc, String fileName,
      {Rect region = const Rect.fromLTWH(0, 0, 500, 500),
      double maxDiffRatePercent = 0.0,
      bool write = false}) async {
    final EngineCanvas engineCanvas =
        BitmapCanvas(screenRect, RenderStrategy());
    rc.endRecording();
    rc.apply(engineCanvas, screenRect);

    // Wrap in <flt-scene> so that our CSS selectors kick in.
    final html.Element sceneElement = html.Element.tag('flt-scene');
    try {
      sceneElement.append(engineCanvas.rootElement);
      html.document.body!.append(sceneElement);
      await matchGoldenFile(
        '$fileName.png',
        region: region,
        write: write,
        maxDiffRatePercent: maxDiffRatePercent,
      );
    } finally {
      // The page is reused across tests, so remove the element after taking the
      // golden screenshot.
      sceneElement.remove();
    }
  }

  setUp(() async {
    debugEmulateFlutterTesterEnvironment = true;
    disposeWebGl();
    await webOnlyInitializePlatform();
    webOnlyFontCollection.debugRegisterTestFonts();
    await webOnlyFontCollection.ensureFontsLoaded();
  });

  Future<void> _testVertices(
      String fileName, Vertices vertices, BlendMode blendMode, Paint paint,
      {bool write: false}) async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 500, 500));
    rc.drawVertices(
        vertices as SurfaceVertices, blendMode, paint as SurfacePaint);
    await _checkScreenshot(rc, fileName, write: write);
  }

  test('Should draw green hairline triangles when colors array is null.',
      () async {
    final Vertices vertices = Vertices.raw(
        VertexMode.triangles,
        Float32List.fromList([
          20.0,
          20.0,
          220.0,
          10.0,
          110.0,
          220.0,
          220.0,
          320.0,
          20.0,
          310.0,
          200.0,
          420.0
        ]));
    await _testVertices('draw_vertices_hairline_triangle', vertices,
        BlendMode.srcOver, Paint()..color = Color.fromARGB(255, 0, 128, 0));
  });

  test(
      'Should draw black hairline triangles when colors array is null'
      ' and Paint() has no color.', () async {
    // ignore: unused_local_variable
    final Int32List colors = Int32List.fromList(<int>[
      0xFFFF0000,
      0xFF00FF00,
      0xFF0000FF,
      0xFFFF0000,
      0xFF00FF00,
      0xFF0000FF,
      0xFFFF0000,
      0xFF00FF00,
      0xFF0000FF,
      0xFFFF0000,
      0xFF00FF00,
      0xFF0000FF
    ]);
    final Vertices vertices = Vertices.raw(
        VertexMode.triangles,
        Float32List.fromList([
          20.0,
          20.0,
          220.0,
          10.0,
          110.0,
          220.0,
          220.0,
          320.0,
          20.0,
          310.0,
          200.0,
          420.0
        ]));
    await _testVertices('draw_vertices_hairline_triangle_black', vertices,
        BlendMode.srcOver, Paint());
  });

  /// Regression test for https://github.com/flutter/flutter/issues/71442.
  test(
      'Should draw filled triangles when colors array is null'
      ' and Paint() has color.', () async {
    // ignore: unused_local_variable
    final Int32List colors = Int32List.fromList(<int>[
      0xFFFF0000,
      0xFF00FF00,
      0xFF0000FF,
      0xFFFF0000,
      0xFF00FF00,
      0xFF0000FF,
      0xFFFF0000,
      0xFF00FF00,
      0xFF0000FF,
      0xFFFF0000,
      0xFF00FF00,
      0xFF0000FF
    ]);
    final Vertices vertices = Vertices.raw(
        VertexMode.triangles,
        Float32List.fromList([
          20.0,
          20.0,
          220.0,
          10.0,
          110.0,
          220.0,
          220.0,
          320.0,
          20.0,
          310.0,
          200.0,
          420.0
        ]));
    await _testVertices(
        'draw_vertices_triangle_green_filled',
        vertices,
        BlendMode.srcOver,
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xFF00FF00));
  });

  test('Should draw hairline triangleFan.', () async {
    final Vertices vertices = Vertices.raw(
        VertexMode.triangleFan,
        Float32List.fromList([
          150.0,
          150.0,
          20.0,
          10.0,
          80.0,
          20.0,
          220.0,
          15.0,
          280.0,
          30.0,
          300.0,
          420.0
        ]));

    await _testVertices('draw_vertices_hairline_triangle_fan', vertices,
        BlendMode.srcOver, Paint()..color = Color.fromARGB(255, 0, 128, 0));
  });

  test('Should draw hairline triangleStrip.', () async {
    final Vertices vertices = Vertices.raw(
        VertexMode.triangleStrip,
        Float32List.fromList([
          20.0,
          20.0,
          220.0,
          10.0,
          110.0,
          220.0,
          220.0,
          320.0,
          20.0,
          310.0,
          200.0,
          420.0
        ]));
    await _testVertices('draw_vertices_hairline_triangle_strip', vertices,
        BlendMode.srcOver, Paint()..color = Color.fromARGB(255, 0, 128, 0));
  });

  test('Should draw triangles with colors.', () async {
    final Int32List colors = Int32List.fromList(<int>[
      0xFFFF0000,
      0xFF00FF00,
      0xFF0000FF,
      0xFFFF0000,
      0xFF00FF00,
      0xFF0000FF
    ]);
    final Vertices vertices = Vertices.raw(
        VertexMode.triangles,
        Float32List.fromList([
          150.0,
          150.0,
          20.0,
          10.0,
          80.0,
          20.0,
          220.0,
          15.0,
          280.0,
          30.0,
          300.0,
          420.0
        ]),
        colors: colors);

    await _testVertices('draw_vertices_triangles', vertices, BlendMode.srcOver,
        Paint()..color = Color.fromARGB(255, 0, 128, 0));
  });

  test('Should draw triangles with colors and indices.', () async {
    final Int32List colors = Int32List.fromList(
        <int>[0xFFFF0000, 0xFF00FF00, 0xFF0000FF, 0xFFFF0000, 0xFF0000FF]);
    final Uint16List indices = Uint16List.fromList(<int>[0, 1, 2, 3, 4, 0]);

    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 500, 500));

    final Vertices vertices = Vertices.raw(
        VertexMode.triangles,
        Float32List.fromList([
          210.0,
          150.0,
          30.0,
          110.0,
          80.0,
          30.0,
          220.0,
          15.0,
          280.0,
          30.0,
        ]),
        colors: colors,
        indices: indices);

    rc.drawVertices(
        vertices as SurfaceVertices, BlendMode.srcOver, SurfacePaint());

    await _checkScreenshot(rc, 'draw_vertices_triangles_indexed');
  });

  test('Should draw triangleFan with colors.', () async {
    final Int32List colors = Int32List.fromList(<int>[
      0xFFFF0000,
      0xFF00FF00,
      0xFF0000FF,
      0xFFFF0000,
      0xFF00FF00,
      0xFF0000FF
    ]);
    final Vertices vertices = Vertices.raw(
        VertexMode.triangleFan,
        Float32List.fromList([
          150.0,
          150.0,
          20.0,
          10.0,
          80.0,
          20.0,
          220.0,
          15.0,
          280.0,
          30.0,
          300.0,
          420.0
        ]),
        colors: colors);

    await _testVertices('draw_vertices_triangle_fan', vertices,
        BlendMode.srcOver, Paint()..color = Color.fromARGB(255, 0, 128, 0));
  });

  test('Should draw triangleStrip with colors.', () async {
    final Int32List colors = Int32List.fromList(<int>[
      0xFFFF0000,
      0xFF00FF00,
      0xFF0000FF,
      0xFFFF0000,
      0xFF00FF00,
      0xFF0000FF
    ]);
    final Vertices vertices = Vertices.raw(
        VertexMode.triangleStrip,
        Float32List.fromList([
          20.0,
          20.0,
          220.0,
          10.0,
          110.0,
          220.0,
          220.0,
          320.0,
          20.0,
          310.0,
          200.0,
          420.0
        ]),
        colors: colors);
    await _testVertices('draw_vertices_triangle_strip', vertices,
        BlendMode.srcOver, Paint()..color = Color.fromARGB(255, 0, 128, 0));
  });

  Future<void> testTexture(TileMode tileMode, String filename) async {
    final Uint16List indices = Uint16List.fromList(<int>[0, 1, 2, 3, 4, 0]);

    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 500, 500));

    final Vertices vertices = Vertices.raw(
        VertexMode.triangles,
        Float32List.fromList([
          210.0,
          150.0,
          0.0,
          0.0,
          80.0,
          30.0,
          220.0,
          15.0,
          280.0,
          30.0,
        ]),
        indices: indices);

    Float32List matrix4 = Matrix4.identity().storage;

    final HtmlImage img = await createTestImage();
    final SurfacePaint paint = SurfacePaint();

    final EngineImageShader imgShader = EngineImageShader(img, tileMode, tileMode,
        Float64List.fromList(matrix4), FilterQuality.high);

    paint.shader = imgShader;

    rc.drawVertices(vertices as SurfaceVertices, BlendMode.srcOver, paint);
    await _checkScreenshot(rc, filename, maxDiffRatePercent: 1.0);
  }

  test('Should draw triangle with texture and indices', () async {
    await testTexture(TileMode.clamp, 'draw_vertices_texture');
  });

  test('Should draw triangle with texture and indices', () async {
    await testTexture(TileMode.mirror, 'draw_vertices_texture_mirror');
  });

  test('Should draw triangle with texture and indices', () async {
    await testTexture(TileMode.repeated, 'draw_vertices_texture_repeated');
  });
}

Future<HtmlImage> createTestImage({int width = 50, int height = 40}) {
  html.CanvasElement canvas =
      new html.CanvasElement(width: width, height: height);
  html.CanvasRenderingContext2D ctx = canvas.context2D;
  ctx.fillStyle = '#E04040';
  ctx.fillRect(0, 0, width / 3, height);
  ctx.fill();
  ctx.fillStyle = '#40E080';
  ctx.fillRect(width / 3, 0, width / 3, height);
  ctx.fill();
  ctx.fillStyle = '#2040E0';
  ctx.fillRect(2 * width / 3, 0, width / 3, height);
  ctx.fill();
  html.ImageElement imageElement = html.ImageElement();
  Completer<HtmlImage> completer = Completer();
  imageElement.onLoad.listen((event) {
    completer.complete(HtmlImage(imageElement, width, height));
  });
  imageElement.src = js_util.callMethod(canvas, 'toDataURL', <dynamic>[]);
  return completer.future;
}
