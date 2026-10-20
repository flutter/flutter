// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'base/common.dart';
import 'base/file_system.dart';
import 'platform_plugins.dart';
import 'plugin_yaml_parser.dart';

class Plugin {
  Plugin({
    required this.name,
    required this.path,
    required this.platforms,
    required this.defaultPackagePlatforms,
    required this.pluginDartClassPlatforms,
    this.flutterConstraint,
    required this.dependencies,
    required this.isDirectDependency,
    required this.isDevDependency,
    this.implementsPackage,
  });

  /// Parses [Plugin] specification from the provided pluginYaml.
  ///
  /// This currently supports two formats. Legacy and Multi-platform.
  ///
  /// Example of the deprecated Legacy format.
  ///
  ///     flutter:
  ///      plugin:
  ///        androidPackage: io.flutter.plugins.sample
  ///        iosPrefix: FLT
  ///        pluginClass: SamplePlugin
  ///
  /// Example Multi-platform format.
  ///
  ///     flutter:
  ///      plugin:
  ///        platforms:
  ///          android:
  ///            package: io.flutter.plugins.sample
  ///            pluginClass: SamplePlugin
  ///          ios:
  ///            # A plugin implemented through method channels.
  ///            pluginClass: SamplePlugin
  ///          linux:
  ///            # A plugin implemented purely in Dart code.
  ///            dartPluginClass: SamplePlugin
  ///            # Optional field to determine file containing dartPluginClass.
  ///            # This file will be used in imports in generated files, e.g.:
  ///            #   import 'package:{{pluginName}}/{{dartFileName}}'
  ///            # instead of default:
  ///            #    import 'package:{{pluginName}}/{{pluginName}}.dart'
  ///            dartFileName: src/sample_plugin.dart
  ///          macos:
  ///            # A plugin implemented with `dart:ffi`.
  ///            ffiPlugin: true
  ///          windows:
  ///            # A plugin using platform-specific Dart and method channels.
  ///            dartPluginClass: SamplePlugin
  ///            pluginClass: SamplePlugin
  factory Plugin.fromYaml(
    String name,
    String path,
    YamlMap? pluginYaml,
    VersionConstraint? flutterConstraint,
    List<String> dependencies, {
    required FileSystem fileSystem,
    required bool isDevDependency,
    Set<String>? appDependencies,
  }) {
    final ParseResult<Plugin> result = _parseFromYaml(
      name,
      path,
      pluginYaml,
      flutterConstraint,
      dependencies,
      fileSystem: fileSystem,
      isDevDependency: isDevDependency,
      appDependencies: appDependencies,
    );
    switch (result) {
      case ParseResultPass(value: final plugin):
        return plugin;
      case ParseResultFail(errors: final errors):
        throwToolExit('Invalid plugin specification $name.\n${errors.join('\n')}');
    }
  }

  static ParseResult<Plugin> _parseFromYaml(
    String name,
    String path,
    YamlMap? pluginYaml,
    VersionConstraint? flutterConstraint,
    List<String> dependencies, {
    required FileSystem fileSystem,
    required bool isDevDependency,
    Set<String>? appDependencies,
  }) {
    if (pluginYaml == null) {
      return .fail(<String>['Invalid "plugin" specification.']);
    }

    final bool usesOldPluginFormat = const <String>{
      'androidPackage',
      'iosPrefix',
      'pluginClass',
    }.any(pluginYaml.containsKey);

    final bool usesNewPluginFormat = pluginYaml.containsKey('platforms');

    if (usesOldPluginFormat && usesNewPluginFormat) {
      const errorMessage =
          'The flutter.plugin.platforms key cannot be used in combination with the old '
          'flutter.plugin.{androidPackage,iosPrefix,pluginClass} keys. '
          'See: https://flutter.dev/to/pubspec-plugin-platforms';
      return .fail(<String>[errorMessage]);
    }

    if (!usesOldPluginFormat && !usesNewPluginFormat) {
      const errorMessage =
          'Cannot find the `flutter.plugin.platforms` key in the `pubspec.yaml` file. '
          'An instruction to format the `pubspec.yaml` can be found here: '
          'https://flutter.dev/to/pubspec-plugin-platforms';
      return .fail(<String>[errorMessage]);
    }

    final bool isDirectDependency = appDependencies != null && appDependencies.contains(name);

    if (usesNewPluginFormat) {
      return _parseMultiPlatformYaml(
        name,
        path,
        pluginYaml,
        flutterConstraint,
        dependencies,
        fileSystem,
        isDirectDependency,
        isDevDependency: isDevDependency,
      );
    }
    return _parseLegacyYaml(
      name,
      path,
      pluginYaml,
      flutterConstraint,
      dependencies,
      fileSystem,
      isDirectDependency,
      isDevDependency: isDevDependency,
    );
  }

