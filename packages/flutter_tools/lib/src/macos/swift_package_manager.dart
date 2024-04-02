// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../artifacts.dart';
import '../base/common.dart';
import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/template.dart';
import '../base/version.dart';
import '../build_info.dart';
import '../ios/plist_parser.dart';
import '../ios/xcodeproj.dart';
import '../migrations/swift_package_manager_integration_migration.dart';
import '../plugins.dart';
import '../project.dart';
import 'swift_packages.dart';

/// Swift Package Manager is a dependency management solution for iOS and macOS
/// applications.
///
/// See also:
///   * https://www.swift.org/documentation/package-manager/ - documentation on
///     Swift Package Manager.
///   * https://developer.apple.com/documentation/packagedescription/package -
///     documentation on Swift Package Manager manifest file, Package.swift.
class SwiftPackageManager {
  SwiftPackageManager({
    required Artifacts artifacts,
    required FileSystem fileSystem,
    required Logger logger,
    required TemplateRenderer templateRenderer,
    required XcodeProjectInterpreter xcodeProjectInterpreter,
    required PlistParser plistParser,
  })  : _artifacts = artifacts,
        _fileSystem = fileSystem,
        _logger = logger,
        _templateRenderer = templateRenderer,
        _xcodeProjectInterpreter = xcodeProjectInterpreter,
        _plistParser = plistParser;

  final Artifacts _artifacts;
  final FileSystem _fileSystem;
  final TemplateRenderer _templateRenderer;
  final Logger _logger;
  final XcodeProjectInterpreter _xcodeProjectInterpreter;
  final PlistParser _plistParser;

  static const String _defaultFlutterPluginsSwiftPackageName = 'FlutterGeneratedPluginSwiftPackage';

  static final SwiftPackageSupportedPlatform _iosSwiftPackageSupportedPlatform = SwiftPackageSupportedPlatform(
    platform: SwiftPackagePlatform.ios,
    version: Version(12, 0, null),
  );

  static final SwiftPackageSupportedPlatform _macosSwiftPackageSupportedPlatform = SwiftPackageSupportedPlatform(
    platform: SwiftPackagePlatform.macos,
    version: Version(10, 14, null),
  );

  /// Creates a Swift Package called 'FlutterGeneratedPluginSwiftPackage' that
  /// has dependencies on Flutter plugins that are compatible with Swift
  /// Package Manager.
  ///
  /// Also, has a dependency on the Flutter/FlutterMacOS.xcframework and
  /// creates a [Link] to it.
  ///
  /// Also, migrates the app to use Swift Package Manager integration.
  Future<void> generatePluginsSwiftPackage(
    List<Plugin> plugins,
    SupportedPlatform platform,
    XcodeBasedProject project,
  ) async {
    _validatePlatform(platform);

    final (
      List<SwiftPackagePackageDependency> packageDependencies,
      List<SwiftPackageTargetDependency> targetDependencies,
    ) = _setupDependenciesForPlugins(project, plugins, platform);

    // If there aren't any Swift Package plugins and the project hasn't been
    // migrated yet, don't generate a Swift package or migrate the app since
    // it's not needed. If the project has already been migrated, regenerate
    // the Package.swift even if there are no dependencies in case there
    // were dependencies previously.
    if (packageDependencies.isEmpty && !project.flutterPluginSwiftPackageInProjectSettings) {
      return;
    }

    if (packageDependencies.isNotEmpty) {
      _generateFlutterFrameworkPackage(platform, project);
    }

    final List<SwiftPackageTarget> packageTargets = <SwiftPackageTarget>[
      SwiftPackageTarget.defaultTarget(
        name: _defaultFlutterPluginsSwiftPackageName,
        dependencies: targetDependencies,
      ),
    ];

    final SwiftPackage pluginsPackage = SwiftPackage(
      manifest: project.flutterPluginSwiftPackageManifest,
      name: _defaultFlutterPluginsSwiftPackageName,
      platforms: supportedPlatforms(platform),
      products: <SwiftPackageProduct>[
        SwiftPackageProduct(
          name: _defaultFlutterPluginsSwiftPackageName,
          targets: <String>[_defaultFlutterPluginsSwiftPackageName],
        ),
      ],
      dependencies: packageDependencies,
      targets: packageTargets,
      templateRenderer: _templateRenderer,
    );
    pluginsPackage.createSwiftPackage();

    await migrateProject(project, platform);
  }

