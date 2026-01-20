// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/template.dart';
import '../base/version.dart';
import '../build_system/build_system.dart';
import '../cache.dart';
import '../convert.dart';
import '../darwin/darwin.dart';
import '../features.dart';
import '../flutter_plugins.dart';
import '../macos/swift_package_manager.dart';
import '../macos/swift_packages.dart';
import '../macos/xcode.dart';
import '../plugins.dart';
import '../project.dart';
import '../runner/flutter_command.dart';
import '../version.dart';
import 'build.dart';

const String _kPlugins = 'Plugins';
const String _kFileAnIssue =
    'Please file an issue at https://github.com/flutter/flutter/issues/new/choose.';

class BuildSwiftPackage extends BuildSubCommand {
  BuildSwiftPackage({
    required super.logger,
    required Analytics analytics,
    required Artifacts artifacts,
    required BuildSystem buildSystem,
    required Cache cache,
    required FeatureFlags featureFlags,
    required FileSystem fileSystem,
    required FlutterVersion flutterVersion,
    required Platform platform,
    required ProcessManager processManager,
    required TemplateRenderer templateRenderer,
    required Xcode? xcode,
    required super.verboseHelp,
  }) : _analytics = analytics,
       _artifacts = artifacts,
       _cache = cache,
       _platform = platform,
       _processManager = processManager,
       _buildSystem = buildSystem,
       _featureFlags = featureFlags,
       _fileSystem = fileSystem,
       _flutterVersion = flutterVersion,
       _templateRenderer = templateRenderer,
       _xcode = xcode {
    argParser
      ..addOption(
        'output',
        abbr: 'o',
        valueHelp: 'path/to/directory/',
        help: 'Location to write the frameworks.',
      )
      ..addOption('platform', allowed: ['ios', 'macos'], defaultsTo: 'ios');
  }

  @override
  final name = 'swift-packages';

  @override
  final description =
      'Produces Swift packages and scripts for a Flutter project '
      'and its plugins for integration into existing, plain iOS and macOS Xcode projects.\n'
      'This can only be run on macOS hosts.';

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{
    DevelopmentArtifact.iOS,
    DevelopmentArtifact.macOS,
  };

  final Platform _platform;
  final BuildSystem _buildSystem;
  final FileSystem _fileSystem;
  final Artifacts _artifacts;
  final ProcessManager _processManager;
  final Xcode? _xcode;
  final Cache _cache;
  final Analytics _analytics;
  final TemplateRenderer _templateRenderer;
  final FlutterVersion _flutterVersion;
  final FeatureFlags _featureFlags;

  @override
  bool get supported => _platform.isMacOS;

  FlutterDarwinPlatform get _targetPlatform {
    final String? platformString = stringArg('platform');
    if (platformString != null) {
      final FlutterDarwinPlatform? darwinPlatform = FlutterDarwinPlatform.fromName(platformString);
      if (darwinPlatform != null) {
        return darwinPlatform;
      }
    }
    throwToolExit(
      'The $platformString platform is being targeted but the Flutter project does not support '
      '$platformString. Use the "--platform" flag to change the targeted platforms.',
    );
  }

  @override
  Future<void> validateCommand() async {
    await super.validateCommand();
    _validateTargetPlatform();
    _validateFeatureFlags();
    _validateXcodeVersion();
  }

  void _validateTargetPlatform() {
    if (_targetPlatform == FlutterDarwinPlatform.ios && !project.ios.existsSync()) {
      throwToolExit(
        'The iOS platform is being targeted but the Flutter project does not support iOS. Use '
        'the "--platform" flag to change the targeted platforms.',
      );
    }
    if (_targetPlatform == FlutterDarwinPlatform.macos && !project.macos.existsSync()) {
      throwToolExit(
        'The macOS platform is being targeted but the Flutter project does not support macOS. Use '
        'the "--platform" flag to change the targeted platforms.',
      );
    }
  }

  void _validateFeatureFlags() {
    if (!_featureFlags.isSwiftPackageManagerEnabled) {
      throwToolExit(
        'Swift Package Manager is disabled. Ensure it is enabled in your global config ("flutter '
        'config --enable-swift-package-manager") and is not disabled in your Flutter '
        "project's pubspec.yaml.",
      );
    }
  }

  void _validateXcodeVersion() {
    final Version? xcodeVersion = _xcode?.currentVersion;
    if (xcodeVersion == null || xcodeVersion.major < 15) {
      throwToolExit(
        'Flutter requires Xcode 15 or greater when using Swift Package Manager. Please ensure '
        'Xcode is installed and meets the version requirements.',
      );
    }
  }

