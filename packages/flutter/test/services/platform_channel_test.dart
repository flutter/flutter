// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:test/test.dart';

void main() {
  group('PlatformMessageChannel', () {
    const MessageCodec<String> string = const StringCodec();
    const PlatformMessageChannel<String> channel = const PlatformMessageChannel<String>('ch', string);
    test('can send string message and get reply', () async {
      PlatformMessages.setMockBinaryMessageHandler(
        'ch',
        (ByteData message) async => string.encodeMessage(string.decodeMessage(message) + ' world'),
      );
      final String reply = await channel.send('hello');
      expect(reply, equals('hello world'));
    });
    test('can receive string message and send reply', () async {
      channel.setMessageHandler((String message) async => message + ' world');
      String reply;
      await PlatformMessages.handlePlatformMessage(
        'ch',
        const StringCodec().encodeMessage('hello'),
        (ByteData replyBinary) {
          reply = string.decodeMessage(replyBinary);
        }
      );
      expect(reply, equals('hello world'));
    });
  });

  group('PlatformMethodChannel', () {
    const MessageCodec<dynamic> jsonMessage = const JSONMessageCodec();
    const MethodCodec jsonMethod = const JSONMethodCodec();
    const PlatformMethodChannel channel = const PlatformMethodChannel('ch7', jsonMethod);
    test('can invoke method and get result', () async {
      PlatformMessages.setMockBinaryMessageHandler(
        'ch7',
        (ByteData message) async {
          final Map<dynamic, dynamic> methodCall = jsonMessage.decodeMessage(message);
          if (methodCall['method'] == 'sayHello')
            return jsonMessage.encodeMessage(<dynamic>['${methodCall['args']} world']);
          else
            return jsonMessage.encodeMessage(<dynamic>['unknown', null, null]);
        },
      );
      final String result = await channel.invokeMethod('sayHello', 'hello');
      expect(result, equals('hello world'));
    });
    test('can invoke method and get error', () async {
      PlatformMessages.setMockBinaryMessageHandler(
        'ch7',
        (ByteData message) async {
          return jsonMessage.encodeMessage(<dynamic>[
            'bad',
            'Something happened',
            <String, dynamic>{'a': 42, 'b': 3.14},
          ]);
        },
      );
      try {
        await channel.invokeMethod('sayHello', 'hello');
        fail('Exception expected');
      } on PlatformException catch(e) {
        expect(e.code, equals('bad'));
        expect(e.message, equals('Something happened'));
        expect(e.details, equals(<String, dynamic>{'a': 42, 'b': 3.14}));
      } catch(e) {
        fail('PlatformException expected');
      }
    });
    test('can invoke unimplemented method', () async {
      PlatformMessages.setMockBinaryMessageHandler(
        'ch7',
        (ByteData message) async => null,
      );
      try {
        await channel.invokeMethod('sayHello', 'hello');
        fail('Exception expected');
      } on MissingPluginException catch(e) {
        expect(e.message, contains('sayHello'));
        expect(e.message, contains('ch7'));
      } catch(e) {
        fail('MissingPluginException expected');
      }
    });
  });
  group('PlatformEventChannel', () {
    const MessageCodec<dynamic> jsonMessage = const JSONMessageCodec();
    const MethodCodec jsonMethod = const JSONMethodCodec();
    const PlatformEventChannel channel = const PlatformEventChannel('ch', jsonMethod);
    test('can receive event stream', () async {
      void emitEvent(dynamic event) {
        PlatformMessages.handlePlatformMessage(
          'ch',
          event,
          (ByteData reply) {},
        );
      }
      bool cancelled = false;
      PlatformMessages.setMockBinaryMessageHandler(
        'ch',
        (ByteData message) async {
          final Map<dynamic, dynamic> methodCall = jsonMessage.decodeMessage(message);
          if (methodCall['method'] == 'listen') {
            final String argument = methodCall['args'];
            emitEvent(jsonMessage.encodeMessage(<dynamic>[argument + '1']));
            emitEvent(jsonMessage.encodeMessage(<dynamic>[argument + '2']));
            emitEvent(null);
            return jsonMessage.encodeMessage(<dynamic>[null]);
          } else if (methodCall['method'] == 'cancel') {
            cancelled = true;
            return jsonMessage.encodeMessage(<dynamic>[null]);
          } else {
            fail('Expected listen or cancel');
          }
        },
      );
      final List<dynamic> events = await channel.receiveBroadcastStream('hello').toList();
      expect(events, orderedEquals(<String>['hello1', 'hello2']));
      await new Future<Null>.delayed(Duration.ZERO);
      expect(cancelled, isTrue);
    });
  });
}
