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

/// A boolean CLI flag declared by a custom [ExtensionBuildTarget].
@immutable
class BuildFlag {
  const BuildFlag({
    required this.help,
    required this.name,
    this.abbr,
    this.defaultsTo = false,
    this.negatable = true,
  }) : assert(name != ''),
       assert(abbr == null || abbr.length == 1);

  /// Deserializes a [BuildFlag] from a JSON-serializable map.
  factory BuildFlag.fromJson(Map<String, Object?> json) {
    final String name = json.requiredField<String>(nameKey);
    if (name.isEmpty) {
      throw const FormatException('Invalid "$nameKey" in BuildFlag: must not be empty.');
    }
    final String? abbr = json.nullableField<String>(abbrKey);
    if (abbr != null && abbr.length != 1) {
      throw const FormatException('Invalid "$abbrKey" in BuildFlag: must be a single character.');
    }
    return BuildFlag(
      help: json.requiredField<String>(helpKey),
      name: name,
      abbr: abbr,
      defaultsTo: json.requiredField<bool>(defaultsToKey),
      negatable: json.requiredField<bool>(negatableKey),
    );
  }

  /// Map key for [abbr].
  static const String abbrKey = 'abbr';

  /// Map key for [defaultsTo].
  static const String defaultsToKey = 'defaultsTo';

  /// Map key for [help].
  static const String helpKey = 'help';

  /// Map key for [name].
  static const String nameKey = 'name';

  /// Map key for [negatable].
  static const String negatableKey = 'negatable';

  /// Deserializes a list of [BuildFlag] objects from JSON.
  static List<BuildFlag> listFromJson(Object? raw) {
    if (raw == null) {
      return const <BuildFlag>[];
    }
    if (raw is! List<Object?>) {
      throw FormatException('Invalid BuildFlag list: expected List, got ${raw.runtimeType}.');
    }
    return <BuildFlag>[
      for (final Object? item in raw)
        if (item case final Map<String, Object?> map)
          BuildFlag.fromJson(map)
        else
          throw FormatException(
            'Invalid BuildFlag element: expected Map<String, Object?>, got ${item.runtimeType}.',
          ),
    ];
  }

  /// Optional single-character abbreviation for this flag.
  final String? abbr;

  /// The default boolean value for this flag when not specified on the CLI.
  final bool defaultsTo;

  /// Help text displayed in `flutter build <target> --help`.
  final String help;

  /// The CLI flag name (without leading `--`).
  final String name;

  /// Whether this flag supports `--no-<name>`.
  final bool negatable;

  /// Serializes this [BuildFlag] to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    abbrKey: ?abbr,
    defaultsToKey: defaultsTo,
    helpKey: help,
    nameKey: name,
    negatableKey: negatable,
  };

  @override
  String toString() =>
      'BuildFlag(name: $name, help: $help, abbr: $abbr, '
      'defaultsTo: $defaultsTo, negatable: $negatable)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BuildFlag &&
            other.abbr == abbr &&
            other.defaultsTo == defaultsTo &&
            other.help == help &&
            other.name == name &&
            other.negatable == negatable);
  }

  @override
  int get hashCode => Object.hash(abbr, defaultsTo, help, name, negatable);
}

/// A string-valued CLI option declared by a custom [ExtensionBuildTarget].
@immutable
class BuildOption {
  const BuildOption({
    required this.help,
    required this.name,
    this.abbr,
    this.allowed,
    this.allowedHelp,
    this.defaultsTo,
    this.mandatory = false,
    this.valueHelp,
  }) : assert(name != ''),
       assert(abbr == null || abbr.length == 1);

  /// Deserializes a [BuildOption] from a JSON-serializable map.
  factory BuildOption.fromJson(Map<String, Object?> json) {
    final String name = json.requiredField<String>(nameKey);
    if (name.isEmpty) {
      throw const FormatException('Invalid "$nameKey" in BuildOption: must not be empty.');
    }
    final String? abbr = json.nullableField<String>(abbrKey);
    if (abbr != null && abbr.length != 1) {
      throw const FormatException('Invalid "$abbrKey" in BuildOption: must be a single character.');
    }
    final List<String>? allowed = json.containsKey(allowedKey) && json[allowedKey] != null
        ? json.stringIterable(allowedKey).toList()
        : null;
    final Map<String, Object?>? rawAllowedHelp = json.nullableField<Map<String, Object?>>(
      allowedHelpKey,
    );
    final Map<String, String>? allowedHelp = rawAllowedHelp != null
        ? _parseStringMap(rawAllowedHelp, allowedHelpKey)
        : null;
    return BuildOption(
      help: json.requiredField<String>(helpKey),
      name: name,
      abbr: abbr,
      allowed: allowed,
      allowedHelp: allowedHelp,
      defaultsTo: json.nullableField<String>(defaultsToKey),
      mandatory: json.requiredField<bool>(mandatoryKey),
      valueHelp: json.nullableField<String>(valueHelpKey),
    );
  }

