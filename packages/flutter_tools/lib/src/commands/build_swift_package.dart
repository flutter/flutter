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
import '../base/fingerprint.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/template.dart';
import '../base/version.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/targets/ios.dart';
import '../build_system/targets/macos.dart';
import '../cache.dart';
import '../convert.dart';
import '../darwin/darwin.dart';
import '../features.dart';
import '../flutter_plugins.dart';
import '../ios/xcodeproj.dart';
import '../macos/cocoapod_utils.dart';
import '../macos/cocoapods.dart';
import '../macos/swift_package_manager.dart';
import '../macos/swift_packages.dart';
import '../macos/xcode.dart';
import '../plugins.dart';
import '../project.dart';
import '../runner/flutter_command.dart'
    show DevelopmentArtifact, FlutterCommandResult, FlutterOptions;
import '../runner/flutter_command_runner.dart';
import '../template.dart';
import '../version.dart';
import 'build.dart';
import 'darwin_add_to_app.dart';

const String _kFileAnIssue =
    'Please file an issue at https://github.com/flutter/flutter/issues/new/choose';
const String _kFrameworks = 'Frameworks';
const String _kPackages = 'Packages';
const String _kFlutterPlugins = '.plugins';
const String _kManifests = 'Manifests';
const String _kCocoaPods = 'CocoaPods';
const String _kNativeAssets = 'NativeAssets';
const String kPluginSwiftPackageName = 'FlutterPluginRegistrant';
const String _kFlutterIntegrationPackageName = 'FlutterNativeIntegration';
const String _kSources = 'Sources';
const String _kScripts = 'Scripts';
const String _kTools = 'Tools';
const String _kTests = 'Tests';
const String _kSwiftPlugins = 'Plugins';
const List<String> _kSupportedPlatforms = ['ios', 'macos'];
const String _kCodesignIdentityFile = '.codesign_identity';

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
    required DarwinAddToAppCodesigning codesign,
    required bool verboseHelp,
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
       _xcode = xcode,
       _codesign = codesign,
       super(verboseHelp: verboseHelp) {
    usesFlavorOption();
    addTreeShakeIconsFlag();
    usesTargetOption();
    usesPubOption();
    usesDartDefineOption();
    addSplitDebugInfoOption();
    addDartObfuscationOption();
    usesExtraDartFlagOptions(verboseHelp: verboseHelp);
    addEnableExperimentation(hide: !verboseHelp);
    usesDarwinCodeSignXCFrameworksOption();
    argParser
      ..addOption(
        'output',
        abbr: 'o',
        valueHelp: 'path/to/directory/',
        help: 'Directory where the Swift package will be written.',
      )
      ..addOption(
        'platform',
        allowed: _kSupportedPlatforms,
        defaultsTo: 'ios',
        help: 'Target platform for the build.',
      )
      ..addMultiOption(
        'build-mode',
        allowed: availableBuildModes.map((e) => e.cliName).toList(),
        defaultsTo: availableBuildModes.map((e) => e.cliName).toList(),
        help: 'Build modes to include.',
      )
      ..addFlag('static', help: 'Build CocoaPods plugins as static frameworks.');
  }

  @override
  final name = 'swift-package';

  @override
  final description =
      'Produces Swift packages and scripts for a Flutter project and its plugins for integration '
      'into existing, native non-Flutter iOS and macOS Xcode projects.\n'
      'This can only be run on macOS hosts.';

  static const availableBuildModes = <BuildMode>[.debug, .profile, .release];

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
  final DarwinAddToAppCodesigning _codesign;

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

  late final XcodeBasedProject _xcodeProject = _targetPlatform.xcodeProject(project);

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
      for (final mode in availableBuildModes)
        if (buildModes.contains(mode.cliName)) await getBuildInfo(forcedBuildMode: mode),
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
    flutterRoot: Cache.flutterRoot!,
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
  late final pluginSwiftDependencies = FlutterPluginSwiftDependencies(
    targetPlatform: _targetPlatform,
    utils: utils,
  );
  late final flutterFrameworkDependency = FlutterFrameworkDependency(
    targetPlatform: _targetPlatform,
    utils: utils,
  );
  late final appAndNativeAssetsDependencies = AppFrameworkAndNativeAssetsDependencies(
    targetPlatform: _targetPlatform,
    utils: utils,
  );
  late final cocoapodDependencies = CocoaPodPluginDependencies(
    targetPlatform: _targetPlatform,
    utils: utils,
  );
  late final flutterNativeIntegrationSwiftPackage = FlutterNativeIntegrationSwiftPackage(
    targetPlatform: _targetPlatform,
    utils: utils,
    generateTests: generateTests,
  );

  /// Whether to generate tests for the Swift package integration tools and plugins.
  ///
  /// Test are only generated with `--ci` is passed in. This is only expected to be used
  /// by the Flutter CI. Tests are not needed by regular users of the command.
  bool get generateTests {
    return boolArg(FlutterGlobalOptions.kContinuousIntegrationFlag, global: true);
  }

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
    final Directory cacheDirectory = outputDirectory.childDirectory('.cache')
      ..createSync(recursive: true);
    final Directory flutterIntegrationPackage = outputDirectory.childDirectory(
      _kFlutterIntegrationPackageName,
    )..createSync(recursive: true);
    final Directory pluginsDirectory = flutterIntegrationPackage.childDirectory(_kFlutterPlugins);

    await project.regeneratePlatformSpecificTooling(releaseMode: false);

    final List<BuildInfo> buildInfos = await _getBuildInfos();
    if (buildInfos.isEmpty) {
      throwToolExit('--build-mode is required.');
    }

    final List<Plugin> plugins = await findPlugins(project);
    plugins.sort((Plugin left, Plugin right) => left.name.compareTo(right.name));
    await pluginSwiftDependencies.processPlugins(
      cacheDirectory: cacheDirectory,
      plugins: plugins,
      pluginsDirectory: pluginsDirectory,
    );

    final File codesignIdentityFile = cacheDirectory.childFile(_kCodesignIdentityFile);
    final String? codesignIdentity = await _codesign.getCodesignIdentity(
      buildInfo: buildInfos.first,
      codesignEnabled: boolArg(FlutterOptions.kCodesign),
      codesignIdentityOption: stringArg(FlutterOptions.kCodesignIdentity),
      identityFile: codesignIdentityFile,
      xcodeProject: _xcodeProject,
    );
    for (final buildInfo in buildInfos) {
      final String xcodeBuildConfiguration = buildInfo.mode.uppercaseName;
      final Directory xcframeworkOutput = flutterIntegrationPackage
          .childDirectory(xcodeBuildConfiguration)
          .childDirectory(_kFrameworks);

      await _buildXCFrameworks(
        buildInfo: buildInfo,
        xcodeBuildConfiguration: xcodeBuildConfiguration,
        xcframeworkOutput: xcframeworkOutput,
        cacheDirectory: cacheDirectory,
        codesignIdentity: codesignIdentity,
        codesignIdentityFile: codesignIdentityFile,
      );

      await _generateSwiftPackages(
        flutterIntegrationPackage: flutterIntegrationPackage,
        plugins: plugins,
        xcodeBuildConfiguration: xcodeBuildConfiguration,
        xcframeworkOutput: xcframeworkOutput,
      );
    }
    await flutterNativeIntegrationSwiftPackage.generateSwiftPackages(
      outputDirectory: outputDirectory,
      flutterIntegrationPackage: flutterIntegrationPackage,
      highestSupportedVersion: pluginSwiftDependencies.highestSupportedVersion,
    );
    createSourcesSymlink(flutterIntegrationPackage, buildInfos.first.mode.uppercaseName);

    if (_xcodeProject is IosProject) {
      generateLLDBInitFile(
        scriptsDirectory: outputDirectory.childDirectory(_kScripts),
        buildInfos: buildInfos,
        project: _xcodeProject,
      );
    }

    return FlutterCommandResult.success();
  }

  /// Copy or build xcframeworks for the Flutter framework, App framework, CocoaPod plugins,
  /// and native assets.
  Future<void> _buildXCFrameworks({
    required BuildInfo buildInfo,
    required String xcodeBuildConfiguration,
    required Directory xcframeworkOutput,
    required Directory cacheDirectory,
    required String? codesignIdentity,
    required File codesignIdentityFile,
  }) async {
    logger.printStatus('Building for $xcodeBuildConfiguration...');
    await flutterFrameworkDependency.generateArtifacts(
      buildMode: buildInfo.mode,
      xcframeworkOutput: xcframeworkOutput,
      codesignIdentity: codesignIdentity,
    );

    await appAndNativeAssetsDependencies.generateArtifacts(
      buildInfo: buildInfo,
      cacheDirectory: cacheDirectory,
      packageConfigPath: packageConfigPath(),
      targetFile: targetFile,
      xcframeworkOutput: xcframeworkOutput,
      codesignIdentity: codesignIdentity,
    );

    await cocoapodDependencies.generateArtifacts(
      buildInfo: buildInfo,
      buildStatic: boolArg('static'),
      cacheDirectory: cacheDirectory,
      xcframeworkOutput: xcframeworkOutput,
      codesignIdentity: codesignIdentity,
      codesignIdentityFile: codesignIdentityFile,
      pluginSwiftDependencies: pluginSwiftDependencies,
    );
  }

  Future<void> _generateSwiftPackages({
    required Directory flutterIntegrationPackage,
    required List<Plugin> plugins,
    required String xcodeBuildConfiguration,
    required Directory xcframeworkOutput,
  }) async {
    final Status status = logger.startProgress('   ├─Generating swift packages...');
    try {
      final Directory modeDirectory = flutterIntegrationPackage.childDirectory(
        xcodeBuildConfiguration,
      );
      final Directory packagesForConfiguration = modeDirectory.childDirectory(_kPackages);

      await flutterFrameworkDependency.generateSwiftPackage(packagesForConfiguration);

      await pluginRegistrant.generateSwiftPackage(
        modeDirectory: modeDirectory,
        plugins: plugins,
        xcodeBuildConfiguration: xcodeBuildConfiguration,
        pluginSwiftDependencies: pluginSwiftDependencies,
        flutterFrameworkDependency: flutterFrameworkDependency,
        appAndNativeAssetsDependencies: appAndNativeAssetsDependencies,
        cocoapodDependencies: cocoapodDependencies,
        packagesForConfiguration: packagesForConfiguration,
        xcframeworkOutput: xcframeworkOutput,
      );
    } finally {
      status.stop();
    }
  }

  /// Creates relative symlinks for FlutterPluginRegistrant using the [defaultBuildMode] so that
  /// the package may easily be switched to a different build mode by updating the symlink.
  ///
  /// Creates a symlink for the FlutterPluginRegistrant directory to the './[defaultBuildMode]' directory.
  @visibleForTesting
  void createSourcesSymlink(Directory flutterIntegrationPackage, String defaultBuildMode) {
    final Link flutterPluginRegistrant = flutterIntegrationPackage.childLink(
      kPluginSwiftPackageName,
    );
    _createOrUpdateSymlink(flutterPluginRegistrant, './$defaultBuildMode');
  }

  void _createOrUpdateSymlink(Link link, String target) {
    if (link.existsSync()) {
      link.updateSync(target);
    } else {
      link.createSync(target);
    }
  }

  /// iOS 26 physical devices require an LLDB Init File to use JIT debugging.
  /// This method generates the LLDB Init File and the helper python script.
  @visibleForTesting
  void generateLLDBInitFile({
    required Directory scriptsDirectory,
    required List<BuildInfo> buildInfos,
    required IosProject project,
  }) {
    scriptsDirectory.createSync(recursive: true);
    if (!buildInfos.any((BuildInfo info) => info.isDebug)) {
      return;
    }
    final File lldbInitSourceFile = project.lldbInitFile;
    final File lldbHelperPythonFile = project.lldbHelperPythonFile;
    final File lldbInitTargetFile = scriptsDirectory.childFile(lldbInitSourceFile.basename);
    final File lldbHelperPythonTargetFile = scriptsDirectory.childFile(
      lldbHelperPythonFile.basename,
    );
    lldbInitSourceFile.copySync(lldbInitTargetFile.path);
    lldbHelperPythonFile.copySync(lldbHelperPythonTargetFile.path);
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
    required Directory modeDirectory,
    required Directory packagesForConfiguration,
    required List<Plugin> plugins,
    required String xcodeBuildConfiguration,
    required FlutterPluginSwiftDependencies pluginSwiftDependencies,
    required FlutterFrameworkDependency flutterFrameworkDependency,
    required AppFrameworkAndNativeAssetsDependencies appAndNativeAssetsDependencies,
    required CocoaPodPluginDependencies cocoapodDependencies,
    required Directory xcframeworkOutput,
  }) async {
    final (
      List<SwiftPackagePackageDependency> pluginPackageDependencies,
      List<SwiftPackageTargetDependency> pluginTargetDependencies,
    ) = pluginSwiftDependencies.generateDependencies(
      packagesForConfiguration: packagesForConfiguration,
    );

    final (
      List<SwiftPackageTargetDependency> flutterGeneratedDependencies,
      List<SwiftPackageTarget> flutterGeneratedTargets,
    ) = appAndNativeAssetsDependencies.generateDependencies(
      xcframeworkOutput: xcframeworkOutput,
    );

    final (
      List<SwiftPackageTargetDependency> cocoaPodDependencies,
      List<SwiftPackageTarget> cocoaPodTargets,
    ) = cocoapodDependencies.generateDependencies(
      xcframeworkOutput: xcframeworkOutput,
    );

    final targetDependencies = <SwiftPackageTargetDependency>[
      flutterFrameworkDependency.targetDependency,
      ...pluginTargetDependencies,
      ...flutterGeneratedDependencies,
      ...cocoaPodDependencies,
    ];
    final packageDependencies = <SwiftPackagePackageDependency>[
      flutterFrameworkDependency.packageDependency,
      ...pluginPackageDependencies,
    ];

    const String swiftPackageName = kPluginSwiftPackageName;
    final File manifestFile = modeDirectory.childFile('Package.swift');

    final product = SwiftPackageProduct.library(
      name: swiftPackageName,
      targets: <String>[swiftPackageName],
      libraryType: .static,
    );

    final targets = <SwiftPackageTarget>[
      SwiftPackageTarget.defaultTarget(name: swiftPackageName, dependencies: targetDependencies),
      ...flutterGeneratedTargets,
      ...cocoaPodTargets,
    ];

    final pluginsPackage = SwiftPackage(
      manifest: manifestFile,
      name: swiftPackageName,
      platforms: <SwiftPackageSupportedPlatform>[pluginSwiftDependencies.highestSupportedVersion],
      products: <SwiftPackageProduct>[product],
      dependencies: packageDependencies,
      targets: targets,
      templateRenderer: _utils.templateRenderer,
      swiftCodeBeforePackageDefinition: '// $xcodeBuildConfiguration',
    );

    pluginsPackage.createSwiftPackage(generateEmptySources: false);

    await _generateSourceFiles(
      sourceDirectory: modeDirectory.childDirectory(_kSources),
      plugins: plugins,
    );
  }

  /// Generates GeneratedPluginRegistrant source files.
  Future<void> _generateSourceFiles({
    required Directory sourceDirectory,
    required List<Plugin> plugins,
  }) async {
    ErrorHandlingFileSystem.deleteIfExists(
      sourceDirectory.childDirectory(kPluginSwiftPackageName),
      recursive: true,
    );
    final File swiftFile = sourceDirectory
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
          // The registrant needs to be public to be accessible in the app, since it's within a
          // Swift package for add-to-app.
          public: true,
        );
    }
  }
}

