// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

class BuiltMapSerializer implements StructuredSerializer<BuiltMap> {
  final bool structured = true;
  @override
  final Iterable<Type> types =
      BuiltList<Type>([BuiltMap, BuiltMap<Object, Object>().runtimeType]);
  @override
  final String wireName = 'map';

  @override
  Iterable<Object?> serialize(Serializers serializers, BuiltMap builtMap,
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
    for (var key in builtMap.keys) {
      result.add(serializers.serialize(key, specifiedType: keyType));
      final value = builtMap[key];
      result.add(serializers.serialize(value, specifiedType: valueType));
    }
    return result;
  }

  @override
  BuiltMap deserialize(Serializers serializers, Iterable serialized,
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
        ? MapBuilder<Object, Object>()
        : serializers.newBuilder(specifiedType) as MapBuilder;

    if (serialized.length % 2 == 1) {
      throw ArgumentError('odd length');
    }

    for (var i = 0; i != serialized.length; i += 2) {
      final key = serializers.deserialize(serialized.elementAt(i),
          specifiedType: keyType);
      final value = serializers.deserialize(serialized.elementAt(i + 1),
          specifiedType: valueType);
      result[key] = value;
    }

    return result.build();
  }
}
