// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'build_target.dart';

part 'build_target_request.g.dart';

/// Registers a build target to be built by the daemon.
///
/// Note this does not trigger a build.
abstract class BuildTargetRequest
    implements Built<BuildTargetRequest, BuildTargetRequestBuilder> {
  static Serializer<BuildTargetRequest> get serializer =>
      _$buildTargetRequestSerializer;

  factory BuildTargetRequest([Function(BuildTargetRequestBuilder b) updates]) =
      _$BuildTargetRequest;

  BuildTargetRequest._();

  BuildTarget get target;
}
