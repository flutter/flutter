// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'build_system/constants.dart';
/// @docImport 'build_system/source.dart';
/// @docImport 'options.dart';
library;

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'build.dart';
import 'json_utils.dart';

const _listEquality = ListEquality<Object?>();

/// Context passed to an extension target's `BuildTarget.build` method.
@immutable
class ExtensionBuildContext {
  const ExtensionBuildContext({
    required this.buildMode,
    required this.flutterRoot,
    required this.mainPath,
    required this.outputDir,
    required this.projectRoot,
    required this.resolvedArtifacts,
    required this.trackWidgetCreation,
    required this.treeShakeIcons,
    this.buildFlags = const <String, bool>{},
    this.buildName,
    this.buildNumber,
    this.buildOptions = const <String, String>{},
    this.codeSizeDirectory,
    this.configuration = const <String, Object?>{},
    this.dartDefines = const <String, String>{},
    this.dartObfuscation = false,
    this.extraFrontEndOptions = const <String>[],
    this.extraGenSnapshotOptions = const <String>[],
    this.flavor,
    this.splitDebugInfo,
    this.targetDeviceId,
    this.targetPlatform,
  });

  /// Deserializes an [ExtensionBuildContext] from a JSON-serializable map.
  factory ExtensionBuildContext.fromJson(Map<String, Object?> json) {
    return ExtensionBuildContext(
      buildMode: _parseBuildMode(json, buildModeKey),
      flutterRoot: _parseDirectoryUri(json, flutterRootKey),
      mainPath: json.requiredField<String>(mainPathKey),
      outputDir: _parseDirectoryUri(json, outputDirKey),
      projectRoot: _parseDirectoryUri(json, projectRootKey),
      resolvedArtifacts: _parseRequiredStringMap(json, resolvedArtifactsKey),
      trackWidgetCreation: json.requiredField<bool>(trackWidgetCreationKey),
      treeShakeIcons: json.requiredField<bool>(treeShakeIconsKey),
      buildFlags: _parseOptionalBoolMap(json, buildFlagsKey),
      buildName: json.nullableField<String>(buildNameKey),
      buildNumber: json.nullableField<String>(buildNumberKey),
      buildOptions: _parseOptionalStringMap(json, buildOptionsKey),
      codeSizeDirectory: _parseOptionalDirectoryUri(json, codeSizeDirectoryKey),
      configuration: _parseOptionalConfigurationMap(json, configurationKey),
      dartDefines: _parseOptionalStringMap(json, dartDefinesKey),
      dartObfuscation: json.requiredField<bool>(dartObfuscationKey),
      extraFrontEndOptions: json.stringIterable(extraFrontEndOptionsKey).toList(),
      extraGenSnapshotOptions: json.stringIterable(extraGenSnapshotOptionsKey).toList(),
      flavor: json.nullableField<String>(flavorKey),
      splitDebugInfo: _parseOptionalDirectoryUri(json, splitDebugInfoKey),
      targetDeviceId: json.nullableField<String>(targetDeviceIdKey),
      targetPlatform: json.nullableField<String>(targetPlatformKey),
    );
  }

  /// Map key for [buildFlags].
  static const String buildFlagsKey = 'buildFlags';

  /// Map key for [buildMode].
  static const String buildModeKey = 'buildMode';

  /// Map key for [buildName].
  static const String buildNameKey = 'buildName';

  /// Map key for [buildNumber].
  static const String buildNumberKey = 'buildNumber';

  /// Map key for [buildOptions].
  static const String buildOptionsKey = 'buildOptions';

  /// Map key for [codeSizeDirectory].
  static const String codeSizeDirectoryKey = 'codeSizeDirectory';

  /// Map key for [configuration].
  static const String configurationKey = 'configuration';

  /// Map key for [dartDefines].
  static const String dartDefinesKey = 'dartDefines';

  /// Map key for [dartObfuscation].
  static const String dartObfuscationKey = 'dartObfuscation';

