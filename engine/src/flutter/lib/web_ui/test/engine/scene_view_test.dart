// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart';

import 'scene_builder_utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

class StubPictureRenderer implements PictureRenderer {
  final DomCanvasElement scratchCanvasElement = createDomCanvasElement(
      width: 500, height: 500
  );

  @override
  Future<DomImageBitmap> renderPicture(ScenePicture picture) async {
    final ui.Rect cullRect = picture.cullRect;
    final DomImageBitmap bitmap = (await createImageBitmap(
      scratchCanvasElement as JSAny,
      (x: 0, y: 0, width: cullRect.width.toInt(), height: cullRect.height.toInt())
    ).toDart)! as DomImageBitmap;
    return bitmap;
  }
}

void testMain() {
  late EngineSceneView sceneView;
  setUp(() {
    sceneView = EngineSceneView(StubPictureRenderer());
  });

  test('SceneView places canvas according to device-pixel ratio', () async {
    debugOverrideDevicePixelRatio(2.0);

    final StubPicture picture = StubPicture(const ui.Rect.fromLTWH(
      50,
      80,
      100,
      120,
    ));
    final EngineRootLayer rootLayer = EngineRootLayer();
    rootLayer.slices.add(PictureSlice(picture));
    final EngineScene scene = EngineScene(rootLayer);
    await sceneView.renderScene(scene);

    final DomElement sceneElement = sceneView.sceneElement;
    final List<DomElement> children = sceneElement.children.toList();
    expect(children.length, 1);
    final DomElement containerElement = children.first;
    expect(containerElement.tagName, equalsIgnoringCase('flt-canvas-container'));

    final List<DomElement> containerChildren = containerElement.children.toList();
    expect(containerChildren.length, 1);
    final DomElement canvasElement = containerChildren.first;
    final DomCSSStyleDeclaration style = canvasElement.style;
    expect(style.left, '25px');
    expect(style.top, '40px');
    expect(style.width, '50px');
    expect(style.height, '60px');

    debugOverrideDevicePixelRatio(null);
  });

  test('SceneView places canvas according to device-pixel ratio', () async {
    debugOverrideDevicePixelRatio(2.0);

    final PlatformView platformView = PlatformView(
      1,
      const ui.Size(100, 120),
      const PlatformViewStyling(
        position: PlatformViewPosition.offset(ui.Offset(50, 80)),
      )
    );
    final EngineRootLayer rootLayer = EngineRootLayer();
    rootLayer.slices.add(PlatformViewSlice(<PlatformView>[platformView], null));
    final EngineScene scene = EngineScene(rootLayer);
    await sceneView.renderScene(scene);

    final DomElement sceneElement = sceneView.sceneElement;
    final List<DomElement> children = sceneElement.children.toList();
    expect(children.length, 1);
    final DomElement containerElement = children.first;
    expect(containerElement.tagName, equalsIgnoringCase('flt-platform-view-slot'));

    final DomCSSStyleDeclaration style = containerElement.style;
    expect(style.left, '25px');
    expect(style.top, '40px');
    expect(style.width, '50px');
    expect(style.height, '60px');

    debugOverrideDevicePixelRatio(null);
  });
}
