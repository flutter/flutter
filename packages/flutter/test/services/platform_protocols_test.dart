// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math' show Point;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:test/test.dart';

void main() {
  group('Invoking JSON platform function', () {
    void setupMockResponse(String json) {
      PlatformMessages.setMockStringMessageHandler('location', (String request) async => json);
    }
    void checkFormatException(String mockResponse) {
      setupMockResponse(mockResponse);
      expect(PlatformProtocols.invokeJSONFunction(
        channel: 'location',
        decoder: decodeLocation
      ), throwsA(new isInstanceOf<FormatException>()));
    }

    test('wraps invocation in envelope', () async {
      String request;
      PlatformMessages.setMockStringMessageHandler('someChannel', (String s) async {
        request = s;
        return '{"status":"ok"}';
      });
      await PlatformProtocols.invokeJSONFunction<Null>(
        channel: 'someChannel',
        name: 'someName',
        args: <String, dynamic>{'a': 2, 'b': 'hello'},
      );
      expect(request, equals('{"name":"someName","args":{"a":2,"b":"hello"}}'));
    });
    test('decodes valid domain object', () async {
      setupMockResponse('{"status":"ok","data":{"x":3,"y":4}}');
      final Point<int> decoded = await PlatformProtocols.invokeJSONFunction(
        channel: 'location',
        decoder: decodeLocation
      );
      expect(decoded, equals(new Point<int>(3, 4)));
    });
    test('decodes valid domain object as null if decoder is missing', () async {
      setupMockResponse('{"status":"ok","data":{"x":3,"y":4}}');
      final Point<int> decoded = await PlatformProtocols.invokeJSONFunction(
        channel: 'location'
      );
      expect(decoded, isNull);
    });
    test('leaves decoding of null to decoder', () async {
      setupMockResponse('{"status":"ok","data":null}');
      final Point<int> decoded = await PlatformProtocols.invokeJSONFunction(
        channel: 'location',
        decoder: decodeLocation
      );
      expect(decoded, new Point<int>(0, 0));
    });
    test('throws exception when native side returns error', () async {
      setupMockResponse('{"status":"error","message":"bad"}');
      try {
        await PlatformProtocols.invokeJSONFunction(
          channel: 'location',
          decoder: decodeLocation
        );
        fail('Exception expected');
      } catch (e) {
        expect(e, new isInstanceOf<PlatformException>());
        expect(e.status, equals('error'));
        expect(e.message, equals('bad'));
      }
    });
    test('throws FormatException when decoder fails', () {
      checkFormatException('{"status":"ok","data":{"x":3,"z":4}}');
    });
    test('throws FormatException when response JSON is invalid', () {
      checkFormatException('{');
    });
    test('throws FormatException when envelope is not a Map', () {
      checkFormatException('"hello"');
    });
    test('throws FormatException when envelope has missing fields', () {
      checkFormatException('{}');
    });
    test('throws FormatException when status is not a string', () {
      checkFormatException('{"status":{}}');
    });
    test('throws FormatException when error message is missing', () {
      checkFormatException('{"status":"error"}');
    });
    test('throws FormatException when error message is not a String', () {
      checkFormatException('{"status":"error","message":{}}');
    });
  });
  group('Creating platform JSON stream', () {
    test('does nothing before a listener is registered', () async {
      final Buffer<String> outgoingMessages = new Buffer<String>();
      final Buffer<String> incomingMessages = new Buffer<String>();
      PlatformMessages.setMockStringMessageHandler('location', (String s) async {
        outgoingMessages.add(s);
        return await incomingMessages.take();
      });
      final Stream<Point<int>> stream = PlatformProtocols.createJSONBroadcastStream(
        channel: 'location',
        decoder: decodeLocation,
      );
      await purgePendingMicrotasks();
      expect(outgoingMessages.length, equals(0));

      stream.listen((Point<int> location) {});

      await purgePendingMicrotasks();
      expect(outgoingMessages.length, equals(1));
    });
    test('should fail if stream is configurable and eventChannel is not specified', () {
      expect(() {
        PlatformProtocols.createJSONBroadcastStream(
          channel: 'location',
          decoder: decodeLocation,
          args: <String, dynamic>{},
        );
      }, throws);
    });
    test('should use main channel for events when an event channel is not specified', () async {
      final Buffer<String> outgoingMessages = new Buffer<String>();
      final Buffer<String> incomingMessages = new Buffer<String>();
      PlatformMessages.setMockStringMessageHandler('location', (String s) async {
        outgoingMessages.add(s);
        return await incomingMessages.take();
      });
      final Stream<Point<int>> stream = PlatformProtocols.createJSONBroadcastStream(
        channel: 'location',
        decoder: decodeLocation,
      );
      final Future<Point<int>> location = stream.first;
      expect(await outgoingMessages.take(), equals('{"name":"listen","args":null}'));
      incomingMessages.add('{"status":"ok"}');

      await PlatformMessages.handlePlatformMessage(
        'location',
        _encodeUTF8('{"status":"ok","data":{"x":3,"y":4}}'),
        (ByteData response) {},
      );
      expect(await location, equals(new Point<int>(3, 4)));
      expect(await outgoingMessages.take(), equals('{"name":"cancel","args":null}'));
      incomingMessages.add('{"status":"ok"}');
    });
    test('should use specified event channel if specified', () async {
      final Buffer<String> outgoingMessages = new Buffer<String>();
      final Buffer<String> incomingMessages = new Buffer<String>();
      PlatformMessages.setMockStringMessageHandler('location', (String s) async {
        outgoingMessages.add(s);
        return await incomingMessages.take();
      });
      final Stream<Point<int>> stream = PlatformProtocols.createJSONBroadcastStream(
        channel: 'location',
        args: <String, dynamic>{'eventChannel': 'location-events', 'a': 42, 'b': 'hello'},
        decoder: decodeLocation,
      );
      final Future<Point<int>> location = stream.first;
      expect(await outgoingMessages.take(), equals(
        '{"name":"listen",'
         '"args":{"eventChannel":"location-events","a":42,"b":"hello"}}'
      ));
      incomingMessages.add('{"status":"ok"}');

      await PlatformMessages.handlePlatformMessage(
        'location-events',
        _encodeUTF8('{"status":"ok","data":{"x":3,"y":4}}'),
        (ByteData response) {},
      );
      expect(await location, equals(new Point<int>(3, 4)));
      expect(await outgoingMessages.take(), equals(
        '{"name":"cancel",'
          '"args":{"eventChannel":"location-events","a":42,"b":"hello"}}'
      ));
      incomingMessages.add('{"status":"ok"}');
    });
    test('should produce error event, if listen call fails', () async {
      final Buffer<String> outgoingMessages = new Buffer<String>();
      final Buffer<String> incomingMessages = new Buffer<String>();
      PlatformMessages.setMockStringMessageHandler('location', (String s) async {
        outgoingMessages.add(s);
        return await incomingMessages.take();
      });
      final Stream<Point<int>> stream = PlatformProtocols.createJSONBroadcastStream(
          channel: 'location',
          decoder: decodeLocation,
      );
      final Future<Point<int>> location = stream.first;
      expect(await outgoingMessages.take(), equals('{"name":"listen","args":null}'));
      incomingMessages.add('{"status":"error","message":"bad"}');
      try {
        await location;
        fail('Exception expected');
      }
      catch(e) {
        expect(e, new isInstanceOf<PlatformException>());
      }
    });
  });
}

Future<Null> purgePendingMicrotasks() async {
  await new Future<Null>(() {});
}

ByteData _encodeUTF8(String message) {
  if (message == null)
    return null;
  Uint8List encoded = UTF8.encoder.convert(message);
  return encoded.buffer.asByteData();
}

Point<int> decodeLocation(dynamic json) {
  if (json == null)
    return new Point<int>(0, 0);
  if (json is Map && json.containsKey('x') && json.containsKey('y'))
    return new Point<int>(json['x'], json['y']);
  throw new FormatException();
}

class Buffer<T> {
  final Map<int, Completer<T>> completers = <int, Completer<T>>{};
  int nextIn = 0;
  int nextOut = 0;
  // Invariant: (nextIn - nextOut).abs() == completers.length

  int get length => completers.length;

  void add(T t) => _completer(nextOut, nextIn++).complete(t);

  Future<T> take() => _completer(nextIn, nextOut++).future;

  Completer<T> _completer(int a, int b) =>
    (a <= b) ? (completers[b] = new Completer<T>()) : completers.remove(b);
}