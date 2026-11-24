// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

typedef _Rgba = ({int r, int g, int b, int a});

const _Rgba _green = (r: 0, g: 255, b: 0, a: 255);
const _Rgba _red = (r: 255, g: 0, b: 0, a: 255);
const _Rgba _blue = (r: 0, g: 0, b: 255, a: 255);

ui.Color _toColor(_Rgba rgba) => ui.Color.fromARGB(rgba.a, rgba.r, rgba.g, rgba.b);

/// The color that fills the whole view.
const _Rgba _baseColor = _green;

/// The color of a 10x10 marker in the bottom-right corner of the view.
///
/// If a view's bitmap is rendered at the wrong size and then stretched or
/// cropped to fit the view, the marker won't be in the bottom-right corner.
const _Rgba _markerColor = _red;

void testMain() {
  group('Multi-view sizing', () {
    setUpUnitTests(withImplicitView: true);

    final hosts = <DomElement>[];
    final views = <EngineFlutterView>[];

    setUp(() {
      // Keep logical and physical pixels the same so that sizes and pixel
      // coordinates in the expectations are easy to reason about.
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);
    });

    tearDown(() {
      for (final view in views) {
        EnginePlatformDispatcher.instance.viewManager.disposeAndUnregisterView(view.viewId);
      }
      views.clear();
      for (final host in hosts) {
        host.remove();
      }
      hosts.clear();
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(null);
    });

    EngineFlutterView createView(int width, int height) {
      final DomElement host = createDomElement('flt-test-view-host');
      host.style
        ..width = '${width}px'
        ..height = '${height}px'
        ..display = 'block';
      domDocument.body!.append(host);
      hosts.add(host);
      final view = EngineFlutterView(EnginePlatformDispatcher.instance, host);
      EnginePlatformDispatcher.instance.viewManager.registerView(view);
      views.add(view);
      return view;
    }

    Future<void> render(EngineFlutterView view) {
      return renderer.renderScene(
        _createMarkedScene(view.physicalSize),
        view,
        size: view.physicalSize,
      );
    }

    test('FlutterView.render uses passed size when hostElement is narrower', () async {
      // Simulate a host container constrained by CSS (e.g. a 360px flex column)
      // while the framework renders larger scenes (680x260 and 960x260) via
      // viewConstraints.
      final EngineFlutterView mediumView = createView(360, 260);
      final EngineFlutterView expandedView = createView(360, 260);

      const mediumSize = ui.Size(680, 260);
      const expandedSize = ui.Size(960, 260);

      final EnginePlatformDispatcher dispatcher = EnginePlatformDispatcher.instance;
      final ui.VoidCallback? previousOnDrawFrame = dispatcher.onDrawFrame;
      addTearDown(() => dispatcher.onDrawFrame = previousOnDrawFrame);

      dispatcher.onDrawFrame = () {
        mediumView.render(_createMarkedScene(mediumSize), size: mediumSize);
        expandedView.render(_createMarkedScene(expandedSize), size: expandedSize);
      };
      dispatcher.invokeOnDrawFrame();

      await Future.wait(<Future<void>>[
        ?renderer.rasterizers[mediumView.viewId]!.queue.current?.completer.future,
        ?renderer.rasterizers[expandedView.viewId]!.queue.current?.completer.future,
      ]);

      // The host elements remain 360x260, so view.physicalSize remains 360x260,
      // while the canvases and root elements match the rendered frame sizes.
      expect(mediumView.physicalSize, const ui.Size(360, 260));
      expect(expandedView.physicalSize, const ui.Size(360, 260));
      expect(mediumView.dom.rootElement.style.width, '680px');
      expect(expandedView.dom.rootElement.style.width, '960px');

      _expectViewRendered(mediumView, 680, 260);
      _expectViewRendered(expandedView, 960, 260);
    });

    test('FlutterView.render falls back to physicalSize when size is omitted', () async {
      final EngineFlutterView view = createView(360, 260);

      final EnginePlatformDispatcher dispatcher = EnginePlatformDispatcher.instance;
      final ui.VoidCallback? previousOnDrawFrame = dispatcher.onDrawFrame;
      addTearDown(() => dispatcher.onDrawFrame = previousOnDrawFrame);

      dispatcher.onDrawFrame = () {
        view.render(_createMarkedScene(const ui.Size(360, 260)));
      };
      dispatcher.invokeOnDrawFrame();

      await renderer.rasterizers[view.viewId]!.queue.current?.completer.future;

      _expectViewRendered(view, 360, 260);
    });

    test('FlutterView.render skips sub-pixel size that rounds to 0 without failing', () async {
      final EngineFlutterView view = createView(360, 260);
      final CkOffscreenSurface? ckSurface = switch (renderer.rasterizer) {
        OffscreenCanvasRasterizer(offscreenSurface: final CkOffscreenSurface s) => s,
        _ => null,
      };
      if (ckSurface != null) {
        await ckSurface.initialized;
      }
      final bool? supportedWebGlBefore = ckSurface?.supportsWebGl;

      const subPixelSize = ui.Size(360, 0.2);
      const finalSize = ui.Size(360, 260);

      final EnginePlatformDispatcher dispatcher = EnginePlatformDispatcher.instance;
      final ui.VoidCallback? previousOnDrawFrame = dispatcher.onDrawFrame;
      addTearDown(() => dispatcher.onDrawFrame = previousOnDrawFrame);

      dispatcher.onDrawFrame = () {
        view.render(_createMarkedScene(subPixelSize), size: subPixelSize);
      };
      dispatcher.invokeOnDrawFrame();
      await renderer.rasterizers[view.viewId]!.queue.current?.completer.future;

      dispatcher.onDrawFrame = () {
        view.render(_createMarkedScene(finalSize), size: finalSize);
      };
      dispatcher.invokeOnDrawFrame();
      await renderer.rasterizers[view.viewId]!.queue.current?.completer.future;

      expect(ckSurface?.supportsWebGl, supportedWebGlBefore);
      _expectViewRendered(view, 360, 260);
    });

    test('queued renderScene requests each use their own size', () async {
      final EngineFlutterView view = createView(360, 260);

      const firstSize = ui.Size(400, 200);
      const droppedSize = ui.Size(500, 220);
      const finalSize = ui.Size(680, 260);

      // Enqueue three scenes in the same turn so the first runs, the second is
      // replaced in `queue.next`, and the third renders at `finalSize`.
      await Future.wait(<Future<void>>[
        renderer.renderScene(_createMarkedScene(firstSize), view, size: firstSize),
        renderer.renderScene(_createMarkedScene(droppedSize), view, size: droppedSize),
        renderer.renderScene(_createMarkedScene(finalSize), view, size: finalSize),
      ]);

      _expectViewRendered(view, 680, 260);
    });

    test('3 views of different sizes rendered in the same turn', () async {
      final EngineFlutterView view1 = createView(100, 100);
      final EngineFlutterView view2 = createView(200, 50);
      final EngineFlutterView view3 = createView(50, 300);

      // Render all views in the same turn without awaiting in between, so their
      // frames are in flight at the same time.
      await Future.wait(<Future<void>>[render(view1), render(view2), render(view3)]);

      _expectViewRendered(view1, 100, 100);
      _expectViewRendered(view2, 200, 50);
      _expectViewRendered(view3, 50, 300);
    });

    test('many rounds of frames in different view orders', () async {
      final viewList = <EngineFlutterView>[
        createView(120, 80),
        createView(60, 140),
        createView(200, 30),
      ];

      // Each view keeps at most one pending frame, so render one round at a
      // time. Within a round, all views render concurrently, and the order in
      // which they start changes from round to round.
      const orders = <List<int>>[
        <int>[0, 1, 2],
        <int>[2, 1, 0],
        <int>[1, 2, 0],
        <int>[0, 2, 1],
        <int>[2, 0, 1],
      ];
      for (final order in orders) {
        await Future.wait(<Future<void>>[for (final index in order) render(viewList[index])]);

        _expectViewRendered(viewList[0], 120, 80);
        _expectViewRendered(viewList[1], 60, 140);
        _expectViewRendered(viewList[2], 200, 30);
      }
    });

    test('3 views of different sizes without createImageBitmap support', () async {
      if (renderer is! CanvasKitRenderer || renderer.rasterizer is! OffscreenCanvasRasterizer) {
        markTestSkipped('Only CanvasKit with a shared offscreen surface supports this path.');
        return;
      }
      debugDisableCreateImageBitmapSupport = true;
      addTearDown(() => debugDisableCreateImageBitmapSupport = false);

      final EngineFlutterView view1 = createView(100, 100);
      final EngineFlutterView view2 = createView(200, 50);
      final EngineFlutterView view3 = createView(50, 300);

      await Future.wait(<Future<void>>[render(view1), render(view2), render(view3)]);

      _expectViewRendered(view1, 100, 100);
      _expectViewRendered(view2, 200, 50);
      _expectViewRendered(view3, 50, 300);
    });

    test('Image.toByteData is not affected by frames rendered at the same time', () async {
      final EngineFlutterView view1 = createView(100, 100);
      final EngineFlutterView view2 = createView(200, 50);

      final ui.Image image = await _createSolidPicture(30, 20, _blue).toImage(30, 20);

      // On some renderers, these operations share a single offscreen surface.
      // Interleave them so that, if resizing and rendering weren't atomic, they
      // would resize the surface under each other.
      final Future<void> render1 = render(view1);
      final Future<ByteData?> pngFuture = image.toByteData(format: ui.ImageByteFormat.png);
      final Future<void> render2 = render(view2);
      final Future<ByteData?> rawFuture = image.toByteData();
      await Future.wait(<Future<void>>[render1, render2]);
      final ByteData png = (await pngFuture)!;
      final ByteData raw = (await rawFuture)!;

      // The width and height of a PNG are the first two fields of the IHDR
      // chunk, stored as big-endian 32-bit integers at offsets 16 and 20.
      expect(png.getUint32(16), 30);
      expect(png.getUint32(20), 20);

      expect(raw.lengthInBytes, 30 * 20 * 4);
      _expectRgba(raw, 0, _blue);
      _expectRgba(raw, raw.lengthInBytes - 4, _blue);

      _expectViewRendered(view1, 100, 100);
      _expectViewRendered(view2, 200, 50);

      image.dispose();
    });

    test('concurrent OffscreenSurface.rasterizeToImageBitmaps calls get their own sizes', () async {
      final Rasterizer rasterizer = renderer.rasterizer;
      if (rasterizer is! OffscreenCanvasRasterizer) {
        markTestSkipped('Only applies to renderers that use a shared offscreen surface.');
        return;
      }
      final OffscreenSurface surface = rasterizer.offscreenSurface;
      await surface.initialized;

      // Don't await in between, so that all requests are in flight at once.
      final List<List<DomImageBitmap>> results = await Future.wait(<Future<List<DomImageBitmap>>>[
        surface.rasterizeToImageBitmaps(const BitmapSize(10, 20), <ui.Picture>[
          _createMarkedPicture(const ui.Size(10, 20)),
        ]),
        surface.rasterizeToImageBitmaps(const BitmapSize(40, 30), <ui.Picture>[
          _createMarkedPicture(const ui.Size(40, 30)),
        ]),
        surface.rasterizeToImageBitmaps(const BitmapSize(25, 15), <ui.Picture>[
          _createMarkedPicture(const ui.Size(25, 15)),
        ]),
      ]);

      _expectMarkedBitmap(results[0].single, 10, 20);
      _expectMarkedBitmap(results[1].single, 40, 30);
      _expectMarkedBitmap(results[2].single, 25, 15);
    });

    test('OffscreenSurface.rasterizeToImageBitmaps captures each picture separately', () async {
      final Rasterizer rasterizer = renderer.rasterizer;
      if (rasterizer is! OffscreenCanvasRasterizer) {
        markTestSkipped('Only applies to renderers that use a shared offscreen surface.');
        return;
      }
      final OffscreenSurface surface = rasterizer.offscreenSurface;
      await surface.initialized;

      final List<DomImageBitmap> bitmaps = await surface.rasterizeToImageBitmaps(
        const BitmapSize(10, 10),
        <ui.Picture>[
          _createSolidPicture(10, 10, _red),
          _createSolidPicture(10, 10, _green),
          _createSolidPicture(10, 10, _blue),
        ],
      );

      expect(bitmaps, hasLength(3));
      _expectPixel(bitmaps[0], 10, 10, 5, 5, _red);
      _expectPixel(bitmaps[1], 10, 10, 5, 5, _green);
      _expectPixel(bitmaps[2], 10, 10, 5, 5, _blue);
    });
  });
}