/// Class that encapsulates logic needed to copy the Flutter framework and generate dependencies
/// for the FlutterPluginRegistrant swift package.
@visibleForTesting
class FlutterFrameworkDependency {
  FlutterFrameworkDependency({
    required FlutterDarwinPlatform targetPlatform,
    required BuildSwiftPackageUtils utils,
  }) : _targetPlatform = targetPlatform,
       _utils = utils;

  final FlutterDarwinPlatform _targetPlatform;
  final BuildSwiftPackageUtils _utils;

  /// Copies the Flutter/FlutterMacOS xcframework to [xcframeworkOutput].
  Future<void> generateArtifacts({
    required BuildMode buildMode,
    required Directory xcframeworkOutput,
    required String? codesignIdentity,
  }) async {
    final Status status = _utils.logger.startProgress(
      '   ├─Copying ${_targetPlatform.binaryName}.xcframework...',
    );
    try {
      final String frameworkArtifactPath = _utils.artifacts.getArtifactPath(
        _targetPlatform.xcframeworkArtifact,
        platform: _targetPlatform.targetPlatform,
        mode: buildMode,
      );
      final ProcessResult result = await _utils.processManager.run(<String>[
        'rsync',
        '-av',
        '--delete',
        '--filter',
        '- .DS_Store/',
        '--chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r',
        frameworkArtifactPath,
        xcframeworkOutput.path,
      ]);
      if (result.exitCode != 0) {
        throwToolExit(
          'Failed to copy $frameworkArtifactPath (exit ${result.exitCode}:\n'
          '${result.stdout}\n---\n${result.stderr}',
        );
      }
      if (codesignIdentity != null) {
        final Directory copiedXCFramework = xcframeworkOutput.childDirectory(
          '${_targetPlatform.binaryName}.xcframework',
        );
        await DarwinAddToAppCodesigning.codesignFlutterXCFramework(
          codesignIdentity: codesignIdentity,
          xcframework: copiedXCFramework,
          processManager: _utils.processManager,
          buildMode: buildMode,
        );
      }
    } finally {
      status.stop();
    }
  }

  /// Creates a FlutterFramework swift package within the [packagesForConfiguration]. This swift
  /// package vends the Flutter xcframework.
  Future<void> generateSwiftPackage(Directory packagesForConfiguration) async {
    final flutterFrameworkPackage = SwiftPackage(
      manifest: packagesForConfiguration
          .childDirectory(kFlutterGeneratedFrameworkSwiftPackageTargetName)
          .childFile('Package.swift'),
      name: kFlutterGeneratedFrameworkSwiftPackageTargetName,
      platforms: [],
      products: [
        SwiftPackageProduct.library(
          name: kFlutterGeneratedFrameworkSwiftPackageTargetName,
          targets: <String>[kFlutterGeneratedFrameworkSwiftPackageTargetName],
        ),
      ],
      dependencies: [],
      targets: [
        SwiftPackageTarget.defaultTarget(
          name: kFlutterGeneratedFrameworkSwiftPackageTargetName,
          dependencies: [SwiftPackageTargetDependency.target(name: _targetPlatform.binaryName)],
        ),
        SwiftPackageTarget.binaryTarget(
          name: _targetPlatform.binaryName,
          relativePath: '../../$_kFrameworks/${_targetPlatform.binaryName}.xcframework',
        ),
      ],
      templateRenderer: _utils.templateRenderer,
    );
    flutterFrameworkPackage.createSwiftPackage();
  }

