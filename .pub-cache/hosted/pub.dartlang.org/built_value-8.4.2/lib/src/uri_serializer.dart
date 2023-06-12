// Copyright (c) 2017, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

class UriSerializer implements PrimitiveSerializer<Uri> {
  final bool structured = false;
  @override
  final Iterable<Type> types = BuiltList<Type>([
    Uri,
    // `Uri` is just an interface. Need to record actual implementation types
    // here. This is a `_SimpleUri`:
    Uri.parse('http://example.com').runtimeType,
    // And this is a `_Uri`:
    Uri.parse('http://example.com:').runtimeType,
  ]);
  @override
  final String wireName = 'Uri';

  @override
  Object serialize(Serializers serializers, Uri uri,
      {FullType specifiedType = FullType.unspecified}) {
    return uri.toString();
  }

  @override
  Uri deserialize(Serializers serializers, Object? serialized,
      {FullType specifiedType = FullType.unspecified}) {
    return Uri.parse(serialized as String);
  }
}
