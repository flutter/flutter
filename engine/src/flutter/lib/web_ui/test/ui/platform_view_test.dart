// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;
import 'package:web_engine_tester/golden_tester.dart';

import '../common/rendering.dart';
import '../common/test_initialization.dart';
import 'utils.dart';

EngineFlutterWindow get implicitView => EnginePlatformDispatcher.instance.implicitView!;

DomElement get platformViewsHost => implicitView.dom.platformViewsHost;
DomElement get sceneHost => implicitView.dom.sceneHost;

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);

  const ui.Rect region = ui.Rect.fromLTWH(0, 0, 300, 300);
  const String platformViewType = 'test-platform-view';
  const String invisiblePlatformViewType = 'invisible-test-platform-view';

  setUp(() {
    ui_web.platformViewRegistry.registerViewFactory(platformViewType, (int viewId) {
      final DomElement element = createDomHTMLDivElement();
      element.style.backgroundColor = 'blue';
      element.style.width = '100%';
      element.style.height = '100%';
      element.id = 'view-$viewId';
      return element;
    });

    ui_web.platformViewRegistry.registerViewFactory(invisiblePlatformViewType, (int viewId) {
      final DomElement element = createDomHTMLDivElement();
      element.style.width = '100%';
      element.style.height = '100%';
      element.id = 'invisible-view-$viewId';
      return element;
    }, isVisible: false);
  });

  tearDown(() {
    PlatformViewManager.instance.debugClear();
    renderer.debugClear();
  });

  test('picture + overlapping platformView', () async {
    await _createPlatformView(1, platformViewType);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawCircle(
      const ui.Offset(50, 50),
      50,
      ui.Paint()
        ..style = ui.PaintingStyle.fill
        ..color = const ui.Color(0xFFFF0000),
    );

    final ui.SceneBuilder sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    sb.addPicture(const ui.Offset(100, 100), recorder.endRecording());

    sb.addPlatformView(1, offset: const ui.Offset(125, 125), width: 50, height: 50);
    await renderScene(sb.build());

    await matchGoldenFile('picture_platformview_overlap.png', region: region);
  });

  test('platformView sandwich', () async {
    await _createPlatformView(1, platformViewType);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawCircle(
      const ui.Offset(50, 50),
      50,
      ui.Paint()
        ..style = ui.PaintingStyle.fill
        ..color = const ui.Color(0xFF00FF00),
    );

    final ui.Picture picture = recorder.endRecording();

    final ui.SceneBuilder sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    sb.addPicture(const ui.Offset(75, 75), picture);

    sb.addPlatformView(1, offset: const ui.Offset(100, 100), width: 100, height: 100);

    sb.addPicture(const ui.Offset(125, 125), picture);
    await renderScene(sb.build());

    await matchGoldenFile('picture_platformview_sandwich.png', region: region);
  });

  test('transformed platformview', () async {
    await _createPlatformView(1, platformViewType);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawCircle(
      const ui.Offset(50, 50),
      50,
      ui.Paint()
        ..style = ui.PaintingStyle.fill
        ..color = const ui.Color(0xFFFF0000),
    );

    final ui.SceneBuilder sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    sb.addPicture(const ui.Offset(100, 100), recorder.endRecording());

    sb.pushTransform(Matrix4.rotationZ(0.1).toFloat64());
    sb.addPlatformView(1, offset: const ui.Offset(125, 125), width: 50, height: 50);
    await renderScene(sb.build());

    await matchGoldenFile('platformview_transformed.png', region: region);
  });

  test('transformed and offset platformview', () async {
    await _createPlatformView(1, platformViewType);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawCircle(
      const ui.Offset(50, 50),
      50,
      ui.Paint()
        ..style = ui.PaintingStyle.fill
        ..color = const ui.Color(0xFFFF0000),
    );

    final ui.SceneBuilder sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    sb.addPicture(const ui.Offset(100, 100), recorder.endRecording());

    // Nest offsets both before and after the transform to make sure that they
    // are applied properly.
    sb.pushOffset(50, 50);
    sb.pushTransform(Matrix4.rotationZ(0.1).toFloat64());
    sb.pushOffset(25, 25);
    sb.addPlatformView(1, offset: const ui.Offset(50, 50), width: 50, height: 50);
    await renderScene(sb.build());

    await matchGoldenFile('platformview_transformed_offset.png', region: region);
  });

  test('offset platformview', () async {
    await _createPlatformView(1, platformViewType);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawCircle(
      const ui.Offset(50, 50),
      50,
      ui.Paint()
        ..style = ui.PaintingStyle.fill
        ..color = const ui.Color(0xFFFF0000),
    );

    final ui.Picture picture = recorder.endRecording();

    final ui.SceneBuilder sb = ui.SceneBuilder();
    sb.pushOffset(50, 50);
    sb.addPicture(const ui.Offset(100, 100), picture);

    final ui.EngineLayer retainedPlatformView = sb.pushOffset(50, 50);
    sb.addPlatformView(1, offset: const ui.Offset(125, 125), width: 50, height: 50);
    await renderScene(sb.build());

    await matchGoldenFile('platformview_offset.png', region: region);

    final ui.SceneBuilder sb2 = ui.SceneBuilder();
    sb2.pushOffset(0, 0);
    sb2.addPicture(const ui.Offset(100, 100), picture);

    sb2.addRetained(retainedPlatformView);
    await renderScene(sb2.build());

    await matchGoldenFile('platformview_offset_moved.png', region: region);
  });

  test('platformview with opacity', () async {
    await _createPlatformView(1, platformViewType);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawCircle(
      const ui.Offset(50, 50),
      50,
      ui.Paint()
        ..style = ui.PaintingStyle.fill
        ..color = const ui.Color(0xFFFF0000),
    );

    final ui.SceneBuilder sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    sb.addPicture(const ui.Offset(100, 100), recorder.endRecording());

    sb.pushOpacity(127, offset: const ui.Offset(50, 50));
    sb.addPlatformView(1, offset: const ui.Offset(125, 125), width: 50, height: 50);
    await renderScene(sb.build());

    await matchGoldenFile('platformview_opacity.png', region: region);
  });

  test('platformview cliprect', () async {
    await _createPlatformView(1, platformViewType);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawCircle(
      const ui.Offset(50, 50),
      50,
      ui.Paint()
        ..style = ui.PaintingStyle.fill
        ..color = const ui.Color(0xFFFF0000),
    );

    final ui.SceneBuilder sb = ui.SceneBuilder();
    sb.pushOffset(50, 50);
    sb.pushClipRect(const ui.Rect.fromLTRB(60, 60, 100, 100));

    sb.addPicture(const ui.Offset(50, 50), recorder.endRecording());
    sb.addPlatformView(1, offset: const ui.Offset(75, 75), width: 50, height: 50);
    await renderScene(sb.build());

    await matchGoldenFile('platformview_cliprect.png', region: region);
  });

  test('platformview cliprrect', () async {
    await _createPlatformView(1, platformViewType);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawCircle(
      const ui.Offset(50, 50),
      50,
      ui.Paint()
        ..style = ui.PaintingStyle.fill
        ..color = const ui.Color(0xFFFF0000),
    );

    final ui.SceneBuilder sb = ui.SceneBuilder();
    sb.pushOffset(50, 50);
    sb.pushClipRRect(
      const ui.RRect.fromLTRBXY(60, 60, 100, 100, 5, 10),
      clipBehavior: ui.Clip.antiAlias,
    );

    sb.addPicture(const ui.Offset(50, 50), recorder.endRecording());
    sb.addPlatformView(1, offset: const ui.Offset(75, 75), width: 50, height: 50);
    await renderScene(sb.build());

    await matchGoldenFile('platformview_cliprrect.png', region: region);
  });

  test('platformview covered clip', () async {
    await _createPlatformView(1, platformViewType);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawCircle(
      const ui.Offset(50, 50),
      50,
      ui.Paint()
        ..style = ui.PaintingStyle.fill
        ..color = const ui.Color(0xFFFF0000),
    );

    final ui.SceneBuilder sb = ui.SceneBuilder();
    sb.pushOffset(50, 50);

    // The rrect should completely cover the rect for this test case.
    sb.pushClipRRect(
      const ui.RRect.fromLTRBXY(50, 50, 110, 110, 5, 10),
      clipBehavior: ui.Clip.antiAlias,
    );
    sb.pushClipRect(const ui.Rect.fromLTRB(60, 60, 100, 100));

    sb.addPicture(const ui.Offset(50, 50), recorder.endRecording());
    sb.addPlatformView(1, offset: const ui.Offset(75, 75), width: 50, height: 50);
    await renderScene(sb.build());

    await matchGoldenFile('platformview_covered_clip.png', region: region);
  });

  test('platformview clippath', () async {
    await _createPlatformView(1, platformViewType);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawCircle(
      const ui.Offset(50, 50),
      50,
      ui.Paint()
        ..style = ui.PaintingStyle.fill
        ..color = const ui.Color(0xFFFF0000),
    );

    final ui.SceneBuilder sb = ui.SceneBuilder();
    sb.pushOffset(50, 50);

    final ui.Path path = ui.Path();
    path.moveTo(80, 100);
    path.lineTo(60, 75);
    path.arcToPoint(const ui.Offset(80, 75), radius: const ui.Radius.elliptical(10, 15));
    path.arcToPoint(const ui.Offset(100, 75), radius: const ui.Radius.elliptical(10, 15));
    path.close();
    sb.pushClipPath(path);

    sb.addPicture(const ui.Offset(50, 50), recorder.endRecording());
    sb.addPlatformView(1, offset: const ui.Offset(75, 75), width: 50, height: 50);
    await renderScene(sb.build());

    await matchGoldenFile('platformview_clippath.png', region: region);
  });

  test('embeds interactive platform views', () async {
    await _createPlatformView(1, platformViewType);

    final ui.SceneBuilder sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    sb.addPlatformView(1, width: 10, height: 10);
    await renderScene(sb.build());

    // The platform view is now split in two parts. The contents live
    // as a child of the glassPane, and the slot lives in the glassPane
    // shadow root. The slot is the one that has pointer events auto.
    final DomElement contents = platformViewsHost.querySelector('#view-1')!;
    final DomElement slot = sceneHost.querySelector('slot')!;
    final DomElement contentsHost = contents.parent!;
    final DomElement slotHost = slot.parent!;

    expect(contents, isNotNull, reason: 'The view from the factory is injected in the DOM.');

    expect(contentsHost.tagName, equalsIgnoringCase('flt-platform-view'));
    expect(slotHost.tagName, equalsIgnoringCase('flt-platform-view-slot'));

    expect(slotHost.style.pointerEvents, 'auto', reason: 'The slot reenables pointer events.');
    expect(
      contentsHost.getAttribute('slot'),
      slot.getAttribute('name'),
      reason: 'The contents and slot are correctly related.',
    );
  });

  test('clips platform views with RRects', () async {
    await _createPlatformView(1, platformViewType);

    final ui.SceneBuilder sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    sb.pushClipRRect(
      ui.RRect.fromLTRBR(0, 0, 10, 10, const ui.Radius.circular(3)),
      clipBehavior: ui.Clip.hardEdge,
    );
    sb.addPlatformView(1, width: 10, height: 10);
    await renderScene(sb.build());

    expect(
      sceneHost.querySelectorAll('flt-clip').single.style.clipPath,
      'rect(0px 10px 10px 0px round 3px)',
    );
    expect(sceneHost.querySelectorAll('flt-clip').single.style.width, '100%');
    expect(sceneHost.querySelectorAll('flt-clip').single.style.height, '100%');
    // CanvasKit doesn't use the `rect` CSS clip-path to clip but it should:
    // https://github.com/flutter/flutter/issues/172308
  }, skip: isCanvasKit);

  test('correctly transforms platform views', () async {
    await _createPlatformView(1, platformViewType);

    final ui.SceneBuilder sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    final Matrix4 scaleMatrix = Matrix4.identity()
      ..scale(5, 5)
      ..translate(100, 100);
    sb.pushTransform(scaleMatrix.toFloat64());
    sb.pushOffset(3, 3);
    sb.addPlatformView(1, width: 10, height: 10);
    await renderScene(sb.build());

    // Transformations happen on the slot element.
    final DomElement slotHost = sceneHost.querySelector('flt-platform-view-slot')!;

    expect(
      slotHost.style.transform,
      // We should apply the scale matrix first, then the offset matrix.
      // So the translate should be 515 (5 * 100 + 5 * 3), and not
      // 503 (5 * 100 + 3).
      'matrix3d(5, 0, 0, 0, 0, 5, 0, 0, 0, 0, 5, 0, 515, 515, 0, 1)',
    );
  });

  test('correctly offsets platform views', () async {
    await _createPlatformView(1, platformViewType);

    final ui.SceneBuilder sb = ui.SceneBuilder();
    sb.addPlatformView(1, offset: const ui.Offset(3, 4), width: 5, height: 6);
    await renderScene(sb.build());

    final DomElement slotHost = sceneHost.querySelector('flt-platform-view-slot')!;
    final DomCSSStyleDeclaration style = slotHost.style;

    expect(style.transform, 'matrix(1, 0, 0, 1, 3, 4)');
    expect(style.width, '5px');
    expect(style.height, '6px');

    final DomRect slotRect = slotHost.getBoundingClientRect();
    expect(slotRect.left, 3);
    expect(slotRect.top, 4);
    expect(slotRect.right, 8);
    expect(slotRect.bottom, 10);
  });

  test('correctly offsets when clip chain length is changed', () async {
    await _createPlatformView(1, platformViewType);

    ui.SceneBuilder sb = ui.SceneBuilder();
    sb.pushOffset(3, 3);
    sb.pushClipRect(ui.Rect.largest);
    sb.pushOffset(6, 6);
    sb.addPlatformView(1, width: 10, height: 10);
    sb.pop();
    await renderScene(sb.build());

    // Transformations happen on the slot element.
    DomElement slotHost = sceneHost.querySelector('flt-platform-view-slot')!;

    expect(getTransformChain(slotHost), <String>[
      'matrix(1, 0, 0, 1, 6, 6)',
      'matrix(1, 0, 0, 1, 3, 3)',
    ]);

    sb = ui.SceneBuilder();
    sb.pushOffset(3, 3);
    sb.pushClipRect(ui.Rect.largest);
    sb.pushOffset(6, 6);
    sb.pushClipRect(ui.Rect.largest);
    sb.pushOffset(9, 9);
    sb.addPlatformView(1, width: 10, height: 10);
    await renderScene(sb.build());

    // Transformations happen on the slot element.
    slotHost = sceneHost.querySelector('flt-platform-view-slot')!;

    expect(getTransformChain(slotHost), <String>[
      'matrix(1, 0, 0, 1, 9, 9)',
      'matrix(1, 0, 0, 1, 6, 6)',
      'matrix(1, 0, 0, 1, 3, 3)',
    ]);
    // Skwasm pre-transforms the clips instead of applying the transforms
    // stepwise in each clip:
    // https://github.com/flutter/flutter/issues/172308
  }, skip: isSkwasm);

  test('converts device pixels to logical pixels (no clips)', () async {
    EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(4);
    await _createPlatformView(1, platformViewType);

    final ui.SceneBuilder sb = ui.SceneBuilder();
    sb.pushOffset(1, 1);
    sb.pushOffset(2, 2);
    sb.pushOffset(3, 3);
    sb.addPlatformView(1, width: 10, height: 10);
    await renderScene(sb.build());

    // Transformations happen on the slot element.
    final DomElement slotHost = sceneHost.querySelector('flt-platform-view-slot')!;

    expect(getTransformChain(slotHost), <String>['matrix(0.25, 0, 0, 0.25, 1.5, 1.5)']);
    EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(null);
    // Skwasm has an empty <flt-clip> element as a parent of the platform view:
    // https://github.com/flutter/flutter/issues/172308
  }, skip: isSkwasm);

  test('converts device pixels to logical pixels (with clips)', () async {
    EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(4);
    await _createPlatformView(1, platformViewType);

    final ui.SceneBuilder sb = ui.SceneBuilder();
    sb.pushOffset(3, 3);
    sb.pushClipRect(ui.Rect.largest);
    sb.pushOffset(6, 6);
    sb.pushClipRect(ui.Rect.largest);
    sb.pushOffset(9, 9);
    sb.addPlatformView(1, width: 10, height: 10);
    await renderScene(sb.build());

    // Transformations happen on the slot element.
    final DomElement slotHost = sceneHost.querySelector('flt-platform-view-slot')!;

    expect(getTransformChain(slotHost), <String>[
      'matrix(1, 0, 0, 1, 9, 9)',
      'matrix(1, 0, 0, 1, 6, 6)',
      'matrix(0.25, 0, 0, 0.25, 0.75, 0.75)',
    ]);
    EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(null);
    // Skwasm pre-transforms the clips instead of applying the transforms
    // stepwise in each clip:
    // https://github.com/flutter/flutter/issues/172308
  }, skip: isSkwasm);

  test('renders overlays on top of platform views', () async {
    debugOverrideJsConfiguration(
      <String, Object?>{'canvasKitMaximumSurfaces': 8}.jsify() as JsFlutterConfiguration?,
    );
    final ui.PictureRecorder testRecorder = ui.PictureRecorder();
    final ui.Canvas testCanvas = ui.Canvas(testRecorder);
    testCanvas.drawCircle(const ui.Offset(5, 5), 5, ui.Paint());
    final ui.Picture testPicture = testRecorder.endRecording();

    // Initialize all platform views to be used in the test.
    final List<int> platformViewIds = <int>[];
    for (int i = 0; i < 16; i++) {
      await _createPlatformView(i, platformViewType);
      platformViewIds.add(i);
    }

    Future<void> renderTestScene({required int viewCount}) async {
      final ui.SceneBuilder sb = ui.SceneBuilder();
      sb.pushOffset(0, 0);
      for (int i = 0; i < viewCount; i++) {
        sb.addPicture(ui.Offset.zero, testPicture);
        sb.addPlatformView(i, width: 10, height: 10);
      }
      await renderScene(sb.build());
    }

    // Frame 1:
    //   Render: up to cache size platform views.
    //   Expect: main canvas plus platform view overlays.
    await renderTestScene(viewCount: 8);
    _expectSceneMatches(<_EmbeddedViewMarker>[
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
    ]);

    // Frame 2:
    //   Render: zero platform views.
    //   Expect: main canvas, no overlays.
    await renderTestScene(viewCount: 0);
    _expectSceneMatches(<_EmbeddedViewMarker>[]);

    // Frame 3:
    //   Render: less than cache size platform views.
    //   Expect: overlays reused.
    await renderTestScene(viewCount: 6);
    _expectSceneMatches(<_EmbeddedViewMarker>[
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
    ]);

    // Frame 4:
    //   Render: more platform views than max overlay count.
    //   Expect: main canvas, backup overlay, maximum overlays.
    await renderTestScene(viewCount: 16);
    _expectSceneMatches(<_EmbeddedViewMarker>[
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _platformView,
      _platformView,
      _platformView,
      _platformView,
      _platformView,
      _platformView,
      _platformView,
      _platformView,
      _overlay,
      _platformView,
    ]);

    // Frame 5:
    //   Render: zero platform views.
    //   Expect: main canvas, no overlays.
    await renderTestScene(viewCount: 0);
    _expectSceneMatches(<_EmbeddedViewMarker>[]);

    // Frame 6:
    //   Render: deleted platform views.
    //   Expect: error.
    for (final int id in platformViewIds) {
      const StandardMethodCodec codec = StandardMethodCodec();
      final Completer<void> completer = Completer<void>();
      ui.PlatformDispatcher.instance.sendPlatformMessage(
        'flutter/platform_views',
        codec.encodeMethodCall(MethodCall('dispose', id)),
        completer.complete,
      );
      await completer.future;
    }

    try {
      await renderTestScene(viewCount: platformViewIds.length);
      fail('Expected to throw');
    } on AssertionError catch (error) {
      expect(
        error.toString(),
        contains(
          'Cannot render platform views: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15. These views have not been created, or they have been deleted.',
        ),
      );
    }

    // Frame 7:
    //   Render: a platform view after error.
    //   Expect: success. Just checking the system is not left in a corrupted state.
    await _createPlatformView(0, platformViewType);
    await renderTestScene(viewCount: 0);
    _expectSceneMatches(<_EmbeddedViewMarker>[]);
    debugOverrideJsConfiguration(null);
    // Skwasm doesn't cap the maximum number of overlays:
    // https://github.com/flutter/flutter/issues/172308
  }, skip: isSkwasm);

  test('correctly reuses overlays', () async {
    final ui.PictureRecorder testRecorder = ui.PictureRecorder();
    final ui.Canvas testCanvas = ui.Canvas(testRecorder);
    testCanvas.drawCircle(const ui.Offset(5, 5), 5, ui.Paint());
    final ui.Picture testPicture = testRecorder.endRecording();

    // Initialize all platform views to be used in the test.
    final List<int> platformViewIds = <int>[];
    for (int i = 0; i < 20; i++) {
      await _createPlatformView(i, platformViewType);
      platformViewIds.add(i);
    }

    Future<void> renderTestScene(List<int> views) async {
      final ui.SceneBuilder sb = ui.SceneBuilder();
      sb.pushOffset(0, 0);
      for (final int view in views) {
        sb.addPicture(ui.Offset.zero, testPicture);
        sb.addPlatformView(view, width: 10, height: 10);
      }
      await renderScene(sb.build());
    }

    // Frame 1:
    //   Render: Views 1-10
    //   Expect: main canvas plus platform view overlays; empty cache.
    await renderTestScene(<int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    _expectSceneMatches(<_EmbeddedViewMarker>[
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _platformView,
      _platformView,
      _overlay,
      _platformView,
    ]);

    // Frame 2:
    //   Render: Views 2-11
    //   Expect: main canvas plus platform view overlays; empty cache.
    await renderTestScene(<int>[2, 3, 4, 5, 6, 7, 8, 9, 10, 11]);
    _expectSceneMatches(<_EmbeddedViewMarker>[
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _platformView,
      _platformView,
      _overlay,
      _platformView,
    ]);

    // Frame 3:
    //   Render: Views 3-12
    //   Expect: main canvas plus platform view overlays; empty cache.
    await renderTestScene(<int>[3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
    _expectSceneMatches(<_EmbeddedViewMarker>[
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _platformView,
      _platformView,
      _overlay,
      _platformView,
    ]);

    // Frame 4:
    //   Render: Views 3-12 again (same as last frame)
    //   Expect: main canvas plus platform view overlays; empty cache.
    await renderTestScene(<int>[3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
    _expectSceneMatches(<_EmbeddedViewMarker>[
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _platformView,
      _platformView,
      _overlay,
      _platformView,
    ]);
    // Skwasm doesn't cap the maximum number of overlays:
    // https://github.com/flutter/flutter/issues/172308
  }, skip: isSkwasm);

  test('embeds and disposes of a platform view', () async {
    await _createPlatformView(1, platformViewType);

    ui.SceneBuilder sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    sb.addPlatformView(1, width: 10, height: 10);
    await renderScene(sb.build());
    _expectSceneMatches(<_EmbeddedViewMarker>[_platformView]);

    expect(platformViewsHost.querySelector('flt-platform-view'), isNotNull);

    await _disposePlatformView(1);

    sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    await renderScene(sb.build());

    _expectSceneMatches(<_EmbeddedViewMarker>[]);

    expect(platformViewsHost.querySelector('flt-platform-view'), isNull);
  });

  test('preserves the DOM node of an unrendered platform view', () async {
    await _createPlatformView(1, platformViewType);

    ui.SceneBuilder sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    sb.addPlatformView(1, width: 10, height: 10);
    await renderScene(sb.build());
    _expectSceneMatches(<_EmbeddedViewMarker>[_platformView]);

    expect(platformViewsHost.querySelectorAll('flt-platform-view'), hasLength(1));

    // Render a frame with a different platform view.
    await _createPlatformView(2, platformViewType);
    sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    sb.addPlatformView(2, width: 10, height: 10);
    await renderScene(sb.build());
    _expectSceneMatches(<_EmbeddedViewMarker>[_platformView]);

    expect(platformViewsHost.querySelectorAll('flt-platform-view'), hasLength(2));

    // Render a frame without a platform view, but also without disposing of
    // the platform view.
    sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    await renderScene(sb.build());
    _expectSceneMatches(<_EmbeddedViewMarker>[]);

    // The actual contents of the platform view are kept in the dom, until
    // it's actually disposed of!
    expect(platformViewsHost.querySelectorAll('flt-platform-view'), hasLength(2));
  });

  test('does not crash when a prerolled platform view is not composited', () async {
    await _createPlatformView(1, platformViewType);

    final ui.SceneBuilder sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    sb.pushClipRect(ui.Rect.zero);
    sb.addPlatformView(1, width: 10, height: 10);
    sb.pop();
    // The below line should not throw an error.
    await renderScene(sb.build());
    _expectSceneMatches(<_EmbeddedViewMarker>[]);
  }, skip: isSkwasm);

  test('does not create overlays for invisible platform views', () async {
    final ui.PictureRecorder testRecorder = ui.PictureRecorder();
    final ui.Canvas testCanvas = ui.Canvas(testRecorder);
    testCanvas.drawCircle(const ui.Offset(5, 5), 5, ui.Paint());
    final ui.Picture testPicture = testRecorder.endRecording();
    await _createPlatformView(0, platformViewType);
    await _createPlatformView(1, invisiblePlatformViewType);
    await _createPlatformView(2, platformViewType);
    await _createPlatformView(3, invisiblePlatformViewType);
    await _createPlatformView(4, invisiblePlatformViewType);
    await _createPlatformView(5, invisiblePlatformViewType);
    await _createPlatformView(6, invisiblePlatformViewType);

    expect(PlatformViewManager.instance.isInvisible(0), isFalse);
    expect(PlatformViewManager.instance.isInvisible(1), isTrue);

    ui.SceneBuilder sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(1, width: 10, height: 10);
    sb.pop();
    await renderScene(sb.build());
    _expectSceneMatches(<_EmbeddedViewMarker>[
      _platformView,
      _overlay,
    ], reason: 'Invisible view renders, followed by an overlay.');

    sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(0, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(1, width: 10, height: 10);
    sb.pop();
    await renderScene(sb.build());
    _expectSceneMatches(<_EmbeddedViewMarker>[
      _overlay,
      _platformView,
      _platformView,
      _overlay,
    ], reason: 'Overlay created after a group containing a visible view.');

    sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(0, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(1, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(2, width: 10, height: 10);
    sb.pop();
    await renderScene(sb.build());
    _expectSceneMatches(<_EmbeddedViewMarker>[
      _overlay,
      _platformView,
      _platformView,
      _overlay,
      _platformView,
    ], reason: 'Overlays created after each group containing a visible view.');

    sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(0, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(1, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(2, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(3, width: 10, height: 10);
    sb.pop();
    await renderScene(sb.build());
    _expectSceneMatches(<_EmbeddedViewMarker>[
      _overlay,
      _platformView,
      _platformView,
      _overlay,
      _platformView,
      _platformView,
      _overlay,
    ], reason: 'Invisible views grouped in with visible views.');

    sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(0, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(1, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(2, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(3, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(4, width: 10, height: 10);
    sb.pop();
    await renderScene(sb.build());
    _expectSceneMatches(<_EmbeddedViewMarker>[
      _overlay,
      _platformView,
      _platformView,
      _overlay,
      _platformView,
      _platformView,
      _platformView,
      _overlay,
    ]);

    sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(0, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(1, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(2, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(3, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(4, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(5, width: 10, height: 10);
    sb.pop();
    await renderScene(sb.build());
    _expectSceneMatches(<_EmbeddedViewMarker>[
      _overlay,
      _platformView,
      _platformView,
      _overlay,
      _platformView,
      _platformView,
      _platformView,
      _platformView,
      _overlay,
    ]);

    sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(0, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(1, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(2, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(3, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(4, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(5, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(6, width: 10, height: 10);
    sb.pop();
    await renderScene(sb.build());
    _expectSceneMatches(<_EmbeddedViewMarker>[
      _overlay,
      _platformView,
      _platformView,
      _overlay,
      _platformView,
      _platformView,
      _platformView,
      _platformView,
      _platformView,
      _overlay,
    ]);

    sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(1, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(3, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(4, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(5, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(6, width: 10, height: 10);
    sb.pop();
    await renderScene(sb.build());
    _expectSceneMatches(<_EmbeddedViewMarker>[
      _platformView,
      _platformView,
      _platformView,
      _platformView,
      _platformView,
      _overlay,
    ], reason: 'Many invisible views can be rendered on top of the base overlay.');

    sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(1, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(2, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(3, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(4, width: 10, height: 10);
    sb.pop();
    await renderScene(sb.build());
    _expectSceneMatches(<_EmbeddedViewMarker>[
      _platformView,
      _overlay,
      _platformView,
      _platformView,
      _platformView,
      _overlay,
    ]);

    sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(4, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(3, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(2, width: 10, height: 10);
    sb.addPicture(ui.Offset.zero, testPicture);
    sb.addPlatformView(1, width: 10, height: 10);
    sb.pop();
    await renderScene(sb.build());
    _expectSceneMatches(<_EmbeddedViewMarker>[
      _platformView,
      _platformView,
      _overlay,
      _platformView,
      _platformView,
      _overlay,
    ]);
  }, skip: isSkwasm);

  test('optimizes overlays when pictures and platform views do not overlap', () async {
    ui.Picture rectPicture(ui.Rect rect) {
      final ui.PictureRecorder testRecorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(testRecorder);
      canvas.drawRect(rect, ui.Paint()..color = const ui.Color.fromARGB(255, 255, 0, 0));
      return testRecorder.endRecording();
    }

    await _createPlatformView(0, platformViewType);
    await _createPlatformView(1, platformViewType);
    await _createPlatformView(2, platformViewType);

    expect(PlatformViewManager.instance.isVisible(0), isTrue);
    expect(PlatformViewManager.instance.isVisible(1), isTrue);
    expect(PlatformViewManager.instance.isVisible(2), isTrue);

    // Scene 1: Pictures just overlap with the most recently painted platform
    // view. Analogous to third-party images with subtitles overlaid. Should
    // only need one overlay at the end of the scene.
    final ui.SceneBuilder sb1 = ui.SceneBuilder();
    sb1.pushOffset(0, 0);
    sb1.addPlatformView(0, offset: const ui.Offset(10, 10), width: 50, height: 50);
    sb1.addPicture(ui.Offset.zero, rectPicture(const ui.Rect.fromLTWH(12, 12, 10, 10)));
    sb1.addPlatformView(1, offset: const ui.Offset(70, 10), width: 50, height: 50);
    sb1.addPicture(ui.Offset.zero, rectPicture(const ui.Rect.fromLTWH(72, 12, 10, 10)));
    sb1.addPlatformView(2, offset: const ui.Offset(130, 10), width: 50, height: 50);
    sb1.addPicture(ui.Offset.zero, rectPicture(const ui.Rect.fromLTWH(132, 12, 10, 10)));
    final ui.Scene scene1 = sb1.build();
    await renderScene(scene1);
    _expectSceneMatches(<_EmbeddedViewMarker>[
      _platformView,
      _platformView,
      _platformView,
      _overlay,
    ]);

    // Scene 2: Same as scene 1 but with a background painted first. Should only
    // need a canvas for the background and one more for the rest of the
    // pictures.
    final ui.SceneBuilder sb2 = ui.SceneBuilder();
    sb2.pushOffset(0, 0);
    sb2.addPicture(ui.Offset.zero, rectPicture(const ui.Rect.fromLTWH(0, 0, 300, 300)));
    sb2.addPlatformView(0, offset: const ui.Offset(10, 10), width: 50, height: 50);
    sb2.addPicture(ui.Offset.zero, rectPicture(const ui.Rect.fromLTWH(12, 12, 10, 10)));
    sb2.addPlatformView(1, offset: const ui.Offset(70, 10), width: 50, height: 50);
    sb2.addPicture(ui.Offset.zero, rectPicture(const ui.Rect.fromLTWH(72, 12, 10, 10)));
    sb2.addPlatformView(2, offset: const ui.Offset(130, 10), width: 50, height: 50);
    sb2.addPicture(ui.Offset.zero, rectPicture(const ui.Rect.fromLTWH(132, 12, 10, 10)));
    final ui.Scene scene2 = sb2.build();
    await renderScene(scene2);
    _expectSceneMatches(<_EmbeddedViewMarker>[
      _overlay,
      _platformView,
      _platformView,
      _platformView,
      _overlay,
    ]);

    // Scene 3: Paints a full-screen picture between each platform view. This
    // is the worst case scenario. There should be an overlay between each
    // platform view.
    final ui.SceneBuilder sb3 = ui.SceneBuilder();
    sb3.pushOffset(0, 0);
    sb3.addPicture(ui.Offset.zero, rectPicture(const ui.Rect.fromLTWH(0, 0, 300, 300)));
    sb3.addPlatformView(0, offset: const ui.Offset(10, 10), width: 50, height: 50);
    sb3.addPicture(ui.Offset.zero, rectPicture(const ui.Rect.fromLTWH(0, 0, 300, 300)));
    sb3.addPlatformView(1, offset: const ui.Offset(70, 10), width: 50, height: 50);
    sb3.addPicture(ui.Offset.zero, rectPicture(const ui.Rect.fromLTWH(0, 0, 300, 300)));
    sb3.addPlatformView(2, offset: const ui.Offset(130, 10), width: 50, height: 50);
    sb3.addPicture(ui.Offset.zero, rectPicture(const ui.Rect.fromLTWH(0, 0, 300, 300)));
    final ui.Scene scene3 = sb3.build();
    await renderScene(scene3);
    _expectSceneMatches(<_EmbeddedViewMarker>[
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
      _platformView,
      _overlay,
    ]);

    // Scene 4: Same as scene 1 but with a placeholder rectangle painted
    // under each platform view. This is closer to how the real Flutter
    // framework would render a grid of platform views. Interestingly, in this
    // case every drawing can go in a base canvas.
    final ui.SceneBuilder sb4 = ui.SceneBuilder();
    sb4.pushOffset(0, 0);
    sb4.addPicture(ui.Offset.zero, rectPicture(const ui.Rect.fromLTWH(0, 0, 300, 300)));
    sb4.addPicture(ui.Offset.zero, rectPicture(const ui.Rect.fromLTWH(10, 10, 50, 50)));
    sb4.addPlatformView(0, offset: const ui.Offset(10, 10), width: 50, height: 50);
    sb4.addPicture(ui.Offset.zero, rectPicture(const ui.Rect.fromLTWH(70, 10, 50, 50)));
    sb4.addPlatformView(1, offset: const ui.Offset(70, 10), width: 50, height: 50);
    sb4.addPicture(ui.Offset.zero, rectPicture(const ui.Rect.fromLTWH(130, 10, 50, 50)));
    sb4.addPlatformView(2, offset: const ui.Offset(130, 10), width: 50, height: 50);
    final ui.Scene scene4 = sb4.build();
    await renderScene(scene4);
    _expectSceneMatches(<_EmbeddedViewMarker>[
      _overlay,
      _platformView,
      _platformView,
      _platformView,
    ]);

    // Scene 5: A combination of scene 1 and scene 4, where a subtitle is
    // painted over each platform view and a placeholder is painted under each
    // one.
    final ui.SceneBuilder sb5 = ui.SceneBuilder();
    sb5.pushOffset(0, 0);
    sb5.addPicture(ui.Offset.zero, rectPicture(const ui.Rect.fromLTWH(0, 0, 300, 300)));
    sb5.addPicture(ui.Offset.zero, rectPicture(const ui.Rect.fromLTWH(10, 10, 50, 50)));
    sb5.addPlatformView(0, offset: const ui.Offset(10, 10), width: 50, height: 50);
    sb5.addPicture(ui.Offset.zero, rectPicture(const ui.Rect.fromLTWH(12, 12, 10, 10)));
    sb5.addPicture(ui.Offset.zero, rectPicture(const ui.Rect.fromLTWH(70, 10, 50, 50)));
    sb5.addPlatformView(1, offset: const ui.Offset(70, 10), width: 50, height: 50);
    sb5.addPicture(ui.Offset.zero, rectPicture(const ui.Rect.fromLTWH(72, 12, 10, 10)));
    sb5.addPicture(ui.Offset.zero, rectPicture(const ui.Rect.fromLTWH(130, 10, 50, 50)));
    sb5.addPlatformView(2, offset: const ui.Offset(130, 10), width: 50, height: 50);
    sb5.addPicture(ui.Offset.zero, rectPicture(const ui.Rect.fromLTWH(132, 12, 10, 10)));
    final ui.Scene scene5 = sb5.build();
    await renderScene(scene5);
    _expectSceneMatches(<_EmbeddedViewMarker>[
      _overlay,
      _platformView,
      _platformView,
      _platformView,
      _overlay,
    ]);
  });

  test('sinks platform view under the canvas if it does not overlap with the picture', () async {
    ui.Picture rectPicture(double l, double t, double w, double h) {
      final ui.Rect rect = ui.Rect.fromLTWH(l, t, w, h);
      final ui.PictureRecorder testRecorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(testRecorder);
      canvas.drawRect(rect, ui.Paint()..color = const ui.Color.fromARGB(255, 255, 0, 0));
      return testRecorder.endRecording();
    }

    await _createPlatformView(0, platformViewType);
    await _createPlatformView(1, platformViewType);

    expect(PlatformViewManager.instance.isVisible(0), isTrue);
    expect(PlatformViewManager.instance.isVisible(1), isTrue);

    final ui.SceneBuilder sb = ui.SceneBuilder();

    // First picture-view-picture stack.
    {
      sb.pushOffset(0, 0);
      sb.addPicture(ui.Offset.zero, rectPicture(0, 0, 10, 10));
      sb.addPlatformView(0, width: 10, height: 10);
      sb.addPicture(ui.Offset.zero, rectPicture(2, 2, 5, 5));
      sb.pop();
    }

    // Second picture-view-picture stack that does not overlap with the first one.
    {
      sb.pushOffset(20, 0);
      sb.addPicture(ui.Offset.zero, rectPicture(0, 0, 10, 10));
      sb.addPlatformView(1, width: 10, height: 10);
      sb.addPicture(ui.Offset.zero, rectPicture(2, 2, 5, 5));
      sb.pop();
    }

    final ui.Scene scene1 = sb.build();
    await renderScene(scene1);
    _expectSceneMatches(<_EmbeddedViewMarker>[_overlay, _platformView, _platformView, _overlay]);
  });

  test('optimizes overlays correctly with transforms and clips', () async {
    ui.Picture rectPicture(ui.Rect rect) {
      final ui.PictureRecorder testRecorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(testRecorder);
      canvas.drawRect(rect, ui.Paint()..color = const ui.Color.fromARGB(255, 255, 0, 0));
      return testRecorder.endRecording();
    }

    await _createPlatformView(0, platformViewType);

    expect(PlatformViewManager.instance.isVisible(0), isTrue);

    // Test optimization correctly computes bounds with transforms and clips.
    final ui.SceneBuilder sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    final Matrix4 scaleMatrix = Matrix4.identity()..scale(3, 3, 1);
    sb.pushTransform(scaleMatrix.toFloat64());
    sb.pushClipRect(const ui.Rect.fromLTWH(10, 10, 10, 10));
    sb.addPicture(ui.Offset.zero, rectPicture(const ui.Rect.fromLTWH(0, 0, 20, 20)));
    sb.addPlatformView(0, width: 20, height: 20);
    final ui.Scene scene = sb.build();
    await renderScene(scene);
    _expectSceneMatches(<_EmbeddedViewMarker>[_overlay, _platformView]);
  });
}

// Sends a platform message to create a Platform View with the given id and viewType.
Future<void> _createPlatformView(int id, String viewType) {
  final Completer<void> completer = Completer<void>();
  const MethodCodec codec = StandardMethodCodec();
  ui.PlatformDispatcher.instance.sendPlatformMessage(
    'flutter/platform_views',
    codec.encodeMethodCall(MethodCall('create', <String, dynamic>{'id': id, 'viewType': viewType})),
    (dynamic _) => completer.complete(),
  );
  return completer.future;
}

/// Disposes of the platform view with the given [id].
Future<void> _disposePlatformView(int id) {
  final Completer<void> completer = Completer<void>();
  const MethodCodec codec = StandardMethodCodec();
  ui.PlatformDispatcher.instance.sendPlatformMessage(
    'flutter/platform_views',
    codec.encodeMethodCall(MethodCall('dispose', id)),
    (dynamic _) => completer.complete(),
  );
  return completer.future;
}

// Returns the list of CSS transforms applied to the ancestor chain of
// elements starting from `viewHost`, up until and excluding <flt-scene>.
List<String> getTransformChain(DomElement viewHost) {
  final List<String> chain = <String>[];
  DomElement? element = viewHost;
  while (element != null && element.tagName.toLowerCase() != 'flt-scene') {
    chain.add(element.style.transform);
    element = element.parent;
  }
  return chain;
}

// Used to test that the platform views and overlays are in the correct order in
// the scene.
enum _EmbeddedViewMarker { overlay, platformView }

_EmbeddedViewMarker get _overlay => _EmbeddedViewMarker.overlay;
_EmbeddedViewMarker get _platformView => _EmbeddedViewMarker.platformView;

const Map<String, _EmbeddedViewMarker> _tagToViewMarker = <String, _EmbeddedViewMarker>{
  'flt-canvas-container': _EmbeddedViewMarker.overlay,
  'flt-platform-view-slot': _EmbeddedViewMarker.platformView,
  'flt-clip': _EmbeddedViewMarker.platformView,
};

void _expectSceneMatches(List<_EmbeddedViewMarker> expectedMarkers, {String? reason}) {
  final DomElement fltScene = sceneHost.querySelector('flt-scene')!;
  // Convert the scene elements to its corresponding array of _EmbeddedViewMarker
  final List<_EmbeddedViewMarker> sceneElements = fltScene.children
      .where((DomElement element) => element.tagName != 'svg')
      .map((DomElement element) => _tagToViewMarker[element.tagName.toLowerCase()]!)
      .toList();

  expect(sceneElements, expectedMarkers, reason: reason);
}
