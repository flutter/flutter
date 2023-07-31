// Copyright (c) 2018, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

/// Serializer for [Duration].
///
/// [Duration] is implemented as an `int` number of microseconds, so just
/// store that `int`.
class DurationSerializer implements PrimitiveSerializer<Duration> {
  final bool structured = false;
  @override
  final Iterable<Type> types = BuiltList<Type>([Duration]);
  @override
  final String wireName = 'Duration';

  @override
  Object serialize(Serializers serializers, Duration duration,
      {FullType specifiedType = FullType.unspecified}) {
    return duration.inMicroseconds;
  }

  @override
  Duration deserialize(Serializers serializers, Object? serialized,
      {FullType specifiedType = FullType.unspecified}) {
    return Duration(microseconds: serialized as int);
  }
}
