// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'build_status.g.dart';

class BuildStatus extends EnumClass {
  static const BuildStatus started = _$started;
  static const BuildStatus succeeded = _$succeeded;
  static const BuildStatus failed = _$failed;

  static Serializer<BuildStatus> get serializer => _$buildStatusSerializer;

  const BuildStatus._(String name) : super(name);
  static BuildStatus valueOf(String name) => _$valueOf(name);
  static BuiltSet<BuildStatus> get values => _$values;
}

/// The build result for a single target.
abstract class BuildResult {
  BuildStatus get status;
  String get target;
  @nullable
  String get buildId;
  @nullable
  String get error;
  @nullable
  bool get isCached;
}

abstract class DefaultBuildResult
    implements
        BuildResult,
        Built<DefaultBuildResult, DefaultBuildResultBuilder> {
  static Serializer<DefaultBuildResult> get serializer =>
      _$defaultBuildResultSerializer;

  factory DefaultBuildResult([void Function(DefaultBuildResultBuilder) b]) =
      _$DefaultBuildResult;

  DefaultBuildResult._();
}

/// The group of [BuildResult]s for a single build done by the daemon.
///
/// Since the daemon can build multiple targets in parallel, the results are
/// grouped together.
///
/// Build results will only be provided if the client has registered a target
/// that was built.
abstract class BuildResults
    implements Built<BuildResults, BuildResultsBuilder> {
  static Serializer<BuildResults> get serializer => _$buildResultsSerializer;

  factory BuildResults([Function(BuildResultsBuilder b) updates]) =
      _$BuildResults;

  BuildResults._();

  BuiltList<BuildResult> get results;
}
