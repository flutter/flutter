// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'run_request.g.dart';

abstract class RunRequest implements Built<RunRequest, RunRequestBuilder> {
  static Serializer<RunRequest> get serializer => _$runRequestSerializer;

  factory RunRequest([Function(RunRequestBuilder) updates]) = _$RunRequest;

  RunRequest._();
}
