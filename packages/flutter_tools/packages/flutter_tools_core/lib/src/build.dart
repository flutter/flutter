// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'build_system/constants.dart';
import 'build_system/native_assets.dart';
import 'build_system/source.dart';
import 'json_utils.dart';

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

/// Representation of a Flutter plugin resolved for an extension target platform.
@immutable
class ExtensionPlugin {
  const ExtensionPlugin({
    required this.name,
    required this.path,
    this.configuration = const <String, Object?>{},
  });

  /// Deserializes an [ExtensionPlugin] from a JSON-serializable map.
  factory ExtensionPlugin.fromJson(Map<String, Object?> json) {
    final String name = json.requiredField<String>(nameKey);
    if (name.isEmpty) {
      throw const FormatException('Missing or invalid "$nameKey" for ExtensionPlugin.');
    }
    final Uri path = json.directoryUri(pathKey);
    final Map<String, Object?> configuration = json.optionalField<Map<String, Object?>>(
      configurationKey,
      defaultValue: const <String, Object?>{},
    );
    return ExtensionPlugin(name: name, path: path, configuration: configuration);
  }

  /// Map key for [configuration].
  static const String configurationKey = 'configuration';

  /// Map key for [name].
  static const String nameKey = 'name';

  /// Map key for [path].
  static const String pathKey = 'path';

  /// Deserializes a list of [ExtensionPlugin] objects from RPC parameter data.
  static List<ExtensionPlugin> listFromJson(Object? rpcResult) {
    if (rpcResult case final List<Object?> list) {
      return <ExtensionPlugin>[
        for (final Object? item in list)
          switch (item) {
            final Map<String, Object?> map => ExtensionPlugin.fromJson(map),
            final Object? invalid => throw FormatException(
              'Invalid entry in ExtensionPlugin list: $invalid',
            ),
          },
      ];
    }
    throw FormatException('Invalid ExtensionPlugin list: $rpcResult');
  }

  /// The package name of the plugin.
  final String name;

  /// The absolute, trailing-slash terminated directory URI of the plugin root on disk.
  final Uri path;

  /// The raw platform-specific configuration map from `pubspec.yaml` under
  /// `flutter.plugin.platforms.<platformKey>`.
  final Map<String, Object?> configuration;

  /// Serializes the plugin to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    nameKey: name,
    pathKey: path.toString(),
    configurationKey: configuration,
  };

  @override
  String toString() => 'ExtensionPlugin(name: $name, path: $path, configuration: $configuration)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionPlugin &&
            other.name == name &&
            other.path == path &&
            const DeepCollectionEquality().equals(other.configuration, configuration));
  }

  @override
  int get hashCode => Object.hash(name, path, const DeepCollectionEquality().hash(configuration));
}

/// Representation of a custom `flutter build` subcommand target provided by a tool extension.
@immutable
class ExtensionBuildTarget {
  const ExtensionBuildTarget({
    required this.description,
    required this.name,
    required this.outputDir,
    required this.targetPlatform,
    this.artifacts = const <ExtensionArtifact>{},
    this.hostArtifacts = const <ExtensionHostArtifact>{},
    this.nativeAssetsConfig,
    this.pluginPlatformKey,
  });

