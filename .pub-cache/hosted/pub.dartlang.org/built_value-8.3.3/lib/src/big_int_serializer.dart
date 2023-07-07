// Copyright (c) 2018, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

class BigIntSerializer implements PrimitiveSerializer<BigInt> {
  final bool structured = false;

  // [BigInt] has a private implementation type; register it via [BigInt.zero].
  @override
  final Iterable<Type> types =
      BuiltList<Type>([BigInt, BigInt.zero.runtimeType]);
  @override
  final String wireName = 'BigInt';

  @override
  Object serialize(Serializers serializers, BigInt bigInt,
      {FullType specifiedType = FullType.unspecified}) {
    return bigInt.toString();
  }

  @override
  BigInt deserialize(Serializers serializers, Object? serialized,
      {FullType specifiedType = FullType.unspecified}) {
    return BigInt.parse(serialized as String);
  }
}
