// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:unified_analytics/unified_analytics.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../darwin/darwin.dart';
import '../features.dart';
import '../plugins.dart';
import '../project.dart';
import 'cocoapods.dart';
import 'swift_package_manager.dart';

/// Flutter has two dependency management solutions for iOS and macOS
/// applications: CocoaPods and Swift Package Manager. They may be used
/// individually or together. This class handles setting up required files and
/// project settings for the dependency manager(s) being used.
class DarwinDependencyManagement {
  DarwinDependencyManagement({
    required FlutterProject project,
    required List<Plugin> plugins,
    required CocoaPods cocoapods,
    required SwiftPackageManager swiftPackageManager,
    required FileSystem fileSystem,
    required FeatureFlags featureFlags,
    required Logger logger,
    required Analytics analytics,
    required Platform platform,
  }) : _project = project,
       _plugins = plugins,
       _cocoapods = cocoapods,
       _swiftPackageManager = swiftPackageManager,
       _fileSystem = fileSystem,
       _featureFlags = featureFlags,
       _logger = logger,
       _analytics = analytics,
       _hostPlatform = platform;

  final FlutterProject _project;
  final List<Plugin> _plugins;
  final CocoaPods _cocoapods;
  final SwiftPackageManager _swiftPackageManager;
  final FileSystem _fileSystem;
  final FeatureFlags _featureFlags;
  final Logger _logger;
  final Analytics _analytics;
  final Platform _hostPlatform;

  /// Generates/updates required files and project settings for Darwin
  /// Dependency Managers (CocoaPods and Swift Package Manager). Projects may
  /// use only CocoaPods (if no SPM compatible dependencies or SPM has been
  /// disabled), only Swift Package Manager (if no CocoaPod dependencies), or
  /// both. This only generates files for the manager(s) being used.
  ///
  /// CocoaPods requires a Podfile and certain values in the Flutter xcconfig
  /// files.
  ///
  /// Swift Package Manager requires a generated Package.swift and certain
  /// settings in the Xcode project's project.pbxproj and xcscheme (done later
  /// before build).
  Future<void> setUp({required FlutterDarwinPlatform platform}) async {
    final XcodeBasedProject xcodeProject = platform.xcodeProject(_project);
    if (xcodeProject.usesSwiftPackageManager) {
      await _swiftPackageManager.generatePluginsSwiftPackage(_plugins, platform, xcodeProject);
    } else if (xcodeProject.flutterPluginSwiftPackageInProjectSettings) {
      // If Swift Package Manager is not enabled but the project is already
      // integrated for Swift Package Manager, pass no plugins to the generator.
      // This will still generate the required Package.swift, but it will have
      // no dependencies.
      await _swiftPackageManager.generatePluginsSwiftPackage(
        <Plugin>[],
        platform,
        xcodeProject,
        flutterAsADependency: false,
      );
    }

    // Skip updating Podfile if project is a module, since it will use a
    // different module-specific Podfile.
    if (_project.isModule) {
      return;
    }
    final (
      :int totalCount,
      :int swiftPackageCount,
      :int podCount,
    ) = await _evaluatePluginsAndPrintWarnings(
      platform: platform,
      xcodeProject: xcodeProject,
      hostPlatformIsMacOS: _hostPlatform.isMacOS,
    );

    final bool useCocoapods;
    if (xcodeProject.usesSwiftPackageManager) {
      useCocoapods = swiftPackageCount < totalCount;
    } else {
      // When Swift Package Manager is not enabled, set up Podfile if plugins
      // is not empty, regardless of if plugins are CocoaPod compatible. This
      // is done because `processPodsIfNeeded` uses `hasPlugins` to determine
      // whether to run.
      useCocoapods = _plugins.isNotEmpty;
    }

    if (useCocoapods) {
      await _cocoapods.setupPodfile(xcodeProject);
    }
    /// The user may have a custom maintained Podfile that they're running `pod install`
    /// on themselves.
    else if (xcodeProject.podfile.existsSync() && xcodeProject.podfileLock.existsSync()) {
      _cocoapods.addPodsDependencyToFlutterXcconfig(xcodeProject);
    }

    final event = Event.flutterInjectDarwinPlugins(
      platform: platform.name,
      isModule: _project.isModule,
      swiftPackageManagerUsable: xcodeProject.usesSwiftPackageManager,
      swiftPackageManagerFeatureEnabled: _featureFlags.isSwiftPackageManagerEnabled,
      // TODO(matanlurey): Remove from unified_analytics and then remove this key.
      projectDisabledSwiftPackageManager: !_featureFlags.isSwiftPackageManagerEnabled,
      projectHasSwiftPackageManagerIntegration:
          xcodeProject.flutterPluginSwiftPackageInProjectSettings,
      pluginCount: totalCount,
      swiftPackageCount: swiftPackageCount,
      podCount: podCount,
    );

    _analytics.send(event);

    // Validate Swift Package Manager support for plugin example apps and print warning if it doesn't support Swift Package Manager.
    _validatePluginSwiftPackageManagerSupport(platform: platform);
  }

