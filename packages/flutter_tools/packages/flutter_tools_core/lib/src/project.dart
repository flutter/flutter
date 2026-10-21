// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'json_utils.dart';

/// Validation helpers for file system [Uri]s exchanged over the tool
/// extension protocol.
extension ExtensionUriValidation on Uri? {
  /// Whether this URI is a non-null, absolute `file:` directory URI ending
  /// with a trailing slash (`/`).
  bool get isValidDirectoryUri => switch (this) {
    final Uri uri => uri.isScheme('file') && uri.hasAbsolutePath && uri.path.endsWith('/'),
    null => false,
  };
}

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
  }) {
    if (!buildDirectory.isValidDirectoryUri) {
      throw ArgumentError.value(
        buildDirectory,
        'buildDirectory',
        'Must be an absolute file:// directory URI ending with "/".',
      );
    }
    if (!directory.isValidDirectoryUri) {
      throw ArgumentError.value(
        directory,
        'directory',
        'Must be an absolute file:// directory URI ending with "/".',
      );
    }
  }

  /// Deserializes an [ExtensionFlutterProject] from a JSON-serializable map.
  ///
  /// Throws a [FormatException] if required fields are missing, if any field
  /// has an invalid type, or if [buildDirectory] or [directory] are not valid
  /// trailing-slash-terminated absolute `file:` directory URIs.
  factory ExtensionFlutterProject.fromJson(Map<String, Object?> json) {
    return ExtensionFlutterProject(
      appName: json.requiredField<String>(appNameKey),
      buildDirectory: _parseDirectoryUri(json, buildDirectoryKey),
      directory: _parseDirectoryUri(json, directoryKey),
      appVersion: json.nullableField<String>(appVersionKey),
      dependencies: json.stringIterable(dependenciesKey).toSet(),
      isEmpty: json.optionalField<bool>(isEmptyKey, defaultValue: false),
      isModule: json.optionalField<bool>(isModuleKey, defaultValue: false),
      isPlugin: json.optionalField<bool>(isPluginKey, defaultValue: false),
      workspace: json.stringIterable(workspaceKey).toList(),
    );
  }

  static Uri _parseDirectoryUri(Map<String, Object?> json, String key) {
    final String rawUri = json.requiredField<String>(key);
    final Uri? uri = Uri.tryParse(rawUri);
    if (uri != null && uri.isValidDirectoryUri) {
      return uri;
    }
    throw FormatException('Invalid "$key": expected trailing-slash-terminated absolute file: URI.');
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
