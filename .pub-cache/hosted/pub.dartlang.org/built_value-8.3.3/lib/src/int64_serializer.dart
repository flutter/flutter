// Copyright (c) 2017, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:fixnum/fixnum.dart';

class Int64Serializer implements PrimitiveSerializer<Int64> {
  final bool structured = false;
  @override
  final Iterable<Type> types = BuiltList<Type>([Int64]);
  @override
  final String wireName = 'Int64';

  @override
  Object serialize(Serializers serializers, Int64 int64,
      {FullType specifiedType = FullType.unspecified}) {
    return int64.toString();
  }

  @override
  Int64 deserialize(Serializers serializers, Object? serialized,
      {FullType specifiedType = FullType.unspecified}) {
    return Int64.parseInt(serialized as String);
  }
}
