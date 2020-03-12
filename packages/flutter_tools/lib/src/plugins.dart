// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import 'android/gradle.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'base/time.dart';
import 'convert.dart';
import 'dart/package_map.dart';
import 'features.dart';
import 'globals.dart' as globals;
import 'macos/cocoapods.dart';
import 'platform_plugins.dart';
import 'project.dart';
import 'windows/property_sheet.dart';
import 'windows/visual_studio_solution_utils.dart';

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
    List<String> dependencies,
  ) {
    final List<String> errors = validatePluginYaml(pluginYaml);
    if (errors.isNotEmpty) {
      throwToolExit('Invalid plugin specification $name.\n${errors.join('\n')}');
    }
    if (pluginYaml != null && pluginYaml['platforms'] != null) {
      return Plugin._fromMultiPlatformYaml(name, path, pluginYaml, dependencies);
    }
    return Plugin._fromLegacyYaml(name, path, pluginYaml, dependencies);
  }

  factory Plugin._fromMultiPlatformYaml(
    String name,
    String path,
    dynamic pluginYaml,
    List<String> dependencies,
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

    if (usesNewPluginFormat) {
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
  final dynamic pubspec = loadYaml(globals.fs.file(pubspecPath).readAsStringSync());
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
  );
}

List<Plugin> findPlugins(FlutterProject project) {
  final List<Plugin> plugins = <Plugin>[];
  Map<String, Uri> packages;
  try {
    final String packagesFile = globals.fs.path.join(
      project.directory.path,
      PackageMap.globalPackagesPath,
    );
    packages = PackageMap(packagesFile).map;
  } on FormatException catch (e) {
    globals.printTrace('Invalid .packages file: $e');
    return plugins;
  }
  packages.forEach((String name, Uri uri) {
    final Uri packageRoot = uri.resolve('..');
    final Plugin plugin = _pluginFromPackage(name, packageRoot);
    if (plugin != null) {
      plugins.add(plugin);
    }
  });
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
    if (pluginsFile.existsSync()) {
      pluginsFile.deleteSync();
      return true;
    }
    return false;
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
  result['date_created'] = systemClock.now().toString();
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
    if (pluginsFile.existsSync()) {
      pluginsFile.deleteSync();
      return true;
    }
    return false;
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

// ignore: unused_import
import 'dart:ui';

{{#plugins}}
import 'package:{{name}}/{{file}}';
{{/plugins}}

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

// ignore: public_member_api_docs
void registerPlugins(PluginRegistry registry) {
{{#plugins}}
  {{class}}.registerWith(registry.registrarFor({{class}}));
{{/plugins}}
  registry.registerMessageHandler();
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
#include <{{filename}}.h>
{{/plugins}}

void RegisterPlugins(flutter::PluginRegistry* registry) {
{{#plugins}}
  {{class}}RegisterWithRegistrar(
      registry->GetRegistrarForPlugin("{{class}}"));
{{/plugins}}
}
''';

const String _linuxPluginMakefileTemplate = '''
# Plugins to include in the build.
GENERATED_PLUGINS=\\
{{#plugins}}
\t{{name}} \\
{{/plugins}}

GENERATED_PLUGINS_DIR={{pluginsDir}}
# A plugin library name plugin name with _plugin appended.
GENERATED_PLUGIN_LIB_NAMES=\$(foreach plugin,\$(GENERATED_PLUGINS),\$(plugin)_plugin)

# Variables for use in the enclosing Makefile. Changes to these names are
# breaking changes.
PLUGIN_TARGETS=\$(GENERATED_PLUGINS)
PLUGIN_LIBRARIES=\$(foreach plugin,\$(GENERATED_PLUGIN_LIB_NAMES),\\
\t\$(OUT_DIR)/lib\$(plugin).so)
PLUGIN_LDFLAGS=\$(patsubst %,-l%,\$(GENERATED_PLUGIN_LIB_NAMES))
PLUGIN_CPPFLAGS=\$(foreach plugin,\$(GENERATED_PLUGINS),\\
\t-I\$(GENERATED_PLUGINS_DIR)/\$(plugin)/linux)

# Targets

# Implicit rules don't match phony targets, so list plugin builds explicitly.
{{#plugins}}
\$(OUT_DIR)/lib{{name}}_plugin.so: | {{name}}
{{/plugins}}

.PHONY: \$(GENERATED_PLUGINS)
\$(GENERATED_PLUGINS):
	make -C \$(GENERATED_PLUGINS_DIR)/\$@/linux \\
		OUT_DIR=\$(OUT_DIR) \\
		FLUTTER_EPHEMERAL_DIR="\$(abspath {{ephemeralDir}})"
''';

Future<void> _writeIOSPluginRegistrant(FlutterProject project, List<Plugin> plugins) async {
  final List<Map<String, dynamic>> iosPlugins = _extractPlatformMaps(plugins, IOSPlugin.kConfigKey);
  final Map<String, dynamic> context = <String, dynamic>{
    'os': 'ios',
    'deploymentTarget': '8.0',
    'framework': 'Flutter',
    'plugins': iosPlugins,
  };
  final String registryDirectory = project.ios.pluginRegistrantHost.path;
  if (project.isModule) {
    final String registryClassesDirectory = globals.fs.path.join(registryDirectory, 'Classes');
    _renderTemplateToFile(
      _pluginRegistrantPodspecTemplate,
      context,
      globals.fs.path.join(registryDirectory, 'FlutterPluginRegistrant.podspec'),
    );
    _renderTemplateToFile(
      _objcPluginRegistryHeaderTemplate,
      context,
      globals.fs.path.join(registryClassesDirectory, 'GeneratedPluginRegistrant.h'),
    );
    _renderTemplateToFile(
      _objcPluginRegistryImplementationTemplate,
      context,
      globals.fs.path.join(registryClassesDirectory, 'GeneratedPluginRegistrant.m'),
    );
  } else {
    _renderTemplateToFile(
      _objcPluginRegistryHeaderTemplate,
      context,
      globals.fs.path.join(registryDirectory, 'GeneratedPluginRegistrant.h'),
    );
    _renderTemplateToFile(
      _objcPluginRegistryImplementationTemplate,
      context,
      globals.fs.path.join(registryDirectory, 'GeneratedPluginRegistrant.m'),
    );
  }
}

Future<void> _writeLinuxPluginFiles(FlutterProject project, List<Plugin> plugins) async {
  final List<Map<String, dynamic>> linuxPlugins = _extractPlatformMaps(plugins, LinuxPlugin.kConfigKey);
  // The generated makefile is checked in, so can't use absolute paths. It is
  // included by the main makefile, so relative paths must be relative to that
  // file's directory.
  final String makefileDirPath = project.linux.makeFile.parent.absolute.path;
  final Map<String, dynamic> context = <String, dynamic>{
    'plugins': linuxPlugins,
    'ephemeralDir': globals.fs.path.relative(
      project.linux.ephemeralDirectory.absolute.path,
      from: makefileDirPath,
    ),
    'pluginsDir': globals.fs.path.relative(
      project.linux.pluginSymlinkDirectory.absolute.path,
      from: makefileDirPath,
    ),
  };
  await _writeCppPluginRegistrant(project.linux.managedDirectory, context);
  await _writeLinuxPluginMakefile(project.linux.managedDirectory, context);
}

Future<void> _writeLinuxPluginMakefile(Directory destination, Map<String, dynamic> templateContext) async {
  final String registryDirectory = destination.path;
  _renderTemplateToFile(
    _linuxPluginMakefileTemplate,
    templateContext,
    globals.fs.path.join(registryDirectory, 'generated_plugins.mk'),
  );
}

Future<void> _writeMacOSPluginRegistrant(FlutterProject project, List<Plugin> plugins) async {
  final List<Map<String, dynamic>> macosPlugins = _extractPlatformMaps(plugins, MacOSPlugin.kConfigKey);
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

Future<void> _writeWindowsPluginFiles(FlutterProject project, List<Plugin> plugins) async {
  final List<Map<String, dynamic>> windowsPlugins = _extractPlatformMaps(plugins, WindowsPlugin.kConfigKey);
  final Map<String, dynamic> context = <String, dynamic>{
    'plugins': windowsPlugins,
  };
  await _writeCppPluginRegistrant(project.windows.managedDirectory, context);
  await _writeWindowsPluginProperties(project.windows, windowsPlugins);
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

Future<void> _writeWindowsPluginProperties(WindowsProject project, List<Map<String, dynamic>> windowsPlugins) async {
  final List<String> pluginLibraryFilenames = windowsPlugins.map(
    (Map<String, dynamic> plugin) => '${plugin['name']}_plugin.lib').toList();
  // Use paths relative to the VS project directory.
  final String projectDir = project.vcprojFile.parent.path;
  final String symlinkDirPath = project.pluginSymlinkDirectory.path.substring(projectDir.length + 1);
  final List<String> pluginIncludePaths = windowsPlugins.map((Map<String, dynamic> plugin) =>
    globals.fs.path.join(symlinkDirPath, plugin['name'] as String, 'windows')).toList();
  project.generatedPluginPropertySheetFile.writeAsStringSync(PropertySheet(
    includePaths: pluginIncludePaths,
    libraryDependencies: pluginLibraryFilenames,
  ).toString());
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
    if (file.existsSync()) {
      file.deleteSync();
    }
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
      if (globals.platform.isWindows && (e.osError?.errorCode ?? 0) == 1314) {
        throwToolExit(
          'Building with plugins requires symlink support. '
          'Please enable Developer Mode in your system settings.\n\n$e'
        );
      }
      rethrow;
    }
  }
}

/// Rewrites the `.flutter-plugins` file of [project] based on the plugin
/// dependencies declared in `pubspec.yaml`.
///
/// If `checkProjects` is true, then plugins are only injected into directories
/// which already exist.
///
/// Assumes `pub get` has been executed since last change to `pubspec.yaml`.
void refreshPluginsList(FlutterProject project, {bool checkProjects = false}) {
  final List<Plugin> plugins = findPlugins(project);

  // TODO(franciscojma): Remove once migration is complete.
  // Write the legacy plugin files to avoid breaking existing apps.
  final bool legacyChanged = _writeFlutterPluginsListLegacy(project, plugins);

  final bool changed = _writeFlutterPluginsList(project, plugins);
  if (changed || legacyChanged) {
    createPluginSymlinks(project, force: true);
    if (!checkProjects || project.ios.existsSync()) {
      cocoaPods.invalidatePodInstallOutput(project.ios);
    }
    // TODO(stuartmorgan): Potentially add checkProjects once a decision has
    // made about how to handle macOS in existing projects.
    if (project.macos.existsSync()) {
      cocoaPods.invalidatePodInstallOutput(project.macos);
    }
  }
}

/// Injects plugins found in `pubspec.yaml` into the platform-specific projects.
///
/// If `checkProjects` is true, then plugins are only injected into directories
/// which already exist.
///
/// Assumes [refreshPluginsList] has been called since last change to `pubspec.yaml`.
Future<void> injectPlugins(FlutterProject project, {bool checkProjects = false}) async {
  final List<Plugin> plugins = findPlugins(project);
  if ((checkProjects && project.android.existsSync()) || !checkProjects) {
    await _writeAndroidPluginRegistrant(project, plugins);
  }
  if ((checkProjects && project.ios.existsSync()) || !checkProjects) {
    await _writeIOSPluginRegistrant(project, plugins);
  }
  // TODO(stuartmorgan): Revisit the conditions here once the plans for handling
  // desktop in existing projects are in place. For now, ignore checkProjects
  // on desktop and always treat it as true.
  if (featureFlags.isLinuxEnabled && project.linux.existsSync()) {
    await _writeLinuxPluginFiles(project, plugins);
  }
  if (featureFlags.isMacOSEnabled && project.macos.existsSync()) {
    await _writeMacOSPluginRegistrant(project, plugins);
  }
  if (featureFlags.isWindowsEnabled && project.windows.existsSync()) {
    await _writeWindowsPluginFiles(project, plugins);
    await VisualStudioSolutionUtils(project: project.windows, fileSystem: globals.fs).updatePlugins(plugins);
  }
  for (final XcodeBasedProject subproject in <XcodeBasedProject>[project.ios, project.macos]) {
    if (!project.isModule && (!checkProjects || subproject.existsSync())) {
      final CocoaPods cocoaPods = CocoaPods();
      if (plugins.isNotEmpty) {
        await cocoaPods.setupPodfile(subproject);
      }
      /// The user may have a custom maintained Podfile that they're running `pod install`
      /// on themselves.
      else if (subproject.podfile.existsSync() && subproject.podfileLock.existsSync()) {
        cocoaPods.addPodsDependencyToFlutterXcconfig(subproject);
      }
    }
  }
  if (featureFlags.isWebEnabled && project.web.existsSync()) {
    await _writeWebPluginRegistrant(project, plugins);
  }
}

/// Returns whether the specified Flutter [project] has any plugin dependencies.
///
/// Assumes [refreshPluginsList] has been called since last change to `pubspec.yaml`.
bool hasPlugins(FlutterProject project) {
  return _readFileContent(project.flutterPluginsFile) != null;
}