  /// Map key for [extraFrontEndOptions].
  static const String extraFrontEndOptionsKey = 'extraFrontEndOptions';

  /// Map key for [extraGenSnapshotOptions].
  static const String extraGenSnapshotOptionsKey = 'extraGenSnapshotOptions';

  /// Map key for [flavor].
  static const String flavorKey = 'flavor';

  /// Map key for [flutterRoot].
  static const String flutterRootKey = 'flutterRoot';

  /// Map key for [mainPath].
  static const String mainPathKey = 'mainPath';

  /// Map key for [outputDir].
  static const String outputDirKey = 'outputDir';

  /// Map key for [projectRoot].
  static const String projectRootKey = 'projectRoot';

  /// Map key for [resolvedArtifacts].
  static const String resolvedArtifactsKey = 'resolvedArtifacts';

  /// Map key for [splitDebugInfo].
  static const String splitDebugInfoKey = 'splitDebugInfo';

  /// Map key for [targetDeviceId].
  static const String targetDeviceIdKey = 'targetDeviceId';

  /// Map key for [targetPlatform].
  static const String targetPlatformKey = 'targetPlatform';

  /// Map key for [trackWidgetCreation].
  static const String trackWidgetCreationKey = 'trackWidgetCreation';

  /// Map key for [treeShakeIcons].
  static const String treeShakeIconsKey = 'treeShakeIcons';

  /// Values of custom [ExtensionFlag]s registered by the build target.
  final Map<String, bool> buildFlags;

  /// The compilation mode for the build.
  final BuildMode buildMode;

  /// The user-visible build name (e.g. `'1.0.0'`), if specified.
  final String? buildName;

  /// The build number (e.g. `'42'`), if specified.
  final String? buildNumber;

  /// Values of custom [ExtensionOption]s registered by the build target,
  /// omitting options that were neither passed nor given a default.
  final Map<String, String> buildOptions;

  /// Directory `file:` URI where code size analysis files should be written, if requested.
  final Uri? codeSizeDirectory;

  /// Snapshot of the extension's owned `flutter config` settings (`bool` for
  /// feature flags and `String` for string options, omitting unset keys).
  final Map<String, Object?> configuration;

  /// Compile-time environment declarations passed via `--dart-define` and `--dart-define-from-file`.
  final Map<String, String> dartDefines;

  /// Whether Dart symbol obfuscation (`--obfuscate`) is enabled.
  final bool dartObfuscation;

  /// Additional options passed to the Dart front-end compiler (`--extra-front-end-options`).
  final List<String> extraFrontEndOptions;

  /// Additional options passed to `gen_snapshot` (`--extra-gen-snapshot-options`).
  final List<String> extraGenSnapshotOptions;

  /// The application flavor (`--flavor`), if specified.
  final String? flavor;

  /// The absolute directory URI (ending with `/`) to the Flutter SDK root directory.
  final Uri flutterRoot;

  /// The path to the main entrypoint file (typically `<project>/lib/main.dart`).
  final String mainPath;

  /// The absolute directory URI (ending with `/`) where final build outputs should be placed.
  final Uri outputDir;

  /// The absolute directory URI (ending with `/`) to the root directory of the Flutter project being built.
  final Uri projectRoot;

  /// A map of resolved engine artifact names to their absolute paths on the host.
  ///
  /// Keys correspond to [ExtensionArtifact.name] or [ExtensionHostArtifact.name] values.
  final Map<String, String> resolvedArtifacts;

  /// Directory `file:` URI where split debug symbols (`--split-debug-info`) should be written, if requested.
  final Uri? splitDebugInfo;

  /// The target device ID when building for a specific device (`-d`), if known.
  final String? targetDeviceId;

  /// The active target platform identifier for this build (e.g. `'linux-x64'`).
  final String? targetPlatform;

  /// Whether widget creation locations are tracked by the kernel transformer.
  final bool trackWidgetCreation;

