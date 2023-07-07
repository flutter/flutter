// Copyright (c) 2016, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:test/test.dart';

void main() {
  group('BuiltSetMultimap with known specifiedType and correct builder', () {
    var data = BuiltSetMultimap<int, String>({
      1: ['one'],
      2: ['two'],
      3: ['three', '3hree']
    });
    var specifiedType =
        const FullType(BuiltSetMultimap, [FullType(int), FullType(String)]);
    var serializers = (Serializers().toBuilder()
          ..addBuilderFactory(
              specifiedType, () => SetMultimapBuilder<int, String>()))
        .build();
    var serialized = json.decode(json.encode([
      1,
      ['one'],
      2,
      ['two'],
      3,
      ['three', '3hree']
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized, specifiedType: specifiedType),
          data);
    });

    test('keeps generic type when deserialized', () {
      expect(
          serializers
              .deserialize(serialized, specifiedType: specifiedType)
              .runtimeType,
          BuiltSetMultimap<int, String>().runtimeType);
    });
  });
}
