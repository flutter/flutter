// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'build_system/constants.dart';
import 'build_system/source.dart';

export 'build_system/constants.dart';
export 'build_system/source.dart';

final _upperRegex = RegExp(r'[A-Z]');

/// Convert `fooBar` to `foo_bar`.
String _snakeCase(String str) {
  return str.replaceAllMapped(
    _upperRegex,
    (Match m) => '${m.start == 0 ? '' : '_'}${m[0]!.toLowerCase()}',
  );
}

/// Converts `fooBar` to `FooBar`.
String _sentenceCase(String str) =>
    str.isEmpty ? str : '${str[0].toUpperCase()}${str.substring(1)}';

/// A summary of the compilation strategy used for Dart.
enum BuildMode {
  /// Built in JIT mode with no optimizations, enabled asserts, and a VM service.
  debug,

  /// Built in AOT mode with some optimizations and a VM service.
  profile,

  /// Built in AOT mode with all optimizations and no VM service.
  release,

  /// Built in JIT mode with all optimizations and no VM service.
  jitRelease;

  factory BuildMode.fromCliName(String value) => values.singleWhere(
    (BuildMode element) => element.cliName == value,
    orElse: () => throw ArgumentError('$value is not a supported build mode'),
  );

  static const releaseModes = <BuildMode>{release, jitRelease};
  static const jitModes = <BuildMode>{debug, jitRelease};

  /// Whether this mode is considered release.
  ///
  /// Useful for determining whether we should enable/disable asserts or
  /// other development features.
  bool get isRelease => releaseModes.contains(this);

  /// Whether this mode is using the JIT runtime.
  bool get isJit => jitModes.contains(this);

  /// Whether this mode is using the precompiled runtime.
  bool get isPrecompiled => !isJit;

  /// [name] formatted in snake case.
  ///
  /// (e.g. debug, profile, release, jit_release)
  String get cliName => _snakeCase(name);

  /// [cliName] formatted in sentence case.
  ///
  /// (e.g. Debug, Profile, Release, Jit_release)
  String get uppercaseName => _sentenceCase(cliName);

  /// [cliName] with `_` replaced with a space.
  ///
  /// (e.g. debug, profile, release, jit release)
  String get friendlyName => cliName.replaceAll('_', ' ');

  /// [friendlyName] formatted in sentence case.
  ///
  /// (e.g. Debug, Profile, Release, Jit release)
  String get uppercaseFriendlyName => _sentenceCase(friendlyName);

  @override
  String toString() => cliName;
}

/// Representation of a custom `flutter build` subcommand target provided by a tool extension.
@immutable
class ExtensionBuildTarget {
  const ExtensionBuildTarget({
    required this.description,
    required this.name,
    required this.targetPlatform,
    this.artifacts = const <ExtensionArtifact>{},
    this.hostArtifacts = const <ExtensionHostArtifact>{},
    this.outputDir = BuiltInPlaceholders.buildDir,
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
      artifacts: switch (json[artifactsKey]) {
        final List<Object?> rawArtifacts => <ExtensionArtifact>{
          for (final item in rawArtifacts)
            switch (item) {
              final String name => ExtensionArtifact(name),
              _ => throw ArgumentError('Invalid entry in "$artifactsKey": $item'),
            },
        },
        null => const <ExtensionArtifact>{},
        final Object? invalid => throw ArgumentError('Invalid "$artifactsKey": $invalid'),
      },
      hostArtifacts: switch (json[hostArtifactsKey]) {
        final List<Object?> rawHostArtifacts => <ExtensionHostArtifact>{
          for (final item in rawHostArtifacts)
            switch (item) {
              final String name => ExtensionHostArtifact(name),
              _ => throw ArgumentError('Invalid entry in "$hostArtifactsKey": $item'),
            },
        },
        null => const <ExtensionHostArtifact>{},
        final Object? invalid => throw ArgumentError('Invalid "$hostArtifactsKey": $invalid'),
      },
      outputDir: switch (json[outputDirKey]) {
        final String value => value,
        _ => BuiltInPlaceholders.buildDir,
      },
    );
  }

