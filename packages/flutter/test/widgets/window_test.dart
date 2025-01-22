// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Object?>? Function(MethodCall)? _createWindowMethodCallHandler(WidgetTester tester) {
  return (MethodCall call) async {
    final Map<Object?, Object?> args = call.arguments as Map<Object?, Object?>;
    if (call.method == 'createWindow') {
      final List<Object?> size = args['size']! as List<Object?>;
      final String state = args['state'] as String? ?? WindowState.restored.toString();

      return <String, Object?>{'viewId': tester.view.viewId, 'size': size, 'state': state};
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
      _createWindowMethodCallHandler(tester),
    );

    final RegularWindowController controller = RegularWindowController(size: windowSize);
    await tester.pumpWidget(
      wrapWithView: false,
      Builder(
        builder: (BuildContext context) {
          return WindowingApp(
            children: <Widget>[RegularWindow(controller: controller, child: Container())],
          );
        },
      ),
    );

    await tester.pump();

    expect(controller.type, WindowArchetype.regular);
    expect(controller.size, windowSize);
    expect(controller.view!.viewId, tester.view.viewId);
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
      _createWindowMethodCallHandler(tester),
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
          return WindowingApp(
            children: <Widget>[RegularWindow(controller: controller, child: Container())],
          );
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
        _createWindowMethodCallHandler(tester),
      );

      final RegularWindowController controller = RegularWindowController(size: initialSize);
      await tester.pumpWidget(
        wrapWithView: false,
        Builder(
          builder: (BuildContext context) {
            return WindowingApp(
              children: <Widget>[RegularWindow(controller: controller, child: Container())],
            );
          },
        ),
      );

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
}
