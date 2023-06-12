// Copyright (c) 2016, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

class BuiltListMultimapSerializer
    implements StructuredSerializer<BuiltListMultimap> {
  final bool structured = true;
  @override
  final Iterable<Type> types = BuiltList<Type>(
      [BuiltListMultimap, BuiltListMultimap<Object, Object>().runtimeType]);
  @override
  final String wireName = 'listMultimap';

  @override
  Iterable<Object?> serialize(
      Serializers serializers, BuiltListMultimap builtListMultimap,
      {FullType specifiedType = FullType.unspecified}) {
    var isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);

    var keyType = specifiedType.parameters.isEmpty
        ? FullType.unspecified
        : specifiedType.parameters[0];
    var valueType = specifiedType.parameters.isEmpty
        ? FullType.unspecified
        : specifiedType.parameters[1];

    var result = <Object?>[];
    for (var key in builtListMultimap.keys) {
      result.add(serializers.serialize(key, specifiedType: keyType));
      result.add(builtListMultimap[key]
          .map(
              (value) => serializers.serialize(value, specifiedType: valueType))
          .toList());
    }
    return result;
  }

  @override
  BuiltListMultimap deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    var isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;

    var keyType = specifiedType.parameters.isEmpty
        ? FullType.unspecified
        : specifiedType.parameters[0];
    var valueType = specifiedType.parameters.isEmpty
        ? FullType.unspecified
        : specifiedType.parameters[1];

    var result = isUnderspecified
        ? ListMultimapBuilder<Object, Object>()
        : serializers.newBuilder(specifiedType) as ListMultimapBuilder;

    if (serialized.length % 2 == 1) {
      throw ArgumentError('odd length');
    }

    for (var i = 0; i != serialized.length; i += 2) {
      final key = serializers.deserialize(serialized.elementAt(i),
          specifiedType: keyType);
      final values = (serialized.elementAt(i + 1) as Iterable<Object?>).map(
          (value) => serializers.deserialize(value, specifiedType: valueType));
      for (var value in values) {
        result.add(key, value);
      }
    }

    return result.build();
  }
}