  /// Map key for [abbr].
  static const String abbrKey = 'abbr';

  /// Map key for [allowed].
  static const String allowedKey = 'allowed';

  /// Map key for [allowedHelp].
  static const String allowedHelpKey = 'allowedHelp';

  /// Map key for [defaultsTo].
  static const String defaultsToKey = 'defaultsTo';

  /// Map key for [help].
  static const String helpKey = 'help';

  /// Map key for [mandatory].
  static const String mandatoryKey = 'mandatory';

  /// Map key for [name].
  static const String nameKey = 'name';

  /// Map key for [valueHelp].
  static const String valueHelpKey = 'valueHelp';

  /// Deserializes a list of [BuildOption] objects from JSON.
  static List<BuildOption> listFromJson(Object? raw) {
    if (raw == null) {
      return const <BuildOption>[];
    }
    if (raw is! List<Object?>) {
      throw FormatException('Invalid BuildOption list: expected List, got ${raw.runtimeType}.');
    }
    return <BuildOption>[
      for (final Object? item in raw)
        if (item case final Map<String, Object?> map)
          BuildOption.fromJson(map)
        else
          throw FormatException(
            'Invalid BuildOption element: expected Map<String, Object?>, got ${item.runtimeType}.',
          ),
    ];
  }

  /// Optional single-character abbreviation for this option.
  final String? abbr;

  /// Optional list of allowed string values for this option.
  final List<String>? allowed;

  /// Optional map from allowed values to their help descriptions.
  final Map<String, String>? allowedHelp;

  /// Optional default string value when not specified on the CLI.
  final String? defaultsTo;

  /// Help text displayed in `flutter build <target> --help`.
  final String help;

  /// Whether this option must be provided by the user.
  final bool mandatory;

  /// The CLI option name (without leading `--`).
  final String name;

  /// Optional placeholder name for the option value in `--help` output.
  final String? valueHelp;

  /// Serializes this [BuildOption] to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    abbrKey: ?abbr,
    allowedKey: ?allowed,
    allowedHelpKey: ?allowedHelp,
    defaultsToKey: ?defaultsTo,
    helpKey: help,
    mandatoryKey: mandatory,
    nameKey: name,
    valueHelpKey: ?valueHelp,
  };

  @override
  String toString() =>
      'BuildOption(name: $name, help: $help, abbr: $abbr, defaultsTo: $defaultsTo, '
      'allowed: $allowed, allowedHelp: $allowedHelp, valueHelp: $valueHelp, '
      'mandatory: $mandatory)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BuildOption &&
            other.abbr == abbr &&
            _nullableListEquals(other.allowed, allowed) &&
            _nullableMapEquals(other.allowedHelp, allowedHelp) &&
            other.defaultsTo == defaultsTo &&
            other.help == help &&
            other.mandatory == mandatory &&
            other.name == name &&
            other.valueHelp == valueHelp);
  }

  @override
  int get hashCode => Object.hash(
    abbr,
    allowed == null ? null : Object.hashAll(allowed!),
    allowedHelp == null ? null : _mapHash(allowedHelp!),
    defaultsTo,
    help,
    mandatory,
    name,
    valueHelp,
  );
}

/// Context passed to an extension target's `BuildTarget.build` method.
@immutable
class ExtensionBuildContext {
  ExtensionBuildContext({
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
    this.buildOptions = const <String, String?>{},
    this.codeSizeDirectory,
    this.configuration = const <String, String?>{},
    this.dartDefines = const <String, String>{},
    this.dartObfuscation = false,
    this.extraFrontEndOptions = const <String>[],
    this.extraGenSnapshotOptions = const <String>[],
    this.flavor,
    this.splitDebugInfo,
    this.targetDeviceId,
    this.targetPlatform,
  }) : assert(
         codeSizeDirectory == null || codeSizeDirectory.isValidDirectoryUri,
         'codeSizeDirectory must be an absolute file:// directory URI ending with "/".',
       ),
       assert(
         splitDebugInfo == null || splitDebugInfo.isValidDirectoryUri,
         'splitDebugInfo must be an absolute file:// directory URI ending with "/".',
       );

