// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import 'package:ui/ui.dart' as ui;

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
        PlatformView(1, platformViewRect.size, PlatformViewStyling(
          position: PlatformViewPosition.offset(platformViewRect.topLeft)
        ))
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
        PlatformView(1, platformViewRect.size, PlatformViewStyling(
          position: PlatformViewPosition.offset(platformViewRect.topLeft)
        ))
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
        PlatformView(1, platformViewRect.size, PlatformViewStyling(
          position: PlatformViewPosition.offset(platformViewRect.topLeft)
        ))
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
        PlatformView(1, platformViewRect.size, PlatformViewStyling(
          position: PlatformViewPosition.offset(platformViewRect.topLeft)
        ))
      ]));
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
        return false;
      }
      if (expectedView.size != actualView.size) {
        return false;
      }
      if (expectedView.styling != actualView.styling) {
        return false;
      }
    }
    return true;
  }
}

class StubPicture implements ScenePicture {
  StubPicture(this.cullRect);

  @override
  final ui.Rect cullRect;

  @override
  int get approximateBytesUsed => throw UnimplementedError();

  @override
  bool get debugDisposed => throw UnimplementedError();

  @override
  void dispose() {}

  @override
  Future<ui.Image> toImage(int width, int height) {
    throw UnimplementedError();
  }

  @override
  ui.Image toImageSync(int width, int height) {
    throw UnimplementedError();
  }
}

class StubCompositePicture extends StubPicture {
  StubCompositePicture(this.children) : super(
    children.fold(null, (ui.Rect? previousValue, StubPicture child) {
      return previousValue?.expandToInclude(child.cullRect) ?? child.cullRect;
    })!
  );

  final List<StubPicture> children;
}

class StubPictureRecorder implements ui.PictureRecorder {
  StubPictureRecorder(this.canvas);

  final StubSceneCanvas canvas;

  @override
  ui.Picture endRecording() {
    return StubCompositePicture(canvas.pictures);
  }

  @override
  bool get isRecording => throw UnimplementedError();
}

class StubSceneCanvas implements SceneCanvas {
  List<StubPicture> pictures = <StubPicture>[];

  @override
  void drawPicture(ui.Picture picture) {
    pictures.add(picture as StubPicture);
  }

  @override
  void clipPath(ui.Path path, {bool doAntiAlias = true}) {}

  @override
  void clipRRect(ui.RRect rrect, {bool doAntiAlias = true}) {}

  @override
  void clipRect(ui.Rect rect, {ui.ClipOp clipOp = ui.ClipOp.intersect, bool doAntiAlias = true}) {}

  @override
  void drawArc(ui.Rect rect, double startAngle, double sweepAngle, bool useCenter, ui.Paint paint) {}

  @override
  void drawAtlas(ui.Image atlas, List<ui.RSTransform> transforms, List<ui.Rect> rects, List<ui.Color>? colors, ui.BlendMode? blendMode, ui.Rect? cullRect, ui.Paint paint) {}

  @override
  void drawCircle(ui.Offset c, double radius, ui.Paint paint) {}

  @override
  void drawColor(ui.Color color, ui.BlendMode blendMode) {}

  @override
  void drawDRRect(ui.RRect outer, ui.RRect inner, ui.Paint paint) {}

  @override
  void drawImage(ui.Image image, ui.Offset offset, ui.Paint paint) {}

  @override
  void drawImageNine(ui.Image image, ui.Rect center, ui.Rect dst, ui.Paint paint) {}

  @override
  void drawImageRect(ui.Image image, ui.Rect src, ui.Rect dst, ui.Paint paint) {}

  @override
  void drawLine(ui.Offset p1, ui.Offset p2, ui.Paint paint) {}

  @override
  void drawOval(ui.Rect rect, ui.Paint paint) {}

  @override
  void drawPaint(ui.Paint paint) {}

  @override
  void drawParagraph(ui.Paragraph paragraph, ui.Offset offset) {}

  @override
  void drawPath(ui.Path path, ui.Paint paint) {}

  @override
  void drawPoints(ui.PointMode pointMode, List<ui.Offset> points, ui.Paint paint) {}

  @override
  void drawRRect(ui.RRect rrect, ui.Paint paint) {}

  @override
  void drawRawAtlas(ui.Image atlas, Float32List rstTransforms, Float32List rects, Int32List? colors, ui.BlendMode? blendMode, ui.Rect? cullRect, ui.Paint paint) {}

  @override
  void drawRawPoints(ui.PointMode pointMode, Float32List points, ui.Paint paint) {}

  @override
  void drawRect(ui.Rect rect, ui.Paint paint) {}

  @override
  void drawShadow(ui.Path path, ui.Color color, double elevation, bool transparentOccluder) {}

  @override
  void drawVertices(ui.Vertices vertices, ui.BlendMode blendMode, ui.Paint paint) {}

  @override
  ui.Rect getDestinationClipBounds() {
    throw UnimplementedError();
  }

  @override
  ui.Rect getLocalClipBounds() {
    throw UnimplementedError();
  }

  @override
  int getSaveCount() {
    throw UnimplementedError();
  }

  @override
  Float64List getTransform() {
    throw UnimplementedError();
  }

  @override
  void restore() {}

  @override
  void restoreToCount(int count) {}

  @override
  void rotate(double radians) {}

  @override
  void save() {}

  @override
  void saveLayer(ui.Rect? bounds, ui.Paint paint) {}

  @override
  void saveLayerWithFilter(ui.Rect? bounds, ui.Paint paint, ui.ImageFilter backdropFilter) {}

  @override
  void scale(double sx, [double? sy]) {}

  @override
  void skew(double sx, double sy) {}

  @override
  void transform(Float64List matrix4) {}

  @override
  void translate(double dx, double dy) {}
}
