// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
import 'dart:async';
import 'dart:html' as html;

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

import 'common.dart';

const MethodCodec codec = StandardMethodCodec();
final EngineSingletonFlutterWindow window =
    EngineSingletonFlutterWindow(0, EnginePlatformDispatcher.instance);

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('HtmlViewEmbedder', () {
    setUpCanvasKitTest();

    test('embeds interactive platform views', () async {
      ui.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (viewId) => html.DivElement()..id = 'view-0',
      );
      await _createPlatformView(0, 'test-platform-view');

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;
      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      dispatcher.rasterizer!.draw(sb.build().layerTree);
      expect(
        domRenderer.sceneElement!
            .querySelectorAll('#view-0')
            .single
            .style
            .pointerEvents,
        'auto',
      );
    });

    test('correctly transforms platform views', () async {
      ui.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (viewId) => html.DivElement()..id = 'view-0',
      );
      await _createPlatformView(0, 'test-platform-view');

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;
      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      Matrix4 scaleMatrix = Matrix4.identity()
        ..scale(5, 5)
        ..translate(100, 100);
      sb.pushTransform(scaleMatrix.toFloat64());
      sb.pushOffset(3, 3);
      sb.addPlatformView(0, width: 10, height: 10);
      dispatcher.rasterizer!.draw(sb.build().layerTree);
      expect(
        domRenderer.sceneElement!
            .querySelectorAll('#view-0')
            .single
            .style
            .transform,
        // We should apply the scale matrix first, then the offset matrix.
        // So the translate should be 515 (5 * 100 + 5 * 3), and not
        // 503 (5 * 100 + 3).
        'matrix3d(5, 0, 0, 0, 0, 5, 0, 0, 0, 0, 5, 0, 515, 515, 0, 1)',
      );
    });
    // TODO: https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}

// Sends a platform message to create a Platform View with the given id and viewType.
Future<void> _createPlatformView(int id, String viewType) {
  final completer = Completer<void>();
  window.sendPlatformMessage(
    'flutter/platform_views',
    codec.encodeMethodCall(MethodCall(
      'create',
      <String, dynamic>{
        'id': id,
        'viewType': viewType,
      },
    )),
    (dynamic _) => completer.complete(),
  );
  return completer.future;
}
