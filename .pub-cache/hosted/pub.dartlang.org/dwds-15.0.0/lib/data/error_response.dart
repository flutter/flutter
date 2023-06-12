// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'error_response.g.dart';

abstract class ErrorResponse
    implements Built<ErrorResponse, ErrorResponseBuilder> {
  static Serializer<ErrorResponse> get serializer => _$errorResponseSerializer;

  factory ErrorResponse([Function(ErrorResponseBuilder) updates]) =
      _$ErrorResponse;

  ErrorResponse._();

  String get error;

  String get stackTrace;
}
