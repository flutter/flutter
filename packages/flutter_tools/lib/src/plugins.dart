// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:mustache/mustache.dart' as mustache;
import 'package:yaml/yaml.dart';

import 'android/gradle.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'convert.dart';
import 'dart/package_map.dart';
import 'features.dart';
import 'globals.dart' as globals;
import 'macos/cocoapods.dart';
import 'platform_plugins.dart';
import 'project.dart';

void _renderTemplateToFile(String template, dynamic context, String filePath) {
  final String renderedTemplate =
     mustache.Template(template, htmlEscapeValues: false).renderString(context);
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

    final bool usesOldPluginFormat = const <String>{
      'androidPackage',
      'iosPrefix',
      'pluginClass',
    }.any(yaml.containsKey);

    final bool usesNewPluginFormat = yaml.containsKey('platforms');

    if (usesOldPluginFormat && usesNewPluginFormat) {
      const String errorMessage =
          'The flutter.plugin.platforms key cannot be used in combination with the old'
          'flutter.plugin.{androidPackage,iosPrefix,pluginClass} keys.'
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
      final dynamic value = yaml[key];
      if (value is! YamlMap) {
        return false;
      }
      final YamlMap yamlValue = value as YamlMap;
      if (yamlValue.containsKey('default_package')) {
        return false;
      }
      return !validate(yamlValue);
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

Plugin _pluginFromPubspec(String name, Uri packageRoot) {
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
    final Plugin plugin = _pluginFromPubspec(name, packageRoot);
    if (plugin != null) {
      plugins.add(plugin);
    }
  });
  return plugins;
}

/// Writes the .flutter-plugins and .flutter-plugins-dependencies files based on the list of plugins.
/// If there aren't any plugins, then the files aren't written to disk.
///
/// Finally, returns [true] if .flutter-plugins or .flutter-plugins-dependencies have changed,
/// otherwise returns [false].
bool _writeFlutterPluginsList(FlutterProject project, List<Plugin> plugins) {
  final List<dynamic> directAppDependencies = <dynamic>[];
  const String info = 'This is a generated file; do not edit or check into version control.';
  final StringBuffer flutterPluginsBuffer = StringBuffer('# $info\n');

  final Set<String> pluginNames = <String>{};
  for (final Plugin plugin in plugins) {
    pluginNames.add(plugin.name);
  }
  for (final Plugin plugin in plugins) {
    flutterPluginsBuffer.write('${plugin.name}=${escapePath(plugin.path)}\n');
    directAppDependencies.add(<String, dynamic>{
      'name': plugin.name,
      // Extract the plugin dependencies which happen to be plugins.
      'dependencies': <String>[...plugin.dependencies.where(pluginNames.contains)],
    });
  }
  final File pluginsFile = project.flutterPluginsFile;
  final String oldPluginFileContent = _readFileContent(pluginsFile);
  final String pluginFileContent = flutterPluginsBuffer.toString();
  if (pluginNames.isNotEmpty) {
    pluginsFile.writeAsStringSync(pluginFileContent, flush: true);
  } else {
    if (pluginsFile.existsSync()) {
      pluginsFile.deleteSync();
    }
  }

  final File dependenciesFile = project.flutterPluginsDependenciesFile;
  final String oldDependenciesFileContent = _readFileContent(dependenciesFile);
  final String dependenciesFileContent = json.encode(<String, dynamic>{
      '_info': '// $info',
      'dependencyGraph': directAppDependencies,
    });
  if (pluginNames.isNotEmpty) {
    dependenciesFile.writeAsStringSync(dependenciesFileContent, flush: true);
  } else {
    if (dependenciesFile.existsSync()) {
      dependenciesFile.deleteSync();
    }
  }

  return oldPluginFileContent != _readFileContent(pluginsFile)
      || oldDependenciesFileContent != _readFileContent(dependenciesFile);
}

/// Returns the contents of [File] or [null] if that file does not exist.
String _readFileContent(File file) {
  return file.existsSync() ? file.readAsStringSync() : null;
}

const String _androidPluginRegistryTemplateOldEmbedding = '''package io.flutter.plugins;

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

const String _androidPluginRegistryTemplateNewEmbedding = '''package io.flutter.plugins;

{{#androidX}}
import androidx.annotation.Keep;
import androidx.annotation.NonNull;
{{/androidX}}
{{^androidX}}
import android.support.annotation.Keep;
import android.support.annotation.NonNull;
{{/androidX}}
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
          break;
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

const String _objcPluginRegistryHeaderTemplate = '''//
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

const String _objcPluginRegistryImplementationTemplate = '''//
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

const String _swiftPluginRegistryTemplate = '''//
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

const String _dartPluginRegistryTemplate = '''//
// Generated file. Do not edit.
//

// ignore: unused_import
import 'dart:ui';

{{#plugins}}
import 'package:{{name}}/{{file}}';
{{/plugins}}

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void registerPlugins(PluginRegistry registry) {
{{#plugins}}
  {{class}}.registerWith(registry.registrarFor({{class}}));
{{/plugins}}
  registry.registerMessageHandler();
}
''';

const String _cppPluginRegistryHeaderTemplate = '''//
//  Generated file. Do not edit.
//

#ifndef GENERATED_PLUGIN_REGISTRANT_
#define GENERATED_PLUGIN_REGISTRANT_

#include <flutter/plugin_registry.h>

// Registers Flutter plugins.
void RegisterPlugins(flutter::PluginRegistry* registry);

#endif  // GENERATED_PLUGIN_REGISTRANT_
''';

const String _cppPluginRegistryImplementationTemplate = '''//
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

Future<void> _writeLinuxPluginRegistrant(FlutterProject project, List<Plugin> plugins) async {
  final List<Map<String, dynamic>> linuxPlugins = _extractPlatformMaps(plugins, LinuxPlugin.kConfigKey);
  final Map<String, dynamic> context = <String, dynamic>{
    'plugins': linuxPlugins,
  };
  await _writeCppPluginRegistrant(project.linux.managedDirectory, context);
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

Future<void> _writeWindowsPluginRegistrant(FlutterProject project, List<Plugin> plugins) async {
  final List<Map<String, dynamic>> windowsPlugins = _extractPlatformMaps(plugins, WindowsPlugin.kConfigKey);
  final Map<String, dynamic> context = <String, dynamic>{
    'plugins': windowsPlugins,
  };
  await _writeCppPluginRegistrant(project.windows.managedDirectory, context);
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

/// Rewrites the `.flutter-plugins` file of [project] based on the plugin
/// dependencies declared in `pubspec.yaml`.
///
/// If `checkProjects` is true, then plugins are only injected into directories
/// which already exist.
///
/// Assumes `pub get` has been executed since last change to `pubspec.yaml`.
void refreshPluginsList(FlutterProject project, {bool checkProjects = false}) {
  final List<Plugin> plugins = findPlugins(project);
  final bool changed = _writeFlutterPluginsList(project, plugins);
  if (changed) {
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
    await _writeLinuxPluginRegistrant(project, plugins);
  }
  if (featureFlags.isMacOSEnabled && project.macos.existsSync()) {
    await _writeMacOSPluginRegistrant(project, plugins);
  }
  if (featureFlags.isWindowsEnabled && project.windows.existsSync()) {
    await _writeWindowsPluginRegistrant(project, plugins);
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
