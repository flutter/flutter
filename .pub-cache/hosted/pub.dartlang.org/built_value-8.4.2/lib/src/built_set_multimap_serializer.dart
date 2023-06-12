// Copyright (c) 2016, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

class BuiltSetMultimapSerializer
    implements StructuredSerializer<BuiltSetMultimap> {
  final bool structured = true;
  @override
  final Iterable<Type> types = BuiltSet<Type>([BuiltSetMultimap]);
  @override
  final String wireName = 'setMultimap';

  @override
  Iterable<Object?> serialize(
      Serializers serializers, BuiltSetMultimap builtSetMultimap,
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
    for (var key in builtSetMultimap.keys) {
      result.add(serializers.serialize(key, specifiedType: keyType));
      result.add(builtSetMultimap[key]!
          .map(
              (value) => serializers.serialize(value, specifiedType: valueType))
          .toList());
    }
    return result;
  }

  @override
  BuiltSetMultimap deserialize(Serializers serializers, Iterable serialized,
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
        ? SetMultimapBuilder<Object, Object>()
        : serializers.newBuilder(specifiedType) as SetMultimapBuilder;

    if (serialized.length % 2 == 1) {
      throw ArgumentError('odd length');
    }

    for (var i = 0; i != serialized.length; i += 2) {
      final key = serializers.deserialize(serialized.elementAt(i),
          specifiedType: keyType);
      final values = serialized.elementAt(i + 1).map(
          (value) => serializers.deserialize(value, specifiedType: valueType));
      for (var value in values) {
        result.add(key, value);
      }
    }

    return result.build();
  }
}
