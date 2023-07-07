// Copyright (c) 2017, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_value/serializer.dart';

/// Deserializer for `BuiltList` that runs asynchronously.
///
/// If you need to deserialize large payloads without blocking, arrange that
/// the top level serialized object is a `BuiltList`. Then use this class to
/// deserialize to a [Stream] of objects.
class BuiltListAsyncDeserializer {
  Stream<Object?> deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) async* {
    var elementType = specifiedType.parameters.isEmpty
        ? FullType.unspecified
        : specifiedType.parameters[0];

    for (var item in serialized) {
      yield serializers.deserialize(item, specifiedType: elementType);
    }
  }
}
