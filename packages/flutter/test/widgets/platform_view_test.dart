// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../services/fake_platform_views.dart';

void main() {

  testWidgets('Create Android view', (WidgetTester tester) async {
    final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
    final FakePlatformViewsController viewsController = new FakePlatformViewsController(TargetPlatform.android);
    viewsController.registerViewType('webview');

    await tester.pumpWidget(
        const Center(
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: AndroidView(viewType: 'webview'),
            )
        )
    );

    expect(
      viewsController.views,
      unorderedEquals(<FakePlatformView>[
        new FakePlatformView(currentViewId + 1, 'webview', const Size(200.0, 100.0))
      ])
    );
  });

  testWidgets('Resize Android view', (WidgetTester tester) async {
    final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
    final FakePlatformViewsController viewsController = new FakePlatformViewsController(TargetPlatform.android);
    viewsController.registerViewType('webview');
    await tester.pumpWidget(
        const Center(
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: AndroidView(viewType: 'webview'),
            )
        )
    );

    await tester.pumpWidget(
        const Center(
            child: SizedBox(
              width: 400.0,
              height: 200.0,
              child: AndroidView(viewType: 'webview'),
            )
        )
    );

    expect(
        viewsController.views,
        unorderedEquals(<FakePlatformView>[
          new FakePlatformView(currentViewId + 1, 'webview', const Size(400.0, 200.0))
        ])
    );
  });

  testWidgets('Change Android view type', (WidgetTester tester) async {
    final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
    final FakePlatformViewsController viewsController = new FakePlatformViewsController(TargetPlatform.android);
    viewsController.registerViewType('webview');
    viewsController.registerViewType('maps');
    await tester.pumpWidget(
        const Center(
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: AndroidView(viewType: 'webview'),
            )
        )
    );

    await tester.pumpWidget(
        const Center(
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: AndroidView(viewType: 'maps'),
            )
        )
    );

    expect(
        viewsController.views,
        unorderedEquals(<FakePlatformView>[
          new FakePlatformView(currentViewId + 2, 'maps', const Size(200.0, 100.0))
        ])
    );
  });

  testWidgets('Dispose Android view', (WidgetTester tester) async {
    final FakePlatformViewsController viewsController = new FakePlatformViewsController(TargetPlatform.android);
    viewsController.registerViewType('webview');
    await tester.pumpWidget(
        const Center(
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: AndroidView(viewType: 'webview'),
            )
        )
    );

    await tester.pumpWidget(
        const Center(
            child: SizedBox(
              width: 200.0,
              height: 100.0,
            )
        )
    );

    expect(
      viewsController.views,
      isEmpty,
    );
  });

  testWidgets('Android view survives widget tree change', (WidgetTester tester) async {
    final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
    final FakePlatformViewsController viewsController = new FakePlatformViewsController(TargetPlatform.android);
    viewsController.registerViewType('webview');
    final GlobalKey key = new GlobalKey();
    await tester.pumpWidget(
        new Center(
            child: new SizedBox(
              width: 200.0,
              height: 100.0,
              child: new AndroidView(viewType: 'webview', key: key),
            )
        )
    );

    await tester.pumpWidget(
      new Center(
        child: new Container(
          child: new SizedBox(
            width: 200.0,
            height: 100.0,
            child: new AndroidView(viewType: 'webview', key: key),
          ),
        ),
      ),
    );

    expect(
        viewsController.views,
        unorderedEquals(<FakePlatformView>[
          new FakePlatformView(currentViewId + 1, 'webview', const Size(200.0, 100.0))
        ])
    );
  });

  testWidgets('Android view gets touch events', (WidgetTester tester) async {
    final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
    final FakePlatformViewsController viewsController = new FakePlatformViewsController(TargetPlatform.android);
    viewsController.registerViewType('webview');
    await tester.pumpWidget(
        const Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: AndroidView(viewType: 'webview'),
            )
        )
    );

    final TestGesture gesture = await tester.startGesture(const Offset(50.0, 50.0));
    await gesture.up();

    expect(
      viewsController.motionEvents[currentViewId + 1],
      orderedEquals(<FakeMotionEvent> [
        const FakeMotionEvent(AndroidViewController.kActionDown, <int> [0], <Offset> [Offset(50.0, 50.0)]),
        const FakeMotionEvent(AndroidViewController.kActionUp, <int> [0], <Offset> [Offset(50.0, 50.0)]),
      ])
    );
  });

  testWidgets('Android view transparent hit test behavior', (WidgetTester tester) async {
    final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
    final FakePlatformViewsController viewsController = new FakePlatformViewsController(TargetPlatform.android);
    viewsController.registerViewType('webview');

    int numPointerDownsOnParent = 0;
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Stack(
          children: <Widget> [
            new Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (PointerDownEvent e) { numPointerDownsOnParent++; },
            ),
            const Positioned(
                child: SizedBox(
                  width: 200.0,
                  height: 100.0,
                  child: AndroidView(
                    viewType: 'webview',
                    hitTestBehavior: PlatformViewHitTestBehavior.transparent,
                  ),
                )
            ),
          ],
        ),
      ),
    );

    await tester.startGesture(const Offset(50.0, 50.0));

    expect(
        viewsController.motionEvents[currentViewId + 1],
        isNull,
    );
    expect(
      numPointerDownsOnParent,
      1
    );
  });

  testWidgets('Android view translucent hit test behavior', (WidgetTester tester) async {
    final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
    final FakePlatformViewsController viewsController = new FakePlatformViewsController(TargetPlatform.android);
    viewsController.registerViewType('webview');

    int numPointerDownsOnParent = 0;
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Stack(
          children: <Widget> [
            new Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (PointerDownEvent e) { numPointerDownsOnParent++; },
            ),
            const Positioned(
                child: SizedBox(
                  width: 200.0,
                  height: 100.0,
                  child: AndroidView(
                    viewType: 'webview',
                    hitTestBehavior: PlatformViewHitTestBehavior.translucent,
                  ),
                )
            ),
          ],
        ),
      ),
    );

    await tester.startGesture(const Offset(50.0, 50.0));

    expect(
      viewsController.motionEvents[currentViewId + 1],
        orderedEquals(<FakeMotionEvent> [
          const FakeMotionEvent(AndroidViewController.kActionDown, <int> [0], <Offset> [Offset(50.0, 50.0)]),
        ])
    );
    expect(
        numPointerDownsOnParent,
        1
    );
  });

  testWidgets('Android view opaque hit test behavior', (WidgetTester tester) async {
    final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
    final FakePlatformViewsController viewsController = new FakePlatformViewsController(TargetPlatform.android);
    viewsController.registerViewType('webview');

    int numPointerDownsOnParent = 0;
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Stack(
          children: <Widget> [
            new Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (PointerDownEvent e) { numPointerDownsOnParent++; },
            ),
            const Positioned(
                child: SizedBox(
                  width: 200.0,
                  height: 100.0,
                  child: AndroidView(
                    viewType: 'webview',
                    hitTestBehavior: PlatformViewHitTestBehavior.opaque,
                  ),
                )
            ),
          ],
        ),
      ),
    );

    await tester.startGesture(const Offset(50.0, 50.0));

    expect(
        viewsController.motionEvents[currentViewId + 1],
        orderedEquals(<FakeMotionEvent> [
          const FakeMotionEvent(AndroidViewController.kActionDown, <int> [0], <Offset> [Offset(50.0, 50.0)]),
        ])
    );
    expect(
        numPointerDownsOnParent,
        0
    );
  });

  testWidgets('Android view touch events are in virtual display\'s coordinate system', (WidgetTester tester) async {
    final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
    final FakePlatformViewsController viewsController = new FakePlatformViewsController(TargetPlatform.android);
    viewsController.registerViewType('webview');
    await tester.pumpWidget(
        new Align(
          alignment: Alignment.topLeft,
          child: new Container(
            margin: const EdgeInsets.all(10.0),
            child: const SizedBox(
              width: 200.0,
              height: 100.0,
              child: AndroidView(viewType: 'webview'),
            ),
          ),
        )
    );

    final TestGesture gesture = await tester.startGesture(const Offset(50.0, 50.0));
    await gesture.up();

    expect(
        viewsController.motionEvents[currentViewId + 1],
        orderedEquals(<FakeMotionEvent> [
          const FakeMotionEvent(AndroidViewController.kActionDown, <int> [0], <Offset> [Offset(40.0, 40.0)]),
          const FakeMotionEvent(AndroidViewController.kActionUp, <int> [0], <Offset> [Offset(40.0, 40.0)]),
        ])
    );
  });
}
