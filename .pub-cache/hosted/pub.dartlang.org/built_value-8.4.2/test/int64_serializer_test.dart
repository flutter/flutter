// Copyright (c) 2017, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:built_value/serializer.dart';
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  var serializers = Serializers();

  group('int64 with known specifiedType', () {
    var data = Int64.MAX_VALUE;
    var serialized = Int64.MAX_VALUE.toString();
    var specifiedType = const FullType(Int64);

    test('can be serialized', () {
      expect(serializers.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized, specifiedType: specifiedType),
          data);
    });
  });

  group('int64 with unknown specifiedType', () {
    var data = Int64.MIN_VALUE;
    var serialized = json
        .decode(json.encode(['Int64', Int64.MIN_VALUE.toString()])) as Object;
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
