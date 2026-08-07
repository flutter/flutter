// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// This file is for testings that require a `LiveTestWidgetsFlutterBinding`
void main() {
  final binding = LiveTestWidgetsFlutterBinding();

  test('showTestPointerCrosshairs defaults to true', () {
    expect(binding.showTestPointerCrosshairs, isTrue);
  });

  testWidgets('showTestPointerCrosshairs hides crosshairs without blocking pointer events', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      binding.showTestPointerCrosshairs = true;
    });

    var tapCount = 0;
    await tester.pumpWidget(
      buildTestApp(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            tapCount += 1;
          },
          child: const ColoredBox(
            key: ValueKey<String>('crosshair-target'),
            color: Color(0xFFFFFFFF),
            child: SizedBox(width: 100, height: 100),
          ),
        ),
      ),
    );

    final Offset position = tester.getCenter(
      find.byKey(const ValueKey<String>('crosshair-target')),
    );

    binding.showTestPointerCrosshairs = false;
    final TestGesture hiddenGesture = await tester.startGesture(position);
    await tester.pump();
    final ui.Image imageWithoutCrosshair = await _captureRenderView(binding);

    await hiddenGesture.up();
    await tester.pump();
    expect(tapCount, 1);

    binding.showTestPointerCrosshairs = true;
    final TestGesture visibleGesture = await tester.startGesture(position);
    await tester.pump();
    final ui.Image imageWithCrosshair = await _captureRenderView(binding);

    binding.showTestPointerCrosshairs = false;
    await tester.pump();
    final ui.Image imageAfterDisablingCrosshair = await _captureRenderView(binding);

    expect(
      await _colorAtLogicalPosition(imageWithoutCrosshair, binding.renderView, position),
      const Color(0xFFFFFFFF),
    );
    expect(
      await _colorAtLogicalPosition(imageWithCrosshair, binding.renderView, position),
      isNot(const Color(0xFFFFFFFF)),
    );
    expect(
      await _colorAtLogicalPosition(imageAfterDisablingCrosshair, binding.renderView, position),
      const Color(0xFFFFFFFF),
    );

    imageWithoutCrosshair.dispose();
    imageWithCrosshair.dispose();
    imageAfterDisablingCrosshair.dispose();
    await visibleGesture.up();
    await tester.pump();
    expect(tapCount, 2);
  });

  testWidgets('Input PointerAddedEvent', (WidgetTester tester) async {
    await tester.pumpWidget(const TestWidgetsApp(home: Text('Test')));
    await tester.pump();
    final TestGesture gesture = await tester.createGesture();
    // This mimics the start of a gesture as seen on a device, where inputs
    // starts with a PointerAddedEvent.
    await gesture.addPointer();
    // The expected result of the test is not to trigger any assert.
  });

  testWidgets('Input PointerHoverEvent', (WidgetTester tester) async {
    PointerHoverEvent? hoverEvent;
    await tester.pumpWidget(
      TestWidgetsApp(
        home: MouseRegion(
          child: const Text('Test'),
          onHover: (PointerHoverEvent event) {
            hoverEvent = event;
          },
        ),
      ),
    );
    await tester.pump();
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    final Offset location = tester.getCenter(find.text('Test'));
    // for mouse input without a down event, moveTo generates a hover event
    await gesture.moveTo(location);
    expect(hoverEvent, isNotNull);
    expect(hoverEvent!.position, location);
  });

  testWidgets('hitTesting works when using setSurfaceSize', (WidgetTester tester) async {
    var invocations = 0;
    await tester.pumpWidget(
      TestWidgetsApp(
        home: GestureDetector(
          onTap: () {
            invocations++;
          },
          child: const Text('Test'),
        ),
      ),
    );

    await tester.tap(find.byType(Text));
    await tester.pump();
    expect(invocations, 1);

    await tester.binding.setSurfaceSize(const Size(200, 300));
    await tester.pump();
    await tester.tap(find.byType(Text));
    await tester.pump();
    expect(invocations, 2);

    await tester.binding.setSurfaceSize(null);
    await tester.pump();
    await tester.tap(find.byType(Text));
    await tester.pump();
    expect(invocations, 3);
  });

  testWidgets('setSurfaceSize works', (WidgetTester tester) async {
    addTearDown(binding.resetLayers);
    await tester.pumpWidget(const TestWidgetsApp(home: Center(child: Text('Test'))));

    final Size windowCenter = tester.view.physicalSize / tester.view.devicePixelRatio / 2;
    final double windowCenterX = windowCenter.width;
    final double windowCenterY = windowCenter.height;

    Offset widgetCenter = tester.getRect(find.byType(Text)).center;
    expect(widgetCenter.dx, windowCenterX);
    expect(widgetCenter.dy, windowCenterY);

    await tester.binding.setSurfaceSize(const Size(200, 300));
    await tester.pump();
    widgetCenter = tester.getRect(find.byType(Text)).center;
    expect(widgetCenter.dx, 100);
    expect(widgetCenter.dy, 150);

    await tester.binding.setSurfaceSize(null);
    await tester.pump();
    widgetCenter = tester.getRect(find.byType(Text)).center;
    expect(widgetCenter.dx, windowCenterX);
    expect(widgetCenter.dy, windowCenterY);
  });

  testWidgets("reassembleApplication doesn't get stuck", (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/79150

    await expectLater(tester.binding.reassembleApplication(), completes);
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets(
    'shouldPropagateDevicePointerEvents can override events from ${TestBindingEventSource.device}',
    (WidgetTester tester) async {
      binding.shouldPropagateDevicePointerEvents = true;

      await tester.pumpWidget(_ShowNumTaps());

      final Offset position = tester.getCenter(find.text('0'));

      // Simulates a real device tap.
      //
      // `handlePointerEventForSource defaults to sending events using
      // TestBindingEventSource.device. This will not be forwarded to the actual
      // gesture handlers, unless `shouldPropagateDevicePointerEvents` is true.
      binding.handlePointerEventForSource(PointerDownEvent(position: position));
      binding.handlePointerEventForSource(PointerUpEvent(position: position));

      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      // Reset the value, otherwise the test will fail when it checks that this
      // has not been changed as an invariant.
      binding.shouldPropagateDevicePointerEvents = false;
    },
  );

  testWidgets('resetLayers resets configuration and replaces root layer', (
    WidgetTester tester,
  ) async {
    // Ensure cleanup. This statement is not part of the test.
    addTearDown(binding.resetLayers);

    final ViewConfiguration currentConfig = binding.renderView.configuration;
    await binding.setSurfaceSize(const Size(400, 400));
    binding.renderView.configuration = const ViewConfiguration(devicePixelRatio: 10.0);
    final Layer? currentRootLayer = binding.renderView.debugLayer;

    await binding.resetLayers(); // This statement is the testee.

    // Verify that all properties have been reset
    expect(
      binding.renderView.configuration.logicalConstraints,
      equals(currentConfig.logicalConstraints),
    );
    expect(
      binding.renderView.configuration.physicalConstraints,
      equals(currentConfig.physicalConstraints),
    );
    expect(
      binding.renderView.configuration.devicePixelRatio,
      equals(currentConfig.devicePixelRatio),
    );
    // Verify that root layer has been replaced
    expect(binding.renderView.debugLayer, isNot(same(currentRootLayer)));
  });
}

Future<ui.Image> _captureRenderView(LiveTestWidgetsFlutterBinding binding) async {
  final RenderView renderView = binding.renderView;
  final layer = renderView.debugLayer! as OffsetLayer;
  final ui.Image? image = await binding.runAsync<ui.Image>(
    () => layer.toImage(renderView.paintBounds),
  );
  return image!;
}

Future<Color> _colorAtLogicalPosition(
  ui.Image image,
  RenderView renderView,
  Offset position,
) async {
  final ByteData data = (await image.toByteData())!;
  final double scaleX = image.width / renderView.size.width;
  final double scaleY = image.height / renderView.size.height;
  final int x = (position.dx * scaleX).round().clamp(0, image.width - 1);
  final int y = (position.dy * scaleY).round().clamp(0, image.height - 1);
  final int offset = (y * image.width + x) * 4;
  return Color.fromARGB(
    data.getUint8(offset + 3),
    data.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
  );
}

/// A widget that shows the number of times it has been tapped.
class _ShowNumTaps extends StatefulWidget {
  @override
  _ShowNumTapsState createState() => _ShowNumTapsState();
}

class _ShowNumTapsState extends State<_ShowNumTaps> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _counter++;
        });
      },
      child: Directionality(textDirection: TextDirection.ltr, child: Text(_counter.toString())),
    );
  }
}