  /// Map key for [artifacts].
  static const String artifactsKey = 'artifacts';

  /// Map key for [description].
  static const String descriptionKey = 'description';

  /// Map key for [hostArtifacts].
  static const String hostArtifactsKey = 'hostArtifacts';

  /// Map key for [name].
  static const String nameKey = 'name';

  /// Map key for [outputDir].
  static const String outputDirKey = 'outputDir';

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

  /// The target platform identifier (e.g. `'linux-x64'`, `'custom-embedder-arm64'`).
  ///
  /// This is an open [String] rather than an enum so that extensions for custom
  /// embedders can declare platform identifiers that are not built into Flutter.
  /// Used to substitute [BuiltInPlaceholders.targetPlatform] in [outputDir], and as the
  /// default artifact platform when it matches a built-in Flutter target platform.
  final String targetPlatform;

  /// Engine artifacts required by this build target, resolved for [targetPlatform]
  /// and the active [BuildMode].
  final Set<ExtensionArtifact> artifacts;

  /// Host-side build tool or library artifacts required by this build target.
  final Set<ExtensionHostArtifact> hostArtifacts;

  /// The directory pattern used by `flutter build` to determine this target's
  /// output directory (`{OUTPUT_DIR}`), for example
  /// `'${BuiltInPlaceholders.projectDir}/build/custom/${BuiltInPlaceholders.targetPlatform}/${BuiltInPlaceholders.buildMode}'`.
  ///
  /// Supports [BuiltInPlaceholders.projectDir], [BuiltInPlaceholders.buildDir],
  /// [BuiltInPlaceholders.buildMode], and [BuiltInPlaceholders.targetPlatform].
  final String outputDir;

  /// Serializes the build target to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    descriptionKey: description,
    nameKey: name,
    targetPlatformKey: targetPlatform,
    artifactsKey: artifacts.map((ExtensionArtifact a) => a.name).toList(),
    hostArtifactsKey: hostArtifacts.map((ExtensionHostArtifact a) => a.name).toList(),
    outputDirKey: outputDir,
  };

  @override
  String toString() =>
      'ExtensionBuildTarget(name: $name, targetPlatform: $targetPlatform, '
      'description: $description, artifacts: $artifacts, '
      'hostArtifacts: $hostArtifacts, outputDir: $outputDir)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionBuildTarget &&
            other.description == description &&
            other.name == name &&
            other.targetPlatform == targetPlatform &&
            other.outputDir == outputDir &&
            _setEquals(other.artifacts, artifacts) &&
            _setEquals(other.hostArtifacts, hostArtifacts));
  }

  @override
  int get hashCode => Object.hash(
    description,
    name,
    targetPlatform,
    outputDir,
    Object.hashAllUnordered(artifacts),
    Object.hashAllUnordered(hostArtifacts),
  );
}

/// Representation of a custom `flutter assemble` target provided by a tool extension.
@immutable
class ExtensionAssembleTarget {
  const ExtensionAssembleTarget({
    required this.description,
    required this.name,
    required this.targetPlatform,
    this.dependencies = const <String>[],
    this.inputs = const <ExtensionSource>[],
    this.outputs = const <ExtensionSource>[],
  });

