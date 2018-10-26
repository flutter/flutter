// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import '../flutter_test_alternative.dart';

void main() {
  group('BasicMessageChannel', () {
    const MessageCodec<String> string = StringCodec();
    const BasicMessageChannel<String> channel = BasicMessageChannel<String>('ch', string);
    test('can send string message and get reply', () async {
      BinaryMessages.setMockMessageHandler(
        'ch',
        (ByteData message) async => string.encodeMessage(string.decodeMessage(message) + ' world'),
      );
      final String reply = await channel.send('hello');
      expect(reply, equals('hello world'));
    });
    test('can receive string message and send reply', () async {
      channel.setMessageHandler((String message) async => message + ' world');
      String reply;
      await BinaryMessages.handlePlatformMessage(
        'ch',
        const StringCodec().encodeMessage('hello'),
        (ByteData replyBinary) {
          reply = string.decodeMessage(replyBinary);
        }
      );
      expect(reply, equals('hello world'));
    });
  });

  group('MethodChannel', () {
    const MessageCodec<dynamic> jsonMessage = JSONMessageCodec();
    const MethodCodec jsonMethod = JSONMethodCodec();
    const MethodChannel channel = MethodChannel('ch7', jsonMethod);
    test('can invoke method and get result', () async {
      BinaryMessages.setMockMessageHandler(
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
      BinaryMessages.setMockMessageHandler(
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
      } on PlatformException catch (e) {
        expect(e.code, equals('bad'));
        expect(e.message, equals('Something happened'));
        expect(e.details, equals(<String, dynamic>{'a': 42, 'b': 3.14}));
      } catch (e) {
        fail('PlatformException expected');
      }
    });
    test('can invoke unimplemented method', () async {
      BinaryMessages.setMockMessageHandler(
        'ch7',
        (ByteData message) async => null,
      );
      try {
        await channel.invokeMethod('sayHello', 'hello');
        fail('Exception expected');
      } on MissingPluginException catch (e) {
        expect(e.message, contains('sayHello'));
        expect(e.message, contains('ch7'));
      } catch (e) {
        fail('MissingPluginException expected');
      }
    });
    test('can handle method call with no registered plugin', () async {
      channel.setMethodCallHandler(null);
      final ByteData call = jsonMethod.encodeMethodCall(const MethodCall('sayHello', 'hello'));
      ByteData envelope;
      await BinaryMessages.handlePlatformMessage('ch7', call, (ByteData result) {
        envelope = result;
      });
      expect(envelope, isNull);
    });
    test('can handle method call of unimplemented method', () async {
      channel.setMethodCallHandler((MethodCall call) async {
        throw MissingPluginException();
      });
      final ByteData call = jsonMethod.encodeMethodCall(const MethodCall('sayHello', 'hello'));
      ByteData envelope;
      await BinaryMessages.handlePlatformMessage('ch7', call, (ByteData result) {
        envelope = result;
      });
      expect(envelope, isNull);
    });
    test('can handle method call with successful result', () async {
      channel.setMethodCallHandler((MethodCall call) async => '${call.arguments}, world');
      final ByteData call = jsonMethod.encodeMethodCall(const MethodCall('sayHello', 'hello'));
      ByteData envelope;
      await BinaryMessages.handlePlatformMessage('ch7', call, (ByteData result) {
        envelope = result;
      });
      expect(jsonMethod.decodeEnvelope(envelope), equals('hello, world'));
    });
    test('can handle method call with expressive error result', () async {
      channel.setMethodCallHandler((MethodCall call) async {
        throw PlatformException(code: 'bad', message: 'sayHello failed', details: null);
      });
      final ByteData call = jsonMethod.encodeMethodCall(const MethodCall('sayHello', 'hello'));
      ByteData envelope;
      await BinaryMessages.handlePlatformMessage('ch7', call, (ByteData result) {
        envelope = result;
      });
      try {
        jsonMethod.decodeEnvelope(envelope);
        fail('Exception expected');
      } on PlatformException catch (e) {
        expect(e.code, equals('bad'));
        expect(e.message, equals('sayHello failed'));
      } catch (e) {
        fail('PlatformException expected');
      }
    });
    test('can handle method call with other error result', () async {
      channel.setMethodCallHandler((MethodCall call) async {
        throw ArgumentError('bad');
      });
      final ByteData call = jsonMethod.encodeMethodCall(const MethodCall('sayHello', 'hello'));
      ByteData envelope;
      await BinaryMessages.handlePlatformMessage('ch7', call, (ByteData result) {
        envelope = result;
      });
      try {
        jsonMethod.decodeEnvelope(envelope);
        fail('Exception expected');
      } on PlatformException catch (e) {
        expect(e.code, equals('error'));
        expect(e.message, equals('Invalid argument(s): bad'));
      } catch (e) {
        fail('PlatformException expected');
      }
    });
  });
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
          final Map<dynamic, dynamic> methodCall = jsonMessage.decodeMessage(message);
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
      final List<dynamic> events = await channel.receiveBroadcastStream('hello').toList();
      expect(events, orderedEquals(<String>['hello1', 'hello2']));
      await Future<void>.delayed(Duration.zero);
      expect(canceled, isTrue);
    });
    test('can receive error event', () async {
      BinaryMessages.setMockMessageHandler(
        'ch',
        (ByteData message) async {
          final Map<dynamic, dynamic> methodCall = jsonMessage.decodeMessage(message);
          if (methodCall['method'] == 'listen') {
            final String argument = methodCall['args'];
            emitEvent(jsonMethod.encodeErrorEnvelope(code: '404', message: 'Not Found.', details: argument));
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
      channel.receiveBroadcastStream('hello').listen(events.add, onError: errors.add);
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
