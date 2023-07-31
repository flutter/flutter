// Copyright (c) 2017, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/async_serializer.dart';
import 'package:built_value/serializer.dart';
import 'package:test/test.dart';

void main() {
  group('BuiltList', () {
    var data = BuiltList<int>([1, 2, 3]);
    var specifiedType = const FullType(BuiltList, [FullType(int)]);
    var serializers = (Serializers().toBuilder()
          ..addBuilderFactory(specifiedType, () => ListBuilder<int>()))
        .build();
    var serialized = json.decode(json.encode([1, 2, 3])) as Iterable;

    test('can be deserialized asynchronously', () async {
      final deserialized = await BuiltListAsyncDeserializer()
          .deserialize(serializers, serialized, specifiedType: specifiedType)
          .toList();

      expect(deserialized, data);
    });
  });
}