  late BuildSwiftPackageUtils utils = BuildSwiftPackageUtils(
    analytics: _analytics,
    artifacts: _artifacts,
    buildSystem: _buildSystem,
    cache: _cache,
    fileSystem: _fileSystem,
    flutterVersion: _flutterVersion,
    logger: logger,
    platform: _platform,
    processManager: _processManager,
    project: project,
    targetPlatform: _targetPlatform,
    templateRenderer: _templateRenderer,
    xcode: _xcode!,
  );
  late final pluginDependencies = FlutterPluginDependencies(utils: utils);

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String outputArgument =
        stringArg('output') ??
        _fileSystem.path.join(
          _fileSystem.currentDirectory.path,
          'build',
          _targetPlatform.name,
          'SwiftPackages',
        );

    if (outputArgument.isEmpty) {
      throwToolExit('--output is required.');
    }

    final Directory outputDirectory = _fileSystem.directory(
      _fileSystem.path.absolute(_fileSystem.path.normalize(outputArgument)),
    );
    final Directory cachedPluginsDirectory = outputDirectory.childDirectory(_kPlugins);

    await project.regeneratePlatformSpecificTooling(releaseMode: false);

    final List<Plugin> plugins = await findPlugins(project);
    plugins.sort((Plugin left, Plugin right) => left.name.compareTo(right.name));

    await pluginDependencies.copyPlugins(
      plugins: plugins,
      cachedPluginsDirectory: cachedPluginsDirectory,
    );

    return FlutterCommandResult.success();
  }
}

@visibleForTesting
class FlutterPluginDependencies {
  FlutterPluginDependencies({required BuildSwiftPackageUtils utils}) : _utils = utils;

  final BuildSwiftPackageUtils _utils;

  Future<void> copyPlugins({
    required List<Plugin> plugins,
    required Directory cachedPluginsDirectory,
  }) async {
    try {
      ErrorHandlingFileSystem.deleteIfExists(cachedPluginsDirectory, recursive: true);
    } on FileSystemException catch (e, stackTrace) {
      // Delete may fail due to Xcode writing hidden files to the directory at the same time.
      _utils.logger.printTrace('Failed to delete ${cachedPluginsDirectory.path}: $e\n$stackTrace');
    }
    final FlutterDarwinPlatform darwinPlatform = _utils.targetPlatform;
    for (final plugin in plugins) {
      // If plugin does not support the platform, skip it.
      if (!plugin.supportSwiftPackageManagerForPlatform(_utils.fileSystem, darwinPlatform.name)) {
        continue;
      }

      // Copy plugins from pubcache to cachedPluginsDirectory.
      // The entire plugin is copied (excluding the example app) instead of just the swift package
      // to maintain any relative links within the plugin.
      // Example: https://github.com/firebase/flutterfire/blob/198aef8db6c96a08f57d750f1fa756da5e4a68a5/packages/firebase_core/firebase_core/ios/firebase_core/Package.swift#L21-L26
      final Directory pluginDestination = cachedPluginsDirectory.childDirectory(plugin.name)
        ..createSync(recursive: true);
      copyDirectory(
        _utils.fileSystem.directory(plugin.path),
        pluginDestination,
        shouldCopyDirectory: (Directory dir) => dir.basename != 'example',
      );

      final String? swiftPackagePath = plugin.pluginSwiftPackagePath(
        _utils.fileSystem,
        darwinPlatform.name,
        overridePath: pluginDestination.path,
      );
      if (swiftPackagePath == null) {
        throwToolExit("Failed to find copied ${plugin.name}'s Package.swift. $_kFileAnIssue");
      }

      await _addFlutterFrameworkDependencyIfNeeded(plugin.name, swiftPackagePath);
    }
  }

