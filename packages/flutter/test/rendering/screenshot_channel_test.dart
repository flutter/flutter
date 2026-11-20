// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

Future<Map<Object?, Object?>?> _invokeCaptureView([Object? arguments]) async {
  const codec = StandardMethodCodec();
  final ByteData callData = codec.encodeMethodCall(MethodCall('Screenshot.captureView', arguments));
  final ByteData? replyData = await TestDefaultBinaryMessengerBinding
      .instance
      .defaultBinaryMessenger
      .handlePlatformMessage('flutter/screenshot', callData, (ByteData? data) {});
  if (replyData == null) {
    return null;
  }
  return codec.decodeEnvelope(replyData) as Map<Object?, Object?>?;
}

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test('SystemChannels.screenshot captures implicit RenderView with viewId 0 and null', () async {
    final coloredBox = RenderDecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFFF0000)),
      child: RenderConstrainedBox(additionalConstraints: const BoxConstraints.expand()),
    );
    layout(coloredBox, phase: EnginePhase.composite);

    final int implicitViewId = RendererBinding.instance.renderViews.first.flutterView.viewId;
    for (final arg in <Object?>[implicitViewId, null]) {
      final Map<Object?, Object?>? response = await _invokeCaptureView(arg);
      expect(response, isNotNull);
      final width = response!['width']! as int;
      final height = response['height']! as int;
      final bytes = response['bytes']! as Uint8List;

      expect(width, greaterThan(0));
      expect(height, greaterThan(0));
      expect(bytes.length, equals(width * height * 4));

      // Verify top-left pixel is solid red (RGBA: 0xFF, 0x00, 0x00, 0xFF).
      expect(bytes[0], equals(0xFF));
      expect(bytes[1], equals(0x00));
      expect(bytes[2], equals(0x00));
      expect(bytes[3], equals(0xFF));
    }
  });

  test('SystemChannels.screenshot waits for endOfFrame when a frame is scheduled', () async {
    final coloredBox = RenderDecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF0000FF)),
      child: RenderConstrainedBox(additionalConstraints: const BoxConstraints.expand()),
    );
    layout(coloredBox, phase: EnginePhase.composite);

    // Update the decoration to green and schedule a frame without pumping yet.
    coloredBox.decoration = const BoxDecoration(color: Color(0xFF00FF00));
    RendererBinding.instance.scheduleFrame();
    expect(RendererBinding.instance.hasScheduledFrame, isTrue);

    var captureCompleted = false;
    final Future<Map<Object?, Object?>?> captureFuture = _invokeCaptureView().then((
      Map<Object?, Object?>? result,
    ) {
      captureCompleted = true;
      return result;
    });

    // Pump microtasks; capture should still be waiting for endOfFrame.
    await Future<void>.delayed(Duration.zero);
    expect(captureCompleted, isFalse);

    // Pump the scheduled frame so endOfFrame completes.
    pumpFrame(phase: EnginePhase.composite);
    final Map<Object?, Object?>? response = await captureFuture;
    expect(captureCompleted, isTrue);
    expect(response, isNotNull);

    final bytes = response!['bytes']! as Uint8List;
    // Verify top-left pixel reflects the updated green decoration (RGBA: 0x00, 0xFF, 0x00, 0xFF).
    expect(bytes[0], equals(0x00));
    expect(bytes[1], equals(0xFF));
    expect(bytes[2], equals(0x00));
    expect(bytes[3], equals(0xFF));
  });

  test('SystemChannels.screenshot returns null for unknown viewId', () async {
    final coloredBox = RenderDecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFFF0000)),
      child: RenderConstrainedBox(additionalConstraints: const BoxConstraints.expand()),
    );
    layout(coloredBox, phase: EnginePhase.composite);

    final Map<Object?, Object?>? response = await _invokeCaptureView(999999);
    expect(response, isNull);
  });
}
