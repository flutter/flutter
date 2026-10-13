// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';
import '../common/texture_shader.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  setUpUnitTests();
  late HybridCanvasRasterizer rasterizer;
  late _ExportSurface export;
  late _OnscreenSurface direct;
  late _View first;
  var publishDirect = true;
  Duration nativeCallbackDelay = Duration.zero;
  Duration readbackDelay = Duration.zero;

  setUp(() {
    EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1);
    publishDirect = true;
    nativeCallbackDelay = Duration.zero;
    readbackDelay = Duration.zero;
    rasterizer = HybridCanvasRasterizer(
      (OnscreenCanvasProvider provider) =>
          direct = _OnscreenSurface(SkwasmSurface.onscreen(provider))
            ..published = publishDirect
            ..completionDelay = nativeCallbackDelay
            ..readbackDelay = readbackDelay,
      (OffscreenCanvasProvider provider) => export = _ExportSurface(SkwasmSurface(provider)),
    );
    first = _View(rasterizer);
    PlatformViewManager.instance.registerFactory(
      'hybrid-test',
      (int id) => createDomHTMLDivElement(),
    );
    PlatformViewManager.instance.renderContent('hybrid-test', 1, null);
  });

  tearDown(() async {
    first.dispose();
    rasterizer.dispose();
    await Future<void>.delayed(Duration.zero);
    PlatformViewManager.instance.debugClear();
    EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(3);
  });

  test('preserves direct pixels and DOM until all exit layers are ready', () async {
    for (var cycle = 0; cycle < 12; cycle++) {
      await first.draw(10 + cycle);
      expect(first.rasterizer.debugIsDirect, isTrue);
      final OnscreenSurface direct = first.rasterizer.debugDirectSurface!;
      final source = direct.canvasImageSource as DomHTMLCanvasElement;
      final List<int> oldPixel = _pixel(source);
      final num? oldWidth = source.width;
      final String oldCssWidth = source.style.width;
      final int context = direct.glContext;
      final List<DomElement> oldChildren = first.rasterizer.sceneElement.children.toList();

      export.hold();
      first.resize(cycle.isEven ? const ui.Size(80, 60) : const ui.Size(64, 48));
      final Future<void> exit = first.draw(100 + cycle, overlay: true);
      await export.reached.future.timeout(const Duration(seconds: 5));
      expect(first.rasterizer.debugIsDirect, isTrue);
      expect(first.rasterizer.sceneElement.children, orderedEquals(oldChildren));
      expect(source.isConnected, isTrue);
      expect(source.width, oldWidth);
      expect(source.style.width, oldCssWidth);
      expect(direct.glContext, context);
      expect(_pixel(source), oldPixel);
      export.release();
      await exit;
      expect(first.rasterizer.debugIsDirect, isFalse);
      expect(first.canvases, hasLength(2));
      expect(_pixel(first.canvases.first.canvasElement), <int>[100 + cycle, 0, 0, 255]);
      expect(_pixel(first.canvases.last.canvasElement, x: 10, y: 10), <int>[255, 0, 255, 128]);
      expect(direct.glContext, context);
    }
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('shares bitmap export safely across views of different sizes', () async {
    await first.draw(1);
    final second = _View(rasterizer)..resize(const ui.Size(96, 72));
    try {
      await Future.wait<void>(<Future<void>>[first.draw(2), second.draw(3)]);
      expect(first.rasterizer.debugIsDirect, isFalse);
      expect(second.rasterizer.debugIsDirect, isFalse);
      expect(first.canvases.single.canvasElement.width, 64);
      expect(second.canvases.single.canvasElement.width, 96);
      expect(_pixel(first.canvases.single.canvasElement), <int>[2, 0, 0, 255]);
      expect(_pixel(second.canvases.single.canvasElement), <int>[3, 0, 0, 255]);
    } finally {
      second.dispose();
    }
    await first.draw(4);
    expect(first.rasterizer.debugIsDirect, isTrue);
  });

  for (final sourceKind in <String>['ImageBitmap', 'HTMLCanvasElement', 'VideoFrame']) {
    test('$sourceKind survives transitions, multiple views, and context loss', () async {
      final ui.Image image = await _textureImage(sourceKind);
      void paint(ui.Canvas canvas) => canvas.drawImageRect(
        image,
        const ui.Rect.fromLTWH(0, 0, 4, 4),
        const ui.Rect.fromLTWH(0, 0, 32, 32),
        ui.Paint(),
      );
      try {
        for (var cycle = 0; cycle < 3; cycle++) {
          await first.draw(1, paint: paint);
          expect(first.rasterizer.debugIsDirect, isTrue);
          _expectTexture(first.canvases.single.canvasElement);
          await first.draw(2, overlay: true, paint: paint);
          expect(first.rasterizer.debugIsDirect, isFalse);
          _expectTexture(first.canvases.first.canvasElement);
        }

        await export.triggerContextLoss();
        await export.handledContextLossEvent;
        await export.initialized;
        await first.draw(3, overlay: true, paint: paint);
        _expectTexture(first.canvases.first.canvasElement);

        final second = _View(rasterizer)..resize(const ui.Size(96, 72));
        try {
          await Future.wait<void>(<Future<void>>[
            first.draw(3, paint: paint),
            second.draw(4, paint: paint),
          ]);
          _expectTexture(first.canvases.single.canvasElement);
          _expectTexture(second.canvases.single.canvasElement);
        } finally {
          second.dispose();
        }

        await first.draw(5, paint: paint);
        expect(first.rasterizer.debugIsDirect, isTrue);
        final OnscreenSurface surface = first.rasterizer.debugDirectSurface!;
        await surface.triggerContextLoss();
        await surface.handledContextLossEvent;
        await surface.initialized;
        await first.draw(6, paint: paint);
        expect(first.rasterizer.debugIsDirect, isFalse);
        _expectTexture(first.canvases.single.canvasElement);
        await first.draw(7, paint: paint);
        expect(first.rasterizer.debugIsDirect, isTrue);
        _expectTexture(first.canvases.single.canvasElement);
      } finally {
        image.dispose();
      }
    }, timeout: const Timeout(Duration(seconds: 30)));
  }

  test('pending pictures retain a texture after its image is disposed', () async {
    await first.draw(1);
    final ui.Image image = await _textureImage('ImageBitmap');
    export.hold();
    final Future<void> pending = first.draw(
      2,
      overlay: true,
      paint: (ui.Canvas canvas) => canvas.drawImageRect(
        image,
        const ui.Rect.fromLTWH(0, 0, 4, 4),
        const ui.Rect.fromLTWH(0, 0, 32, 32),
        ui.Paint(),
      ),
    );
    await export.reached.future.timeout(const Duration(seconds: 5));
    image.dispose();
    export.release();
    await pending;
    _expectTexture(first.canvases.first.canvasElement);
  });

  test(
    'fragment shader samplers survive transitions and context loss',
    () async {
      final ui.Image image = await _textureImage('ImageBitmap');
      final program = SkwasmFragmentProgram.fromBytes(
        'hybrid-texture',
        utf8.encode(kTextureShaderSksl),
      );
      final ui.FragmentShader shader = program.fragmentShader()
        ..setFloat(0, 32)
        ..setFloat(1, 32)
        ..setImageSampler(0, image);
      void paint(ui.Canvas canvas) =>
          canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 32, 32), ui.Paint()..shader = shader);
      try {
        for (var cycle = 0; cycle < 3; cycle++) {
          await first.draw(1, paint: paint);
          expect(first.rasterizer.debugIsDirect, isTrue);
          _expectTexture(first.canvases.single.canvasElement);
          await first.draw(2, overlay: true, paint: paint);
          expect(first.rasterizer.debugIsDirect, isFalse);
          _expectTexture(first.canvases.first.canvasElement);
        }
        final OnscreenSurface surface = first.rasterizer.debugDirectSurface!;
        await surface.triggerContextLoss();
        await surface.handledContextLossEvent;
        await surface.initialized;
        await first.draw(3, paint: paint);
        expect(first.rasterizer.debugIsDirect, isTrue);
        _expectTexture(first.canvases.single.canvasElement);
      } finally {
        shader.dispose();
        image.dispose();
        program.dispose();
      }
    },
    skip: (renderer as SkwasmRenderer).isWimp,
    timeout: const Timeout(Duration(seconds: 30)),
  ); // https://github.com/flutter/flutter/issues/175431

  test('a failed export preserves the active frame and permits another draw', () async {
    await first.draw(1);
    final OnscreenSurface surface = first.rasterizer.debugDirectSurface!;
    final List<DomElement> children = first.rasterizer.sceneElement.children.toList();
    export.failNextExport = true;
    await expectLater(first.draw(2, overlay: true), throwsStateError);
    expect(first.rasterizer.debugIsDirect, isTrue);
    expect(first.rasterizer.sceneElement.children, orderedEquals(children));
    expect(_pixel(surface.canvasImageSource as DomHTMLCanvasElement), <int>[1, 0, 0, 255]);
    await first.draw(3, overlay: true);
    expect(first.rasterizer.debugIsDirect, isFalse);
    expect(first.canvases, hasLength(2));
    expect(_pixel(first.canvases.first.canvasElement), <int>[3, 0, 0, 255]);
    await first.draw(4);
    expect(first.rasterizer.debugIsDirect, isTrue);
  });

  test('updates DPR without resizing the visible direct surface during export', () async {
    await first.draw(1);
    final source = first.rasterizer.debugDirectSurface!.canvasImageSource as DomHTMLCanvasElement;
    expect(source.style.width, '64px');
    EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(2);
    export.hold();
    final Future<void> resized = first.draw(2);
    await export.reached.future.timeout(const Duration(seconds: 5));
    expect(source.style.width, '64px');
    export.release();
    await resized;
    expect(first.rasterizer.debugIsDirect, isFalse);
    expect(first.canvases.single.canvasElement.style.width, '32px');
    await first.draw(3);
    expect(first.rasterizer.debugIsDirect, isTrue);
    expect(source.style.width, '32px');
  });

  test('recovers presentation after context loss', () async {
    await first.draw(1);
    final OnscreenSurface surface = first.rasterizer.debugDirectSurface!;
    final int context = surface.glContext;
    await surface.triggerContextLoss();
    await surface.handledContextLossEvent;
    await surface.initialized;
    await first.draw(2);
    expect(first.rasterizer.debugIsDirect, isFalse);
    expect(_pixel(first.canvases.single.canvasElement), <int>[2, 0, 0, 255]);
    await first.draw(3);
    expect(first.rasterizer.debugIsDirect, isTrue);
    expect(surface.glContext, isNot(context));
    expect(_pixel(surface.canvasImageSource as DomHTMLCanvasElement), <int>[3, 0, 0, 255]);
  }, timeout: const Timeout(Duration(seconds: 15)));

  test('observes a DPR change that arrives during a pending direct frame', () async {
    // Warm the transferred context and enter from a bitmap composition. Cold
    // publication may safely exceed the observation window; this test requires
    // an active direct frame to hold while changing the DPR.
    await first.draw(0);
    await first.draw(0, overlay: true);
    await first.draw(1);
    expect(
      first.rasterizer.debugIsDirect,
      isTrue,
      reason: 'The frame must be direct before holding its native work.',
    );
    direct.hold();
    final Future<void> pending = first.draw(2);
    await direct.reached.future.timeout(const Duration(seconds: 5));
    EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(2);
    direct.release();
    await pending;
    await first.draw(3);
    expect(first.rasterizer.debugIsDirect, isFalse);
    await first.draw(4);
    expect(first.rasterizer.debugIsDirect, isTrue);
    final source = first.rasterizer.debugDirectSurface!.canvasImageSource as DomHTMLCanvasElement;
    expect(source.style.width, '32px');
  });

  test('observes document adoption during a pending direct frame', () async {
    await first.draw(1);
    final int originalContext = first.rasterizer.debugDirectSurface!.glContext;
    final DomHTMLIFrameElement frame = createDomHTMLIFrameElement();
    domDocument.body!.append(frame);
    try {
      direct.hold();
      final Future<void> pending = first.draw(2);
      await direct.reached.future.timeout(const Duration(seconds: 5));
      final destination = frame.contentWindow.document as DomHTMLDocument;
      destination.body!.append(first.host);
      direct.release();
      await pending;
      await first.draw(3);
      expect(first.rasterizer.debugIsDirect, isFalse);
      await first.draw(4);
      expect(first.rasterizer.debugIsDirect, isTrue);
      final OnscreenSurface adopted = first.rasterizer.debugDirectSurface!;
      expect(adopted.glContext, isNot(originalContext));
      expect((adopted.canvasImageSource as DomHTMLCanvasElement).ownerDocument, destination);
    } finally {
      first.dispose();
      frame.remove();
    }
  });

  test('a disposed view never publishes a pending bitmap composition', () async {
    await first.draw(1);
    export.hold();
    final Future<void> pending = first.draw(2, overlay: true);
    await export.reached.future.timeout(const Duration(seconds: 5));
    first.dispose();
    export.release();
    await pending;
    expect(first.rasterizer.sceneElement.querySelectorAll('canvas'), isEmpty);
    expect(first.host.children, isEmpty);
    // The shared export remains usable by a subsequent view.
    final second = _View(rasterizer);
    try {
      await second.draw(3);
      expect(second.rasterizer.debugIsDirect, isTrue);
    } finally {
      second.dispose();
    }
  });

  test('omits a platform view removed while bitmap export is pending', () async {
    await first.draw(1);
    export.hold();
    final Future<void> pending = first.draw(2, overlay: true);
    await export.reached.future.timeout(const Duration(seconds: 5));
    PlatformViewManager.instance.clearPlatformView(1);
    export.release();
    await pending;
    expect(first.rasterizer.sceneElement.querySelectorAll('flt-platform-view-slot'), isEmpty);
    expect(first.rasterizer.debugIsDirect, isFalse);
    expect(_pixel(first.canvases.first.canvasElement), <int>[2, 0, 0, 255]);
    await first.draw(3);
    expect(first.rasterizer.debugIsDirect, isTrue);
  });

  test('keeps bitmap presentation while detached and promotes after attachment', () async {
    first.host.remove();
    await first.draw(1);
    expect(first.rasterizer.debugIsDirect, isFalse);
    domDocument.body!.append(first.host);
    await first.draw(2);
    expect(first.rasterizer.debugIsDirect, isTrue);
  });

  test('joins pending direct work before preparing an exit', () async {
    await first.draw(1);
    direct.hold();
    final Future<void> pending = first.draw(2);
    await direct.reached.future.timeout(const Duration(seconds: 5));
    final Future<void> exit = first.draw(3, overlay: true);
    await Future<void>.delayed(Duration.zero);
    expect(first.rasterizer.debugIsDirect, isTrue);
    expect(first.canvases, hasLength(1));
    direct.release();
    await Future.wait<void>(<Future<void>>[pending, exit]);
    expect(first.rasterizer.debugIsDirect, isFalse);
    expect(_pixel(first.canvases.first.canvasElement), <int>[3, 0, 0, 255]);
  });

  test('unpublished direct pixels keep the completed bitmap visible', () async {
    publishDirect = false;
    await first.draw(9);
    expect(first.rasterizer.debugIsDirect, isFalse);
    expect(_pixel(first.canvases.single.canvasElement), <int>[9, 0, 0, 255]);
    final int attempts = direct.renders;
    await first.draw(10);
    expect(first.rasterizer.debugIsDirect, isFalse);
    expect(direct.renders, attempts, reason: 'A failed entry is not retried on every frame.');
    expect(_pixel(first.canvases.single.canvasElement), <int>[10, 0, 0, 255]);
  });

  test('slow native completion does not consume the placeholder observation budget', () async {
    nativeCallbackDelay = const Duration(milliseconds: 150);
    await first.draw(9);
    expect(first.rasterizer.debugIsDirect, isTrue);
    expect(
      _pixel(first.rasterizer.debugDirectSurface!.canvasImageSource as DomHTMLCanvasElement),
      <int>[9, 0, 0, 255],
    );
  });

  test('translucent and antialiased pixels survive bitmap to direct entry', () async {
    final second = _View(rasterizer);
    await first.draw(8, transparent: true);
    final List<int> expected = _pixels(first.canvases.single.canvasElement);
    second.dispose();
    await first.draw(8, transparent: true);
    expect(first.rasterizer.debugIsDirect, isTrue);
    expect(
      _pixels(first.rasterizer.debugDirectSurface!.canvasImageSource as DomHTMLCanvasElement),
      expected,
    );
  });

  test('accepts verified pixels when a synchronous observation finishes late', () async {
    // Let the placeholder publish before injecting a pause into the first
    // observation. The test exercises a late match, not unpublished pixels.
    nativeCallbackDelay = const Duration(milliseconds: 150);
    readbackDelay = const Duration(milliseconds: 120);
    await first.draw(9);
    expect(first.rasterizer.debugIsDirect, isTrue);
    expect(
      _pixel(first.rasterizer.debugDirectSurface!.canvasImageSource as DomHTMLCanvasElement),
      <int>[9, 0, 0, 255],
    );
  });

  test('promotes a full-size DPR 2 canvas within the observation budget', () async {
    EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(2);
    first.resize(const ui.Size(2048, 1536));
    final second = _View(rasterizer);
    await first.draw(8, transparent: true);
    expect(first.rasterizer.debugIsDirect, isFalse);
    second.dispose();
    await first.draw(8, transparent: true);
    expect(first.rasterizer.debugIsDirect, isTrue);
    final source = first.rasterizer.debugDirectSurface!.canvasImageSource as DomHTMLCanvasElement;
    expect(source.width, 2048);
    expect(source.height, 1536);
    expect(_pixel(source), <int>[8, 0, 0, 255]);
  });

  test('recreates transferred presentation in the destination document', () async {
    await first.draw(1);
    final int originalContext = first.rasterizer.debugDirectSurface!.glContext;
    final DomHTMLIFrameElement frame = createDomHTMLIFrameElement();
    domDocument.body!.append(frame);
    try {
      final destination = frame.contentWindow.document as DomHTMLDocument;
      destination.body!.append(first.host);
      await first.draw(2);
      expect(first.rasterizer.debugIsDirect, isFalse);
      await first.draw(3);
      expect(first.rasterizer.debugIsDirect, isTrue);
      final OnscreenSurface adopted = first.rasterizer.debugDirectSurface!;
      expect(adopted.glContext, isNot(originalContext));
      expect((adopted.canvasImageSource as DomHTMLCanvasElement).ownerDocument, destination);
      expect(_pixel(adopted.canvasImageSource as DomHTMLCanvasElement), <int>[3, 0, 0, 255]);
      expect(first.rasterizer.sceneElement.querySelector('flt-canvas-staging')!.children, isEmpty);
      domDocument.body!.append(first.host);
      await first.draw(4);
      await first.draw(5);
      expect(first.rasterizer.debugIsDirect, isTrue);
      expect(first.rasterizer.sceneElement.querySelector('flt-canvas-staging')!.children, isEmpty);
    } finally {
      domDocument.body!.append(first.host);
      frame.remove();
    }
  });

  test('disposal releases native context-loss subscriptions', () async {
    final int before = SkwasmCallbackHandler.instance.debugPendingCallbackCount;
    await first.draw(1);
    expect(SkwasmCallbackHandler.instance.debugPendingCallbackCount, before + 2);
    first.dispose();
    rasterizer.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(SkwasmCallbackHandler.instance.debugPendingCallbackCount, before);
  });
}