  /// The package dependency for the FlutterFramework.
  ///
  /// ```swift
  ///   dependencies: [
  ///     .package(name: "FlutterFramework", path: "Sources/Packages/FlutterFramework"),
  /// ```
  SwiftPackagePackageDependency get packageDependency => SwiftPackagePackageDependency(
    name: kFlutterGeneratedFrameworkSwiftPackageTargetName,
    path: '$_kPackages/$kFlutterGeneratedFrameworkSwiftPackageTargetName',
  );

  /// The target dependency for the FlutterFramework.
  ///
  /// ```swift
  ///  .target(
  ///    name: "FlutterPluginRegistrant",
  ///    dependencies: [
  ///      .product(name: "FlutterFramework", package: "FlutterFramework"),
  /// ```
  SwiftPackageTargetDependency get targetDependency => SwiftPackageTargetDependency.product(
    name: kFlutterGeneratedFrameworkSwiftPackageTargetName,
    packageName: kFlutterGeneratedFrameworkSwiftPackageTargetName,
  );
}

/// Class that encapsulates logic needed to copy Flutter plugins that support SwiftPM and generate
/// dependencies for the FlutterPluginRegistrant swift package.
@visibleForTesting
class FlutterPluginSwiftDependencies {
  FlutterPluginSwiftDependencies({
    required FlutterDarwinPlatform targetPlatform,
    required BuildSwiftPackageUtils utils,
  }) : _targetPlatform = targetPlatform,
       _utils = utils;

  final FlutterDarwinPlatform _targetPlatform;
  final BuildSwiftPackageUtils _utils;

  /// The highest [SwiftPackageSupportedPlatform] among all of the Flutter SwiftPM plugins.
  /// Defaults to the Flutter framework's [SwiftPackageSupportedPlatform].
  SwiftPackageSupportedPlatform get highestSupportedVersion => _highestSupportedVersion;
  late SwiftPackageSupportedPlatform _highestSupportedVersion =
      _targetPlatform.supportedPackagePlatform;

  @visibleForTesting
  /// A list of plugin name, path to the copied Swift package, and the plugin's required minimum
  /// [SwiftPackageSupportedPlatform].
  final List<
    ({
      String name,
      String swiftPackagePath,
      SwiftPackageSupportedPlatform? packageMinimumSupportedPlatform,
    })
  >
  copiedPlugins = [];

  /// Copy plugins from pubcache to [pluginsDirectory] and sets [highestSupportedVersion] to later
  /// be used when creating the FlutterPluginRegistrant.
  Future<void> processPlugins({
    required Directory cacheDirectory,
    required List<Plugin> plugins,
    required Directory pluginsDirectory,
  }) async {
    final Status status = _utils.logger.startProgress('Processing plugins...');
    var skipped = true;
    try {
      ErrorHandlingFileSystem.deleteIfExists(pluginsDirectory, recursive: true);
    } on FileSystemException catch (e, stackTrace) {
      // Delete may fail due to Xcode writing hidden files to the directory at the same time.
      // The delete succeeds in deleting the non-XCode generated contents so it's okay to ignore.
      _utils.logger.printTrace('Failed to delete ${pluginsDirectory.path}: $e\n$stackTrace');
    }
    try {
      for (final plugin in plugins) {
        // If plugin does not support the platform, skip it.
        if (!plugin.supportSwiftPackageManagerForPlatform(
          _utils.fileSystem,
          _targetPlatform.name,
        )) {
          continue;
        }
        final ({
          String name,
          String swiftPackagePath,
          SwiftPackageSupportedPlatform? packageMinimumSupportedPlatform,
          bool restoredFromCache,
        })
        result = await _processPlugin(plugin, pluginsDirectory, cacheDirectory);
        if (!result.restoredFromCache) {
          skipped = false;
        }
        copiedPlugins.add((
          name: result.name,
          swiftPackagePath: result.swiftPackagePath,
          packageMinimumSupportedPlatform: result.packageMinimumSupportedPlatform,
        ));
      }
      _highestSupportedVersion = _determineHighestSupportedVersion(copiedPlugins);
    } finally {
      status.stop();
      if (skipped) {
        _utils.logger.printStatus('   │   └── Skipping processing plugins. No change detected.');
      }
    }
  }

  /// Processes a single plugin by copying it to the [pluginsDirectory] and modifying its Package.swift
  /// to inject the plugin's version and Flutter framework dependency (if applicable).
  ///
  /// The modified manifest is saved to the cache to allow for skipping plugin processing on the
  /// next run.
  Future<
    ({
      String name,
      String swiftPackagePath,
      SwiftPackageSupportedPlatform? packageMinimumSupportedPlatform,
      bool restoredFromCache,
    })
  >
  _processPlugin(Plugin plugin, Directory pluginsDirectory, Directory cacheDirectory) async {
    final String swiftPackagePath = await _copyPlugin(plugin, pluginsDirectory);
    final File manifest = _utils.fileSystem.directory(swiftPackagePath).childFile('Package.swift');

    final Directory pluginCache = cacheDirectory
        .childDirectory(_kManifests)
        .childDirectory(plugin.name);
    final File cachedManifest = pluginCache.childFile('Package.swift');
    final File cachedVersionFile = pluginCache.childFile('${_targetPlatform.name}.version');

    final ({
      String name,
      String swiftPackagePath,
      SwiftPackageSupportedPlatform? packageMinimumSupportedPlatform,
    })?
    cached = await _restoreFromCache(
      pluginCache: pluginCache,
      manifest: manifest,
      swiftPackagePath: swiftPackagePath,
      plugin: plugin,
      cachedManifest: cachedManifest,
      cachedVersionFile: cachedVersionFile,
    );
    if (cached != null) {
      return (
        name: cached.name,
        swiftPackagePath: cached.swiftPackagePath,
        packageMinimumSupportedPlatform: cached.packageMinimumSupportedPlatform,
        restoredFromCache: true,
      );
    }

    final Map<String, Object?> manifestAsJson = await _parseSwiftPackage(manifest);
    final SwiftPackageSupportedPlatform? parsedPlatformVersion =
        _parseSwiftPackageSupportedPlatform(manifestAsJson);
    final bool flutterDependencyFound = _hasFlutterDependency(manifestAsJson);
    if (!flutterDependencyFound) {
      final List<String> targetNames = _getTargetNames(manifestAsJson);
      if (targetNames.isEmpty) {
        throwToolExit('Failed to find any targets in ${plugin.name}');
      }
      await _injectFlutterDependencies(
        targetNames: targetNames,
        workingDirectory: _utils.fileSystem.directory(swiftPackagePath),
      );
    }

    _saveManifestInfoToCache(
      basename: _utils.fileSystem.directory(plugin.path).basename,
      manifest: manifest,
      cachedManifest: cachedManifest,
      cachedVersionFile: cachedVersionFile,
      parsedPlatformVersion: parsedPlatformVersion,
    );
    return (
      name: plugin.name,
      swiftPackagePath: swiftPackagePath,
      packageMinimumSupportedPlatform: parsedPlatformVersion,
      restoredFromCache: false,
    );
  }

  /// Copies the plugin to the [pluginsDirectory] and returns the path to the copied Swift package.
  Future<String> _copyPlugin(Plugin plugin, Directory pluginsDirectory) async {
    final Directory pluginDestination = pluginsDirectory.childDirectory(plugin.name)
      ..createSync(recursive: true);
    // The entire plugin is copied instead of just the Swift package to maintain any relative
    // links within the plugin.
    // Example: https://github.com/firebase/flutterfire/blob/198aef8db6c96a08f57d750f1fa756da5e4a68a5/packages/firebase_core/firebase_core/ios/firebase_core/Package.swift#L21-L26
    copyDirectory(
      _utils.fileSystem.directory(plugin.path),
      pluginDestination,
      shouldCopyDirectory: (directory) {
        // Skip copying symlinks and build outputs.
        return !directory.path.contains('.symlinks/plugins') &&
            !directory.path.contains('example/build/') &&
            !directory.path.contains('.build/') &&
            !directory.path.contains('.swiftpm/') &&
            !directory.path.contains('.dart_tool/');
      },
    );

    final String? swiftPackagePath = plugin.pluginSwiftPackagePath(
      _utils.fileSystem,
      _targetPlatform.name,
      overridePath: pluginDestination.path,
    );
    if (swiftPackagePath == null) {
      throwToolExit("Failed to find copied ${plugin.name}'s Package.swift. $_kFileAnIssue");
    }
    return swiftPackagePath;
  }

  /// Restores the plugin info from the cache if the original manifest has not changed and the
  /// cached files exist.
  Future<
    ({
      String name,
      String swiftPackagePath,
      SwiftPackageSupportedPlatform? packageMinimumSupportedPlatform,
    })?
  >
  _restoreFromCache({
    required Directory pluginCache,
    required File manifest,
    required String swiftPackagePath,
    required Plugin plugin,
    required File cachedManifest,
    required File cachedVersionFile,
  }) async {
    final fingerprinter = Fingerprinter(
      fileSystem: _utils.fileSystem,
      fingerprintPath: pluginCache.childFile('manifest.fingerprint').path,
      paths: [
        manifest.path,
        _utils.fileSystem.path.join(
          _utils.flutterRoot,
          'packages',
          'flutter_tools',
          'lib',
          'src',
          'commands',
          'build_swift_package.dart',
        ),
      ],
      logger: _utils.logger,
    );

    if (fingerprinter.doesFingerprintMatch() &&
        cachedManifest.existsSync() &&
        cachedVersionFile.existsSync()) {
      cachedManifest.copySync(manifest.path);

      SwiftPackageSupportedPlatform? parsedPlatform;
      final String versionString = cachedVersionFile.readAsStringSync();
      final Version? version = Version.parse(versionString);
      if (version != null) {
        parsedPlatform = SwiftPackageSupportedPlatform(
          platform: _targetPlatform.swiftPackagePlatform,
          version: version,
        );
      }
      return (
        name: plugin.name,
        swiftPackagePath: swiftPackagePath,
        packageMinimumSupportedPlatform: parsedPlatform,
      );
    }

    fingerprinter.writeFingerprint();
    return null;
  }

