// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
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
    required Logger logger,
  })  : _project = project,
        _plugins = plugins,
        _cocoapods = cocoapods,
        _swiftPackageManager = swiftPackageManager,
        _fileSystem = fileSystem,
        _logger = logger;

  final FlutterProject _project;
  final List<Plugin> _plugins;
  final CocoaPods _cocoapods;
  final SwiftPackageManager _swiftPackageManager;
  final FileSystem _fileSystem;
  final Logger _logger;

  /// Generates/updates required files and project settings for Darwin
  /// Dependency Managers (CocoaPods and Swift Package Manager). Projects may
  /// use only CocoaPods, only Swift Package Manager, or both. This only
  /// generates files for the manager(s) being used.
  ///
  /// CocoaPods requires a Podfile and certain values in the Flutter xcconfig
  /// files.
  ///
  /// Swift Package Manager requires a Package.swift, link to the Flutter
  /// framework, and certain settings in the Xcode project's project.pbxproj.
  Future<void> setup({
    required SupportedPlatform platform,
  }) async {
    if (platform != SupportedPlatform.ios &&
        platform != SupportedPlatform.macos) {
      throwToolExit(
        'The platform ${platform.name} is incompatible with Darwin Dependency Managers. Only iOS and macOS is allowed.',
      );
    }
    final XcodeBasedProject xcodeProject = platform == SupportedPlatform.ios
        ? _project.ios
        : _project.macos;
    if (_project.usesSwiftPackageManager) {
      await _swiftPackageManager.generatePluginsSwiftPackage(
        _plugins,
        platform,
        xcodeProject,
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
      );
    }

    // Skip updating Podfile if project is a module, since it will use a
    // different module-specific Podfile.
    if (!_project.isModule) {
      final (int pluginCount, int swiftPackageCount, int cocoapodCount) = await _evaluatePluginsAndPrintWarnings(
        platform: platform,
        xcodeProject: xcodeProject,
      );

      final bool useCocoapods;
      if (_project.usesSwiftPackageManager) {
        useCocoapods = _usingCocoaPodsPlugin(
          pluginCount: pluginCount,
          swiftPackageCount: swiftPackageCount,
          cocoapodCount: cocoapodCount,
        );
      } else {
        // When Swift Package Manager is not enabled, setup Podfile if plugins
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
    }
  }

  bool _usingCocoaPodsPlugin({
    required int pluginCount,
    required int swiftPackageCount,
    required int cocoapodCount,
  }) {
    if (_project.usesSwiftPackageManager) {
      if (pluginCount == swiftPackageCount) {
        return false;
      }
    }
    if (cocoapodCount > 0) {
      return true;
    }
    return false;
  }

  /// Returns count of total number of plugins, number of Swift Package Manager
  /// compatible plugins, and number of CocoaPods compatible plugins. A plugin
  /// can be both Swift Package Manager and CocoaPods compatible.
  ///
  /// Prints warnings when using a plugin incompatible with the available Darwin
  /// Dependency Manager (Swift Package Manager or CocoaPods).
  ///
  /// Prints message prompting the user to deintegrate CocoaPods if using all
  /// Swift Package plugins.
  Future<(int, int, int)> _evaluatePluginsAndPrintWarnings({
    required SupportedPlatform platform,
    required XcodeBasedProject xcodeProject,
  }) async {
    int pluginCount = 0;
    int swiftPackageCount = 0;
    int cocoapodCount = 0;
    for (final Plugin plugin in _plugins) {
      if (plugin.platforms[platform.name] == null) {
        continue;
      }
      final String? swiftPackagePath = plugin.pluginSwiftPackageManifestPath(
        _fileSystem,
        platform.name,
      );
      final bool swiftPackageManagerCompatible = swiftPackagePath != null &&
          _fileSystem.file(swiftPackagePath).existsSync();

      final String? podspecPath = plugin.pluginPodspecPath(
        _fileSystem,
        platform.name,
      );
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
      if (!_project.usesSwiftPackageManager &&
          !cocoaPodsCompatible &&
          swiftPackageManagerCompatible) {
        throwToolExit(
            'Plugin ${plugin.name} is only Swift Package Manager compatible. Try '
            'enabling Swift Package Manager by running '
            '"flutter config --enable-swift-package-manager" or remove the '
            'plugin as a dependency.');
      }
    }

    if (_project.usesSwiftPackageManager &&
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
        if (xcodeProject.podfile.readAsStringSync() ==
            podfileTemplate.readAsStringSync()) {
          _logger.printWarning(
              'All plugins found for ${platform.name} are Swift Packages, but your '
              'project still has CocoaPods integration. To remove CocoaPods '
              'integration, in the ${platform.name}/ directory run "pod deintegrate" '
              'and delete the Podfile. Removing CocoaPods integration will improve '
              "the project's build time.");
        } else {
          // If all plugins are Swift Packages, but the Podfile has custom logic,
          // recommend migrating manually.
          _logger.printWarning(
              'All plugins found for ${platform.name} are Swift Packages, but your '
              'project still has CocoaPods integration. Your project uses a '
              'non-standard Podfile and will need to be migrated to Swift Package '
              'Manager manually. Removing CocoaPods integration will improve the '
              "project's build time.");
        }
      }
    }

    return (pluginCount, swiftPackageCount, cocoapodCount);
  }
}
