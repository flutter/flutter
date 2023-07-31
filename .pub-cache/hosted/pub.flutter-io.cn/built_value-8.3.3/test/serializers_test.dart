// Copyright (c) 2019, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_value/serializer.dart';
import 'package:built_value/src/date_time_serializer.dart';
import 'package:built_value/src/int_serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:test/test.dart';

void main() {
  var serializers = Serializers();
  final moreSerializers = (serializers.toBuilder()
        ..addAll([TestSerializer()])
        ..addBuilderFactory(FullType(TestSerializer), () => null))
      .build();
  final serializersWithPlugin =
      (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();

  group(Serializers, () {
    test('exposes iterable of serializer', () {
      expect(serializers.serializers, contains(TypeMatcher<IntSerializer>()));
    });

    test('can be added to', () {
      expect(
          moreSerializers.serializers, contains(TypeMatcher<TestSerializer>()));
    });

    test('can be merged', () {
      var mergedSerializers =
          (serializers.toBuilder()..mergeAll([moreSerializers])).build();
      expect(mergedSerializers.serializers,
          contains(TypeMatcher<TestSerializer>()));
      expect(mergedSerializers.builderFactories.keys,
          contains(FullType(TestSerializer)));
    });

    test('can be merged by static method', () {
      var mergedSerializers = Serializers.merge([serializers, moreSerializers]);
      expect(mergedSerializers.serializers,
          contains(TypeMatcher<TestSerializer>()));
      expect(mergedSerializers.builderFactories.keys,
          contains(FullType(TestSerializer)));
    });

    test('provides convenience toJson method', () {
      expect(serializers.toJson(DateTimeSerializer(), DateTime.utc(2020, 1, 1)),
          '1577836800000000');
    });

    test('provides convenience fromJson method', () {
      expect(serializers.fromJson(DateTimeSerializer(), '1577836800000000'),
          DateTime.utc(2020, 1, 1));
    });

    test('serializes null int to null', () {
      expect(serializers.serialize(null, specifiedType: FullType(int)), null);
    });

    test('deserializes null int from null', () {
      expect(serializers.deserialize(null, specifiedType: FullType(int)), null);
    });

    test('serializes null int to null when plugin is installed', () {
      expect(
          serializersWithPlugin.serialize(null, specifiedType: FullType(int)),
          null);
    });

    test('deserializes null int from null when plugin is installed', () {
      expect(
          serializersWithPlugin.deserialize(null, specifiedType: FullType(int)),
          null);
    });

    test('serializes unknown type null to null', () {
      expect(serializers.serialize(null), ['Null', null]);
    });

    test('deserializes null from unknown type null', () {
      expect(serializers.deserialize(['Null', null]), null);
    });

    test('serializes unknown type null to null when plugin is installed', () {
      expect(serializersWithPlugin.serialize(null), {r'$': 'Null', '': null});
    });

    test('deserializes null from unknown type null when plugin is installed',
        () {
      expect(serializersWithPlugin.deserialize({r'$': 'Null', '': null}), null);
    });
  });
}

class TestSerializer implements PrimitiveSerializer<Object?> {
  @override
  Iterable<Type> get types => [];

  @override
  String get wireName => '';

  @override
  Object? deserialize(Serializers serializers, Object serialized,
      {FullType specifiedType = FullType.unspecified}) {
    return null;
  }

  @override
  Object serialize(Serializers serializers, Object? object,
      {FullType specifiedType = FullType.unspecified}) {
    return '';
  }
}
