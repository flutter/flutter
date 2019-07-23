// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Tool extensions for interfacing with the flutter build process.
library build;

import 'package:meta/meta.dart';

import '../convert.dart';
import 'app.dart';
import 'extension.dart';

/// The build variant of the dart comnponents of the flutter application.
class DartBuildMode implements Serializable {
  const DartBuildMode._(this._value);

  /// Create a [DartBuildMode] object from its json encoded equivalent.
  ///
  /// Throws an [ArgumentError] if an invalid value is provided.
  factory DartBuildMode.fromJson(int value) {
    switch (value) {
      case 0:
        return debug;
      case 1:
        return profile;
      case 2:
        return release;
    }
    throw ArgumentError.value(value);
  }

  /// Dart components are built with a debug snapshot and will run in the VM.
  ///
  /// Both assertions and the vmservice are enabled in this mode.
  static const DartBuildMode debug = DartBuildMode._(0);

  /// Dart components are built with a profile snapshot and will run AOT.
  ///
  /// Assertions are disabled in this mode. unlike [release], the vmservice
  /// is still enabled but has reduced functionality. Performance will be
  /// closer to a release application.
  static const DartBuildMode profile = DartBuildMode._(1);

  /// Dart components are built with a release snapshot and will run AOT.
  ///
  /// Both assertions and the vmservice are disabled in this mode.
  static const DartBuildMode release = DartBuildMode._(2);

  final int _value;

  @override
  Object toJson() => _value;

  @override
  String toString() => json.encode(toJson());
}

/// Dart specific information about the application to be built.
class BuildInfo implements Serializable {
  /// Create a new [BuildInfo].
  ///
  /// All values must not be null.
  const BuildInfo({
    @required this.dartBuildMode,
    @required this.targetFile,
    @required this.projectRoot,
  }) : assert(dartBuildMode != null),
       assert(targetFile != null),
       assert(projectRoot != null);

  /// Create a new [BuildInfo] from a json object.
  factory BuildInfo.fromJson(Map<String, Object> json) {
    final DartBuildMode dartBuildMode = DartBuildMode.fromJson(json['dartBuildMode']);
    final Uri targetFile = Uri.parse(json['targetFile']);
    final Uri projectRoot = Uri.parse(json['projectRoot']);
    return BuildInfo(
      dartBuildMode: dartBuildMode,
      targetFile: targetFile,
      projectRoot: projectRoot,
    );
  }

  /// The mode that the dart components are built in.
  final DartBuildMode dartBuildMode;

  /// The entrypoint file the dart components are built with.
  ///
  /// This value is provided as a file Uri.
  final Uri targetFile;

  /// The root of the flutter project that is being built.
  ///
  /// This value is provided as a file Uri.
  final Uri projectRoot;

  @override
  Object toJson() {
    return <String, Object>{
      'dartBuildMode': dartBuildMode.toJson(),
      'targetFile': targetFile.toString(),
      'projectRoot': projectRoot,
    };
  }
}

/// A requested build output location.
class BuildOutputRequest implements Serializable {
  /// Create a new [BuildOutputRequest].
  ///
  /// [outputDirectory] must not be null.
  const BuildOutputRequest({
    @required this.outputDirectory,
    this.ignoreCache = false,
  }) : assert(outputDirectory != null);

  /// Create a new [BuildOutputRequest] from a json object.
  factory BuildOutputRequest.fromJson(Map<String, Object> json) {
    final Uri outputDirectory = json['outputDirectory'];
    final bool ignoreCache = json['ignoreCache'];
    return BuildOutputRequest(
      ignoreCache: ignoreCache,
      outputDirectory: outputDirectory,
    );
  }

  /// The output directory where dart and flutter assets are placed.
  final Uri outputDirectory;

  /// Whether to ignore the tools build cache.
  ///
  /// Defaults to false if not set. Setting this value to true may result
  /// in significantly slower incremental builds.
  final bool ignoreCache;

  @override
  Object toJson() {
    return <String, Object>{
      'outputDirectory': outputDirectory.toString(),
      'ignoreCache': ignoreCache,
    };
  }
}

/// Functionality related to building applications.
abstract class BuildDomain extends Domain {
  /// The tool has requested that an application be built.
  ///
  /// The correct configuration for the build is provided in [buildInfo].
  /// Deviation from this, such as producing a debug application when
  /// a release application is requested, may lead to build and run
  /// failures.
  Future<ApplicationBundle> buildApp(BuildInfo buildInfo);
}
