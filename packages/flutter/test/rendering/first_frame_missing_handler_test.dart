// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestRenderBinding();
  test(
    'Web first-frame notification is sent exactly once and does not report an error when flutter/service_worker is unhandled',
    () async {
      final errors = <FlutterErrorDetails>[];
      final FlutterExceptionHandler? oldHandler = FlutterError.onError;
      FlutterError.onError = errors.add;
      var messages = 0;
      // A null binary reply is how an unhandled platform channel looks to
      // the framework.
      binding.defaultBinaryMessenger.setMockMessageHandler('flutter/service_worker', (
        ByteData? message,
      ) async {
        messages += 1;
        return null;
      });
      addTearDown(() {
        FlutterError.onError = oldHandler;
        binding.defaultBinaryMessenger.setMockMessageHandler('flutter/service_worker', null);
      });

      // The first frame sends the notification.
      binding.handleBeginFrame(Duration.zero);
      binding.handleDrawFrame();
      await pumpEventQueue();

      expect(messages, 1);
      expect(errors, isEmpty);

      // Later frames do not send it again.
      binding.handleBeginFrame(const Duration(milliseconds: 16));
      binding.handleDrawFrame();
      await pumpEventQueue();

      expect(messages, 1);
      expect(errors, isEmpty);
    },
    skip: !kIsWeb, // [intended] _handleWebFirstFrame only runs on the web.
  );
}

class TestRenderBinding extends BindingBase
    with
        SchedulerBinding,
        ServicesBinding,
        GestureBinding,
        SemanticsBinding,
        RendererBinding,
        TestDefaultBinaryMessengerBinding {}
