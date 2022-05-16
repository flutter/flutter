// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Undo Interactions', () {
    test('UndoManagerClient handleUndo', () async {
      // Assemble an UndoManagerClient so we can verify its change in state.
      final _FakeUndoManagerClient client = _FakeUndoManagerClient();
      UndoManager.client = client;

      expect(client.latestMethodCall, isEmpty);

      // Send handleUndo message with "undo" as the direction.
      ByteData? messageBytes = const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'args': <dynamic>['undo'],
        'method': 'UndoManagerClient.handleUndo',
      });
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/undomanager',
        messageBytes,
        null,
      );

      expect(client.latestMethodCall, 'handlePlatformUndo(undo)');

      // Send handleUndo message with "undo" as the direction.
      messageBytes = const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'args': <dynamic>['redo'],
        'method': 'UndoManagerClient.handleUndo',
      });
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/undomanager',
        messageBytes,
        (ByteData? _) {},
      );

      expect(client.latestMethodCall, 'handlePlatformUndo(redo)');
    });
  });
}

class _FakeUndoManagerClient implements UndoManagerClient {
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
  void handlePlatformUndo(String direction) {
    latestMethodCall = 'handlePlatformUndo($direction)';
  }
}