  /// Saves the plugin manifest and [SwiftPackageSupportedPlatform] to the cache.
  void _saveManifestInfoToCache({
    required File cachedManifest,
    required File manifest,
    required File cachedVersionFile,
    required String basename,
    required SwiftPackageSupportedPlatform? parsedPlatformVersion,
  }) {
    // Append the basename to the manifest to force Xcode to re-cache the package when the version changes.
    cachedManifest.writeAsStringSync('${manifest.readAsStringSync()}\n\n// $basename');
    cachedVersionFile.writeAsStringSync(parsedPlatformVersion?.version.toString() ?? '');
  }

  /// Determine the highest [SwiftPackageSupportedPlatform] from the list of plugins.
  SwiftPackageSupportedPlatform _determineHighestSupportedVersion(
    List<
      ({
        String name,
        String swiftPackagePath,
        SwiftPackageSupportedPlatform? packageMinimumSupportedPlatform,
      })
    >
    plugins,
  ) {
    SwiftPackageSupportedPlatform highest = _targetPlatform.supportedPackagePlatform;
    for (final plugin in plugins) {
      final SwiftPackageSupportedPlatform? pluginVersion = plugin.packageMinimumSupportedPlatform;
      if (pluginVersion != null && pluginVersion.version > highest.version) {
        highest = pluginVersion;
      }
    }
    return highest;
  }

  /// Uses `swift` command line tool to convert Package.swift to json.
  Future<Map<String, Object?>> _parseSwiftPackage(File swiftPackageManifest) async {
    try {
      final ProcessResult parsedManifest = await _utils.processManager.run([
        'swift',
        'package',
        'dump-package',
      ], workingDirectory: swiftPackageManifest.parent.path);
      return json.decode(parsedManifest.stdout.toString()) as Map<String, Object?>;
    } on Exception catch (e, stackTrace) {
      throwToolExit(
        'Failed to decode ${swiftPackageManifest.path}. $_kFileAnIssue and include this file '
        'and the following stack trace: \n$e\n$stackTrace',
      );
    }
  }

  /// Parses the Swift package manifest to determine the [SwiftPackageSupportedPlatform].
  SwiftPackageSupportedPlatform? _parseSwiftPackageSupportedPlatform(
    Map<String, Object?> manifestAsJson,
  ) {
    if (manifestAsJson case {'platforms': final List<Object?> platformsData}) {
      for (final Map<String, Object?> platformData
          in platformsData.whereType<Map<String, Object?>>()) {
        final SwiftPackageSupportedPlatform? platform = SwiftPackageSupportedPlatform.fromJson(
          platformData,
        );
        if (platform != null && platform.platform == _targetPlatform.swiftPackagePlatform) {
          return platform;
        }
      }
    }
    return null;
  }

