// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'build_system/depfile.dart';
library;

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'build_system/constants.dart';
import 'build_system/source.dart';
import 'json_utils.dart';
import 'project.dart';

export 'build_system/constants.dart';
export 'build_system/depfile.dart';
export 'build_system/source.dart';

const _listEquality = ListEquality<Object?>();
const _setEquality = SetEquality<Object?>();

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
  ExtensionPlugin({
    required this.name,
    required this.path,
    this.configuration = const <String, Object?>{},
  }) : assert(name.trim().isNotEmpty, 'Plugin name cannot be empty.'),
       assert(
         path.isValidDirectoryUri,
         'Plugin path must be an absolute file: directory URI ending with "/": $path',
       );

  /// Deserializes an [ExtensionPlugin] from a JSON-serializable map.
  factory ExtensionPlugin.fromJson(Map<String, Object?> json) {
    final String name = json.requiredField<String>(nameKey);
    if (name.trim().isEmpty) {
      throw const FormatException('Missing or invalid "$nameKey" for ExtensionPlugin.');
    }
    final Uri path = json.directoryUri(pathKey);
    final Map<String, Object?> configuration = json.requiredField<Map<String, Object?>>(
      configurationKey,
    );
    return ExtensionPlugin(name: name, path: path, configuration: configuration);
  }

  /// Map key for [configuration].
  @visibleForTesting
  static const String configurationKey = 'configuration';

  /// Map key for [name].
  @visibleForTesting
  static const String nameKey = 'name';

  /// Map key for [path].
  @visibleForTesting
  static const String pathKey = 'path';

  /// Deserializes a list of [ExtensionPlugin] objects from RPC parameter data.
  static List<ExtensionPlugin> listFromJson(Object? rpcResult) {
    if (rpcResult case final List<Object?> list) {
      return <ExtensionPlugin>[
        for (final Object? item in list)
          switch (item) {
            final Map<String, Object?> map => ExtensionPlugin.fromJson(map),
            final Object? invalid => throw FormatException(
              'Invalid ExtensionPlugin list element: expected Map<String, Object?>, got ${invalid.runtimeType}.',
            ),
          },
      ];
    }
    throw FormatException(
      'Invalid ExtensionPlugin list: expected List<Object?>, got ${rpcResult.runtimeType}.',
    );
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

/// Context passed to `BuildService.injectPlugins` when generating native
/// plugin registrants and build inputs inside a platform runner directory.
@immutable
final class ExtensionPluginInjectionContext {
  /// Creates a native plugin injection context for [pluginPlatformKey] and
  /// [runnerDirectory].
  const ExtensionPluginInjectionContext({
    required this.pluginPlatformKey,
    required this.plugins,
    required this.project,
    required this.releaseMode,
    required this.runnerDirectory,
  });

  /// Deserializes an [ExtensionPluginInjectionContext] from a JSON-serializable map.
  factory ExtensionPluginInjectionContext.fromJson(Map<String, Object?> json) {
    final String pluginPlatformKey = json.requiredField<String>(pluginPlatformKeyKey);
    if (!ExtensionBuildTarget.isValidPluginPlatformKey(pluginPlatformKey)) {
      throw FormatException(
        'Invalid "$pluginPlatformKeyKey" field: "$pluginPlatformKey". '
        '${ExtensionBuildTarget._invalidPluginPlatformKeyMessage}',
      );
    }
    final List<ExtensionPlugin> plugins = ExtensionPlugin.listFromJson(
      json.requiredField<List<Object?>>(pluginsKey),
    );
    final project = ExtensionFlutterProject.fromJson(
      json.requiredField<Map<String, Object?>>(projectKey),
    );
    final bool releaseMode = json.requiredField<bool>(releaseModeKey);
    final Uri runnerDirectory = json.directoryUri(runnerDirectoryKey);
    return ExtensionPluginInjectionContext(
      pluginPlatformKey: pluginPlatformKey,
      plugins: plugins,
      project: project,
      releaseMode: releaseMode,
      runnerDirectory: runnerDirectory,
    );
  }

  /// Map key for [pluginPlatformKey].
  @visibleForTesting
  static const pluginPlatformKeyKey = 'pluginPlatformKey';

  /// Map key for [plugins].
  @visibleForTesting
  static const pluginsKey = 'plugins';

  /// Map key for [project].
  @visibleForTesting
  static const projectKey = 'project';

  /// Map key for [releaseMode].
  @visibleForTesting
  static const releaseModeKey = 'releaseMode';

  /// Map key for [runnerDirectory].
  @visibleForTesting
  static const runnerDirectoryKey = 'runnerDirectory';

  /// The `flutter.plugin.platforms.<key>` identifier being injected (for
  /// example, `'custom_os'`).
  final String pluginPlatformKey;

  /// Resolved plugins declaring [pluginPlatformKey] in `pubspec.yaml`.
  final List<ExtensionPlugin> plugins;

  /// The Flutter project receiving generated native plugin tooling.
  final ExtensionFlutterProject project;

  /// Whether plugin tooling is being generated for a release build.
  final bool releaseMode;

  /// Absolute directory URI of the existing platform runner directory on disk
  /// (for example, `file:///workspace/app/custom_os/`).
  final Uri runnerDirectory;

  /// Serializes this context to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    pluginPlatformKeyKey: pluginPlatformKey,
    pluginsKey: <Map<String, Object?>>[
      for (final ExtensionPlugin plugin in plugins) plugin.toMap(),
    ],
    projectKey: project.toMap(),
    releaseModeKey: releaseMode,
    runnerDirectoryKey: runnerDirectory.toString(),
  };

  @override
  String toString() =>
      'ExtensionPluginInjectionContext(pluginPlatformKey: $pluginPlatformKey, '
      'plugins: $plugins, project: $project, releaseMode: $releaseMode, '
      'runnerDirectory: $runnerDirectory)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionPluginInjectionContext &&
            other.pluginPlatformKey == pluginPlatformKey &&
            const ListEquality<ExtensionPlugin>().equals(other.plugins, plugins) &&
            other.project == project &&
            other.releaseMode == releaseMode &&
            other.runnerDirectory == runnerDirectory);
  }

  @override
  int get hashCode => Object.hash(
    pluginPlatformKey,
    Object.hashAll(plugins),
    project,
    releaseMode,
    runnerDirectory,
  );
}