ui.Picture _createSolidPicture(int width, int height, _Rgba color) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = _toColor(color),
  );
  return recorder.endRecording();
}

/// Creates a picture of [size] filled with [_baseColor], with a 10x10
/// [_markerColor] square in the bottom-right corner.
ui.Picture _createMarkedPicture(ui.Size size) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, ui.Offset.zero & size);
  canvas.drawRect(ui.Offset.zero & size, ui.Paint()..color = _toColor(_baseColor));
  canvas.drawRect(
    ui.Rect.fromLTWH(size.width - 10, size.height - 10, 10, 10),
    ui.Paint()..color = _toColor(_markerColor),
  );
  return recorder.endRecording();
}

ui.Scene _createMarkedScene(ui.Size size) {
  final builder = ui.SceneBuilder();
  builder.addPicture(ui.Offset.zero, _createMarkedPicture(size));
  return builder.build();
}

/// Expects the on-screen canvas of [view] to be exactly [width]x[height] and,
/// where its pixels can be read back, to contain the marked picture unscaled.
void _expectViewRendered(EngineFlutterView view, int width, int height) {
  final canvas = view.dom.renderingHost.querySelector('canvas')! as DomHTMLCanvasElement;
  expect(canvas.width, width, reason: 'Canvas width of view ${view.viewId}');
  expect(canvas.height, height, reason: 'Canvas height of view ${view.viewId}');

  // Only canvases filled with `transferFromImageBitmap` keep their contents
  // after the frame. WebGL canvases (used by `MultiSurfaceRasterizer`) may be
  // cleared once composited, so their pixels can't be checked reliably here.
  if (renderer.rasterizer is OffscreenCanvasRasterizer) {
    _expectMarkedPixels(canvas, width, height);
  }
}

