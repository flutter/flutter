// Copyright (c) 2019, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:built_value/serializer.dart';
import 'package:test/test.dart';

void main() {
  var serializers = Serializers();

  group('RegExp with known specifiedType', () {
    var data = RegExp(r'\d+, [A-Z](foo)?');
    var serialized = r'\d+, [A-Z](foo)?';
    var specifiedType = const FullType(RegExp);

    test('can be serialized', () {
      expect(serializers.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized, specifiedType: specifiedType),
          data);
    });
  });

  group('String with unknown specifiedType', () {
    var data = RegExp('testing, testing');
    var serialized =
        json.decode(json.encode(['RegExp', 'testing, testing'])) as Object;
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
