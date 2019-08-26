// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

import 'package:test/test.dart';

import 'matchers.dart';

void main() {
  group('SceneBuilder', () {
    test('pushOffset implements surface lifecycle', () {
      testLayerLifeCycle((SceneBuilder sceneBuilder, EngineLayer oldLayer) {
        return sceneBuilder.pushOffset(10, 20, oldLayer: oldLayer);
      }, () {
        return '''<s><flt-offset></flt-offset></s>''';
      });
    });

    test('pushTransform implements surface lifecycle', () {
      testLayerLifeCycle((SceneBuilder sceneBuilder, EngineLayer oldLayer) {
        return sceneBuilder.pushTransform(
            Matrix4.translationValues(10, 20, 0).storage,
            oldLayer: oldLayer);
      }, () {
        return '''<s><flt-transform></flt-transform></s>''';
      });
    });

    test('pushClipRect implements surface lifecycle', () {
      testLayerLifeCycle((SceneBuilder sceneBuilder, EngineLayer oldLayer) {
        return sceneBuilder.pushClipRect(const Rect.fromLTRB(10, 20, 30, 40),
            oldLayer: oldLayer);
      }, () {
        return '''
<s>
  <clip><clip-i></clip-i></clip>
</s>
''';
      });
    });

    test('pushClipRRect implements surface lifecycle', () {
      testLayerLifeCycle((SceneBuilder sceneBuilder, EngineLayer oldLayer) {
        return sceneBuilder.pushClipRRect(
            RRect.fromLTRBR(10, 20, 30, 40, const Radius.circular(3)),
            oldLayer: oldLayer);
      }, () {
        return '''
<s>
  <rclip><clip-i></clip-i></rclip>
</s>
''';
      });
    });

    test('pushClipPath implements surface lifecycle', () {
      testLayerLifeCycle((SceneBuilder sceneBuilder, EngineLayer oldLayer) {
        final Path path = Path()..addRect(const Rect.fromLTRB(10, 20, 30, 40));
        return sceneBuilder.pushClipPath(path, oldLayer: oldLayer);
      }, () {
        return '''
<s>
  <flt-clippath>
    <svg><defs><clipPath><path></path></clipPath></defs></svg>
  </flt-clippath>
</s>
''';
      });
    });

    test('pushOpacity implements surface lifecycle', () {
      testLayerLifeCycle((SceneBuilder sceneBuilder, EngineLayer oldLayer) {
        return sceneBuilder.pushOpacity(10, oldLayer: oldLayer);
      }, () {
        return '''<s><o></o></s>''';
      });
    });

    test('pushPhysicalShape implements surface lifecycle', () {
      testLayerLifeCycle((SceneBuilder sceneBuilder, EngineLayer oldLayer) {
        final Path path = Path()..addRect(const Rect.fromLTRB(10, 20, 30, 40));
        return sceneBuilder.pushPhysicalShape(
          path: path,
          elevation: 2,
          color: const Color.fromRGBO(0, 0, 0, 1),
          shadowColor: const Color.fromRGBO(0, 0, 0, 1),
          oldLayer: oldLayer,
        );
      }, () {
        return '''<s><pshape><clip-i></clip-i></pshape></s>''';
      });
    });

    test('pushBackdropFilter implements surface lifecycle', () {
      testLayerLifeCycle((SceneBuilder sceneBuilder, EngineLayer oldLayer) {
        return sceneBuilder.pushBackdropFilter(
          ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
          oldLayer: oldLayer,
        );
      }, () {
        return '<s><flt-backdrop>'
            '<flt-backdrop-filter></flt-backdrop-filter>'
            '<flt-backdrop-interior></flt-backdrop-interior>'
            '</flt-backdrop></s>';
      });
    });
  });

  group('parent child lifecycle', () {
    test(
        'build, retain, update, and applyPaint are called the right number of times',
        () {
      final PersistedScene scene1 = PersistedScene(null);
      final PersistedClipRect clip1 =
          PersistedClipRect(null, const Rect.fromLTRB(10, 10, 20, 20));
      final PersistedOpacity opacity = PersistedOpacity(null, 100, Offset.zero);
      final MockPersistedPicture picture = MockPersistedPicture();

      scene1.appendChild(clip1);
      clip1.appendChild(opacity);
      opacity.appendChild(picture);

      expect(picture.retainCount, 0);
      expect(picture.buildCount, 0);
      expect(picture.updateCount, 0);
      expect(picture.applyPaintCount, 0);

      scene1.preroll();
      scene1.build();
      commitScene(scene1);
      expect(picture.retainCount, 0);
      expect(picture.buildCount, 1);
      expect(picture.updateCount, 0);
      expect(picture.applyPaintCount, 1);

      // The second scene graph retains the opacity, but not the clip. However,
      // because the clip didn't change no repaints should happen.
      final PersistedScene scene2 = PersistedScene(scene1);
      final PersistedClipRect clip2 =
          PersistedClipRect(clip1, const Rect.fromLTRB(10, 10, 20, 20));
      clip1.state = PersistedSurfaceState.pendingUpdate;
      scene2.appendChild(clip2);
      opacity.state = PersistedSurfaceState.pendingRetention;
      clip2.appendChild(opacity);

      scene2.preroll();
      scene2.update(scene1);
      commitScene(scene1);
      expect(picture.retainCount, 1);
      expect(picture.buildCount, 1);
      expect(picture.updateCount, 0);
      expect(picture.applyPaintCount, 1);

      // The third scene graph retains the opacity, and produces a new clip.
      // This should cause the picture to repaint despite being retained.
      final PersistedScene scene3 = PersistedScene(scene2);
      final PersistedClipRect clip3 =
          PersistedClipRect(clip2, const Rect.fromLTRB(10, 10, 50, 50));
      clip2.state = PersistedSurfaceState.pendingUpdate;
      scene3.appendChild(clip3);
      opacity.state = PersistedSurfaceState.pendingRetention;
      clip3.appendChild(opacity);

      scene3.preroll();
      scene3.update(scene2);
      commitScene(scene1);
      expect(picture.retainCount, 2);
      expect(picture.buildCount, 1);
      expect(picture.updateCount, 0);
      expect(picture.applyPaintCount, 2);
    });
  });
}

