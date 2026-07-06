// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Core build service and target definitions for tool extensions.
///
/// This library defines the interface for registering custom build targets
/// and executing builds from the host tool.
library flutter_tools_core.build;

import '../../generic_extension_protocol.dart';
import 'artifacts.dart';

/// The primary coordinator between the tool and extension compilation logic.
abstract base class BuildService extends ToolExtensionService {
  static const String serviceNamespace = 'build';
  static const String getTargetsMethod = 'build.getTargets';
  static const String buildMethod = 'build.build';

  @override
  String get namespace => serviceNamespace;

  /// The set of build targets provided by this extension.
  List<Target> get targets;

  /// Configurations for Dart Build Hooks (build.dart/link.dart).
  Map<String, Object?> get nativeAssetsConfig;

  /// Declares engine artifacts required before building.
  List<ArtifactDependency> get artifactDependencies;

  /// Initializes the service by registering RPC methods with the extension provider.
  ///
  /// Registers `getTargets` to list targets and `build` to trigger a build.
  @override
  Future<Map<String, Function>> initialize() async {
    return <String, Function>{'getTargets': _getTargetsRpc, 'build': _buildRpc};
  }

  /// Shuts down the service and cleans up any resources.
  @override
  Future<void> shutdown() async {}

  Future<List<Map<String, Object?>>> _getTargetsRpc(Map<String, Object?> params) async {
    return targets
        .map(
          (Target target) => <String, Object?>{
            'name': target.name,
            'dependencies': target.dependencies,
            'inputs': target.inputs,
            'outputs': target.outputs,
            if (target.cliSubcommand != null) 'cliSubcommand': target.cliSubcommand,
            if (target.cliDescription != null) 'cliDescription': target.cliDescription,
            if (target.targetPlatformDirectory != null)
              'targetPlatformDirectory': target.targetPlatformDirectory,
            if (target.targetDeviceDirectory != null)
              'targetDeviceDirectory': target.targetDeviceDirectory,
            if (target.pluginPlatformKey != null) 'pluginPlatformKey': target.pluginPlatformKey,
          },
        )
        .toList();
  }

  Future<Map<String, Object?>> _buildRpc(Map<String, Object?> params) async {
    if (params case {
      'targetName': final String targetName,
      'environment': final Map<dynamic, dynamic> rawEnv,
    }) {
      final BuildEnvironment env;
      try {
        env = BuildEnvironment.fromJson(rawEnv.cast<String, Object?>());
      } on Object catch (e, stackTrace) {
        return <String, Object?>{
          'success': false,
          'errorMessage': 'Failed to deserialize environment: $e',
          'stackTrace': stackTrace.toString(),
        };
      }

      final List<Target> matching = targets.where((Target t) => t.name == targetName).toList();
      if (matching.isEmpty) {
        return <String, Object?>{
          'success': false,
          'errorMessage': 'Target "$targetName" not found.',
        };
      }
      final Target foundTarget = matching.first;

      try {
        final Map<String, Object?> buildResultMap = await foundTarget.build(env);
        return <String, Object?>{'success': true, ...buildResultMap};
      } on Object catch (e, stackTrace) {
        return <String, Object?>{
          'success': false,
          'errorMessage': e.toString(),
          'stackTrace': stackTrace.toString(),
        };
      }
    }
    return <String, Object?>{
      'success': false,
      'errorMessage':
          'Missing or invalid parameters: targetName must be a String and environment must be a Map.',
    };
  }
}

/// A stable, version-checked catalog of core build targets provided by the host tool.
///
/// These targets represent standard build steps in the Flutter tool's build system
/// (like compiling the kernel snapshot or copying assets) that extensions can depend on.
abstract final class CoreBuildTargets {
  static const String kernelSnapshot = 'kernel_snapshot_program';
  static const String aotElf = 'aot_elf_profile';
  static const String webAssets = 'web_release_assets';
  static const String flutterAssets = 'copy_flutter_assets';
}

