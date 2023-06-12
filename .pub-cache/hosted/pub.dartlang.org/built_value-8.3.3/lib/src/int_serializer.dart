// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

class IntSerializer implements PrimitiveSerializer<int> {
  final bool structured = false;
  @override
  final Iterable<Type> types = BuiltList<Type>([int]);
  @override
  final String wireName = 'int';

  @override
  Object serialize(Serializers serializers, int integer,
      {FullType specifiedType = FullType.unspecified}) {
    return integer;
  }

  @override
  int deserialize(Serializers serializers, Object? serialized,
      {FullType specifiedType = FullType.unspecified}) {
    return serialized as int;
  }
}
