// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../services/fake_platform_views.dart';

void main() {

  group('AndroidView', () {
    testWidgets('Create Android view', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');

      await tester.pumpWidget(
        const Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: AndroidView(viewType: 'webview', layoutDirection: TextDirection.ltr),
          ),
        ),
      );

      expect(
        viewsController.views,
        unorderedEquals(<FakeAndroidPlatformView>[
          FakeAndroidPlatformView(currentViewId + 1, 'webview', const Size(200.0, 100.0),
              AndroidViewController.kAndroidLayoutDirectionLtr)
        ]),
      );
    });

    testWidgets('Create Android view with params', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');

      await tester.pumpWidget(
        const Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: AndroidView(
              viewType: 'webview',
              layoutDirection: TextDirection.ltr,
              creationParams: 'creation parameters',
              creationParamsCodec: StringCodec(),
            ),
          ),
        ),
      );

      final FakeAndroidPlatformView fakeView = viewsController.views.first;
      final Uint8List rawCreationParams = fakeView.creationParams;
      final ByteData byteData = ByteData.view(
          rawCreationParams.buffer,
          rawCreationParams.offsetInBytes,
          rawCreationParams.lengthInBytes
      );
      final dynamic actualParams = const StringCodec().decodeMessage(byteData);

      expect(actualParams, 'creation parameters');
      expect(
        viewsController.views,
        unorderedEquals(<FakeAndroidPlatformView>[
          FakeAndroidPlatformView(currentViewId + 1, 'webview', const Size(200.0, 100.0),
              AndroidViewController.kAndroidLayoutDirectionLtr, fakeView.creationParams)
        ]),
      );
    });

    testWidgets('Zero sized Android view is not created', (WidgetTester tester) async {
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');

      await tester.pumpWidget(
        const Center(
          child: SizedBox(
            width: 0.0,
            height: 0.0,
            child: AndroidView(viewType: 'webview', layoutDirection: TextDirection.ltr),
          ),
        ),
      );

      expect(
        viewsController.views,
        isEmpty,
      );
    });

    testWidgets('Resize Android view', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');
      await tester.pumpWidget(
        const Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: AndroidView(viewType: 'webview', layoutDirection: TextDirection.ltr),
          ),
        ),
      );

      viewsController.resizeCompleter = Completer<void>();

      await tester.pumpWidget(
        const Center(
          child: SizedBox(
            width: 100.0,
            height: 50.0,
            child: AndroidView(viewType: 'webview', layoutDirection: TextDirection.ltr),
          ),
        ),
      );

      final Layer textureParentLayer = tester.layers[tester.layers.length - 2];
      expect(textureParentLayer, isInstanceOf<ClipRectLayer>());
      final ClipRectLayer clipRect = textureParentLayer;
      expect(clipRect.clipRect, Rect.fromLTWH(0.0, 0.0, 100.0, 50.0));
      expect(
        viewsController.views,
        unorderedEquals(<FakeAndroidPlatformView>[
          FakeAndroidPlatformView(currentViewId + 1, 'webview', const Size(200.0, 100.0),
              AndroidViewController.kAndroidLayoutDirectionLtr)
        ]),
      );

      viewsController.resizeCompleter.complete();
      await tester.pump();

      expect(
        viewsController.views,
        unorderedEquals(<FakeAndroidPlatformView>[
          FakeAndroidPlatformView(currentViewId + 1, 'webview', const Size(100.0, 50.0),
              AndroidViewController.kAndroidLayoutDirectionLtr)
        ]),
      );
    });

    testWidgets('Change Android view type', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');
      viewsController.registerViewType('maps');
      await tester.pumpWidget(
        const Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: AndroidView(viewType: 'webview', layoutDirection: TextDirection.ltr),
          ),
        ),
      );

      await tester.pumpWidget(
        const Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: AndroidView(viewType: 'maps', layoutDirection: TextDirection.ltr),
          ),
        ),
      );

      expect(
        viewsController.views,
        unorderedEquals(<FakeAndroidPlatformView>[
          FakeAndroidPlatformView(currentViewId + 2, 'maps', const Size(200.0, 100.0),
              AndroidViewController.kAndroidLayoutDirectionLtr)
        ]),
      );
    });

    testWidgets('Dispose Android view', (WidgetTester tester) async {
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');
      await tester.pumpWidget(
        const Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: AndroidView(viewType: 'webview', layoutDirection: TextDirection.ltr),
          ),
        ),
      );

      await tester.pumpWidget(
        const Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
          ),
        ),
      );

      expect(
        viewsController.views,
        isEmpty,
      );
    });

    testWidgets('Android view survives widget tree change', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');
      final GlobalKey key = GlobalKey();
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: AndroidView(viewType: 'webview', layoutDirection: TextDirection.ltr, key: key),
          ),
        ),
      );

      await tester.pumpWidget(
        Center(
          child: Container(
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: AndroidView(viewType: 'webview', layoutDirection: TextDirection.ltr, key: key),
            ),
          ),
        ),
      );

      expect(
        viewsController.views,
        unorderedEquals(<FakeAndroidPlatformView>[
          FakeAndroidPlatformView(currentViewId + 1, 'webview', const Size(200.0, 100.0),
              AndroidViewController.kAndroidLayoutDirectionLtr)
        ]),
      );
    });

    testWidgets('Android view gets touch events', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');
      await tester.pumpWidget(
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: AndroidView(viewType: 'webview', layoutDirection: TextDirection.ltr,),
          ),
        ),
      );

      final TestGesture gesture = await tester.startGesture(const Offset(50.0, 50.0));
      await gesture.up();

      expect(
        viewsController.motionEvents[currentViewId + 1],
        orderedEquals(<FakeAndroidMotionEvent>[
          const FakeAndroidMotionEvent(
              AndroidViewController.kActionDown, <int>[0], <Offset>[Offset(50.0, 50.0)]),
          const FakeAndroidMotionEvent(
              AndroidViewController.kActionUp, <int>[0], <Offset>[Offset(50.0, 50.0)]),
        ]),
      );
    });

    testWidgets('Android view transparent hit test behavior', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');

      int numPointerDownsOnParent = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: <Widget>[
              Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (PointerDownEvent e) {
                  numPointerDownsOnParent++;
                },
              ),
              const Positioned(
                child: SizedBox(
                  width: 200.0,
                  height: 100.0,
                  child: AndroidView(
                    viewType: 'webview',
                    hitTestBehavior: PlatformViewHitTestBehavior.transparent,
                    layoutDirection: TextDirection.ltr,
                  ),
                ),
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
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');

      int numPointerDownsOnParent = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: <Widget>[
              Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (PointerDownEvent e) {
                  numPointerDownsOnParent++;
                },
              ),
              const Positioned(
                child: SizedBox(
                  width: 200.0,
                  height: 100.0,
                  child: AndroidView(
                    viewType: 'webview',
                    hitTestBehavior: PlatformViewHitTestBehavior.translucent,
                    layoutDirection: TextDirection.ltr,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      await tester.startGesture(const Offset(50.0, 50.0));

      expect(
        viewsController.motionEvents[currentViewId + 1],
        orderedEquals(<FakeAndroidMotionEvent>[
          const FakeAndroidMotionEvent(
              AndroidViewController.kActionDown, <int>[0], <Offset>[Offset(50.0, 50.0)]),
        ]),
      );
      expect(
          numPointerDownsOnParent,
          1
      );
    });

    testWidgets('Android view opaque hit test behavior', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');

      int numPointerDownsOnParent = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: <Widget>[
              Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (PointerDownEvent e) {
                  numPointerDownsOnParent++;
                },
              ),
              const Positioned(
                child: SizedBox(
                  width: 200.0,
                  height: 100.0,
                  child: AndroidView(
                    viewType: 'webview',
                    hitTestBehavior: PlatformViewHitTestBehavior.opaque,
                    layoutDirection: TextDirection.ltr,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      await tester.startGesture(const Offset(50.0, 50.0));

      expect(
        viewsController.motionEvents[currentViewId + 1],
        orderedEquals(<FakeAndroidMotionEvent>[
          const FakeAndroidMotionEvent(
              AndroidViewController.kActionDown, <int>[0], <Offset>[Offset(50.0, 50.0)]),
        ]),
      );
      expect(
          numPointerDownsOnParent,
          0
      );
    });

    testWidgets('Android view touch events are in virtual display\'s coordinate system', (
        WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');
      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.all(10.0),
            child: const SizedBox(
              width: 200.0,
              height: 100.0,
              child: AndroidView(viewType: 'webview', layoutDirection: TextDirection.ltr),
            ),
          ),
        ),
      );

      final TestGesture gesture = await tester.startGesture(const Offset(50.0, 50.0));
      await gesture.up();

      expect(
        viewsController.motionEvents[currentViewId + 1],
        orderedEquals(<FakeAndroidMotionEvent>[
          const FakeAndroidMotionEvent(
              AndroidViewController.kActionDown, <int>[0], <Offset>[Offset(40.0, 40.0)]),
          const FakeAndroidMotionEvent(
              AndroidViewController.kActionUp, <int>[0], <Offset>[Offset(40.0, 40.0)]),
        ]),
      );
    });

    testWidgets('Android view directionality', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('maps');
      await tester.pumpWidget(
        const Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: AndroidView(viewType: 'maps', layoutDirection: TextDirection.rtl),
          ),
        ),
      );

      expect(
        viewsController.views,
        unorderedEquals(<FakeAndroidPlatformView>[
          FakeAndroidPlatformView(currentViewId + 1, 'maps', const Size(200.0, 100.0),
              AndroidViewController.kAndroidLayoutDirectionRtl)
        ]),
      );

      await tester.pumpWidget(
        const Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: AndroidView(viewType: 'maps', layoutDirection: TextDirection.ltr),
          ),
        ),
      );

      expect(
        viewsController.views,
        unorderedEquals(<FakeAndroidPlatformView>[
          FakeAndroidPlatformView(currentViewId + 1, 'maps', const Size(200.0, 100.0),
              AndroidViewController.kAndroidLayoutDirectionLtr)
        ]),
      );
    });

    testWidgets('Android view ambient directionality', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('maps');
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: AndroidView(viewType: 'maps'),
            ),
          ),
        ),
      );

      expect(
        viewsController.views,
        unorderedEquals(<FakeAndroidPlatformView>[
          FakeAndroidPlatformView(currentViewId + 1, 'maps', const Size(200.0, 100.0),
              AndroidViewController.kAndroidLayoutDirectionRtl)
        ]),
      );

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: AndroidView(viewType: 'maps'),
            ),
          ),
        ),
      );

      expect(
        viewsController.views,
        unorderedEquals(<FakeAndroidPlatformView>[
          FakeAndroidPlatformView(currentViewId + 1, 'maps', const Size(200.0, 100.0),
              AndroidViewController.kAndroidLayoutDirectionLtr)
        ]),
      );
    });

    testWidgets('Android view can lose gesture arenas', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');
      bool verticalDragAcceptedByParent = false;
      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.all(10.0),
            child: GestureDetector(
              onVerticalDragStart: (DragStartDetails d) {
                verticalDragAcceptedByParent = true;
              },
              child: const SizedBox(
                width: 200.0,
                height: 100.0,
                child: AndroidView(viewType: 'webview', layoutDirection: TextDirection.ltr),
              ),
            ),
          ),
        ),
      );

      final TestGesture gesture = await tester.startGesture(const Offset(50.0, 50.0));
      await gesture.moveBy(const Offset(0.0, 100.0));
      await gesture.up();

      expect(verticalDragAcceptedByParent, true);
      expect(
        viewsController.motionEvents[currentViewId + 1],
        isNull,
      );
    });

    testWidgets('Android view gesture recognizers', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');
      bool verticalDragAcceptedByParent = false;
      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: GestureDetector(
            onVerticalDragStart: (DragStartDetails d) {
              verticalDragAcceptedByParent = true;
            },
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: AndroidView(
                viewType: 'webview',
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                  Factory<VerticalDragGestureRecognizer>(
                        () => VerticalDragGestureRecognizer(),
                  ),
                ].toSet(),
                layoutDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      );

      final TestGesture gesture = await tester.startGesture(const Offset(50.0, 50.0));
      await gesture.moveBy(const Offset(0.0, 100.0));
      await gesture.up();

      expect(verticalDragAcceptedByParent, false);
      expect(
        viewsController.motionEvents[currentViewId + 1],
        orderedEquals(<FakeAndroidMotionEvent>[
          const FakeAndroidMotionEvent(
              AndroidViewController.kActionDown, <int>[0], <Offset>[Offset(50.0, 50.0)]),
          const FakeAndroidMotionEvent(
              AndroidViewController.kActionMove, <int>[0], <Offset>[Offset(50.0, 150.0)]),
          const FakeAndroidMotionEvent(
              AndroidViewController.kActionUp, <int>[0], <Offset>[Offset(50.0, 150.0)]),
        ]),
      );
    });

    testWidgets(
        'Android view can claim gesture after all pointers are up', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');
      bool verticalDragAcceptedByParent = false;
      // The long press recognizer rejects the gesture after the AndroidView gets the pointer up event.
      // This test makes sure that the Android view can win the gesture after it got the pointer up event.
      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: GestureDetector(
            onVerticalDragStart: (DragStartDetails d) {
              verticalDragAcceptedByParent = true;
            },
            onLongPress: () {},
            child: const SizedBox(
              width: 200.0,
              height: 100.0,
              child: AndroidView(
                viewType: 'webview',
                layoutDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      );

      final TestGesture gesture = await tester.startGesture(const Offset(50.0, 50.0));
      await gesture.up();

      expect(verticalDragAcceptedByParent, false);
      expect(
        viewsController.motionEvents[currentViewId + 1],
        orderedEquals(<FakeAndroidMotionEvent>[
          const FakeAndroidMotionEvent(
              AndroidViewController.kActionDown, <int>[0], <Offset>[Offset(50.0, 50.0)]),
          const FakeAndroidMotionEvent(
              AndroidViewController.kActionUp, <int>[0], <Offset>[Offset(50.0, 50.0)]),
        ]),
      );
    });

    testWidgets('Android view rebuilt during gesture', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');
      await tester.pumpWidget(
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: AndroidView(
              viewType: 'webview',
              layoutDirection: TextDirection.ltr,
            ),
          ),
        ),
      );

      final TestGesture gesture = await tester.startGesture(const Offset(50.0, 50.0));
      await gesture.moveBy(const Offset(0.0, 100.0));

      await tester.pumpWidget(
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: AndroidView(
              viewType: 'webview',
              layoutDirection: TextDirection.ltr,
            ),
          ),
        ),
      );

      await gesture.up();

      expect(
        viewsController.motionEvents[currentViewId + 1],
        orderedEquals(<FakeAndroidMotionEvent>[
          const FakeAndroidMotionEvent(
              AndroidViewController.kActionDown, <int>[0], <Offset>[Offset(50.0, 50.0)]),
          const FakeAndroidMotionEvent(
              AndroidViewController.kActionMove, <int>[0], <Offset>[Offset(50.0, 150.0)]),
          const FakeAndroidMotionEvent(
              AndroidViewController.kActionUp, <int>[0], <Offset>[Offset(50.0, 150.0)]),
        ]),
      );
    });

    testWidgets('Android view with eager gesture recognizer', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');
      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: GestureDetector(
            onVerticalDragStart: (DragStartDetails d) {},
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: AndroidView(
                viewType: 'webview',
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                  Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                  ),
                ].toSet(),
                layoutDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      );

      await tester.startGesture(const Offset(50.0, 50.0));

      // Normally (without the eager gesture recognizer) after just the pointer down event
      // no gesture arena member will claim the arena (so no motion events will be dispatched to
      // the Android view). Here we assert that with the eager recognizer in the gesture team the
      // pointer down event is immediately dispatched.
      expect(
        viewsController.motionEvents[currentViewId + 1],
        orderedEquals(<FakeAndroidMotionEvent>[
          const FakeAndroidMotionEvent(
              AndroidViewController.kActionDown, <int>[0], <Offset>[Offset(50.0, 50.0)]),
        ]),
      );
    });

    testWidgets('RenderAndroidView reconstructed with same gestureRecognizers', (
        WidgetTester tester) async {
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');

      final AndroidView androidView = AndroidView(
        viewType: 'webview',
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
          Factory<EagerGestureRecognizer>(
                () => EagerGestureRecognizer(),
          ),
        ].toSet(),
        layoutDirection: TextDirection.ltr,
      );

      await tester.pumpWidget(androidView);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(androidView);
    });

    testWidgets('AndroidView rebuilt with same gestureRecognizers', (WidgetTester tester) async {
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');

      int factoryInvocationCount = 0;
      final ValueGetter<EagerGestureRecognizer> constructRecognizer = () {
        factoryInvocationCount += 1;
        return EagerGestureRecognizer();
      };

      await tester.pumpWidget(
        AndroidView(
          viewType: 'webview',
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
            Factory<EagerGestureRecognizer>(constructRecognizer),
          ].toSet(),
          layoutDirection: TextDirection.ltr,
        ),
      );

      await tester.pumpWidget(
        AndroidView(
          viewType: 'webview',
          hitTestBehavior: PlatformViewHitTestBehavior.translucent,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
            Factory<EagerGestureRecognizer>(constructRecognizer),
          ].toSet(),
          layoutDirection: TextDirection.ltr,
        ),
      );

      expect(factoryInvocationCount, 1);
    });
  });

  group('UiKitView', () {
    testWidgets('Create UIView', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');

      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: UiKitView(viewType: 'webview', layoutDirection: TextDirection.ltr),
          ),
        ),
      );

      expect(
        viewsController.views,
        unorderedEquals(<FakeUiKitView>[
          FakeUiKitView(currentViewId + 1, 'webview')
        ]),
      );
    });

    testWidgets('Change UIView view type', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');
      viewsController.registerViewType('maps');
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: UiKitView(viewType: 'webview', layoutDirection: TextDirection.ltr),
          ),
        ),
      );

      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: UiKitView(viewType: 'maps', layoutDirection: TextDirection.ltr),
          ),
        ),
      );

      expect(
        viewsController.views,
        unorderedEquals(<FakeUiKitView>[
          FakeUiKitView(currentViewId + 2, 'maps')
        ]),
      );
    });

    testWidgets('Dispose UIView ', (WidgetTester tester) async {
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: UiKitView(viewType: 'webview', layoutDirection: TextDirection.ltr),
          ),
        ),
      );

      await tester.pumpWidget(
        const Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
          ),
        ),
      );

      expect(
        viewsController.views,
        isEmpty,
      );
    });

    testWidgets('Dispose UIView before creation completed ', (WidgetTester tester) async {
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');
      viewsController.creationDelay = Completer<void>();
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: UiKitView(viewType: 'webview', layoutDirection: TextDirection.ltr),
          ),
        ),
      );

      await tester.pumpWidget(
        const Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
          ),
        ),
      );

      viewsController.creationDelay.complete();

      expect(
        viewsController.views,
        isEmpty,
      );
    });

    testWidgets('UIView survives widget tree change', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');
      final GlobalKey key = GlobalKey();
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: UiKitView(viewType: 'webview', layoutDirection: TextDirection.ltr, key: key),
          ),
        ),
      );

      await tester.pumpWidget(
        Center(
          child: Container(
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: UiKitView(viewType: 'webview', layoutDirection: TextDirection.ltr, key: key),
            ),
          ),
        ),
      );

      expect(
        viewsController.views,
        unorderedEquals(<FakeUiKitView>[
          FakeUiKitView(currentViewId + 1, 'webview')
        ]),
      );
    });

    testWidgets('Create UIView with params', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');

      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: UiKitView(
              viewType: 'webview',
              layoutDirection: TextDirection.ltr,
              creationParams: 'creation parameters',
              creationParamsCodec: const StringCodec(),
            ),
          ),
        ),
      );

      final FakeUiKitView fakeView = viewsController.views.first;
      final Uint8List rawCreationParams = fakeView.creationParams;
      final ByteData byteData = ByteData.view(
          rawCreationParams.buffer,
          rawCreationParams.offsetInBytes,
          rawCreationParams.lengthInBytes
      );
      final dynamic actualParams = const StringCodec().decodeMessage(byteData);

      expect(actualParams, 'creation parameters');
      expect(
        viewsController.views,
        unorderedEquals(<FakeUiKitView>[
          FakeUiKitView(currentViewId + 1, 'webview', fakeView.creationParams)
        ]),
      );
    });

    testWidgets('UiKitView accepts gestures', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');

      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: UiKitView(viewType: 'webview', layoutDirection: TextDirection.ltr,),
          ),
        ),
      );

      // First frame is before the platform view was created so the render object
      // is not yet in the tree.
      await tester.pump();

      expect(viewsController.gesturesAccepted[currentViewId + 1], 0);

      final TestGesture gesture = await tester.startGesture(const Offset(50.0, 50.0));
      await gesture.up();

      expect(viewsController.gesturesAccepted[currentViewId + 1], 1);
    });

    testWidgets('UiKitView transparent hit test behavior', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');

      int numPointerDownsOnParent = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: <Widget>[
              Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (PointerDownEvent e) {
                  numPointerDownsOnParent++;
                },
              ),
              Positioned(
                child: SizedBox(
                  width: 200.0,
                  height: 100.0,
                  child: UiKitView(
                    viewType: 'webview',
                    hitTestBehavior: PlatformViewHitTestBehavior.transparent,
                    layoutDirection: TextDirection.ltr,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // First frame is before the platform view was created so the render object
      // is not yet in the tree.
      await tester.pump();

      final TestGesture gesture = await tester.startGesture(const Offset(50.0, 50.0));
      await gesture.up();

      expect(viewsController.gesturesAccepted[currentViewId + 1], 0);

      expect(numPointerDownsOnParent, 1);
    });

    testWidgets('UiKitView translucent hit test behavior', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');

      int numPointerDownsOnParent = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: <Widget>[
              Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (PointerDownEvent e) {
                  numPointerDownsOnParent++;
                },
              ),
              Positioned(
                child: SizedBox(
                  width: 200.0,
                  height: 100.0,
                  child: UiKitView(
                    viewType: 'webview',
                    hitTestBehavior: PlatformViewHitTestBehavior.translucent,
                    layoutDirection: TextDirection.ltr,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // First frame is before the platform view was created so the render object
      // is not yet in the tree.
      await tester.pump();

      final TestGesture gesture = await tester.startGesture(const Offset(50.0, 50.0));
      await gesture.up();

      expect(viewsController.gesturesAccepted[currentViewId + 1], 1);

      expect(numPointerDownsOnParent, 1);
    });

    testWidgets('UiKitView opaque hit test behavior', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');

      int numPointerDownsOnParent = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: <Widget>[
              Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (PointerDownEvent e) {
                  numPointerDownsOnParent++;
                },
              ),
              Positioned(
                child: SizedBox(
                  width: 200.0,
                  height: 100.0,
                  child: UiKitView(
                    viewType: 'webview',
                    hitTestBehavior: PlatformViewHitTestBehavior.opaque,
                    layoutDirection: TextDirection.ltr,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // First frame is before the platform view was created so the render object
      // is not yet in the tree.
      await tester.pump();

      final TestGesture gesture = await tester.startGesture(const Offset(50.0, 50.0));
      await gesture.up();

      expect(viewsController.gesturesAccepted[currentViewId + 1], 1);
      expect(numPointerDownsOnParent, 0);
    });

    testWidgets('UiKitView can lose gesture arenas', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');

      bool verticalDragAcceptedByParent = false;
      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.all(10.0),
            child: GestureDetector(
              onVerticalDragStart: (DragStartDetails d) {
                verticalDragAcceptedByParent = true;
              },
              child: SizedBox(
                width: 200.0,
                height: 100.0,
                child: UiKitView(viewType: 'webview', layoutDirection: TextDirection.ltr),
              ),
            ),
          ),
        ),
      );

      // First frame is before the platform view was created so the render object
      // is not yet in the tree.
      await tester.pump();

      final TestGesture gesture = await tester.startGesture(const Offset(50.0, 50.0));
      await gesture.moveBy(const Offset(0.0, 100.0));
      await gesture.up();

      expect(verticalDragAcceptedByParent, true);
      expect(viewsController.gesturesAccepted[currentViewId + 1], 0);
    });

    testWidgets('UiKitView gesture recognizers', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');
      bool verticalDragAcceptedByParent = false;
      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: GestureDetector(
            onVerticalDragStart: (DragStartDetails d) {
              verticalDragAcceptedByParent = true;
            },
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: UiKitView(
                viewType: 'webview',
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                  Factory<VerticalDragGestureRecognizer>(
                        () => VerticalDragGestureRecognizer(),
                  ),
                ].toSet(),
                layoutDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      );

      // First frame is before the platform view was created so the render object
      // is not yet in the tree.
      await tester.pump();

      final TestGesture gesture = await tester.startGesture(const Offset(50.0, 50.0));
      await gesture.moveBy(const Offset(0.0, 100.0));
      await gesture.up();

      expect(verticalDragAcceptedByParent, false);
      expect(viewsController.gesturesAccepted[currentViewId + 1], 1);
    });

    testWidgets('UiKitView can claim gesture after all pointers are up', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');
      bool verticalDragAcceptedByParent = false;
      // The long press recognizer rejects the gesture after the AndroidView gets the pointer up event.
      // This test makes sure that the Android view can win the gesture after it got the pointer up event.
      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: GestureDetector(
            onVerticalDragStart: (DragStartDetails d) {
              verticalDragAcceptedByParent = true;
            },
            onLongPress: () {},
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: UiKitView(
                viewType: 'webview',
                layoutDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      );

      // First frame is before the platform view was created so the render object
      // is not yet in the tree.
      await tester.pump();

      final TestGesture gesture = await tester.startGesture(const Offset(50.0, 50.0));
      await gesture.up();

      expect(verticalDragAcceptedByParent, false);

      expect(viewsController.gesturesAccepted[currentViewId + 1], 1);
    });

    testWidgets('UiKitView rebuilt during gesture', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');
      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: UiKitView(
              viewType: 'webview',
              layoutDirection: TextDirection.ltr,
            ),
          ),
        ),
      );

      // First frame is before the platform view was created so the render object
      // is not yet in the tree.
      await tester.pump();

      final TestGesture gesture = await tester.startGesture(const Offset(50.0, 50.0));
      await gesture.moveBy(const Offset(0.0, 100.0));

      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: UiKitView(
              viewType: 'webview',
              layoutDirection: TextDirection.ltr,
            ),
          ),
        ),
      );

      await gesture.up();

      expect(viewsController.gesturesAccepted[currentViewId + 1], 1);
    });

    testWidgets('UiKitView with eager gesture recognizer', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');
      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: GestureDetector(
            onVerticalDragStart: (DragStartDetails d) {},
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: UiKitView(
                viewType: 'webview',
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                  Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                  ),
                ].toSet(),
                layoutDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      );

      // First frame is before the platform view was created so the render object
      // is not yet in the tree.
      await tester.pump();

      await tester.startGesture(const Offset(50.0, 50.0));

      // Normally (without the eager gesture recognizer) after just the pointer down event
      // no gesture arena member will claim the arena (so no motion events will be dispatched to
      // the Android view). Here we assert that with the eager recognizer in the gesture team the
      // pointer down event is immediately dispatched.
      expect(viewsController.gesturesAccepted[currentViewId + 1], 1);
    });

    testWidgets('AndroidView rebuilt with same gestureRecognizers', (WidgetTester tester) async {
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');

      int factoryInvocationCount = 0;
      final ValueGetter<EagerGestureRecognizer> constructRecognizer = () {
        factoryInvocationCount += 1;
        return EagerGestureRecognizer();
      };

      await tester.pumpWidget(
        UiKitView(
          viewType: 'webview',
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
            Factory<EagerGestureRecognizer>(constructRecognizer),
          ].toSet(),
          layoutDirection: TextDirection.ltr,
        ),
      );

      await tester.pumpWidget(
        UiKitView(
          viewType: 'webview',
          hitTestBehavior: PlatformViewHitTestBehavior.translucent,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
            Factory<EagerGestureRecognizer>(constructRecognizer),
          ].toSet(),
          layoutDirection: TextDirection.ltr,
        ),
      );

      expect(factoryInvocationCount, 1);
    });
  });
}