/// Representation of a custom `flutter build` subcommand target provided by a tool extension.
@immutable
class ExtensionBuildTarget {
  ExtensionBuildTarget({
    required this.description,
    required this.name,
    required this.outputDir,
    this.targetPlatform,
    this.artifacts = const <ExtensionArtifact>{},
    this.hostArtifacts = const <ExtensionHostArtifact>{},
    this.pluginPlatformKey,
  }) : assert(isValidName(name), 'Invalid build target name "$name". $_invalidNameMessage'),
       assert(targetPlatform == null || targetPlatform != ''),
       assert(
         pluginPlatformKey == null || isValidPluginPlatformKey(pluginPlatformKey),
         'Invalid pluginPlatformKey "$pluginPlatformKey". $_invalidPluginPlatformKeyMessage',
       );

  /// Deserializes an [ExtensionBuildTarget] from a JSON-serializable map.
  factory ExtensionBuildTarget.fromJson(Map<String, Object?> json) {
    final String name = json.requiredField<String>(nameKey);
    if (!isValidName(name)) {
      throw FormatException('Invalid "$nameKey" field: "$name". $_invalidNameMessage');
    }
    final String? targetPlatform = json.nullableField<String>(targetPlatformKey);
    if (targetPlatform != null && targetPlatform.isEmpty) {
      throw const FormatException(
        'Invalid "$targetPlatformKey" in ExtensionBuildTarget: must not be empty.',
      );
    }
    final String? pluginPlatformKey = json.nullableField<String>(pluginPlatformKeyKey);
    if (pluginPlatformKey != null && !isValidPluginPlatformKey(pluginPlatformKey)) {
      throw FormatException(
        'Invalid "$pluginPlatformKeyKey" field: "$pluginPlatformKey". $_invalidPluginPlatformKeyMessage',
      );
    }
    return ExtensionBuildTarget(
      description: json.requiredField<String>(descriptionKey),
      name: name,
      outputDir: json.requiredField<String>(outputDirKey),
      targetPlatform: targetPlatform,
      artifacts: <ExtensionArtifact>{
        for (final String name in json.stringIterable(artifactsKey)) ExtensionArtifact(name),
      },
      hostArtifacts: <ExtensionHostArtifact>{
        for (final String name in json.stringIterable(hostArtifactsKey))
          ExtensionHostArtifact(name),
      },
      pluginPlatformKey: pluginPlatformKey,
    );
  }

