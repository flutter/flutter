// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'build/constants.dart';
import 'build/source.dart';

export 'build/constants.dart';
export 'build/enums.dart';
export 'build/source.dart';
export 'build/target.dart';

/// Representation of a custom build target provided by a tool extension.
@immutable
class ExtensionBuildTarget {
  const ExtensionBuildTarget({
    required this.description,
    required this.name,
    required this.targetPlatform,
    this.dependencies = const <String>[],
    this.inputs = const <Source>[],
    this.isTopLevel = true,
    this.outputDir = kBuildDirPlaceholder,
    this.outputs = const <Source>[],
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
      dependencies: switch (json[dependenciesKey]) {
        final List<Object?> rawDependencies => <String>[
          for (final item in rawDependencies)
            if (item case final String dep) dep,
        ],
        _ => const <String>[],
      },
      inputs: switch (json[inputsKey]) {
        final List<Object?> rawInputs => <Source>[
          for (final item in rawInputs)
            if (item case final Map<String, Object?> map) Source.fromJson(map),
        ],
        _ => const <Source>[],
      },
      isTopLevel: switch (json[isTopLevelKey]) {
        final bool value => value,
        _ => true,
      },
      outputDir: switch (json[outputDirKey]) {
        final String value => value,
        _ => kBuildDirPlaceholder,
      },
      outputs: switch (json[outputsKey]) {
        final List<Object?> rawOutputs => <Source>[
          for (final item in rawOutputs)
            if (item case final Map<String, Object?> map) Source.fromJson(map),
        ],
        _ => const <Source>[],
      },
    );
  }

  /// Map key for [dependencies].
  static const String dependenciesKey = 'dependencies';

  /// Map key for [description].
  static const String descriptionKey = 'description';

  /// Map key for [inputs].
  static const String inputsKey = 'inputs';

  /// Map key for [isTopLevel].
  static const String isTopLevelKey = 'isTopLevel';

  /// Map key for [name].
  static const String nameKey = 'name';

  /// Map key for [outputDir].
  static const String outputDirKey = 'outputDir';

  /// Map key for [outputs].
  static const String outputsKey = 'outputs';

  /// Map key for [targetPlatform].
  static const String targetPlatformKey = 'targetPlatform';

  /// Deserializes a list of [ExtensionBuildTarget] objects from RPC response data.
  static List<ExtensionBuildTarget> listFromJson(Object? rpcResult) {
    if (rpcResult case final List<Object?> list) {
      return <ExtensionBuildTarget>[
        for (final item in list)
          if (item case final Map<String, Object?> map) ExtensionBuildTarget.fromJson(map),
      ];
    }
    return const <ExtensionBuildTarget>[];
  }

  /// Description of what this target builds.
  final String description;

  /// The name of this build target (e.g. `'custom-apk'`).
  final String name;

  /// The target platform string (e.g. `'linux-x64'`, `'android-arm64'`).
  final String targetPlatform;

  /// Whether this target is a top-level target invokable through `flutter build`.
  final bool isTopLevel;

  /// The names of other targets that this target depends on.
  final List<String> dependencies;

  /// Input file patterns and artifacts.
  final List<Source> inputs;

  /// Output file patterns.
  final List<Source> outputs;

  /// The output directory pattern.
  final String outputDir;

  /// Serializes the build target to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    nameKey: name,
    targetPlatformKey: targetPlatform,
    descriptionKey: description,
    isTopLevelKey: isTopLevel,
    dependenciesKey: dependencies,
    inputsKey: inputs.map((Source s) => s.toJson()).toList(),
    outputsKey: outputs.map((Source s) => s.toJson()).toList(),
    outputDirKey: outputDir,
  };

  @override
  String toString() =>
      'ExtensionBuildTarget(name: $name, targetPlatform: $targetPlatform, description: $description)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionBuildTarget &&
            other.name == name &&
            other.targetPlatform == targetPlatform &&
            other.description == description &&
            other.isTopLevel == isTopLevel &&
            other.outputDir == outputDir &&
            _listEquals(other.dependencies, dependencies) &&
            _listEquals(other.inputs, inputs) &&
            _listEquals(other.outputs, outputs));
  }

  @override
  int get hashCode => Object.hash(
    name,
    targetPlatform,
    description,
    isTopLevel,
    outputDir,
    Object.hashAll(dependencies),
    Object.hashAll(inputs),
    Object.hashAll(outputs),
  );
}

/// Representation of a build result returned by a tool extension.
@immutable
class ExtensionBuildResult {
  const ExtensionBuildResult({required this.success, this.errorMessage});

  /// Creates a successful build result.
  const ExtensionBuildResult.success() : this(success: true);

  /// Creates a failed build result with the given [message].
  const ExtensionBuildResult.failure({required String message})
    : this(success: false, errorMessage: message);

  /// Deserializes an [ExtensionBuildResult] from a JSON-serializable map.
  factory ExtensionBuildResult.fromJson(Map<String, Object?> json) {
    final bool success = switch (json[successKey]) {
      final bool value => value,
      _ => false,
    };
    if (success) {
      return const ExtensionBuildResult.success();
    }
    return ExtensionBuildResult(
      success: false,
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

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