  /// Convert the plugin's Package.swift to json and parse the dependencies. If the plugin does not
  /// have a dependency on the FlutterFramework, add it into the copied Package.swift.
  Future<void> _addFlutterFrameworkDependencyIfNeeded(
    String pluginName,
    String copiedPackagePath,
  ) async {
    final File swiftPackageManifest = _utils.fileSystem.file(
      _utils.fileSystem.path.join(copiedPackagePath, 'Package.swift'),
    );
    if (!swiftPackageManifest.existsSync()) {
      throwToolExit(
        "Failed to find copied $pluginName's Package.swift at $copiedPackagePath. $_kFileAnIssue",
      );
    }
    final String originalManifestContents = swiftPackageManifest.readAsStringSync();

    final List<SwiftPackagePackageDependency> dependencies;
    final List<SwiftPackageTarget> targets;

    try {
      final ProcessResult parsedManifest = await _utils.processManager.run([
        'swift',
        'package',
        'dump-package',
      ], workingDirectory: copiedPackagePath);

      final jsonData = json.decode(parsedManifest.stdout.toString()) as Map<String, Object?>;
      dependencies = _parseJsonList<SwiftPackagePackageDependency>(
        jsonData['dependencies'],
        SwiftPackagePackageDependency.fromJson,
      );
      targets = _parseJsonList<SwiftPackageTarget>(
        jsonData['targets'],
        SwiftPackageTarget.fromJson,
      );
      if (targets.isEmpty) {
        throw Exception('Failed to find targets for plugin $pluginName.');
      }
    } on Exception catch (e, stackTrace) {
      _utils.logger.printTrace('Failed to parse $copiedPackagePath: $e\n$stackTrace');
      throwToolExit('Failed to validate $pluginName. $_kFileAnIssue.');
    }
    try {
      // Parse swift package for FlutterFramework dependency
      final bool hasDependencyOnFlutter = dependencies
          .where(
            (dependency) => dependency.name == kFlutterGeneratedFrameworkSwiftPackageTargetName,
          )
          .isNotEmpty;
      if (hasDependencyOnFlutter) {
        return;
      }

      // If FlutterFramework is not found as a package dependency, add it.
      final ProcessResult addPackageDependencyResult = await _utils.processManager.run([
        'swift',
        'package',
        'add-dependency',
        '../$kFlutterGeneratedFrameworkSwiftPackageTargetName',
        '--type',
        'path',
      ], workingDirectory: copiedPackagePath);
      if (addPackageDependencyResult.exitCode != 0) {
        throw Exception(
          'Failed to add $kFlutterGeneratedFrameworkSwiftPackageTargetName to plugin $pluginName:\n'
          '${addPackageDependencyResult.stderr}',
        );
      }

      // Add FlutterFramework as a dependency for each regular target.
      for (final target in targets) {
        if (target.targetType != SwiftPackageTargetType.target) {
          continue;
        }
        final ProcessResult addTargetDependencyResult = await _utils.processManager.run([
          'swift',
          'package',
          'add-target-dependency',
          kFlutterGeneratedFrameworkSwiftPackageTargetName,
          target.name,
          '--package',
          kFlutterGeneratedFrameworkSwiftPackageTargetName,
        ], workingDirectory: copiedPackagePath);
        if (addTargetDependencyResult.exitCode != 0) {
          throw Exception(
            'Failed to add $kFlutterGeneratedFrameworkSwiftPackageTargetName as a target dependency '
            'to ${target.name} for plugin $pluginName:\n'
            '${addTargetDependencyResult.stderr}',
          );
        }
      }
    } on Exception catch (e, stackTrace) {
      _utils.logger.printTrace('Failed to update $copiedPackagePath: $e\n$stackTrace');
      swiftPackageManifest.writeAsStringSync(originalManifestContents);
      // TODO(vashworth): Add link to documentation.
      throwToolExit(
        'Plugin $pluginName does not have a dependency on the $kFlutterGeneratedFrameworkSwiftPackageTargetName. '
        'Please file an issue with the plugin to add this dependency.',
      );
    }
  }

  static List<T> _parseJsonList<T>(Object? data, T? Function(Map<String, Object?>) parse) {
    final parsedItems = <T>[];
    if (data is List<Object?>) {
      for (final Object? item in data) {
        if (item is Map<String, Object?>) {
          final T? parsedItem = parse(item);
          if (parsedItem != null) {
            parsedItems.add(parsedItem);
          }
        }
      }
    }
    return parsedItems;
  }
}

@visibleForTesting
class BuildSwiftPackageUtils {
  BuildSwiftPackageUtils({
    required this.analytics,
    required this.artifacts,
    required this.buildSystem,
    required this.cache,
    required this.fileSystem,
    required this.flutterVersion,
    required this.logger,
    required this.platform,
    required this.processManager,
    required this.project,
    required this.targetPlatform,
    required this.templateRenderer,
    required this.xcode,
  });

  final Analytics analytics;
  final Artifacts artifacts;
  final BuildSystem buildSystem;
  final Cache cache;
  final FileSystem fileSystem;
  final FlutterVersion flutterVersion;
  final Logger logger;
  final Platform platform;
  final ProcessManager processManager;
  final FlutterProject project;
  final FlutterDarwinPlatform targetPlatform;
  final TemplateRenderer templateRenderer;
  final Xcode xcode;
}
