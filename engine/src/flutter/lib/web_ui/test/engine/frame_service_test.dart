// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('FrameService', () {
    void resetFrameService() {
      // Emulate a hot restart to clear listeners from previous tests.
      debugEmulateHotRestart();

      FrameService.debugOverrideFrameService(null);
      expect(FrameService.instance.runtimeType, FrameService);
      EnginePlatformDispatcher.instance.onBeginFrame = null;
      EnginePlatformDispatcher.instance.onDrawFrame = null;
    }

    setUp(resetFrameService);
    tearDownAll(resetFrameService);

    test('instance is valid and can be overridden', () {
      final FrameService defaultInstance = FrameService.instance;
      expect(defaultInstance.runtimeType, FrameService);

      FrameService.debugOverrideFrameService(DummyFrameService());
      expect(FrameService.instance.runtimeType, DummyFrameService);

      FrameService.debugOverrideFrameService(null);
      expect(FrameService.instance.runtimeType, FrameService);
    });

    test('counts frames', () async {
      final FrameService instance = FrameService.instance;
      instance.debugResetFrameData();

      final frameCompleter = Completer<void>();
      instance.onFinishedRenderingFrame = () {
        frameCompleter.complete();
      };

      expect(instance.frameData.frameNumber, 0);
      instance.scheduleFrame();
      await frameCompleter.future;
      expect(instance.frameData.frameNumber, 1);
    });

    test('isFrameScheduled is true if the frame is scheduled', () async {
      final FrameService instance = FrameService.instance;
      instance.debugResetFrameData();

      var frameCompleter = Completer<void>();
      instance.onFinishedRenderingFrame = () {
        frameCompleter.complete();
      };

      // Normal case: pump one frame
      expect(instance.isFrameScheduled, isFalse);
      instance.scheduleFrame();
      expect(instance.isFrameScheduled, isTrue);
      await frameCompleter.future;
      expect(instance.isFrameScheduled, isFalse);
      expect(instance.frameData.frameNumber, 1);

      // Test idempotency
      instance.debugResetFrameData();
      frameCompleter = Completer<void>();
      instance.scheduleFrame();
      instance.scheduleFrame();
      instance.scheduleFrame();
      instance.scheduleFrame();

      expect(instance.isFrameScheduled, isTrue);
      await frameCompleter.future;
      expect(instance.isFrameScheduled, isFalse);
      expect(instance.frameData.frameNumber, 1);
    });

    test('onBeginFrame and onDrawFrame are called with isRenderingFrame set to true', () async {
      final FrameService instance = FrameService.instance;

      bool? isRenderingInOnBeginFrame;
      EnginePlatformDispatcher.instance.onBeginFrame = (_) {
        isRenderingInOnBeginFrame = instance.isRenderingFrame;
      };

      bool? isRenderingInOnDrawFrame;
      EnginePlatformDispatcher.instance.onDrawFrame = () {
        isRenderingInOnDrawFrame = instance.isRenderingFrame;
      };

      final frameCompleter = Completer<void>();
      bool? valueInOnFinishedRenderingFrame;
      instance.onFinishedRenderingFrame = () {
        valueInOnFinishedRenderingFrame = instance.isRenderingFrame;
        frameCompleter.complete();
      };

      expect(instance.isRenderingFrame, isFalse);
      instance.scheduleFrame();

      // IMPORTANT: scheduled, but not yet rendering
      expect(instance.isRenderingFrame, isFalse);
      await frameCompleter.future;
      expect(instance.isFrameScheduled, isFalse);

      expect(isRenderingInOnBeginFrame, isTrue);
      expect(isRenderingInOnDrawFrame, isTrue);
      expect(valueInOnFinishedRenderingFrame, isFalse);
    });

    test('scheduleWarmUpFrame', () async {
      final FrameService instance = FrameService.instance;

      final frameCompleter = Completer<void>();
      bool? valueInOnFinishedRenderingFrame;
      instance.onFinishedRenderingFrame = () {
        valueInOnFinishedRenderingFrame = instance.isRenderingFrame;
        frameCompleter.complete();
      };

      bool? isRenderingInOnBeginFrame;
      bool? isRenderingInOnDrawFrame;

      expect(instance.isRenderingFrame, isFalse);
      expect(instance.isFrameScheduled, isFalse);

      instance.scheduleWarmUpFrame(
        beginFrame: () {
          isRenderingInOnBeginFrame = instance.isRenderingFrame;
        },
        drawFrame: () {
          isRenderingInOnDrawFrame = instance.isRenderingFrame;
        },
      );

      // Even though the warm-up frame is scheduled the value of
      // isFrameScheduled remains false. This is because, for reasons to be yet
      // addressed, the warm-up frame can be (and indeed is) interleaved with
      // a normal scheduleFrame request. See the TODOs inside the
      // scheduleWarmUpFrame code, and this discussion in particular:
      // https://github.com/flutter/engine/pull/50570#discussion_r1496671676
      expect(instance.isFrameScheduled, isFalse);
      expect(instance.isRenderingFrame, isFalse);
      await frameCompleter.future;
      expect(instance.isFrameScheduled, isFalse);

      expect(isRenderingInOnBeginFrame, isTrue);
      expect(isRenderingInOnDrawFrame, isTrue);
      expect(valueInOnFinishedRenderingFrame, isFalse);
    });

    test('Frame is cancelled after a hot restart', () async {
      final FrameService instance = FrameService.instance;

      final frameCompleter = Completer<void>();
      instance.onFinishedRenderingFrame = () {
        frameCompleter.complete();
      };

      expect(instance.isFrameScheduled, isFalse);
      instance.scheduleFrame();
      expect(instance.isFrameScheduled, isTrue);
      // Perform a hot restart immediately after scheduling the frame.
      debugEmulateHotRestart();

      // Wait for 1 second for the frame to be rendered.
      var timedOut = false;
      await frameCompleter.future.timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          timedOut = true;
        },
      );
      // No frame should've been rendered because the animation frame callback should've been
      // cancelled on hot restart.
      expect(timedOut, isTrue);
      expect(instance.frameData.frameNumber, isZero);
      expect(frameCompleter.isCompleted, isFalse);
      // ... and no frame is scheduled.
      expect(instance.isFrameScheduled, isFalse);

      // To avoid leaving an uncompleted completer, let's complete it.
      frameCompleter.complete();
    });
  });
}

class DummyFrameService extends FrameService {}
