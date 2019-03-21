// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import '../flutter_test_alternative.dart';

void main() {
  group('EventChannel', () {
    const MessageCodec<dynamic> jsonMessage = JSONMessageCodec();
    const MethodCodec jsonMethod = JSONMethodCodec();
    const EventChannel channel = EventChannel('ch', jsonMethod);
    void emitEvent(dynamic event) {
      BinaryMessages.handlePlatformMessage(
        'ch',
        event,
        (ByteData reply) {},
      );
    }

    test('can receive event stream', () async {
      bool canceled = false;
      BinaryMessages.setMockMessageHandler(
        'ch',
        (ByteData message) async {
          final Map<dynamic, dynamic> methodCall =
              jsonMessage.decodeMessage(message);
          if (methodCall['method'] == 'listen') {
            final String argument = methodCall['args'];
            emitEvent(jsonMethod.encodeSuccessEnvelope(argument + '1'));
            emitEvent(jsonMethod.encodeSuccessEnvelope(argument + '2'));
            emitEvent(null);
            return jsonMethod.encodeSuccessEnvelope(null);
          } else if (methodCall['method'] == 'cancel') {
            canceled = true;
            return jsonMethod.encodeSuccessEnvelope(null);
          } else {
            fail('Expected listen or cancel');
          }
        },
      );
      final List<dynamic> events =
          await channel.receiveBroadcastStream('hello').toList();
      expect(events, orderedEquals(<String>['hello1', 'hello2']));
      await Future<void>.delayed(Duration.zero);
      expect(canceled, isTrue);
    });
    test('can receive error event', () async {
      BinaryMessages.setMockMessageHandler(
        'ch',
        (ByteData message) async {
          final Map<dynamic, dynamic> methodCall =
              jsonMessage.decodeMessage(message);
          if (methodCall['method'] == 'listen') {
            final String argument = methodCall['args'];
            emitEvent(jsonMethod.encodeErrorEnvelope(
                code: '404', message: 'Not Found.', details: argument));
            return jsonMethod.encodeSuccessEnvelope(null);
          } else if (methodCall['method'] == 'cancel') {
            return jsonMethod.encodeSuccessEnvelope(null);
          } else {
            fail('Expected listen or cancel');
          }
        },
      );
      final List<dynamic> events = <dynamic>[];
      final List<dynamic> errors = <dynamic>[];
      channel
          .receiveBroadcastStream('hello')
          .listen(events.add, onError: errors.add);
      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);
      expect(errors, hasLength(1));
      expect(errors[0], isInstanceOf<PlatformException>());
      final PlatformException error = errors[0];
      expect(error.code, '404');
      expect(error.message, 'Not Found.');
      expect(error.details, 'hello');
    });
  });
}