  static final _validNamePattern = RegExp(r'^[a-z][a-z0-9_-]*$');
  static const String _invalidNameMessage =
      'Build target names must start with a lowercase ASCII letter and contain '
      'only lowercase ASCII letters, digits, underscores, and hyphens.';

  // Plugin platform keys map to snake_case identifiers in pubspec.yaml and Dart
  // code generation, so hyphens and uppercase characters are disallowed.
  static final _validPluginPlatformKeyPattern = RegExp(r'^[a-z][a-z0-9_]*$');
  static const String _invalidPluginPlatformKeyMessage =
      'Plugin platform keys must start with a lowercase ASCII letter and contain '
      'only lowercase ASCII letters, digits, and underscores.';

  /// Returns whether [name] is a valid build target name.
  ///
  /// A valid target name must start with a lowercase ASCII letter (`a-z`) and
  /// may contain only lowercase ASCII letters, digits (`0-9`), underscores
  /// (`_`), and hyphens (`-`).
  static bool isValidName(String name) => _validNamePattern.hasMatch(name);

  /// Returns whether [key] is a valid plugin platform key (`^[a-z][a-z0-9_]*$`).
  static bool isValidPluginPlatformKey(String key) => _validPluginPlatformKeyPattern.hasMatch(key);

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

  /// Map key for [pluginPlatformKey].
  @visibleForTesting
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
  ///
  /// Must match [isValidName].
  final String name;

  /// The target platform identifier (e.g. `'linux-x64'`, `'custom-embedder-arm64'`),
  /// or `null` if this target is platform-agnostic.
  ///
  /// This is an open [String] rather than an enum so that extensions for custom
  /// embedders can declare platform identifiers that are not built into Flutter.
  /// Used to substitute [BuiltInPlaceholders.targetPlatform] in [outputDir], and as the
  /// default artifact platform when it matches a built-in Flutter target platform.
  ///
  /// When `null`, [outputDir] must not reference
  /// [BuiltInPlaceholders.targetPlatform], and only target-platform-independent
  /// engine artifacts ([BuiltInArtifacts.flutterPatchedSdkPath] and
  /// [BuiltInArtifacts.icuData]) can be resolved in [artifacts].
  // TODO(bkonyi): Replace with declared supported target platforms on BuildTarget and a selected target platform on ExtensionBuildContext, https://github.com/flutter/flutter/issues/194810.
  final String? targetPlatform;

  /// Engine artifacts required by this build target, resolved for [targetPlatform]
  /// and the active [BuildMode].
  final Set<ExtensionArtifact> artifacts;

  /// Host-side build tool or library artifacts required by this build target.
  final Set<ExtensionHostArtifact> hostArtifacts;

  /// The directory pattern used by `flutter build` to determine this target's
  /// output directory, for example
  /// `'${BuiltInPlaceholders.outputDir}/custom/${BuiltInPlaceholders.targetPlatform}/${BuiltInPlaceholders.buildMode}'`.
  ///
  /// Supports [BuiltInPlaceholders.outputDir] (the project's configured build
  /// output root from `flutter config --build-dir`, defaulting to
  /// `<project>/build`), [BuiltInPlaceholders.projectDir],
  /// [BuiltInPlaceholders.buildMode], and [BuiltInPlaceholders.targetPlatform]
  /// (when [targetPlatform] is non-null).
  final String outputDir;

