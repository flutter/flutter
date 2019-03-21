// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_channels/flutter_channels.dart';

import 'common.dart';

void main() {
  group('BaseMessageChannel', () {
    const MessageCodec<String> string = StringCodec();
    const BaseMessageChannel<String> channel =
        BaseMessageChannel<String>('ch', string, testMessenger);
    test('can send string message and get reply', () async {
      testMessenger.setMockMessageHandler(
        'ch',
        (ByteData message) async =>
            string.encodeMessage(string.decodeMessage(message) + ' world'),
      );
      final String reply = await channel.send('hello');
      expect(reply, equals('hello world'));
    });
    test('can receive string message and send reply', () async {
      channel.setMessageHandler((String message) async => message + ' world');
      String reply;
      await TestMessages.receiveMessage(
        'ch',
        const StringCodec().encodeMessage('hello'),
        (ByteData replyBinary) {
          reply = string.decodeMessage(replyBinary);
        },
      );
      expect(reply, equals('hello world'));
    });
  });

  group('BaseMethodChannel', () {
    const MessageCodec<dynamic> jsonMessage = JSONMessageCodec();
    const MethodCodec jsonMethod = JSONMethodCodec();
    const BaseMethodChannel channel =
        BaseMethodChannel('ch7', testMessenger, jsonMethod);
    test('can invoke method and get result', () async {
      testMessenger.setMockMessageHandler(
        'ch7',
        (ByteData message) async {
          final Map<dynamic, dynamic> methodCall =
              jsonMessage.decodeMessage(message);
          if (methodCall['method'] == 'sayHello') {
            return jsonMessage
                .encodeMessage(<dynamic>['${methodCall['args']} world']);
          } else {
            return jsonMessage.encodeMessage(<dynamic>['unknown', null, null]);
          }
        },
      );
      final String result = await channel.invokeMethod('sayHello', 'hello');
      expect(result, equals('hello world'));
    });
    test('can invoke list method and get result', () async {
      testMessenger.setMockMessageHandler(
        'ch7',
        (ByteData message) async {
          final Map<dynamic, dynamic> methodCall =
              jsonMessage.decodeMessage(message);
          if (methodCall['method'] == 'sayHello') {
            return jsonMessage.encodeMessage(<dynamic>[
              <String>['${methodCall['args']}', 'world']
            ]);
          } else {
            return jsonMessage.encodeMessage(<dynamic>['unknown', null, null]);
          }
        },
      );
      expect(channel.invokeMethod<List<String>>('sayHello', 'hello'),
          throwsA(isInstanceOf<TypeError>()));
      expect(await channel.invokeListMethod<String>('sayHello', 'hello'),
          <String>['hello', 'world']);
    });

    test('can invoke map method and get result', () async {
      testMessenger.setMockMessageHandler(
        'ch7',
        (ByteData message) async {
          final Map<dynamic, dynamic> methodCall =
              jsonMessage.decodeMessage(message);
          if (methodCall['method'] == 'sayHello') {
            return jsonMessage.encodeMessage(<dynamic>[
              <String, String>{'${methodCall['args']}': 'world'}
            ]);
          } else {
            return jsonMessage.encodeMessage(<dynamic>['unknown', null, null]);
          }
        },
      );
      expect(channel.invokeMethod<Map<String, String>>('sayHello', 'hello'),
          throwsA(isInstanceOf<TypeError>()));
      expect(await channel.invokeMapMethod<String, String>('sayHello', 'hello'),
          <String, String>{'hello': 'world'});
    });

    test('can invoke method and get error', () async {
      testMessenger.setMockMessageHandler(
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
        await channel.invokeMethod<dynamic>('sayHello', 'hello');
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
      testMessenger.setMockMessageHandler(
        'ch7',
        (ByteData message) async => null,
      );
      try {
        await channel.invokeMethod<void>('sayHello', 'hello');
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
      final ByteData call =
          jsonMethod.encodeMethodCall(const MethodCall('sayHello', 'hello'));
      ByteData envelope;
      await TestMessages.receiveMessage('ch7', call, (ByteData result) {
        envelope = result;
      });
      expect(envelope, isNull);
    });
    test('can handle method call of unimplemented method', () async {
      channel.setMethodCallHandler((MethodCall call) async {
        throw MissingPluginException();
      });
      final ByteData call =
          jsonMethod.encodeMethodCall(const MethodCall('sayHello', 'hello'));
      ByteData envelope;
      await TestMessages.receiveMessage('ch7', call, (ByteData result) {
        envelope = result;
      });
      expect(envelope, isNull);
    });
    test('can handle method call with successful result', () async {
      channel.setMethodCallHandler(
          (MethodCall call) async => '${call.arguments}, world');
      final ByteData call =
          jsonMethod.encodeMethodCall(const MethodCall('sayHello', 'hello'));
      ByteData envelope;
      await TestMessages.receiveMessage('ch7', call, (ByteData result) {
        envelope = result;
      });
      expect(jsonMethod.decodeEnvelope(envelope), equals('hello, world'));
    });
    test('can handle method call with expressive error result', () async {
      channel.setMethodCallHandler((MethodCall call) async {
        throw PlatformException(
            code: 'bad', message: 'sayHello failed', details: null);
      });
      final ByteData call =
          jsonMethod.encodeMethodCall(const MethodCall('sayHello', 'hello'));
      ByteData envelope;
      await TestMessages.receiveMessage('ch7', call, (ByteData result) {
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
      final ByteData call =
          jsonMethod.encodeMethodCall(const MethodCall('sayHello', 'hello'));
      ByteData envelope;
      await TestMessages.receiveMessage('ch7', call, (ByteData result) {
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
}

typedef _MessageHandler = Future<ByteData> Function(ByteData message);

class TestMessages {
  const TestMessages._();
  static final Map<String, _MessageHandler> _mockHandlers =
      <String, _MessageHandler>{};
  static final Map<String, _MessageHandler> _handlers =
      <String, _MessageHandler>{};

  static Future<ByteData> send(String channel, ByteData message) {
    final _MessageHandler handler = _mockHandlers[channel];
    if (handler != null) {
      return handler(message);
    }

    return null;
  }

  static void setMessageHandler(
      String channel, Future<ByteData> Function(ByteData message) handler) {
    if (handler == null) {
      _handlers.remove(channel);
    } else {
      _handlers[channel] = handler;
    }
  }

  static void setMockMessageHandler(
      String channel, Future<ByteData> Function(ByteData message) handler) {
    if (handler == null) {
      _mockHandlers.remove(channel);
    } else {
      _mockHandlers[channel] = handler;
    }
  }

  static Future<void> receiveMessage(
      String channel, ByteData data, void Function(ByteData) callback) async {
    ByteData response;
    final _MessageHandler handler = _handlers[channel];
    if (handler != null) {
      response = await handler(data);
    }
    callback(response);
  }
}

class TestMessenger extends BinaryMessenger {
  const TestMessenger();

  @override
  Future<ByteData> send(String channel, ByteData message) {
    return TestMessages.send(channel, message);
  }

  @override
  void setMessageHandler(
      String channel, Future<ByteData> Function(ByteData message) handler) {
    TestMessages.setMessageHandler(channel, handler);
  }

  @override
  void setMockMessageHandler(
      String channel, Future<ByteData> Function(ByteData message) handler) {
    TestMessages.setMockMessageHandler(channel, handler);
  }
}

const TestMessenger testMessenger = TestMessenger();