  static ParseResult<Plugin> _parseMultiPlatformYaml(
    String name,
    String path,
    YamlMap pluginYaml,
    VersionConstraint? flutterConstraint,
    List<String> dependencies,
    FileSystem fileSystem,
    bool isDirectDependency, {
    required bool isDevDependency,
  }) {
    final Object? platformsValue = pluginYaml['platforms'];
    if (platformsValue is! YamlMap?) {
      const errorMessage =
          'flutter.plugin.platforms should be a map with the platform name as the key';
      return .fail(<String>[errorMessage]);
    }
    if (platformsValue == null) {
      return .fail(<String>['Invalid "platforms" specification.']);
    }
    final YamlMap platformsYaml = platformsValue;

    final errors = <String>[];
    final platforms = <String, PluginPlatform>{};
    // TODO(stuartmorgan): Consider merging web into this common handling; the
    //  fact that its implementation of Dart-only plugins and default packages
    //  are separate is legacy.
    final defaultPackages = <String, String>{};
    final dartPluginClasses = <String, DartPluginClassAndFilePair>{};

    void parsePlatform<T extends PluginPlatform>(
      String platformKey,
      ParseResult<T?> Function(YamlMap) parse, {
      bool isWebPlugin = false,
    }) {
      if (!platformsYaml.containsKey(platformKey)) {
        return;
      }
      final Object? yamlValue = platformsYaml[platformKey];
      if (yamlValue is! YamlMap) {
        if (!isWebPlugin) {
          // Unlike native/Dart platforms, an empty `web:` entry (where the value is
          // null rather than a YamlMap) is ignored rather than rejected, as existing
          // published packages use an empty `web:` key to declare web support without
          // a WebPlugin registrant class.
          errors.add('Invalid "$platformKey" plugin specification.');
        }
        return;
      }
      if (isWebPlugin && yamlValue.containsKey(kDefaultPackage)) {
        // Unlike native/Dart platforms, a `web:` entry with `default_package` is
        // ignored.
        return;
      }
      final parser = PluginYamlParser(yamlValue, pluginName: name, configKey: platformKey);
      final ParseResult<void> result =
          (parser.string(kDefaultPackage, allowNull: false), parse(yamlValue)).map((
            String? defaultPackage,
            T? parsed,
          ) {
            if (defaultPackage != null) {
              defaultPackages[platformKey] = defaultPackage;
            } else if (parsed != null) {
              platforms[platformKey] = parsed;
            } else {
              errors.add('Invalid "$platformKey" plugin specification.');
            }
            if (parsed case DartPlugin(:final String dartPluginClass, :final String dartFileName)) {
              dartPluginClasses[platformKey] = (
                dartClass: dartPluginClass,
                dartFileName: dartFileName,
              );
            }
          });
      if (result case ParseResultFail(errors: final List<String> platformErrors)) {
        errors.addAll(platformErrors);
      }
    }

    parsePlatform(
      AndroidPlugin.kConfigKey,
      (YamlMap yaml) =>
          AndroidPlugin.parseFromYaml(name, yaml, pluginPath: path, fileSystem: fileSystem),
    );
    parsePlatform(IOSPlugin.kConfigKey, (YamlMap yaml) => IOSPlugin.parseFromYaml(name, yaml));
    parsePlatform(LinuxPlugin.kConfigKey, (YamlMap yaml) => LinuxPlugin.parseFromYaml(name, yaml));
    parsePlatform(MacOSPlugin.kConfigKey, (YamlMap yaml) => MacOSPlugin.parseFromYaml(name, yaml));
    parsePlatform(
      WebPlugin.kConfigKey,
      (YamlMap yaml) => WebPlugin.parseFromYaml(name, yaml),
      isWebPlugin: true,
    );
    parsePlatform(
      WindowsPlugin.kConfigKey,
      (YamlMap yaml) => WindowsPlugin.parseFromYaml(name, yaml),
    );

    final Object? implementsValue = pluginYaml['implements'];
    var implementsPackage = '';
    if (implementsValue != null) {
      if (implementsValue is String) {
        implementsPackage = implementsValue;
      } else {
        errors.add('Invalid "implements" specification.');
      }
    }

    if (errors.isNotEmpty) {
      return .fail(errors);
    }

    return .pass(
      Plugin(
        name: name,
        path: path,
        platforms: platforms,
        defaultPackagePlatforms: defaultPackages,
        pluginDartClassPlatforms: dartPluginClasses,
        flutterConstraint: flutterConstraint,
        dependencies: dependencies,
        isDirectDependency: isDirectDependency,
        implementsPackage: implementsPackage,
        isDevDependency: isDevDependency,
      ),
    );
  }