  /// Plugins must have a dependency on the Flutter framework, but plugins are
  /// not aware where to find the Flutter framework. To handle this, create
  /// symlinks to plugin files except for the Package.swift. Create a copy of
  /// the Package.swift and inject the path to the Flutter framework. Also,
  /// update the minimum iOS and macOS target deployment version in the
  /// Package.swift to the minimum supported by Flutter so plugins don't
  /// support a version lower than Flutter.
  (List<SwiftPackagePackageDependency>, List<SwiftPackageTargetDependency>) _setupDependenciesForPlugins(
    XcodeBasedProject project,
    List<Plugin> plugins,
    SupportedPlatform platform,
  ) {
    final List<SwiftPackagePackageDependency> packageDependencies =
        <SwiftPackagePackageDependency>[];
    final List<SwiftPackageTargetDependency> targetDependencies =
        <SwiftPackageTargetDependency>[];

    final Directory symlinkDirectory = project.ephemeralSwiftPackageDirectory
        .childDirectory('.symlinks');
    ErrorHandlingFileSystem.deleteIfExists(symlinkDirectory, recursive: true);
    final Directory symlinkPluginDirectory = symlinkDirectory
        .childDirectory('plugins');
    symlinkPluginDirectory.createSync(recursive: true);

    for (final Plugin plugin in plugins) {
      final String? pluginSwiftPackageManifestPath = plugin.pluginSwiftPackageManifestPath(
        _fileSystem,
        platform.name,
      );
      final String? platformName = plugin.darwinPluginDirectoryName(platform.name);
      if (plugin.platforms[platform.name] == null ||
          pluginSwiftPackageManifestPath == null ||
          platformName == null ||
          !_fileSystem.file(pluginSwiftPackageManifestPath).existsSync()) {
        continue;
      }

      _createSymlinks(plugin, platformName, symlinkPluginDirectory);

      final File swiftPackageManifest = symlinkPluginDirectory
          .childDirectory(plugin.name)
          .childDirectory(platformName)
          .childDirectory(plugin.name)
          .childFile('Package.swift');

      _updatePluginSwiftPackageManifest(
        project,
        plugin,
        platformName,
        swiftPackageManifest,
      );

      packageDependencies.add(SwiftPackagePackageDependency(
        name: plugin.name,
        path: _fileSystem.path.relative(
          swiftPackageManifest.parent.path,
          from: project.flutterPluginSwiftPackageDirectory.path,
        ),
      ));
      targetDependencies.add(SwiftPackageTargetDependency.product(
        name: plugin.name,
        packageName: plugin.name,
      ));
    }
    return (packageDependencies, targetDependencies);
  }

  void _updatePluginSwiftPackageManifest(
    XcodeBasedProject project,
    Plugin plugin,
    String platformName,
    File swiftPackageManifest,
  ) {
    if (!swiftPackageManifest.existsSync()) {
      throwToolExit('Failed to copy Package.swift for ${plugin.name}.');
    }
    final String manifestContents = swiftPackageManifest.readAsStringSync();

    // Inject the Flutter framework Swift Package path into the copied
    // Package.swift.
    String newContents = _updateFrameworkPackagePath(
      project,
      plugin,
      manifestContents,
    );

    // Update the minimum iOS and macOS supported versions.
    newContents = _updateMinimumSupportedVersions(plugin, newContents);

    swiftPackageManifest.writeAsStringSync(newContents);
  }