  /// Checks if the Swift package has a dependency on the Flutter framework.
  bool _hasFlutterDependency(Map<String, Object?> manifestAsJson) {
    if (manifestAsJson case {'dependencies': final List<Object?> dependenciesData}) {
      for (final Map<String, Object?> dependencyData
          in dependenciesData.whereType<Map<String, Object?>>()) {
        if (dependencyData case {'fileSystem': final List<Object?> fileSystemData}) {
          for (final Map<String, Object?> fileSystemData
              in fileSystemData.whereType<Map<String, Object?>>()) {
            if (fileSystemData['identity'] ==
                kFlutterGeneratedFrameworkSwiftPackageTargetName.toLowerCase()) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  /// Parses the Swift package manifest to extract the names of the regular targets.
  List<String> _getTargetNames(Map<String, Object?> manifestAsJson) {
    final List<String> targetNames = [];
    if (manifestAsJson case {'targets': final List<Object?> targetData}) {
      for (final Map<String, Object?> target in targetData.whereType<Map<String, Object?>>()) {
        if (target case {'type': final String targetType, 'name': final String targetName}) {
          if (targetType == 'regular') {
            targetNames.add(targetName);
          }
        }
      }
    }
    return targetNames;
  }

  /// Injects the Flutter framework as a dependency into the Swift package using `swift` commands.
  ///
  /// This is necessary as adding the FlutterFramework dependency was a secondary requirement that
  /// some plugins may not have adopted yet.
  Future<void> _injectFlutterDependencies({
    required List<String> targetNames,
    required Directory workingDirectory,
  }) async {
    final ProcessResult result = await _utils.processManager.run([
      'swift',
      'package',
      'add-dependency',
      '../FlutterFramework',
      '--type',
      'path',
    ], workingDirectory: workingDirectory.path);
    if (result.exitCode != 0) {
      throwToolExit('Failed to add FlutterFramework as a dependency. ${result.stderr}');
    }
    for (final targetName in targetNames) {
      final ProcessResult targetResult = await _utils.processManager.run([
        'swift',
        'package',
        'add-target-dependency',
        kFlutterGeneratedFrameworkSwiftPackageTargetName,
        targetName,
        '--package',
        kFlutterGeneratedFrameworkSwiftPackageTargetName,
      ], workingDirectory: workingDirectory.path);
      if (targetResult.exitCode != 0) {
        throwToolExit(
          'Failed to add FlutterFramework as a target dependency. ${targetResult.stderr}',
        );
      }
    }
  }

  /// Returns dependencies from the SwiftPM-supported plugins for the FlutterPluginRegistrant.
  ///
  /// Also creates the symlinks to the Swift package within [packagesForConfiguration].
  (List<SwiftPackagePackageDependency>, List<SwiftPackageTargetDependency>) generateDependencies({
    required Directory packagesForConfiguration,
  }) {
    final List<SwiftPackagePackageDependency> packageDependencies = [];
    final List<SwiftPackageTargetDependency> targetDependencies = [];
    for (final ({
          String name,
          String swiftPackagePath,
          SwiftPackageSupportedPlatform? packageMinimumSupportedPlatform,
        })
        plugin
        in copiedPlugins) {
      // Symlink the swift package inside the packagesForConfiguration directory
      final Link symlink = packagesForConfiguration.childLink(plugin.name);
      final String target = _utils.fileSystem.path.relative(
        plugin.swiftPackagePath,
        from: symlink.parent.path,
      );
      if (symlink.existsSync()) {
        symlink.updateSync(target);
      } else {
        symlink.createSync(target, recursive: true);
      }

      packageDependencies.add(
        SwiftPackagePackageDependency(name: plugin.name, path: '$_kPackages/${plugin.name}'),
      );
      targetDependencies.add(
        SwiftPackageTargetDependency.product(
          name: plugin.name.replaceAll('_', '-'),
          packageName: plugin.name,
        ),
      );
    }

    return (packageDependencies, targetDependencies);
  }
}

/// Class that encapsulates logic needed to build App and native asset frameworks and generate
/// dependencies for the FlutterPluginRegistrant swift package.
@visibleForTesting
class AppFrameworkAndNativeAssetsDependencies {
  AppFrameworkAndNativeAssetsDependencies({
    required FlutterDarwinPlatform targetPlatform,
    required BuildSwiftPackageUtils utils,
  }) : _targetPlatform = targetPlatform,
       _utils = utils;

  final FlutterDarwinPlatform _targetPlatform;
  final BuildSwiftPackageUtils _utils;

  static const String _appBinaryName = 'App';

  /// Builds an App.framework for every sdk and then combines them into a single XCFramework.
  /// Also, builds any native assets for each sdk and bundles them into XCFrameworks.
  ///
  /// Intermediate build files are put in the [cacheDirectory]. The final XCFrameworks are copied
  /// to the [xcframeworkOutput].
  Future<void> generateArtifacts({
    required BuildInfo buildInfo,
    required Directory xcframeworkOutput,
    required Directory cacheDirectory,
    required String packageConfigPath,
    required String targetFile,
    required String? codesignIdentity,
  }) async {
    final String xcodeBuildConfiguration = buildInfo.mode.uppercaseName;
    final appFrameworks = <Directory>[];
    final Map<String, List<({XcodeSdk sdk, String path})>> nativeAssetFrameworks = {};
    final List<String> warnings = [];

    final Status status = _utils.logger.startProgress(
      '   ├─Building $_appBinaryName.xcframework and native assets...',
    );
    try {
      // Create App.framework (and .frameworks for native assets) for each sdk.
      for (final XcodeSdk sdk in _targetPlatform.sdks) {
        final Directory outputBuildDirectory = cacheDirectory
            .childDirectory(xcodeBuildConfiguration)
            .childDirectory(sdk.platformName);
        await _buildFlutterGeneratedFrameworks(
          buildInfo: buildInfo,
          outputBuildDirectory: outputBuildDirectory,
          packageConfigPath: packageConfigPath,
          targetFile: targetFile,
          platform: _targetPlatform,
          sdk: sdk,
        );
        final Directory appFramework = outputBuildDirectory.childDirectory(
          '$_appBinaryName.framework',
        );
        appFrameworks.add(appFramework);
        _findNativeAssetFrameworks(outputBuildDirectory, nativeAssetFrameworks, sdk: sdk);
      }

      // Create App.xcframework
      await _produceXCFramework(
        frameworks: appFrameworks,
        frameworkBinaryName: _appBinaryName,
        outputDirectory: xcframeworkOutput,
        processManager: _utils.processManager,
        codesignIdentity: codesignIdentity,
        buildMode: buildInfo.mode,
      );

      // Create native assets XCFrameworks
      final Directory nativeAssetOutput = xcframeworkOutput.childDirectory(_kNativeAssets);
      ErrorHandlingFileSystem.deleteIfExists(nativeAssetOutput, recursive: true);
      if (nativeAssetFrameworks.isNotEmpty) {
        final List<String> nativeAssetWarnings = await _createXCFrameworksForNativeAssets(
          nativeAssetFrameworks: nativeAssetFrameworks,
          xcframeworkOutput: nativeAssetOutput,
          codesignIdentity: codesignIdentity,
          buildInfo: buildInfo,
        );
        warnings.addAll(nativeAssetWarnings);
      }
    } finally {
      status.stop();
      for (final warning in warnings) {
        _utils.logger.printWarning('   │   └── $warning');
      }
    }
  }

  /// Use the Flutter build system to build Flutter generated frameworks for the given [platform]
  /// and [sdk].
  Future<void> _buildFlutterGeneratedFrameworks({
    required BuildInfo buildInfo,
    required Directory outputBuildDirectory,
    required String packageConfigPath,
    required String targetFile,
    required FlutterDarwinPlatform platform,
    required XcodeSdk sdk,
  }) async {
    final environment = Environment(
      projectDir: _utils.fileSystem.currentDirectory,
      packageConfigPath: packageConfigPath,
      outputDir: outputBuildDirectory,
      buildDir: _utils.project.dartTool.childDirectory('flutter_build'),
      cacheDir: _utils.cache.getRoot(),
      flutterRootDir: _utils.fileSystem.directory(_utils.flutterRoot),
      defines: <String, String>{
        kTargetFile: targetFile,
        kTargetPlatform: getNameForTargetPlatform(platform.targetPlatform),
        ...await _platformDefines(platform, sdk),
        ...buildInfo.toBuildSystemEnvironment(),
        kBuildSwiftPackage: 'true',
      },
      artifacts: _utils.artifacts,
      fileSystem: _utils.fileSystem,
      logger: _utils.logger,
      processManager: _utils.processManager,
      platform: _utils.platform,
      analytics: _utils.analytics,
      engineVersion: _utils.artifacts.usesLocalArtifacts
          ? null
          : _utils.flutterVersion.engineRevision,
      generateDartPluginRegistry: true,
    );
    final Target target = determineTarget(platform, sdk, buildInfo);

    final BuildResult result = await _utils.buildSystem.build(target, environment);
    if (!result.success) {
      for (final ExceptionMeasurement measurement in result.exceptions.values) {
        _utils.logger.printError(measurement.exception.toString());
      }
      throwToolExit('The $_appBinaryName.xcframework build failed.');
    }
  }

  /// Find all native assets in the [outputDirectory] and add them to the [nativeAssetFrameworks]
  /// map, which maps the native asset key to a list of (sdk, path) pairs.
  void _findNativeAssetFrameworks(
    Directory outputDirectory,
    Map<String, List<({XcodeSdk sdk, String path})>> nativeAssetFrameworks, {
    required XcodeSdk sdk,
  }) {
    final Map<String, String> deviceAssets = DarwinAddToAppNativeAssets.parseNativeAssetsManifest(
      outputDirectory,
      _targetPlatform,
    );
    for (final MapEntry<String, String> asset in deviceAssets.entries) {
      final String pathToAsset = _utils.fileSystem.path.join(
        outputDirectory.path,
        'native_assets',
        asset.value,
      );
      nativeAssetFrameworks.putIfAbsent(asset.key, () => <({XcodeSdk sdk, String path})>[]).add((
        sdk: sdk,
        path: pathToAsset,
      ));
    }
  }

  /// Create XCFrameworks for native assets.
  ///
  /// Iterates through [nativeAssetFrameworks] and verifies that all assets support all sdks with
  /// the same framework name. Then creates an XCFramework for each asset.
  ///
  /// Returns a list of warnings for assets that do not support all sdks to be printed after the
  /// status is stopped. Throws if a native asset has a different framework name for different SDKs.
  Future<List<String>> _createXCFrameworksForNativeAssets({
    required Map<String, List<({XcodeSdk sdk, String path})>> nativeAssetFrameworks,
    required Directory xcframeworkOutput,
    required String? codesignIdentity,
    required BuildInfo buildInfo,
  }) async {
    final List<String> warnings = [];
    for (final List<({XcodeSdk sdk, String path})> assetPaths in nativeAssetFrameworks.values) {
      final String binaryName = _utils.fileSystem.file(assetPaths.first.path).basename;

      // Add a warning if the asset does not support all sdks.
      if (assetPaths.length != _targetPlatform.sdks.length) {
        final List<String> unsupportedSdks = [];
        for (final XcodeSdk sdk in _targetPlatform.sdks) {
          if (!assetPaths.any((asset) => asset.sdk == sdk)) {
            unsupportedSdks.add('${sdk.displayName} (${sdk.platformName})');
          }
        }
        warnings.add('The asset "$binaryName" does not support ${unsupportedSdks.join(', ')}');
      }

      final List<Directory> frameworks = [];
      var invalidAsset = false;
      var pathPerPlatformMessage = '';
      final String frameworkName = _utils.fileSystem.file(assetPaths.first.path).parent.basename;

      for (final assetPath in assetPaths) {
        final File binaryAsset = _utils.fileSystem.file(assetPath.path);
        // The parent of the binary is the framework directory.
        final Directory frameworkDir = binaryAsset.parent;
        if (frameworkDir.basename != frameworkName) {
          invalidAsset = true;
        }
        frameworks.add(frameworkDir);
        pathPerPlatformMessage +=
            '  - ${assetPath.sdk.platformName}: '
            '${frameworkDir.basename}/${binaryAsset.basename}\n';
      }

      // Throw an error if the asset has different framework names across sdks.
      if (invalidAsset) {
        throwToolExit(
          'Consistent code asset framework names are required for '
          'XCFramework creation.\n'
          'The asset "$binaryName" has different framework paths across '
          'platforms:\n'
          '$pathPerPlatformMessage'
          'This is likely an issue in the package providing the asset. '
          'Please report this to the package maintainers and ensure the '
          '"build.dart" hook produces consistent filenames.',
        );
      }
      await _produceXCFramework(
        frameworks: frameworks,
        frameworkBinaryName: binaryName,
        outputDirectory: xcframeworkOutput,
        processManager: _utils.processManager,
        codesignIdentity: codesignIdentity,
        buildMode: buildInfo.mode,
      );
    }

    return warnings;
  }

  /// Determine the [Target] to build based on the [platform], [sdk], and [buildInfo].
  @visibleForTesting
  Target determineTarget(FlutterDarwinPlatform platform, XcodeSdk sdk, BuildInfo buildInfo) {
    switch (platform) {
      case FlutterDarwinPlatform.ios:
        // Always build debug for simulator.
        if (buildInfo.isDebug || sdk.sdkType == EnvironmentType.simulator) {
          return const DebugIosApplicationBundle();
        } else if (buildInfo.isProfile) {
          return const ProfileIosApplicationBundle();
        } else {
          return const ReleaseIosApplicationBundle();
        }
      case FlutterDarwinPlatform.macos:
        if (buildInfo.isDebug) {
          return const DebugMacOSBundleFlutterAssets();
        } else if (buildInfo.isProfile) {
          return const ProfileMacOSBundleFlutterAssets();
        } else {
          return const ReleaseMacOSBundleFlutterAssets();
        }
    }
  }

  /// Defines specific to the platform.
  Future<Map<String, String>> _platformDefines(FlutterDarwinPlatform platform, XcodeSdk sdk) async {
    switch (platform) {
      case FlutterDarwinPlatform.ios:
        return <String, String>{
          kIosArchs: defaultIOSArchsForEnvironment(
            sdk.sdkType,
            _utils.artifacts,
          ).map((DarwinArch e) => e.name).join(' '),
          kSdkRoot: await _utils.xcode.sdkLocation(sdk.sdkType),
        };
      case FlutterDarwinPlatform.macos:
        return <String, String>{
          kDarwinArchs: defaultMacOSArchsForEnvironment(
            _utils.artifacts,
          ).map((DarwinArch e) => e.name).join(' '),
        };
    }
  }

  /// The target dependency for the App framework.
  ///
  /// ```swift
  ///  .target(
  ///    name: "FlutterPluginRegistrant",
  ///    dependencies: [
  ///      .target(name: "App"),
  /// ```
  SwiftPackageTargetDependency get appTargetDependency =>
      SwiftPackageTargetDependency.target(name: _appBinaryName);

  /// The binary target for the App framework.
  ///
  /// ```swift
  ///   .binaryTarget(
  ///     name: "App",
  ///     path: "Sources/Frameworks/App.xcframework"
  ///   )
  /// ```
  SwiftPackageTarget get appBinaryTarget => SwiftPackageTarget.binaryTarget(
    name: _appBinaryName,
    relativePath: '$_kFrameworks/$_appBinaryName.xcframework',
  );

  /// Generate target dependencies and binary targets for the App.xcframework and any native
  /// assets.
  (List<SwiftPackageTargetDependency>, List<SwiftPackageTarget>) generateDependencies({
    required Directory xcframeworkOutput,
  }) {
    final (
      List<SwiftPackageTargetDependency> targetDependencies,
      List<SwiftPackageTarget> packageTargets,
    ) = generateDependenciesFromDirectory(
      fileSystem: _utils.fileSystem,
      directoryName: _kNativeAssets,
      xcframeworkDirectory: xcframeworkOutput.childDirectory(_kNativeAssets),
    );
    targetDependencies.add(appTargetDependency);
    packageTargets.add(appBinaryTarget);
    return (targetDependencies, packageTargets);
  }
}

/// Class that encapsulates the logic for building CocoaPod plugins for every platform and sdk into
/// frameworks and then combines them into a single XCFramework for each.
@visibleForTesting
class CocoaPodPluginDependencies {
  CocoaPodPluginDependencies({
    required FlutterDarwinPlatform targetPlatform,
    required BuildSwiftPackageUtils utils,
  }) : _targetPlatform = targetPlatform,
       _utils = utils;

  final FlutterDarwinPlatform _targetPlatform;
  final BuildSwiftPackageUtils _utils;

  late final XcodeBasedProject _xcodeProject = _targetPlatform.xcodeProject(_utils.project);

  /// Builds CocoaPod plugins for every platform and sdk into frameworks and then combines them into
  /// a single XCFramework for each.
  ///
  /// Intermediate build files are put in the [cacheDirectory]. The final XCFramework are copied to
  /// the [xcframeworkOutput].
  Future<void> generateArtifacts({
    required BuildInfo buildInfo,
    required Directory cacheDirectory,
    required Directory xcframeworkOutput,
    required bool buildStatic,
    required String? codesignIdentity,
    required File codesignIdentityFile,
    required FlutterPluginSwiftDependencies pluginSwiftDependencies,
  }) async {
    final String xcodeBuildConfiguration = buildInfo.mode.uppercaseName;
    if (!_xcodeProject.podfile.existsSync()) {
      return;
    }
    final Directory cocoapodXCFrameworkOutput = xcframeworkOutput.childDirectory(_kCocoaPods);
    final Directory cocoapodCacheDirectory = cacheDirectory
        .childDirectory(xcodeBuildConfiguration)
        .childDirectory(_kCocoaPods);

    final Status status = _utils.logger.startProgress('   ├─Building CocoaPod frameworks...');
    var skipped = false;
    try {
      final bool dependenciesChanged = _haveDependenciesChanged(
        cacheDirectory.path,
        cocoapodXCFrameworkOutput,
        buildInfo.mode.cliName,
        buildStatic,
        _xcodeProject,
        codesignIdentityFile,
      );
      if (!dependenciesChanged && cocoapodXCFrameworkOutput.existsSync()) {
        skipped = true;
        return;
      }
      if (dependenciesChanged) {
        ErrorHandlingFileSystem.deleteIfExists(cocoapodCacheDirectory, recursive: true);
        ErrorHandlingFileSystem.deleteIfExists(cocoapodXCFrameworkOutput, recursive: true);
      }

      await processPods(_xcodeProject, buildInfo);
      // Pods directory may not exist until after `processPods` is called.
      final Directory podsDirectory = _xcodeProject.hostAppRoot.childDirectory('Pods');
      if (!podsDirectory.existsSync()) {
        return;
      }

      final frameworksPerPod = <String, List<Directory>>{};
      for (final XcodeSdk sdk in _targetPlatform.sdks) {
        final Directory outputBuildDirectory = cocoapodCacheDirectory.childDirectory(
          sdk.platformName,
        );
        final Map<String, List<Directory>> sdkSpecificFrameworks = await _buildCocoaPodsForSdk(
          sdk: sdk,
          platform: _targetPlatform,
          xcodeBuildConfiguration: xcodeBuildConfiguration,
          buildStatic: buildStatic,
          outputBuildDirectory: outputBuildDirectory,
          podsDirectory: podsDirectory,
          pluginSwiftDependencies: pluginSwiftDependencies,
        );
        sdkSpecificFrameworks.forEach((String name, List<Directory> frameworks) {
          frameworksPerPod.putIfAbsent(name, () => <Directory>[]).addAll(frameworks);
        });
      }

      for (final MapEntry<String, List<Directory>> entry in frameworksPerPod.entries) {
        await _produceXCFramework(
          frameworks: entry.value,
          frameworkBinaryName: entry.key,
          outputDirectory: cocoapodXCFrameworkOutput,
          processManager: _utils.processManager,
          codesignIdentity: codesignIdentity,
          buildMode: buildInfo.mode,
        );
      }
      _writeFingerprint(
        cacheDirectory.path,
        cocoapodXCFrameworkOutput,
        buildInfo.mode.cliName,
        buildStatic,
        codesignIdentityFile,
      );
    } finally {
      status.stop();
      if (skipped) {
        _utils.logger.printStatus(
          '   │   └── Skipping building CocoaPod plugins. No change detected.',
        );
      }
    }
  }

  @visibleForTesting
  /// Wrap [processPodsIfNeeded] in a method to be overwritten in tests.
  Future<void> processPods(XcodeBasedProject xcodeProject, BuildInfo buildInfo) async {
    await processPodsIfNeeded(xcodeProject, _targetPlatform.buildDirectory(), buildInfo.mode);
  }

  /// Builds CocoaPod plugins into frameworks for the given [xcodeBuildConfiguration], [platform],
  /// and [sdk].
  ///
  /// Returns a Map where the key is the name of the plugin and the value is a list of [Directory]s
  /// containing the plugin's frameworks.
  Future<Map<String, List<Directory>>> _buildCocoaPodsForSdk({
    required XcodeSdk sdk,
    required FlutterDarwinPlatform platform,
    required String xcodeBuildConfiguration,
    required bool buildStatic,
    required Directory outputBuildDirectory,
    required Directory podsDirectory,
    required FlutterPluginSwiftDependencies pluginSwiftDependencies,
  }) async {
    final String configuration = _configurationForSdkType(sdk, xcodeBuildConfiguration);
    final ProcessResult buildPluginsResult = await _utils.processManager.run(<String>[
      ..._utils.xcode.xcrunCommand(),
      'xcodebuild',
      '-alltargets',
      '-sdk',
      sdk.platformName,
      '-configuration',
      configuration,
      'SYMROOT=${outputBuildDirectory.path}',
      'ONLY_ACTIVE_ARCH=NO', // No device targeted, so build all valid architectures.
      'BUILD_LIBRARY_FOR_DISTRIBUTION=YES',
      if (buildStatic) 'MACH_O_TYPE=staticlib',
    ], workingDirectory: podsDirectory.path);
    if (buildPluginsResult.exitCode != 0) {
      throwToolExit('Unable to build CocoaPod plugin frameworks: ${buildPluginsResult.stderr}');
    }

    final Directory configurationBuildDir;
    switch (platform) {
      case FlutterDarwinPlatform.macos:
        configurationBuildDir = outputBuildDirectory.childDirectory(configuration);
      case FlutterDarwinPlatform.ios:
        configurationBuildDir = outputBuildDirectory.childDirectory(
          '$configuration-${sdk.platformName}',
        );
    }
    return _findFrameworks(configurationBuildDir, pluginSwiftDependencies);
  }

  /// Iterates through the build files and find .frameworks
  ///
  /// ex.
  /// ```text
  /// > Debug-iphoneos
  ///   > plugin_a
  ///     > plugin_a.framework
  /// ```
  Future<Map<String, List<Directory>>> _findFrameworks(
    Directory configurationBuildDir,
    FlutterPluginSwiftDependencies pluginSwiftDependencies,
  ) async {
    final frameworks = <String, List<Directory>>{};

    final Iterable<Directory> products = configurationBuildDir
        .listSync(followLinks: false)
        .whereType<Directory>();
    for (final builtProduct in products) {
      for (final Directory podProduct
          in builtProduct.listSync(followLinks: false).whereType<Directory>()) {
        final String podFrameworkName = podProduct.basename;
        if (_utils.fileSystem.path.extension(podFrameworkName) != '.framework') {
          continue;
        }
        final String binaryName = _utils.fileSystem.path.basenameWithoutExtension(podFrameworkName);
        if (_utils.project.isModule &&
            (binaryName == 'FlutterPluginRegistrant' ||
                pluginSwiftDependencies.copiedPlugins.any((record) => record.name == binaryName))) {
          // Flutter modules don't support SwiftPM and force all plugins to be built as CocoaPods.
          // Since SwiftPM supported plugins are used as Swift packages in this command, they should
          // be skipped and not included as CocoaPod framework dependencies.
          // In addition, modules generate a FlutterPluginRegistrant framework. Since the
          // FlutterPluginRegistrant is also being used as a Swift Package in this command, it should
          // also be skipped.
          // TODO(vashworth): Find a way to prevent CocoaPods from building SwiftPM plugins and
          // FlutterPluginRegistrant when using a module in the first place.
          // See https://github.com/flutter/flutter/issues/184590.
          continue;
        }
        frameworks.putIfAbsent(binaryName, () => <Directory>[]).add(podProduct);
      }
    }
    return frameworks;
  }

  /// Return true if CocoaPod fingerprinter has changed, or if the pod lock files
  /// are outdated.
  bool _haveDependenciesChanged(
    String cacheDirectoryPath,
    Directory cocoapodXCFrameworkDirectory,
    String xcodeBuildConfiguration,
    bool buildStatic,
    XcodeBasedProject xcodeProject,
    File codesignIdentityFile,
  ) {
    final Fingerprinter fingerprinter = _cocoapodsFingerprinter(
      cacheDirectoryPath: cacheDirectoryPath,
      cocoapodXCFrameworkDirectory: cocoapodXCFrameworkDirectory,
      xcodeBuildConfiguration: xcodeBuildConfiguration,
      buildStatic: buildStatic,
      codesignIdentityFile: codesignIdentityFile,
    );
    if (!fingerprinter.doesFingerprintMatch()) {
      return true;
    }
    return CocoaPods.podLockFilesOutdated(xcodeProject);
  }

  void _writeFingerprint(
    String cacheDirectoryPath,
    Directory cocoapodXCFrameworkDirectory,
    String xcodeBuildConfiguration,
    bool buildStatic,
    File codesignIdentityFile,
  ) {
    final Fingerprinter fingerprinter = _cocoapodsFingerprinter(
      cacheDirectoryPath: cacheDirectoryPath,
      cocoapodXCFrameworkDirectory: cocoapodXCFrameworkDirectory,
      xcodeBuildConfiguration: xcodeBuildConfiguration,
      buildStatic: buildStatic,
      codesignIdentityFile: codesignIdentityFile,
    );
    fingerprinter.writeFingerprint();
  }

  /// Returns a [Fingerprinter] for the CocoaPod plugins.
  ///
  /// The [Fingerprinter] is used to check if the CocoaPod output, static status, build
  /// configuration, this file, Xcode project, Podfile, generated plugin Swift Package, or
  /// podhelper have changed since the last build.
  Fingerprinter _cocoapodsFingerprinter({
    required String cacheDirectoryPath,
    required Directory cocoapodXCFrameworkDirectory,
    required String xcodeBuildConfiguration,
    required bool buildStatic,
    required File codesignIdentityFile,
  }) {
    final fingerprintedFiles = <String>[codesignIdentityFile.path];

    final File staticStatus =
        _utils.fileSystem.file(
            _utils.fileSystem.path.join(
              cacheDirectoryPath,
              'build_${xcodeBuildConfiguration}_static_status',
            ),
          )
          ..createSync(recursive: true)
          ..writeAsStringSync('$buildStatic');
    fingerprintedFiles.add(staticStatus.path);

    // Add already created XCFrameworks
    if (cocoapodXCFrameworkDirectory.existsSync()) {
      for (final FileSystemEntity entity in cocoapodXCFrameworkDirectory.listSync(
        recursive: true,
      )) {
        if (entity is File) {
          fingerprintedFiles.add(entity.path);
        }
      }
    }

    // If the Xcode project, Podfile, generated plugin Swift Package, or podhelper
    // have changed since last run, pods should be updated.
    fingerprintedFiles.add(_xcodeProject.xcodeProjectInfoFile.path);
    fingerprintedFiles.add(_xcodeProject.podfile.path);
    if (_xcodeProject.flutterPluginSwiftPackageManifest.existsSync()) {
      fingerprintedFiles.add(_xcodeProject.flutterPluginSwiftPackageManifest.path);
    }

    final fingerprinter = Fingerprinter(
      fingerprintPath: _utils.fileSystem.path.join(
        cacheDirectoryPath,
        'build_${xcodeBuildConfiguration}_pod_inputs.fingerprint',
      ),
      paths: <String>[
        _utils.fileSystem.path.join(
          _utils.flutterRoot,
          'packages',
          'flutter_tools',
          'bin',
          'podhelper.rb',
        ),
        _utils.fileSystem.path.join(
          _utils.flutterRoot,
          'packages',
          'flutter_tools',
          'lib',
          'src',
          'commands',
          'build_swift_package.dart',
        ),
        ...fingerprintedFiles,
      ],
      fileSystem: _utils.fileSystem,
      logger: _utils.logger,
    );
    return fingerprinter;
  }

  /// With SwiftPM integration, we can't reliably switch the build mode for CocoaPod frameworks.
  /// This can cause errors like "missing required module 'SwiftOnoneSupport'" when building for release.
  /// To avoid this, we always build debug for simulator and release for device.
  String _configurationForSdkType(XcodeSdk sdk, String configuration) {
    if (sdk.sdkType == EnvironmentType.simulator) {
      // Always build debug for simulator.
      return BuildMode.debug.uppercaseName;
    }
    return configuration;
  }

  /// The target dependencies and binary targets for the CocoaPod plugin xcframeworks.
  ///
  /// ```swift
  ///  .target(
  ///    name: "FlutterPluginRegistrant",
  ///    dependencies: [
  ///      .target(name: "cocoapod_plugin_a"),
  ///
  ///    ...
  ///
  ///   .binaryTarget(
  ///     name: "cocoapod_plugin_a",
  ///     path: "Frameworks/CocoaPods/cocoapod_plugin_a.xcframework"
  ///   )
  /// ```
  (List<SwiftPackageTargetDependency>, List<SwiftPackageTarget>) generateDependencies({
    required Directory xcframeworkOutput,
  }) {
    return generateDependenciesFromDirectory(
      fileSystem: _utils.fileSystem,
      directoryName: _kCocoaPods,
      xcframeworkDirectory: xcframeworkOutput.childDirectory(_kCocoaPods),
    );
  }
}

/// Class that encapsulates the logic for the Swift package that will be used to integrate
/// a Flutter app into a native iOS or macOS app.
///
/// This Swift package will depend on the FlutterRegistrant Swift package and will include tools
/// that will be integrated into the native build process.
@visibleForTesting
class FlutterNativeIntegrationSwiftPackage {
  FlutterNativeIntegrationSwiftPackage({
    required BuildSwiftPackageUtils utils,
    required bool generateTests,
    required FlutterDarwinPlatform targetPlatform,
  }) : _targetPlatform = targetPlatform,
       _utils = utils,
       _generateTests = generateTests;

  final FlutterDarwinPlatform _targetPlatform;
  final BuildSwiftPackageUtils _utils;
  final bool _generateTests;

  /// The name of the Swift package that vends the executable and plugin tools.
  static const String _kFlutterNativeTools = 'FlutterNativeTools';

  /// The name of the Swift package library with common logic shared among the other tools.
  static const String _kFlutterToolHelper = 'FlutterToolHelper';

  /// The name of the Swift package executable tool that will be used during a scheme pre-action.
  static const String _kFlutterPrebuildTool = 'FlutterPrebuildTool';

  /// The name of the Swift package executable tool that will be used during a build run phase that
  /// occurs after the Flutter.framework and App.framework are embedded into the app bundle.
  static const String _kFlutterAssembleTool = 'FlutterAssembleTool';

  /// The name of the Swift package executable tool that will be used by the "Switch to..."
  /// plugins.
  static const String _kFlutterPluginTool = 'FlutterPluginTool';

  /// The name of the Swift test target that will be used to test the Flutter tools in CI.
  static const String _kFlutterToolTests = 'FlutterToolTests';

  /// Generates the Swift package and its sources that will be used to integrate a Flutter app
  /// into a native iOS or macOS app.
  Future<void> generateSwiftPackages({
    required Directory outputDirectory,
    required Directory flutterIntegrationPackage,
    required SwiftPackageSupportedPlatform highestSupportedVersion,
  }) async {
    final Directory nativeToolsPackage = flutterIntegrationPackage.childDirectory(
      _kFlutterNativeTools,
    );
    final Directory scriptsDirectory = outputDirectory.childDirectory(_kScripts);
    ErrorHandlingFileSystem.deleteIfExists(nativeToolsPackage, recursive: true);
    ErrorHandlingFileSystem.deleteIfExists(scriptsDirectory, recursive: true);
    await _generateSourceFiles(
      scriptsDirectory: scriptsDirectory,
      nativeToolsPackage: nativeToolsPackage,
    );

    final integrationPackage = SwiftPackage(
      manifest: flutterIntegrationPackage.childFile('Package.swift'),
      name: _kFlutterIntegrationPackageName,
      platforms: <SwiftPackageSupportedPlatform>[highestSupportedVersion],
      products: [
        SwiftPackageProduct.library(
          name: _kFlutterIntegrationPackageName,
          targets: [_kFlutterIntegrationPackageName],
        ),
      ],
      dependencies: [
        SwiftPackagePackageDependency(name: _kFlutterNativeTools, path: _kFlutterNativeTools),
        SwiftPackagePackageDependency(name: kPluginSwiftPackageName, path: kPluginSwiftPackageName),
      ],
      targets: [
        SwiftPackageTarget.defaultTarget(
          name: _kFlutterIntegrationPackageName,
          dependencies: [
            SwiftPackageTargetDependency.product(
              name: kPluginSwiftPackageName,
              packageName: kPluginSwiftPackageName,
            ),
          ],
        ),
      ],
      templateRenderer: _utils.templateRenderer,
    );

    integrationPackage.createSwiftPackage();

    final toolsPackage = SwiftPackage(
      manifest: nativeToolsPackage.childFile('Package.swift'),
      name: _kFlutterNativeTools,
      platforms: <SwiftPackageSupportedPlatform>[],
      products: [_pluginTool.product, _assembleTool.product, _prebuildTool.product],
      dependencies: [],
      targets: [
        SwiftPackageTarget.defaultTarget(name: _kFlutterToolHelper),
        _assembleTool.target,
        _prebuildTool.target,
        ..._pluginTool.targets,
        if (_generateTests) _testTarget,
      ],
      templateRenderer: _utils.templateRenderer,
    );

    toolsPackage.createSwiftPackage();
  }

  /// Copies files from the template to the output directory.
  Future<void> _generateSourceFiles({
    required Directory scriptsDirectory,
    required Directory nativeToolsPackage,
  }) async {
    await _generateScripts(scriptsDirectory);
    await _generateToolsSources(nativeToolsPackage.childDirectory(_kSources));
    await _generatePluginsSources(
      pluginsDirectory: nativeToolsPackage.childDirectory(_kSwiftPlugins),
    );
    await _generateTestSources(nativeToolsPackage.childDirectory(_kTests));
  }

  /// Generates bash scripts and xcfilelists to be used for integrating SwiftPM into the
  /// [scriptsDirectory].
  Future<void> _generateScripts(Directory scriptsDirectory) async {
    ErrorHandlingFileSystem.deleteIfExists(scriptsDirectory, recursive: true);
    final Template scriptsTemplate = await Template.fromName(
      _utils.fileSystem.path.join('add_to_app', 'darwin', _kScripts),
      fileSystem: _utils.fileSystem,
      templateManifest: null,
      logger: _utils.logger,
      templateRenderer: _utils.templateRenderer,
    );
    scriptsTemplate.render(scriptsDirectory, <String, Object>{
      'flutterFrameworkName': _targetPlatform.binaryName,
      'infoPlistPath': _targetPlatform == FlutterDarwinPlatform.macos
          ? 'Versions/A/Resources/Info.plist'
          : 'Info.plist',
    }, printStatusWhenWriting: false);
  }

  /// Generate source files for Swift package executable tools to be used for integrating SwiftPM
  /// into the [sourcesDirectory].
  Future<void> _generateToolsSources(Directory sourcesDirectory) async {
    final Template toolsTemplate = await Template.fromName(
      _utils.fileSystem.path.join('add_to_app', 'darwin', _kTools),
      fileSystem: _utils.fileSystem,
      templateManifest: null,
      logger: _utils.logger,
      templateRenderer: _utils.templateRenderer,
    );
    toolsTemplate.render(sourcesDirectory, <String, Object>{}, printStatusWhenWriting: false);
  }

  /// Generate source files for Swift package plugins to be used for integrating SwiftPM into the
  /// [pluginsDirectory].
  Future<void> _generatePluginsSources({required Directory pluginsDirectory}) async {
    // Copy swift plugins to be used for integrating SwiftPM into an native project.
    final Template pluginsTemplate = await Template.fromName(
      _utils.fileSystem.path.join('add_to_app', 'darwin', 'Plugins'),
      fileSystem: _utils.fileSystem,
      templateManifest: null,
      logger: _utils.logger,
      templateRenderer: _utils.templateRenderer,
    );

    for (final BuildMode mode in BuildSwiftPackage.availableBuildModes) {
      final Directory pluginsModeDirectory = pluginsDirectory.childDirectory(mode.uppercaseName);
      pluginsTemplate.render(pluginsModeDirectory, <String, Object>{
        'buildMode': mode.uppercaseName,
      }, printStatusWhenWriting: false);
    }
  }

  /// Generate tests for the Swift package integration tools and plugins if [_generateTests] is true.
  Future<void> _generateTestSources(Directory testDirectory) async {
    ErrorHandlingFileSystem.deleteIfExists(testDirectory, recursive: true);
    if (_generateTests) {
      final Template testsTemplate = await Template.fromName(
        _utils.fileSystem.path.join('add_to_app', 'darwin', _kTests),
        fileSystem: _utils.fileSystem,
        templateManifest: null,
        logger: _utils.logger,
        templateRenderer: _utils.templateRenderer,
      );
      testsTemplate.render(testDirectory, <String, Object>{}, printStatusWhenWriting: false);
    }
  }

  ({SwiftPackageProduct product, List<SwiftPackageTarget> targets}) get _pluginTool {
    final product = SwiftPackageProduct.plugin(
      name: 'FlutterBuildModePlugin',
      targets: BuildSwiftPackage.availableBuildModes
          .map((mode) => 'Switch to ${mode.uppercaseName} Mode')
          .toList(),
    );
    final targets = <SwiftPackageTarget>[
      SwiftPackageTarget.executableTarget(
        name: _kFlutterPluginTool,
        dependencies: [SwiftPackageTargetDependency.target(name: _kFlutterToolHelper)],
      ),
      for (final mode in BuildSwiftPackage.availableBuildModes)
        SwiftPackageTarget.pluginTarget(
          name: 'Switch to ${mode.uppercaseName} Mode',
          dependencies: <SwiftPackageTargetDependency>[
            SwiftPackageTargetDependency.target(name: _kFlutterPluginTool),
          ],
          path: '$_kSwiftPlugins/${mode.uppercaseName}',
          commandCapability: SwiftPackageCommandCapability(
            verb: 'switch-to-${mode.cliName}',
            description: 'Updates package to use the ${mode.uppercaseName} mode Flutter framework',
          ),
        ),
    ];
    return (product: product, targets: targets);
  }

  ({SwiftPackageProduct product, SwiftPackageTarget target}) get _assembleTool {
    final product = SwiftPackageProduct.executable(
      name: 'flutter-assemble-tool',
      targets: [_kFlutterAssembleTool],
    );
    final target = SwiftPackageTarget.executableTarget(
      name: _kFlutterAssembleTool,
      dependencies: [SwiftPackageTargetDependency.target(name: _kFlutterToolHelper)],
    );
    return (product: product, target: target);
  }

  ({SwiftPackageProduct product, SwiftPackageTarget target}) get _prebuildTool {
    final product = SwiftPackageProduct.executable(
      name: 'flutter-prebuild-tool',
      targets: [_kFlutterPrebuildTool],
    );
    final target = SwiftPackageTarget.executableTarget(
      name: _kFlutterPrebuildTool,
      dependencies: [SwiftPackageTargetDependency.target(name: _kFlutterToolHelper)],
    );
    return (product: product, target: target);
  }

  SwiftPackageTarget get _testTarget => SwiftPackageTarget.testTarget(
    name: _kFlutterToolTests,
    dependencies: [
      SwiftPackageTargetDependency.target(name: _kFlutterPluginTool),
      SwiftPackageTargetDependency.target(name: _kFlutterToolHelper),
      SwiftPackageTargetDependency.target(name: _kFlutterAssembleTool),
    ],
  );
}

/// Create an XCFramework from a list of frameworks.
Future<void> _produceXCFramework({
  required Iterable<Directory> frameworks,
  required String frameworkBinaryName,
  required Directory outputDirectory,
  required ProcessManager processManager,
  required String? codesignIdentity,
  required BuildMode buildMode,
}) async {
  final Directory xcframeworkOutput = outputDirectory.childDirectory(
    '$frameworkBinaryName.xcframework',
  );

  ErrorHandlingFileSystem.deleteIfExists(xcframeworkOutput, recursive: true);
  final xcframeworkCommand = <String>[
    'xcrun',
    'xcodebuild',
    '-create-xcframework',
    for (final Directory framework in frameworks) ...<String>[
      '-framework',
      framework.path,
      // If there is a dSYM for this framework, add it to the XCFramework.
      if (framework.parent
          .childDirectory('$frameworkBinaryName.framework.dSYM')
          .existsSync()) ...<String>[
        '-debug-symbols',
        framework.parent.childDirectory('$frameworkBinaryName.framework.dSYM').path,
      ],
    ],
    '-output',
    xcframeworkOutput.path,
  ];

  final ProcessResult xcframeworkResult = await processManager.run(
    xcframeworkCommand,
    includeParentEnvironment: false,
  );

  if (xcframeworkResult.exitCode != 0) {
    throwToolExit('Unable to create $frameworkBinaryName.xcframework: ${xcframeworkResult.stderr}');
  }
  if (codesignIdentity != null) {
    await DarwinAddToAppCodesigning.codesign(
      codesignIdentity: codesignIdentity,
      artifact: xcframeworkOutput,
      processManager: processManager,
      buildMode: buildMode,
    );
  }
}

/// Generate target dependencies and binary targets from a directory of XCFrameworks.
(List<SwiftPackageTargetDependency>, List<SwiftPackageTarget>) generateDependenciesFromDirectory({
  required Directory xcframeworkDirectory,
  required FileSystem fileSystem,
  required String directoryName,
}) {
  final targetDependencies = <SwiftPackageTargetDependency>[];
  final binaryTargets = <SwiftPackageTarget>[];

  if (xcframeworkDirectory.existsSync()) {
    for (final FileSystemEntity entity in xcframeworkDirectory.listSync()) {
      if (entity is Directory && entity.basename.endsWith('xcframework')) {
        final String frameworkName = fileSystem.path.basenameWithoutExtension(entity.path);
        targetDependencies.add(SwiftPackageTargetDependency.target(name: frameworkName));
        binaryTargets.add(
          SwiftPackageTarget.binaryTarget(
            name: frameworkName,
            relativePath: '$_kFrameworks/$directoryName/${entity.basename}',
          ),
        );
      }
    }
  }
  return (targetDependencies, binaryTargets);
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
    required this.flutterRoot,
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
  final String flutterRoot;
  final FlutterVersion flutterVersion;
  final Logger logger;
  final Platform platform;
  final ProcessManager processManager;
  final FlutterProject project;
  final TemplateRenderer templateRenderer;
  final Xcode xcode;
}