  /// Returns count of total number of plugins, number of Swift Package Manager compatible plugins,
  /// and number of CocoaPods compatible plugins. A plugin can be both Swift Package Manager and
  /// CocoaPods compatible.
  ///
  /// If [hostPlatformIsMacOS], prints warnings when using a plugin incompatible with the available
  /// Darwin Dependency Manager (Swift Package Manager or CocoaPods).
  ///
  /// If [hostPlatformIsMacOS], prints message prompting the user to deintegrate CocoaPods if
  /// using all Swift Package plugins.
  Future<({int totalCount, int swiftPackageCount, int podCount})> _evaluatePluginsAndPrintWarnings({
    required FlutterDarwinPlatform platform,
    required XcodeBasedProject xcodeProject,
    required bool hostPlatformIsMacOS,
  }) async {
    var pluginCount = 0;
    var swiftPackageCount = 0;
    var cocoapodCount = 0;
    for (final Plugin plugin in _plugins) {
      if (plugin.platforms[platform.name] == null) {
        continue;
      }
      final String? swiftPackagePath = plugin.pluginSwiftPackageManifestPath(
        _fileSystem,
        platform.name,
      );
      final bool swiftPackageManagerCompatible =
          swiftPackagePath != null && _fileSystem.file(swiftPackagePath).existsSync();

      final String? podspecPath = plugin.pluginPodspecPath(_fileSystem, platform.name);
      final bool cocoaPodsCompatible =
          podspecPath != null && _fileSystem.file(podspecPath).existsSync();

      // If a plugin is missing both a Package.swift and Podspec, it won't be
      // included by either Swift Package Manager or Cocoapods. This can happen
      // when a plugin doesn't have native platform code.
      // For example, image_picker_macos only uses dart code.
      if (!swiftPackageManagerCompatible && !cocoaPodsCompatible) {
        continue;
      }

      pluginCount += 1;
      if (swiftPackageManagerCompatible) {
        swiftPackageCount += 1;
      }
      if (cocoaPodsCompatible) {
        cocoapodCount += 1;
      }

      // If not using Swift Package Manager and plugin does not have podspec
      // but does have a Package.swift, throw an error. Otherwise, it'll error
      // when it builds.
      if (hostPlatformIsMacOS &&
          !xcodeProject.usesSwiftPackageManager &&
          !cocoaPodsCompatible &&
          swiftPackageManagerCompatible) {
        throwToolExit(
          'Plugin ${plugin.name} is only Swift Package Manager compatible. Try '
          'enabling Swift Package Manager by running '
          '"flutter config --enable-swift-package-manager" or remove the '
          'plugin as a dependency.',
        );
      }
    }

    // Only show warnings to remove CocoaPods if the project is using Swift
    // Package Manager, has already been migrated to have SPM integration, and
    // all plugins are Swift Packages.
    if (xcodeProject.usesSwiftPackageManager &&
        xcodeProject.flutterPluginSwiftPackageInProjectSettings &&
        pluginCount == swiftPackageCount &&
        swiftPackageCount != 0) {
      final bool podfileExists = xcodeProject.podfile.existsSync();
      if (podfileExists) {
        // If all plugins are Swift Packages and the Podfile matches the
        // default template, recommend pod deintegration.
        final File podfileTemplate = await _cocoapods.getPodfileTemplate(
          xcodeProject,
          xcodeProject.xcodeProject,
        );

        final configWarning =
            '${_podIncludeInConfigWarning(xcodeProject, 'Debug')}'
            '${_podIncludeInConfigWarning(xcodeProject, 'Release')}';

        if (hostPlatformIsMacOS &&
            xcodeProject.podfile.readAsStringSync() == podfileTemplate.readAsStringSync()) {
          _logger.printWarning(
            'All plugins found for ${platform.name} are Swift Packages, but your '
            'project still has CocoaPods integration. To remove CocoaPods '
            'integration, complete the following steps:\n'
            '  * In the ${platform.name}/ directory run "pod deintegrate"\n'
            '  * Also in the ${platform.name}/ directory, delete the Podfile\n'
            '$configWarning\n'
            "Removing CocoaPods integration will improve the project's build time.",
          );
        } else if (hostPlatformIsMacOS) {
          // If all plugins are Swift Packages, but the Podfile has custom logic,
          // recommend migrating manually.
          _logger.printWarning(
            'All plugins found for ${platform.name} are Swift Packages, but your '
            'project still has CocoaPods integration. Your project uses a '
            'non-standard Podfile and will need to be migrated to Swift Package '
            'Manager manually. Some steps you may need to complete include:\n'
            '  * In the ${platform.name}/ directory run "pod deintegrate"\n'
            '  * Transition any Pod dependencies to Swift Package equivalents. '
            'See https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app\n'
            '  * Transition any custom logic\n'
            '$configWarning\n'
            "Removing CocoaPods integration will improve the project's build time.",
          );
        }
      }
    }

    return (totalCount: pluginCount, swiftPackageCount: swiftPackageCount, podCount: cocoapodCount);
  }