  /// Optional platform key under `flutter.plugin.platforms.<key>` in `pubspec.yaml`
  /// used to resolve plugins for this target (e.g. `'linux'`, `'custom_platform'`).
  final String? pluginPlatformKey;

  /// Serializes the build target to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    descriptionKey: description,
    nameKey: name,
    targetPlatformKey: ?targetPlatform,
    artifactsKey: artifacts.map((ExtensionArtifact a) => a.name).toList(),
    hostArtifactsKey: hostArtifacts.map((ExtensionHostArtifact a) => a.name).toList(),
    outputDirKey: outputDir,
    pluginPlatformKeyKey: ?pluginPlatformKey,
  };

  @override
  String toString() =>
      'ExtensionBuildTarget(name: $name, targetPlatform: $targetPlatform, '
      'description: $description, artifacts: $artifacts, '
      'hostArtifacts: $hostArtifacts, outputDir: $outputDir, '
      'pluginPlatformKey: $pluginPlatformKey)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionBuildTarget &&
            other.description == description &&
            other.name == name &&
            other.targetPlatform == targetPlatform &&
            other.outputDir == outputDir &&
            other.pluginPlatformKey == pluginPlatformKey &&
            _setEquality.equals(other.artifacts, artifacts) &&
            _setEquality.equals(other.hostArtifacts, hostArtifacts));
  }

  @override
  int get hashCode => Object.hash(
    description,
    name,
    targetPlatform,
    outputDir,
    pluginPlatformKey,
    Object.hashAllUnordered(artifacts),
    Object.hashAllUnordered(hostArtifacts),
  );
}

/// Representation of a custom `flutter assemble` target provided by a tool extension.
@immutable
class ExtensionAssembleTarget {
  ExtensionAssembleTarget({
    required this.description,
    required this.name,
    required this.targetPlatform,
    this.dependencies = const <String>[],
    this.depfiles = const <String>[],
    this.inputs = const <ExtensionSource>[],
    this.outputs = const <ExtensionSource>[],
  }) : assert(depfiles.every(isValidDepfileName), _invalidDepfileNameMessage);

  /// Deserializes an [ExtensionAssembleTarget] from a JSON-serializable map.
  factory ExtensionAssembleTarget.fromJson(Map<String, Object?> json) {
    final List<String> depfiles = json.stringIterable(depfilesKey).toList();
    for (final depfileName in depfiles) {
      if (!isValidDepfileName(depfileName)) {
        throw FormatException(
          'Invalid "$depfilesKey" element "$depfileName": $_invalidDepfileNameMessage',
        );
      }
    }
    return ExtensionAssembleTarget(
      description: json.requiredField<String>(descriptionKey),
      name: json.requiredField<String>(nameKey),
      targetPlatform: json.requiredField<String>(targetPlatformKey),
      dependencies: json.stringIterable(dependenciesKey).toList(),
      depfiles: depfiles,
      inputs: _parseSources(json, inputsKey),
      outputs: _parseSources(json, outputsKey),
    );
  }

  static const String _invalidDepfileNameMessage =
      'Depfile names must be non-empty single file names without path separators.';