  /// Whether icon font tree shaking (`--tree-shake-icons`) is enabled.
  final bool treeShakeIcons;

  /// Serializes this [ExtensionBuildContext] to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    if (buildFlags.isNotEmpty) buildFlagsKey: buildFlags,
    buildModeKey: buildMode.cliName,
    buildNameKey: ?buildName,
    buildNumberKey: ?buildNumber,
    if (buildOptions.isNotEmpty) buildOptionsKey: buildOptions,
    codeSizeDirectoryKey: ?codeSizeDirectory?.toString(),
    if (configuration.isNotEmpty) configurationKey: configuration,
    if (dartDefines.isNotEmpty) dartDefinesKey: dartDefines,
    dartObfuscationKey: dartObfuscation,
    if (extraFrontEndOptions.isNotEmpty) extraFrontEndOptionsKey: extraFrontEndOptions,
    if (extraGenSnapshotOptions.isNotEmpty) extraGenSnapshotOptionsKey: extraGenSnapshotOptions,
    flavorKey: ?flavor,
    flutterRootKey: flutterRoot.toString(),
    mainPathKey: mainPath,
    outputDirKey: outputDir.toString(),
    projectRootKey: projectRoot.toString(),
    resolvedArtifactsKey: resolvedArtifacts,
    splitDebugInfoKey: ?splitDebugInfo?.toString(),
    targetDeviceIdKey: ?targetDeviceId,
    targetPlatformKey: ?targetPlatform,
    trackWidgetCreationKey: trackWidgetCreation,
    treeShakeIconsKey: treeShakeIcons,
  };

  @override
  String toString() =>
      'ExtensionBuildContext(buildMode: $buildMode, flutterRoot: $flutterRoot, '
      'mainPath: $mainPath, outputDir: $outputDir, projectRoot: $projectRoot, '
      'resolvedArtifacts: $resolvedArtifacts, trackWidgetCreation: $trackWidgetCreation, '
      'treeShakeIcons: $treeShakeIcons, targetPlatform: $targetPlatform, '
      'flavor: $flavor, buildName: $buildName, buildNumber: $buildNumber, '
      'dartDefines: $dartDefines, dartObfuscation: $dartObfuscation, '
      'splitDebugInfo: $splitDebugInfo, codeSizeDirectory: $codeSizeDirectory, '
      'extraFrontEndOptions: $extraFrontEndOptions, '
      'extraGenSnapshotOptions: $extraGenSnapshotOptions, '
      'targetDeviceId: $targetDeviceId, configuration: $configuration, '
      'buildFlags: $buildFlags, buildOptions: $buildOptions)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionBuildContext &&
            other.buildMode == buildMode &&
            other.flutterRoot == flutterRoot &&
            other.mainPath == mainPath &&
            other.outputDir == outputDir &&
            other.projectRoot == projectRoot &&
            _mapEquals(other.resolvedArtifacts, resolvedArtifacts) &&
            other.trackWidgetCreation == trackWidgetCreation &&
            other.treeShakeIcons == treeShakeIcons &&
            _mapEquals(other.buildFlags, buildFlags) &&
            other.buildName == buildName &&
            other.buildNumber == buildNumber &&
            _mapEquals(other.buildOptions, buildOptions) &&
            other.codeSizeDirectory == codeSizeDirectory &&
            _mapEquals(other.configuration, configuration) &&
            _mapEquals(other.dartDefines, dartDefines) &&
            other.dartObfuscation == dartObfuscation &&
            _listEquals(other.extraFrontEndOptions, extraFrontEndOptions) &&
            _listEquals(other.extraGenSnapshotOptions, extraGenSnapshotOptions) &&
            other.flavor == flavor &&
            other.splitDebugInfo == splitDebugInfo &&
            other.targetDeviceId == targetDeviceId &&
            other.targetPlatform == targetPlatform);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    buildMode,
    flutterRoot,
    mainPath,
    outputDir,
    projectRoot,
    _mapHash(resolvedArtifacts),
    trackWidgetCreation,
    treeShakeIcons,
    _mapHash(buildFlags),
    buildName,
    buildNumber,
    _mapHash(buildOptions),
    codeSizeDirectory,
    _mapHash(configuration),
    _mapHash(dartDefines),
    dartObfuscation,
    Object.hashAll(extraFrontEndOptions),
    Object.hashAll(extraGenSnapshotOptions),
    flavor,
    splitDebugInfo,
    targetDeviceId,
    targetPlatform,
  ]);
}

