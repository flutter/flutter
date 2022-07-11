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
    final RasterWidgetController controller = RasterWidgetController(rasterize: true);
    await tester.pumpWidget(RepaintBoundary(
      child: Center(
        child: RasterWidget(
          controller: controller,
          child: Container(
            width: 100,
            height: 100,
            color: const Color(0xFFAABB11),
          ),
        ),
      ),
    ));

    await expectLater(find.byType(RepaintBoundary), matchesGoldenFile('raster_widget.yellow.png'));
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689

  testWidgets('RasterWidget is a repaint boundary when rasterizing', (WidgetTester tester) async {
    final RasterWidgetController controller = RasterWidgetController(rasterize: true);
    await tester.pumpWidget(RepaintBoundary(
      child: Center(
        child: RasterWidget(
          controller: controller,
          child: Container(
            width: 100,
            height: 100,
            color: const Color(0xFFAABB11),
          ),
        ),
      ),
    ));

    expect(tester.layers, hasLength(4));
    expect(tester.layers.last, isA<PictureLayer>());
    expect(tester.layers[2], isA<OffsetLayer>());

    controller.rasterize = false;
    await tester.pump();

    expect(tester.layers, hasLength(3));
    expect(tester.layers.last, isA<PictureLayer>());
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689

  testWidgets('RasterWidget repaints when RasterWidgetDelegate notifies listeners', (WidgetTester tester) async {
    final TestDelegate delegate = TestDelegate();
    final RasterWidgetController controller = RasterWidgetController(rasterize: true);
    await tester.pumpWidget(RepaintBoundary(
      child: Center(
        child: RasterWidget(
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
    final RasterWidgetController controller = RasterWidgetController(rasterize: true);
    await tester.pumpWidget(RepaintBoundary(
      child: Center(
        child: RasterWidget(
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

    final RasterWidgetController controller = RasterWidgetController(rasterize: true);
    late void Function(void Function()) setStateFn;
    await tester.pumpWidget(StatefulBuilder(
      builder: (BuildContext context, void Function(void Function()) setState) {
        setStateFn = setState;
        return Center(
          child: RasterWidget(
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
    final RasterWidgetController controllerA = RasterWidgetController(rasterize: true);
    final RasterWidgetController controllerB = RasterWidgetController();
    RasterWidgetController controller = controllerA;
    late void Function(void Function()) setStateFn;
    await tester.pumpWidget(StatefulBuilder(
      builder: (BuildContext context, void Function(void Function()) setState) {
        setStateFn = setState;
        return Center(
          child: RasterWidget(
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
    controllerA.rasterize = false;
    await tester.pump();

    expect(delegate.count, 1);
    expect(tester.layers.last, isA<PictureLayer>());

    await tester.pumpWidget(const SizedBox());

    // changes to notifier do not impact widget after disposal.
    controllerB.rasterize = true;
    await tester.pump();
    expect(delegate.count, 1);
  }, skip: kIsWeb); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/106689

  testWidgets('RenderRasterWidget correctly attaches and detaches delegate callbacks', (WidgetTester tester) async {
    final TestDelegate delegate = TestDelegate();
    final RasterWidgetController controller = RasterWidgetController(rasterize: true);
    final RenderRasterWidget rasterWidget = RenderRasterWidget(
      delegate: delegate,
      controller: controller,
      devicePixelRatio: 1.0,
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
    final RenderRasterWidget rasterWidget = RenderRasterWidget(
      delegate: delegate,
      controller: controller,
      devicePixelRatio: 1.0,
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
}

class TestController extends RasterWidgetController {
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
  void paint(PaintingContext context, Rect area, ui.Image image, double pixelRatio) {
    count += 1;
    lastImage = image;
  }

  @override
  bool shouldRepaint(covariant RasterWidgetDelegate oldDelegate) => shouldRepaintValue;
}