  static ParseResult<Plugin> _parseLegacyYaml(
    String name,
    String path,
    YamlMap pluginYaml,
    VersionConstraint? flutterConstraint,
    List<String> dependencies,
    FileSystem fileSystem,
    bool isDirectDependency, {
    required bool isDevDependency,
  }) {
    final Object? androidPackage = pluginYaml['androidPackage'];
    final Object? iosPrefix = pluginYaml['iosPrefix'];
    final Object? pluginClass = pluginYaml['pluginClass'];

    // As in the `platforms:` format, every identifier is checked here: they are
    // interpolated verbatim into the generated GeneratedPluginRegistrant source
    // files, so anything that is not a plain identifier would let a (possibly
    // transitive) dependency inject native code into the consuming app's build.
    const identifierRequirement =
        'must be a valid identifier, optionally with dot-separated segments';

    final errors = <String>[
      if (androidPackage is! String?)
        'The "androidPackage" must either be null or a string.'
      else if (androidPackage != null && !isValidPluginIdentifier(androidPackage))
        'The "androidPackage" $identifierRequirement.',
      if (iosPrefix is! String?)
        'The "iosPrefix" must either be null or a string.'
      // An empty prefix is the default for a legacy plugin that does not set one.
      else if (iosPrefix != null && iosPrefix.isNotEmpty && !isValidPluginIdentifier(iosPrefix))
        'The "iosPrefix" $identifierRequirement.',
      if (pluginClass is! String?)
        'The "pluginClass" must either be null or a string.'
      else if (pluginClass != null && !isValidPluginIdentifier(pluginClass))
        'The "pluginClass" $identifierRequirement.',
    ];

    if (errors.isNotEmpty) {
      return .fail(errors);
    }

    final platforms = <String, PluginPlatform>{};
    if (pluginClass is String) {
      if (androidPackage is String) {
        platforms[AndroidPlugin.kConfigKey] = AndroidPlugin(
          name: name,
          package: androidPackage,
          pluginClass: pluginClass,
          pluginPath: path,
          fileSystem: fileSystem,
        );
      }

      platforms[IOSPlugin.kConfigKey] = IOSPlugin(
        name: name,
        classPrefix: iosPrefix as String? ?? '',
        pluginClass: pluginClass,
      );
    }
    return .pass(
      Plugin(
        name: name,
        path: path,
        platforms: platforms,
        defaultPackagePlatforms: <String, String>{},
        pluginDartClassPlatforms: <String, DartPluginClassAndFilePair>{},
        flutterConstraint: flutterConstraint,
        dependencies: dependencies,
        isDirectDependency: isDirectDependency,
        isDevDependency: isDevDependency,
      ),
    );
  }

