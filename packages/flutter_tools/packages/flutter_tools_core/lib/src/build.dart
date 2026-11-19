// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'build_context.dart';
/// @docImport 'build_system/depfile.dart';
library;

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'build_system/constants.dart';
import 'build_system/source.dart';
import 'json_utils.dart';
import 'options.dart';

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

/// Representation of a custom `flutter build` subcommand target provided by a tool extension.
@immutable
class ExtensionBuildTarget {
  ExtensionBuildTarget({
    required this.description,
    required this.name,
    required this.outputDir,
    this.artifacts = const <ExtensionArtifact>{},
    this.flags = const <ExtensionFlag>[],
    this.hostArtifacts = const <ExtensionHostArtifact>{},
    this.options = const <ExtensionOption>[],
    this.supportedBuildModes = const <BuildMode>{.debug, .profile, .release},
    this.supportsFlavors = false,
    this.supportsSizeAnalysis = false,
    this.targetPlatforms = const <String>{},
  }) : assert(isValidName(name), 'Invalid build target name "$name". $_invalidNameMessage'),
       assert(supportedBuildModes.isNotEmpty, 'supportedBuildModes must not be empty.'),
       assert(
         targetPlatforms.every((String platform) => platform.isNotEmpty),
         'targetPlatforms must not contain empty platform names.',
       );

  /// Deserializes an [ExtensionBuildTarget] from a JSON-serializable map.
  factory ExtensionBuildTarget.fromJson(Map<String, Object?> json) {
    final String name = json.requiredField<String>(nameKey);
    if (!isValidName(name)) {
      throw FormatException('Invalid "$nameKey" field: "$name". $_invalidNameMessage');
    }
    final Set<BuildMode> supportedBuildModes;
    if (json[supportedBuildModesKey] == null) {
      supportedBuildModes = const <BuildMode>{.debug, .profile, .release};
    } else {
      final modes = <BuildMode>{};
      for (final String rawMode in json.stringIterable(supportedBuildModesKey)) {
        try {
          modes.add(BuildMode.fromCliName(rawMode));
        } on ArgumentError {
          throw FormatException(
            'Invalid "$supportedBuildModesKey" element in ExtensionBuildTarget: "$rawMode".',
          );
        }
      }
      if (modes.isEmpty) {
        throw const FormatException(
          'Invalid "$supportedBuildModesKey" in ExtensionBuildTarget: must not be empty.',
        );
      }
      supportedBuildModes = Set<BuildMode>.unmodifiable(modes);
    }
    return ExtensionBuildTarget(
      description: json.requiredField<String>(descriptionKey),
      name: name,
      outputDir: json.requiredField<String>(outputDirKey),
      artifacts: <ExtensionArtifact>{
        for (final String artifactName in json.stringIterable(artifactsKey))
          ExtensionArtifact(artifactName),
      },
      flags: ExtensionFlag.listFromJson(json[flagsKey]),
      hostArtifacts: <ExtensionHostArtifact>{
        for (final String artifactName in json.stringIterable(hostArtifactsKey))
          ExtensionHostArtifact(artifactName),
      },
      options: ExtensionOption.listFromJson(json[optionsKey]),
      supportedBuildModes: supportedBuildModes,
      supportsFlavors: json.optionalField<bool>(supportsFlavorsKey, defaultValue: false),
      supportsSizeAnalysis: json.optionalField<bool>(supportsSizeAnalysisKey, defaultValue: false),
      targetPlatforms: json.stringSet(targetPlatformsKey, rejectEmpty: true),
    );
  }

  static final _validNamePattern = RegExp(r'^[a-z][a-z0-9_-]*$');
  static const String _invalidNameMessage =
      'Build target names must start with a lowercase ASCII letter and contain '
      'only lowercase ASCII letters, digits, underscores, and hyphens.';

  /// Returns whether [name] is a valid build target name.
  ///
  /// A valid target name must start with a lowercase ASCII letter (`a-z`) and
  /// may contain only lowercase ASCII letters, digits (`0-9`), underscores
  /// (`_`), and hyphens (`-`).
  static bool isValidName(String name) => _validNamePattern.hasMatch(name);

  /// Map key for [artifacts].
  static const String artifactsKey = 'artifacts';

  /// Map key for [description].
  static const String descriptionKey = 'description';

  /// Map key for [flags].
  static const String flagsKey = 'flags';

  /// Map key for [hostArtifacts].
  static const String hostArtifactsKey = 'hostArtifacts';

  /// Map key for [name].
  static const String nameKey = 'name';

