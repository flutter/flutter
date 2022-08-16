// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SnapshotWidget can rasterize child', (WidgetTester tester) async {
    final SnapshotController controller = SnapshotController(allowSnapshotting: true);
    final Key key = UniqueKey();
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: Center(
        child: SnapshotWidget(
          controller: controller,
          child: Container(
            width: 100,
            height: 100,
            color: const Color(0xFFAABB11),
          ),
        ),
      ),
    ));
    await tester.pump();
    await expectLater(find.byKey(key), matchesGoldenFile('raster_widget.yellow.png'));

    // Now change the color and assert the old snapshot still matches.
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: Center(
        child: SnapshotWidget(
          controller: controller,
          child: Container(
            width: 100,
            height: 100,
            color: const Color(0xFFAA0000),
          ),
        ),
      ),
    ));
    await tester.pump();
    await expectLater(find.byKey(key), matchesGoldenFile('raster_widget.yellow.png'));

    // Now invoke clear and the raster is re-generated.
    controller.clear();

    await tester.pump();
    await expectLater(find.byKey(key), matchesGoldenFile('raster_widget.red.png'));
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689

  testWidgets('SnapshotWidget paints its child as a single picture layer', (WidgetTester tester) async {
    final SnapshotController controller = SnapshotController(allowSnapshotting: true);
    await tester.pumpWidget(RepaintBoundary(
      child: Center(
        child: SnapshotWidget(
          controller: controller,
          child: Container(
            width: 100,
            height: 100,
            color: const Color(0xFFAABB11),
          ),
        ),
      ),
    ));

    expect(tester.layers, hasLength(3));
    expect(tester.layers.last, isA<PictureLayer>());

    controller.allowSnapshotting = false;
    await tester.pump();

    expect(tester.layers, hasLength(3));
    expect(tester.layers.last, isA<PictureLayer>());
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689

  testWidgets('RenderSnapshotWidget does not error on rasterization of child with empty size', (WidgetTester tester) async {
    final SnapshotController controller = SnapshotController(allowSnapshotting: true);
    await tester.pumpWidget(
      Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SnapshotWidget(
            controller: controller,
            child: const SizedBox(),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689


  testWidgets('RenderSnapshotWidget throws assertion if platform view is encountered', (WidgetTester tester) async {
    final SnapshotController controller = SnapshotController(allowSnapshotting: true);
    await tester.pumpWidget(
      Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SnapshotWidget(
            controller: controller,
            child: const SizedBox(
              width: 100,
              height: 100,
              child: TestPlatformView(),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isA<FlutterError>()
      .having((FlutterError error) => error.message, 'message', contains('SnapshotWidget used with a child that contains a PlatformView')));
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689

  testWidgets('RenderSnapshotWidget does not assert if SnapshotMode.forced', (WidgetTester tester) async {
    final SnapshotController controller = SnapshotController(allowSnapshotting: true);
    await tester.pumpWidget(
      Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SnapshotWidget(
            controller: controller,
            mode: SnapshotMode.forced,
            child: const SizedBox(
              width: 100,
              height: 100,
              child: TestPlatformView(),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689

  testWidgets('RenderSnapshotWidget does not take a snapshot if a platform view is encounted with SnapshotMode.permissive', (WidgetTester tester) async {
    final SnapshotController controller = SnapshotController(allowSnapshotting: true);
    await tester.pumpWidget(
      Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SnapshotWidget(
            controller: controller,
            mode: SnapshotMode.permissive,
            child: const SizedBox(
              width: 100,
              height: 100,
              child: TestPlatformView(),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.layers.last, isA<PlatformViewLayer>());
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689
}

class TestController extends SnapshotController {
  int addedListenerCount = 0;
  int removedListenerCount = 0;

  @override
  void addListener(ui.VoidCallback listener) {
    addedListenerCount += 1;
    super.addListener(listener);
  }

  @override
  void removeListener(ui.VoidCallback listener) {
    removedListenerCount += 1;
    super.removeListener(listener);
  }
}

class TestPlatformView extends SingleChildRenderObjectWidget {
  const TestPlatformView({super.key});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderTestPlatformView();
  }
}

class RenderTestPlatformView extends RenderProxyBox {
  @override
  void paint(PaintingContext context, ui.Offset offset) {
    context.addLayer(PlatformViewLayer(rect: offset & size, viewId: 1));
  }
}

class TestPainter extends SnapshotPainter {
  int count = 0;
  bool shouldRepaintValue = false;
  ui.Image? lastImage;

  int addedListenerCount = 0;
  int removedListenerCount = 0;

  @override
  void addListener(ui.VoidCallback listener) {
    addedListenerCount += 1;
    super.addListener(listener);
  }

  @override
  void removeListener(ui.VoidCallback listener) {
    removedListenerCount += 1;
    super.removeListener(listener);
  }

  void notify() {
    notifyListeners();
  }

  @override
  void paintSnapshot(PaintingContext context, Offset offset, Size size, ui.Image image, double pixelRatio) {
    count += 1;
    lastImage = image;
  }

  @override
  void paint(PaintingContext context, ui.Offset offset, ui.Size size, PaintingContextCallback painter) {

  }

  @override
  bool shouldRepaint(covariant TestPainter oldDelegate) => shouldRepaintValue;
}
