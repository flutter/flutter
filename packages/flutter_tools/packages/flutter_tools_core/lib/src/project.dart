// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// Returns whether [uri] is a valid absolute `file:` directory URI ending with
/// a trailing slash (`/`).
@internal
bool isValidDirectoryUri(Uri uri) =>
    uri.isScheme('file') && uri.hasAbsolutePath && uri.path.endsWith('/');

/// Serializable representation of a Flutter project and its manifest metadata
/// for tool extensions.
@immutable
class ExtensionFlutterProject {
  ExtensionFlutterProject({
    required this.appName,
    required this.buildDirectory,
    required this.directory,
    this.appVersion,
    this.dependencies = const <String>{},
    this.isEmpty = false,
    this.isModule = false,
    this.isPlugin = false,
    this.workspace = const <String>[],
  }) : assert(
         isValidDirectoryUri(buildDirectory),
         'buildDirectory must be an absolute file:// directory URI ending with "/": $buildDirectory',
       ),
       assert(
         isValidDirectoryUri(directory),
         'directory must be an absolute file:// directory URI ending with "/": $directory',
       );

  /// Deserializes an [ExtensionFlutterProject] from a JSON-serializable map.
  ///
  /// Throws a [FormatException] if required fields are missing, if any field
  /// has an invalid type, or if [buildDirectory] or [directory] are not valid
  /// trailing-slash-terminated absolute `file:` directory URIs.
  factory ExtensionFlutterProject.fromJson(Map<String, Object?> json) {
    if (json case {
      appNameKey: final String appName,
      buildDirectoryKey: final String buildDirectoryStr,
      directoryKey: final String directoryStr,
    }) {
      final Uri? buildDirectoryUri = Uri.tryParse(buildDirectoryStr);
      final Uri? directoryUri = Uri.tryParse(directoryStr);
      if (buildDirectoryUri != null &&
          isValidDirectoryUri(buildDirectoryUri) &&
          directoryUri != null &&
          isValidDirectoryUri(directoryUri)) {
        final String? appVersion = switch (json[appVersionKey]) {
          final String value => value,
          null => null,
          _ => throw FormatException('Invalid ExtensionFlutterProject JSON: $json'),
        };
        final bool isEmpty = switch (json[isEmptyKey]) {
          final bool value => value,
          null => false,
          _ => throw FormatException('Invalid ExtensionFlutterProject JSON: $json'),
        };
        final bool isModule = switch (json[isModuleKey]) {
          final bool value => value,
          null => false,
          _ => throw FormatException('Invalid ExtensionFlutterProject JSON: $json'),
        };
        final bool isPlugin = switch (json[isPluginKey]) {
          final bool value => value,
          null => false,
          _ => throw FormatException('Invalid ExtensionFlutterProject JSON: $json'),
        };
        final Set<String> dependencies = switch (json[dependenciesKey]) {
          final Iterable<Object?> items => <String>{
            for (final Object? item in items)
              switch (item) {
                final String value => value,
                _ => throw FormatException('Invalid ExtensionFlutterProject JSON: $json'),
              },
          },
          null => const <String>{},
          _ => throw FormatException('Invalid ExtensionFlutterProject JSON: $json'),
        };
        final List<String> workspace = switch (json[workspaceKey]) {
          final Iterable<Object?> items => <String>[
            for (final Object? item in items)
              switch (item) {
                final String value => value,
                _ => throw FormatException('Invalid ExtensionFlutterProject JSON: $json'),
              },
          ],
          null => const <String>[],
          _ => throw FormatException('Invalid ExtensionFlutterProject JSON: $json'),
        };
        return ExtensionFlutterProject(
          appName: appName,
          buildDirectory: buildDirectoryUri,
          directory: directoryUri,
          appVersion: appVersion,
          dependencies: dependencies,
          isEmpty: isEmpty,
          isModule: isModule,
          isPlugin: isPlugin,
          workspace: workspace,
        );
      }
    }
    throw FormatException('Invalid ExtensionFlutterProject JSON: $json');
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

  /// The absolute directory URI of the project's build directory (e.g.,
  /// `file:///path/to/my_app/build/`), trailing-slash terminated.
  final Uri buildDirectory;

  /// Direct dependency package names declared in the project's `pubspec.yaml` file.
  final Set<String> dependencies;

  /// The absolute root directory URI of the Flutter project (e.g.,
  /// `file:///path/to/my_app/`), trailing-slash terminated.
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
    workspaceKey: workspace.toList(),
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