/// Context passed to an extension target's `AssembleTarget.build` method,
/// containing only the build inputs hashed into the `flutter assemble` environment.
@immutable
class ExtensionAssembleContext {
  const ExtensionAssembleContext({
    required this.buildDir,
    required this.buildMode,
    required this.flutterRoot,
    required this.mainPath,
    required this.outputDir,
    required this.projectRoot,
    required this.resolvedArtifacts,
    required this.trackWidgetCreation,
    required this.treeShakeIcons,
    this.buildName,
    this.buildNumber,
    this.codeSizeDirectory,
    this.configuration = const <String, Object?>{},
    this.dartDefines = const <String, String>{},
    this.dartObfuscation = false,
    this.extraDefines = const <String, String>{},
    this.extraFrontEndOptions = const <String>[],
    this.extraGenSnapshotOptions = const <String>[],
    this.flavor,
    this.splitDebugInfo,
    this.targetPlatform,
  });

  /// Deserializes an [ExtensionAssembleContext] from a JSON-serializable map.
  factory ExtensionAssembleContext.fromJson(Map<String, Object?> json) {
    return ExtensionAssembleContext(
      buildDir: _parseDirectoryUri(json, buildDirKey),
      buildMode: _parseBuildMode(json, buildModeKey),
      flutterRoot: _parseDirectoryUri(json, flutterRootKey),
      mainPath: json.requiredField<String>(mainPathKey),
      outputDir: _parseDirectoryUri(json, outputDirKey),
      projectRoot: _parseDirectoryUri(json, projectRootKey),
      resolvedArtifacts: _parseRequiredStringMap(json, resolvedArtifactsKey),
      trackWidgetCreation: json.requiredField<bool>(trackWidgetCreationKey),
      treeShakeIcons: json.requiredField<bool>(treeShakeIconsKey),
      buildName: json.nullableField<String>(buildNameKey),
      buildNumber: json.nullableField<String>(buildNumberKey),
      codeSizeDirectory: _parseOptionalDirectoryUri(json, codeSizeDirectoryKey),
      configuration: _parseOptionalConfigurationMap(json, configurationKey),
      dartDefines: _parseOptionalStringMap(json, dartDefinesKey),
      dartObfuscation: json.requiredField<bool>(dartObfuscationKey),
      extraDefines: _parseOptionalStringMap(json, extraDefinesKey),
      extraFrontEndOptions: json.stringIterable(extraFrontEndOptionsKey).toList(),
      extraGenSnapshotOptions: json.stringIterable(extraGenSnapshotOptionsKey).toList(),
      flavor: json.nullableField<String>(flavorKey),
      splitDebugInfo: _parseOptionalDirectoryUri(json, splitDebugInfoKey),
      targetPlatform: json.nullableField<String>(targetPlatformKey),
    );
  }

  /// Map key for [buildDir].
  static const String buildDirKey = 'buildDir';

  /// Map key for [buildMode].
  static const String buildModeKey = 'buildMode';

  /// Map key for [buildName].
  static const String buildNameKey = 'buildName';

  /// Map key for [buildNumber].
  static const String buildNumberKey = 'buildNumber';

  /// Map key for [codeSizeDirectory].
  static const String codeSizeDirectoryKey = 'codeSizeDirectory';

  /// Map key for [configuration].
  static const String configurationKey = 'configuration';

  /// Map key for [dartDefines].
  static const String dartDefinesKey = 'dartDefines';