  /// Overwrite flutterFrameworkPackagePath in the plugin's copied Package.swift to
  /// the path of the Flutter framework Swift Package. Plugins must have a
  /// dependency on the framework to compile.
  String _updateFrameworkPackagePath(
    XcodeBasedProject project,
    Plugin plugin,
    String manifestContents,
  ) {
    const String flutterFrameworkDependency = '.package(name: "Flutter", path: flutterFrameworkPackagePath)';
    if (!manifestContents.contains(flutterFrameworkDependency)) {
      throwToolExit(
        'Invalid Package.swift for ${plugin.name}. '
        'Missing or altered "flutterFrameworkDependency".',
      );
    }

    return manifestContents.replaceAll(
      flutterFrameworkDependency,
      '.package(name: "Flutter", path: "${project.flutterFrameworkSwiftPackageDirectory.path}")',
    );
  }

  /// Overwrite iosFlutterMinimumVersion and macosFlutterMinimumVersion
  /// in the plugin's copied Package.swift to the minimum supported by Flutter.
  ///
  /// Swift Package Manager emits an error if a dependency isn’t compatible
  /// with the top-level package’s deployment version. The deployment target of
  /// a package’s dependencies must be lower than or equal to the top-level
  /// package’s deployment target version for a particular platform.
  ///
  /// Since plugins have a dependency on the Flutter framework, the deployment
  /// target must always be higher or equal to that of the Flutter framework.
  String _updateMinimumSupportedVersions(
    Plugin plugin,
    String manifestContents,
  ) {
    final RegExp iosVersionPattern = RegExp(
      r'let iosFlutterMinimumVersion = Version\("\d+.\d+.\d+"\)',
    );
    final String iosVersionTarget =
        'let iosFlutterMinimumVersion = Version("${_supportedPlatformVersion(_iosSwiftPackageSupportedPlatform.version)}")';
    if (!manifestContents.contains(iosVersionPattern)) {
      throwToolExit(
        'Invalid Package.swift for ${plugin.name}. '
        'Missing or altered "flutterMinimumIOSVersion".',
      );
    }

    final RegExp macosVersionPattern = RegExp(
      r'let macosFlutterMinimumVersion = Version\("\d+.\d+.\d+"\)',
    );
    final String macosVersionTarget =
        'let macosFlutterMinimumVersion = Version("${_supportedPlatformVersion(_macosSwiftPackageSupportedPlatform.version)}")';
    if (!manifestContents.contains(macosVersionPattern)) {
      throwToolExit(
        'Invalid Package.swift for ${plugin.name}. '
        'Missing or altered "flutterMinimumMacOSVersion".',
      );
    }

    return manifestContents
        .replaceAll(iosVersionPattern, iosVersionTarget)
        .replaceAll(macosVersionPattern, macosVersionTarget);
  }

  /// Return version as three integers separated by periods. This is required
  /// format for Swift.
  String _supportedPlatformVersion(Version version) {
    return '${version.major}.${version.minor}.${version.patch}';
  }

  /// Symlink each [FileSystemEntity] within the plugin, except for the
  /// Package.swift. Create a copy of the Package.swift so that it can be
  /// edited without affecting the source.
  void _createSymlinks(
    Plugin plugin,
    String platformName,
    Directory symlinkDirectory,
  ) {
    final Directory pluginSource = _fileSystem.directory(plugin.path);
    final Directory pluginDestination = symlinkDirectory
        .childDirectory(plugin.name)
        ..createSync();
    final Directory pluginPlatformDestination = pluginDestination
        .childDirectory(platformName)
        ..createSync();
    final Directory pluginSwiftPackageDestination = pluginPlatformDestination
        .childDirectory(plugin.name)
        ..createSync();

    for (final FileSystemEntity pluginEntity in pluginSource.listSync()) {
      if (pluginEntity.basename == pluginPlatformDestination.basename && pluginEntity is Directory) {
        for (final FileSystemEntity platformEntity in pluginEntity.listSync()) {
          if (platformEntity.basename == pluginSwiftPackageDestination.basename && platformEntity is Directory) {
            for (final FileSystemEntity swiftPackageEntity in platformEntity.listSync()) {
              if (swiftPackageEntity.basename == 'Package.swift' && swiftPackageEntity is File) {
                swiftPackageEntity.copySync(
                  _fileSystem.path.join(
                    pluginSwiftPackageDestination.path,
                    'Package.swift',
                  ),
                );
              } else {
                final Link newLink = pluginSwiftPackageDestination
                    .childLink(swiftPackageEntity.basename);
                newLink.createSync(swiftPackageEntity.path);
              }
            }
          } else {
            final Link newLink = pluginPlatformDestination
                .childLink(platformEntity.basename);
            newLink.createSync(platformEntity.path);
          }
        }
      } else {
        final Link newLink = pluginDestination.childLink(pluginEntity.basename);
        newLink.createSync(pluginEntity.path);
      }
    }
  }

