// Copyright (c) 2018, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:built_value/serializer.dart';
import 'package:test/test.dart';

void main() {
  var serializers =
      (Serializers().toBuilder()..add(Iso8601DateTimeSerializer())).build();

  group('DateTime with known specifiedType', () {
    var data = DateTime.utc(1980, 1, 2, 3, 4, 5, 6, 7);
    var serialized = '1980-01-02T03:04:05.006007Z';
    var specifiedType = const FullType(DateTime);

    test('can be serialized', () {
      expect(serializers.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized, specifiedType: specifiedType),
          data);
    });

    test('serialize throws if not UTC', () {
      expect(() => serializers.serialize(DateTime.now()),
          throwsA(const TypeMatcher<ArgumentError>()));
    });
  });

  group('DateTime with unknown specifiedType', () {
    var data = DateTime.utc(1980, 1, 2, 3, 4, 5, 6, 7);
    var serialized =
        json.decode(json.encode(['DateTime', '1980-01-02T03:04:05.006007Z']))
            as Object;
    var specifiedType = FullType.unspecified;

    test('can be serialized', () {
      expect(serializers.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized, specifiedType: specifiedType),
          data);
    });
  });
}
