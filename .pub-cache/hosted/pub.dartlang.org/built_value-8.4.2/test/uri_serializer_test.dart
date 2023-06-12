// Copyright (c) 2017, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:built_value/serializer.dart';
import 'package:test/test.dart';

void main() {
  var serializers = Serializers();

  group('SimpleUri with known specifiedType', () {
    var data = Uri.parse('https://github.com/google/built_value.dart');
    var serialized = 'https://github.com/google/built_value.dart';
    var specifiedType = const FullType(Uri);

    test('has expected type', () {
      expect(data.runtimeType.toString(), '_SimpleUri');
    });

    test('can be serialized', () {
      expect(serializers.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized, specifiedType: specifiedType),
          data);
    });
  });

  group('Uri with known specifiedType', () {
    var data = Uri.parse('https://github.com:0/google/built_value.dart');
    var serialized = 'https://github.com:0/google/built_value.dart';
    var specifiedType = const FullType(Uri);

    test('has expected type', () {
      expect(data.runtimeType.toString(), '_Uri');
    });

    test('can be serialized', () {
      expect(serializers.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized, specifiedType: specifiedType),
          data);
    });
  });

  group('Uri with unknown specifiedType', () {
    var data = Uri.parse('https://github.com/google/built_value.dart');
    var serialized = json.decode(
            json.encode(['Uri', 'https://github.com/google/built_value.dart']))
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
