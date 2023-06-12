// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:built_value/serializer.dart';
import 'package:test/test.dart';

void main() {
  var serializers = Serializers();

  group('double with known specifiedType', () {
    var data = 3.141592653589793;
    var serialized = data;
    var specifiedType = const FullType(double);

    test('can be serialized', () {
      expect(serializers.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized, specifiedType: specifiedType),
          data);
    });
  });

  group('double with unknown specifiedType', () {
    var data = 3.141592653589793;
    var serialized = json.decode(json.encode(['double', data])) as Object;
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

  group('double with NaN value', () {
    var data = double.nan;
    var serialized = 'NaN';
    var specifiedType = const FullType(double);

    test('can be serialized', () {
      expect(serializers.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      // Compare using toString as NaN != NaN.
      expect(
          serializers
              .deserialize(serialized, specifiedType: specifiedType)
              .toString(),
          data.toString());
    });
  });

  group('double with -INF value', () {
    var data = double.negativeInfinity;
    var serialized = '-INF';
    var specifiedType = const FullType(double);

    test('can be serialized', () {
      expect(serializers.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized, specifiedType: specifiedType),
          data);
    });
  });

  group('double with INF value', () {
    var data = double.infinity;
    var serialized = 'INF';
    var specifiedType = const FullType(double);

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
