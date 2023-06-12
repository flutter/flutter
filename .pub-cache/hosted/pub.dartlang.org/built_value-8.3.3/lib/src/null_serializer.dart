// Copyright (c) 2021, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

class NullSerializer implements PrimitiveSerializer<Null> {
  final bool structured = false;
  @override
  final Iterable<Type> types = BuiltList<Type>([Null]);
  @override
  final String wireName = 'Null';

  @override
  Object serialize(Serializers serializers, Null value,
      {FullType specifiedType = FullType.unspecified}) {
    // Never actually called; `built_json_serializer.dart` handles nulls.
    throw UnimplementedError();
  }

  @override
  Null deserialize(Serializers serializers, Object? serialized,
      {FullType specifiedType = FullType.unspecified}) {
    // Never actually called; `built_json_serializer.dart` handles nulls.
    throw UnimplementedError();
  }
}