  /// Returns whether [name] is a valid depfile file name within the build directory.
  ///
  /// A valid depfile name must be non-empty, must not be `'.'` or `'..'`, and
  /// must not contain `/` or `\` path separators.
  static bool isValidDepfileName(String name) =>
      name.isNotEmpty && name != '.' && name != '..' && !name.contains('/') && !name.contains(r'\');

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

  /// Map key for [depfiles].
  static const String depfilesKey = 'depfiles';

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

  /// Names of `.d` dependency files written by this target into the build directory.
  ///
  /// Extensions that declare [depfiles] can use [Depfile.format] to write `.d`
  /// files into their build directory. The host deletes any existing declared
  /// depfiles from the build directory before invoking the target.
  ///
  /// Each entry must match [isValidDepfileName]. Because all targets write
  /// depfiles directly into the shared build directory, depfile names must be
  /// unique across built-in Flutter tool targets and all active extensions.
  /// Prefix depfile names with the target platform or extension name (for
  /// example, `'linux_build.d'`) to avoid conflicts.
  ///
  /// Relative paths inside each depfile are resolved against the project root
  /// directory and rewritten in place with normalized paths by the host after
  /// a successful build. If a declared depfile is missing or invalid after a
  /// successful build, the host logs an error and disables incremental build
  /// caching for this target without failing the build.
  final List<String> depfiles;

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
    if (depfiles.isNotEmpty) depfilesKey: depfiles,
    inputsKey: inputs.map((ExtensionSource s) => s.toMap()).toList(),
    outputsKey: outputs.map((ExtensionSource s) => s.toMap()).toList(),
  };

  @override
  String toString() =>
      'ExtensionAssembleTarget(name: $name, targetPlatform: $targetPlatform, '
      'description: $description, dependencies: $dependencies, '
      'depfiles: $depfiles, inputs: $inputs, outputs: $outputs)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionAssembleTarget &&
            other.description == description &&
            other.name == name &&
            other.targetPlatform == targetPlatform &&
            _listEquality.equals(other.dependencies, dependencies) &&
            _listEquality.equals(other.depfiles, depfiles) &&
            _listEquality.equals(other.inputs, inputs) &&
            _listEquality.equals(other.outputs, outputs));
  }

  @override
  int get hashCode => Object.hash(
    description,
    name,
    targetPlatform,
    Object.hashAll(dependencies),
    Object.hashAll(depfiles),
    Object.hashAll(inputs),
    Object.hashAll(outputs),
  );
}

/// Representation of a build result returned by a tool extension.
@immutable
class ExtensionBuildResult {
  const ExtensionBuildResult({required this.success, this.errorMessage, this.executableUri});

  /// Deserializes an [ExtensionBuildResult] from a JSON-serializable map.
  ///
  /// Throws a [FormatException] if [executableUriKey] is present and is not a
  /// valid absolute `file:` URI.
  factory ExtensionBuildResult.fromJson(Map<String, Object?> json) {
    return ExtensionBuildResult(
      success: json.optionalField<bool>(successKey, defaultValue: false),
      errorMessage: json.nullableField<String>(errorMessageKey),
      executableUri: _parseExecutableUri(json),
    );
  }

  static Uri? _parseExecutableUri(Map<String, Object?> json) {
    final String? raw = json.nullableField<String>(executableUriKey);
    if (raw == null) {
      return null;
    }
    final Uri? uri = Uri.tryParse(raw);
    if (uri != null && uri.isValidFileUri) {
      return uri;
    }
    throw const FormatException(
      'Invalid "$executableUriKey" in ExtensionBuildResult: must be an absolute file:// URI.',
    );
  }

  /// Map key for [errorMessage].
  static const String errorMessageKey = 'errorMessage';

  /// Map key for [executableUri].
  static const String executableUriKey = 'executableUri';

  /// Map key for [success].
  static const String successKey = 'success';

  /// Whether the build succeeded.
  final bool success;

  /// Optional error message if the build failed.
  final String? errorMessage;

  /// Optional absolute `file:` URI to the built application executable or bundle.
  final Uri? executableUri;

  /// Serializes the build result to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    successKey: success,
    errorMessageKey: ?errorMessage,
    executableUriKey: ?executableUri?.toString(),
  };

  @override
  String toString() =>
      'ExtensionBuildResult(success: $success, errorMessage: $errorMessage, '
      'executableUri: $executableUri)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionBuildResult &&
            other.success == success &&
            other.errorMessage == errorMessage &&
            other.executableUri == executableUri);
  }

  @override
  int get hashCode => Object.hash(success, errorMessage, executableUri);
}
