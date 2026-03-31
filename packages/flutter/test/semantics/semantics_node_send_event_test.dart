// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/rendering_tester.dart';

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test('SemanticsNode.sendEvent reports error to FlutterError', () async {
    final errorDetails = <FlutterErrorDetails>[];
    final FlutterExceptionHandler? oldHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      errorDetails.add(details);
    };

    try {
      final node = SemanticsNode();
      final semanticsOwner = SemanticsOwner(onSemanticsUpdate: (SemanticsUpdate update) {});
      node.attach(semanticsOwner);

      expect(node.attached, isTrue);

      // Mock accessibility channel to throw error.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
            dynamic message,
          ) async {
            throw Exception('Test exception');
          });

      node.sendEvent(const AnnounceSemanticsEvent('hello', TextDirection.ltr, 0));

      // Wait for the async error handler to run.
      await pumpEventQueue();

      expect(errorDetails.length, 1);
      expect(errorDetails[0].exception, isA<Exception>());
      expect(errorDetails[0].exception.toString(), contains('Test exception'));
      expect(errorDetails[0].library, 'semantics library');
      expect(errorDetails[0].context.toString(), contains('while sending accessibility event'));
    } finally {
      FlutterError.onError = oldHandler;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, null);
    }
  });
}