  /// Deserializes an [ExtensionAssembleTarget] from a JSON-serializable map.
  factory ExtensionAssembleTarget.fromJson(Map<String, Object?> json) {
    return ExtensionAssembleTarget(
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
            switch (item) {
              final String dep => dep,
              _ => throw ArgumentError('Invalid entry in "$dependenciesKey": $item'),
            },
        ],
        null => const <String>[],
        final Object? invalid => throw ArgumentError('Invalid "$dependenciesKey": $invalid'),
      },
      inputs: switch (json[inputsKey]) {
        final List<Object?> rawInputs => <ExtensionSource>[
          for (final item in rawInputs)
            switch (item) {
              final Map<String, Object?> map => ExtensionSource.fromJson(map),
              _ => throw ArgumentError('Invalid entry in "$inputsKey": $item'),
            },
        ],
        null => const <ExtensionSource>[],
        final Object? invalid => throw ArgumentError('Invalid "$inputsKey": $invalid'),
      },
      outputs: switch (json[outputsKey]) {
        final List<Object?> rawOutputs => <ExtensionSource>[
          for (final item in rawOutputs)
            switch (item) {
              final Map<String, Object?> map => ExtensionSource.fromJson(map),
              _ => throw ArgumentError('Invalid entry in "$outputsKey": $item'),
            },
        ],
        null => const <ExtensionSource>[],
        final Object? invalid => throw ArgumentError('Invalid "$outputsKey": $invalid'),
      },
    );
  }

  /// Map key for [dependencies].
  static const String dependenciesKey = 'dependencies';

  /// Map key for [description].
  static const String descriptionKey = 'description';

  /// Map key for [inputs].
  static const String inputsKey = 'inputs';

  /// Map key for [name].
  static const String nameKey = 'name';

  /// Map key for [outputs].
  static const String outputsKey = 'outputs';

  /// Map key for [targetPlatform].
  static const String targetPlatformKey = 'targetPlatform';

  /// Deserializes a list of [ExtensionAssembleTarget] objects from RPC response data.
  static List<ExtensionAssembleTarget> listFromJson(Object? rpcResult) {
    if (rpcResult case final List<Object?> list) {
      return <ExtensionAssembleTarget>[
        for (final item in list)
          if (item case final Map<String, Object?> map) ExtensionAssembleTarget.fromJson(map),
      ];
    }
    return const <ExtensionAssembleTarget>[];
  }

  /// Description of what this target builds.
  final String description;

  /// The name of this assemble target (e.g. `'custom-linux-assemble-only-debug'`).
  final String name;

  /// The target platform identifier (e.g. `'linux-x64'`, `'custom-embedder-arm64'`).
  ///
  /// This is an open [String] rather than an enum so that extensions for custom
  /// embedders can declare platform identifiers that are not built into Flutter.
  /// Used as the default artifact platform when it matches a built-in Flutter target platform.
  final String targetPlatform;

  /// The names of other targets that this target depends on.
  final List<String> dependencies;

  /// Input file patterns and artifacts.
  final List<ExtensionSource> inputs;

  /// Output file patterns produced by this target (for example,
  /// `ExtensionSource.pattern('${BuiltInPlaceholders.outputDir}/app.bundle')`).
  final List<ExtensionSource> outputs;

  /// Serializes the assemble target to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    descriptionKey: description,
    nameKey: name,
    targetPlatformKey: targetPlatform,
    dependenciesKey: dependencies,
    inputsKey: inputs.map((ExtensionSource s) => s.toMap()).toList(),
    outputsKey: outputs.map((ExtensionSource s) => s.toMap()).toList(),
  };

  @override
  String toString() =>
      'ExtensionAssembleTarget(name: $name, targetPlatform: $targetPlatform, '
      'description: $description, dependencies: $dependencies, '
      'inputs: $inputs, outputs: $outputs)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionAssembleTarget &&
            other.description == description &&
            other.name == name &&
            other.targetPlatform == targetPlatform &&
            _listEquals(other.dependencies, dependencies) &&
            _listEquals(other.inputs, inputs) &&
            _listEquals(other.outputs, outputs));
  }

  @override
  int get hashCode => Object.hash(
    description,
    name,
    targetPlatform,
    Object.hashAll(dependencies),
    Object.hashAll(inputs),
    Object.hashAll(outputs),
  );
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

bool _setEquals<T>(Set<T> a, Set<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  return a.containsAll(b);
}
