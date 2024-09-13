// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import 'package:ui/ui.dart' as ui;

import 'scene_builder_utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  setUpAll(() {
    LayerBuilder.debugRecorderFactory = (ui.Rect rect) {
      final StubSceneCanvas canvas = StubSceneCanvas();
      final StubPictureRecorder recorder = StubPictureRecorder(canvas);
      return (recorder, canvas);
    };
  });

  tearDownAll(() {
    LayerBuilder.debugRecorderFactory = null;
  });

  group('EngineSceneBuilder', () {
    test('single picture', () {
      final EngineSceneBuilder sceneBuilder = EngineSceneBuilder();

      const ui.Rect pictureRect = ui.Rect.fromLTRB(100, 100, 200, 200);
      sceneBuilder.addPicture(ui.Offset.zero, StubPicture(pictureRect));

      final EngineScene scene = sceneBuilder.build() as EngineScene;
      final List<LayerSlice> slices = scene.rootLayer.slices;
      expect(slices.length, 1);
      expect(slices[0], pictureSliceWithRect(pictureRect));
    });

    test('two pictures', () {
      final EngineSceneBuilder sceneBuilder = EngineSceneBuilder();

      const ui.Rect pictureRect1 = ui.Rect.fromLTRB(100, 100, 200, 200);
      const ui.Rect pictureRect2 = ui.Rect.fromLTRB(300, 400, 400, 400);
      sceneBuilder.addPicture(ui.Offset.zero, StubPicture(pictureRect1));
      sceneBuilder.addPicture(ui.Offset.zero, StubPicture(pictureRect2));

      final EngineScene scene = sceneBuilder.build() as EngineScene;
      final List<LayerSlice> slices = scene.rootLayer.slices;
      expect(slices.length, 1);
      expect(slices[0], pictureSliceWithRect(const ui.Rect.fromLTRB(100, 100, 400, 400)));
    });

    test('picture + platform view (overlapping)', () {
            final EngineSceneBuilder sceneBuilder = EngineSceneBuilder();

      const ui.Rect pictureRect = ui.Rect.fromLTRB(100, 100, 200, 200);
      const ui.Rect platformViewRect = ui.Rect.fromLTRB(150, 150, 250, 250);
      sceneBuilder.addPicture(ui.Offset.zero, StubPicture(pictureRect));
      sceneBuilder.addPlatformView(
        1,
        offset: platformViewRect.topLeft,
        width: platformViewRect.width,
        height: platformViewRect.height
      );

      final EngineScene scene = sceneBuilder.build() as EngineScene;
      final List<LayerSlice> slices = scene.rootLayer.slices;
      expect(slices.length, 2);
      expect(slices[0], pictureSliceWithRect(pictureRect));
      expect(slices[1], platformViewSliceWithViews(<PlatformView>[
        PlatformView(1, platformViewRect, const PlatformViewStyling())
      ]));
    });

    test('platform view + picture (overlapping)', () {
      final EngineSceneBuilder sceneBuilder = EngineSceneBuilder();

      const ui.Rect pictureRect = ui.Rect.fromLTRB(100, 100, 200, 200);
      const ui.Rect platformViewRect = ui.Rect.fromLTRB(150, 150, 250, 250);
      sceneBuilder.addPlatformView(
        1,
        offset: platformViewRect.topLeft,
        width: platformViewRect.width,
        height: platformViewRect.height
      );
      sceneBuilder.addPicture(ui.Offset.zero, StubPicture(pictureRect));

      final EngineScene scene = sceneBuilder.build() as EngineScene;
      final List<LayerSlice> slices = scene.rootLayer.slices;
      expect(slices.length, 2);
      expect(slices[0], platformViewSliceWithViews(<PlatformView>[
        PlatformView(1, platformViewRect, const PlatformViewStyling())
      ]));
      expect(slices[1], pictureSliceWithRect(pictureRect));
    });

    test('platform view sandwich (overlapping)', () {
      final EngineSceneBuilder sceneBuilder = EngineSceneBuilder();

      const ui.Rect pictureRect1 = ui.Rect.fromLTRB(100, 100, 200, 200);
      const ui.Rect platformViewRect = ui.Rect.fromLTRB(150, 150, 250, 250);
      const ui.Rect pictureRect2 = ui.Rect.fromLTRB(200, 200, 300, 300);
      sceneBuilder.addPicture(ui.Offset.zero, StubPicture(pictureRect1));
      sceneBuilder.addPlatformView(
        1,
        offset: platformViewRect.topLeft,
        width: platformViewRect.width,
        height: platformViewRect.height
      );
      sceneBuilder.addPicture(ui.Offset.zero, StubPicture(pictureRect2));

      final EngineScene scene = sceneBuilder.build() as EngineScene;
      final List<LayerSlice> slices = scene.rootLayer.slices;
      expect(slices.length, 3);
      expect(slices[0], pictureSliceWithRect(pictureRect1));
      expect(slices[1], platformViewSliceWithViews(<PlatformView>[
        PlatformView(1, platformViewRect, const PlatformViewStyling())
      ]));
      expect(slices[2], pictureSliceWithRect(pictureRect2));
    });

    test('platform view sandwich (non-overlapping)', () {
      final EngineSceneBuilder sceneBuilder = EngineSceneBuilder();

      const ui.Rect pictureRect1 = ui.Rect.fromLTRB(100, 100, 200, 200);
      const ui.Rect platformViewRect = ui.Rect.fromLTRB(150, 150, 250, 250);
      const ui.Rect pictureRect2 = ui.Rect.fromLTRB(50, 50, 100, 100);
      sceneBuilder.addPicture(ui.Offset.zero, StubPicture(pictureRect1));
      sceneBuilder.addPlatformView(
        1,
        offset: platformViewRect.topLeft,
        width: platformViewRect.width,
        height: platformViewRect.height
      );
      sceneBuilder.addPicture(ui.Offset.zero, StubPicture(pictureRect2));

      final EngineScene scene = sceneBuilder.build() as EngineScene;
      final List<LayerSlice> slices = scene.rootLayer.slices;

      // The top picture does not overlap with the platform view, so it should
      // be grouped into the slice below it to reduce the number of canvases we
      // need.
      expect(slices.length, 2);
      expect(slices[0], pictureSliceWithRect(const ui.Rect.fromLTRB(50, 50, 200, 200)));
      expect(slices[1], platformViewSliceWithViews(<PlatformView>[
        PlatformView(1, platformViewRect, const PlatformViewStyling())
      ]));
    });

    test('platform view sandwich (overlapping) with offset layers', () {
      final EngineSceneBuilder sceneBuilder = EngineSceneBuilder();

      const ui.Rect pictureRect1 = ui.Rect.fromLTRB(100, 100, 200, 200);
      sceneBuilder.addPicture(ui.Offset.zero, StubPicture(pictureRect1));

      sceneBuilder.pushOffset(150, 150);
      const ui.Rect platformViewRect = ui.Rect.fromLTRB(0, 0, 100, 100);
      sceneBuilder.addPlatformView(
        1,
        offset: platformViewRect.topLeft,
        width: platformViewRect.width,
        height: platformViewRect.height
      );
      sceneBuilder.pushOffset(50, 50);
      sceneBuilder.addPicture(ui.Offset.zero, StubPicture(const ui.Rect.fromLTRB(0, 0, 100, 100)));

      final EngineScene scene = sceneBuilder.build() as EngineScene;
      final List<LayerSlice> slices = scene.rootLayer.slices;
      expect(slices.length, 3);
      expect(slices[0], pictureSliceWithRect(pictureRect1));
      expect(slices[1], platformViewSliceWithViews(<PlatformView>[
        PlatformView(1, platformViewRect, const PlatformViewStyling(position: PlatformViewPosition.offset(ui.Offset(150, 150))))
      ]));
      expect(slices[2], pictureSliceWithRect(const ui.Rect.fromLTRB(200, 200, 300, 300)));
    });
  });
}