void _expectMarkedBitmap(DomImageBitmap bitmap, int width, int height) {
  expect(bitmap.width, width);
  expect(bitmap.height, height);
  _expectMarkedPixels(bitmap, width, height);
}

void _expectMarkedPixels(DomCanvasImageSource source, int width, int height) {
  _expectPixel(source, width, height, 1, 1, _baseColor);
  _expectPixel(source, width, height, width - 1, height - 1, _markerColor);
}

void _expectPixel(DomCanvasImageSource source, int width, int height, int x, int y, _Rgba color) {
  final DomHTMLCanvasElement sampler = createDomCanvasElement(width: width, height: height);
  final DomCanvasRenderingContext2D context = sampler.context2D;
  context.drawImage(source, 0, 0);
  final Uint8ClampedList pixel = context.getImageData(x, y, 1, 1).data;
  expect(
    (r: pixel[0], g: pixel[1], b: pixel[2], a: pixel[3]),
    color,
    reason: 'Pixel at ($x, $y) of a ${width}x$height image',
  );
}

void _expectRgba(ByteData data, int offset, _Rgba color) {
  expect((
    r: data.getUint8(offset),
    g: data.getUint8(offset + 1),
    b: data.getUint8(offset + 2),
    a: data.getUint8(offset + 3),
  ), color);
}
