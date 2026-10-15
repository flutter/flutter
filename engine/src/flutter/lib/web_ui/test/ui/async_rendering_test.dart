// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

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

  test('first-frame browser event waits for the first frame to be rendered', () async {
    // Each dispatcher tracks only its own first frame, so this test brings its
    // own and drives its `onDrawFrame` directly, instead of going through the
    // singleton via `renderScene`, to stay independent of what ran before it.
    final ownDispatcher = EnginePlatformDispatcher();
    addTearDown(ownDispatcher.dispose);

    final EngineFlutterView view = EnginePlatformDispatcher.instance.implicitView!;
    final displayFactory = DisplayCanvasFactory<DisplayCanvas>(
      createCanvas: () => FakeDisplayCanvas(),
    );
    final testRasterizer = TestRasterizer(view, displayFactory)
      ..prepareCompleter = Completer<void>();
    final ViewRasterizer originalRasterizer = renderer.rasterizers[view.viewId]!;
    renderer.rasterizers[view.viewId] = testRasterizer;
    addTearDown(() => renderer.rasterizers[view.viewId] = originalRasterizer);

    var firstFrameEventCount = 0;
    final firstFrameEvent = Completer<void>();
    final DomEventListener listener = createDomEventListener((DomEvent event) {
      firstFrameEventCount++;
      if (!firstFrameEvent.isCompleted) {
        firstFrameEvent.complete();
      }
    });
    domWindow.addEventListener('flutter-first-frame', listener);
    addTearDown(() => domWindow.removeEventListener('flutter-first-frame', listener));

    // Wait for next frame.
    Future<void> waitForAnimationFrame() {
      final completer = Completer<void>();
      domWindow.requestAnimationFrame((_) {
        Timer.run(completer.complete);
      });
      return completer.future;
    }

    // `render` only draws anything in an `onDrawFrame` scope, so a frame is a
    // scene rendered from within `onDrawFrame`.
    Future<void> renderFrame() {
      final ui.Scene scene = ui.SceneBuilder().build();
      addTearDown(scene.dispose);
      late final Future<void> rendered;
      ownDispatcher.onDrawFrame = () {
        rendered = ownDispatcher.render(scene, view);
      };
      ownDispatcher.invokeOnDrawFrame();
      return rendered;
    }

    final Future<void> renderFuture = renderFrame();
    ownDispatcher.sendPlatformMessage(
      'flutter/service_worker',
      ByteData(0),
      (ByteData? response) {},
    );

    // The render is parked in `prepareToDraw`, so nothing is on screen yet. The
    // event is dispatched from an animation frame callback, so waiting for one
    // is enough to observe it if it were sent too early.
    await waitForAnimationFrame();
    expect(firstFrameEventCount, 0);

    testRasterizer.prepareCompleter!.complete();
    await renderFuture;
    await expectLater(firstFrameEvent.future, completes);

    // Renders requested by later frames are not tracked, and don't dispatch the
    // event again, no matter how many frames go by.
    await renderFrame();
    await waitForAnimationFrame();
    expect(firstFrameEventCount, 1);

    await renderFrame();
    await waitForAnimationFrame();
    expect(firstFrameEventCount, 1);
  });

  test('first-frame browser event is still sent if a first-frame render fails', () async {
    // Each dispatcher tracks only its own first frame, so this test brings its
    // own and drives its `onDrawFrame` directly instead of going through
    // `renderScene`, to stay independent of what ran before it.
    final ownDispatcher = EnginePlatformDispatcher();
    addTearDown(ownDispatcher.dispose);

    final EngineFlutterView view = EnginePlatformDispatcher.instance.implicitView!;
    final displayFactory = DisplayCanvasFactory<DisplayCanvas>(
      createCanvas: () => FakeDisplayCanvas(),
    );
    final testRasterizer = TestRasterizer(view, displayFactory)
      ..prepareCompleter = Completer<void>();
    final ViewRasterizer originalRasterizer = renderer.rasterizers[view.viewId]!;
    renderer.rasterizers[view.viewId] = testRasterizer;
    addTearDown(() => renderer.rasterizers[view.viewId] = originalRasterizer);

    var firstFrameEventCount = 0;
    final firstFrameEvent = Completer<void>();
    final DomEventListener listener = createDomEventListener((DomEvent event) {
      firstFrameEventCount++;
      if (!firstFrameEvent.isCompleted) {
        firstFrameEvent.complete();
      }
    });
    domWindow.addEventListener('flutter-first-frame', listener);
    addTearDown(() => domWindow.removeEventListener('flutter-first-frame', listener));

    // Wait for next frame.
    Future<void> waitForAnimationFrame() {
      final completer = Completer<void>();
      domWindow.requestAnimationFrame((_) {
        Timer.run(completer.complete);
      });
      return completer.future;
    }

    final ui.Scene scene = ui.SceneBuilder().build();
    addTearDown(scene.dispose);
    late final Future<void> renderFuture;
    ownDispatcher.onDrawFrame = () {
      renderFuture = ownDispatcher.render(scene, view);
    };
    ownDispatcher.invokeOnDrawFrame();
    ownDispatcher.sendPlatformMessage(
      'flutter/service_worker',
      ByteData(0),
      (ByteData? response) {},
    );

    // The render is parked in `prepareToDraw`, so the first frame is not
    // settled yet and the event is withheld.
    await waitForAnimationFrame();
    expect(firstFrameEventCount, 0);

    // Failing the render settles the first frame too: `render` reports the
    // failure to its caller, and the event still goes out, so an app hiding its
    // loading screen on the event is not stuck on a failed frame.
    testRasterizer.prepareCompleter!.completeError(StateError('render failed'));
    await expectLater(renderFuture, throwsStateError);
    await expectLater(firstFrameEvent.future, completes);
    await waitForAnimationFrame();
    expect(firstFrameEventCount, 1);
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
