// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

// TODO(bkonyi): Include ExtensionFlutterProject on CleanEnvironment once
// https://github.com/flutter/flutter/pull/193749 lands so extensions can
// inspect project metadata (such as isModule or isPlugin) during clean.

/// Environment context provided to tool extensions during `flutter clean`.
///
/// The host `flutter_tools` constructs a [CleanEnvironment] with the absolute
/// directory URIs for the project root and build output directory and sends it
/// to active extensions implementing `CleanService`.
@immutable
class CleanEnvironment {
  const CleanEnvironment({required this.buildDir, required this.projectRoot});

  /// Deserializes a [CleanEnvironment] from a JSON-serializable map.
  ///
  /// Throws a [FormatException] if required fields are missing or are not
  /// valid trailing-slash-terminated absolute `file:` directory URIs.
  factory CleanEnvironment.fromJson(Map<String, Object?> json) {
    if (json case {
      projectRootKey: final String projectRootStr,
      buildDirKey: final String buildDirStr,
    }) {
      final Uri? projectRootUri = _parseDirectoryUri(projectRootStr);
      final Uri? buildDirUri = _parseDirectoryUri(buildDirStr);
      if (projectRootUri != null && buildDirUri != null) {
        return CleanEnvironment(buildDir: buildDirUri, projectRoot: projectRootUri);
      }
    }
    throw FormatException('Invalid CleanEnvironment JSON: $json');
  }

  static Uri? _parseDirectoryUri(String rawUri) {
    final Uri? uri = Uri.tryParse(rawUri);
    if (uri != null && uri.isScheme('file') && uri.hasAbsolutePath && uri.path.endsWith('/')) {
      return uri;
    }
    return null;
  }

  /// Map key for [buildDir].
  static const String buildDirKey = 'buildDir';

  /// Map key for [projectRoot].
  static const String projectRootKey = 'projectRoot';

  /// The absolute build directory URI of the Flutter project being cleaned
  /// (e.g., `file:///path/to/my_app/build/`), trailing-slash terminated and
  /// honoring any custom `flutter config --build-dir` setting.
  final Uri buildDir;

  /// The absolute root directory URI of the Flutter project being cleaned
  /// (e.g., `file:///path/to/my_app/`), trailing-slash terminated.
  final Uri projectRoot;

  /// Serializes the clean environment to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    projectRootKey: projectRoot.toString(),
    buildDirKey: buildDir.toString(),
  };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CleanEnvironment &&
            other.projectRoot == projectRoot &&
            other.buildDir == buildDir);
  }

  @override
  int get hashCode => Object.hash(projectRoot, buildDir);

  @override
  String toString() => 'CleanEnvironment(projectRoot: $projectRoot, buildDir: $buildDir)';
}
