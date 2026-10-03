// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// Representation of a custom build target provided by a tool extension.
@immutable
class ExtensionBuildTarget {
  const ExtensionBuildTarget({
    required this.description,
    required this.name,
    required this.targetPlatform,
  });

  /// Deserializes an [ExtensionBuildTarget] from a JSON-serializable map.
  factory ExtensionBuildTarget.fromJson(Map<String, Object?> json) {
    return ExtensionBuildTarget(
      description: switch (json[descriptionKey]) {
        final String value => value,
        _ => '',
      },
      name: switch (json[nameKey]) {
        final String value => value,
        _ => '',
      },
      targetPlatform: switch (json[targetPlatformKey]) {
        final String value => value,
        _ => '',
      },
    );
  }

  /// Map key for [description].
  static const String descriptionKey = 'description';

  /// Map key for [name].
  static const String nameKey = 'name';

  /// Map key for [targetPlatform].
  static const String targetPlatformKey = 'targetPlatform';

  /// Deserializes a list of [ExtensionBuildTarget] objects from RPC response data.
  static List<ExtensionBuildTarget> listFromJson(Object? rpcResult) {
    if (rpcResult case final List<Object?> list) {
      return <ExtensionBuildTarget>[
        for (final item in list)
          if (item case final Map<String, Object?> map)
            ExtensionBuildTarget.fromJson(map)
          else if (item case final Map<Object?, Object?> map)
            ExtensionBuildTarget.fromJson(map.cast<String, Object?>()),
      ];
    }
    return const <ExtensionBuildTarget>[];
  }

  /// Description of what this target builds.
  final String description;

  /// The name of this build target (e.g. `'custom-apk'`).
  final String name;

  /// The target platform string (e.g. `'android-arm64'`).
  final String targetPlatform;

  /// Serializes the build target to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    descriptionKey: description,
    nameKey: name,
    targetPlatformKey: targetPlatform,
  };

  @override
  String toString() =>
      'ExtensionBuildTarget(name: $name, targetPlatform: $targetPlatform, description: $description)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionBuildTarget &&
            other.description == description &&
            other.name == name &&
            other.targetPlatform == targetPlatform);
  }

  @override
  int get hashCode => Object.hash(description, name, targetPlatform);
}

/// Representation of a build result returned by a tool extension.
@immutable
class ExtensionBuildResult {
  const ExtensionBuildResult({required this.success, this.errorMessage});

  /// Deserializes an [ExtensionBuildResult] from a JSON-serializable map.
  factory ExtensionBuildResult.fromJson(Map<String, Object?> json) {
    return ExtensionBuildResult(
      success: switch (json[successKey]) {
        final bool value => value,
        _ => false,
      },
      errorMessage: switch (json[errorMessageKey]) {
        final String value => value,
        _ => null,
      },
    );
  }

  /// Map key for [errorMessage].
  static const String errorMessageKey = 'errorMessage';

  /// Map key for [success].
  static const String successKey = 'success';

  /// Whether the build succeeded.
  final bool success;

  /// Optional error message if the build failed.
  final String? errorMessage;

  /// Serializes the build result to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    successKey: success,
    errorMessageKey: ?errorMessage,
  };

  @override
  String toString() => 'ExtensionBuildResult(success: $success, errorMessage: $errorMessage)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionBuildResult &&
            other.success == success &&
            other.errorMessage == errorMessage);
  }

  @override
  int get hashCode => Object.hash(success, errorMessage);
}
