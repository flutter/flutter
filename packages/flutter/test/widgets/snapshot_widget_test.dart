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
  testWidgets('RasterWidget can rasterize child', (WidgetTester tester) async {
    final SnapshotWidgetController controller = SnapshotWidgetController(enabled: true);
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
    // Rasterization is not actually complete until a frame has been pumped through
    // the engine.
    await tester.pumpAndSettle();

    await expectLater(find.byKey(key), matchesGoldenFile('raster_widget.yellow.png'));
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689

  testWidgets('RasterWidget is not a repaint boundary when rasterizing', (WidgetTester tester) async {
    final SnapshotWidgetController controller = SnapshotWidgetController(enabled: true);
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

    controller.enabled = false;
    await tester.pump();

    expect(tester.layers, hasLength(3));
    expect(tester.layers.last, isA<PictureLayer>());
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689

  testWidgets('RasterWidget repaints when RasterWidgetDelegate notifies listeners', (WidgetTester tester) async {
    final TestDelegate delegate = TestDelegate();
    final SnapshotWidgetController controller = SnapshotWidgetController(enabled: true);
    await tester.pumpWidget(RepaintBoundary(
      child: Center(
        child: SnapshotWidget(
          delegate: delegate,
          controller: controller,
          child: Container(
            width: 100,
            height: 100,
            color: const Color(0xFFAABB11),
          ),
        ),
      ),
    ));

    expect(delegate.count, 1);
    delegate.notify();
    await tester.pump();

    expect(delegate.count, 2);

    // Remove widget and verify removal of listeners.
    await tester.pumpWidget(const SizedBox());

    delegate.notify();
    await tester.pump();

    expect(delegate.count, 2);
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689

  testWidgets('RasterWidget will recreate raster when controller calls clear', (WidgetTester tester) async {
    final TestDelegate delegate = TestDelegate();
    final SnapshotWidgetController controller = SnapshotWidgetController(enabled: true);
    await tester.pumpWidget(RepaintBoundary(
      child: Center(
        child: SnapshotWidget(
          delegate: delegate,
          controller: controller,
          child: Container(
            width: 100,
            height: 100,
            color: const Color(0xFFAABB11),
          ),
        ),
      ),
    ));

    expect(delegate.lastImage, isNotNull);
    final ui.Image lastImage = delegate.lastImage!;

    await tester.pump();

    // Raster is re-used
    expect(lastImage, equals(delegate.lastImage));

    controller.clear();

    await tester.pump();
    // Raster is re-created.
    expect(delegate.lastImage, isNotNull);
    expect(lastImage, isNot(delegate.lastImage));
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689

  testWidgets('RasterWidget can update the delegate', (WidgetTester tester) async {
    final TestDelegate delegateA = TestDelegate();
    final TestDelegate delegateB = TestDelegate()
      ..shouldRepaintValue = true;
    TestDelegate delegate = delegateA;

    final SnapshotWidgetController controller = SnapshotWidgetController(enabled: true);
    late void Function(void Function()) setStateFn;
    await tester.pumpWidget(StatefulBuilder(
      builder: (BuildContext context, void Function(void Function()) setState) {
        setStateFn = setState;
        return Center(
          child: SnapshotWidget(
            delegate: delegate,
            controller: controller,
            child: Container(
              width: 100,
              height: 100,
              color: const Color(0xFFAABB11),
            ),
          ),
        );
      })
    );

    expect(delegateA.count, 1);
    expect(delegateB.count, 0);
    setStateFn(() {
      delegate = delegateB;
    });
    await tester.pump();

    expect(delegateA.count, 1);
    expect(delegateB.count, 1);
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689

  testWidgets('RasterWidget can update the ValueNotifier', (WidgetTester tester) async {
    final TestDelegate delegate = TestDelegate();
    final SnapshotWidgetController controllerA = SnapshotWidgetController(enabled: true);
    final SnapshotWidgetController controllerB = SnapshotWidgetController();
    SnapshotWidgetController controller = controllerA;
    late void Function(void Function()) setStateFn;
    await tester.pumpWidget(StatefulBuilder(
      builder: (BuildContext context, void Function(void Function()) setState) {
        setStateFn = setState;
        return Center(
          child: SnapshotWidget(
            delegate: delegate,
            controller: controller,
            child: Container(
              width: 100,
              height: 100,
              color: const Color(0xFFAABB11),
            ),
          ),
        );
      })
    );

    expect(delegate.count, 1);
    expect(tester.layers.last, isA<OffsetLayer>());
    setStateFn(() {
      controller = controllerB;
    });
    await tester.pump();

    expect(delegate.count, 1);
    expect(tester.layers.last, isA<PictureLayer>());

    // changes to old notifier do not impact widget.
    controllerA.enabled = false;
    await tester.pump();

    expect(delegate.count, 1);
    expect(tester.layers.last, isA<PictureLayer>());

    await tester.pumpWidget(const SizedBox());

    // changes to notifier do not impact widget after disposal.
    controllerB.enabled = true;
    await tester.pump();
    expect(delegate.count, 1);
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689

  testWidgets('RenderRasterWidget correctly attaches and detaches delegate callbacks', (WidgetTester tester) async {
    final TestDelegate delegate = TestDelegate();
    final SnapshotWidgetController controller = SnapshotWidgetController(enabled: true);
    final RenderSnapshotWidget rasterWidget = RenderSnapshotWidget(
      delegate: delegate,
      controller: controller,
      devicePixelRatio: 1.0,
      mode: SnapshotMode.enabled,
    );

    expect(delegate.addedListenerCount, 0);
    expect(delegate.removedListenerCount, 0);

    final PipelineOwner owner = PipelineOwner();
    rasterWidget.attach(owner);

    expect(delegate.addedListenerCount, 1);
    expect(delegate.removedListenerCount, 0);

    rasterWidget.detach();

    expect(delegate.addedListenerCount, 1);
    expect(delegate.removedListenerCount, 1);

    final TestDelegate updatedDelegate = TestDelegate();
    rasterWidget.delegate = updatedDelegate;

    // No listeners added or removed while not attached.
    expect(updatedDelegate.addedListenerCount, 0);
    expect(updatedDelegate.removedListenerCount, 0);
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689

  testWidgets('RenderRasterWidget correctly attaches and detaches controller callbacks', (WidgetTester tester) async {
    final TestDelegate delegate = TestDelegate();
    final TestController controller = TestController();
    final RenderSnapshotWidget rasterWidget = RenderSnapshotWidget(
      delegate: delegate,
      controller: controller,
      devicePixelRatio: 1.0,
      mode: SnapshotMode.enabled,
    );

    expect(controller.addedListenerCount, 0);
    expect(controller.removedListenerCount, 0);

    final PipelineOwner owner = PipelineOwner();
    rasterWidget.attach(owner);

    expect(controller.addedListenerCount, 1);
    expect(controller.removedListenerCount, 0);

    rasterWidget.detach();

    expect(controller.addedListenerCount, 1);
    expect(controller.removedListenerCount, 1);

    final TestController updatedController = TestController();
    rasterWidget.controller = updatedController;

    // No listeners added or removed while not attached.
    expect(updatedController.addedListenerCount, 0);
    expect(updatedController.removedListenerCount, 0);
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689

  testWidgets('RenderRasterWidget does not error on rasterization of child with empty size', (WidgetTester tester) async {
    final TestDelegate delegate = TestDelegate();
    final SnapshotWidgetController controller = SnapshotWidgetController(enabled: true);

    await tester.pumpWidget(
      Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SnapshotWidget(
            delegate: delegate,
            controller: controller,
            child: const SizedBox(),
          ),
        ),
      ),
    );
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689


  testWidgets('RenderRasterWidget throws assertion if platform view is encountered', (WidgetTester tester) async {
    final TestDelegate delegate = TestDelegate();
    final SnapshotWidgetController controller = SnapshotWidgetController(enabled: true);

    await tester.pumpWidget(
      Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SnapshotWidget(
            delegate: delegate,
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
      .having((FlutterError error) => error.message, 'message', contains('RasterWidget used with a child that contains a PlatformView')));
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689

  testWidgets('RenderRasterWidget does not assert if RasterizeMode.forced', (WidgetTester tester) async {
    final TestDelegate delegate = TestDelegate();
    final SnapshotWidgetController controller = SnapshotWidgetController(enabled: true);

    await tester.pumpWidget(
      Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SnapshotWidget(
            delegate: delegate,
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

  testWidgets('RenderRasterWidget fallbacks to delegate if PlatformView is present', (WidgetTester tester) async {
    final TestDelegate delegate = TestDelegate();
    final SnapshotWidgetController controller = SnapshotWidgetController(enabled: true);
    final TestFallback fallback = TestFallback();
    await tester.pumpWidget(
      Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SnapshotWidget(
            delegate: delegate,
            controller: controller,
            fallback: fallback,
            child: const SizedBox(
              width: 100,
              height: 100,
              child: TestPlatformView(),
            ),
          ),
        ),
      ),
    );

    expect(fallback.calledFallback, 1);
    expect(delegate.count, 0);
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689

  testWidgets('RenderRasterWidget fallbacks to delegate if mode: RasterizeMode.fallback', (WidgetTester tester) async {
    final TestDelegate delegate = TestDelegate();
    final SnapshotWidgetController controller = SnapshotWidgetController(enabled: true);
    final TestFallback fallback = TestFallback();
    await tester.pumpWidget(
      Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SnapshotWidget(
            delegate: delegate,
            controller: controller,
            fallback: fallback,
            mode: SnapshotMode.fallback,
            child: const SizedBox(
              width: 100,
              height: 100,
            ),
          ),
        ),
      ),
    );

    expect(fallback.calledFallback, 1);
    expect(delegate.count, 0);
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689
}

class TestFallback extends RasterWidgetFallbackDelegate {
  int calledFallback = 0;

  @override
  void paintFallback(PaintingContext context, ui.Offset offset, ui.Size size, PaintingContextCallback painter) {
    calledFallback += 1;
  }

}

class TestController extends SnapshotWidgetController {
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

class TestDelegate extends RasterWidgetDelegate {
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
  void paint(PaintingContext context, Offset offset, Size size, ui.Image image, double pixelRatio) {
    count += 1;
    lastImage = image;
  }

  @override
  bool shouldRepaint(covariant RasterWidgetDelegate oldDelegate) => shouldRepaintValue;
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