  /// Adds Swift Package Manager integration to the Xcode project's project.pbxproj.
  Future<void> migrateProject(
    XcodeBasedProject project,
    SupportedPlatform platform,
  ) async {
    _validatePlatform(platform);
    final SwiftPackageManagerIntegrationMigration migration = SwiftPackageManagerIntegrationMigration(
      project,
      platform,
      xcodeProjectInterpreter: _xcodeProjectInterpreter,
      logger: _logger,
      fileSystem: _fileSystem,
      plistParser: _plistParser,
    );
    await migration.migrate();
  }

  /// Validates the platform is either iOS or macOS, otherwise throw an error.
  static void _validatePlatform(SupportedPlatform platform) {
    if (platform != SupportedPlatform.ios &&
        platform != SupportedPlatform.macos) {
      throwToolExit(
        'The platform ${platform.name} is not compatible with Swift Package Manager. '
        'Only iOS and macOS is allowed.',
      );
    }
  }

  List<SwiftPackageSupportedPlatform> supportedPlatforms(
    SupportedPlatform platform,
  ) {
    return <SwiftPackageSupportedPlatform>[
      if (platform == SupportedPlatform.ios)
        _iosSwiftPackageSupportedPlatform,
      if (platform == SupportedPlatform.macos)
        _macosSwiftPackageSupportedPlatform,
    ];
  }

  (SwiftPackagePackageDependency, SwiftPackageTargetDependency) _generateFlutterFrameworkPackage(
    SupportedPlatform platform,
    XcodeBasedProject project,
  ) {
    final String flutterFramework = platform == SupportedPlatform.ios
        ? 'Flutter'
        : 'FlutterMacOS';
    final SwiftPackageTarget frameworkTarget = SwiftPackageTarget.binaryTarget(
      name: flutterFramework,
      relativePath: '$flutterFramework.xcframework',
    );
    final SwiftPackage frameworkPackage = SwiftPackage(
      manifest: project.flutterFrameworkSwiftPackageManifest,
      name: 'Flutter',
      platforms: supportedPlatforms(platform),
      products: <SwiftPackageProduct>[
        SwiftPackageProduct(
          name: 'Flutter',
          targets: <String>[flutterFramework],
        ),
      ],
      dependencies: <SwiftPackagePackageDependency>[],
      targets: <SwiftPackageTarget>[frameworkTarget],
      templateRenderer: _templateRenderer,
    );
    frameworkPackage.createSwiftPackage();

    final SwiftPackagePackageDependency dependency = SwiftPackagePackageDependency(
      name: 'Flutter',
      path: project.flutterFrameworkSwiftPackageDirectory.path,
    );

    final SwiftPackageTargetDependency target = SwiftPackageTargetDependency.product(
      name: 'Flutter',
      packageName: 'Flutter',
    );

    // Setup the framework symlink so xcodebuild commands like -showBuildSettings
    // will still work. The BuildMode is not known yet, so set to release for
    // now. The correct framework will be symlinked when the project is built.
    linkFlutterFramework(
      platform,
      project,
      BuildMode.release,
      artifacts: _artifacts,
      fileSystem: _fileSystem,
      logger: _logger,
    );

    return (dependency, target);
  }