  /// Deserializes an [ExtensionBuildContext] from a JSON-serializable map.
  factory ExtensionBuildContext.fromJson(Map<String, Object?> json) {
    final String rawBuildMode = json.requiredField<String>(buildModeKey);
    final BuildMode mode;
    try {
      mode = BuildMode.fromCliName(rawBuildMode);
    } on ArgumentError {
      throw const FormatException('Missing or invalid "$buildModeKey" parameter.');
    }

    return ExtensionBuildContext(
      buildMode: mode,
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
      buildOptions: _parseOptionalNullableStringMap(json, buildOptionsKey),
      codeSizeDirectory: _parseOptionalDirectoryUri(json, codeSizeDirectoryKey),
      configuration: _parseOptionalNullableStringMap(json, configurationKey),
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

  /// Values of custom [BuildFlag]s registered by the build target.
  final Map<String, bool> buildFlags;

  /// The compilation mode for the build.
  final BuildMode buildMode;

  /// The user-visible build name (e.g. `'1.0.0'`), if specified.
  final String? buildName;

  /// The build number (e.g. `'42'`), if specified.
  final String? buildNumber;

  /// Values of custom [BuildOption]s registered by the build target.
  final Map<String, String?> buildOptions;

  /// Directory `file:` URI where code size analysis files should be written, if requested.
  final Uri? codeSizeDirectory;

  /// Snapshot of the extension's owned `flutter config` settings.
  final Map<String, String?> configuration;

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

  /// The path to the main entrypoint file (typically `lib/main.dart`).
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
        (other.runtimeType == ExtensionBuildContext &&
            other is ExtensionBuildContext &&
            _sameBuildFields(other));
  }

  bool _sameBuildFields(ExtensionBuildContext other) {
    return other.buildMode == buildMode &&
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
        other.targetPlatform == targetPlatform;
  }

  int get _buildFieldsHash => Object.hashAll(<Object?>[
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

  @override
  int get hashCode => _buildFieldsHash;
}

/// Context passed to an extension target's `AssembleTarget.build` method.
@immutable
class ExtensionAssembleContext extends ExtensionBuildContext {
  ExtensionAssembleContext({
    required this.buildDir,
    required super.buildMode,
    required super.flutterRoot,
    required super.mainPath,
    required super.outputDir,
    required super.projectRoot,
    required super.resolvedArtifacts,
    required super.trackWidgetCreation,
    required super.treeShakeIcons,
    super.buildFlags,
    super.buildName,
    super.buildNumber,
    super.buildOptions,
    super.codeSizeDirectory,
    super.configuration,
    super.dartDefines,
    super.dartObfuscation,
    this.extraDefines = const <String, String>{},
    super.extraFrontEndOptions,
    super.extraGenSnapshotOptions,
    super.flavor,
    super.splitDebugInfo,
    super.targetDeviceId,
    super.targetPlatform,
  });

  /// Deserializes an [ExtensionAssembleContext] from a JSON-serializable map.
  factory ExtensionAssembleContext.fromJson(Map<String, Object?> json) {
    final baseContext = ExtensionBuildContext.fromJson(json);
    final Uri buildDir = _parseDirectoryUri(json, buildDirKey);
    return ExtensionAssembleContext(
      buildDir: buildDir,
      buildMode: baseContext.buildMode,
      flutterRoot: baseContext.flutterRoot,
      mainPath: baseContext.mainPath,
      outputDir: baseContext.outputDir,
      projectRoot: baseContext.projectRoot,
      resolvedArtifacts: baseContext.resolvedArtifacts,
      trackWidgetCreation: baseContext.trackWidgetCreation,
      treeShakeIcons: baseContext.treeShakeIcons,
      buildFlags: baseContext.buildFlags,
      buildName: baseContext.buildName,
      buildNumber: baseContext.buildNumber,
      buildOptions: baseContext.buildOptions,
      codeSizeDirectory: baseContext.codeSizeDirectory,
      configuration: baseContext.configuration,
      dartDefines: baseContext.dartDefines,
      dartObfuscation: baseContext.dartObfuscation,
      extraDefines: _parseOptionalStringMap(json, extraDefinesKey),
      extraFrontEndOptions: baseContext.extraFrontEndOptions,
      extraGenSnapshotOptions: baseContext.extraGenSnapshotOptions,
      flavor: baseContext.flavor,
      splitDebugInfo: baseContext.splitDebugInfo,
      targetDeviceId: baseContext.targetDeviceId,
      targetPlatform: baseContext.targetPlatform,
    );
  }

  /// Map key for [buildDir].
  static const String buildDirKey = 'buildDir';

  /// Map key for [extraDefines].
  static const String extraDefinesKey = 'extraDefines';

  /// The absolute directory URI (ending with `/`) used for intermediate build
  /// artifacts (matching [BuiltInPlaceholders.buildDir]).
  final Uri buildDir;

  /// Non-standard `-dKey=Value` defines passed to `flutter assemble` or produced
  /// by upstream assemble targets.
  final Map<String, String> extraDefines;

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    ...super.toMap(),
    buildDirKey: buildDir.toString(),
    if (extraDefines.isNotEmpty) extraDefinesKey: extraDefines,
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
      'targetDeviceId: $targetDeviceId, configuration: $configuration, '
      'buildFlags: $buildFlags, buildOptions: $buildOptions, '
      'extraDefines: $extraDefines)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionAssembleContext &&
            _sameBuildFields(other) &&
            other.buildDir == buildDir &&
            _mapEquals(other.extraDefines, extraDefines));
  }

  @override
  int get hashCode => Object.hash(_buildFieldsHash, buildDir, _mapHash(extraDefines));
}

/// Representation of a custom `flutter build` subcommand target provided by a tool extension.
@immutable
class ExtensionBuildTarget {
  ExtensionBuildTarget({
    required this.description,
    required this.name,
    required this.outputDir,
    this.artifacts = const <ExtensionArtifact>{},
    this.buildFlags = const <BuildFlag>[],
    this.buildOptions = const <BuildOption>[],
    this.hostArtifacts = const <ExtensionHostArtifact>{},
    this.targetPlatform,
    this._targetPlatforms = const <String>{},
  }) : assert(isValidName(name), 'Invalid build target name "$name". $_invalidNameMessage'),
       assert(targetPlatform == null || targetPlatform != ''),
       assert(
         _targetPlatforms.every((String platform) => platform.isNotEmpty),
         'targetPlatforms must not contain empty platform names.',
       ),
       assert(
         targetPlatform == null ||
             _targetPlatforms.isEmpty ||
             _targetPlatforms.contains(targetPlatform),
         'targetPlatforms must contain targetPlatform when both are specified.',
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
    final Set<String> targetPlatforms = json.stringIterable(targetPlatformsKey).toSet();
    if (targetPlatforms.any((String platform) => platform.isEmpty)) {
      throw const FormatException(
        'Invalid "$targetPlatformsKey" in ExtensionBuildTarget: platform names must not be empty.',
      );
    }
    if (targetPlatform != null &&
        targetPlatforms.isNotEmpty &&
        !targetPlatforms.contains(targetPlatform)) {
      throw const FormatException(
        'Invalid "$targetPlatformsKey" in ExtensionBuildTarget: must contain "$targetPlatformKey" when both are specified.',
      );
    }
    return ExtensionBuildTarget(
      description: json.requiredField<String>(descriptionKey),
      name: name,
      outputDir: json.requiredField<String>(outputDirKey),
      artifacts: <ExtensionArtifact>{
        for (final String name in json.stringIterable(artifactsKey)) ExtensionArtifact(name),
      },
      buildFlags: BuildFlag.listFromJson(json[buildFlagsKey]),
      buildOptions: BuildOption.listFromJson(json[buildOptionsKey]),
      hostArtifacts: <ExtensionHostArtifact>{
        for (final String name in json.stringIterable(hostArtifactsKey))
          ExtensionHostArtifact(name),
      },
      targetPlatform: targetPlatform,
      targetPlatforms: targetPlatforms,
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

  /// Map key for [buildFlags].
  static const String buildFlagsKey = 'buildFlags';

  /// Map key for [buildOptions].
  static const String buildOptionsKey = 'buildOptions';

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

  /// The default target platform identifier (e.g. `'linux-x64'`, `'custom-embedder-arm64'`),
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

  final Set<String> _targetPlatforms;

  /// The set of target platform identifiers supported by this build target.
  ///
  /// Defaults to `{targetPlatform!}` when [targetPlatform] is non-null and no
  /// explicit `targetPlatforms` set was provided, or `{}` when platform-agnostic.
  /// When [targetPlatforms] contains more than one platform, `flutter build <name>`
  /// registers a `--target-platform` CLI option allowing the user to select among them.
  Set<String> get targetPlatforms => _targetPlatforms.isNotEmpty
      ? _targetPlatforms
      : (targetPlatform != null ? <String>{targetPlatform!} : const <String>{});

  /// Engine artifacts required by this build target, resolved for [targetPlatform]
  /// and the active [BuildMode].
  final Set<ExtensionArtifact> artifacts;

  /// Custom boolean CLI flags exposed on `flutter build <name>`.
  final List<BuildFlag> buildFlags;

  /// Custom string CLI options exposed on `flutter build <name>`.
  final List<BuildOption> buildOptions;

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

  /// Serializes the build target to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    descriptionKey: description,
    nameKey: name,
    targetPlatformKey: ?targetPlatform,
    if (targetPlatforms.isNotEmpty) targetPlatformsKey: targetPlatforms.toList(),
    artifactsKey: artifacts.map((ExtensionArtifact a) => a.name).toList(),
    if (buildFlags.isNotEmpty) buildFlagsKey: buildFlags.map((BuildFlag f) => f.toMap()).toList(),
    if (buildOptions.isNotEmpty)
      buildOptionsKey: buildOptions.map((BuildOption o) => o.toMap()).toList(),
    hostArtifactsKey: hostArtifacts.map((ExtensionHostArtifact a) => a.name).toList(),
    outputDirKey: outputDir,
  };

  @override
  String toString() =>
      'ExtensionBuildTarget(name: $name, targetPlatform: $targetPlatform, '
      'targetPlatforms: $targetPlatforms, description: $description, '
      'artifacts: $artifacts, hostArtifacts: $hostArtifacts, '
      'buildFlags: $buildFlags, buildOptions: $buildOptions, '
      'outputDir: $outputDir)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionBuildTarget &&
            other.description == description &&
            other.name == name &&
            other.targetPlatform == targetPlatform &&
            _setEquality.equals(other.targetPlatforms, targetPlatforms) &&
            other.outputDir == outputDir &&
            _setEquality.equals(other.artifacts, artifacts) &&
            _listEquality.equals(other.buildFlags, buildFlags) &&
            _listEquality.equals(other.buildOptions, buildOptions) &&
            _setEquality.equals(other.hostArtifacts, hostArtifacts));
  }

