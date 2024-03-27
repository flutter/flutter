// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/template.dart';
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

  final SwiftPackageSupportedPlatform _iosSwiftPackageSupportedPlatform = SwiftPackageSupportedPlatform(
    platform: SwiftPackagePlatform.ios,
    version: '12.0',
  );

  final SwiftPackageSupportedPlatform _macosSwiftPackageSupportedPlatform = SwiftPackageSupportedPlatform(
    platform: SwiftPackagePlatform.macos,
    version: '10.14',
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
      List<SwiftPackageTargetDependency> targetDependencies
    ) = _dependenciesForPlugins(plugins, platform);

    // If there aren't any Swift Package plugins and the project hasn't been
    // migrated yet, don't generate a Swift package or migrate the app since
    // it's not needed. If the project has already been migrated, regenerate
    // the Package.swift even if there are no dependencies in case there
    // were dependencies previously.
    if (packageDependencies.isEmpty && !project.flutterPluginSwiftPackageInProjectSettings) {
      return;
    }

    SwiftPackageTarget? frameworkTarget;
    if (packageDependencies.isNotEmpty) {
      final String flutterFramework = platform == SupportedPlatform.ios
        ? 'Flutter'
        : 'FlutterMacOS';
      frameworkTarget = SwiftPackageTarget.binaryTarget(
        name: flutterFramework,
        relativePath: '$flutterFramework.xcframework',
      );
      final SwiftPackage frameworkPackage = SwiftPackage(
        manifest: project.flutterFrameworkSwiftPackageManifest,
        name: 'FlutterFramework',
        platforms: <SwiftPackageSupportedPlatform>[
          if (platform == SupportedPlatform.ios)
            _iosSwiftPackageSupportedPlatform,
          if (platform == SupportedPlatform.macos)
            _macosSwiftPackageSupportedPlatform,
        ],
        products: <SwiftPackageProduct>[
          SwiftPackageProduct(
            name: 'FlutterFramework',
            targets: <String>[flutterFramework],
          ),
        ],
        dependencies: <SwiftPackagePackageDependency>[],
        targets: <SwiftPackageTarget>[frameworkTarget],
        templateRenderer: _templateRenderer,
      );
      frameworkPackage.createSwiftPackage();
      packageDependencies.insert(
        0,
        SwiftPackagePackageDependency(
          name: 'FlutterFramework',
          path: project.flutterFrameworkSwiftPackageDirectory.path,
        ),
      );
      targetDependencies.insert(
        0,
        SwiftPackageTargetDependency.product(
          name: 'FlutterFramework',
          packageName: 'FlutterFramework',
        ),
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
      platforms: <SwiftPackageSupportedPlatform>[
        if (platform == SupportedPlatform.ios)
          _iosSwiftPackageSupportedPlatform,
        if (platform == SupportedPlatform.macos)
          _macosSwiftPackageSupportedPlatform,
      ],
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

  (List<SwiftPackagePackageDependency>, List<SwiftPackageTargetDependency>) _dependenciesForPlugins(
    List<Plugin> plugins,
    SupportedPlatform platform,
  ) {
    final List<SwiftPackagePackageDependency> packageDependencies =
        <SwiftPackagePackageDependency>[];
    final List<SwiftPackageTargetDependency> targetDependencies =
        <SwiftPackageTargetDependency>[];

    for (final Plugin plugin in plugins) {
      final String? pluginSwiftPackageManifestPath = plugin.pluginSwiftPackageManifestPath(
        _fileSystem,
        platform.name,
      );
      if (plugin.platforms[platform.name] == null ||
          pluginSwiftPackageManifestPath == null ||
          !_fileSystem.file(pluginSwiftPackageManifestPath).existsSync()) {
        continue;
      }

      packageDependencies.add(SwiftPackagePackageDependency(
        name: plugin.name,
        path: _fileSystem.file(pluginSwiftPackageManifestPath).parent.path,
      ));
      targetDependencies.add(SwiftPackageTargetDependency.product(
        name: plugin.name,
        packageName: plugin.name,
      ));
    }
    return (packageDependencies, targetDependencies);
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
      throwToolExit('The platform ${platform.name} is not compatible with Swift Package Manager. Only iOS and macOS is allowed.');
    }
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
      logger.printTrace('FlutterFramework Swift Package does not exist, skipping adding link to $xcframeworkName.');
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
}