/// Defines a specific build, bundle, or signing step.
///
/// Extensions implement this class to define custom build targets (e.g., compiling
/// native binaries for a custom platform).
abstract base class Target {
  /// The name of this target.
  String get name;

  /// Optional subcommand name if this target should be registered as a CLI subcommand under `flutter build`.
  String? get cliSubcommand => null;

  /// Optional description for the CLI subcommand when registered under `flutter build`.
  String? get cliDescription => null;

  /// Optional target platform directory name (e.g., 'linux-x64') for structuring output directories to match `flutter run`.
  String? get targetPlatformDirectory => null;

  /// Optional device directory name (e.g., 'linux-proto-1') for structuring output directories to match `flutter run`.
  String? get targetDeviceDirectory => null;

  /// Optional plugin platform key (e.g., 'linux') for negotiating host plugin generation and injection.
  String? get pluginPlatformKey => null;

  /// The list of names of dependencies.
  List<String> get dependencies;

  /// Inputs required for this target.
  List<String> get inputs;

  /// Outputs generated by this target.
  List<String> get outputs;

  /// References to depfiles.
  List<Depfile> get depfiles => const <Depfile>[];

  /// Executes target operations.
  ///
  /// Returns a map of custom build results (e.g. `executablePath`).
  Future<Map<String, Object?>> build(BuildEnvironment env);

  /// Custom defines passed back to the tool.
  Future<Map<String, String>> get extraDefines async => const <String, String>{};
}

/// A concrete implementation of [Target] that can be parsed from a JSON map
/// returned over the tool extension RPC.
///
/// This represents an extension's target on the host side. Its [build] method
/// throws an [UnimplementedError] because the actual build execution must be
/// delegated to the extension isolate via RPC.
final class ExtensionBuildTarget extends Target {
  ExtensionBuildTarget.fromJson(Map<String, Object?> json)
    : name = json['name']! as String,
      dependencies = json['dependencies'] is List
          ? (json['dependencies']! as List<Object?>).cast<String>()
          : const <String>[],
      inputs = json['inputs'] is List
          ? (json['inputs']! as List<Object?>).cast<String>()
          : const <String>[],
      outputs = json['outputs'] is List
          ? (json['outputs']! as List<Object?>).cast<String>()
          : const <String>[],
      cliSubcommand = json['cliSubcommand'] as String?,
      cliDescription = json['cliDescription'] as String?,
      pluginPlatformKey = json['pluginPlatformKey'] as String?,
      targetPlatformDirectory = json['targetPlatformDirectory'] as String?,
      targetDeviceDirectory = json['targetDeviceDirectory'] as String?;

  @override
  final String name;

  @override
  final List<String> dependencies;

  @override
  final List<String> inputs;

  @override
  final List<String> outputs;

  @override
  final String? cliSubcommand;

  @override
  final String? cliDescription;

  @override
  final String? pluginPlatformKey;

  @override
  final String? targetPlatformDirectory;

  @override
  final String? targetDeviceDirectory;

  @override
  Future<Map<String, Object?>> build(BuildEnvironment env) async {
    throw UnimplementedError(
      'ExtensionBuildTarget.build should not be called directly on host representation.',
    );
  }

  static List<ExtensionBuildTarget> listFromJson(Object? rpcResult) => <ExtensionBuildTarget>[
    if (rpcResult case final List<Object?> l)
      for (final item in l)
        if (item case final Map<dynamic, dynamic> m)
          ExtensionBuildTarget.fromJson(m.cast<String, Object?>()),
  ];
}

/// Environment state provided by the host tool to the extension build target.
///
/// This structure is serialized over the tool extension RPC to convey directories,
/// build flags, engine parameters, and resolved plugins to the extension-side compiler.
class BuildEnvironment {
  BuildEnvironment({
    required this.cacheDir,
    required this.defines,
    required this.flutterAssetsDir,
    required this.outputDirectory,
    required this.projectRoot,
    required this.plugins,
  });

