// Copyright (c) 2017, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/src/double_serializer.dart';

class NumSerializer implements PrimitiveSerializer<num> {
  final bool structured = false;
  @override
  final Iterable<Type> types = BuiltList<Type>([num]);
  @override
  final String wireName = 'num';

  @override
  Object serialize(Serializers serializers, num number,
      {FullType specifiedType = FullType.unspecified}) {
    if (number.isNaN) {
      return DoubleSerializer.nan;
    } else if (number.isInfinite) {
      return number.isNegative
          ? DoubleSerializer.negativeInfinity
          : DoubleSerializer.infinity;
    } else {
      return number;
    }
  }

  @override
  num deserialize(Serializers serializers, Object? serialized,
      {FullType specifiedType = FullType.unspecified}) {
    if (serialized == DoubleSerializer.nan) {
      return double.nan;
    } else if (serialized == DoubleSerializer.negativeInfinity) {
      return double.negativeInfinity;
    } else if (serialized == DoubleSerializer.infinity) {
      return double.infinity;
    } else {
      return serialized as num;
    }
  }
}
