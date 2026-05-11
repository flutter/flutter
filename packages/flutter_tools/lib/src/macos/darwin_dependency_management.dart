// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:unified_analytics/unified_analytics.dart';

import '../base/common.dart';
import '../base/config.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../darwin/darwin.dart';
import '../features.dart';
import '../flutter_manifest.dart';
import '../ios/xcodeproj.dart';
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
    required CocoaPods? cocoapods,
    required SwiftPackageManager swiftPackageManager,
    required FileSystem fileSystem,
    required FeatureFlags featureFlags,
    required Analytics analytics,
    required XcodeProjectInterpreter? xcodeProjectInterpreter,
    required Config? config,
  }) : _config = config,
       _xcodeProjectInterpreter = xcodeProjectInterpreter,
       _project = project,
       _plugins = plugins,
       _cocoapods = cocoapods,
       _swiftPackageManager = swiftPackageManager,
       _fileSystem = fileSystem,
       _featureFlags = featureFlags,
       _analytics = analytics;

  final FlutterProject _project;
  final List<Plugin> _plugins;
  final CocoaPods? _cocoapods;
  final SwiftPackageManager _swiftPackageManager;
  final FileSystem _fileSystem;
  final FeatureFlags _featureFlags;
  final Analytics _analytics;
  final XcodeProjectInterpreter? _xcodeProjectInterpreter;
  final Config? _config;

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

      // Start the SwiftPM dependency resolution in the background.
      await _xcodeProjectInterpreter?.prefetchSwiftPackages(
        xcodeProject.hostAppRoot.path,
        waitForCompletion: false,
        buildDirectory: _fileSystem.directory(
          platform.buildDirectory(config: _config, fileSystem: _fileSystem),
        ),
      );
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
    final (:int totalCount, :int swiftPackageCount, :int podCount) = await _countPluginsPerManager(
      platform: platform,
      xcodeProject: xcodeProject,
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
      await _cocoapods?.setupPodfile(xcodeProject);
    }
    /// The user may have a custom maintained Podfile that they're running `pod install`
    /// on themselves.
    else if (xcodeProject.podfile.existsSync() && xcodeProject.podfileLock.existsSync()) {
      _cocoapods?.addPodsDependencyToFlutterXcconfig(xcodeProject);
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
  }

  /// Returns count of total number of plugins, number of Swift Package Manager compatible plugins,
  /// and number of CocoaPods compatible plugins. A plugin can be both Swift Package Manager and
  /// CocoaPods compatible.
  Future<({int totalCount, int swiftPackageCount, int podCount})> _countPluginsPerManager({
    required FlutterDarwinPlatform platform,
    required XcodeBasedProject xcodeProject,
  }) async {
    var pluginCount = 0;
    var swiftPackageCount = 0;
    var cocoapodCount = 0;
    for (final Plugin plugin in _plugins) {
      final bool pluginSupportsSwiftPM = plugin.supportSwiftPackageManagerForPlatform(
        _fileSystem,
        platform.name,
      );
      final bool pluginSupportCocoapods = plugin.supportCocoapodsForPlatform(
        _fileSystem,
        platform.name,
      );

      // If a plugin is missing both a Package.swift and Podspec, it won't be
      // included by either Swift Package Manager or Cocoapods. This can happen
      // when a plugin doesn't have native platform code.
      // For example, image_picker_macos only uses dart code.
      if (!pluginSupportsSwiftPM && !pluginSupportCocoapods) {
        continue;
      }
      pluginCount += 1;
      if (pluginSupportsSwiftPM) {
        swiftPackageCount += 1;
      }
      if (pluginSupportCocoapods) {
        cocoapodCount += 1;
      }
    }
    return (totalCount: pluginCount, swiftPackageCount: swiftPackageCount, podCount: cocoapodCount);
  }

  /// Validate that plugins are compatible with the project dependency management set up.
  ///
  /// This includes the following checks:
  ///   - Throws when using a SwiftPM-only plugin but SwiftPM is not enabled
  ///   - Warns when using CocoaPod-only plugins
  ///   - Warns when CocoaPods integration is removable
  ///   - Warns when building a plugin example app that doesn't support SwiftPM
  static Future<void> validatePluginSupport({
    required FlutterDarwinPlatform platform,
    required XcodeBasedProject xcodeProject,
    required List<Plugin> plugins,
    required FileSystem fileSystem,
    required Logger logger,
    required CocoaPods? cocoapods,
  }) async {
    final bool projectUsesSwiftPM =
        xcodeProject.usesSwiftPackageManager &&
        xcodeProject.flutterPluginSwiftPackageInProjectSettings;

    final swiftPackageOnlyPlugins = <String>[];
    final cocoapodOnlyPlugins = <String>[];
    for (final plugin in plugins) {
      final bool pluginSupportsSwiftPM = plugin.supportSwiftPackageManagerForPlatform(
        fileSystem,
        platform.name,
      );
      final bool pluginSupportCocoapods = plugin.supportCocoapodsForPlatform(
        fileSystem,
        platform.name,
      );

      // If a plugin is missing both a Package.swift and Podspec, it won't be
      // included by either Swift Package Manager or Cocoapods. This can happen
      // when a plugin doesn't have native platform code.
      // For example, image_picker_macos only uses dart code.
      if (!pluginSupportsSwiftPM && !pluginSupportCocoapods) {
        continue;
      }
      if (pluginSupportsSwiftPM && !pluginSupportCocoapods) {
        swiftPackageOnlyPlugins.add(plugin.name);
      }
      if (!pluginSupportsSwiftPM && pluginSupportCocoapods) {
        cocoapodOnlyPlugins.add(plugin.name);
      }
    }

    _throwToolExitIfSwiftPMOnlyPluginsExist(
      swiftPackageOnlyPlugins: swiftPackageOnlyPlugins,
      xcodeProject: xcodeProject,
      projectUsesSwiftPM: projectUsesSwiftPM,
    );

    _printCocoapodOnlyPluginsWarning(
      cocoapodOnlyPlugins: cocoapodOnlyPlugins,
      logger: logger,
      platform: platform,
    );

    await _printRemoveCocoapodIntegrationMessage(
      cocoapods: cocoapods,
      cocoapodOnlyPlugins: cocoapodOnlyPlugins,
      logger: logger,
      platform: platform,
      xcodeProject: xcodeProject,
      projectUsesSwiftPM: projectUsesSwiftPM,
    );

    // Prompt plugin author when local plugin does not support SwiftPM
    _validateExampleAppPluginSupportsSwiftPackageManager(
      fileSystem: fileSystem,
      logger: logger,
      platform: platform,
      project: xcodeProject.parent,
      plugins: plugins,
    );
  }

  /// Throw a [ToolExit] if there are plugins that only support SwiftPM but the project does not
  /// use SwiftPM. Otherwise, it'll error later when it builds.
  static void _throwToolExitIfSwiftPMOnlyPluginsExist({
    required List<String> swiftPackageOnlyPlugins,
    required XcodeBasedProject xcodeProject,
    required bool projectUsesSwiftPM,
  }) {
    if (projectUsesSwiftPM || swiftPackageOnlyPlugins.isEmpty) {
      return;
    }
    if (xcodeProject.compatibleWithSwiftPackageManager) {
      throwToolExit(
        'The following plugin(s) are only compatible with Swift Package Manager:\n'
        '  - ${swiftPackageOnlyPlugins.join('\n  - ')}\n\n'
        'Try enabling Swift Package Manager by running '
        '"flutter config --enable-swift-package-manager" or remove the '
        'plugin as a dependency.',
      );
    } else {
      throwToolExit(
        'The following plugin(s) are only compatible with Swift Package Manager:\n'
        '  - ${swiftPackageOnlyPlugins.join('\n  - ')}\n\n'
        'Your project does not currently support Swift Package Manager. To support Swift Package Manager:\n'
        '  - Ensure Xcode 15+ is being used '
        '  - Enable Swift Package Manager feature by running '
        '"flutter config --enable-swift-package-manager"',
      );
    }
  }

  /// Print a warning when there are plugins that don't support SwiftPM and therefore require
  /// CocoaPods.
  static void _printCocoapodOnlyPluginsWarning({
    required List<String> cocoapodOnlyPlugins,
    required Logger logger,
    required FlutterDarwinPlatform platform,
  }) {
    if (cocoapodOnlyPlugins.isEmpty) {
      return;
    }
    logger.printWarning(
      'The following plugins do not support Swift Package Manager for ${platform.name}:\n'
      '  - ${cocoapodOnlyPlugins.join('\n  - ')}\n'
      'This will become an error in a future version of Flutter. Please contact the plugin '
      'maintainers to request Swift Package Manager adoption.',
    );
  }

  /// Print a message recommending removing CocoaPod integration when all plugins support SwiftPM.
  static Future<void> _printRemoveCocoapodIntegrationMessage({
    required CocoaPods? cocoapods,
    required XcodeBasedProject xcodeProject,
    required Logger logger,
    required FlutterDarwinPlatform platform,
    required List<String> cocoapodOnlyPlugins,
    required bool projectUsesSwiftPM,
  }) async {
    if (!projectUsesSwiftPM || cocoapodOnlyPlugins.isNotEmpty || cocoapods == null) {
      return;
    }
    final bool podfileExists = xcodeProject.podfile.existsSync();
    if (!podfileExists) {
      return;
    }
    final configWarning =
        '${_podIncludeInConfigWarning(cocoapods: cocoapods, xcodeProject: xcodeProject, mode: 'Debug')}'
        '${_podIncludeInConfigWarning(cocoapods: cocoapods, xcodeProject: xcodeProject, mode: 'Release')}';

    if (await _podfileMatchesTemplate(cocoapods: cocoapods, xcodeProject: xcodeProject)) {
      logger.printWarning(
        'All plugins found for ${platform.name} are Swift Packages, but your '
        'project still has CocoaPods integration. To remove CocoaPods '
        'integration, complete the following steps:\n'
        '  * In the ${platform.name}/ directory run "pod deintegrate"\n'
        '  * Also in the ${platform.name}/ directory, delete the Podfile\n'
        '$configWarning\n'
        "Removing CocoaPods integration will improve the project's build time.",
      );
    } else {
      // If all plugins are Swift Packages, but the Podfile has custom logic,
      // recommend migrating manually.
      logger.printWarning(
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

  /// Return `true` if the Podfile matches the create template, meaning it hasn't been modified.
  static Future<bool> _podfileMatchesTemplate({
    required CocoaPods cocoapods,
    required XcodeBasedProject xcodeProject,
  }) async {
    // If all plugins are Swift Packages and the Podfile matches the
    // default template, recommend pod deintegration.
    final File podfileTemplate = await cocoapods.getPodfileTemplate(
      xcodeProject,
      xcodeProject.xcodeProject,
    );

    return xcodeProject.podfile.readAsStringSync() == podfileTemplate.readAsStringSync();
  }

  /// Returns a step to remove the CocoaPods `#include` from the xcconfig file for the given mode.
  /// If the xcconfig file does not include the CocoaPods `#include`, it returns an empty string.
  static String _podIncludeInConfigWarning({
    required CocoaPods cocoapods,
    required XcodeBasedProject xcodeProject,
    required String mode,
  }) {
    final File xcconfigFile = xcodeProject.xcodeConfigFor(mode);
    final bool configIncludesPods = cocoapods.xcconfigIncludesPods(xcconfigFile);
    if (configIncludesPods) {
      return '  * Remove the include to '
          '"${cocoapods.includePodsXcconfig(mode)}" in your '
          '${xcconfigFile.parent.parent.basename}/${xcconfigFile.parent.basename}/${xcconfigFile.basename}\n';
    }

    return '';
  }

  /// Validates that a plugin supports Swift Package Manager when building
  /// its example app.
  ///
  /// If the current project is a plugin's example app, this checks whether
  /// the parent plugin has SwiftPM support:
  /// 1. If the plugin has a podspec but no Package.swift, prompts the author
  ///    to add SwiftPM support.
  /// 2. If the plugin has a Package.swift, validates that it contains a
  ///    dependency on FlutterFramework.
  static void _validateExampleAppPluginSupportsSwiftPackageManager({
    required FlutterDarwinPlatform platform,
    required FileSystem fileSystem,
    required Logger logger,
    required FlutterProject project,
    required List<Plugin> plugins,
  }) {
    final Plugin? parentPlugin = _loadPluginFromExampleProject(
      fileSystem: fileSystem,
      logger: logger,
      project: project,
      plugins: plugins,
    );
    if (parentPlugin == null) {
      return;
    }

    final String? warning = validatePluginSupportsSwiftPackageManager(
      parentPlugin,
      fileSystem: fileSystem,
      platform: platform.name,
    );

    if (warning != null) {
      logger.printWarning(warning);
    }
  }

  /// Returns the parent plugin if the current project is a plugin's example app,
  /// or `null` otherwise.
  static Plugin? _loadPluginFromExampleProject({
    required FileSystem fileSystem,
    required Logger logger,
    required FlutterProject project,
    required List<Plugin> plugins,
  }) {
    final Directory projectDir = project.directory;
    if (!projectDir.path.endsWith('example')) {
      return null;
    }

    final Directory parentDir = projectDir.parent;
    final File parentPubspec = parentDir.childFile('pubspec.yaml');
    if (!parentPubspec.existsSync()) {
      return null;
    }

    final FlutterManifest? parentManifest;
    try {
      parentManifest = FlutterManifest.createFromPath(
        parentPubspec.path,
        fileSystem: fileSystem,
        logger: logger,
      );
    } on Exception catch (e) {
      logger.printTrace('Failed to parse parent pubspec for SwiftPM validation: $e');
      return null;
    }

    if (parentManifest == null || !parentManifest.isPlugin) {
      return null;
    }

    final String pluginName = parentManifest.appName;
    return plugins.where((Plugin p) => p.name == pluginName).firstOrNull;
  }

  /// Validates a plugin's Swift Package Manager compatibility for a given [platform].
  ///
  /// Returns a warning message if the plugin has SwiftPM compatibility issues,
  /// or `null` if the plugin is compatible or does not apply.
  ///
  /// This checks:
  /// 1. If the plugin has a podspec but no Package.swift, it returns a message
  ///    prompting the author to add SwiftPM support.
  /// 2. If the plugin has a Package.swift, it validates that it contains the
  ///    string "FlutterFramework".
  static String? validatePluginSupportsSwiftPackageManager(
    Plugin plugin, {
    required FileSystem fileSystem,
    required String platform,
  }) {
    final String? podspecPath = plugin.pluginPodspecPath(fileSystem, platform);
    final String? packageSwiftPath = plugin.pluginSwiftPackageManifestPath(fileSystem, platform);

    final bool hasPodspec = podspecPath != null && fileSystem.file(podspecPath).existsSync();

    final bool hasPackageSwift =
        packageSwiftPath != null && fileSystem.file(packageSwiftPath).existsSync();

    if (hasPodspec && !hasPackageSwift) {
      return 'Plugin ${plugin.name} does not have Swift Package Manager support for $platform. '
          'Consider adding Swift Package Manager compatibility to your plugin. '
          'See $kSwiftPackageManagerDocsUrl for more information.';
    }

    if (hasPackageSwift) {
      final String contents = fileSystem.file(packageSwiftPath).readAsStringSync();
      if (!contents.contains('FlutterFramework')) {
        return 'Plugin ${plugin.name} has a Package.swift for $platform but is missing a dependency '
            'on FlutterFramework. Add the following to your Package.swift dependencies:\n'
            '    .package(name: "FlutterFramework", path: "../FlutterFramework")\n'
            'And add FlutterFramework as a target dependency:\n'
            '    .product(name: "FlutterFramework", package: "FlutterFramework")\n'
            'See $kSwiftPackageManagerDocsUrl for more information.';
      }
    }

    return null;
  }
}

/// The URL for documentation on adding Swift Package Manager support to a plugin.
const String kSwiftPackageManagerDocsUrl =
    'https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-plugin-authors';