  /// Create a YamlMap that represents the supported platforms.
  ///
  /// For example, if the `platforms` contains 'ios' and 'android', the return map looks like:
  ///
  ///     android:
  ///       package: io.flutter.plugins.sample
  ///       pluginClass: SamplePlugin
  ///     ios:
  ///       pluginClass: SamplePlugin
  static YamlMap createPlatformsYamlMap(
    List<String> platforms,
    String pluginClass,
    String androidPackage,
  ) {
    final map = <String, dynamic>{};
    for (final platform in platforms) {
      map[platform] = <String, String>{
        'pluginClass': pluginClass,
        ...platform == 'android' ? <String, String>{'package': androidPackage} : <String, String>{},
      };
    }
    return YamlMap.wrap(map);
  }

  static List<String> validatePluginYaml(YamlMap? yaml, {String packageName = 'plugin'}) {
    final ParseResult<Plugin> result = _parseFromYaml(
      packageName,
      '',
      yaml,
      null,
      const <String>[],
      // `_parseFromYaml` requires a `FileSystem` to construct `AndroidPlugin`,
      // which only accesses `_fileSystem` lazily when `toMap()` is called. Since
      // `validatePluginYaml` is called from `FlutterManifest` where no
      // `FileSystem` is available and the parsed `Plugin` is discarded here,
      // an unused `MemoryFileSystem` is passed.
      // TODO(chingjun): Remove the required fileSystem parameter here.
      fileSystem: MemoryFileSystem(),
      isDevDependency: false,
    );
    return switch (result) {
      ParseResultFail(:final errors) => errors,
      ParseResultPass() => const <String>[],
    };
  }

  final String name;
  final String path;

  /// The name of the interface package that this plugin implements.
  /// If `null`, this plugin doesn't implement an interface.
  final String? implementsPackage;

  /// The required version of Flutter, if specified.
  final VersionConstraint? flutterConstraint;

  /// The name of the packages this plugin depends on.
  final List<String> dependencies;

  /// This is a mapping from platform config key to the plugin platform spec.
  final Map<String, PluginPlatform> platforms;

  /// This is a mapping from platform config key to the default package implementation.
  final Map<String, String> defaultPackagePlatforms;

  /// This is a mapping from platform config key to the Dart plugin class for the given platform.
  final Map<String, DartPluginClassAndFilePair> pluginDartClassPlatforms;

  /// Whether this plugin is a direct dependency of the app.
  /// If `false`, the plugin is a dependency of another plugin.
  final bool isDirectDependency;

  /// Whether this plugin is exclusively used as a dev dependency of the app.
  ///
  /// If `false`, the plugin is either:
  /// - _Not_ a dev dependency
  /// - _Not_ a dev dependency of some dependency that itself is not a dev
  ///   dependency
  ///
  /// Dev dependencies are intended to be stripped out in release builds.
  final bool isDevDependency;

  /// Expected path to the plugin's swift package, which contains the Package.swift.
  ///
  /// This path should be `/path/to/[package_name]/[platform]/[package_name]`
  /// (e.g. `/path/to/my_plugin/ios/my_plugin`).
  ///
  /// Returns null if the plugin does not support the [platform] or the
  /// [platform] is not iOS or macOS.
  ///
  /// If [overridePath] is provided, returns `[overridePath]/[platform]/[package_name]`.
  String? pluginSwiftPackagePath(FileSystem fileSystem, String platform, {String? overridePath}) {
    final String? platformDirectoryName = _darwinPluginDirectoryName(platform);
    if (platformDirectoryName == null) {
      return null;
    }
    if (overridePath != null) {
      return fileSystem.path.join(overridePath, platformDirectoryName, name);
    }
    return fileSystem.path.join(path, platformDirectoryName, name);
  }

