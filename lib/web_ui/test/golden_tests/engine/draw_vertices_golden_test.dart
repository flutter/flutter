// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:ui/ui.dart' hide TextStyle;
import 'package:ui/src/engine.dart';
import 'package:test/test.dart';

import 'package:web_engine_tester/golden_tester.dart';

void main() async {
  const double screenWidth = 600.0;
  const double screenHeight = 800.0;
  const Rect screenRect = Rect.fromLTWH(0, 0, screenWidth, screenHeight);

  // Commit a recording canvas to a bitmap, and compare with the expected
  Future<void> _checkScreenshot(RecordingCanvas rc, String fileName,
      {Rect region = const Rect.fromLTWH(0, 0, 500, 500),
        bool write = false}) async {
    final EngineCanvas engineCanvas = BitmapCanvas(screenRect);
    rc.endRecording();
    rc.apply(engineCanvas, screenRect);

    // Wrap in <flt-scene> so that our CSS selectors kick in.
    final html.Element sceneElement = html.Element.tag('flt-scene');
    try {
      sceneElement.append(engineCanvas.rootElement);
      html.document.body.append(sceneElement);
      await matchGoldenFile(
        '$fileName.png',
        region: region,
        write: write,
        maxDiffRatePercent: 0.0,
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

  Future<void> _testVertices(String fileName, Vertices vertices,
      BlendMode blendMode,
      Paint paint) async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 500, 500));
    rc.drawVertices(vertices, blendMode, paint);
    await _checkScreenshot(rc, fileName);
  }

  test('Should draw green hairline triangles when colors array is null.',
          () async {
    final Vertices vertices = Vertices.raw(VertexMode.triangles,
        Float32List.fromList([
          20.0, 20.0, 220.0, 10.0, 110.0, 220.0,
          220.0, 320.0, 20.0, 310.0, 200.0, 420.0
        ]));
    await _testVertices(
        'draw_vertices_hairline_triangle',
        vertices,
        BlendMode.srcOver,
        Paint()..color = Color.fromARGB(255, 0, 128, 0));
  });

  test('Should draw black hairline triangles when colors array is null'
      ' and Paint() has no color.',
          () async {
    // ignore: unused_local_variable
    final Int32List colors = Int32List.fromList(<int>[
        0xFFFF0000, 0xFF00FF00, 0xFF0000FF,
        0xFFFF0000, 0xFF00FF00, 0xFF0000FF,
        0xFFFF0000, 0xFF00FF00, 0xFF0000FF,
        0xFFFF0000, 0xFF00FF00, 0xFF0000FF]);
    final Vertices vertices = Vertices.raw(VertexMode.triangles,
        Float32List.fromList([
          20.0, 20.0, 220.0, 10.0, 110.0, 220.0,
          220.0, 320.0, 20.0, 310.0, 200.0, 420.0
        ]));
    await _testVertices(
        'draw_vertices_hairline_triangle_black',
        vertices,
        BlendMode.srcOver,
        Paint());
  });

  test('Should draw hairline triangleFan.',
          () async {
    final Vertices vertices = Vertices.raw(VertexMode.triangleFan,
        Float32List.fromList([
          150.0, 150.0, 20.0, 10.0, 80.0, 20.0,
          220.0, 15.0, 280.0, 30.0, 300.0, 420.0
        ]));

    await _testVertices(
        'draw_vertices_hairline_triangle_fan',
        vertices,
        BlendMode.srcOver,
        Paint()..color = Color.fromARGB(255, 0, 128, 0));
  });

  test('Should draw hairline triangleStrip.',
          () async {
    final Vertices vertices = Vertices.raw(VertexMode.triangleStrip,
        Float32List.fromList([
          20.0, 20.0, 220.0, 10.0, 110.0, 220.0,
          220.0, 320.0, 20.0, 310.0, 200.0, 420.0
        ]));
    await _testVertices(
        'draw_vertices_hairline_triangle_strip',
        vertices,
        BlendMode.srcOver,
        Paint()..color = Color.fromARGB(255, 0, 128, 0));
  });

  test('Should draw triangles with colors.',
      () async {
    final Int32List colors = Int32List.fromList(<int>[
        0xFFFF0000, 0xFF00FF00, 0xFF0000FF,
        0xFFFF0000, 0xFF00FF00, 0xFF0000FF]);
    final Vertices vertices = Vertices.raw(VertexMode.triangles,
        Float32List.fromList([
          150.0, 150.0, 20.0, 10.0, 80.0, 20.0,
          220.0, 15.0, 280.0, 30.0, 300.0, 420.0
        ]), colors: colors);

    await _testVertices(
        'draw_vertices_triangles',
        vertices,
        BlendMode.srcOver,
        Paint()..color = Color.fromARGB(255, 0, 128, 0));
  });

  test('Should draw triangleFan with colors.',
      () async {
    final Int32List colors = Int32List.fromList(<int>[
        0xFFFF0000, 0xFF00FF00, 0xFF0000FF,
        0xFFFF0000, 0xFF00FF00, 0xFF0000FF]);
    final Vertices vertices = Vertices.raw(VertexMode.triangleFan,
        Float32List.fromList([
          150.0, 150.0, 20.0, 10.0, 80.0, 20.0,
          220.0, 15.0, 280.0, 30.0, 300.0, 420.0
        ]), colors: colors);

    await _testVertices(
        'draw_vertices_triangle_fan',
        vertices,
        BlendMode.srcOver,
        Paint()..color = Color.fromARGB(255, 0, 128, 0));
  });

  test('Should draw triangleStrip with colors.',
      () async {
    final Int32List colors = Int32List.fromList(<int>[
        0xFFFF0000, 0xFF00FF00, 0xFF0000FF,
        0xFFFF0000, 0xFF00FF00, 0xFF0000FF]);
    final Vertices vertices = Vertices.raw(VertexMode.triangleStrip,
        Float32List.fromList([
          20.0, 20.0, 220.0, 10.0, 110.0, 220.0,
          220.0, 320.0, 20.0, 310.0, 200.0, 420.0
        ]), colors: colors);
    await _testVertices(
        'draw_vertices_triangle_strip',
        vertices,
        BlendMode.srcOver,
        Paint()..color = Color.fromARGB(255, 0, 128, 0));
  });
}