  /// Map key for [dartObfuscation].
  static const String dartObfuscationKey = 'dartObfuscation';

  /// Map key for [extraDefines].
  static const String extraDefinesKey = 'extraDefines';

  /// Map key for [extraFrontEndOptions].
  static const String extraFrontEndOptionsKey = 'extraFrontEndOptions';

  /// Map key for [extraGenSnapshotOptions].
  static const String extraGenSnapshotOptionsKey = 'extraGenSnapshotOptions';

  /// Map key for [flavor].
  static const String flavorKey = 'flavor';

  /// Map key for [flutterRoot].
  static const String flutterRootKey = 'flutterRoot';

  /// Map key for [mainPath].
  static const String mainPathKey = 'mainPath';

  /// Map key for [outputDir].
  static const String outputDirKey = 'outputDir';

  /// Map key for [projectRoot].
  static const String projectRootKey = 'projectRoot';

  /// Map key for [resolvedArtifacts].
  static const String resolvedArtifactsKey = 'resolvedArtifacts';

  /// Map key for [splitDebugInfo].
  static const String splitDebugInfoKey = 'splitDebugInfo';

  /// Map key for [targetPlatform].
  static const String targetPlatformKey = 'targetPlatform';

  /// Map key for [trackWidgetCreation].
  static const String trackWidgetCreationKey = 'trackWidgetCreation';

  /// Map key for [treeShakeIcons].
  static const String treeShakeIconsKey = 'treeShakeIcons';

  /// The absolute directory URI (ending with `/`) used for intermediate build
  /// artifacts (matching [BuiltInPlaceholders.buildDir]).
  final Uri buildDir;

  /// The compilation mode for the build.
  final BuildMode buildMode;

  /// The user-visible build name (e.g. `'1.0.0'`), if specified.
  final String? buildName;

  /// The build number (e.g. `'42'`), if specified.
  final String? buildNumber;

  /// Directory `file:` URI where code size analysis files should be written, if requested.
  final Uri? codeSizeDirectory;

  /// Snapshot of the extension's owned `flutter config` settings (`bool` for
  /// feature flags and `String` for string options, omitting unset keys),
  /// hashed into the `flutter assemble` environment inputs.
  final Map<String, Object?> configuration;

  /// Compile-time environment declarations passed via `--dart-define` and `--dart-define-from-file`.
  final Map<String, String> dartDefines;

  /// Whether Dart symbol obfuscation (`--obfuscate`) is enabled.
  final bool dartObfuscation;

  /// Non-standard `-dKey=Value` defines passed to `flutter assemble` or produced
  /// by upstream assemble targets.
  final Map<String, String> extraDefines;

  /// Additional options passed to the Dart front-end compiler (`--extra-front-end-options`).
  final List<String> extraFrontEndOptions;

  /// Additional options passed to `gen_snapshot` (`--extra-gen-snapshot-options`).
  final List<String> extraGenSnapshotOptions;

  /// The application flavor (`--flavor`), if specified.
  final String? flavor;

  /// The absolute directory URI (ending with `/`) to the Flutter SDK root directory.
  final Uri flutterRoot;

  /// The path to the main entrypoint file (typically `<project>/lib/main.dart`).
  final String mainPath;

  /// The absolute directory URI (ending with `/`) where final build outputs should be placed.
  final Uri outputDir;

  /// The absolute directory URI (ending with `/`) to the root directory of the Flutter project being built.
  final Uri projectRoot;

  /// A map of resolved engine artifact names to their absolute paths on the host.
  ///
  /// Keys correspond to [ExtensionArtifact.name] or [ExtensionHostArtifact.name] values.
  final Map<String, String> resolvedArtifacts;

  /// Directory `file:` URI where split debug symbols (`--split-debug-info`) should be written, if requested.
  final Uri? splitDebugInfo;

  /// The active target platform identifier for this assemble invocation (e.g. `'linux-x64'`).
  final String? targetPlatform;

  /// Whether widget creation locations are tracked by the kernel transformer.
  final bool trackWidgetCreation;

