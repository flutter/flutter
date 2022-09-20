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

  testWidgets('Changing devicePixelRatio does not repaint if snapshotting is not enabled', (WidgetTester tester) async {
    final SnapshotController controller = SnapshotController();
    final TestPainter painter = TestPainter();
    double devicePixelRatio = 1.0;
    late StateSetter localSetState;

    await tester.pumpWidget(
      StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
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

  testWidgets('Changing devicePixelRatio forces raster regeneration', (WidgetTester tester) async {
    final SnapshotController controller = SnapshotController(allowSnapshotting: true);
    final TestPainter painter = TestPainter();
    double devicePixelRatio = 1.0;
    late StateSetter localSetState;

    await tester.pumpWidget(
      StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
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

  testWidgets('SnapshotWidget paints its child as a single picture layer', (WidgetTester tester) async {
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

  testWidgets('SnapshotWidget can update the painter type', (WidgetTester tester) async {
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

  testWidgets('RenderSnapshotWidget does not error on rasterization of child with empty size', (WidgetTester tester) async {
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


  testWidgets('RenderSnapshotWidget throws assertion if platform view is encountered', (WidgetTester tester) async {
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
      .having((FlutterError error) => error.message, 'message', contains('SnapshotWidget used with a child that contains a PlatformView')));
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689

  testWidgets('RenderSnapshotWidget does not assert if SnapshotMode.forced', (WidgetTester tester) async {
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

  testWidgets('RenderSnapshotWidget does not take a snapshot if a platform view is encounted with SnapshotMode.permissive', (WidgetTester tester) async {
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
    count += 1;
  }

  @override
  bool shouldRepaint(covariant TestPainter oldDelegate) => shouldRepaintValue;
}

class TestPainter2 extends TestPainter {
  @override
  bool shouldRepaint(covariant TestPainter2 oldDelegate) => shouldRepaintValue;
}

class TestDependencies extends StatelessWidget {
  const TestDependencies({required this.child, super.key, this.devicePixelRatio});

  final Widget child;
  final double? devicePixelRatio;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData.fromWindow(WidgetsBinding.instance.window)
          .copyWith(devicePixelRatio: devicePixelRatio),
        child: child,
      ),
    );
  }
}
