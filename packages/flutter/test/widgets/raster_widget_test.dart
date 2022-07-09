// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RasterWidget can rasterize child', (WidgetTester tester) async {
    final ValueNotifier<bool> notifier = ValueNotifier<bool>(true);
    await tester.pumpWidget(RepaintBoundary(
      child: Center(
        child: RasterWidget(
          rasterize: notifier,
          child: Container(
            width: 100,
            height: 100,
            color: const Color(0xFFAABB11),
          ),
        ),
      ),
    ));

    await expectLater(find.byType(RepaintBoundary), matchesGoldenFile('raster_widget.yellow.png'));
  });

  testWidgets('RasterWidget is a repaint boundary when rasterizing', (WidgetTester tester) async {
    final ValueNotifier<bool> notifier = ValueNotifier<bool>(true);
    await tester.pumpWidget(RepaintBoundary(
      child: Center(
        child: RasterWidget(
          rasterize: notifier,
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

    notifier.value = false;
    await tester.pump();

    expect(tester.layers, hasLength(3));
    expect(tester.layers.last, isA<PictureLayer>());
  });

  testWidgets('RasterWidget repaints when RasterWidgetDelegate notifies listeners', (WidgetTester tester) async {
    final TestDelegate delegate = TestDelegate();
    final ValueNotifier<bool> notifier = ValueNotifier<bool>(true);
    await tester.pumpWidget(RepaintBoundary(
      child: Center(
        child: RasterWidget(
          delegate: delegate,
          rasterize: notifier,
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
  });

  testWidgets('RasterWidget can update the delegate', (WidgetTester tester) async {
    final TestDelegate delegateA = TestDelegate();
    final TestDelegate delegateB = TestDelegate()
      ..shouldRepaintValue = true;
    TestDelegate delegate = delegateA;

    final ValueNotifier<bool> notifier = ValueNotifier<bool>(true);
    late void Function(void Function()) setStateFn;
    await tester.pumpWidget(StatefulBuilder(
      builder: (BuildContext context, void Function(void Function()) setState) {
        setStateFn = setState;
        return Center(
          child: RasterWidget(
            delegate: delegate,
            rasterize: notifier,
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
  });

  testWidgets('RasterWidget can update the ValueNotifier', (WidgetTester tester) async {
    final TestDelegate delegate = TestDelegate();
    final ValueNotifier<bool> notifierA = ValueNotifier<bool>(true);
    final ValueNotifier<bool> notifierB = ValueNotifier<bool>(false);
    ValueNotifier<bool> notifier = notifierA;
    late void Function(void Function()) setStateFn;
    await tester.pumpWidget(StatefulBuilder(
      builder: (BuildContext context, void Function(void Function()) setState) {
        setStateFn = setState;
        return Center(
          child: RasterWidget(
            delegate: delegate,
            rasterize: notifier,
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
      notifier = notifierB;
    });
    await tester.pump();

    expect(delegate.count, 1);
    expect(tester.layers.last, isA<PictureLayer>());

    // changes to old notifier do not impact widget.
    notifierA.value = false;
    await tester.pump();

    expect(delegate.count, 1);
    expect(tester.layers.last, isA<PictureLayer>());

    await tester.pumpWidget(const SizedBox());

    // changes to notifier do not impact widget after disposal.
    notifierB.value = true;
    await tester.pump();
    expect(delegate.count, 1);
  });
}

class TestDelegate extends RasterWidgetDelegate {
  int count = 0;
  bool shouldRepaintValue = false;

  void notify() {
    notifyListeners();
  }

  @override
  void paint(PaintingContext context, Rect area, ui.Image image, double pixelRatio) {
    count += 1;
  }

  @override
  bool shouldRepaint(covariant RasterWidgetDelegate oldDelegate) => shouldRepaintValue;
}
