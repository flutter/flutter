// Copyright (c) 2017, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';

class JsonObjectSerializer implements PrimitiveSerializer<JsonObject> {
  final bool structured = false;
  @override
  final Iterable<Type> types = BuiltList<Type>([
    JsonObject,
    BoolJsonObject,
    ListJsonObject,
    MapJsonObject,
    NumJsonObject,
    StringJsonObject,
  ]);
  @override
  final String wireName = 'JsonObject';

  @override
  Object serialize(Serializers serializers, JsonObject jsonObject,
      {FullType specifiedType = FullType.unspecified}) {
    return jsonObject.value;
  }

  @override
  JsonObject deserialize(Serializers serializers, Object? serialized,
      {FullType specifiedType = FullType.unspecified}) {
    return JsonObject(serialized);
  }
}
