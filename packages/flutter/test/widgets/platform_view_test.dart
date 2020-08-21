// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

@TestOn('!chrome')
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

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
              AndroidViewController.kAndroidLayoutDirectionLtr, null),
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
          rawCreationParams.lengthInBytes,
      );
      final dynamic actualParams = const StringCodec().decodeMessage(byteData);

      expect(actualParams, 'creation parameters');
      expect(
        viewsController.views,
        unorderedEquals(<FakeAndroidPlatformView>[
          FakeAndroidPlatformView(currentViewId + 1, 'webview', const Size(200.0, 100.0),
              AndroidViewController.kAndroidLayoutDirectionLtr, null, fakeView.creationParams),
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
      expect(textureParentLayer, isA<ClipRectLayer>());
      final ClipRectLayer clipRect = textureParentLayer as ClipRectLayer;
      expect(clipRect.clipRect, const Rect.fromLTWH(0.0, 0.0, 100.0, 50.0));
      expect(
        viewsController.views,
        unorderedEquals(<FakeAndroidPlatformView>[
          FakeAndroidPlatformView(currentViewId + 1, 'webview', const Size(200.0, 100.0),
              AndroidViewController.kAndroidLayoutDirectionLtr, null),
        ]),
      );

      viewsController.resizeCompleter.complete();
      await tester.pump();

      expect(
        viewsController.views,
        unorderedEquals(<FakeAndroidPlatformView>[
          FakeAndroidPlatformView(currentViewId + 1, 'webview', const Size(100.0, 50.0),
              AndroidViewController.kAndroidLayoutDirectionLtr, null),
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
              AndroidViewController.kAndroidLayoutDirectionLtr, null),
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
              AndroidViewController.kAndroidLayoutDirectionLtr, null),
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
          1,
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
          1,
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
          0,
      );
    });

    testWidgets("Android view touch events are in virtual display's coordinate system", (WidgetTester tester) async {
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
              AndroidViewController.kAndroidLayoutDirectionRtl, null),
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
              AndroidViewController.kAndroidLayoutDirectionLtr, null),
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
              AndroidViewController.kAndroidLayoutDirectionRtl, null),
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
              AndroidViewController.kAndroidLayoutDirectionLtr, null),
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

    testWidgets('Android view drag gesture recognizer', (WidgetTester tester) async {
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
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<VerticalDragGestureRecognizer>(
                    () {
                      return VerticalDragGestureRecognizer();
                    },
                  ),
                },
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

    testWidgets('Android view long press gesture recognizer', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');
      bool longPressAccessedByParent = false;
      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: GestureDetector(
            onLongPress: () {
              longPressAccessedByParent = true;
            },
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: AndroidView(
                viewType: 'webview',
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<LongPressGestureRecognizer>(
                    () {
                      return LongPressGestureRecognizer();
                    },
                  ),
                },
                layoutDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      );

      await tester.longPressAt(const Offset(50.0, 50.0));

      expect(longPressAccessedByParent, false);
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

    testWidgets('Android view tap gesture recognizer', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');
      bool tapAccessedByParent = false;
      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: GestureDetector(
            onTap: () {
              tapAccessedByParent = true;
            },
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: AndroidView(
                viewType: 'webview',
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<TapGestureRecognizer>(
                    () {
                      return TapGestureRecognizer();
                    },
                  ),
                },
                layoutDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      );

      await tester.tapAt(const Offset(50.0, 50.0));

      expect(tapAccessedByParent, false);
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

    testWidgets('Android view can claim gesture after all pointers are up', (WidgetTester tester) async {
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
            onLongPress: () { },
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
            onVerticalDragStart: (DragStartDetails d) { },
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: AndroidView(
                viewType: 'webview',
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                  ),
                },
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

    // This test makes sure it doesn't crash.
    // https://github.com/flutter/flutter/issues/21514
    testWidgets('RenderAndroidView reconstructed with same gestureRecognizers does not crash', (WidgetTester tester) async {
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');

      final AndroidView androidView = AndroidView(
        viewType: 'webview',
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<EagerGestureRecognizer>(
                () => EagerGestureRecognizer(),
          ),
        },
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
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<EagerGestureRecognizer>(constructRecognizer),
          },
          layoutDirection: TextDirection.ltr,
        ),
      );

      await tester.pumpWidget(
        AndroidView(
          viewType: 'webview',
          hitTestBehavior: PlatformViewHitTestBehavior.translucent,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<EagerGestureRecognizer>(constructRecognizer),
          },
          layoutDirection: TextDirection.ltr,
        ),
      );

      expect(factoryInvocationCount, 1);
    });

    testWidgets('AndroidView has correct semantics', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      expect(currentViewId, greaterThanOrEqualTo(0));
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');

      viewsController.createCompleter = Completer<void>();

      await tester.pumpWidget(
        Semantics(
          container: true,
          child: const Align(
            alignment: Alignment.bottomRight,
            child: SizedBox(
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

      // Find the first _AndroidPlatformView widget inside of the AndroidView so
      // that it finds the right RenderObject when looking for semantics.
      final Finder semanticsFinder = find.byWidgetPredicate(
            (Widget widget) {
          return widget.runtimeType.toString() == '_AndroidPlatformView';
        },
        description: '_AndroidPlatformView widget inside AndroidView',
      );
      final SemanticsNode semantics = tester.getSemantics(semanticsFinder.first);

      // Platform view has not been created yet, no platformViewId.
      expect(semantics.platformViewId, null);
      expect(semantics.rect, const Rect.fromLTWH(0, 0, 200, 100));
      // A 200x100 rect positioned at bottom right of a 800x600 box.
      expect(semantics.transform, Matrix4.translationValues(600, 500, 0));
      expect(semantics.childrenCount, 0);

      viewsController.createCompleter.complete();
      await tester.pumpAndSettle();

      expect(semantics.platformViewId, currentViewId + 1);
      expect(semantics.rect, const Rect.fromLTWH(0, 0, 200, 100));
      // A 200x100 rect positioned at bottom right of a 800x600 box.
      expect(semantics.transform, Matrix4.translationValues(600, 500, 0));
      expect(semantics.childrenCount, 0);

      handle.dispose();
    });

    testWidgets('AndroidView can take input focus', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');

      viewsController.createCompleter = Completer<void>();

      final GlobalKey containerKey = GlobalKey();
      await tester.pumpWidget(
        Center(
          child: Column(
            children: <Widget>[
              const SizedBox(
                width: 200.0,
                height: 100.0,
                child: AndroidView(viewType: 'webview', layoutDirection: TextDirection.ltr),
              ),
              Focus(
                debugLabel: 'container',
                child: Container(key: containerKey),
              ),
            ],
          ),
        ),
      );

      final Focus androidViewFocusWidget =
      tester.widget(
          find.descendant(
              of: find.byType(AndroidView),
              matching: find.byType(Focus),
          ),
      );
      final Element containerElement = tester.element(find.byKey(containerKey));
      final FocusNode androidViewFocusNode = androidViewFocusWidget.focusNode;
      final FocusNode containerFocusNode = Focus.of(containerElement);

      containerFocusNode.requestFocus();

      await tester.pump();

      expect(containerFocusNode.hasFocus, isTrue);
      expect(androidViewFocusNode.hasFocus, isFalse);

      viewsController.invokeViewFocused(currentViewId + 1);

      await tester.pump();

      expect(containerFocusNode.hasFocus, isFalse);
      expect(androidViewFocusNode.hasFocus, isTrue);
    });

    testWidgets('AndroidView sets a platform view text input client when focused', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');

      viewsController.createCompleter = Completer<void>();

      final GlobalKey containerKey = GlobalKey();
      await tester.pumpWidget(
        Center(
          child: Column(
            children: <Widget>[
              const SizedBox(
                width: 200.0,
                height: 100.0,
                child: AndroidView(viewType: 'webview', layoutDirection: TextDirection.ltr),
              ),
              Focus(
                debugLabel: 'container',
                child: Container(key: containerKey),
              ),
            ],
          ),
        ),
      );

      viewsController.createCompleter.complete();


      final Element containerElement = tester.element(find.byKey(containerKey));
      final FocusNode containerFocusNode = Focus.of(containerElement);

      containerFocusNode.requestFocus();
      await tester.pump();

      int lastPlatformViewTextClient;
      SystemChannels.textInput.setMockMethodCallHandler((MethodCall call) {
        if (call.method == 'TextInput.setPlatformViewClient') {
          lastPlatformViewTextClient = call.arguments as int;
        }
        return null;
      });

      viewsController.invokeViewFocused(currentViewId + 1);
      await tester.pump();

      expect(lastPlatformViewTextClient, currentViewId + 1);
    });

    testWidgets('AndroidView clears platform focus when unfocused', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeAndroidPlatformViewsController viewsController = FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');

      viewsController.createCompleter = Completer<void>();

      final GlobalKey containerKey = GlobalKey();
      await tester.pumpWidget(
        Center(
          child: Column(
            children: <Widget>[
              const SizedBox(
                width: 200.0,
                height: 100.0,
                child: AndroidView(viewType: 'webview', layoutDirection: TextDirection.ltr),
              ),
              Focus(
                debugLabel: 'container',
                child: Container(key: containerKey),
              ),
            ],
          ),
        ),
      );

      viewsController.createCompleter.complete();

      final Element containerElement = tester.element(find.byKey(containerKey));
      final FocusNode containerFocusNode = Focus.of(containerElement);

      containerFocusNode.requestFocus();
      await tester.pump();

      viewsController.invokeViewFocused(currentViewId + 1);
      await tester.pump();

      viewsController.lastClearedFocusViewId = null;

      containerFocusNode.requestFocus();
      await tester.pump();

      expect(viewsController.lastClearedFocusViewId, currentViewId + 1);
    });
  });

  group('AndroidViewSurface', () {
    FakeAndroidViewController controller;

    setUp(() {
      controller = FakeAndroidViewController(0);
    });

    testWidgets('AndroidViewSurface sets pointTransformer of view controller', (WidgetTester tester) async {
      final AndroidViewSurface surface = AndroidViewSurface(
        controller: controller,
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},);
      await tester.pumpWidget(surface);
      expect(controller.pointTransformer, isNotNull);
    });
  });

  group('UiKitView', () {
    testWidgets('Create UIView', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');

      await tester.pumpWidget(
        const Center(
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
          FakeUiKitView(currentViewId + 1, 'webview'),
        ]),
      );
    });

    testWidgets('Change UIView view type', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');
      viewsController.registerViewType('maps');
      await tester.pumpWidget(
        const Center(
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
            child: UiKitView(viewType: 'maps', layoutDirection: TextDirection.ltr),
          ),
        ),
      );

      expect(
        viewsController.views,
        unorderedEquals(<FakeUiKitView>[
          FakeUiKitView(currentViewId + 2, 'maps'),
        ]),
      );
    });

    testWidgets('Dispose UIView ', (WidgetTester tester) async {
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');
      await tester.pumpWidget(
        const Center(
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
        const Center(
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
          FakeUiKitView(currentViewId + 1, 'webview'),
        ]),
      );
    });

    testWidgets('Create UIView with params', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');

      await tester.pumpWidget(
        const Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: UiKitView(
              viewType: 'webview',
              layoutDirection: TextDirection.ltr,
              creationParams: 'creation parameters',
              creationParamsCodec: StringCodec(),
            ),
          ),
        ),
      );

      final FakeUiKitView fakeView = viewsController.views.first;
      final Uint8List rawCreationParams = fakeView.creationParams;
      final ByteData byteData = ByteData.view(
          rawCreationParams.buffer,
          rawCreationParams.offsetInBytes,
          rawCreationParams.lengthInBytes,
      );
      final dynamic actualParams = const StringCodec().decodeMessage(byteData);

      expect(actualParams, 'creation parameters');
      expect(
        viewsController.views,
        unorderedEquals(<FakeUiKitView>[
          FakeUiKitView(currentViewId + 1, 'webview', fakeView.creationParams),
        ]),
      );
    });

    testWidgets('UiKitView accepts gestures', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');

      await tester.pumpWidget(
        const Align(
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
              const Positioned(
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
              const Positioned(
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
              const Positioned(
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
              child: const SizedBox(
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
      expect(viewsController.gesturesRejected[currentViewId + 1], 1);
    });

    testWidgets('UiKitView tap gesture recognizers', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');
      bool gestureAcceptedByParent = false;
      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: GestureDetector(
            onVerticalDragStart: (DragStartDetails d) {
              gestureAcceptedByParent = true;
            },
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: UiKitView(
                viewType: 'webview',
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<VerticalDragGestureRecognizer>(
                    () {
                      return VerticalDragGestureRecognizer();
                    },
                  ),
                },
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

      expect(gestureAcceptedByParent, false);
      expect(viewsController.gesturesAccepted[currentViewId + 1], 1);
      expect(viewsController.gesturesRejected[currentViewId + 1], 0);
    });

    testWidgets('UiKitView long press gesture recognizers', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');
      bool gestureAcceptedByParent = false;
      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: GestureDetector(
            onLongPress: () {
              gestureAcceptedByParent = true;
            },
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: UiKitView(
                viewType: 'webview',
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<LongPressGestureRecognizer>(
                    () {
                      return LongPressGestureRecognizer();
                    },
                  ),
                },
                layoutDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      );

      // First frame is before the platform view was created so the render object
      // is not yet in the tree.
      await tester.pump();

      await tester.longPressAt(const Offset(50.0, 50.0));

      expect(gestureAcceptedByParent, false);
      expect(viewsController.gesturesAccepted[currentViewId + 1], 1);
      expect(viewsController.gesturesRejected[currentViewId + 1], 0);
    });

    testWidgets('UiKitView drag gesture recognizers', (WidgetTester tester) async {
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
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<TapGestureRecognizer>(
                    () {
                      return TapGestureRecognizer();
                    },
                  ),
                },
                layoutDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      );

      // First frame is before the platform view was created so the render object
      // is not yet in the tree.
      await tester.pump();

      await tester.tapAt(const Offset(50.0, 50.0));

      expect(verticalDragAcceptedByParent, false);
      expect(viewsController.gesturesAccepted[currentViewId + 1], 1);
      expect(viewsController.gesturesRejected[currentViewId + 1], 0);
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
            onLongPress: () { },
            child: const SizedBox(
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
      expect(viewsController.gesturesRejected[currentViewId + 1], 0);
    });

    testWidgets('UiKitView rebuilt during gesture', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');
      await tester.pumpWidget(
        const Align(
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
        const Align(
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
      expect(viewsController.gesturesRejected[currentViewId + 1], 0);
    });

    testWidgets('UiKitView with eager gesture recognizer', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');
      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: GestureDetector(
            onVerticalDragStart: (DragStartDetails d) { },
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: UiKitView(
                viewType: 'webview',
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                  ),
                },
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
      expect(viewsController.gesturesRejected[currentViewId + 1], 0);
    });

    testWidgets('UiKitView rejects gestures absorbed by siblings', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');

      await tester.pumpWidget(
        Stack(
          alignment: Alignment.topLeft,
          children: <Widget>[
            const UiKitView(viewType: 'webview', layoutDirection: TextDirection.ltr),
            Container(
              color: const Color.fromARGB(255, 255, 255, 255),
              width: 100,
              height: 100,
            ),
          ],
        ),
      );

      // First frame is before the platform view was created so the render object
      // is not yet in the tree.
      await tester.pump();

      final TestGesture gesture = await tester.startGesture(const Offset(50.0, 50.0));
      await gesture.up();

      expect(viewsController.gesturesRejected[currentViewId + 1], 1);
      expect(viewsController.gesturesAccepted[currentViewId + 1], 0);
    });

    testWidgets('UiKitView rejects gestures absorbed by siblings if the touch is outside of the platform view bounds but inside platform view frame', (WidgetTester tester) async {
      // UiKitView is positioned at (left=0, top=100, right=300, bottom=600).
      // Opaque container is on top of the UiKitView positioned at (left=0, top=500, right=300, bottom=600).
      // Touch on (550, 150) is expected to be absorbed by the container.
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');

      await tester.pumpWidget(
        Container(width: 300, height: 600,
          child: Stack(
            alignment: Alignment.topLeft,
            children: <Widget>[
              Transform.translate(
                offset: const Offset(0, 100),
                child: Container(
                  width: 300,
                  height: 500,
                  child: const UiKitView(viewType: 'webview', layoutDirection: TextDirection.ltr)),),
              Transform.translate(
                offset: const Offset(0, 500),
                child: Container(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  width: 300,
                  height: 100,
              ),),
            ],
          ),
        ),
      );

      // First frame is before the platform view was created so the render object
      // is not yet in the tree.
      await tester.pump();

      final TestGesture gesture = await tester.startGesture(const Offset(150, 550));
      await gesture.up();

      expect(viewsController.gesturesRejected[currentViewId + 1], 1);
      expect(viewsController.gesturesAccepted[currentViewId + 1], 0);
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
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<EagerGestureRecognizer>(constructRecognizer),
          },
          layoutDirection: TextDirection.ltr,
        ),
      );

      await tester.pumpWidget(
        UiKitView(
          viewType: 'webview',
          hitTestBehavior: PlatformViewHitTestBehavior.translucent,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<EagerGestureRecognizer>(constructRecognizer),
          },
          layoutDirection: TextDirection.ltr,
        ),
      );

      expect(factoryInvocationCount, 1);
    });

    testWidgets('UiKitView has correct semantics', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      expect(currentViewId, greaterThanOrEqualTo(0));
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');

      await tester.pumpWidget(
        Semantics(
          container: true,
          child: const Align(
            alignment: Alignment.bottomRight,
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

      final SemanticsNode semantics = tester.getSemantics(find.byType(UiKitView));

      expect(semantics.platformViewId, currentViewId + 1);
      expect(semantics.rect, const Rect.fromLTWH(0, 0, 200, 100));
      // A 200x100 rect positioned at bottom right of a 800x600 box.
      expect(semantics.transform, Matrix4.translationValues(600, 500, 0));
      expect(semantics.childrenCount, 0);

      handle.dispose();
    });
  });

  group('Common PlatformView', () {
    FakePlatformViewController controller;

    setUp((){
      controller = FakePlatformViewController(0);
    });

    testWidgets('PlatformViewSurface should create platform view layer', (WidgetTester tester) async {
      final PlatformViewSurface surface = PlatformViewSurface(
        controller: controller,
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},);
      await tester.pumpWidget(surface);
      expect(() => tester.layers.whereType<PlatformViewLayer>().first, returnsNormally);
    });

    testWidgets('PlatformViewSurface can lose gesture arenas', (WidgetTester tester) async {
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
                child: PlatformViewSurface(
                  controller: controller,
                  gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
                  hitTestBehavior: PlatformViewHitTestBehavior.opaque),
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
        controller.dispatchedPointerEvents,
        isEmpty,
      );
    });

    testWidgets('PlatformViewSurface gesture recognizers dispatch events', (WidgetTester tester) async {
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
              child: PlatformViewSurface(
                controller: controller,
                hitTestBehavior: PlatformViewHitTestBehavior.opaque,
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<VerticalDragGestureRecognizer>(
                    () {
                      return VerticalDragGestureRecognizer();
                    },
                  ),
                },
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
        controller.dispatchedPointerEvents.length,
        3,
      );

    });

    testWidgets('PlatformViewSurface can claim gesture after all pointers are up', (WidgetTester tester) async {
      bool verticalDragAcceptedByParent = false;
      // The long press recognizer rejects the gesture after the PlatformViewSurface gets the pointer up event.
      // This test makes sure that the PlatformViewSurface can win the gesture after it got the pointer up event.
      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: GestureDetector(
            onVerticalDragStart: (DragStartDetails d) {
              verticalDragAcceptedByParent = true;
            },
            onLongPress: () { },
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: PlatformViewSurface(
                controller: controller,
                hitTestBehavior: PlatformViewHitTestBehavior.opaque,
                gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
              ),
            ),
          ),
        ),
      );

      final TestGesture gesture = await tester.startGesture(const Offset(50.0, 50.0));
      await gesture.up();

      expect(verticalDragAcceptedByParent, false);
      expect(
        controller.dispatchedPointerEvents.length,
        2,
      );

    });

    testWidgets('PlatformViewSurface rebuilt during gesture', (WidgetTester tester) async {
      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: PlatformViewSurface(
                controller: controller,
                hitTestBehavior: PlatformViewHitTestBehavior.opaque,
                gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            ),
          ),
        ),
      );

      final TestGesture gesture = await tester.startGesture(const Offset(50.0, 50.0));
      await gesture.moveBy(const Offset(0.0, 100.0));

      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: PlatformViewSurface(
                controller: controller,
                hitTestBehavior: PlatformViewHitTestBehavior.opaque,
                gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            ),
          ),
        ),
      );

      await gesture.up();

      expect(
        controller.dispatchedPointerEvents.length,
        3,
      );
    });

    testWidgets('PlatformViewSurface with eager gesture recognizer', (WidgetTester tester) async {
      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: GestureDetector(
            onVerticalDragStart: (DragStartDetails d) { },
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: PlatformViewSurface(
                controller: controller,
                hitTestBehavior: PlatformViewHitTestBehavior.opaque,
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                  ),
                },
              ),
            ),
          ),
        ),
      );

      await tester.startGesture(const Offset(50.0, 50.0));

      // Normally (without the eager gesture recognizer) after just the pointer down event
      // no gesture arena member will claim the arena (so no motion events will be dispatched to
      // the PlatformViewSurface). Here we assert that with the eager recognizer in the gesture team the
      // pointer down event is immediately dispatched.
      expect(
        controller.dispatchedPointerEvents.length,
        1,
      );
    });

    testWidgets('PlatformViewRenderBox reconstructed with same gestureRecognizers', (WidgetTester tester) async {

      int factoryInvocationCount = 0;
      final ValueGetter<EagerGestureRecognizer> constructRecognizer = () {
        ++ factoryInvocationCount;
        return EagerGestureRecognizer();
      };

      final PlatformViewSurface platformViewSurface = PlatformViewSurface(
              controller: controller,
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                      constructRecognizer,
                ),
              });

      await tester.pumpWidget(platformViewSurface);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(platformViewSurface);

      expect(factoryInvocationCount, 2);
    });

    testWidgets('PlatformViewSurface rebuilt with same gestureRecognizers', (WidgetTester tester) async {

      int factoryInvocationCount = 0;
      final ValueGetter<EagerGestureRecognizer> constructRecognizer = () {
        ++ factoryInvocationCount;
        return EagerGestureRecognizer();
      };

      await tester.pumpWidget(
        PlatformViewSurface(
          controller: controller,
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
                  constructRecognizer,
            ),
          },
        ),
      );

      await tester.pumpWidget(
        PlatformViewSurface(
          controller: controller,
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
                  constructRecognizer,
            ),
          },
        ),
      );
      expect(factoryInvocationCount, 1);
    });

    testWidgets('PlatformViewLink Widget init, should create a SizedBox widget before onPlatformViewCreated and a PlatformViewSurface after', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      int createdPlatformViewId;

      PlatformViewCreatedCallback onPlatformViewCreatedCallBack;

      final PlatformViewLink platformViewLink = PlatformViewLink(
        viewType: 'webview',
        onCreatePlatformView: (PlatformViewCreationParams params){
          onPlatformViewCreatedCallBack = params.onPlatformViewCreated;
          createdPlatformViewId = params.id;
          return FakePlatformViewController(params.id);
        },
        surfaceFactory: (BuildContext context, PlatformViewController controller) {
          return PlatformViewSurface(
              gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
              controller: controller,
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
      });

      await tester.pumpWidget(platformViewLink);
      expect(() => tester.allWidgets.whereType<SizedBox>().first, returnsNormally);

      onPlatformViewCreatedCallBack(createdPlatformViewId);

      await tester.pump();

      expect(() => tester.allWidgets.whereType<PlatformViewSurface>().first, returnsNormally);

      expect(createdPlatformViewId, currentViewId+1);
    });

    testWidgets('PlatformViewLink Widget dispose', (WidgetTester tester) async {
      FakePlatformViewController disposedController;
      final PlatformViewLink platformViewLink = PlatformViewLink(
        viewType: 'webview',
        onCreatePlatformView: (PlatformViewCreationParams params){
          disposedController = FakePlatformViewController(params.id);
          params.onPlatformViewCreated(params.id);
          return disposedController;
        },
        surfaceFactory: (BuildContext context,PlatformViewController controller) {
          return PlatformViewSurface(
              gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
              controller: controller,
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
      });

      await tester.pumpWidget(platformViewLink);

      await tester.pumpWidget(Container());

      expect(disposedController.disposed, true);
    });

    testWidgets('PlatformViewLink widget survives widget tree change', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final List<int> ids = <int>[];

      FakePlatformViewController controller;

      PlatformViewLink createPlatformViewLink() {
        return PlatformViewLink(
          key: key,
          viewType: 'webview',
          onCreatePlatformView: (PlatformViewCreationParams params){
            ids.add(params.id);
            controller = FakePlatformViewController(params.id);
            params.onPlatformViewCreated(params.id);
            return controller;
          },
          surfaceFactory: (BuildContext context, PlatformViewController controller) {
            return PlatformViewSurface(
              gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
              controller: controller,
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            );
          },
        );
      }
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: createPlatformViewLink(),
          ),
        ),
      );

      await tester.pumpWidget(
        Center(
          child: Container(
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: createPlatformViewLink(),
            ),
          ),
        ),
      );

      expect(
        ids,
        unorderedEquals(<int>[
          currentViewId+1,
        ]),
      );
    });

    testWidgets('PlatformViewLink re-initializes when view type changes', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final List<int> ids = <int>[];
      final List<int> surfaceViewIds = <int>[];
      final List<String> viewTypes = <String>[];

      PlatformViewLink createPlatformViewLink(String viewType) {
        return PlatformViewLink(
          viewType: viewType,
          onCreatePlatformView: (PlatformViewCreationParams params){
            ids.add(params.id);
            viewTypes.add(params.viewType);
            controller = FakePlatformViewController(params.id);
            params.onPlatformViewCreated(params.id);
            return controller;
          },
          surfaceFactory: (BuildContext context, PlatformViewController controller) {
            surfaceViewIds.add(controller.viewId);
            return PlatformViewSurface(
              gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
              controller: controller,
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            );
          },
        );
      }
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: createPlatformViewLink('webview'),
          ),
        ),
      );

      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: createPlatformViewLink('maps'),
          ),
        ),
      );

      expect(
        ids,
        unorderedEquals(<int>[
          currentViewId+1, currentViewId+2,
        ]),
      );

      expect(
        surfaceViewIds,
        unorderedEquals(<int>[
          currentViewId+1, currentViewId+2,
        ]),
      );

      expect(
        viewTypes,
        unorderedEquals(<String>[
          'webview', 'maps',
        ]),
      );
    });

    testWidgets('PlatformViewLink can take any widget to return in the SurfaceFactory', (WidgetTester tester) async {
      final PlatformViewLink platformViewLink = PlatformViewLink(
        viewType: 'webview',
        onCreatePlatformView: (PlatformViewCreationParams params){
          params.onPlatformViewCreated(params.id);
          return FakePlatformViewController(params.id);
        },
        surfaceFactory: (BuildContext context,PlatformViewController controller) {
          return Container();
        });

      await tester.pumpWidget(platformViewLink);

      expect(() => tester.allWidgets.whereType<Container>().first, returnsNormally);
    });

    testWidgets('PlatformViewLink manages the focus properly', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      FakePlatformViewController controller;
      ValueChanged<bool> focusChanged;
      final PlatformViewLink platformViewLink = PlatformViewLink(
        viewType: 'webview',
        onCreatePlatformView: (PlatformViewCreationParams params){
          params.onPlatformViewCreated(params.id);
          focusChanged = params.onFocusChanged;
          controller = FakePlatformViewController(params.id);
          return controller;
        },
        surfaceFactory: (BuildContext context, PlatformViewController controller) {
          return PlatformViewSurface(
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            controller: controller,
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      });
      await tester.pumpWidget(
        Center(
          child: Column(
            children: <Widget>[
              SizedBox(child: platformViewLink, width: 300, height: 300,),
              Focus(
                debugLabel: 'container',
                child: Container(key: containerKey),
              ),
            ],
          ),
        ),
      );
      final Focus platformViewFocusWidget =
      tester.widget(
          find.descendant(
              of: find.byType(PlatformViewLink),
              matching: find.byType(Focus),
          ),
      );
      final FocusNode platformViewFocusNode = platformViewFocusWidget.focusNode;
      final Element containerElement = tester.element(find.byKey(containerKey));
      final FocusNode containerFocusNode = Focus.of(containerElement);

      containerFocusNode.requestFocus();
      await tester.pump();

      expect(containerFocusNode.hasFocus, true);
      expect(platformViewFocusNode.hasFocus, false);

      // ask the platform view to gain focus
      focusChanged(true);
      await tester.pump();

      expect(containerFocusNode.hasFocus, false);
      expect(platformViewFocusNode.hasFocus, true);
      expect(controller.focusCleared, false);
      // ask the container to gain focus, and the platform view should clear focus.
      containerFocusNode.requestFocus();
      await tester.pump();

      expect(containerFocusNode.hasFocus, true);
      expect(platformViewFocusNode.hasFocus, false);
      expect(controller.focusCleared, true);
    });
  });

  testWidgets('Platform views respect hitTestBehavior', (WidgetTester tester) async {
    final FakePlatformViewController controller = FakePlatformViewController(0);

    final List<String> logs = <String>[];

    // -------------------------
    // | MouseRegion1          |       MouseRegion1
    // |  |-----------------|  |        |
    // |  | MouseRegion2    |  |        |- Stack
    // |  |   |---------|   |  |            |
    // |  |   |Platform |   |  |            |- MouseRegion2
    // |  |   |View     |   |  |            |- PlatformView
    // |  |   |---------|   |  |
    // |  |                 |  |
    // |  |-----------------|  |
    // |                       |
    // -------------------------
    Widget scaffold(Widget target) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 600,
            height: 600,
            child: MouseRegion(
              onEnter: (_) { logs.add('enter1'); },
              onExit: (_) { logs.add('exit1'); },
              cursor: SystemMouseCursors.forbidden,
              child: Stack(
                children: <Widget>[
                  Center(
                    child: SizedBox(
                      width: 400,
                      height: 400,
                      child: MouseRegion(
                        onEnter: (_) { logs.add('enter2'); },
                        onExit: (_) { logs.add('exit2'); },
                        cursor: SystemMouseCursors.text,
                      ),
                    ),
                  ),
                  Center(
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: target,
                    ),
                  ),
                ],
              )
            ),
          ),
        ),
      );
    }

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 0);
    addTearDown(gesture.removePointer);

    // Test: Opaque
    await tester.pumpWidget(
      scaffold(PlatformViewSurface(
        controller: controller,
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{}
      ))
    );
    logs.clear();

    await gesture.moveTo(const Offset(400, 300));
    expect(logs, <String>['enter1']);
    expect(controller.dispatchedPointerEvents, hasLength(1));
    expect(controller.dispatchedPointerEvents[0].runtimeType, PointerHoverEvent);
    logs.clear();
    controller.dispatchedPointerEvents.clear();

    // Test: changing no option does not trigger events
    await tester.pumpWidget(
      scaffold(PlatformViewSurface(
        controller: controller,
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{}
      ))
    );
    expect(logs, isEmpty);
    expect(controller.dispatchedPointerEvents, isEmpty);

    // Test: Transluscent
    await tester.pumpWidget(
      scaffold(PlatformViewSurface(
        controller: controller,
        hitTestBehavior: PlatformViewHitTestBehavior.translucent,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{}
      ))
    );
    expect(logs, <String>['enter2']);
    expect(controller.dispatchedPointerEvents, isEmpty);
    logs.clear();

    await gesture.moveBy(const Offset(1, 1));
    expect(logs, isEmpty);
    expect(controller.dispatchedPointerEvents, hasLength(1));
    expect(controller.dispatchedPointerEvents[0].runtimeType, PointerHoverEvent);
    expect(controller.dispatchedPointerEvents[0].position, const Offset(401, 301));
    expect(controller.dispatchedPointerEvents[0].localPosition, const Offset(101, 101));
    controller.dispatchedPointerEvents.clear();

    // Test: Transparent
    await tester.pumpWidget(
      scaffold(PlatformViewSurface(
        controller: controller,
        hitTestBehavior: PlatformViewHitTestBehavior.transparent,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{}
      ))
    );
    expect(logs, isEmpty);
    expect(controller.dispatchedPointerEvents, isEmpty);

    await gesture.moveBy(const Offset(1, 1));
    expect(logs, isEmpty);
    expect(controller.dispatchedPointerEvents, isEmpty);

    // Test: Back to opaque
    await tester.pumpWidget(
      scaffold(PlatformViewSurface(
        controller: controller,
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{}
      ))
    );
    expect(logs, <String>['exit2']);
    expect(controller.dispatchedPointerEvents, isEmpty);
    logs.clear();

    await gesture.moveBy(const Offset(1, 1));
    expect(logs, isEmpty);
    expect(controller.dispatchedPointerEvents, hasLength(1));
    expect(controller.dispatchedPointerEvents[0].runtimeType, PointerHoverEvent);
  });
}