  /// Whether icon font tree shaking (`--tree-shake-icons`) is enabled.
  final bool treeShakeIcons;

  /// Serializes this [ExtensionAssembleContext] to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    buildDirKey: buildDir.toString(),
    buildModeKey: buildMode.cliName,
    buildNameKey: ?buildName,
    buildNumberKey: ?buildNumber,
    codeSizeDirectoryKey: ?codeSizeDirectory?.toString(),
    if (configuration.isNotEmpty) configurationKey: configuration,
    if (dartDefines.isNotEmpty) dartDefinesKey: dartDefines,
    dartObfuscationKey: dartObfuscation,
    if (extraDefines.isNotEmpty) extraDefinesKey: extraDefines,
    if (extraFrontEndOptions.isNotEmpty) extraFrontEndOptionsKey: extraFrontEndOptions,
    if (extraGenSnapshotOptions.isNotEmpty) extraGenSnapshotOptionsKey: extraGenSnapshotOptions,
    flavorKey: ?flavor,
    flutterRootKey: flutterRoot.toString(),
    mainPathKey: mainPath,
    outputDirKey: outputDir.toString(),
    projectRootKey: projectRoot.toString(),
    resolvedArtifactsKey: resolvedArtifacts,
    splitDebugInfoKey: ?splitDebugInfo?.toString(),
    targetPlatformKey: ?targetPlatform,
    trackWidgetCreationKey: trackWidgetCreation,
    treeShakeIconsKey: treeShakeIcons,
  };

  @override
  String toString() =>
      'ExtensionAssembleContext(buildDir: $buildDir, buildMode: $buildMode, '
      'flutterRoot: $flutterRoot, mainPath: $mainPath, outputDir: $outputDir, '
      'projectRoot: $projectRoot, resolvedArtifacts: $resolvedArtifacts, '
      'trackWidgetCreation: $trackWidgetCreation, treeShakeIcons: $treeShakeIcons, '
      'targetPlatform: $targetPlatform, flavor: $flavor, buildName: $buildName, '
      'buildNumber: $buildNumber, dartDefines: $dartDefines, '
      'dartObfuscation: $dartObfuscation, splitDebugInfo: $splitDebugInfo, '
      'codeSizeDirectory: $codeSizeDirectory, '
      'extraFrontEndOptions: $extraFrontEndOptions, '
      'extraGenSnapshotOptions: $extraGenSnapshotOptions, '
      'configuration: $configuration, extraDefines: $extraDefines)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionAssembleContext &&
            other.buildDir == buildDir &&
            other.buildMode == buildMode &&
            other.flutterRoot == flutterRoot &&
            other.mainPath == mainPath &&
            other.outputDir == outputDir &&
            other.projectRoot == projectRoot &&
            _mapEquals(other.resolvedArtifacts, resolvedArtifacts) &&
            other.trackWidgetCreation == trackWidgetCreation &&
            other.treeShakeIcons == treeShakeIcons &&
            other.buildName == buildName &&
            other.buildNumber == buildNumber &&
            other.codeSizeDirectory == codeSizeDirectory &&
            _mapEquals(other.configuration, configuration) &&
            _mapEquals(other.dartDefines, dartDefines) &&
            other.dartObfuscation == dartObfuscation &&
            _mapEquals(other.extraDefines, extraDefines) &&
            _listEquals(other.extraFrontEndOptions, extraFrontEndOptions) &&
            _listEquals(other.extraGenSnapshotOptions, extraGenSnapshotOptions) &&
            other.flavor == flavor &&
            other.splitDebugInfo == splitDebugInfo &&
            other.targetPlatform == targetPlatform);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    buildDir,
    buildMode,
    flutterRoot,
    mainPath,
    outputDir,
    projectRoot,
    _mapHash(resolvedArtifacts),
    trackWidgetCreation,
    treeShakeIcons,
    buildName,
    buildNumber,
    codeSizeDirectory,
    _mapHash(configuration),
    _mapHash(dartDefines),
    dartObfuscation,
    _mapHash(extraDefines),
    Object.hashAll(extraFrontEndOptions),
    Object.hashAll(extraGenSnapshotOptions),
    flavor,
    splitDebugInfo,
    targetPlatform,
  ]);
}

