// Copyright (c) 2021, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:test/test.dart';

void main() {
  group('Missing builder factory', () {
    var data = BuiltList<int>([1, 2, 3]);
    var specifiedType = const FullType(BuiltList, [FullType(int)]);
    var serializers = Serializers();
    var serialized = json.decode(json.encode([1, 2, 3])) as Object;

    test('serialize throws with nice message', () {
      expect(
          () => serializers.serialize(data, specifiedType: specifiedType),
          throwsA(predicate((e) =>
              e.toString().contains('No builder factory for BuiltList<int>'))));
    });

    test('deserialize throws with nice message', () {
      expect(
          () =>
              serializers.deserialize(serialized, specifiedType: specifiedType),
          throwsA(predicate((e) =>
              e.toString().contains('No builder factory for BuiltList<int>'))));
    });
  });
}