  String _podIncludeInConfigWarning(XcodeBasedProject xcodeProject, String mode) {
    final File xcconfigFile = xcodeProject.xcodeConfigFor(mode);
    final bool configIncludesPods = _cocoapods.xcconfigIncludesPods(xcconfigFile);
    if (configIncludesPods) {
      return '  * Remove the include to '
          '"${_cocoapods.includePodsXcconfig(mode)}" in your '
          '${xcconfigFile.parent.parent.basename}/${xcconfigFile.parent.basename}/${xcconfigFile.basename}\n';
    }

    return '';
  }

  /// Tracks which plugin/platform combinations have already been warned about
  /// during this session to avoid duplicate warnings.
  static final Set<String> _spmValidationWarningsShown = <String>{};

  /// Validates Swift Package Manager support for plugins in the current project.
  ///
  /// Checks if the current project is a plugin example app and validates
  /// the parent plugin's Swift Package Manager compatibility:
  /// 1. If the plugin has a podspec but no Package.swift, prompts the user to
  ///    add SPM support.
  /// 2. If the plugin has a Package.swift, validates that it has a dependency
  ///    on FlutterFramework.
  ///
  /// Warnings are printed to inform plugin authors about SPM compatibility issues.
  void _validatePluginSwiftPackageManagerSupport({required FlutterDarwinPlatform platform}) {
    final Directory projectDir = _project.directory;
    if (!projectDir.path.endsWith('example')) {
      return;
    }

    final Directory parentDir = projectDir.parent;
    final File parentPubspec = parentDir.childFile('pubspec.yaml');
    if (!parentPubspec.existsSync()) {
      return;
    }

    final FlutterProject parentProject;
    try {
      parentProject = FlutterProject.fromDirectory(parentDir);
    } on Exception catch (e) {
      _logger.printTrace('Failed to parse parent project for SPM validation: $e');
      return;
    }

    if (!parentProject.isPlugin) {
      return;
    }

    final Plugin? parentPlugin = _plugins
        .where((Plugin p) => p.name == parentProject.manifest.appName)
        .firstOrNull;

    if (parentPlugin == null) {
      return;
    }

    final cacheKey = '${parentPlugin.name}:${platform.name}';
    if (_spmValidationWarningsShown.contains(cacheKey)) {
      return;
    }

    final SwiftPackageManagerPluginValidationResult result =
        validatePluginSwiftPackageManagerSupport(
          parentPlugin,
          fileSystem: _fileSystem,
          platform: platform.name,
        );

    if (result.validationMessages.isNotEmpty) {
      _spmValidationWarningsShown.add(cacheKey);
      result.validationMessages.forEach(_logger.printWarning);
    }
  }

