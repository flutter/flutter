// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// Serializable representation of a Flutter project and its manifest metadata
/// for tool extensions.
@immutable
class ExtensionFlutterProject {
  const ExtensionFlutterProject({
    required this.appName,
    required this.buildDirectory,
    required this.directory,
    this.appVersion,
    this.dependencies = const <String>{},
    this.isEmpty = false,
    this.isModule = false,
    this.isPlugin = false,
    this.workspace = const <String>[],
  });

  /// Deserializes an [ExtensionFlutterProject] from a JSON-serializable map.
  factory ExtensionFlutterProject.fromJson(Map<String, Object?> json) {
    return ExtensionFlutterProject(
      appName: switch (json[appNameKey]) {
        final String value => value,
        _ => '',
      },
      buildDirectory: switch (json[buildDirectoryKey]) {
        final String value => Uri.parse(value),
        _ => Uri(),
      },
      directory: switch (json[directoryKey]) {
        final String value => Uri.parse(value),
        _ => Uri(),
      },
      appVersion: switch (json[appVersionKey]) {
        final String value => value,
        _ => null,
      },
      dependencies: switch (json[dependenciesKey]) {
        final Iterable<Object?> items => <String>{
          for (final Object? item in items)
            if (item case final String value) value,
        },
        _ => const <String>{},
      },
      isEmpty: json[isEmptyKey] == true,
      isModule: json[isModuleKey] == true,
      isPlugin: json[isPluginKey] == true,
      workspace: switch (json[workspaceKey]) {
        final Iterable<Object?> items => <String>[
          for (final Object? item in items)
            if (item case final String value) value,
        ],
        _ => const <String>[],
      },
    );
  }

  /// Map key for [appName].
  static const String appNameKey = 'appName';

  /// Map key for [appVersion].
  static const String appVersionKey = 'appVersion';

  /// Map key for [buildDirectory].
  static const String buildDirectoryKey = 'buildDirectory';

  /// Map key for [dependencies].
  static const String dependenciesKey = 'dependencies';

  /// Map key for [directory].
  static const String directoryKey = 'directory';

  /// Map key for [isEmpty].
  static const String isEmptyKey = 'isEmpty';

  /// Map key for [isModule].
  static const String isModuleKey = 'isModule';

  /// Map key for [isPlugin].
  static const String isPluginKey = 'isPlugin';

  /// Map key for [workspace].
  static const String workspaceKey = 'workspace';

  /// The `name` property in the project's `pubspec.yaml` file.
  final String appName;

  /// The `version` property in the project's `pubspec.yaml` file, if valid.
  final String? appVersion;

  /// The location of the project's build directory.
  final Uri buildDirectory;

  /// Direct dependency package names declared in the project's `pubspec.yaml` file.
  final Set<String> dependencies;

  /// The root directory of the Flutter project.
  final Uri directory;

  /// Whether the project's `pubspec.yaml` file is missing or empty.
  final bool isEmpty;

  /// Whether this project is a Flutter module project.
  final bool isModule;

  /// Whether this project is a Flutter plugin project.
  final bool isPlugin;

  /// Workspace member glob entries declared in the project's `pubspec.yaml` file.
  final List<String> workspace;

  /// Serializes the project metadata to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    appNameKey: appName,
    appVersionKey: ?appVersion,
    buildDirectoryKey: buildDirectory.toString(),
    dependenciesKey: dependencies.toList(),
    directoryKey: directory.toString(),
    isEmptyKey: isEmpty,
    isModuleKey: isModule,
    isPluginKey: isPlugin,
    workspaceKey: workspace,
  };

  @override
  String toString() =>
      'ExtensionFlutterProject(appName: $appName, appVersion: $appVersion, '
      'directory: $directory, buildDirectory: $buildDirectory, '
      'isEmpty: $isEmpty, isModule: $isModule, isPlugin: $isPlugin, '
      'dependencies: $dependencies, workspace: $workspace)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! ExtensionFlutterProject) {
      return false;
    }
    if (appName != other.appName ||
        appVersion != other.appVersion ||
        buildDirectory != other.buildDirectory ||
        directory != other.directory ||
        isEmpty != other.isEmpty ||
        isModule != other.isModule ||
        isPlugin != other.isPlugin ||
        dependencies.length != other.dependencies.length ||
        workspace.length != other.workspace.length) {
      return false;
    }
    if (!dependencies.containsAll(other.dependencies)) {
      return false;
    }
    for (var i = 0; i < workspace.length; i++) {
      if (workspace[i] != other.workspace[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    appName,
    appVersion,
    buildDirectory,
    Object.hashAllUnordered(dependencies),
    directory,
    isEmpty,
    isModule,
    isPlugin,
    Object.hashAll(workspace),
  );
}
