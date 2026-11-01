// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' as convert;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('jsonDecodeAsync', () {
    test('matches jsonDecode', () async {
      const sources = <String>[
        'null',
        'true',
        '42',
        '3.14',
        '"text"',
        '[1, "two", false, null]',
        '{"nested": {"list": [1, 2, 3]}, "unicode": "Grüße 😀"}',
      ];

      for (final source in sources) {
        expect(await jsonDecodeAsync(source), convert.jsonDecode(source));
      }
    });

    test('matches jsonDecode when tokens cross chunk boundaries', () async {
      const int chunkSize = 16 * 1024;
      final String textPrefix = ''.padRight(chunkSize - 2, 'a');
      final String whitespace = ''.padRight(chunkSize - 2);
      final sources = <String>[
        '"$textPrefix\\u0062"',
        '"$textPrefix😀"',
        '${whitespace}1234567890',
        '[${whitespace}null]',
      ];

      for (final source in sources) {
        expect(await jsonDecodeAsync(source), convert.jsonDecode(source));
      }
    });

    test('supports revivers', () async {
      Object? reviver(Object? key, Object? value) {
        if (value is num) {
          return value * 2;
        }
        if (key == null) {
          return <String, Object?>{'value': value};
        }
        return value;
      }

      const source = '{"values": [1, 2.5], "nested": {"value": 3}}';

      expect(
        await jsonDecodeAsync(source, reviver: reviver),
        convert.jsonDecode(source, reviver: reviver),
      );
    });

    test('reports malformed JSON', () async {
      const sources = <String>['', '[', '{"key":}', 'true false', r'"\uZZZZ"'];

      for (final source in sources) {
        await expectLater(jsonDecodeAsync(source), throwsA(isA<FormatException>()));
      }
    });

    test('forwards errors thrown by a reviver', () async {
      final error = StateError('reviver failed');

      await expectLater(
        jsonDecodeAsync('1', reviver: (Object? key, Object? value) => throw error),
        throwsA(same(error)),
      );
    });

    test('yields to the event loop while decoding large inputs', () async {
      const int valueCount = 512 * 1024;
      final source = '[${List<String>.filled(valueCount, '0').join(',')}]';
      var eventLoopReached = false;
      Timer.run(() {
        eventLoopReached = true;
      });

      final Object? result = await jsonDecodeAsync(source);

      expect(eventLoopReached, isTrue);
      expect(
        result,
        isA<List<Object?>>().having((List<Object?> value) => value.length, 'length', valueCount),
      );
    }, skip: kIsWeb); // [intended] Web yields before rather than during decoding.

    test('yields to the event loop before decoding on web', () async {
      var eventLoopReached = false;
      Timer.run(() {
        eventLoopReached = true;
      });

      final Object? result = await jsonDecodeAsync('null');

      expect(eventLoopReached, isTrue);
      expect(result, isNull);
    }, skip: !kIsWeb); // [intended] This behavior is specific to the web implementation.

    test('supports concurrent decodes', () async {
      final String padding = ''.padRight(256 * 1024);
      final List<Object?> results = await Future.wait(<Future<Object?>>[
        jsonDecodeAsync('$padding[1, 2, 3]'),
        jsonDecodeAsync('$padding{"key": "value"}'),
      ]);

      expect(results, <Object?>[
        <Object?>[1, 2, 3],
        <String, Object?>{'key': 'value'},
      ]);
    });
  });
}