class _View {
  _View(HybridCanvasRasterizer parent) {
    domDocument.body!.append(host);
    view = EngineFlutterView(EnginePlatformDispatcher.instance, host);
    resize(const ui.Size(64, 48));
    rasterizer = parent.createViewRasterizer(view);
  }

  final DomElement host = createDomHTMLDivElement();
  late final EngineFlutterView view;
  late final HybridCanvasViewRasterizer rasterizer;
  bool _disposed = false;

  List<HybridDisplayCanvas> get canvases => rasterizer.viewEmbedder.debugActiveComposition.canvases
      .map((CompositionCanvas canvas) => canvas.displayCanvas! as HybridDisplayCanvas)
      .toList();

  void resize(ui.Size size) {
    view.debugPhysicalSizeOverride = size;
    view.debugForceResize();
  }

  Future<void> draw(
    int frame, {
    bool overlay = false,
    bool transparent = false,
    void Function(ui.Canvas)? paint,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      transparent ? const ui.Rect.fromLTWH(0, 0, 6, 6) : const ui.Rect.fromLTWH(0, 0, 128, 96),
      ui.Paint()..color = ui.Color(0xFF000000 | frame << 16),
    );
    if (transparent) {
      canvas.drawCircle(
        const ui.Offset(28.25, 24.5),
        19.75,
        ui.Paint()..color = const ui.Color(0x7FA43EC1),
      );
      canvas.drawRect(
        const ui.Rect.fromLTWH(8, 6, 23, 16),
        ui.Paint()..color = const ui.Color(0x031337AD),
      );
    }
    paint?.call(canvas);
    final ui.Picture picture = recorder.endRecording();
    final builder = ui.SceneBuilder()..addPicture(ui.Offset.zero, picture);
    ui.Picture? foreground;
    if (overlay) {
      builder.addPlatformView(1, offset: const ui.Offset(8, 8), width: 20, height: 20);
      final foregroundRecorder = ui.PictureRecorder();
      ui.Canvas(foregroundRecorder).drawRect(
        const ui.Rect.fromLTWH(8, 8, 12, 12),
        ui.Paint()..color = const ui.Color(0x80FF00FF),
      );
      foreground = foregroundRecorder.endRecording();
      builder.addPicture(ui.Offset.zero, foreground);
    }
    final scene = builder.build() as LayerScene;
    try {
      await rasterizer.draw(scene.layerTree, null);
    } finally {
      scene.dispose();
      picture.dispose();
      foreground?.dispose();
    }
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    rasterizer.dispose();
    view.dispose();
    host.remove();
  }
}

