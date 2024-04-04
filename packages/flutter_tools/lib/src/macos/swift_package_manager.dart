// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/template.dart';
import '../base/version.dart';
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
    required FileSystem fileSystem,
    required TemplateRenderer templateRenderer,
  })  : _fileSystem = fileSystem,
        _templateRenderer = templateRenderer;

  final FileSystem _fileSystem;
  final TemplateRenderer _templateRenderer;

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