  @override
  int get hashCode => Object.hash(
    description,
    name,
    targetPlatform,
    Object.hashAllUnordered(targetPlatforms),
    outputDir,
    Object.hashAllUnordered(artifacts),
    Object.hashAll(buildFlags),
    Object.hashAll(buildOptions),
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

Map<String, String?> _parseOptionalNullableStringMap(Map<String, Object?> json, String key) {
  final Map<String, Object?>? raw = json.nullableField<Map<String, Object?>>(key);
  if (raw == null) {
    return const <String, String?>{};
  }
  final result = <String, String?>{};
  for (final MapEntry(key: String entryKey, :Object? value) in raw.entries) {
    if (value != null && value is! String) {
      throw FormatException(
        'Invalid "$key" entry for "$entryKey": expected String?, got ${value.runtimeType}.',
      );
    }
    result[entryKey] = value as String?;
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

bool _nullableListEquals<T>(List<T>? a, List<T>? b) => _listEquality.equals(a, b);

bool _nullableMapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
  if (a == null || b == null) {
    return a == b;
  }
  return _mapEquals(a, b);
}

int _mapHash<K, V>(Map<K, V> map) => Object.hashAllUnordered(<int>[
  for (final MapEntry(:K key, :V value) in map.entries) Object.hash(key, value),
]);

bool _listEquals<T>(List<T> a, List<T> b) => _listEquality.equals(a, b);

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) =>
    const MapEquality<Object?, Object?>().equals(a, b);
