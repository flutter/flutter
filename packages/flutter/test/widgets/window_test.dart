// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Object?>? Function(MethodCall)? _createWindowMethodCallHandler({
<<<<<<< HEAD
  void Function(MethodCall)? onMethodCall,
  required WidgetTester tester,
=======
  required WidgetTester tester,
  void Function(MethodCall)? onMethodCall,
>>>>>>> regular-windows-modify
}) {
  return (MethodCall call) async {
    onMethodCall?.call(call);
    final Map<Object?, Object?> args = call.arguments as Map<Object?, Object?>;
    if (call.method == 'createWindow') {
      final List<Object?> size = args['size']! as List<Object?>;
      final String state = args['state'] as String? ?? WindowState.restored.toString();

      return <String, Object?>{'viewId': tester.view.viewId, 'size': size, 'state': state};
<<<<<<< HEAD
    } else if (call.method == 'createPopup') {
      final int parent = args['parent']! as int;
      final List<Object?> size = args['size']! as List<Object?>;

      return <String, Object?>{'viewId': tester.view.viewId, 'size': size, 'parentViewId': parent};
=======
    } else if (call.method == 'modifyRegular') {
      return null;
>>>>>>> regular-windows-modify
    } else if (call.method == 'destroyWindow') {
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.windowing.name,
        SystemChannels.windowing.codec.encodeMethodCall(
          MethodCall('onWindowDestroyed', <String, Object?>{'viewId': tester.view.viewId}),
        ),
        (ByteData? data) {},
      );

      return null;
    }

    throw Exception('Unsupported method call: ${call.method}');
  };
}

void main() {
  testWidgets('RegularWindow widget populates the controller with proper values', (
    WidgetTester tester,
  ) async {
    const Size windowSize = Size(800, 600);

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.windowing,
      _createWindowMethodCallHandler(tester: tester),
    );

    final RegularWindowController controller = RegularWindowController(size: windowSize);

    await tester.pump();

    expect(controller.type, WindowArchetype.regular);
    expect(controller.size, windowSize);
    expect(controller.rootView.viewId, tester.view.viewId);
  });

  testWidgets('RegularWindow.onError is called when creation throws an error', (
    WidgetTester tester,
  ) async {
    const Size windowSize = Size(800, 600);

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.windowing, (
      MethodCall call,
    ) async {
      throw Exception('Failed to create the window');
    });

    bool receivedError = false;
    final RegularWindowController controller = RegularWindowController(
      onError: (String error) {
        receivedError = true;
      },
      size: windowSize,
    );

    await tester.pump();

    expect(receivedError, true);
  });

  testWidgets('RegularWindowController.destroy results in the RegularWindow.onDestroyed callback', (
    WidgetTester tester,
  ) async {
    const Size windowSize = Size(800, 600);

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.windowing,
      _createWindowMethodCallHandler(tester: tester),
    );

    bool destroyed = false;
    final RegularWindowController controller = RegularWindowController(
      size: windowSize,
      onDestroyed: () {
        destroyed = true;
      },
    );
    await tester.pumpWidget(
      wrapWithView: false,
      Builder(
        builder: (BuildContext context) {
          return RegularWindow(controller: controller, child: Container());
        },
      ),
    );

    await tester.pump();
    await controller.destroy();

    await tester.pump();
    expect(destroyed, true);
  });

  testWidgets(
    'RegularWindowController.size is updated when an onWindowChanged event is triggered on the channel',
    (WidgetTester tester) async {
      const Size initialSize = Size(800, 600);
      const Size newSize = Size(400, 300);

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.windowing,
        _createWindowMethodCallHandler(tester: tester),
      );

      final RegularWindowController controller = RegularWindowController(size: initialSize);
      await tester.pump();

      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.windowing.name,
        SystemChannels.windowing.codec.encodeMethodCall(
          MethodCall('onWindowChanged', <String, Object?>{
            'viewId': tester.view.viewId,
            'size': <double>[newSize.width, newSize.height],
          }),
        ),
        (ByteData? data) {},
      );
      await tester.pump();

      expect(controller.size, newSize);
    },
  );