  /// Expected path to the plugin's Package.swift. Returns null if the plugin
  /// does not support the [platform] or the [platform] is not iOS or macOS.
  String? pluginSwiftPackageManifestPath(FileSystem fileSystem, String platform) {
    final String? packagePath = pluginSwiftPackagePath(fileSystem, platform);
    if (packagePath == null) {
      return null;
    }
    return fileSystem.path.join(packagePath, 'Package.swift');
  }

  /// Returns true if the plugin supports the [platform] and a Package.swift exists.
  bool supportSwiftPackageManagerForPlatform(FileSystem fileSystem, String platform) {
    final String? manifestPath = pluginSwiftPackageManifestPath(fileSystem, platform);
    return platforms[platform] != null &&
        manifestPath != null &&
        fileSystem.file(manifestPath).existsSync();
  }

  /// Returns true if the plugin supports the [platform] and a podspec exists.
  bool supportCocoapodsForPlatform(FileSystem fileSystem, String platform) {
    final String? podspecPath = pluginPodspecPath(fileSystem, platform);
    return platforms[platform] != null &&
        podspecPath != null &&
        fileSystem.file(podspecPath).existsSync();
  }

  /// Expected path to the plugin's podspec. Returns null if the plugin does
  /// not support the [platform] or the [platform] is not iOS or macOS.
  String? pluginPodspecPath(FileSystem fileSystem, String platform) {
    final String? platformDirectoryName = _darwinPluginDirectoryName(platform);
    if (platformDirectoryName == null) {
      return null;
    }
    return fileSystem.path.join(path, platformDirectoryName, '$name.podspec');
  }

  String? _darwinPluginDirectoryName(String platform) {
    final PluginPlatform? platformPlugin = platforms[platform];
    if (platformPlugin == null ||
        (platform != IOSPlugin.kConfigKey && platform != MacOSPlugin.kConfigKey)) {
      return null;
    }

    // iOS and macOS code can be shared in "darwin" directory, otherwise
    // respectively in "ios" or "macos" directories.
    if (platformPlugin is DarwinPlugin && (platformPlugin as DarwinPlugin).sharedDarwinSource) {
      return 'darwin';
    }
    return platform;
  }
}

/// Metadata associated with the resolution of a platform interface of a plugin.
class PluginInterfaceResolution {
  PluginInterfaceResolution({required this.plugin, required this.platform});

  /// The plugin.
  final Plugin plugin;

  /// The name of the platform that this plugin implements.
  final String platform;

  Map<String, String> toMap() {
    return <String, String>{
      'pluginName': plugin.name,
      'platform': platform,
      'dartClass': plugin.pluginDartClassPlatforms[platform]?.dartClass ?? '',
      'dartFileName': plugin.pluginDartClassPlatforms[platform]?.dartFileName ?? '',
    };
  }

  @override
  String toString() {
    return '<PluginInterfaceResolution ${plugin.name} for $platform>';
  }
}

/// A record representing pair of dartPluginClass and dartFileName used as metadata
/// in [PluginInterfaceResolution].
///
/// The `dartClass` and `dartFileName` fields are guaranteed to be non-null:
///
/// - record should be created only if dartClassName exists in plugin configuration.
/// - dartFileName either taken from configuration, or, if absent, should be
///   constructed from plugin name.
///
/// See also:
/// - [PluginInterfaceResolution], which uses this record to create Map with metadata.
typedef DartPluginClassAndFilePair = ({String dartClass, String dartFileName});
