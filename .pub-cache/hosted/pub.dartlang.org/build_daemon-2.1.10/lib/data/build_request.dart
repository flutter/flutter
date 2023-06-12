// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'build_request.g.dart';

/// A request to trigger a build of all registered build targets.
abstract class BuildRequest
    implements Built<BuildRequest, BuildRequestBuilder> {
  static Serializer<BuildRequest> get serializer => _$buildRequestSerializer;

  factory BuildRequest([Function(BuildRequestBuilder b) updates]) =
      _$BuildRequest;

  BuildRequest._();
}