<<<<<<< HEAD
  testWidgets('PopupWindow widget can specify anchorRect', (WidgetTester tester) async {
    const Size childWindow = Size(400, 300);

    bool called = false;
=======
  testWidgets('RegularWindowController.modify can be called when provided with a "size" argument', (
    WidgetTester tester,
  ) async {
    const Size initialSize = Size(800, 600);
    const Size newSize = Size(400, 300);

    bool wasCalled = false;
>>>>>>> regular-windows-modify
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.windowing,
      _createWindowMethodCallHandler(
        tester: tester,
        onMethodCall: (MethodCall call) {
<<<<<<< HEAD
          final Map<Object?, Object?> args = call.arguments as Map<Object?, Object?>;
          if (call.method == 'createPopup') {
            final List<Object?>? anchorRect = args['anchorRect'] as List<Object?>?;
            expect(anchorRect, <Object?>[0, 0, 100, 100]);
            called = true;
          }
=======
          if (call.method != 'modifyRegular') {
            return;
          }

          final Map<Object?, Object?> args = call.arguments as Map<Object?, Object?>;
          final int viewId = args['viewId']! as int;
          final List<Object?>? size = args['size'] as List<Object?>?;
          final String? title = args['title'] as String?;
          final String? state = args['state'] as String?;
          expect(viewId, tester.view.viewId);
          expect(size, <double>[newSize.width, newSize.height]);
          expect(title, null);
          expect(state, null);
          wasCalled = true;
>>>>>>> regular-windows-modify
        },
      ),
    );

<<<<<<< HEAD
    final PopupWindowController controller = PopupWindowController(
      parent: tester.binding.window,
      size: childWindow,
      anchorRect: const Rect.fromLTWH(0, 0, 100, 100),
    );

    await tester.pump();

    expect(called, true);
  });

  testWidgets('PopupWindow widget can specify positioner', (WidgetTester tester) async {
    const Size childWindow = Size(400, 300);
    const Set<WindowPositionerConstraintAdjustment> constraintAdjustment =
        <WindowPositionerConstraintAdjustment>{
          WindowPositionerConstraintAdjustment.flipX,
          WindowPositionerConstraintAdjustment.resizeX,
        };

    bool called = false;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.windowing,
      _createWindowMethodCallHandler(
        tester: tester,
        onMethodCall: (MethodCall call) {
          final Map<Object?, Object?> args = call.arguments as Map<Object?, Object?>;
          if (call.method == 'createPopup') {
            final int positionerParentAnchor = args['positionerParentAnchor']! as int;
            final int positionerChildAnchor = args['positionerChildAnchor']! as int;
            final List<Object?> positionerOffset = args['positionerOffset']! as List<Object?>;

            final int positionerConstraintAdjustment =
                args['positionerConstraintAdjustment']! as int;

            expect(positionerParentAnchor, WindowPositionerAnchor.left.index);
            expect(positionerChildAnchor, WindowPositionerAnchor.left.index);
            expect(positionerOffset, <Object?>[100, 100]);

            int constraintAdjustmentBitmask = 0;
            for (final WindowPositionerConstraintAdjustment adjustment in constraintAdjustment) {
              constraintAdjustmentBitmask |= 1 << adjustment.index;
            }
            expect(positionerConstraintAdjustment, constraintAdjustmentBitmask);
            called = true;
          }
        },
      ),
    );

    final PopupWindowController controller = PopupWindowController(
      parent: tester.binding.window,
      size: childWindow,
      positioner: const WindowPositioner(
        parentAnchor: WindowPositionerAnchor.left,
        childAnchor: WindowPositionerAnchor.left,
        offset: Offset(100, 100),
        constraintAdjustment: constraintAdjustment,
      ),
    );

    await tester.pump();

    expect(called, true);
=======
    final RegularWindowController controller = RegularWindowController(size: initialSize);
    await tester.pump();

    await controller.modify(size: newSize);
    await tester.pump();

    expect(wasCalled, true);
  });

  testWidgets(
    'RegularWindowController.modify can be called when provided with a "title" argument',
    (WidgetTester tester) async {
      const Size initialSize = Size(800, 600);
      const String newTitle = 'New Title';

      bool wasCalled = false;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.windowing,
        _createWindowMethodCallHandler(
          tester: tester,
          onMethodCall: (MethodCall call) {
            if (call.method != 'modifyRegular') {
              return;
            }

            final Map<Object?, Object?> args = call.arguments as Map<Object?, Object?>;
            final int viewId = args['viewId']! as int;
            final List<Object?>? size = args['size'] as List<Object?>?;
            final String? title = args['title'] as String?;
            final String? state = args['state'] as String?;
            expect(viewId, tester.view.viewId);
            expect(size, null);
            expect(title, newTitle);
            expect(state, null);
            wasCalled = true;
          },
        ),
      );

      final RegularWindowController controller = RegularWindowController(size: initialSize);
      await tester.pump();

      await controller.modify(title: newTitle);
      await tester.pump();

      expect(wasCalled, true);
    },
  );

  testWidgets(
    'RegularWindowController.modify can be called when provided with a "state" argument',
    (WidgetTester tester) async {
      const Size initialSize = Size(800, 600);
      const WindowState newState = WindowState.minimized;

      bool wasCalled = false;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.windowing,
        _createWindowMethodCallHandler(
          tester: tester,
          onMethodCall: (MethodCall call) {
            if (call.method != 'modifyRegular') {
              return;
            }

            final Map<Object?, Object?> args = call.arguments as Map<Object?, Object?>;
            final int viewId = args['viewId']! as int;
            final List<Object?>? size = args['size'] as List<Object?>?;
            final String? title = args['title'] as String?;
            final String? state = args['state'] as String?;
            expect(viewId, tester.view.viewId);
            expect(size, null);
            expect(title, null);
            expect(state, newState.toString());
            wasCalled = true;
          },
        ),
      );

      final RegularWindowController controller = RegularWindowController(size: initialSize);
      await tester.pump();

      await controller.modify(state: newState);
      await tester.pump();

      expect(wasCalled, true);
    },
  );

  testWidgets('RegularWindowController.modify throws when no arguments are provided', (
    WidgetTester tester,
  ) async {
    const Size initialSize = Size(800, 600);
    const WindowState newState = WindowState.minimized;

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.windowing,
      _createWindowMethodCallHandler(tester: tester),
    );

    final RegularWindowController controller = RegularWindowController(size: initialSize);
    await tester.pump();

    expect(() async => controller.modify(), throwsA(isA<AssertionError>()));
>>>>>>> regular-windows-modify
  });
}