  /// Creates a [BuildEnvironment] from a JSON map received over RPC.
  factory BuildEnvironment.fromJson(Map<String, Object?> json) {
    return BuildEnvironment(
      cacheDir: Uri.parse(json['cacheDir']! as String),
      defines: (json['defines']! as Map<dynamic, dynamic>).cast<String, String>(),
      flutterAssetsDir: Uri.parse(json['flutterAssetsDir']! as String),
      outputDirectory: Uri.parse(json['outputDirectory']! as String),
      projectRoot: Uri.parse(json['projectRoot']! as String),
      plugins:
          (json['plugins'] as List<Object?>?)
              ?.map(
                (Object? item) => ExtensionPlugin.fromJson(
                  (item! as Map<dynamic, dynamic>).cast<String, Object?>(),
                ),
              )
              .toList() ??
          const <ExtensionPlugin>[],
    );
  }

  /// Defines and build flags passed to compilation targets.
  final Map<String, String> defines;

  /// Directory holding cached artifacts and files.
  final Uri cacheDir;

  /// Root directory of the Flutter project being built.
  final Uri projectRoot;

  /// Output directory where build artifacts should be written.
  final Uri outputDirectory;

  /// Directory holding the compiled flutter assets (e.g. AssetBundle).
  final Uri flutterAssetsDir;

  /// The list of resolved plugins applicable to the target platform.
  ///
  /// This lists plugins resolved on the host tool, including their paths and raw
  /// configurations, allowing the extension-side build to dynamically bundle
  /// and link them natively.
  final List<ExtensionPlugin> plugins;

  /// Converts the environment config to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    'cacheDir': cacheDir.toString(),
    'defines': defines,
    'flutterAssetsDir': flutterAssetsDir.toString(),
    'outputDirectory': outputDirectory.toString(),
    'plugins': plugins.map((ExtensionPlugin p) => p.toMap()).toList(),
    'projectRoot': projectRoot.toString(),
  };
}

/// A Data Transfer Object representing a resolved Flutter plugin.
///
/// This class is shared between the host tool and the extension protocol.
/// It contains the plugin's metadata and the raw configuration block extracted
/// from `pubspec.yaml` under `platforms: <platform_key>`, allowing custom
/// platforms to interpret their specific plugin parameters on the extension side.
class ExtensionPlugin {
  ExtensionPlugin({required this.configuration, required this.name, required this.path});

  /// Creates an [ExtensionPlugin] from a JSON map.
  factory ExtensionPlugin.fromJson(Map<String, Object?> json) {
    return ExtensionPlugin(
      configuration:
          (json['configuration'] as Map<dynamic, dynamic>?)?.cast<String, Object?>() ??
          const <String, Object?>{},
      name: json['name']! as String,
      path: json['path']! as String,
    );
  }

  /// The raw plugin configuration map defined under the platform key in `pubspec.yaml`.
  final Map<String, Object?> configuration;

  /// The name of the plugin package.
  final String name;

  /// The absolute path to the plugin package on the host filesystem.
  final String path;

  /// Encodes this plugin DTO into a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    'configuration': configuration,
    'name': name,
    'path': path,
  };
}

/// A class for representing depfile formats.
class Depfile {
  /// Create a [Depfile] from a list of [inputs] and [outputs].
  const Depfile(this.inputs, this.outputs);

  /// Inputs in the depfile.
  final List<String> inputs;

  /// Outputs in the depfile.
  final List<String> outputs;
}

/// A DTO representing the result of a compilation build operation over the tool extension RPC.
class BuildResult {
  /// Create a new instance of [BuildResult].
  BuildResult({required this.success, this.errorMessage, this.executablePath, this.stackTrace});

  /// Parses a [BuildResult] from a JSON map returned over the RPC.
  factory BuildResult.fromJson(Map<String, Object?> json) {
    return BuildResult(
      success: json['success'] == true,
      errorMessage: json['errorMessage'] as String?,
      executablePath: json['executablePath'] as String?,
      stackTrace: json['stackTrace'] as String?,
    );
  }

  /// Whether the build succeeded.
  final bool success;

  /// An error message if the build failed.
  final String? errorMessage;

  /// The path or URI of the built application executable or bundle, if any.
  final String? executablePath;

  /// The stack trace of a build failure, if any.
  final String? stackTrace;

  /// Convert to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    'success': success,
    if (errorMessage != null) 'errorMessage': errorMessage,
    if (executablePath != null) 'executablePath': executablePath,
    if (stackTrace != null) 'stackTrace': stackTrace,
  };
}
