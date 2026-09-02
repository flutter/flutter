// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

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

    testWidgets(
      'motion event converter dispatches move events when tracking subset of total pointers',
      (WidgetTester tester) async {
        final log = <MethodCall>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform_views,
          (MethodCall methodCall) async {
            log.add(methodCall);
            return null;
          },
        );

        final AndroidViewController viewController = PlatformViewsService.initSurfaceAndroidView(
          // Arbitrary test view ID.
          id: 8,
          viewType: 'web',
          layoutDirection: TextDirection.ltr,
        );
        viewController.pointTransformer = (Offset offset) => offset;

        // Platform view only tracks pointer 0 (e.g. pointer 1 was outside the platform view).
        await viewController.dispatchPointerEvent(
          // Timestamp for first pointer down.
          const PointerDownEvent(timeStamp: Duration(milliseconds: 1)),
        );

        // Pointer event platform data constant from _AndroidMotionEventConverter.
        const kPointerDataFlagMultiple = 2;
        // Shift for encoding total pointer count into PointerEvent.platformData.
        const kPointerDataMultiplePointerCountShift = 8;
        // Number of pointers present in the underlying Android MotionEvent.
        const totalAndroidPointers = 2;

        // Dispatch a move event for pointer 0 where totalAndroidPointers is 2.
        await viewController.dispatchPointerEvent(
          const PointerMoveEvent(
            // Timestamp for move event.
            timeStamp: Duration(milliseconds: 2),
            platformData:
                kPointerDataFlagMultiple |
                (totalAndroidPointers << kPointerDataMultiplePointerCountShift),
          ),
        );

        // Indexes in the list returned by AndroidMotionEvent._asList.
        const kAndroidMotionEventListIndexAction = 3;
        const kAndroidMotionEventListIndexPointerCount = 4;

        final List<MethodCall> moveCalls = log.where((MethodCall call) {
          final args = call.arguments as List<dynamic>;
          return call.method == 'touch' &&
              args[kAndroidMotionEventListIndexAction] == AndroidViewController.kActionMove;
        }).toList();

        // The _AndroidMotionEventConverter should dispatch the move event for the tracked pointer.
        expect(moveCalls.length, equals(1));
        final moveArgs = moveCalls.single.arguments as List<dynamic>;
        expect(moveArgs[kAndroidMotionEventListIndexPointerCount], equals(1));
      },
    );

    testWidgets('motion event converter multi-pointer lifecycle sequence', (
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
        // Arbitrary test view ID.
        id: 9,
        viewType: 'web',
        layoutDirection: TextDirection.ltr,
      );
      viewController.pointTransformer = (Offset offset) => offset;

      // Pointer event platform data bitmask constants from _AndroidMotionEventConverter.
      const kPointerDataFlagBatched = 1;
      const kPointerDataFlagMultiple = 2;
      // Shift for encoding total pointer count into PointerEvent.platformData.
      const kPointerDataMultiplePointerCountShift = 8;
      // Total pointers present in the underlying Android MotionEvent.
      const totalAndroidPointersTwo = 2;
      const totalAndroidPointersOne = 1;

      // 1. Pointer 0 Down
      await viewController.dispatchPointerEvent(
        // Primary touch down timestamp.
        const PointerDownEvent(timeStamp: Duration(milliseconds: 1)),
      );

      // 2. Pointer 1 Down (secondary pointer down)
      await viewController.dispatchPointerEvent(
        // Secondary touch down timestamp and pointer ID.
        const PointerDownEvent(timeStamp: Duration(milliseconds: 2), pointer: 1),
      );

      // 3. Batched move for pointers 0 and 1
      await viewController.dispatchPointerEvent(
        const PointerMoveEvent(
          // Move event timestamp for pointer 0.
          timeStamp: Duration(milliseconds: 3),
          platformData: kPointerDataFlagBatched,
        ),
      );
      await viewController.dispatchPointerEvent(
        const PointerMoveEvent(
          // Move event timestamp for pointer 1.
          timeStamp: Duration(milliseconds: 3),
          pointer: 1,
          platformData:
              kPointerDataFlagMultiple |
              (totalAndroidPointersTwo << kPointerDataMultiplePointerCountShift),
        ),
      );

      // 4. Pointer 1 Up (pointer index 1 lifted)
      await viewController.dispatchPointerEvent(
        // Pointer 1 up timestamp and pointer ID.
        const PointerUpEvent(timeStamp: Duration(milliseconds: 4), pointer: 1),
      );

      // 5. Move for remaining pointer 0
      await viewController.dispatchPointerEvent(
        const PointerMoveEvent(
          // Move event timestamp for pointer 0.
          timeStamp: Duration(milliseconds: 5),
          platformData:
              kPointerDataFlagMultiple |
              (totalAndroidPointersOne << kPointerDataMultiplePointerCountShift),
        ),
      );

      // 6. Pointer 0 Up (last pointer lifted)
      await viewController.dispatchPointerEvent(
        // Final pointer up timestamp.
        const PointerUpEvent(timeStamp: Duration(milliseconds: 6)),
      );

      // Indexes in the list returned by AndroidMotionEvent._asList.
      const kAndroidMotionEventListIndexAction = 3;
      const kAndroidMotionEventListIndexPointerCount = 4;

      final List<int> actions = log.map((MethodCall call) {
        final args = call.arguments as List<dynamic>;
        return args[kAndroidMotionEventListIndexAction] as int;
      }).toList();

      final List<int> pointerCounts = log.map((MethodCall call) {
        final args = call.arguments as List<dynamic>;
        return args[kAndroidMotionEventListIndexPointerCount] as int;
      }).toList();

      expect(
        actions,
        equals(<int>[
          AndroidViewController.kActionDown,
          AndroidViewController.pointerAction(1, AndroidViewController.kActionPointerDown),
          AndroidViewController.kActionMove,
          AndroidViewController.pointerAction(1, AndroidViewController.kActionPointerUp),
          AndroidViewController.kActionMove,
          AndroidViewController.kActionUp,
        ]),
      );
      expect(pointerCounts, equals(<int>[1, 2, 2, 2, 1, 1]));
    });

    testWidgets('motion event converter handles pointer cancel', (WidgetTester tester) async {
      final log = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform_views,
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        },
      );

      final AndroidViewController viewController = PlatformViewsService.initSurfaceAndroidView(
        // Arbitrary test view ID.
        id: 10,
        viewType: 'web',
        layoutDirection: TextDirection.ltr,
      );
      viewController.pointTransformer = (Offset offset) => offset;

      const kPointerDataFlagMultiple = 2;
      const kPointerDataMultiplePointerCountShift = 8;
      // Total pointers present in the underlying Android MotionEvent.
      const totalAndroidPointersOne = 1;

      // Down on pointer 0
      await viewController.dispatchPointerEvent(
        // Primary touch down timestamp.
        const PointerDownEvent(timeStamp: Duration(milliseconds: 1)),
      );

      // Down on pointer 1
      await viewController.dispatchPointerEvent(
        // Secondary touch down timestamp and pointer ID.
        const PointerDownEvent(timeStamp: Duration(milliseconds: 2), pointer: 1),
      );

      // Cancel pointer 0
      await viewController.dispatchPointerEvent(
        // Cancel timestamp.
        const PointerCancelEvent(timeStamp: Duration(milliseconds: 3)),
      );

      // Move on pointer 1 (now 1 tracked pointer)
      await viewController.dispatchPointerEvent(
        const PointerMoveEvent(
          // Move timestamp.
          timeStamp: Duration(milliseconds: 4),
          pointer: 1,
          platformData:
              kPointerDataFlagMultiple |
              (totalAndroidPointersOne << kPointerDataMultiplePointerCountShift),
        ),
      );

      const kAndroidMotionEventListIndexAction = 3;
      const kAndroidMotionEventListIndexPointerCount = 4;

      final List<int> actions = log.map((MethodCall call) {
        final args = call.arguments as List<dynamic>;
        return args[kAndroidMotionEventListIndexAction] as int;
      }).toList();

      final List<int> pointerCounts = log.map((MethodCall call) {
        final args = call.arguments as List<dynamic>;
        return args[kAndroidMotionEventListIndexPointerCount] as int;
      }).toList();

      expect(
        actions,
        equals(<int>[
          AndroidViewController.kActionDown,
          AndroidViewController.pointerAction(1, AndroidViewController.kActionPointerDown),
          AndroidViewController.kActionCancel,
          AndroidViewController.kActionMove,
        ]),
      );
      expect(pointerCounts, equals(<int>[1, 2, 2, 1]));
    });

    testWidgets('motion event converter full recorded replay sequence', (
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
        // Arbitrary test view ID.
        id: 11,
        viewType: 'web',
        layoutDirection: TextDirection.ltr,
      );
      viewController.pointTransformer = (Offset offset) => offset;

      var file = File(
        'dev/integration_tests/android_views/build/app/intermediates/flutter/debug/flutter_assets/packages/assets_for_android_views/assets/touchEvents',
      );
      if (!file.existsSync()) {
        file = File(
          '../../dev/integration_tests/android_views/build/app/intermediates/flutter/debug/flutter_assets/packages/assets_for_android_views/assets/touchEvents',
        );
      }
      final Uint8List bytes = file.readAsBytesSync();
      const codec = StandardMessageCodec();
      final unTyped = codec.decodeMessage(ByteData.sublistView(bytes))! as List<dynamic>;
      final List<Map<String, dynamic>> recordedEvents = unTyped
          .cast<Map<dynamic, dynamic>>()
          .map<Map<String, dynamic>>((Map<dynamic, dynamic> e) => e.cast<String, dynamic>())
          .toList();

      // Pointer event platform data bitmask constants from _AndroidMotionEventConverter.
      const kPointerDataFlagBatched = 1;
      const kPointerDataFlagMultiple = 2;
      const kPointerDataMultiplePointerCountShift = 8;

      final androidPointerToDartPointer = <int, int>{};
      var nextPointerId = 0;

      for (final Map<String, dynamic> event in recordedEvents.reversed) {
        final action = event['action'] as int;
        final int maskedAction = action & 0xff;
        final int actionIndex = (action >> 8) & 0xff;
        final dynamic rawProps = event['pointerProperties'];
        final List<dynamic> props = rawProps is List<dynamic>
            ? rawProps
            : (rawProps as Map<dynamic, dynamic>).values.toList();
        final int pointerCount = props.length;
        final eventTime = event['eventTime'] as int;

        final bool updateForSinglePointer =
            maskedAction == 0 || maskedAction == 5; // DOWN, POINTER_DOWN
        final bool updateForMultiplePointers =
            !updateForSinglePointer && (maskedAction == 1 || maskedAction == 6); // UP, POINTER_UP

        int getAndroidId(dynamic prop) =>
            prop is List ? (prop[0] as int) : (prop as Map<dynamic, dynamic>)['id'] as int;

        if (updateForSinglePointer) {
          final int androidId = getAndroidId(props[actionIndex]);
          final int dartPointer = androidPointerToDartPointer.putIfAbsent(
            androidId,
            () => nextPointerId++,
          );
          await viewController.dispatchPointerEvent(
            PointerDownEvent(
              pointer: dartPointer,
              timeStamp: Duration(milliseconds: eventTime),
            ),
          );
        } else if (updateForMultiplePointers) {
          for (var p = 0; p < pointerCount; p++) {
            final int androidId = getAndroidId(props[p]);
            final int dartPointer = androidPointerToDartPointer[androidId]!;
            if (p != actionIndex) {
              await viewController.dispatchPointerEvent(
                PointerMoveEvent(
                  pointer: dartPointer,
                  timeStamp: Duration(milliseconds: eventTime),
                  platformData: kPointerDataFlagBatched,
                ),
              );
            }
          }
          final int androidId = getAndroidId(props[actionIndex]);
          final int dartPointer = androidPointerToDartPointer[androidId]!;
          await viewController.dispatchPointerEvent(
            PointerUpEvent(
              pointer: dartPointer,
              timeStamp: Duration(milliseconds: eventTime),
            ),
          );
          androidPointerToDartPointer.remove(androidId);
        } else {
          // ACTION_MOVE
          for (var p = 0; p < pointerCount; p++) {
            final int androidId = getAndroidId(props[p]);
            final int dartPointer = androidPointerToDartPointer[androidId]!;
            await viewController.dispatchPointerEvent(
              PointerMoveEvent(
                pointer: dartPointer,
                timeStamp: Duration(milliseconds: eventTime),
                platformData:
                    kPointerDataFlagMultiple |
                    (pointerCount << kPointerDataMultiplePointerCountShift),
              ),
            );
          }
        }
      }

      expect(log.length, equals(recordedEvents.length));
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