  /// Create a [Link] in the [flutterPackageDirectory] to the
  /// [Artifact.flutterXcframework] / [Artifact.flutterMacOSXcframework]. If the
  /// link already exists, update it if needed.
  static void linkFlutterFramework(
    SupportedPlatform platform,
    XcodeBasedProject project,
    BuildMode buildMode, {
    required Artifacts artifacts,
    required FileSystem fileSystem,
    required Logger logger,
  }) {
    _validatePlatform(platform);
    final String xcframeworkName = platform == SupportedPlatform.macos
        ? 'FlutterMacOS.xcframework'
        : 'Flutter.xcframework';
    if (!project.flutterFrameworkSwiftPackageDirectory.existsSync()) {
      // This can happen when Swift Package Manager is enabled, but the project
      // hasn't been migrated yet since it doesn't have any Swift Package
      // Manager plugin dependencies.
      logger.printTrace(
          'Flutter Swift Package does not exist, skipping adding link to $xcframeworkName.');
      return;
    }

    String engineFlutterFrameworkArtifactPath;
    if (platform == SupportedPlatform.macos) {
      engineFlutterFrameworkArtifactPath = artifacts.getArtifactPath(
        Artifact.flutterMacOSXcframework,
        platform: TargetPlatform.darwin,
        mode: buildMode,
      );
    } else {
      engineFlutterFrameworkArtifactPath = artifacts.getArtifactPath(
        Artifact.flutterXcframework,
        platform: TargetPlatform.ios,
        mode: buildMode,
      );
    }
    final Link frameworkSymlink = project.flutterFrameworkSwiftPackageDirectory
        .childLink(xcframeworkName);
    if (!frameworkSymlink.existsSync()) {
      frameworkSymlink.createSync(engineFlutterFrameworkArtifactPath);
    } else if (frameworkSymlink.targetSync() != engineFlutterFrameworkArtifactPath) {
      frameworkSymlink.updateSync(engineFlutterFrameworkArtifactPath);
    }
  }

  /// If the project's IPHONEOS_DEPLOYMENT_TARGET/MACOSX_DEPLOYMENT_TARGET is
  /// higher than the FlutterGeneratedPluginSwiftPackage's default
  /// SupportedPlatform, increase the SupportedPlatform to match the project's
  /// deployment target.
  ///
  /// This is done for the use case of a plugin requiring a higher iOS/macOS
  /// version than a project's default. To still be able to use the plugin, the
  /// user can increase the Xcode project's iOS/macOS deployment target. However,
  /// if FlutterGeneratedPluginSwiftPackage still supports a lower version, it
  /// will fail to build. So FlutterGeneratedPluginSwiftPackage must be updated,
  /// as well.
  static void updateMinimumDeployment({
    required XcodeBasedProject project,
    required SupportedPlatform platform,
    required String deploymentTarget,
  }) {
    final Version? projectDeploymentTargetVersion = Version.parse(deploymentTarget);
    final SwiftPackageSupportedPlatform defaultPlatform;
    final SwiftPackagePlatform packagePlatform;
    if (platform == SupportedPlatform.ios) {
      defaultPlatform = _iosSwiftPackageSupportedPlatform;
      packagePlatform = SwiftPackagePlatform.ios;
    } else {
      defaultPlatform = _macosSwiftPackageSupportedPlatform;
      packagePlatform = SwiftPackagePlatform.macos;
    }

    if (projectDeploymentTargetVersion == null ||
        projectDeploymentTargetVersion <= defaultPlatform.version ||
        !project.flutterPluginSwiftPackageManifest.existsSync()) {
      return;
    }

    final String manifestContents = project.flutterPluginSwiftPackageManifest.readAsStringSync();
    final String oldSupportedPlatform = defaultPlatform.format();
    final String newSupportedPlatform = SwiftPackageSupportedPlatform(
      platform: packagePlatform,
      version: projectDeploymentTargetVersion,
    ).format();

    project.flutterPluginSwiftPackageManifest.writeAsStringSync(
      manifestContents.replaceFirst(oldSupportedPlatform, newSupportedPlatform),
    );
  }
}