BuildMode _parseBuildMode(Map<String, Object?> json, String key) {
  final String rawBuildMode = json.requiredField<String>(key);
  try {
    return BuildMode.fromCliName(rawBuildMode);
  } on ArgumentError {
    throw FormatException('Missing or invalid "$key" parameter.');
  }
}

Uri _parseDirectoryUri(Map<String, Object?> json, String key) {
  final String raw = json.requiredField<String>(key);
  final Uri? uri = Uri.tryParse(raw);
  if (uri == null || !uri.hasAbsolutePath || (uri.hasScheme && !uri.isScheme('file'))) {
    throw FormatException('Missing or invalid "$key" parameter.');
  }
  return uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');
}

Uri? _parseOptionalDirectoryUri(Map<String, Object?> json, String key) {
  final String? raw = json.nullableField<String>(key);
  if (raw == null) {
    return null;
  }
  final Uri? uri = Uri.tryParse(raw);
  if (uri == null || !uri.isValidDirectoryUri) {
    throw FormatException(
      'Invalid "$key": expected trailing-slash-terminated absolute file: URI, got "$raw".',
    );
  }
  return uri;
}

Map<String, String> _parseRequiredStringMap(Map<String, Object?> json, String key) {
  final Map<String, Object?> raw = json.requiredField<Map<String, Object?>>(key);
  return _parseStringMap(raw, key);
}

Map<String, String> _parseOptionalStringMap(Map<String, Object?> json, String key) {
  final Map<String, Object?>? raw = json.nullableField<Map<String, Object?>>(key);
  if (raw == null) {
    return const <String, String>{};
  }
  return _parseStringMap(raw, key);
}

Map<String, String> _parseStringMap(Map<String, Object?> raw, String key) {
  final result = <String, String>{};
  for (final MapEntry(key: String entryKey, :Object? value) in raw.entries) {
    if (value is! String) {
      throw FormatException(
        'Invalid "$key" parameter: Invalid "$entryKey": expected String, got ${value.runtimeType}.',
      );
    }
    result[entryKey] = value;
  }
  return result;
}

Map<String, Object?> _parseOptionalConfigurationMap(Map<String, Object?> json, String key) {
  final Map<String, Object?>? raw = json.nullableField<Map<String, Object?>>(key);
  if (raw == null) {
    return const <String, Object?>{};
  }
  final result = <String, Object?>{};
  for (final MapEntry(key: String entryKey, :Object? value) in raw.entries) {
    if (value is! bool && value is! String) {
      throw FormatException(
        'Invalid "$key" entry for "$entryKey": expected bool or String, got ${value.runtimeType}.',
      );
    }
    result[entryKey] = value;
  }
  return result;
}

Map<String, bool> _parseOptionalBoolMap(Map<String, Object?> json, String key) {
  final Map<String, Object?>? raw = json.nullableField<Map<String, Object?>>(key);
  if (raw == null) {
    return const <String, bool>{};
  }
  final result = <String, bool>{};
  for (final MapEntry(key: String entryKey, :Object? value) in raw.entries) {
    if (value is! bool) {
      throw FormatException(
        'Invalid "$key" entry for "$entryKey": expected bool, got ${value.runtimeType}.',
      );
    }
    result[entryKey] = value;
  }
  return result;
}

int _mapHash<K, V>(Map<K, V> map) => Object.hashAllUnordered(<int>[
  for (final MapEntry(:K key, :V value) in map.entries) Object.hash(key, value),
]);

bool _listEquals<T>(List<T> a, List<T> b) => _listEquality.equals(a, b);

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) =>
    const MapEquality<Object?, Object?>().equals(a, b);