PictureSliceMatcher pictureSliceWithRect(ui.Rect rect) => PictureSliceMatcher(rect);
PlatformViewSliceMatcher platformViewSliceWithViews(List<PlatformView> views)
  => PlatformViewSliceMatcher(views);

class PictureSliceMatcher extends Matcher {
  PictureSliceMatcher(this.expectedRect);

  final ui.Rect expectedRect;

  @override
  Description describe(Description description) {
    return description.add('<picture slice with cullRect: $expectedRect>');
  }

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! PictureSlice) {
      return false;
    }
    final ScenePicture picture = item.picture;
    if (picture is! StubPicture) {
      return false;
    }

    if (picture.cullRect != expectedRect) {
      return false;
    }

    return true;
  }
}

class PlatformViewSliceMatcher extends Matcher {
  PlatformViewSliceMatcher(this.expectedPlatformViews);

  final List<PlatformView> expectedPlatformViews;

  @override
  Description describe(Description description) {
    return description.add('<platform view slice with platform views: $expectedPlatformViews>');
  }

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! PlatformViewSlice) {
      return false;
    }

    if (item.views.length != expectedPlatformViews.length) {
      return false;
    }

    for (int i = 0; i < item.views.length; i++) {
      final PlatformView expectedView = expectedPlatformViews[i];
      final PlatformView actualView = item.views[i];
      if (expectedView.viewId != actualView.viewId) {
        print('viewID mismatch');
        return false;
      }
      if (expectedView.bounds != actualView.bounds) {
        print('bounds mismatch');
        return false;
      }
      if (expectedView.styling != actualView.styling) {
        print('styling mismatch');
        return false;
      }
    }
    return true;
  }
}