@JS('VideoFrame')
extension type _TestVideoFrame._(JSObject _) implements VideoFrame {
  external _TestVideoFrame(DomHTMLCanvasElement source, JSObject init);
}

Future<ui.Image> _textureImage(String kind) async {
  final DomHTMLCanvasElement source = createDomCanvasElement(width: 4, height: 4);
  final DomCanvasRenderingContext2D context = source.context2D;
  for (final (x, y, color) in <(int, int, String)>[
    (0, 0, '#ff0000'),
    (2, 0, '#00ff00'),
    (0, 2, '#0000ff'),
    (2, 2, '#ffffff'),
  ]) {
    context.fillStyle = color.toJS;
    context.fillRect(x, y, 2, 2);
  }
  final JSObject texture = switch (kind) {
    'ImageBitmap' => await createImageBitmap(source),
    'VideoFrame' => _TestVideoFrame(source, <String, int>{'timestamp': 0}.jsify()! as JSObject),
    _ => source,
  };
  return renderer.createImageFromTextureSource(
    texture,
    width: 4,
    height: 4,
    transferOwnership: true,
  );
}

void _expectTexture(DomHTMLCanvasElement canvas) {
  expect(_pixel(canvas, x: 2, y: 2), <int>[255, 0, 0, 255]);
  expect(_pixel(canvas, x: 30, y: 2), <int>[0, 255, 0, 255]);
  expect(_pixel(canvas, x: 2, y: 30), <int>[0, 0, 255, 255]);
  expect(_pixel(canvas, x: 30, y: 30), <int>[255, 255, 255, 255]);
}