  /// Map key for [options].
  static const String optionsKey = 'options';

  /// Map key for [outputDir].
  static const String outputDirKey = 'outputDir';

  /// Map key for [supportedBuildModes].
  static const String supportedBuildModesKey = 'supportedBuildModes';

  /// Map key for [supportsFlavors].
  static const String supportsFlavorsKey = 'supportsFlavors';

  /// Map key for [supportsSizeAnalysis].
  static const String supportsSizeAnalysisKey = 'supportsSizeAnalysis';

  /// Map key for [targetPlatforms].
  static const String targetPlatformsKey = 'targetPlatforms';

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

  /// The set of target platform identifiers supported by this build target,
  /// preserving insertion order.
  ///
  /// * When empty (`const <String>{}`), no `--target-platform` CLI option is
  ///   registered and [ExtensionBuildContext.targetPlatform] is `null`.
  /// * When containing a single platform, `targetPlatforms.single` is passed
  ///   automatically as [ExtensionBuildContext.targetPlatform] without adding a
  ///   redundant `--target-platform` CLI option.
  /// * When containing multiple platforms, `flutter build <name>` registers a
  ///   `--target-platform` CLI option defaulting to `targetPlatforms.first`.
  final Set<String> targetPlatforms;

  /// Engine artifacts required by this build target, resolved for the active
  /// target platform and [BuildMode].
  final Set<ExtensionArtifact> artifacts;

  /// Custom boolean CLI flags exposed on `flutter build <name>`.
  final List<ExtensionFlag> flags;

  /// Custom string CLI options exposed on `flutter build <name>`.
  final List<ExtensionOption> options;

  /// Compilation modes supported by this target on `flutter build <name>`.
  final Set<BuildMode> supportedBuildModes;

  /// Whether this target supports `--flavor` on `flutter build <name>`.
  final bool supportsFlavors;

  /// Whether this target supports `--analyze-size` and `--code-size-directory`
  /// on `flutter build <name>`.
  final bool supportsSizeAnalysis;

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
  /// (when [targetPlatforms] is non-empty).
  final String outputDir;

