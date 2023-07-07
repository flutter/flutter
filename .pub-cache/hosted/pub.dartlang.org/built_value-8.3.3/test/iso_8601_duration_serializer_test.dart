// Copyright (c) 2019, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_value/iso_8601_duration_serializer.dart';
import 'package:built_value/serializer.dart';
import 'package:test/test.dart';

void main() {
  var serializers =
      (Serializers().toBuilder()..add(Iso8601DurationSerializer())).build();

  const testTable = [
    {
      #s: 'P1DT2H3M4S',
      #d: Duration(days: 1, hours: 2, minutes: 3, seconds: 4),
    },
    {
      #s: 'PT0S',
      #d: Duration.zero,
    },
    {
      #s: 'PT2H',
      #d: Duration(hours: 2),
    },
    {
      #s: 'PT2H3M',
      #d: Duration(hours: 2, minutes: 3),
    },
    {
      #s: 'P2D',
      #d: Duration(days: 2),
    },
  ];
  const badOnes = [
    'P',
    'P0',
    'PT2S567',
  ];

  group('Duration with known specifiedType', () {
    final specifiedType = const FullType(Duration);
    testTable.forEach((testValue) {
      test('can be serialized', () {
        expect(
            serializers.serialize(testValue[#d]!, specifiedType: specifiedType),
            testValue[#s]);
      });

      test('can be deserialized', () {
        expect(
            serializers.deserialize(testValue[#s]!,
                specifiedType: specifiedType),
            testValue[#d]);
      });
    });
    badOnes.forEach((badOne) {
      test('deserialize throws if not ISO format', () {
        expect(
            () => serializers.deserialize(badOne, specifiedType: specifiedType),
            throwsA(const TypeMatcher<FormatException>()));
      });
    });
  });

  group('Duration with unknown specifiedType', () {
    final specifiedType = FullType.unspecified;
    testTable.forEach((testValue) {
      test('can be serialized', () {
        expect(
            serializers.serialize(testValue[#d]!, specifiedType: specifiedType),
            ['Duration', testValue[#s]]);
      });

      test('can be deserialized', () {
        expect(
            serializers.deserialize(['Duration', testValue[#s]],
                specifiedType: specifiedType),
            testValue[#d]);
      });
    });

    group('Duration with subsecond data', () {
      final data = Duration(seconds: 2, milliseconds: 4);
      final specifiedType = const FullType(Duration);
      test('throws an error upon serialization', () {
        expect(() => serializers.serialize(data, specifiedType: specifiedType),
            throwsArgumentError);
      });
    });
  });
}
