// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SnapshotWidget can rasterize child', (final WidgetTester tester) async {
    final SnapshotController controller = SnapshotController(allowSnapshotting: true);
    final Key key = UniqueKey();
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: TestDependencies(
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
    await expectLater(find.byKey(key), matchesGoldenFile('raster_widget.yellow.png'));

    // Now change the color and assert the old snapshot still matches.
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: TestDependencies(
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
    await expectLater(find.byKey(key), matchesGoldenFile('raster_widget.yellow.png'));

    // Now invoke clear and the raster is re-generated.
    controller.clear();
    await tester.pump();

    await expectLater(find.byKey(key), matchesGoldenFile('raster_widget.red.png'));
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689

  testWidgets('Changing devicePixelRatio does not repaint if snapshotting is not enabled', (final WidgetTester tester) async {
    final SnapshotController controller = SnapshotController();
    final TestPainter painter = TestPainter();
    double devicePixelRatio = 1.0;
    late StateSetter localSetState;

    await tester.pumpWidget(
      StatefulBuilder(builder: (final BuildContext context, final StateSetter setState) {
        localSetState = setState;
        return Center(
          child: TestDependencies(
            devicePixelRatio: devicePixelRatio,
            child: SnapshotWidget(
              controller: controller,
              painter: painter,
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        );
      }),
    );

    expect(painter.count, 1);

    localSetState(() {
      devicePixelRatio = 2.0;
    });
    await tester.pump();

    // Not repainted as dpr was not used.
    expect(painter.count, 1);
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689

  testWidgets('Changing devicePixelRatio forces raster regeneration', (final WidgetTester tester) async {
    final SnapshotController controller = SnapshotController(allowSnapshotting: true);
    final TestPainter painter = TestPainter();
    double devicePixelRatio = 1.0;
    late StateSetter localSetState;

    await tester.pumpWidget(
      StatefulBuilder(builder: (final BuildContext context, final StateSetter setState) {
        localSetState = setState;
        return Center(
          child: TestDependencies(
            devicePixelRatio: devicePixelRatio,
            child: SnapshotWidget(
              controller: controller,
              painter: painter,
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        );
      }),
    );
    final ui.Image? raster = painter.lastImage;

    expect(raster, isNotNull);
    expect(painter.count, 1);

    localSetState(() {
      devicePixelRatio = 2.0;
    });
    await tester.pump();

    final ui.Image? newRaster = painter.lastImage;

    expect(painter.count, 2);
    expect(raster, isNot(newRaster));
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689

  testWidgets('SnapshotWidget paints its child as a single picture layer', (final WidgetTester tester) async {
    final SnapshotController controller = SnapshotController(allowSnapshotting: true);
    await tester.pumpWidget(RepaintBoundary(
      child: Center(
        child: TestDependencies(
          child: SnapshotWidget(
            controller: controller,
            child: Container(
              width: 100,
              height: 100,
              color: const Color(0xFFAABB11),
            ),
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

  testWidgets('SnapshotWidget can update the painter type', (final WidgetTester tester) async {
    final SnapshotController controller = SnapshotController(allowSnapshotting: true);
    await tester.pumpWidget(
      Center(
        child: TestDependencies(
          child: SnapshotWidget(
            controller: controller,
            painter: TestPainter(),
            child: const SizedBox(),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      Center(
        child: TestDependencies(
          child: SnapshotWidget(
            controller: controller,
            painter: TestPainter2(),
            child: const SizedBox(),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689

  testWidgets('RenderSnapshotWidget does not error on rasterization of child with empty size', (final WidgetTester tester) async {
    final SnapshotController controller = SnapshotController(allowSnapshotting: true);
    await tester.pumpWidget(
      Center(
        child: TestDependencies(
          child: SnapshotWidget(
            controller: controller,
            child: const SizedBox(),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689


  testWidgets('RenderSnapshotWidget throws assertion if platform view is encountered', (final WidgetTester tester) async {
    final SnapshotController controller = SnapshotController(allowSnapshotting: true);
    await tester.pumpWidget(
      Center(
        child: TestDependencies(
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
      .having((final FlutterError error) => error.message, 'message', contains('SnapshotWidget used with a child that contains a PlatformView')));
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689

  testWidgets('RenderSnapshotWidget does not assert if SnapshotMode.forced', (final WidgetTester tester) async {
    final SnapshotController controller = SnapshotController(allowSnapshotting: true);
    await tester.pumpWidget(
      Center(
        child: TestDependencies(
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

  testWidgets('RenderSnapshotWidget does not take a snapshot if a platform view is encountered with SnapshotMode.permissive', (final WidgetTester tester) async {
    final SnapshotController controller = SnapshotController(allowSnapshotting: true);
    await tester.pumpWidget(
      Center(
        child: TestDependencies(
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

  testWidgets('SnapshotWidget should have same result when enabled', (final WidgetTester tester) async {
    addTearDown(tester.view.reset);

    tester.view
      ..physicalSize = const Size(10, 10)
      ..devicePixelRatio = 1;

    const ValueKey<String> repaintBoundaryKey = ValueKey<String>('boundary');
    final SnapshotController controller = SnapshotController();
    await tester.pumpWidget(RepaintBoundary(
      key: repaintBoundaryKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Container(
          color: Colors.black,
          padding: const EdgeInsets.only(right: 0.6, bottom: 0.6),
          child: SnapshotWidget(
            controller: controller,
            child: Container(
              margin: const EdgeInsets.only(right: 0.4, bottom: 0.4),
              color: Colors.blue,
            ),
          ),
        ),
      ),
    ));

    final ui.Image imageWhenDisabled = (tester.renderObject(find.byKey(repaintBoundaryKey)) as RenderRepaintBoundary).toImageSync();

    controller.allowSnapshotting = true;
    await tester.pump();

    await expectLater(find.byKey(repaintBoundaryKey), matchesReferenceImage(imageWhenDisabled));
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689
}

class TestPlatformView extends SingleChildRenderObjectWidget {
  const TestPlatformView({super.key});

  @override
  RenderObject createRenderObject(final BuildContext context) {
    return RenderTestPlatformView();
  }
}

class RenderTestPlatformView extends RenderProxyBox {
  @override
  void paint(final PaintingContext context, final ui.Offset offset) {
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
  void addListener(final ui.VoidCallback listener) {
    addedListenerCount += 1;
    super.addListener(listener);
  }

  @override
  void removeListener(final ui.VoidCallback listener) {
    removedListenerCount += 1;
    super.removeListener(listener);
  }

  void notify() {
    notifyListeners();
  }

  @override
  void paintSnapshot(final PaintingContext context, final Offset offset, final Size size, final ui.Image image, final Size sourceSize, final double pixelRatio) {
    count += 1;
    lastImage = image;
  }

  @override
  void paint(final PaintingContext context, final ui.Offset offset, final ui.Size size, final PaintingContextCallback painter) {
    count += 1;
  }

  @override
  bool shouldRepaint(covariant final TestPainter oldDelegate) => shouldRepaintValue;
}

class TestPainter2 extends TestPainter {
  @override
  bool shouldRepaint(covariant final TestPainter2 oldDelegate) => shouldRepaintValue;
}

class TestDependencies extends StatelessWidget {
  const TestDependencies({required this.child, super.key, this.devicePixelRatio});

  final Widget child;
  final double? devicePixelRatio;

  @override
  Widget build(final BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData().copyWith(devicePixelRatio: devicePixelRatio),
        child: child,
      ),
    );
  }
}
