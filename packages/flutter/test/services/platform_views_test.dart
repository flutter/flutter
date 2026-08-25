// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_platform_views.dart';

void main() {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();

  group('Android', () {
    late FakeAndroidPlatformViewsController viewsController;
    setUp(() {
      viewsController = FakeAndroidPlatformViewsController();
    });

    test('create Android view of unregistered type', () async {
      await expectLater(
        () => PlatformViewsService.initAndroidView(
          id: 0,
          viewType: 'web',
          layoutDirection: TextDirection.ltr,
        ).create(size: const Size(100.0, 100.0)),
        throwsA(isA<PlatformException>()),
      );
      viewsController.registerViewType('web');

      try {
        await PlatformViewsService.initSurfaceAndroidView(
          id: 0,
          viewType: 'web',
          layoutDirection: TextDirection.ltr,
        ).create(size: const Size(1.0, 1.0));
      } catch (e) {
        expect(false, isTrue, reason: 'did not expected any exception, but instead got `$e`');
      }

      try {
        await PlatformViewsService.initAndroidView(
          id: 1,
          viewType: 'web',
          layoutDirection: TextDirection.ltr,
        ).create(size: const Size(1.0, 1.0));
      } catch (e) {
        expect(false, isTrue, reason: 'did not expected any exception, but instead got `$e`');
      }
    });

    test('create VD-fallback Android views', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initAndroidView(
        id: 0,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      ).create(size: const Size(100.0, 100.0));
      await PlatformViewsService.initAndroidView(
        id: 1,
        viewType: 'webview',
        layoutDirection: TextDirection.rtl,
      ).create(size: const Size(200.0, 300.0));
      expect(
        viewsController.views,
        unorderedEquals(<FakeAndroidPlatformView>[
          const FakeAndroidPlatformView(
            0,
            'webview',
            Size(100.0, 100.0),
            AndroidViewController.kAndroidLayoutDirectionLtr,
          ),
          const FakeAndroidPlatformView(
            1,
            'webview',
            Size(200.0, 300.0),
            AndroidViewController.kAndroidLayoutDirectionRtl,
          ),
        ]),
      );
    });

    test('create HC-fallback Android views', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initSurfaceAndroidView(
        id: 0,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      ).create(size: const Size(100.0, 100.0));
      await PlatformViewsService.initSurfaceAndroidView(
        id: 1,
        viewType: 'webview',
        layoutDirection: TextDirection.rtl,
      ).create(size: const Size(200.0, 300.0));
      expect(
        viewsController.views,
        unorderedEquals(<FakeAndroidPlatformView>[
          const FakeAndroidPlatformView(
            0,
            'webview',
            Size(100.0, 100.0),
            AndroidViewController.kAndroidLayoutDirectionLtr,
            hybridFallback: true,
          ),
          const FakeAndroidPlatformView(
            1,
            'webview',
            Size(200.0, 300.0),
            AndroidViewController.kAndroidLayoutDirectionRtl,
            hybridFallback: true,
          ),
        ]),
      );
    });

    test('create HC-only Android views', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initExpensiveAndroidView(
        id: 0,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      ).create(size: const Size(100.0, 100.0));
      await PlatformViewsService.initExpensiveAndroidView(
        id: 1,
        viewType: 'webview',
        layoutDirection: TextDirection.rtl,
      ).create(size: const Size(200.0, 300.0));
      expect(
        viewsController.views,
        unorderedEquals(<FakeAndroidPlatformView>[
          const FakeAndroidPlatformView(
            0,
            'webview',
            null,
            AndroidViewController.kAndroidLayoutDirectionLtr,
            hybrid: true,
          ),
          const FakeAndroidPlatformView(
            1,
            'webview',
            null,
            AndroidViewController.kAndroidLayoutDirectionRtl,
            hybrid: true,
          ),
        ]),
      );
    });

    test('default view does not use view composition by default', () async {
      viewsController.registerViewType('webview');
      final AndroidViewController controller = PlatformViewsService.initAndroidView(
        id: 0,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      );
      await controller.create(size: const Size(100.0, 100.0));
      expect(controller.requiresViewComposition, false);
    });

    test('default view does not use view composition in fallback mode', () async {
      viewsController.registerViewType('webview');
      viewsController.allowTextureLayerMode = false;
      final AndroidViewController controller = PlatformViewsService.initAndroidView(
        id: 0,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      );
      await controller.create(size: const Size(100.0, 100.0));
      viewsController.allowTextureLayerMode = true;
      expect(controller.requiresViewComposition, false);
    });

    test('surface view does not use view composition by default', () async {
      viewsController.registerViewType('webview');
      final AndroidViewController controller = PlatformViewsService.initSurfaceAndroidView(
        id: 0,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      );
      await controller.create(size: const Size(100.0, 100.0));
      expect(controller.requiresViewComposition, false);
    });

    test('surface view does uses view composition in fallback mode', () async {
      viewsController.registerViewType('webview');
      viewsController.allowTextureLayerMode = false;
      final AndroidViewController controller = PlatformViewsService.initSurfaceAndroidView(
        id: 0,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      );
      await controller.create(size: const Size(100.0, 100.0));
      viewsController.allowTextureLayerMode = true;
      expect(controller.requiresViewComposition, true);
    });

    test('expensive view uses view composition', () async {
      viewsController.registerViewType('webview');
      final AndroidViewController controller = PlatformViewsService.initExpensiveAndroidView(
        id: 0,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      );
      await controller.create(size: const Size(100.0, 100.0));
      expect(controller.requiresViewComposition, true);
    });

    test('reuse Android view id', () async {
      viewsController.registerViewType('webview');
      final AndroidViewController controller = PlatformViewsService.initAndroidView(
        id: 0,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      );
      await controller.create(size: const Size(100.0, 100.0));
      await expectLater(() {
        final AndroidViewController controller = PlatformViewsService.initAndroidView(
          id: 0,
          viewType: 'web',
          layoutDirection: TextDirection.ltr,
        );
        return controller.create(size: const Size(100.0, 100.0));
      }, throwsA(isA<PlatformException>()));
    });

    test('dispose Android view', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initAndroidView(
        id: 0,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      ).create(size: const Size(100.0, 100.0));

      final AndroidViewController viewController = PlatformViewsService.initAndroidView(
        id: 1,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      );
      await viewController.create(size: const Size(200.0, 300.0));
      await viewController.dispose();

      final AndroidViewController surfaceViewController =
          PlatformViewsService.initSurfaceAndroidView(
            id: 1,
            viewType: 'webview',
            layoutDirection: TextDirection.ltr,
          );
      await surfaceViewController.create(size: const Size(200.0, 300.0));
      await surfaceViewController.dispose();

      expect(
        viewsController.views,
        unorderedEquals(<FakeAndroidPlatformView>[
          const FakeAndroidPlatformView(
            0,
            'webview',
            Size(100.0, 100.0),
            AndroidViewController.kAndroidLayoutDirectionLtr,
          ),
        ]),
      );
    });

    test('dispose Android view twice', () async {
      viewsController.registerViewType('webview');
      final AndroidViewController viewController = PlatformViewsService.initAndroidView(
        id: 1,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      );
      await viewController.create(size: const Size(200.0, 300.0));
      await viewController.dispose();
      await viewController.dispose();
    });

    test('dispose clears focusCallbacks', () async {
      var didFocus = false;
      viewsController.registerViewType('webview');
      final AndroidViewController viewController = PlatformViewsService.initAndroidView(
        id: 0,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
        onFocus: () {
          didFocus = true;
        },
      );
      await viewController.create(size: const Size(100.0, 100.0));
      await viewController.dispose();
      final ByteData message = SystemChannels.platform_views.codec.encodeMethodCall(
        const MethodCall('viewFocused', 0),
      );
      await binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.platform_views.name,
        message,
        (_) {},
      );
      expect(didFocus, isFalse);
    });

    test('resize Android view', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initAndroidView(
        id: 0,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      ).create(size: const Size(100.0, 100.0));

      final AndroidViewController androidView = PlatformViewsService.initAndroidView(
        id: 1,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      );
      await androidView.create(size: const Size(200.0, 300.0));
      await androidView.setSize(const Size(500.0, 500.0));

      expect(
        viewsController.views,
        unorderedEquals(<FakeAndroidPlatformView>[
          const FakeAndroidPlatformView(
            0,
            'webview',
            Size(100.0, 100.0),
            AndroidViewController.kAndroidLayoutDirectionLtr,
          ),
          const FakeAndroidPlatformView(
            1,
            'webview',
            Size(500.0, 500.0),
            AndroidViewController.kAndroidLayoutDirectionLtr,
          ),
        ]),
      );
    });

    test('OnPlatformViewCreated callback', () async {
      viewsController.registerViewType('webview');
      final createdViews = <int>[];
      void callback(int id) {
        createdViews.add(id);
      }

      final AndroidViewController controller1 = PlatformViewsService.initAndroidView(
        id: 0,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      )..addOnPlatformViewCreatedListener(callback);
      expect(createdViews, isEmpty);

      await controller1.create(size: const Size(100.0, 100.0));
      expect(createdViews, orderedEquals(<int>[0]));

      final AndroidViewController controller2 = PlatformViewsService.initAndroidView(
        id: 5,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      )..addOnPlatformViewCreatedListener(callback);
      expect(createdViews, orderedEquals(<int>[0]));

      await controller2.create(size: const Size(100.0, 200.0));
      expect(createdViews, orderedEquals(<int>[0, 5]));

      final AndroidViewController controller3 = PlatformViewsService.initAndroidView(
        id: 10,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      )..addOnPlatformViewCreatedListener(callback);
      expect(createdViews, orderedEquals(<int>[0, 5]));

      await Future.wait(<Future<void>>[
        controller3.create(size: const Size(100.0, 200.0)),
        controller3.dispose(),
      ]);

      expect(createdViews, orderedEquals(<int>[0, 5]));
    });

    test("change Android view's directionality before creation", () async {
      viewsController.registerViewType('webview');
      final AndroidViewController viewController = PlatformViewsService.initAndroidView(
        id: 0,
        viewType: 'webview',
        layoutDirection: TextDirection.rtl,
      );
      await viewController.setLayoutDirection(TextDirection.ltr);
      await viewController.create(size: const Size(100.0, 100.0));
      expect(
        viewsController.views,
        unorderedEquals(<FakeAndroidPlatformView>[
          const FakeAndroidPlatformView(
            0,
            'webview',
            Size(100.0, 100.0),
            AndroidViewController.kAndroidLayoutDirectionLtr,
          ),
        ]),
      );
    });

    test("change Android view's directionality after creation", () async {
      viewsController.registerViewType('webview');
      final AndroidViewController viewController = PlatformViewsService.initAndroidView(
        id: 0,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      );
      await viewController.setLayoutDirection(TextDirection.rtl);
      await viewController.create(size: const Size(100.0, 100.0));
      expect(
        viewsController.views,
        unorderedEquals(<FakeAndroidPlatformView>[
          const FakeAndroidPlatformView(
            0,
            'webview',
            Size(100.0, 100.0),
            AndroidViewController.kAndroidLayoutDirectionRtl,
          ),
        ]),
      );
    });

    test("set Android view's offset if view is created", () async {
      viewsController.registerViewType('webview');
      final AndroidViewController viewController = PlatformViewsService.initAndroidView(
        id: 7,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      );
      await viewController.create(size: const Size(100.0, 100.0));
      await viewController.setOffset(const Offset(10, 20));
      expect(viewsController.offsets, equals(<int, Offset>{7: const Offset(10, 20)}));
    });

    test("doesn't set Android view's offset if view isn't created", () async {
      viewsController.registerViewType('webview');
      final AndroidViewController viewController = PlatformViewsService.initAndroidView(
        id: 7,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      );
      await viewController.setOffset(const Offset(10, 20));
      expect(viewsController.offsets, equals(<int, Offset>{}));
    });

    testWidgets('motion event converter does not duplicate move events', (
      WidgetTester tester,
    ) async {
      final log = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform_views,
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        },
      );

      final AndroidViewController viewController = PlatformViewsService.initSurfaceAndroidView(
        id: 7,
        viewType: 'web',
        layoutDirection: TextDirection.ltr,
      );
      viewController.pointTransformer = (Offset offset) => offset;

      const pointerCount = 10;
      for (var i = 0; i < pointerCount; i++) {
        final PointerEvent event = PointerDownEvent(
          timeStamp: const Duration(milliseconds: 1),
          pointer: i,
        );
        await viewController.dispatchPointerEvent(event);
      }

      // Pointer event platform data constant from _AndroidMotionEventConverter
      const kPointerDataFlagMultiple = 2;

      for (var i = 0; i < pointerCount; i++) {
        final PointerEvent event = PointerMoveEvent(
          timeStamp: const Duration(milliseconds: 2),
          pointer: i,
          platformData: kPointerDataFlagMultiple | (pointerCount << 8),
        );
        await viewController.dispatchPointerEvent(event);
      }

      // Indexes in the list returned by AndroidMotionEvent._asList
      const kAndroidMotionEventListIndexAction = 3;
      const kAndroidMotionEventListIndexPointerCount = 4;

      final List<MethodCall> moveCalls = log.where((MethodCall call) {
        final args = call.arguments as List<dynamic>;
        return call.method == 'touch' &&
            args[kAndroidMotionEventListIndexAction] == AndroidViewController.kActionMove;
      }).toList();

      // The _AndroidMotionEventConverter should yield one touch event containing all of the pointers.
      expect(moveCalls.length, equals(1));
      final moveArgs = moveCalls.single.arguments as List<dynamic>;
      expect(moveArgs[kAndroidMotionEventListIndexPointerCount], equals(pointerCount));
    });

    // Regression test for https://github.com/flutter/flutter/issues/191105.
    testWidgets('motion event converter orders pointers by Android pointer id', (
      WidgetTester tester,
    ) async {
      final log = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform_views,
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        },
      );

      final AndroidViewController viewController = PlatformViewsService.initSurfaceAndroidView(
        id: 7,
        viewType: 'web',
        layoutDirection: TextDirection.ltr,
      );
      viewController.pointTransformer = (Offset offset) => offset;

      // Indexes in the list returned by AndroidMotionEvent._asList.
      const kIndexAction = 3;
      const kIndexPointerCount = 4;
      const kIndexPointerProperties = 5;
      const kIndexPointerCoords = 6;
      // Index of x within the list returned by AndroidPointerCoords._asList.
      const kCoordsIndexX = 7;

      List<double> xOf(MethodCall call) {
        final args = call.arguments as List<dynamic>;
        return (args[kIndexPointerCoords] as List<dynamic>)
            .map<double>((dynamic coords) => (coords as List<dynamic>)[kCoordsIndexX] as double)
            .toList();
      }

      // Flutter pointer 1 takes Android pointer id 0, Flutter pointer 2 takes id 1.
      await viewController.dispatchPointerEvent(
        const PointerDownEvent(pointer: 1, position: Offset(10, 10)),
      );
      await viewController.dispatchPointerEvent(
        const PointerDownEvent(pointer: 2, position: Offset(20, 20)),
      );
      // Lifting Flutter pointer 1 releases Android pointer id 0 for reuse.
      await viewController.dispatchPointerEvent(
        const PointerUpEvent(pointer: 1, position: Offset(10, 10)),
      );
      log.clear();
      // Flutter pointer 3 is assigned the recycled Android pointer id 0, so it is
      // last in insertion order but first in Android pointer id order.
      await viewController.dispatchPointerEvent(
        const PointerDownEvent(pointer: 3, position: Offset(30, 30)),
      );

      final MethodCall downCall = log.singleWhere((MethodCall call) => call.method == 'touch');
      final downArgs = downCall.arguments as List<dynamic>;
      expect(downArgs[kIndexPointerCount], 2);
      // The action index is the position of the pressed pointer in Android pointer id order.
      expect(
        downArgs[kIndexAction],
        AndroidViewController.pointerAction(0, AndroidViewController.kActionPointerDown),
      );
      expect(
        downArgs[kIndexPointerProperties],
        <List<int>>[
          <int>[0, AndroidPointerProperties.kToolTypeFinger],
          <int>[1, AndroidPointerProperties.kToolTypeFinger],
        ],
      );
      // Android pointer id 0 is Flutter pointer 3, id 1 is Flutter pointer 2.
      expect(xOf(downCall), <double>[30, 20]);

      // The engine splits one Android move across its pointers in Android pointer
      // id order, flagging each with the original pointer count. The converter must
      // send a single MotionEvent once the last of them has arrived.
      const kPointerDataFlagMultiple = 2;
      const int platformData = kPointerDataFlagMultiple | (2 << 8);
      log.clear();
      await viewController.dispatchPointerEvent(
        const PointerMoveEvent(pointer: 3, position: Offset(31, 31), platformData: platformData),
      );
      await viewController.dispatchPointerEvent(
        const PointerMoveEvent(pointer: 2, position: Offset(21, 21), platformData: platformData),
      );

      final MethodCall moveCall = log.singleWhere((MethodCall call) => call.method == 'touch');
      final moveArgs = moveCall.arguments as List<dynamic>;
      expect(moveArgs[kIndexAction], AndroidViewController.kActionMove);
      expect(xOf(moveCall), <double>[31, 21]);
    });
  });

  group('iOS', () {
    late FakeIosPlatformViewsController viewsController;
    setUp(() {
      viewsController = FakeIosPlatformViewsController();
    });

    test('create iOS view of unregistered type', () async {
      expect(() {
        return PlatformViewsService.initUiKitView(
          id: 0,
          viewType: 'web',
          layoutDirection: TextDirection.ltr,
        );
      }, throwsA(isA<PlatformException>()));
    });

    test('create iOS views', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initUiKitView(
        id: 0,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      );
      await PlatformViewsService.initUiKitView(
        id: 1,
        viewType: 'webview',
        layoutDirection: TextDirection.rtl,
      );
      expect(
        viewsController.views,
        unorderedEquals(<FakeUiKitView>[
          const FakeUiKitView(0, 'webview'),
          const FakeUiKitView(1, 'webview'),
        ]),
      );
    });

    test('reuse iOS view id', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initUiKitView(
        id: 0,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      );
      expect(
        () => PlatformViewsService.initUiKitView(
          id: 0,
          viewType: 'web',
          layoutDirection: TextDirection.ltr,
        ),
        throwsA(isA<PlatformException>()),
      );
    });

    test('dispose iOS view', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initUiKitView(
        id: 0,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      );
      final UiKitViewController viewController = await PlatformViewsService.initUiKitView(
        id: 1,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      );

      await viewController.dispose();
      expect(
        viewsController.views,
        unorderedEquals(<FakeUiKitView>[const FakeUiKitView(0, 'webview')]),
      );
    });

    test('dispose inexisting iOS view', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initUiKitView(
        id: 0,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      );
      final UiKitViewController viewController = await PlatformViewsService.initUiKitView(
        id: 1,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      );
      await viewController.dispose();
      expect(() async {
        await viewController.dispose();
      }, throwsA(isA<PlatformException>()));
    });
  });

  test('toString works as intended', () async {
    const androidPointerProperties = AndroidPointerProperties(id: 0, toolType: 0);
    expect(androidPointerProperties.toString(), 'AndroidPointerProperties(id: 0, toolType: 0)');

    const zero = 0.0;
    const androidPointerCoords = AndroidPointerCoords(
      orientation: zero,
      pressure: zero,
      size: zero,
      toolMajor: zero,
      toolMinor: zero,
      touchMajor: zero,
      touchMinor: zero,
      x: zero,
      y: zero,
    );
    expect(
      androidPointerCoords.toString(),
      'AndroidPointerCoords(orientation: $zero, '
      'pressure: $zero, '
      'size: $zero, '
      'toolMajor: $zero, '
      'toolMinor: $zero, '
      'touchMajor: $zero, '
      'touchMinor: $zero, '
      'x: $zero, '
      'y: $zero)',
    );

    final androidMotionEvent = AndroidMotionEvent(
      downTime: 0,
      eventTime: 0,
      action: 0,
      pointerCount: 0,
      pointerProperties: <AndroidPointerProperties>[],
      pointerCoords: <AndroidPointerCoords>[],
      metaState: 0,
      buttonState: 0,
      xPrecision: zero,
      yPrecision: zero,
      deviceId: 0,
      edgeFlags: 0,
      source: 0,
      flags: 0,
      motionEventId: 0,
    );
    expect(
      androidMotionEvent.toString(),
      'AndroidPointerEvent(downTime: 0, '
      'eventTime: 0, '
      'action: 0, '
      'pointerCount: 0, '
      'pointerProperties: [], '
      'pointerCoords: [], '
      'metaState: 0, '
      'buttonState: 0, '
      'xPrecision: $zero, '
      'yPrecision: $zero, '
      'deviceId: 0, '
      'edgeFlags: 0, '
      'source: 0, '
      'flags: 0, '
      'motionEventId: 0)',
    );
  });
}