List<int> _pixel(DomHTMLCanvasElement source, {int x = 0, int y = 0}) {
  final DomHTMLCanvasElement readback = createDomCanvasElement(width: 1, height: 1);
  try {
    readback.context2D.drawImage(source, -x, -y);
    return readback.context2D.getImageData(0, 0, 1, 1).data.toList();
  } finally {
    readback.width = readback.height = 0;
  }
}

List<int> _pixels(DomHTMLCanvasElement source) {
  final DomHTMLCanvasElement readback = createDomCanvasElement(
    width: source.width!.toInt(),
    height: source.height!.toInt(),
  );
  try {
    readback.context2D.drawImage(source, 0, 0);
    return readback.context2D
        .getImageData(0, 0, source.width!.toInt(), source.height!.toInt())
        .data
        .toList();
  } finally {
    readback.width = readback.height = 0;
  }
}

class _OnscreenSurface extends _ExportSurface implements OnscreenSurface {
  _OnscreenSurface(super.delegate);
  bool published = true;
  Duration completionDelay = Duration.zero;
  Duration readbackDelay = Duration.zero;
  int sourceReads = 0;
  int renders = 0;
  final DomHTMLCanvasElement _unpublished = createDomCanvasElement(width: 64, height: 48);

  @override
  DomCanvasImageSource get canvasImageSource {
    sourceReads++;
    if (sourceReads == 2 && readbackDelay != Duration.zero) {
      // Model a blocking browser readback/GC pause after observation started.
      final timer = Stopwatch()..start();
      while (timer.elapsed < readbackDelay) {
        // Synchronous browser work cannot be preempted by a Dart timer.
      }
    }
    return published ? delegate.canvasImageSource : _unpublished;
  }

