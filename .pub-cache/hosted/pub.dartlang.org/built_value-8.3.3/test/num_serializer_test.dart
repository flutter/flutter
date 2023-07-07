// Copyright (c) 2017, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_value/serializer.dart';
import 'package:test/test.dart';

void main() {
  var serializers = Serializers();

  group('num with known specifiedType', () {
    var data = 42;
    var serialized = 42;
    var specifiedType = const FullType(num);

    test('can be serialized', () {
      expect(serializers.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized, specifiedType: specifiedType),
          data);
    });
  });

  group('num with NaN value', () {
    var data = double.nan;
    var serialized = 'NaN';
    var specifiedType = const FullType(num);

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

  group('num with -INF value', () {
    var data = double.negativeInfinity;
    var serialized = '-INF';
    var specifiedType = const FullType(num);

    test('can be serialized', () {
      expect(serializers.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized, specifiedType: specifiedType),
          data);
    });
  });

  group('num with INF value', () {
    var data = double.infinity;
    var serialized = 'INF';
    var specifiedType = const FullType(num);

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
