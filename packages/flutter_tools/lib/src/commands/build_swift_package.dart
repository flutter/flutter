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
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/template.dart';
import '../base/version.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../cache.dart';
import '../darwin/darwin.dart';
import '../features.dart';
import '../flutter_plugins.dart';
import '../macos/swift_packages.dart';
import '../macos/xcode.dart';
import '../plugins.dart';
import '../project.dart';
import '../runner/flutter_command.dart';
import '../version.dart';
import 'build.dart';

const String kPluginSwiftPackageName = 'FlutterPluginRegistrant';
const String _kSources = 'Sources';
const List<String> _kSupportedPlatforms = ['ios', 'macos'];

/// Create a swift package that can be used to embed a Flutter app inside a native iOS or macOS app.
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
        help: 'Location to write the swift package.',
      )
      ..addOption('platform', allowed: _kSupportedPlatforms, defaultsTo: 'ios')
      ..addMultiOption(
        'build-mode',
        allowed: ['debug', 'profile', 'release'],
        defaultsTo: ['debug', 'profile', 'release'],
      );
  }

  @override
  final name = 'swift-package';

  @override
  final description =
      'Produces Swift packages and scripts for a Flutter project and its plugins for integration '
      'into existing, native non-Flutter iOS and macOS Xcode projects.\n'
      'This can only be run on macOS hosts.';

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
      'The $platformString platform is being targeted, but is not supported for this command. '
      'Supported platforms include: ${_kSupportedPlatforms.join(', ')}.',
    );
  }

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async {
    return switch (_targetPlatform) {
      .ios => <DevelopmentArtifact>{.iOS},
      .macos => <DevelopmentArtifact>{.macOS},
    };
  }

  Future<List<BuildInfo>> _getBuildInfos() async {
    final List<String> buildModes = stringsArg('build-mode');
    return <BuildInfo>[
      if (buildModes.contains('debug')) await getBuildInfo(forcedBuildMode: .debug),
      if (buildModes.contains('profile')) await getBuildInfo(forcedBuildMode: .profile),
      if (buildModes.contains('release')) await getBuildInfo(forcedBuildMode: .release),
    ];
  }

  @override
  Future<void> validateCommand() async {
    await super.validateCommand();
    _validateTargetPlatform();
    _validateFeatureFlags();
    _validateXcodeVersion();
  }

  /// Validates the Flutter project supports the [_targetPlatform].
  ///
  /// Throws a [ToolExit] if iOS/macOS subproject does not exist.
  void _validateTargetPlatform() {
    switch (_targetPlatform) {
      case .ios:
        if (!project.ios.existsSync()) {
          throwToolExit(
            'The iOS platform is being targeted but the Flutter project does not support iOS. Use '
            'the "--platform" flag to change the targeted platforms.',
          );
        }
      case .macos:
        if (!project.macos.existsSync()) {
          throwToolExit(
            'The macOS platform is being targeted but the Flutter project does not support macOS. Use '
            'the "--platform" flag to change the targeted platforms.',
          );
        }
    }
  }

  /// Validates the SwiftPM feature flag is enabled.
  ///
  /// Throws a [ToolExit] if the flag is disabled.
  void _validateFeatureFlags() {
    if (!_featureFlags.isSwiftPackageManagerEnabled) {
      throwToolExit(
        'Swift Package Manager is disabled. Ensure it is enabled in your global config ("flutter '
        'config --enable-swift-package-manager") and is not disabled in your Flutter '
        "project's pubspec.yaml.",
      );
    }
  }

  /// Validates the Xcode version is equal to or greater than 15.
  ///
  /// Throws a [ToolExit] if the Xcoder version is less than 15.
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
    templateRenderer: _templateRenderer,
    xcode: _xcode!,
  );
  late final pluginRegistrant = FlutterPluginRegistrantSwiftPackage(
    targetPlatform: _targetPlatform,
    utils: utils,
  );

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
      throwToolExit('Please provide a value for --output.');
    }

    final Directory outputDirectory = _fileSystem.directory(
      _fileSystem.path.absolute(_fileSystem.path.normalize(outputArgument)),
    );
    final Directory pluginRegistrantSwiftPackage = outputDirectory.childDirectory(
      kPluginSwiftPackageName,
    );
    pluginRegistrantSwiftPackage.createSync(recursive: true);

    await project.regeneratePlatformSpecificTooling(releaseMode: false);

    final List<BuildInfo> buildInfos = await _getBuildInfos();
    if (buildInfos.isEmpty) {
      throwToolExit('--build-mode is required.');
    }

    final List<Plugin> plugins = await findPlugins(project);
    plugins.sort((Plugin left, Plugin right) => left.name.compareTo(right.name));

    for (final buildInfo in buildInfos) {
      final String xcodeBuildConfiguration = buildInfo.mode.uppercaseName;
      await _generateSwiftPackages(
        pluginRegistrantSwiftPackage: pluginRegistrantSwiftPackage,
        plugins: plugins,
        xcodeBuildConfiguration: xcodeBuildConfiguration,
      );
    }

    createSourcesSymlink(pluginRegistrantSwiftPackage, buildInfos.first.mode.uppercaseName);

    return FlutterCommandResult.success();
  }

  Future<void> _generateSwiftPackages({
    required Directory pluginRegistrantSwiftPackage,
    required List<Plugin> plugins,
    required String xcodeBuildConfiguration,
  }) async {
    final Status status = logger.startProgress('   ├─Generating swift packages...');
    try {
      await pluginRegistrant.generateSwiftPackage(
        pluginRegistrantSwiftPackage: pluginRegistrantSwiftPackage,
        plugins: plugins,
        xcodeBuildConfiguration: xcodeBuildConfiguration,
      );
    } finally {
      status.stop();
    }
  }

  /// Creates relative symlinks for Sources and Package.swift using the [defaultBuildMode] so that
  /// the package may easily be switched to a different build mode by updating the symlink.
  ///
  /// Creates a symlink from the Sources directory to the './[defaultBuildMode]' directory.
  ///
  /// Creates a symlink from Package.swift to "./[defaultBuildMode]/Package.swift"
  @visibleForTesting
  void createSourcesSymlink(Directory pluginRegistrantSwiftPackage, String defaultBuildMode) {
    final Link sourcesLink = pluginRegistrantSwiftPackage.childLink(_kSources);
    final Link manifestLink = pluginRegistrantSwiftPackage.childLink('Package.swift');
    _createOrUpdateSymlink(sourcesLink, './$defaultBuildMode');
    _createOrUpdateSymlink(manifestLink, './$defaultBuildMode/Package.swift');
  }

  void _createOrUpdateSymlink(Link link, String target) {
    if (link.existsSync()) {
      link.updateSync(target);
    } else {
      link.createSync(target);
    }
  }
}

