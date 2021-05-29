// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as path; // flutter_ignore: package_path_import
import 'package:yaml/yaml.dart';

import 'android/gradle.dart';
import 'base/common.dart';
import 'base/error_handling_io.dart';
import 'base/file_system.dart';
import 'base/os.dart';
import 'base/platform.dart';
import 'base/version.dart';
import 'convert.dart';
import 'dart/package_map.dart';
import 'features.dart';
import 'globals.dart' as globals;
import 'platform_plugins.dart';
import 'project.dart';

void _renderTemplateToFile(String template, dynamic context, String filePath) {
  final String renderedTemplate = globals.templateRenderer
    .renderString(template, context, htmlEscapeValues: false);
  final File file = globals.fs.file(filePath);
  file.createSync(recursive: true);
  file.writeAsStringSync(renderedTemplate);
}

class Plugin {
  Plugin({
    @required this.name,
    @required this.path,
    @required this.platforms,
    @required this.dependencies,
  }) : assert(name != null),
       assert(path != null),
       assert(platforms != null),
       assert(dependencies != null);

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
  ///            pluginClass: SamplePlugin
  ///          linux:
  ///            pluginClass: SamplePlugin
  ///          macos:
  ///            pluginClass: SamplePlugin
  ///          windows:
  ///            pluginClass: SamplePlugin
  factory Plugin.fromYaml(
    String name,
    String path,
    YamlMap pluginYaml,
    List<String> dependencies, {
    @required FileSystem fileSystem,
  }) {
    final List<String> errors = validatePluginYaml(pluginYaml);
    if (errors.isNotEmpty) {
      throwToolExit('Invalid plugin specification $name.\n${errors.join('\n')}');
    }
    if (pluginYaml != null && pluginYaml['platforms'] != null) {
      return Plugin._fromMultiPlatformYaml(name, path, pluginYaml, dependencies, fileSystem);
    }
    return Plugin._fromLegacyYaml(name, path, pluginYaml, dependencies, fileSystem);
  }

  factory Plugin._fromMultiPlatformYaml(
    String name,
    String path,
    dynamic pluginYaml,
    List<String> dependencies,
    FileSystem fileSystem,
  ) {
    assert (pluginYaml != null && pluginYaml['platforms'] != null,
            'Invalid multi-platform plugin specification $name.');
    final YamlMap platformsYaml = pluginYaml['platforms'] as YamlMap;

    assert (_validateMultiPlatformYaml(platformsYaml).isEmpty,
            'Invalid multi-platform plugin specification $name.');

    final Map<String, PluginPlatform> platforms = <String, PluginPlatform>{};

    if (_providesImplementationForPlatform(platformsYaml, AndroidPlugin.kConfigKey)) {
      platforms[AndroidPlugin.kConfigKey] = AndroidPlugin.fromYaml(
        name,
        platformsYaml[AndroidPlugin.kConfigKey] as YamlMap,
        path,
        fileSystem,
      );
    }

    if (_providesImplementationForPlatform(platformsYaml, IOSPlugin.kConfigKey)) {
      platforms[IOSPlugin.kConfigKey] =
          IOSPlugin.fromYaml(name, platformsYaml[IOSPlugin.kConfigKey] as YamlMap);
    }

    if (_providesImplementationForPlatform(platformsYaml, LinuxPlugin.kConfigKey)) {
      platforms[LinuxPlugin.kConfigKey] =
          LinuxPlugin.fromYaml(name, platformsYaml[LinuxPlugin.kConfigKey] as YamlMap);
    }

    if (_providesImplementationForPlatform(platformsYaml, MacOSPlugin.kConfigKey)) {
      platforms[MacOSPlugin.kConfigKey] =
          MacOSPlugin.fromYaml(name, platformsYaml[MacOSPlugin.kConfigKey] as YamlMap);
    }

    if (_providesImplementationForPlatform(platformsYaml, WebPlugin.kConfigKey)) {
      platforms[WebPlugin.kConfigKey] =
          WebPlugin.fromYaml(name, platformsYaml[WebPlugin.kConfigKey] as YamlMap);
    }

    if (_providesImplementationForPlatform(platformsYaml, WindowsPlugin.kConfigKey)) {
      platforms[WindowsPlugin.kConfigKey] =
          WindowsPlugin.fromYaml(name, platformsYaml[WindowsPlugin.kConfigKey] as YamlMap);
    }

    return Plugin(
      name: name,
      path: path,
      platforms: platforms,
      dependencies: dependencies,
    );
  }

