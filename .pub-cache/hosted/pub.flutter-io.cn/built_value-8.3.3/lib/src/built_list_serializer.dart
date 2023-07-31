// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

class BuiltListSerializer implements StructuredSerializer<BuiltList> {
  final bool structured = true;
  @override
  final Iterable<Type> types =
      BuiltList<Type>([BuiltList, BuiltList<Object>().runtimeType]);
  @override
  final String wireName = 'list';

  @override
  Iterable<Object?> serialize(Serializers serializers, BuiltList builtList,
      {FullType specifiedType = FullType.unspecified}) {
    var isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);

    var elementType = specifiedType.parameters.isEmpty
        ? FullType.unspecified
        : specifiedType.parameters[0];

    return builtList
        .map((item) => serializers.serialize(item, specifiedType: elementType));
  }

  @override
  BuiltList deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) {
    var isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;

    var elementType = specifiedType.parameters.isEmpty
        ? FullType.unspecified
        : specifiedType.parameters[0];

    var result = isUnderspecified
        ? ListBuilder<Object>()
        : serializers.newBuilder(specifiedType) as ListBuilder;

    result.replace(serialized.map(
        (item) => serializers.deserialize(item, specifiedType: elementType)));
    return result.build();
  }
}