/// Class that encapsulates logic needed to create the FlutterPluginRegistrant swift package.
@visibleForTesting
class FlutterPluginRegistrantSwiftPackage {
  FlutterPluginRegistrantSwiftPackage({
    required FlutterDarwinPlatform targetPlatform,
    required BuildSwiftPackageUtils utils,
  }) : _targetPlatform = targetPlatform,
       _utils = utils;

  final FlutterDarwinPlatform _targetPlatform;
  final BuildSwiftPackageUtils _utils;

  Future<void> generateSwiftPackage({
    required Directory pluginRegistrantSwiftPackage,
    required List<Plugin> plugins,
    required String xcodeBuildConfiguration,
  }) async {
    final List<SwiftPackageTargetDependency> targetDependencies = [];
    final List<SwiftPackagePackageDependency> packageDependencies = [];

    const String swiftPackageName = kPluginSwiftPackageName;
    final File manifestFile = pluginRegistrantSwiftPackage
        .childDirectory(xcodeBuildConfiguration)
        .childFile('Package.swift');

    final product = SwiftPackageProduct(
      name: swiftPackageName,
      targets: <String>[swiftPackageName],
      libraryType: .static,
    );

    final targets = <SwiftPackageTarget>[
      SwiftPackageTarget.defaultTarget(name: swiftPackageName, dependencies: targetDependencies),
    ];

    final pluginsPackage = SwiftPackage(
      manifest: manifestFile,
      name: swiftPackageName,
      platforms: <SwiftPackageSupportedPlatform>[],
      products: <SwiftPackageProduct>[product],
      dependencies: packageDependencies,
      targets: targets,
      templateRenderer: _utils.templateRenderer,
      swiftCodeBeforePackageDefinition: '// $xcodeBuildConfiguration',
    );

    pluginsPackage.createSwiftPackage(generateEmptySources: false);

    await _generateSourceFiles(
      pluginRegistrantSwiftPackage: pluginRegistrantSwiftPackage,
      plugins: plugins,
      xcodeBuildConfiguration: xcodeBuildConfiguration,
    );
  }

  /// Generates GeneratedPluginRegistrant source files.
  Future<void> _generateSourceFiles({
    required Directory pluginRegistrantSwiftPackage,
    required List<Plugin> plugins,
    required String xcodeBuildConfiguration,
  }) async {
    final Directory sourcesDirectory = pluginRegistrantSwiftPackage.childDirectory(
      xcodeBuildConfiguration,
    );
    ErrorHandlingFileSystem.deleteIfExists(
      sourcesDirectory.childDirectory(kPluginSwiftPackageName),
      recursive: true,
    );
    final File swiftFile = sourcesDirectory
        .childDirectory(kPluginSwiftPackageName)
        .childFile('GeneratedPluginRegistrant.swift');
    switch (_targetPlatform) {
      case .ios:
        await writeIOSPluginRegistrant(
          _utils.project,
          plugins,
          swiftPluginRegistrant: swiftFile,
          templateRenderer: _utils.templateRenderer,
        );
      case .macos:
        await writeMacOSPluginRegistrant(
          _utils.project,
          plugins,
          pluginRegistrantImplementation: swiftFile,
          templateRenderer: _utils.templateRenderer,
        );
    }
  }
}

/// Helper class that bundles global context variables for easy passing with less boilerplate.
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
  final TemplateRenderer templateRenderer;
  final Xcode xcode;
}
