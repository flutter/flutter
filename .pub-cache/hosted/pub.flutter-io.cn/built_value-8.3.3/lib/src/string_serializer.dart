// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

class StringSerializer implements PrimitiveSerializer<String> {
  final bool structured = false;
  @override
  final Iterable<Type> types = BuiltList<Type>([String]);
  @override
  final String wireName = 'String';

  @override
  Object serialize(Serializers serializers, String string,
      {FullType specifiedType = FullType.unspecified}) {
    return string;
  }

  @override
  String deserialize(Serializers serializers, Object? serialized,
      {FullType specifiedType = FullType.unspecified}) {
    return serialized as String;
  }
}