  /// Deserializes an [ExtensionBuildTarget] from a JSON-serializable map.
  factory ExtensionBuildTarget.fromJson(Map<String, Object?> json) {
    final Map<String, Object?>? rawNativeAssetsConfig = json.nullableField<Map<String, Object?>>(
      nativeAssetsConfigKey,
    );
    return ExtensionBuildTarget(
      description: json.requiredField<String>(descriptionKey),
      name: json.requiredField<String>(nameKey),
      outputDir: json.requiredField<String>(outputDirKey),
      targetPlatform: json.requiredField<String>(targetPlatformKey),
      artifacts: <ExtensionArtifact>{
        for (final String name in json.stringIterable(artifactsKey)) ExtensionArtifact(name),
      },
      hostArtifacts: <ExtensionHostArtifact>{
        for (final String name in json.stringIterable(hostArtifactsKey))
          ExtensionHostArtifact(name),
      },
      nativeAssetsConfig: rawNativeAssetsConfig != null
          ? ExtensionNativeAssetsConfig.fromJson(rawNativeAssetsConfig)
          : null,
      pluginPlatformKey: json.nullableField<String>(pluginPlatformKeyKey),
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

  /// Map key for [nativeAssetsConfig].
  static const String nativeAssetsConfigKey = 'nativeAssetsConfig';

  /// Map key for [outputDir].
  static const String outputDirKey = 'outputDir';

  /// Map key for [pluginPlatformKey].
  static const String pluginPlatformKeyKey = 'pluginPlatformKey';

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
  // TODO(bkonyi): Support target-platform agnostic BuildTargets, https://github.com/flutter/flutter/issues/194810.
  final String targetPlatform;

  /// Engine artifacts required by this build target, resolved for [targetPlatform]
  /// and the active [BuildMode].
  final Set<ExtensionArtifact> artifacts;

  /// Host-side build tool or library artifacts required by this build target.
  final Set<ExtensionHostArtifact> hostArtifacts;

  /// Optional Dart hooks (`native_assets`) target OS, architecture, and compiler
  /// configuration for custom targets.
  final ExtensionNativeAssetsConfig? nativeAssetsConfig;

  /// The directory pattern used by `flutter build` to determine this target's
  /// output directory, for example
  /// `'${BuiltInPlaceholders.outputDir}/custom/${BuiltInPlaceholders.targetPlatform}/${BuiltInPlaceholders.buildMode}'`.
  ///
  /// Supports [BuiltInPlaceholders.outputDir] (the project's configured build
  /// output root from `flutter config --build-dir`, defaulting to
  /// `<project>/build`), [BuiltInPlaceholders.projectDir],
  /// [BuiltInPlaceholders.buildMode], and [BuiltInPlaceholders.targetPlatform].
  final String outputDir;

  /// Optional platform key under `flutter.plugin.platforms.<key>` in `pubspec.yaml`
  /// used to resolve plugins for this target (e.g. `'linux'`, `'custom_platform'`).
  final String? pluginPlatformKey;

  /// Serializes the build target to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    descriptionKey: description,
    nameKey: name,
    targetPlatformKey: targetPlatform,
    artifactsKey: artifacts.map((ExtensionArtifact a) => a.name).toList(),
    hostArtifactsKey: hostArtifacts.map((ExtensionHostArtifact a) => a.name).toList(),
    nativeAssetsConfigKey: ?nativeAssetsConfig?.toMap(),
    outputDirKey: outputDir,
    pluginPlatformKeyKey: ?pluginPlatformKey,
  };

  @override
  String toString() =>
      'ExtensionBuildTarget(name: $name, targetPlatform: $targetPlatform, '
      'description: $description, artifacts: $artifacts, '
      'hostArtifacts: $hostArtifacts, outputDir: $outputDir, '
      'nativeAssetsConfig: $nativeAssetsConfig, '
      'pluginPlatformKey: $pluginPlatformKey)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionBuildTarget &&
            other.description == description &&
            other.name == name &&
            other.targetPlatform == targetPlatform &&
            other.outputDir == outputDir &&
            other.nativeAssetsConfig == nativeAssetsConfig &&
            other.pluginPlatformKey == pluginPlatformKey &&
            _setEquals(other.artifacts, artifacts) &&
            _setEquals(other.hostArtifacts, hostArtifacts));
  }

  @override
  int get hashCode => Object.hash(
    description,
    name,
    targetPlatform,
    outputDir,
    nativeAssetsConfig,
    pluginPlatformKey,
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
      description: json.requiredField<String>(descriptionKey),
      name: json.requiredField<String>(nameKey),
      targetPlatform: json.requiredField<String>(targetPlatformKey),
      dependencies: json.stringIterable(dependenciesKey).toList(),
      inputs: _parseSources(json, inputsKey),
      outputs: _parseSources(json, outputsKey),
    );
  }

  static List<ExtensionSource> _parseSources(Map<String, Object?> json, String key) {
    final List<Object?> rawSources = json.optionalField<List<Object?>>(
      key,
      defaultValue: const <Object?>[],
    );
    return <ExtensionSource>[
      for (final Object? item in rawSources)
        if (item case final Map<String, Object?> map)
          ExtensionSource.fromJson(map)
        else
          throw FormatException(
            'Invalid "$key" element: expected Map<String, Object?>, got ${item.runtimeType}.',
          ),
    ];
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
      success: json.optionalField<bool>(successKey, defaultValue: false),
      errorMessage: json.nullableField<String>(errorMessageKey),
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
