// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

class TestRasterizer extends ViewRasterizer {
  TestRasterizer(super.view, this.displayFactory);

  @override
  final DisplayCanvasFactory<DisplayCanvas> displayFactory;

  Completer<void>? prepareCompleter;
  Completer<void>? rasterizeCompleter;

  @override
  Future<void> prepareToDraw() async {
    if (prepareCompleter != null) {
      await prepareCompleter!.future;
    }
  }

  @override
  Future<void> rasterize(
    List<DisplayCanvas> displayCanvases,
    List<ui.Picture> pictures,
    FrameTimingRecorder? recorder,
  ) async {
    if (rasterizeCompleter != null) {
      await rasterizeCompleter!.future;
    }
  }
}

class FakeDisplayCanvas extends DisplayCanvas {
  @override
  final DomElement hostElement = domDocument.createElement('div');
  @override
  bool get isConnected => true;
  @override
  void initialize() {}
  @override
  void dispose() {}
}

Future<void> _sendPlatformViewMessage(String method, dynamic args) {
  final completer = Completer<void>();
  const MethodCodec codec = StandardMethodCodec();
  ui.PlatformDispatcher.instance.sendPlatformMessage(
    'flutter/platform_views',
    codec.encodeMethodCall(MethodCall(method, args)),
    (dynamic _) => completer.complete(),
  );
  return completer.future;
}

// Sends a platform message to create a Platform View with the given id and viewType.
Future<void> createPlatformView(int id, String viewType) =>
    _sendPlatformViewMessage('create', <String, dynamic>{'id': id, 'viewType': viewType});

// Sends a platform message to dispose the Platform View with the given id.
Future<void> disposePlatformView(int id) => _sendPlatformViewMessage('dispose', id);

void testMain() {
  setUpUnitTests(withImplicitView: true);

  final warnings = <String>[];
  late void Function(String) originalPrintWarning;

  setUp(() {
    warnings.clear();
    originalPrintWarning = printWarning;
    printWarning = (String warning) => warnings.add(warning);
  });

  tearDown(() {
    printWarning = originalPrintWarning;
  });

  test('disposing platform view during prepareToDraw causes crash in submitFrame', () async {
    final EngineFlutterView view = EnginePlatformDispatcher.instance.implicitView!;
    final displayFactory = DisplayCanvasFactory<DisplayCanvas>(
      createCanvas: () => FakeDisplayCanvas(),
    );
    final rasterizer = TestRasterizer(view, displayFactory);

    const platformViewId = 123;
    ui_web.platformViewRegistry.registerViewFactory('test-type', (int id) {
      return domDocument.createElement('div');
    });
    await createPlatformView(platformViewId, 'test-type');

    final sb = ui.SceneBuilder();
    sb.addPlatformView(platformViewId, width: 100, height: 100);
    final ui.Scene scene = sb.build();

    rasterizer.prepareCompleter = Completer<void>();

    final Future<void> drawFuture = rasterizer.draw((scene as LayerScene).layerTree, null);

    // Now we are in the async gap of prepareToDraw.
    // Dispose the platform view.
    await disposePlatformView(platformViewId);

    // Complete the prepareToDraw.
    rasterizer.prepareCompleter!.complete();
    // This should NOT crash, but should log a warning.
    await drawFuture;

    expect(warnings, contains(contains('Cannot render platform views: 123')));
  });

  test('disposing platform view during rasterize causes crash in submitFrame', () async {
    final EngineFlutterView view = EnginePlatformDispatcher.instance.implicitView!;
    final displayFactory = DisplayCanvasFactory<DisplayCanvas>(
      createCanvas: () => FakeDisplayCanvas(),
    );
    final rasterizer = TestRasterizer(view, displayFactory);

    const platformViewId = 124;
    ui_web.platformViewRegistry.registerViewFactory('test-type-2', (int id) {
      return domDocument.createElement('div');
    });
    await createPlatformView(platformViewId, 'test-type-2');

    final sb = ui.SceneBuilder();
    sb.addPlatformView(platformViewId, width: 100, height: 100);
    final ui.Scene scene = sb.build();

    rasterizer.rasterizeCompleter = Completer<void>();

    final Future<void> drawFuture = rasterizer.draw((scene as LayerScene).layerTree, null);

    // Wait a bit to ensure we are in the rasterize gap.
    await Future<void>.delayed(Duration.zero);

    // Dispose the platform view.
    await disposePlatformView(platformViewId);

    // Complete the rasterize.
    rasterizer.rasterizeCompleter!.complete();

    // This should NOT crash, but should log a warning.
    await drawFuture;

    expect(warnings, contains(contains('Cannot render platform views: 124')));
  });
}
