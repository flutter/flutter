// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import '../common/matchers.dart';
import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('MultiView', () {
    setUpUnitTests(withImplicitView: true);

    late ui.Scene scene;

    setUp(() {
      // Create a scene to use in tests.
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder, const ui.Rect.fromLTRB(0, 0, 60, 60));
      canvas.drawRect(
        const ui.Rect.fromLTRB(0, 0, 60, 60),
        ui.Paint()..style = ui.PaintingStyle.fill,
      );
      final ui.Picture picture = recorder.endRecording();
      final sb = ui.SceneBuilder();
      sb.addPicture(ui.Offset.zero, picture);
      scene = sb.build();
    });

    test('can render into arbitrary views', () async {
      await renderer.renderScene(scene, implicitView as EngineFlutterView);

      final anotherView = EngineFlutterView(
        EnginePlatformDispatcher.instance,
        createDomElement('another-view'),
      );
      EnginePlatformDispatcher.instance.viewManager.registerView(anotherView);

      await renderer.renderScene(scene, anotherView);
    });

    test('will error if trying to render into an unregistered view', () async {
      final unregisteredView = EngineFlutterView(
        EnginePlatformDispatcher.instance,
        createDomElement('unregistered-view'),
      );
      expect(() => renderer.renderScene(scene, unregisteredView), throwsAssertionError);
    });

    test('will dispose the Rasterizer for a disposed view', () async {
      final view = EngineFlutterView(
        EnginePlatformDispatcher.instance,
        createDomElement('multi-view'),
      );
      EnginePlatformDispatcher.instance.viewManager.registerView(view);
      expect(renderer.rasterizers[view.viewId], isNotNull);

      EnginePlatformDispatcher.instance.viewManager.disposeAndUnregisterView(view.viewId);
      expect(renderer.rasterizers[view.viewId], isNull);
    });

    // Issue https://github.com/flutter/flutter/issues/142094
    test('does not reset platform view factories when disposing a view', () async {
      expect(PlatformViewManager.instance.knowsViewType('self-test'), isFalse);

      final view = EngineFlutterView(
        EnginePlatformDispatcher.instance,
        createDomElement('multi-view'),
      );
      EnginePlatformDispatcher.instance.viewManager.registerView(view);
      expect(renderer.rasterizers[view.viewId], isNotNull);

      EnginePlatformDispatcher.instance.viewManager.disposeAndUnregisterView(view.viewId);
      expect(renderer.rasterizers[view.viewId], isNull);

      expect(
        PlatformViewManager.instance.knowsViewType(
          ui_web.PlatformViewRegistry.defaultVisibleViewType,
        ),
        isTrue,
      );
      expect(
        PlatformViewManager.instance.knowsViewType(
          ui_web.PlatformViewRegistry.defaultInvisibleViewType,
        ),
        isTrue,
      );
    });
  });
}