  factory Plugin._fromLegacyYaml(
    String name,
    String path,
    dynamic pluginYaml,
    List<String> dependencies,
    FileSystem fileSystem,
  ) {
    final Map<String, PluginPlatform> platforms = <String, PluginPlatform>{};
    final String pluginClass = pluginYaml['pluginClass'] as String;
    if (pluginYaml != null && pluginClass != null) {
      final String androidPackage = pluginYaml['androidPackage'] as String;
      if (androidPackage != null) {
        platforms[AndroidPlugin.kConfigKey] = AndroidPlugin(
          name: name,
          package: pluginYaml['androidPackage'] as String,
          pluginClass: pluginClass,
          pluginPath: path,
          fileSystem: fileSystem,
        );
      }

      final String iosPrefix = pluginYaml['iosPrefix'] as String ?? '';
      platforms[IOSPlugin.kConfigKey] =
          IOSPlugin(
            name: name,
            classPrefix: iosPrefix,
            pluginClass: pluginClass,
          );
    }
    return Plugin(
      name: name,
      path: path,
      platforms: platforms,
      dependencies: dependencies,
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
  static YamlMap createPlatformsYamlMap(List<String> platforms, String pluginClass, String androidPackage) {
    final Map<String, dynamic> map = <String, dynamic>{};
    for (final String platform in platforms) {
      map[platform] = <String, String>{
        'pluginClass': pluginClass,
        ...platform == 'android' ? <String, String>{'package': androidPackage} : <String, String>{},
      };
    }
    return YamlMap.wrap(map);
  }

  static List<String> validatePluginYaml(YamlMap yaml) {
    if (yaml == null) {
      return <String>['Invalid "plugin" specification.'];
    }

    final bool usesOldPluginFormat = const <String>{
      'androidPackage',
      'iosPrefix',
      'pluginClass',
    }.any(yaml.containsKey);

    final bool usesNewPluginFormat = yaml.containsKey('platforms');

    if (usesOldPluginFormat && usesNewPluginFormat) {
      const String errorMessage =
          'The flutter.plugin.platforms key cannot be used in combination with the old '
          'flutter.plugin.{androidPackage,iosPrefix,pluginClass} keys. '
          'See: https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin';
      return <String>[errorMessage];
    }

    if (!usesOldPluginFormat && !usesNewPluginFormat) {
      const String errorMessage =
          'Cannot find the `flutter.plugin.platforms` key in the `pubspec.yaml` file. '
          'An instruction to format the `pubspec.yaml` can be found here: '
          'https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms';
      return <String>[errorMessage];
    }

    if (usesNewPluginFormat) {
      if (yaml['platforms'] != null && yaml['platforms'] is! YamlMap) {
        const String errorMessage = 'flutter.plugin.platforms should be a map with the platform name as the key';
        return <String>[errorMessage];
      }
      return _validateMultiPlatformYaml(yaml['platforms'] as YamlMap);
    } else {
      return _validateLegacyYaml(yaml);
    }
  }

  static List<String> _validateMultiPlatformYaml(YamlMap yaml) {
    bool isInvalid(String key, bool Function(YamlMap) validate) {
      if (!yaml.containsKey(key)) {
        return false;
      }
      final dynamic value = yaml[key];
      if (value is! YamlMap) {
        return true;
      }
      final YamlMap yamlValue = value as YamlMap;
      if (yamlValue.containsKey('default_package')) {
        return false;
      }
      return !validate(yamlValue);
    }

    if (yaml == null) {
      return <String>['Invalid "platforms" specification.'];
    }
    final List<String> errors = <String>[];
    if (isInvalid(AndroidPlugin.kConfigKey, AndroidPlugin.validate)) {
      errors.add('Invalid "android" plugin specification.');
    }
    if (isInvalid(IOSPlugin.kConfigKey, IOSPlugin.validate)) {
      errors.add('Invalid "ios" plugin specification.');
    }
    if (isInvalid(LinuxPlugin.kConfigKey, LinuxPlugin.validate)) {
      errors.add('Invalid "linux" plugin specification.');
    }
    if (isInvalid(MacOSPlugin.kConfigKey, MacOSPlugin.validate)) {
      errors.add('Invalid "macos" plugin specification.');
    }
    if (isInvalid(WindowsPlugin.kConfigKey, WindowsPlugin.validate)) {
      errors.add('Invalid "windows" plugin specification.');
    }
    return errors;
  }

  static List<String> _validateLegacyYaml(YamlMap yaml) {
    final List<String> errors = <String>[];

    if (yaml['androidPackage'] != null && yaml['androidPackage'] is! String) {
      errors.add('The "androidPackage" must either be null or a string.');
    }
    if (yaml['iosPrefix'] != null && yaml['iosPrefix'] is! String) {
      errors.add('The "iosPrefix" must either be null or a string.');
    }
    if (yaml['pluginClass'] != null && yaml['pluginClass'] is! String) {
      errors.add('The "pluginClass" must either be null or a string..');
    }
    return errors;
  }

  static bool _providesImplementationForPlatform(YamlMap platformsYaml, String platformKey) {
    if (!platformsYaml.containsKey(platformKey)) {
      return false;
    }
    if ((platformsYaml[platformKey] as YamlMap).containsKey('default_package')) {
      return false;
    }
    return true;
  }

  final String name;
  final String path;

  /// The name of the packages this plugin depends on.
  final List<String> dependencies;

  /// This is a mapping from platform config key to the plugin platform spec.
  final Map<String, PluginPlatform> platforms;
}

Plugin _pluginFromPackage(String name, Uri packageRoot) {
  final String pubspecPath = globals.fs.path.fromUri(packageRoot.resolve('pubspec.yaml'));
  if (!globals.fs.isFileSync(pubspecPath)) {
    return null;
  }
  dynamic pubspec;

  try {
    pubspec = loadYaml(globals.fs.file(pubspecPath).readAsStringSync());
  } on YamlException catch (err) {
    globals.printTrace('Failed to parse plugin manifest for $name: $err');
    // Do nothing, potentially not a plugin.
  }
  if (pubspec == null) {
    return null;
  }
  final dynamic flutterConfig = pubspec['flutter'];
  if (flutterConfig == null || !(flutterConfig.containsKey('plugin') as bool)) {
    return null;
  }
  final String packageRootPath = globals.fs.path.fromUri(packageRoot);
  final YamlMap dependencies = pubspec['dependencies'] as YamlMap;
  globals.printTrace('Found plugin $name at $packageRootPath');
  return Plugin.fromYaml(
    name,
    packageRootPath,
    flutterConfig['plugin'] as YamlMap,
    dependencies == null ? <String>[] : <String>[...dependencies.keys.cast<String>()],
    fileSystem: globals.fs,
  );
}

Future<List<Plugin>> findPlugins(FlutterProject project, { bool throwOnError = true}) async {
  final List<Plugin> plugins = <Plugin>[];
  final String packagesFile = globals.fs.path.join(
    project.directory.path,
    '.packages',
  );
  final PackageConfig packageConfig = await loadPackageConfigWithLogging(
    globals.fs.file(packagesFile),
    logger: globals.logger,
    throwOnError: throwOnError,
  );
  for (final Package package in packageConfig.packages) {
    final Uri packageRoot = package.packageUriRoot.resolve('..');
    final Plugin plugin = _pluginFromPackage(package.name, packageRoot);
    if (plugin != null) {
      plugins.add(plugin);
    }
  }
  return plugins;
}

// Key strings for the .flutter-plugins-dependencies file.
const String _kFlutterPluginsPluginListKey = 'plugins';
const String _kFlutterPluginsNameKey = 'name';
const String _kFlutterPluginsPathKey = 'path';
const String _kFlutterPluginsDependenciesKey = 'dependencies';

  /// Filters [plugins] to those supported by [platformKey].
  List<Map<String, dynamic>> _filterPluginsByPlatform(List<Plugin>plugins, String platformKey) {
    final Iterable<Plugin> platformPlugins = plugins.where((Plugin p) {
      return p.platforms.containsKey(platformKey);
    });

    final Set<String> pluginNames = platformPlugins.map((Plugin plugin) => plugin.name).toSet();
    final List<Map<String, dynamic>> list = <Map<String, dynamic>>[];
    for (final Plugin plugin in platformPlugins) {
      list.add(<String, dynamic>{
        _kFlutterPluginsNameKey: plugin.name,
        _kFlutterPluginsPathKey: globals.fsUtils.escapePath(plugin.path),
        _kFlutterPluginsDependenciesKey: <String>[...plugin.dependencies.where(pluginNames.contains)],
      });
    }
    return list;
  }

/// Writes the .flutter-plugins-dependencies file based on the list of plugins.
/// If there aren't any plugins, then the files aren't written to disk. The resulting
/// file looks something like this (order of keys is not guaranteed):
/// {
///   "info": "This is a generated file; do not edit or check into version control.",
///   "plugins": {
///     "ios": [
///       {
///         "name": "test",
///         "path": "test_path",
///         "dependencies": [
///           "plugin-a",
///           "plugin-b"
///         ]
///       }
///     ],
///     "android": [],
///     "macos": [],
///     "linux": [],
///     "windows": [],
///     "web": []
///   },
///   "dependencyGraph": [
///     {
///       "name": "plugin-a",
///       "dependencies": [
///         "plugin-b",
///         "plugin-c"
///       ]
///     },
///     {
///       "name": "plugin-b",
///       "dependencies": [
///         "plugin-c"
///       ]
///     },
///     {
///       "name": "plugin-c",
///       "dependencies": []
///     }
///   ],
///   "date_created": "1970-01-01 00:00:00.000",
///   "version": "0.0.0-unknown"
/// }
///
///
/// Finally, returns [true] if the plugins list has changed, otherwise returns [false].
bool _writeFlutterPluginsList(FlutterProject project, List<Plugin> plugins) {
  final File pluginsFile = project.flutterPluginsDependenciesFile;
  if (plugins.isEmpty) {
    return ErrorHandlingFileSystem.deleteIfExists(pluginsFile);
  }

  final String iosKey = project.ios.pluginConfigKey;
  final String androidKey = project.android.pluginConfigKey;
  final String macosKey = project.macos.pluginConfigKey;
  final String linuxKey = project.linux.pluginConfigKey;
  final String windowsKey = project.windows.pluginConfigKey;
  final String webKey = project.web.pluginConfigKey;

  final Map<String, dynamic> pluginsMap = <String, dynamic>{};
  pluginsMap[iosKey] = _filterPluginsByPlatform(plugins, iosKey);
  pluginsMap[androidKey] = _filterPluginsByPlatform(plugins, androidKey);
  pluginsMap[macosKey] = _filterPluginsByPlatform(plugins, macosKey);
  pluginsMap[linuxKey] = _filterPluginsByPlatform(plugins, linuxKey);
  pluginsMap[windowsKey] = _filterPluginsByPlatform(plugins, windowsKey);
  pluginsMap[webKey] = _filterPluginsByPlatform(plugins, webKey);

  final Map<String, dynamic> result = <String, dynamic> {};

  result['info'] =  'This is a generated file; do not edit or check into version control.';
  result[_kFlutterPluginsPluginListKey] = pluginsMap;
  /// The dependencyGraph object is kept for backwards compatibility, but
  /// should be removed once migration is complete.
  /// https://github.com/flutter/flutter/issues/48918
  result['dependencyGraph'] = _createPluginLegacyDependencyGraph(plugins);
  result['date_created'] = globals.systemClock.now().toString();
  result['version'] = globals.flutterVersion.frameworkVersion;

  // Only notify if the plugins list has changed. [date_created] will always be different,
  // [version] is not relevant for this check.
  final String oldPluginsFileStringContent = _readFileContent(pluginsFile);
  bool pluginsChanged = true;
  if (oldPluginsFileStringContent != null) {
    pluginsChanged = oldPluginsFileStringContent.contains(pluginsMap.toString());
  }
  final String pluginFileContent = json.encode(result);
  pluginsFile.writeAsStringSync(pluginFileContent, flush: true);

  return pluginsChanged;
}

List<dynamic> _createPluginLegacyDependencyGraph(List<Plugin> plugins) {
  final List<dynamic> directAppDependencies = <dynamic>[];

  final Set<String> pluginNames = plugins.map((Plugin plugin) => plugin.name).toSet();
  for (final Plugin plugin in plugins) {
    directAppDependencies.add(<String, dynamic>{
      'name': plugin.name,
      // Extract the plugin dependencies which happen to be plugins.
      'dependencies': <String>[...plugin.dependencies.where(pluginNames.contains)],
    });
  }
  return directAppDependencies;
}

// The .flutter-plugins file will be DEPRECATED in favor of .flutter-plugins-dependencies.
// TODO(franciscojma): Remove this method once deprecated.
// https://github.com/flutter/flutter/issues/48918
//
/// Writes the .flutter-plugins files based on the list of plugins.
/// If there aren't any plugins, then the files aren't written to disk.
///
/// Finally, returns [true] if .flutter-plugins has changed, otherwise returns [false].
bool _writeFlutterPluginsListLegacy(FlutterProject project, List<Plugin> plugins) {
  final File pluginsFile = project.flutterPluginsFile;
  if (plugins.isEmpty) {
    return ErrorHandlingFileSystem.deleteIfExists(pluginsFile);
  }

  const String info = 'This is a generated file; do not edit or check into version control.';
  final StringBuffer flutterPluginsBuffer = StringBuffer('# $info\n');

  for (final Plugin plugin in plugins) {
    flutterPluginsBuffer.write('${plugin.name}=${globals.fsUtils.escapePath(plugin.path)}\n');
  }
  final String oldPluginFileContent = _readFileContent(pluginsFile);
  final String pluginFileContent = flutterPluginsBuffer.toString();
  pluginsFile.writeAsStringSync(pluginFileContent, flush: true);

  return oldPluginFileContent != _readFileContent(pluginsFile);
}

/// Returns the contents of [File] or [null] if that file does not exist.
String _readFileContent(File file) {
  return file.existsSync() ? file.readAsStringSync() : null;
}

const String _androidPluginRegistryTemplateOldEmbedding = '''
package io.flutter.plugins;

import io.flutter.plugin.common.PluginRegistry;
{{#plugins}}
import {{package}}.{{class}};
{{/plugins}}

/**
 * Generated file. Do not edit.
 */
public final class GeneratedPluginRegistrant {
  public static void registerWith(PluginRegistry registry) {
    if (alreadyRegisteredWith(registry)) {
      return;
    }
{{#plugins}}
    {{class}}.registerWith(registry.registrarFor("{{package}}.{{class}}"));
{{/plugins}}
  }

  private static boolean alreadyRegisteredWith(PluginRegistry registry) {
    final String key = GeneratedPluginRegistrant.class.getCanonicalName();
    if (registry.hasPlugin(key)) {
      return true;
    }
    registry.registrarFor(key);
    return false;
  }
}
''';

const String _androidPluginRegistryTemplateNewEmbedding = '''
package io.flutter.plugins;

import androidx.annotation.Keep;
import androidx.annotation.NonNull;

import io.flutter.embedding.engine.FlutterEngine;
{{#needsShim}}
import io.flutter.embedding.engine.plugins.shim.ShimPluginRegistry;
{{/needsShim}}

/**
 * Generated file. Do not edit.
 * This file is generated by the Flutter tool based on the
 * plugins that support the Android platform.
 */
@Keep
public final class GeneratedPluginRegistrant {
  public static void registerWith(@NonNull FlutterEngine flutterEngine) {
{{#needsShim}}
    ShimPluginRegistry shimPluginRegistry = new ShimPluginRegistry(flutterEngine);
{{/needsShim}}
{{#plugins}}
  {{#supportsEmbeddingV2}}
    flutterEngine.getPlugins().add(new {{package}}.{{class}}());
  {{/supportsEmbeddingV2}}
  {{^supportsEmbeddingV2}}
    {{#supportsEmbeddingV1}}
      {{package}}.{{class}}.registerWith(shimPluginRegistry.registrarFor("{{package}}.{{class}}"));
    {{/supportsEmbeddingV1}}
  {{/supportsEmbeddingV2}}
{{/plugins}}
  }
}
''';

List<Map<String, dynamic>> _extractPlatformMaps(List<Plugin> plugins, String type) {
  final List<Map<String, dynamic>> pluginConfigs = <Map<String, dynamic>>[];
  for (final Plugin p in plugins) {
    final PluginPlatform platformPlugin = p.platforms[type];
    if (platformPlugin != null) {
      pluginConfigs.add(platformPlugin.toMap());
    }
  }
  return pluginConfigs;
}

/// Returns the version of the Android embedding that the current
/// [project] is using.
AndroidEmbeddingVersion _getAndroidEmbeddingVersion(FlutterProject project) {
  assert(project.android != null);

  return project.android.getEmbeddingVersion();
}

Future<void> _writeAndroidPluginRegistrant(FlutterProject project, List<Plugin> plugins) async {
  final List<Map<String, dynamic>> androidPlugins =
    _extractPlatformMaps(plugins, AndroidPlugin.kConfigKey);

  final Map<String, dynamic> templateContext = <String, dynamic>{
    'plugins': androidPlugins,
    'androidX': isAppUsingAndroidX(project.android.hostAppGradleRoot),
  };
  final String javaSourcePath = globals.fs.path.join(
    project.android.pluginRegistrantHost.path,
    'src',
    'main',
    'java',
  );
  final String registryPath = globals.fs.path.join(
    javaSourcePath,
    'io',
    'flutter',
    'plugins',
    'GeneratedPluginRegistrant.java',
  );
  String templateContent;
  final AndroidEmbeddingVersion appEmbeddingVersion = _getAndroidEmbeddingVersion(project);
  switch (appEmbeddingVersion) {
    case AndroidEmbeddingVersion.v2:
      templateContext['needsShim'] = false;
      // If a plugin is using an embedding version older than 2.0 and the app is using 2.0,
      // then add shim for the old plugins.
      for (final Map<String, dynamic> plugin in androidPlugins) {
        if (plugin['supportsEmbeddingV1'] as bool && !(plugin['supportsEmbeddingV2'] as bool)) {
          templateContext['needsShim'] = true;
          if (project.isModule) {
            globals.printStatus(
              'The plugin `${plugin['name']}` is built using an older version '
              "of the Android plugin API which assumes that it's running in a "
              'full-Flutter environment. It may have undefined behaviors when '
              'Flutter is integrated into an existing app as a module.\n'
              'The plugin can be updated to the v2 Android Plugin APIs by '
              'following https://flutter.dev/go/android-plugin-migration.'
            );
          }
        }
      }
      templateContent = _androidPluginRegistryTemplateNewEmbedding;
      break;
    case AndroidEmbeddingVersion.v1:
    default:
      for (final Map<String, dynamic> plugin in androidPlugins) {
        if (!(plugin['supportsEmbeddingV1'] as bool) && plugin['supportsEmbeddingV2'] as bool) {
          throwToolExit(
            'The plugin `${plugin['name']}` requires your app to be migrated to '
            'the Android embedding v2. Follow the steps on https://flutter.dev/go/android-project-migration '
            'and re-run this command.'
          );
        }
      }
      templateContent = _androidPluginRegistryTemplateOldEmbedding;
      break;
  }
  globals.printTrace('Generating $registryPath');
  _renderTemplateToFile(
    templateContent,
    templateContext,
    registryPath,
  );
}

const String _objcPluginRegistryHeaderTemplate = '''
//
//  Generated file. Do not edit.
//

#ifndef GeneratedPluginRegistrant_h
#define GeneratedPluginRegistrant_h

#import <{{framework}}/{{framework}}.h>

NS_ASSUME_NONNULL_BEGIN

@interface GeneratedPluginRegistrant : NSObject
+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry;
@end

NS_ASSUME_NONNULL_END
#endif /* GeneratedPluginRegistrant_h */
''';

const String _objcPluginRegistryImplementationTemplate = '''
//
//  Generated file. Do not edit.
//

#import "GeneratedPluginRegistrant.h"

{{#plugins}}
#if __has_include(<{{name}}/{{class}}.h>)
#import <{{name}}/{{class}}.h>
#else
@import {{name}};
#endif

{{/plugins}}
@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
{{#plugins}}
  [{{prefix}}{{class}} registerWithRegistrar:[registry registrarForPlugin:@"{{prefix}}{{class}}"]];
{{/plugins}}
}

@end
''';

const String _swiftPluginRegistryTemplate = '''
//
//  Generated file. Do not edit.
//

import {{framework}}
import Foundation

{{#plugins}}
import {{name}}
{{/plugins}}

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  {{#plugins}}
  {{class}}.register(with: registry.registrar(forPlugin: "{{class}}"))
{{/plugins}}
}
''';

const String _pluginRegistrantPodspecTemplate = '''
#
# Generated file, do not edit.
#

Pod::Spec.new do |s|
  s.name             = 'FlutterPluginRegistrant'
  s.version          = '0.0.1'
  s.summary          = 'Registers plugins with your flutter app'
  s.description      = <<-DESC
Depends on all your plugins, and provides a function to register them.
                       DESC
  s.homepage         = 'https://flutter.dev'
  s.license          = { :type => 'BSD' }
  s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.{{os}}.deployment_target = '{{deploymentTarget}}'
  s.source_files =  "Classes", "Classes/**/*.{h,m}"
  s.source           = { :path => '.' }
  s.public_header_files = './Classes/**/*.h'
  s.static_framework    = true
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.dependency '{{framework}}'
  {{#plugins}}
  s.dependency '{{name}}'
  {{/plugins}}
end
''';

const String _dartPluginRegistryTemplate = '''
//
// Generated file. Do not edit.
//

// ignore_for_file: lines_longer_than_80_chars

{{#plugins}}
import 'package:{{name}}/{{file}}';
{{/plugins}}

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

// ignore: public_member_api_docs
void registerPlugins(Registrar registrar) {
{{#plugins}}
  {{class}}.registerWith(registrar);
{{/plugins}}
  registrar.registerMessageHandler();
}
''';

const String _cppPluginRegistryHeaderTemplate = '''
//
//  Generated file. Do not edit.
//

#ifndef GENERATED_PLUGIN_REGISTRANT_
#define GENERATED_PLUGIN_REGISTRANT_

#include <flutter/plugin_registry.h>

// Registers Flutter plugins.
void RegisterPlugins(flutter::PluginRegistry* registry);

#endif  // GENERATED_PLUGIN_REGISTRANT_
''';

const String _cppPluginRegistryImplementationTemplate = '''
//
//  Generated file. Do not edit.
//

#include "generated_plugin_registrant.h"

{{#plugins}}
#include <{{name}}/{{filename}}.h>
{{/plugins}}

void RegisterPlugins(flutter::PluginRegistry* registry) {
{{#plugins}}
  {{class}}RegisterWithRegistrar(
      registry->GetRegistrarForPlugin("{{class}}"));
{{/plugins}}
}
''';

const String _linuxPluginRegistryHeaderTemplate = '''
//
//  Generated file. Do not edit.
//

#ifndef GENERATED_PLUGIN_REGISTRANT_
#define GENERATED_PLUGIN_REGISTRANT_

#include <flutter_linux/flutter_linux.h>

// Registers Flutter plugins.
void fl_register_plugins(FlPluginRegistry* registry);

#endif  // GENERATED_PLUGIN_REGISTRANT_
''';

const String _linuxPluginRegistryImplementationTemplate = '''
//
//  Generated file. Do not edit.
//

#include "generated_plugin_registrant.h"

{{#plugins}}
#include <{{name}}/{{filename}}.h>
{{/plugins}}

void fl_register_plugins(FlPluginRegistry* registry) {
{{#plugins}}
  g_autoptr(FlPluginRegistrar) {{name}}_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "{{class}}");
  {{filename}}_register_with_registrar({{name}}_registrar);
{{/plugins}}
}
''';

const String _pluginCmakefileTemplate = r'''
#
# Generated file, do not edit.
#

list(APPEND FLUTTER_PLUGIN_LIST
{{#plugins}}
  {{name}}
{{/plugins}}
)

set(PLUGIN_BUNDLED_LIBRARIES)

foreach(plugin ${FLUTTER_PLUGIN_LIST})
  add_subdirectory({{pluginsDir}}/${plugin}/{{os}} plugins/${plugin})
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})
endforeach(plugin)
''';

Future<void> _writeIOSPluginRegistrant(FlutterProject project, List<Plugin> plugins) async {
  final List<Map<String, dynamic>> iosPlugins = _extractPlatformMaps(plugins, IOSPlugin.kConfigKey);
  final Map<String, dynamic> context = <String, dynamic>{
    'os': 'ios',
    'deploymentTarget': '9.0',
    'framework': 'Flutter',
    'plugins': iosPlugins,
  };
  if (project.isModule) {
    final String registryDirectory = project.ios.pluginRegistrantHost.path;
    _renderTemplateToFile(
      _pluginRegistrantPodspecTemplate,
      context,
      globals.fs.path.join(registryDirectory, 'FlutterPluginRegistrant.podspec'),
    );
  }
  _renderTemplateToFile(
    _objcPluginRegistryHeaderTemplate,
    context,
    project.ios.pluginRegistrantHeader.path,
  );
  _renderTemplateToFile(
    _objcPluginRegistryImplementationTemplate,
    context,
    project.ios.pluginRegistrantImplementation.path,
  );
}

/// The relative path from a project's main CMake file to the plugin symlink
/// directory to use in the generated plugin CMake file.
///
/// Because the generated file is checked in, it can't use absolute paths. It is
/// designed to be included by the main CMakeLists.txt, so it relative to
/// that file, rather than the generated file.
String _cmakeRelativePluginSymlinkDirectoryPath(CmakeBasedProject project) {
  final String makefileDirPath = project.cmakeFile.parent.absolute.path;
  // CMake always uses posix-style path separators, regardless of the platform.
  final path.Context cmakePathContext = path.Context(style: path.Style.posix);
  final List<String> relativePathComponents = globals.fs.path.split(globals.fs.path.relative(
    project.pluginSymlinkDirectory.absolute.path,
    from: makefileDirPath,
  ));
  return cmakePathContext.joinAll(relativePathComponents);
}

Future<void> _writeLinuxPluginFiles(FlutterProject project, List<Plugin> plugins) async {
  final List<Plugin>nativePlugins = _filterNativePlugins(plugins, LinuxPlugin.kConfigKey);
  final List<Map<String, dynamic>> linuxPlugins = _extractPlatformMaps(nativePlugins, LinuxPlugin.kConfigKey);
  final Map<String, dynamic> context = <String, dynamic>{
    'os': 'linux',
    'plugins': linuxPlugins,
    'pluginsDir': _cmakeRelativePluginSymlinkDirectoryPath(project.linux),
  };
  await _writeLinuxPluginRegistrant(project.linux.managedDirectory, context);
  await _writePluginCmakefile(project.linux.generatedPluginCmakeFile, context);
}

Future<void> _writeLinuxPluginRegistrant(Directory destination, Map<String, dynamic> templateContext) async {
  final String registryDirectory = destination.path;
  _renderTemplateToFile(
    _linuxPluginRegistryHeaderTemplate,
    templateContext,
    globals.fs.path.join(registryDirectory, 'generated_plugin_registrant.h'),
  );
  _renderTemplateToFile(
    _linuxPluginRegistryImplementationTemplate,
    templateContext,
    globals.fs.path.join(registryDirectory, 'generated_plugin_registrant.cc'),
  );
}

Future<void> _writePluginCmakefile(File destinationFile, Map<String, dynamic> templateContext) async {
  _renderTemplateToFile(
    _pluginCmakefileTemplate,
    templateContext,
    destinationFile.path,
  );
}

Future<void> _writeMacOSPluginRegistrant(FlutterProject project, List<Plugin> plugins) async {
  final List<Plugin>nativePlugins = _filterNativePlugins(plugins, MacOSPlugin.kConfigKey);
  final List<Map<String, dynamic>> macosPlugins = _extractPlatformMaps(nativePlugins, MacOSPlugin.kConfigKey);
  final Map<String, dynamic> context = <String, dynamic>{
    'os': 'macos',
    'framework': 'FlutterMacOS',
    'plugins': macosPlugins,
  };
  final String registryDirectory = project.macos.managedDirectory.path;
  _renderTemplateToFile(
    _swiftPluginRegistryTemplate,
    context,
    globals.fs.path.join(registryDirectory, 'GeneratedPluginRegistrant.swift'),
  );
}

/// Filters out Dart-only plugins, which shouldn't be added to the native generated registrants.
List<Plugin> _filterNativePlugins(List<Plugin> plugins, String platformKey) {
  return plugins.where((Plugin element) {
    final PluginPlatform plugin = element.platforms[platformKey];
    if (plugin == null) {
      return false;
    }
    if (plugin is NativeOrDartPlugin) {
      return (plugin as NativeOrDartPlugin).isNative();
    }
    // Not all platforms have the ability to create Dart-only plugins. Therefore, any plugin that doesn't
    // implement NativeOrDartPlugin is always native.
    return true;
  }).toList();
}

Future<void> _writeWindowsPluginFiles(FlutterProject project, List<Plugin> plugins) async {
  final List<Plugin> nativePlugins = _filterNativePlugins(plugins, WindowsPlugin.kConfigKey);
  final List<Map<String, dynamic>> windowsPlugins = _extractPlatformMaps(nativePlugins, WindowsPlugin.kConfigKey);
  final Map<String, dynamic> context = <String, dynamic>{
    'os': 'windows',
    'plugins': windowsPlugins,
    'pluginsDir': _cmakeRelativePluginSymlinkDirectoryPath(project.windows),
  };
  await _writeCppPluginRegistrant(project.windows.managedDirectory, context);
  await _writePluginCmakefile(project.windows.generatedPluginCmakeFile, context);
}

/// The tooling does not currently support any UWP plugins.
///
/// Always generates an empty file to satisfy the cmake template.
Future<void> _writeWindowsUwpPluginFiles(FlutterProject project, List<Plugin> plugins) async {
  final List<Plugin> nativePlugins = <Plugin>[];
  final List<Map<String, dynamic>> windowsPlugins = _extractPlatformMaps(nativePlugins, WindowsPlugin.kConfigKey);
  final Map<String, dynamic> context = <String, dynamic>{
    'os': 'windows',
    'plugins': windowsPlugins,
    'pluginsDir': _cmakeRelativePluginSymlinkDirectoryPath(project.windowsUwp),
  };
  await _writeCppPluginRegistrant(project.windowsUwp.managedDirectory, context);
  await _writePluginCmakefile(project.windowsUwp.generatedPluginCmakeFile, context);
}

Future<void> _writeCppPluginRegistrant(Directory destination, Map<String, dynamic> templateContext) async {
  final String registryDirectory = destination.path;
  _renderTemplateToFile(
    _cppPluginRegistryHeaderTemplate,
    templateContext,
    globals.fs.path.join(registryDirectory, 'generated_plugin_registrant.h'),
  );
  _renderTemplateToFile(
    _cppPluginRegistryImplementationTemplate,
    templateContext,
    globals.fs.path.join(registryDirectory, 'generated_plugin_registrant.cc'),
  );
}

Future<void> _writeWebPluginRegistrant(FlutterProject project, List<Plugin> plugins) async {
  final List<Map<String, dynamic>> webPlugins = _extractPlatformMaps(plugins, WebPlugin.kConfigKey);
  final Map<String, dynamic> context = <String, dynamic>{
    'plugins': webPlugins,
  };
  final String registryDirectory = project.web.libDirectory.path;
  final String filePath = globals.fs.path.join(registryDirectory, 'generated_plugin_registrant.dart');
  if (webPlugins.isEmpty) {
    final File file = globals.fs.file(filePath);
    return ErrorHandlingFileSystem.deleteIfExists(file);
  } else {
    _renderTemplateToFile(
      _dartPluginRegistryTemplate,
      context,
      filePath,
    );
  }
}

/// For each platform that uses them, creates symlinks within the platform
/// directory to each plugin used on that platform.
///
/// If |force| is true, the symlinks will be recreated, otherwise they will
/// be created only if missing.
///
/// This uses [project.flutterPluginsDependenciesFile], so it should only be
/// run after refreshPluginList has been run since the last plugin change.
void createPluginSymlinks(FlutterProject project, {bool force = false}) {
  Map<String, dynamic> platformPlugins;
  final String pluginFileContent = _readFileContent(project.flutterPluginsDependenciesFile);
  if (pluginFileContent != null) {
    final Map<String, dynamic> pluginInfo = json.decode(pluginFileContent) as Map<String, dynamic>;
    platformPlugins = pluginInfo[_kFlutterPluginsPluginListKey] as Map<String, dynamic>;
  }
  platformPlugins ??= <String, dynamic>{};

  if (featureFlags.isWindowsEnabled && project.windows.existsSync()) {
    _createPlatformPluginSymlinks(
      project.windows.pluginSymlinkDirectory,
      platformPlugins[project.windows.pluginConfigKey] as List<dynamic>,
      force: force,
    );
  }
  if (featureFlags.isLinuxEnabled && project.linux.existsSync()) {
    _createPlatformPluginSymlinks(
      project.linux.pluginSymlinkDirectory,
      platformPlugins[project.linux.pluginConfigKey] as List<dynamic>,
      force: force,
    );
  }
  if (featureFlags.isWindowsUwpEnabled && project.windowsUwp.existsSync()) {
    _createPlatformPluginSymlinks(
      project.windowsUwp.pluginSymlinkDirectory,
      <dynamic>[],
      force: force,
    );
  }
}

/// Handler for symlink failures which provides specific instructions for known
/// failure cases.
@visibleForTesting
void handleSymlinkException(FileSystemException e, {
  @required Platform platform,
  @required OperatingSystemUtils os,
}) {
  if (platform.isWindows && (e.osError?.errorCode ?? 0) == 1314) {
    final String versionString = RegExp(r'[\d.]+').firstMatch(os.name)?.group(0);
    final Version version = Version.parse(versionString);
    // Windows 10 14972 is the oldest version that allows creating symlinks
    // just by enabling developer mode; before that it requires running the
    // terminal as Administrator.
    // https://blogs.windows.com/windowsdeveloper/2016/12/02/symlinks-windows-10/
    final String instructions = (version != null && version >= Version(10, 0, 14972))
        ? 'Please enable Developer Mode in your system settings. Run\n'
          '  start ms-settings:developers\n'
          'to open settings.'
        : 'You must build from a terminal run as administrator.';
    throwToolExit('Building with plugins requires symlink support.\n\n' +
        instructions);
  }
}

/// Creates [symlinkDirectory] containing symlinks to each plugin listed in [platformPlugins].
///
/// If [force] is true, the directory will be created only if missing.
void _createPlatformPluginSymlinks(Directory symlinkDirectory, List<dynamic> platformPlugins, {bool force = false}) {
  if (force && symlinkDirectory.existsSync()) {
    // Start fresh to avoid stale links.
    symlinkDirectory.deleteSync(recursive: true);
  }
  symlinkDirectory.createSync(recursive: true);
  if (platformPlugins == null) {
    return;
  }
  for (final Map<String, dynamic> pluginInfo in platformPlugins.cast<Map<String, dynamic>>()) {
    final String name = pluginInfo[_kFlutterPluginsNameKey] as String;
    final String path = pluginInfo[_kFlutterPluginsPathKey] as String;
    final Link link = symlinkDirectory.childLink(name);
    if (link.existsSync()) {
      continue;
    }
    try {
      link.createSync(path);
    } on FileSystemException catch (e) {
      handleSymlinkException(e, platform: globals.platform, os: globals.os);
      rethrow;
    }
  }
}

/// Rewrites the `.flutter-plugins` file of [project] based on the plugin
/// dependencies declared in `pubspec.yaml`.
///
/// Assumes `pub get` has been executed since last change to `pubspec.yaml`.
Future<void> refreshPluginsList(
  FlutterProject project, {
  bool iosPlatform = false,
  bool macOSPlatform = false,
}) async {
  final List<Plugin> plugins = await findPlugins(project);
  // Sort the plugins by name to keep ordering stable in generated files.
  plugins.sort((Plugin left, Plugin right) => left.name.compareTo(right.name));
  // TODO(franciscojma): Remove once migration is complete.
  // Write the legacy plugin files to avoid breaking existing apps.
  final bool legacyChanged = _writeFlutterPluginsListLegacy(project, plugins);

  final bool changed = _writeFlutterPluginsList(project, plugins);
  if (changed || legacyChanged) {
    createPluginSymlinks(project, force: true);
    if (iosPlatform) {
      globals.cocoaPods.invalidatePodInstallOutput(project.ios);
    }
    if (macOSPlatform) {
      globals.cocoaPods.invalidatePodInstallOutput(project.macos);
    }
  }
}

/// Injects plugins found in `pubspec.yaml` into the platform-specific projects.
///
/// Assumes [refreshPluginsList] has been called since last change to `pubspec.yaml`.
Future<void> injectPlugins(
  FlutterProject project, {
  bool androidPlatform = false,
  bool iosPlatform = false,
  bool linuxPlatform = false,
  bool macOSPlatform = false,
  bool windowsPlatform = false,
  bool winUwpPlatform = false,
  bool webPlatform = false,
}) async {
  final List<Plugin> plugins = await findPlugins(project);
  // Sort the plugins by name to keep ordering stable in generated files.
  plugins.sort((Plugin left, Plugin right) => left.name.compareTo(right.name));
  if (androidPlatform) {
    await _writeAndroidPluginRegistrant(project, plugins);
  }
  if (iosPlatform) {
    await _writeIOSPluginRegistrant(project, plugins);
  }
  if (linuxPlatform) {
    await _writeLinuxPluginFiles(project, plugins);
  }
  if (macOSPlatform) {
    await _writeMacOSPluginRegistrant(project, plugins);
  }
  if (windowsPlatform) {
    await _writeWindowsPluginFiles(project, plugins);
  }
  if (winUwpPlatform) {
    await _writeWindowsUwpPluginFiles(project, plugins);
  }
  if (!project.isModule) {
    final List<XcodeBasedProject> darwinProjects = <XcodeBasedProject>[
      if (iosPlatform) project.ios,
      if (macOSPlatform) project.macos,
    ];
    for (final XcodeBasedProject subproject in darwinProjects) {
      if (plugins.isNotEmpty) {
        await globals.cocoaPods.setupPodfile(subproject);
      }
      /// The user may have a custom maintained Podfile that they're running `pod install`
      /// on themselves.
      else if (subproject.podfile.existsSync() && subproject.podfileLock.existsSync()) {
        globals.cocoaPods.addPodsDependencyToFlutterXcconfig(subproject);
      }
    }
  }
  if (webPlatform) {
    await _writeWebPluginRegistrant(project, plugins);
  }
}

/// Returns whether the specified Flutter [project] has any plugin dependencies.
///
/// Assumes [refreshPluginsList] has been called since last change to `pubspec.yaml`.
bool hasPlugins(FlutterProject project) {
  return _readFileContent(project.flutterPluginsFile) != null;
}