  /// Serializes the build target to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    artifactsKey: artifacts.map((ExtensionArtifact a) => a.name).toList(),
    descriptionKey: description,
    if (flags.isNotEmpty) flagsKey: flags.map((ExtensionFlag f) => f.toMap()).toList(),
    hostArtifactsKey: hostArtifacts.map((ExtensionHostArtifact a) => a.name).toList(),
    nameKey: name,
    if (options.isNotEmpty) optionsKey: options.map((ExtensionOption o) => o.toMap()).toList(),
    outputDirKey: outputDir,
    supportedBuildModesKey: supportedBuildModes.map((BuildMode m) => m.cliName).toList(),
    if (supportsFlavors) supportsFlavorsKey: supportsFlavors,
    if (supportsSizeAnalysis) supportsSizeAnalysisKey: supportsSizeAnalysis,
    if (targetPlatforms.isNotEmpty) targetPlatformsKey: targetPlatforms.toList(),
  };

  @override
  String toString() =>
      'ExtensionBuildTarget(name: $name, targetPlatforms: $targetPlatforms, '
      'description: $description, artifacts: $artifacts, '
      'hostArtifacts: $hostArtifacts, flags: $flags, options: $options, '
      'supportedBuildModes: $supportedBuildModes, supportsFlavors: $supportsFlavors, '
      'supportsSizeAnalysis: $supportsSizeAnalysis, outputDir: $outputDir)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionBuildTarget &&
            other.description == description &&
            other.name == name &&
            _setEquality.equals(other.targetPlatforms, targetPlatforms) &&
            other.outputDir == outputDir &&
            _setEquality.equals(other.artifacts, artifacts) &&
            _listEquality.equals(other.flags, flags) &&
            _listEquality.equals(other.options, options) &&
            _setEquality.equals(other.supportedBuildModes, supportedBuildModes) &&
            other.supportsFlavors == supportsFlavors &&
            other.supportsSizeAnalysis == supportsSizeAnalysis &&
            _setEquality.equals(other.hostArtifacts, hostArtifacts));
  }

  @override
  int get hashCode => Object.hash(
    description,
    name,
    Object.hashAllUnordered(targetPlatforms),
    outputDir,
    Object.hashAllUnordered(artifacts),
    Object.hashAll(flags),
    Object.hashAll(options),
    Object.hashAllUnordered(supportedBuildModes),
    supportsFlavors,
    supportsSizeAnalysis,
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
  static bool isValidDepfileName(String name) => _isValidFileName(name);

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
  /// files into their build directory and [Depfile.parse] to read them back.
  ///
  /// Each entry must match [isValidDepfileName]. Relative paths inside each
  /// depfile are resolved against the project root directory and rewritten in
  /// place with normalized paths by the host after a successful build. If a
  /// declared depfile is missing or invalid after a successful build, the host
  /// logs an error and disables incremental build caching for this target
  /// without failing the build.
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

/// Representation of a build result returned by a tool extension on success.
@immutable
class ExtensionBuildResult {
  const ExtensionBuildResult({
    this.aotSnapshotFileName = 'libapp.so',
    this.bundleDirectoryUri,
    this.executableUri,
  }) : assert(aotSnapshotFileName != '');

  /// Deserializes an [ExtensionBuildResult] from a JSON-serializable map.
  ///
  /// Throws a [FormatException] if [aotSnapshotFileNameKey] is invalid, if
  /// [bundleDirectoryUriKey] is present and not a valid directory `file:` URI,
  /// or if [executableUriKey] is present and not a valid artifact `file:` URI.
  factory ExtensionBuildResult.fromJson(Map<String, Object?> json) {
    final String aotSnapshotFileName = json.optionalField<String>(
      aotSnapshotFileNameKey,
      defaultValue: 'libapp.so',
    );
    if (!_isValidFileName(aotSnapshotFileName)) {
      throw const FormatException(
        'Invalid "$aotSnapshotFileNameKey" in ExtensionBuildResult: '
        'must be a non-empty file name without path separators.',
      );
    }
    return ExtensionBuildResult(
      aotSnapshotFileName: aotSnapshotFileName,
      bundleDirectoryUri: _parseBundleDirectoryUri(json),
      executableUri: _parseExecutableUri(json),
    );
  }

  static Uri? _parseBundleDirectoryUri(Map<String, Object?> json) {
    final String? raw = json.nullableField<String>(bundleDirectoryUriKey);
    if (raw == null) {
      return null;
    }
    final Uri? uri = Uri.tryParse(raw);
    if (uri != null && uri.isValidDirectoryUri) {
      return uri;
    }
    throw FormatException(
      'Invalid "$bundleDirectoryUriKey": expected trailing-slash-terminated absolute file: URI, got "$raw".',
    );
  }

  static Uri? _parseExecutableUri(Map<String, Object?> json) {
    final String? raw = json.nullableField<String>(executableUriKey);
    if (raw == null) {
      return null;
    }
    final Uri? uri = Uri.tryParse(raw);
    if (uri != null && uri.isValidArtifactUri) {
      return uri;
    }
    throw const FormatException(
      'Invalid "$executableUriKey" in ExtensionBuildResult: must be an absolute file:// URI.',
    );
  }

  /// Map key for [aotSnapshotFileName].
  static const String aotSnapshotFileNameKey = 'aotSnapshotFileName';

  /// Map key for [bundleDirectoryUri].
  static const String bundleDirectoryUriKey = 'bundleDirectoryUri';

  /// Map key for [executableUri].
  static const String executableUriKey = 'executableUri';

  /// File name of the compiled AOT snapshot inside [bundleDirectoryUri] used
  /// during `--analyze-size` inspection.
  final String aotSnapshotFileName;

  /// Optional trailing-slash-terminated `file:` directory URI to the unpacked
  /// output bundle directory inspected during `--analyze-size`.
  final Uri? bundleDirectoryUri;

  /// Optional absolute `file:` URI to the built application executable or bundle.
  final Uri? executableUri;

  /// Serializes the build result to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    aotSnapshotFileNameKey: aotSnapshotFileName,
    bundleDirectoryUriKey: ?bundleDirectoryUri?.toString(),
    executableUriKey: ?executableUri?.toString(),
  };

  @override
  String toString() =>
      'ExtensionBuildResult(aotSnapshotFileName: $aotSnapshotFileName, '
      'bundleDirectoryUri: $bundleDirectoryUri, executableUri: $executableUri)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionBuildResult &&
            other.aotSnapshotFileName == aotSnapshotFileName &&
            other.bundleDirectoryUri == bundleDirectoryUri &&
            other.executableUri == executableUri);
  }

  @override
  int get hashCode => Object.hash(aotSnapshotFileName, bundleDirectoryUri, executableUri);
}

bool _isValidFileName(String name) =>
    name.isNotEmpty && name != '.' && name != '..' && !name.contains('/') && !name.contains(r'\');
