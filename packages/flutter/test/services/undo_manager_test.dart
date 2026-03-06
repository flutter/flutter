// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();

  group('Undo Interactions', () {
    test('UndoManagerClient handleUndo', () async {
      // Assemble an UndoManagerClient so we can verify its change in state.
      final client = _FakeUndoManagerClient();
      UndoManager.client = client;

      expect(client.latestMethodCall, isEmpty);

      // Send handleUndo message with "undo" as the direction.
      ByteData? messageBytes = const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'args': <dynamic>['undo'],
        'method': 'UndoManagerClient.handleUndo',
      });
      await binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/undomanager',
        messageBytes,
        null,
      );

      expect(client.latestMethodCall, 'handlePlatformUndo(${UndoDirection.undo})');

      // Send handleUndo message with "undo" as the direction.
      messageBytes = const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'args': <dynamic>['redo'],
        'method': 'UndoManagerClient.handleUndo',
      });
      await binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/undomanager',
        messageBytes,
        (ByteData? _) {},
      );

      expect(client.latestMethodCall, 'handlePlatformUndo(${UndoDirection.redo})');
    });

    test('UndoManager.setUndoState reports error when channel fails', () async {
      final FlutterExceptionHandler? oldOnError = FlutterError.onError;
      final errors = <FlutterErrorDetails>[];
      // Use a Completer to signal when the error has been caught.
      final errorReceived = Completer<void>();
      FlutterError.onError = (FlutterErrorDetails details) {
        errors.add(details);
        if (!errorReceived.isCompleted) {
          errorReceived.complete();
        }
      };

      try {
        final log = <MethodCall>[];
        const channel = MethodChannel('flutter/undomanager');
        UndoManager.setChannel(channel);

        channel.setMockMethodCallHandler((MethodCall methodCall) async {
          log.add(methodCall);
          throw Exception('Channel failed');
        });

        UndoManager.setUndoState(canUndo: true, canRedo: true);

        // Wait specifically for the error handler to fire.
        // Set a timeout so the test doesn't hang forever if it fails.
        await errorReceived.future.timeout(const Duration(seconds: 5));

        expect(errors, hasLength(1));
        expect(errors.single.exception, isA<Exception>());
        expect(errors.single.exception.toString(), contains('Channel failed'));
        expect(
          errors.single.context.toString(),
          contains('while sending the UndoManager.setUndoState event'),
        );
        expect(log, hasLength(1));
        expect(log.single.method, 'UndoManager.setUndoState');
      } finally {
        FlutterError.onError = oldOnError;
        UndoManager.setChannel(SystemChannels.undoManager);
      }
    });
  });
}

class _FakeUndoManagerClient with UndoManagerClient {
  String latestMethodCall = '';

  @override
  void undo() {}

  @override
  void redo() {}

  @override
  bool get canUndo => false;

  @override
  bool get canRedo => false;

  @override
  void handlePlatformUndo(UndoDirection direction) {
    latestMethodCall = 'handlePlatformUndo($direction)';
  }
}