  @override
  Future<void> rasterizeToCanvas(ui.Picture picture) async {
    renders++;
    final Completer<void>? release = _release;
    if (release != null) {
      reached.complete();
      await release.future;
    }
    await delegate.rasterizeToCanvas(picture);
    if (completionDelay != Duration.zero) {
      await Future<void>.delayed(completionDelay);
    }
  }

  @override
  DomElement get hostElement => delegate.hostElement;
  @override
  bool get isConnected => delegate.isConnected;
  @override
  void initialize() => delegate.initialize();
  @override
  void setIsOverlay(bool isOverlay) => delegate.setIsOverlay(isOverlay);
}

// Delay actual Skwasm exports to observe the old frame during native work.
class _ExportSurface implements OffscreenSurface {
  _ExportSurface(this.delegate);
  final SkwasmSurface delegate;
  Completer<void>? _release;
  late Completer<void> reached;
  bool failNextExport = false;

  void hold() {
    reached = Completer<void>();
    _release = Completer<void>();
  }

  void release() {
    _release!.complete();
    _release = null;
  }

  @override
  Future<List<DomImageBitmap>> rasterizeToImageBitmaps(List<ui.Picture> pictures) async {
    if (failNextExport) {
      failNextExport = false;
      throw StateError('Simulated export failure.');
    }
    final Completer<void>? release = _release;
    if (release != null) {
      reached.complete();
      await release.future;
    }
    return delegate.rasterizeToImageBitmaps(pictures);
  }

  @override
  Future<void> setSize(BitmapSize size) => delegate.setSize(size);
  @override
  Future<ByteData> rasterizeImage(ui.Image image, ui.ImageByteFormat format) =>
      delegate.rasterizeImage(image, format);
  @override
  bool get supportsPngEncoding => delegate.supportsPngEncoding;
  @override
  void setSkiaResourceCacheMaxBytes(int bytes) => delegate.setSkiaResourceCacheMaxBytes(bytes);
  @override
  Future<void> recreateContextForCanvas(DomEventTarget canvas) =>
      delegate.recreateContextForCanvas(canvas);
  @override
  void dispose() => delegate.dispose();
  @override
  Future<void> get initialized => delegate.initialized;
  @override
  DomCanvasImageSource get canvasImageSource => delegate.canvasImageSource;
  @override
  Future<void> rasterizeToCanvas(ui.Picture picture) => delegate.rasterizeToCanvas(picture);
  @override
  int get glContext => delegate.glContext;
  @override
  Future<void> triggerContextLoss() => delegate.triggerContextLoss();
  @override
  Future<void> get handledContextLossEvent => delegate.handledContextLossEvent;
}