  /// Validates a plugin's Swift Package Manager compatibility for a given [platform].
  ///
  /// This function checks:
  /// 1. If the plugin has a podspec but no Package.swift, it means the plugin
  ///    needs to add Swift Package Manager support.
  /// 2. If the plugin has a Package.swift, it validates that there's a dependency
  ///    on FlutterFramework.
  static SwiftPackageManagerPluginValidationResult validatePluginSwiftPackageManagerSupport(
    Plugin plugin, {
    required FileSystem fileSystem,
    required String platform,
  }) {
    final messages = <String>[];

    final String? podspecPath = plugin.pluginPodspecPath(fileSystem, platform);
    final String? packageSwiftPath = plugin.pluginSwiftPackageManifestPath(fileSystem, platform);

    final bool hasPodspec = podspecPath != null && fileSystem.file(podspecPath).existsSync();

    final bool hasPackageSwift =
        packageSwiftPath != null && fileSystem.file(packageSwiftPath).existsSync();

    var hasFlutterFrameworkDependency = false;

    if (hasPodspec && !hasPackageSwift) {
      messages.add(
        'Plugin ${plugin.name} does not have Swift Package Manager support for $platform. '
        'Consider adding Swift Package Manager compatibility to your plugin. '
        'See $kSwiftPackageManagerDocsUrl for more information.',
      );
    } else if (hasPackageSwift) {
      hasFlutterFrameworkDependency = _hasFlutterFrameworkDependency(
        fileSystem.file(packageSwiftPath),
      );
      if (!hasFlutterFrameworkDependency) {
        messages.add(
          'Plugin ${plugin.name} has a Package.swift for $platform but is missing a dependency '
          'on FlutterFramework. Add the following to your Package.swift dependencies:\n'
          '    .package(name: "FlutterFramework", path: "../FlutterFramework")\n'
          'And add FlutterFramework as a target dependency:\n'
          '    .product(name: "FlutterFramework", package: "FlutterFramework")\n'
          'See $kSwiftPackageManagerDocsUrl for more information.',
        );
      }
    }

    return SwiftPackageManagerPluginValidationResult(
      hasPodspec: hasPodspec,
      hasPackageSwift: hasPackageSwift,
      hasFlutterFrameworkDependency: hasFlutterFrameworkDependency,
      validationMessages: messages,
    );
  }

  /// Checks if a Package.swift file contains a dependency on FlutterFramework.
  ///
  /// This looks for common patterns used to declare a FlutterFramework dependency:
  /// - `.package(name: "FlutterFramework", path: "../FlutterFramework")` - package dependency
  /// - `.product(name: "FlutterFramework", package: "FlutterFramework")` - target dependency
  ///
  /// Both patterns must be present (and not commented out) for the plugin to be
  /// fully compatible with Swift Package Manager.
  static bool _hasFlutterFrameworkDependency(File packageSwiftFile) {
    if (!packageSwiftFile.existsSync()) {
      return false;
    }

    try {
      final String contents = packageSwiftFile.readAsStringSync();

      // Remove both single-line (//) and block (/* ... */) comments.
      final String uncommentedContents = contents.replaceAll(RegExp(r'//.*|/\*[\s\S]*?\*/'), '');

      final bool hasPackageDependency = uncommentedContents.contains(
        RegExp(r'\.package\s*\(\s*name\s*:\s*"FlutterFramework"'),
      );
      final bool hasTargetDependency = uncommentedContents.contains(
        RegExp(r'\.product\s*\(\s*name\s*:\s*"FlutterFramework"'),
      );

      return hasPackageDependency && hasTargetDependency;
    } on FileSystemException {
      return false;
    }
  }
}

/// The URL for documentation on adding Swift Package Manager support to a plugin.
const String kSwiftPackageManagerDocsUrl =
    'https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-plugin-authors';

/// The result of validating a plugin's Swift Package Manager compatibility.
class SwiftPackageManagerPluginValidationResult {
  SwiftPackageManagerPluginValidationResult({
    required this.hasPodspec,
    required this.hasPackageSwift,
    required this.hasFlutterFrameworkDependency,
    this.validationMessages = const <String>[],
  });

  final bool hasPodspec;
  final bool hasPackageSwift;
  final bool hasFlutterFrameworkDependency;
  final List<String> validationMessages;

  bool get isFullyCompatible => hasPackageSwift && hasFlutterFrameworkDependency;

  bool get needsSwiftPackageManagerSupport => hasPodspec && !hasPackageSwift;
}