typedef TestLayerBuilder = EngineLayer Function(
    SceneBuilder sceneBuilder, EngineLayer oldLayer);
typedef ExpectedHtmlGetter = String Function();

void testLayerLifeCycle(
    TestLayerBuilder layerBuilder, ExpectedHtmlGetter expectedHtmlGetter) {
  // Force scene builder to start from scratch. This guarantees that the first
  // scene starts from the "build" phase.
  SceneBuilder.debugForgetFrameScene();

  // Build: builds a brand new layer.
  SceneBuilder sceneBuilder = SceneBuilder();
  final EngineLayer layer1 = layerBuilder(sceneBuilder, null);
  final Type surfaceType = layer1.runtimeType;
  sceneBuilder.pop();

  SceneTester tester = SceneTester(sceneBuilder.build());
  tester.expectSceneHtml(expectedHtmlGetter());

  PersistedSurface findSurface() {
    return enumerateSurfaces()
        .where((PersistedSurface s) => s.runtimeType == surfaceType)
        .single;
  }

  final PersistedSurface surface1 = findSurface();
  final html.Element surfaceElement1 = surface1.rootElement;

  // Retain: reuses a layer as is along with its DOM elements.
  sceneBuilder = SceneBuilder();
  sceneBuilder.addRetained(layer1);

  tester = SceneTester(sceneBuilder.build());
  tester.expectSceneHtml(expectedHtmlGetter());

  final PersistedSurface surface2 = findSurface();
  final html.Element surfaceElement2 = surface2.rootElement;

  expect(surface2, same(surface1));
  expect(surfaceElement2, same(surfaceElement1));

  // Reuse: reuses a layer's DOM elements by matching it.
  sceneBuilder = SceneBuilder();
  final EngineLayer layer3 = layerBuilder(sceneBuilder, layer1);
  sceneBuilder.pop();
  expect(layer3, isNot(same(layer1)));
  tester = SceneTester(sceneBuilder.build());
  tester.expectSceneHtml(expectedHtmlGetter());

  final PersistedSurface surface3 = findSurface();
  expect(surface3, same(layer3));
  final html.Element surfaceElement3 = surface3.rootElement;
  expect(surface3, isNot(same(surface2)));
  expect(surfaceElement3, isNotNull);
  expect(surfaceElement3, same(surfaceElement2));

  // Recycle: discards all the layers.
  sceneBuilder = SceneBuilder();
  tester = SceneTester(sceneBuilder.build());
  tester.expectSceneHtml('<s></s>');

  expect(surface3.rootElement, isNull); // offset3 should be recycled.

  // Retain again: the framework should be able to request that a layer is added
  //               as retained even after it has been recycled. In this case the
  //               engine would "rehydrate" the layer with new DOM elements.
  sceneBuilder = SceneBuilder();
  sceneBuilder.addRetained(layer3);
  tester = SceneTester(sceneBuilder.build());
  tester.expectSceneHtml(expectedHtmlGetter());
  expect(surface3.rootElement, isNotNull); // offset3 should be rehydrated.

  // Make sure we clear retained surface list.
  expect(debugRetainedSurfaces, isEmpty);
}

class MockPersistedPicture extends PersistedPicture {
  factory MockPersistedPicture() {
    final PictureRecorder recorder = PictureRecorder();
    // Use the largest cull rect so that layer clips are effective. The tests
    // rely on this.
    recorder.beginRecording(Rect.largest)..drawPaint(Paint());
    return MockPersistedPicture._(recorder.endRecording());
  }

  MockPersistedPicture._(Picture picture) : super(0, 0, picture, 0);

  int retainCount = 0;
  int buildCount = 0;
  int updateCount = 0;
  int applyPaintCount = 0;

  @override
  double matchForUpdate(PersistedPicture existingSurface) {
    return identical(existingSurface.picture, picture) ? 0.0 : 1.0;
  }

  @override
  Matrix4 get localTransformInverse => null;

  @override
  void build() {
    super.build();
    buildCount++;
  }

  @override
  void retain() {
    super.retain();
    retainCount++;
  }

  @override
  void applyPaint(EngineCanvas oldCanvas) {
    applyPaintCount++;
  }

  @override
  void update(PersistedPicture oldSurface) {
    super.update(oldSurface);
    updateCount++;
  }

  @override
  int get bitmapPixelCount => 0;
}
