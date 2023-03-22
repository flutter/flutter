// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as path; // flutter_ignore: package_path_import
import 'package:pub_semver/pub_semver.dart' as semver;
import 'package:yaml/yaml.dart';

import 'android/gradle.dart';
import 'base/common.dart';
import 'base/error_handling_io.dart';
import 'base/file_system.dart';
import 'base/os.dart';
import 'base/platform.dart';
import 'base/template.dart';
import 'base/version.dart';
import 'cache.dart';
import 'convert.dart';
import 'dart/language_version.dart';
import 'dart/package_map.dart';
import 'features.dart';
import 'globals.dart' as globals;
import 'platform_plugins.dart';
import 'plugins.dart';
import 'project.dart';

void _renderTemplateToFile(String template, Object? context, File file, TemplateRenderer templateRenderer) {
  final String renderedTemplate = templateRenderer
    .renderString(template, context);
  file.createSync(recursive: true);
  file.writeAsStringSync(renderedTemplate);
}

Plugin? _pluginFromPackage(String name, Uri packageRoot, Set<String> appDependencies, {FileSystem? fileSystem}) {
  final FileSystem fs = fileSystem ?? globals.fs;
  final File pubspecFile = fs.file(packageRoot.resolve('pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    return null;
  }
  Object? pubspec;

  try {
    pubspec = loadYaml(pubspecFile.readAsStringSync());
  } on YamlException catch (err) {
    globals.printTrace('Failed to parse plugin manifest for $name: $err');
    // Do nothing, potentially not a plugin.
  }
  if (pubspec == null || pubspec is! YamlMap) {
    return null;
  }
  final Object? flutterConfig = pubspec['flutter'];
  if (flutterConfig == null || flutterConfig is! YamlMap || !flutterConfig.containsKey('plugin')) {
    return null;
  }
  final String? flutterConstraintText = (pubspec['environment'] as YamlMap?)?['flutter'] as String?;
  final semver.VersionConstraint? flutterConstraint = flutterConstraintText == null ?
    null : semver.VersionConstraint.parse(flutterConstraintText);
  final String packageRootPath = fs.path.fromUri(packageRoot);
  final YamlMap? dependencies = pubspec['dependencies'] as YamlMap?;
  globals.printTrace('Found plugin $name at $packageRootPath');
  return Plugin.fromYaml(
    name,
    packageRootPath,
    flutterConfig['plugin'] as YamlMap?,
    flutterConstraint,
    dependencies == null ? <String>[] : <String>[...dependencies.keys.cast<String>()],
    fileSystem: fs,
    appDependencies: appDependencies,
  );
}

Future<List<Plugin>> findPlugins(FlutterProject project, { bool throwOnError = true}) async {
  final List<Plugin> plugins = <Plugin>[];
  final FileSystem fs = project.directory.fileSystem;
  final String packagesFile = fs.path.join(
    project.directory.path,
    '.packages',
  );
  final PackageConfig packageConfig = await loadPackageConfigWithLogging(
    fs.file(packagesFile),
    logger: globals.logger,
    throwOnError: throwOnError,
  );
  for (final Package package in packageConfig.packages) {
    final Uri packageRoot = package.packageUriRoot.resolve('..');
    final Plugin? plugin = _pluginFromPackage(
      package.name,
      packageRoot,
      project.manifest.dependencies,
      fileSystem: fs
    );
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
const String _kFlutterPluginsHasNativeBuildKey = 'native_build';
const String _kFlutterPluginsSharedDarwinSource = 'shared_darwin_source';

/// Filters [plugins] to those supported by [platformKey].
List<Map<String, Object>> _filterPluginsByPlatform(List<Plugin> plugins, String platformKey) {
  final Iterable<Plugin> platformPlugins = plugins.where((Plugin p) {
    return p.platforms.containsKey(platformKey);
  });

  final Set<String> pluginNames = platformPlugins.map((Plugin plugin) => plugin.name).toSet();
  final List<Map<String, Object>> pluginInfo = <Map<String, Object>>[];
  for (final Plugin plugin in platformPlugins) {
    // This is guaranteed to be non-null due to the `where` filter above.
    final PluginPlatform platformPlugin = plugin.platforms[platformKey]!;
    pluginInfo.add(<String, Object>{
      _kFlutterPluginsNameKey: plugin.name,
      _kFlutterPluginsPathKey: globals.fsUtils.escapePath(plugin.path),
      if (platformPlugin is DarwinPlugin && (platformPlugin as DarwinPlugin).sharedDarwinSource)
        _kFlutterPluginsSharedDarwinSource: (platformPlugin as DarwinPlugin).sharedDarwinSource,
      if (platformPlugin is NativeOrDartPlugin)
        _kFlutterPluginsHasNativeBuildKey: (platformPlugin as NativeOrDartPlugin).hasMethodChannel() || (platformPlugin as NativeOrDartPlugin).hasFfi(),
      _kFlutterPluginsDependenciesKey: <String>[...plugin.dependencies.where(pluginNames.contains)],
    });
  }
  return pluginInfo;
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
///         ],
///         "native_build": true
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

  final Map<String, Object> pluginsMap = <String, Object>{};
  pluginsMap[iosKey] = _filterPluginsByPlatform(plugins, iosKey);
  pluginsMap[androidKey] = _filterPluginsByPlatform(plugins, androidKey);
  pluginsMap[macosKey] = _filterPluginsByPlatform(plugins, macosKey);
  pluginsMap[linuxKey] = _filterPluginsByPlatform(plugins, linuxKey);
  pluginsMap[windowsKey] = _filterPluginsByPlatform(plugins, windowsKey);
  pluginsMap[webKey] = _filterPluginsByPlatform(plugins, webKey);

  final Map<String, Object> result = <String, Object> {};

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
  final String? oldPluginsFileStringContent = _readFileContent(pluginsFile);
  bool pluginsChanged = true;
  if (oldPluginsFileStringContent != null) {
    pluginsChanged = oldPluginsFileStringContent.contains(pluginsMap.toString());
  }
  final String pluginFileContent = json.encode(result);
  pluginsFile.writeAsStringSync(pluginFileContent, flush: true);

  return pluginsChanged;
}

List<Object?> _createPluginLegacyDependencyGraph(List<Plugin> plugins) {
  final List<Object> directAppDependencies = <Object>[];

  final Set<String> pluginNames = plugins.map((Plugin plugin) => plugin.name).toSet();
  for (final Plugin plugin in plugins) {
    directAppDependencies.add(<String, Object>{
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
  final String? oldPluginFileContent = _readFileContent(pluginsFile);
  final String pluginFileContent = flutterPluginsBuffer.toString();
  pluginsFile.writeAsStringSync(pluginFileContent, flush: true);

  return oldPluginFileContent != _readFileContent(pluginsFile);
}

/// Returns the contents of [File] or [null] if that file does not exist.
String? _readFileContent(File file) {
  return file.existsSync() ? file.readAsStringSync() : null;
}

const String _androidPluginRegistryTemplateOldEmbedding = '''
package io.flutter.plugins;

import io.flutter.plugin.common.PluginRegistry;
{{#methodChannelPlugins}}
import {{package}}.{{class}};
{{/methodChannelPlugins}}

/**
 * Generated file. Do not edit.
 */
public final class GeneratedPluginRegistrant {
  public static void registerWith(PluginRegistry registry) {
    if (alreadyRegisteredWith(registry)) {
      return;
    }
{{#methodChannelPlugins}}
    {{class}}.registerWith(registry.registrarFor("{{package}}.{{class}}"));
{{/methodChannelPlugins}}
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
import io.flutter.Log;

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
  private static final String TAG = "GeneratedPluginRegistrant";
  public static void registerWith(@NonNull FlutterEngine flutterEngine) {
{{#needsShim}}
    ShimPluginRegistry shimPluginRegistry = new ShimPluginRegistry(flutterEngine);
{{/needsShim}}
{{#methodChannelPlugins}}
  {{#supportsEmbeddingV2}}
    try {
      flutterEngine.getPlugins().add(new {{package}}.{{class}}());
    } catch(Exception e) {
      Log.e(TAG, "Error registering plugin {{name}}, {{package}}.{{class}}", e);
    }
  {{/supportsEmbeddingV2}}
  {{^supportsEmbeddingV2}}
    {{#supportsEmbeddingV1}}
    try {
      {{package}}.{{class}}.registerWith(shimPluginRegistry.registrarFor("{{package}}.{{class}}"));
    } catch(Exception e) {
      Log.e(TAG, "Error registering plugin {{name}}, {{package}}.{{class}}", e);
    }
    {{/supportsEmbeddingV1}}
  {{/supportsEmbeddingV2}}
{{/methodChannelPlugins}}
  }
}
''';

List<Map<String, Object?>> _extractPlatformMaps(List<Plugin> plugins, String type) {
  final List<Map<String, Object?>> pluginConfigs = <Map<String, Object?>>[];
  for (final Plugin p in plugins) {
    final PluginPlatform? platformPlugin = p.platforms[type];
    if (platformPlugin != null) {
      pluginConfigs.add(platformPlugin.toMap());
    }
  }
  return pluginConfigs;
}

/// Returns the version of the Android embedding that the current
/// [project] is using.
AndroidEmbeddingVersion _getAndroidEmbeddingVersion(FlutterProject project) {
  return project.android.getEmbeddingVersion();
}

Future<void> _writeAndroidPluginRegistrant(FlutterProject project, List<Plugin> plugins) async {
  final List<Plugin> methodChannelPlugins = _filterMethodChannelPlugins(plugins, AndroidPlugin.kConfigKey);
  final List<Map<String, Object?>> androidPlugins = _extractPlatformMaps(methodChannelPlugins, AndroidPlugin.kConfigKey);

  final Map<String, Object> templateContext = <String, Object>{
    'methodChannelPlugins': androidPlugins,
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

      final List<String> pluginsUsingV1 = <String>[];
      for (final Map<String, Object?> plugin in androidPlugins) {
        final bool supportsEmbeddingV1 = (plugin['supportsEmbeddingV1'] as bool?) ?? false;
        final bool supportsEmbeddingV2 = (plugin['supportsEmbeddingV2'] as bool?) ?? false;
        if (supportsEmbeddingV1 && !supportsEmbeddingV2) {
          templateContext['needsShim'] = true;
          if (plugin['name'] != null) {
            pluginsUsingV1.add(plugin['name']! as String);
          }
        }
      }
      if (pluginsUsingV1.length > 1) {
        globals.printWarning(
          'The plugins `${pluginsUsingV1.join(', ')}` use a deprecated version of the Android embedding.\n'
          'To avoid unexpected runtime failures, or future build failures, try to see if these plugins '
          'support the Android V2 embedding. Otherwise, consider removing them since a future release '
          'of Flutter will remove these deprecated APIs.\n'
          'If you are plugin author, take a look at the docs for migrating the plugin to the V2 embedding: '
          'https://flutter.dev/go/android-plugin-migration.'
        );
      } else if (pluginsUsingV1.isNotEmpty) {
        globals.printWarning(
          'The plugin `${pluginsUsingV1.first}` uses a deprecated version of the Android embedding.\n'
          'To avoid unexpected runtime failures, or future build failures, try to see if this plugin '
          'supports the Android V2 embedding. Otherwise, consider removing it since a future release '
          'of Flutter will remove these deprecated APIs.\n'
          'If you are plugin author, take a look at the docs for migrating the plugin to the V2 embedding: '
          'https://flutter.dev/go/android-plugin-migration.'
        );
      }
      templateContent = _androidPluginRegistryTemplateNewEmbedding;
      break;
    case AndroidEmbeddingVersion.v1:
      globals.printWarning(
        'This app is using a deprecated version of the Android embedding.\n'
        'To avoid unexpected runtime failures, or future build failures, try to migrate this '
        'app to the V2 embedding.\n'
        'Take a look at the docs for migrating an app: https://github.com/flutter/flutter/wiki/Upgrading-pre-1.12-Android-projects'
      );
      for (final Map<String, Object?> plugin in androidPlugins) {
        final bool supportsEmbeddingV1 = (plugin['supportsEmbeddingV1'] as bool?) ?? false;
        final bool supportsEmbeddingV2 = (plugin['supportsEmbeddingV2'] as bool?) ?? false;
        if (!supportsEmbeddingV1 && supportsEmbeddingV2) {
          throwToolExit(
            'The plugin `${plugin['name']}` requires your app to be migrated to '
            'the Android embedding v2. Follow the steps on the migration doc above '
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
    globals.fs.file(registryPath),
    globals.templateRenderer,
  );
}

const String _objcPluginRegistryHeaderTemplate = '''
//
//  Generated file. Do not edit.
//

// clang-format off

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

// clang-format off

#import "GeneratedPluginRegistrant.h"

{{#methodChannelPlugins}}
#if __has_include(<{{name}}/{{class}}.h>)
#import <{{name}}/{{class}}.h>
#else
@import {{name}};
#endif

{{/methodChannelPlugins}}
@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
{{#methodChannelPlugins}}
  [{{prefix}}{{class}} registerWithRegistrar:[registry registrarForPlugin:@"{{prefix}}{{class}}"]];
{{/methodChannelPlugins}}
}

@end
''';

const String _swiftPluginRegistryTemplate = '''
//
//  Generated file. Do not edit.
//

import {{framework}}
import Foundation

{{#methodChannelPlugins}}
import {{name}}
{{/methodChannelPlugins}}

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  {{#methodChannelPlugins}}
  {{class}}.register(with: registry.registrar(forPlugin: "{{class}}"))
{{/methodChannelPlugins}}
}
''';

const String _pluginRegistrantPodspecTemplate = '''
#
# Generated file, do not edit.
#

Pod::Spec.new do |s|
  s.name             = 'FlutterPluginRegistrant'
  s.version          = '0.0.1'
  s.summary          = 'Registers plugins with your Flutter app'
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
  {{#methodChannelPlugins}}
  s.dependency '{{name}}'
  {{/methodChannelPlugins}}
end
''';

const String _noopDartPluginRegistryTemplate = '''
// Flutter web plugin registrant file.
//
// Generated file. Do not edit.
//

// ignore_for_file: type=lint

void registerPlugins() {}
''';

const String _dartPluginRegistryTemplate = '''
// Flutter web plugin registrant file.
//
// Generated file. Do not edit.
//

// @dart = 2.13
// ignore_for_file: type=lint

{{#methodChannelPlugins}}
import 'package:{{name}}/{{file}}';
{{/methodChannelPlugins}}
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void registerPlugins([final Registrar? pluginRegistrar]) {
  final Registrar registrar = pluginRegistrar ?? webPluginRegistrar;
{{#methodChannelPlugins}}
  {{class}}.registerWith(registrar);
{{/methodChannelPlugins}}
  registrar.registerMessageHandler();
}
''';

const String _cppPluginRegistryHeaderTemplate = '''
//
//  Generated file. Do not edit.
//

// clang-format off

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

// clang-format off

#include "generated_plugin_registrant.h"

{{#methodChannelPlugins}}
#include <{{name}}/{{filename}}.h>
{{/methodChannelPlugins}}

void RegisterPlugins(flutter::PluginRegistry* registry) {
{{#methodChannelPlugins}}
  {{class}}RegisterWithRegistrar(
      registry->GetRegistrarForPlugin("{{class}}"));
{{/methodChannelPlugins}}
}
''';

const String _linuxPluginRegistryHeaderTemplate = '''
//
//  Generated file. Do not edit.
//

// clang-format off

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

// clang-format off

#include "generated_plugin_registrant.h"

{{#methodChannelPlugins}}
#include <{{name}}/{{filename}}.h>
{{/methodChannelPlugins}}

void fl_register_plugins(FlPluginRegistry* registry) {
{{#methodChannelPlugins}}
  g_autoptr(FlPluginRegistrar) {{name}}_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "{{class}}");
  {{filename}}_register_with_registrar({{name}}_registrar);
{{/methodChannelPlugins}}
}
''';

const String _pluginCmakefileTemplate = r'''
#
# Generated file, do not edit.
#

list(APPEND FLUTTER_PLUGIN_LIST
{{#methodChannelPlugins}}
  {{name}}
{{/methodChannelPlugins}}
)

list(APPEND FLUTTER_FFI_PLUGIN_LIST
{{#ffiPlugins}}
  {{name}}
{{/ffiPlugins}}
)

set(PLUGIN_BUNDLED_LIBRARIES)

foreach(plugin ${FLUTTER_PLUGIN_LIST})
  add_subdirectory({{pluginsDir}}/${plugin}/{{os}} plugins/${plugin})
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})
endforeach(plugin)

foreach(ffi_plugin ${FLUTTER_FFI_PLUGIN_LIST})
  add_subdirectory({{pluginsDir}}/${ffi_plugin}/{{os}} plugins/${ffi_plugin})
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${ffi_plugin}_bundled_libraries})
endforeach(ffi_plugin)
''';

const String _dartPluginRegisterWith = r'''
      try {
        {{dartClass}}.registerWith();
      } catch (err) {
        print(
          '`{{pluginName}}` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
        rethrow;
      }
''';

// TODO(egarciad): Evaluate merging the web and non-web plugin registry templates.
// https://github.com/flutter/flutter/issues/80406
const String _dartPluginRegistryForNonWebTemplate = '''
//
// Generated file. Do not edit.
// This file is generated from template in file `flutter_tools/lib/src/flutter_plugins.dart`.
//

// @dart = {{dartLanguageVersion}}

import 'dart:io'; // flutter_ignore: dart_io_import.
{{#android}}
import 'package:{{pluginName}}/{{pluginName}}.dart';
{{/android}}
{{#ios}}
import 'package:{{pluginName}}/{{pluginName}}.dart';
{{/ios}}
{{#linux}}
import 'package:{{pluginName}}/{{pluginName}}.dart';
{{/linux}}
{{#macos}}
import 'package:{{pluginName}}/{{pluginName}}.dart';
{{/macos}}
{{#windows}}
import 'package:{{pluginName}}/{{pluginName}}.dart';
{{/windows}}

@pragma('vm:entry-point')
class _PluginRegistrant {

  @pragma('vm:entry-point')
  static void register() {
    if (Platform.isAndroid) {
      {{#android}}
$_dartPluginRegisterWith
      {{/android}}
    } else if (Platform.isIOS) {
      {{#ios}}
$_dartPluginRegisterWith
      {{/ios}}
    } else if (Platform.isLinux) {
      {{#linux}}
$_dartPluginRegisterWith
      {{/linux}}
    } else if (Platform.isMacOS) {
      {{#macos}}
$_dartPluginRegisterWith
      {{/macos}}
    } else if (Platform.isWindows) {
      {{#windows}}
$_dartPluginRegisterWith
      {{/windows}}
    }
  }
}
''';

Future<void> _writeIOSPluginRegistrant(FlutterProject project, List<Plugin> plugins) async {
  final List<Plugin> methodChannelPlugins = _filterMethodChannelPlugins(plugins, IOSPlugin.kConfigKey);
  final List<Map<String, Object?>> iosPlugins = _extractPlatformMaps(methodChannelPlugins, IOSPlugin.kConfigKey);
  final Map<String, Object> context = <String, Object>{
    'os': 'ios',
    'deploymentTarget': '11.0',
    'framework': 'Flutter',
    'methodChannelPlugins': iosPlugins,
  };
  if (project.isModule) {
    final Directory registryDirectory = project.ios.pluginRegistrantHost;
    _renderTemplateToFile(
      _pluginRegistrantPodspecTemplate,
      context,
      registryDirectory.childFile('FlutterPluginRegistrant.podspec'),
      globals.templateRenderer,
    );
  }
  _renderTemplateToFile(
    _objcPluginRegistryHeaderTemplate,
    context,
    project.ios.pluginRegistrantHeader,
    globals.templateRenderer,
  );
  _renderTemplateToFile(
    _objcPluginRegistryImplementationTemplate,
    context,
    project.ios.pluginRegistrantImplementation,
    globals.templateRenderer,
  );
}

/// The relative path from a project's main CMake file to the plugin symlink
/// directory to use in the generated plugin CMake file.
///
/// Because the generated file is checked in, it can't use absolute paths. It is
/// designed to be included by the main CMakeLists.txt, so it relative to
/// that file, rather than the generated file.
String _cmakeRelativePluginSymlinkDirectoryPath(CmakeBasedProject project) {
  final FileSystem fileSystem = project.pluginSymlinkDirectory.fileSystem;
  final String makefileDirPath = project.cmakeFile.parent.absolute.path;
  // CMake always uses posix-style path separators, regardless of the platform.
  final path.Context cmakePathContext = path.Context(style: path.Style.posix);
  final List<String> relativePathComponents = fileSystem.path.split(fileSystem.path.relative(
    project.pluginSymlinkDirectory.absolute.path,
    from: makefileDirPath,
  ));
  return cmakePathContext.joinAll(relativePathComponents);
}

Future<void> _writeLinuxPluginFiles(FlutterProject project, List<Plugin> plugins) async {
  final List<Plugin> methodChannelPlugins = _filterMethodChannelPlugins(plugins, LinuxPlugin.kConfigKey);
  final List<Map<String, Object?>> linuxMethodChannelPlugins = _extractPlatformMaps(methodChannelPlugins, LinuxPlugin.kConfigKey);
  final List<Plugin> ffiPlugins = _filterFfiPlugins(plugins, LinuxPlugin.kConfigKey)..removeWhere(methodChannelPlugins.contains);
  final List<Map<String, Object?>> linuxFfiPlugins = _extractPlatformMaps(ffiPlugins, LinuxPlugin.kConfigKey);
  final Map<String, Object> context = <String, Object>{
    'os': 'linux',
    'methodChannelPlugins': linuxMethodChannelPlugins,
    'ffiPlugins': linuxFfiPlugins,
    'pluginsDir': _cmakeRelativePluginSymlinkDirectoryPath(project.linux),
  };
  await _writeLinuxPluginRegistrant(project.linux.managedDirectory, context);
  await _writePluginCmakefile(project.linux.generatedPluginCmakeFile, context, globals.templateRenderer);
}

Future<void> _writeLinuxPluginRegistrant(Directory destination, Map<String, Object> templateContext) async {
  _renderTemplateToFile(
    _linuxPluginRegistryHeaderTemplate,
    templateContext,
    destination.childFile('generated_plugin_registrant.h'),
    globals.templateRenderer,
  );
  _renderTemplateToFile(
    _linuxPluginRegistryImplementationTemplate,
    templateContext,
    destination.childFile('generated_plugin_registrant.cc'),
    globals.templateRenderer,
  );
}

Future<void> _writePluginCmakefile(File destinationFile, Map<String, Object> templateContext, TemplateRenderer templateRenderer) async {
  _renderTemplateToFile(
    _pluginCmakefileTemplate,
    templateContext,
    destinationFile,
    templateRenderer,
  );
}

Future<void> _writeMacOSPluginRegistrant(FlutterProject project, List<Plugin> plugins) async {
  final List<Plugin> methodChannelPlugins = _filterMethodChannelPlugins(plugins, MacOSPlugin.kConfigKey);
  final List<Map<String, Object?>> macosMethodChannelPlugins = _extractPlatformMaps(methodChannelPlugins, MacOSPlugin.kConfigKey);
  final Map<String, Object> context = <String, Object>{
    'os': 'macos',
    'framework': 'FlutterMacOS',
    'methodChannelPlugins': macosMethodChannelPlugins,
  };
  _renderTemplateToFile(
    _swiftPluginRegistryTemplate,
    context,
    project.macos.managedDirectory.childFile('GeneratedPluginRegistrant.swift'),
    globals.templateRenderer,
  );
}

/// Filters out any plugins that don't use method channels, and thus shouldn't be added to the native generated registrants.
List<Plugin> _filterMethodChannelPlugins(List<Plugin> plugins, String platformKey) {
  return plugins.where((Plugin element) {
    final PluginPlatform? plugin = element.platforms[platformKey];
    if (plugin == null) {
      return false;
    }
    if (plugin is NativeOrDartPlugin) {
      return (plugin as NativeOrDartPlugin).hasMethodChannel();
    }
    // Not all platforms have the ability to create Dart-only plugins. Therefore, any plugin that doesn't
    // implement NativeOrDartPlugin is always native.
    return true;
  }).toList();
}

/// Filters out Dart-only and method channel plugins.
///
/// FFI plugins do not need native code registration, but their binaries need to be bundled.
List<Plugin> _filterFfiPlugins(List<Plugin> plugins, String platformKey) {
  return plugins.where((Plugin element) {
    final PluginPlatform? plugin = element.platforms[platformKey];
    if (plugin == null) {
      return false;
    }
    if (plugin is NativeOrDartPlugin) {
      final NativeOrDartPlugin plugin_ = plugin as NativeOrDartPlugin;
      return plugin_.hasFfi();
    }
    return false;
  }).toList();
}

/// Returns only the plugins with the given platform variant.
List<Plugin> _filterPluginsByVariant(List<Plugin> plugins, String platformKey, PluginPlatformVariant variant) {
  return plugins.where((Plugin element) {
    final PluginPlatform? platformPlugin = element.platforms[platformKey];
    if (platformPlugin == null) {
      return false;
    }
    assert(platformPlugin is VariantPlatformPlugin);
    return (platformPlugin as VariantPlatformPlugin).supportedVariants.contains(variant);
  }).toList();
}

@visibleForTesting
Future<void> writeWindowsPluginFiles(FlutterProject project, List<Plugin> plugins, TemplateRenderer templateRenderer) async {
  final List<Plugin> methodChannelPlugins = _filterMethodChannelPlugins(plugins, WindowsPlugin.kConfigKey);
  final List<Plugin> win32Plugins = _filterPluginsByVariant(methodChannelPlugins, WindowsPlugin.kConfigKey, PluginPlatformVariant.win32);
  final List<Map<String, Object?>> windowsMethodChannelPlugins = _extractPlatformMaps(win32Plugins, WindowsPlugin.kConfigKey);
  final List<Plugin> ffiPlugins = _filterFfiPlugins(plugins, WindowsPlugin.kConfigKey)..removeWhere(methodChannelPlugins.contains);
  final List<Map<String, Object?>> windowsFfiPlugins = _extractPlatformMaps(ffiPlugins, WindowsPlugin.kConfigKey);
  final Map<String, Object> context = <String, Object>{
    'os': 'windows',
    'methodChannelPlugins': windowsMethodChannelPlugins,
    'ffiPlugins': windowsFfiPlugins,
    'pluginsDir': _cmakeRelativePluginSymlinkDirectoryPath(project.windows),
  };
  await _writeCppPluginRegistrant(project.windows.managedDirectory, context, templateRenderer);
  await _writePluginCmakefile(project.windows.generatedPluginCmakeFile, context, templateRenderer);
}

Future<void> _writeCppPluginRegistrant(Directory destination, Map<String, Object> templateContext, TemplateRenderer templateRenderer) async {
  _renderTemplateToFile(
    _cppPluginRegistryHeaderTemplate,
    templateContext,
    destination.childFile('generated_plugin_registrant.h'),
    templateRenderer,
  );
  _renderTemplateToFile(
    _cppPluginRegistryImplementationTemplate,
    templateContext,
    destination.childFile('generated_plugin_registrant.cc'),
    templateRenderer,
  );
}

Future<void> _writeWebPluginRegistrant(FlutterProject project, List<Plugin> plugins, Directory destination) async {
  final List<Map<String, Object?>> webPlugins = _extractPlatformMaps(plugins, WebPlugin.kConfigKey);
  final Map<String, Object> context = <String, Object>{
    'methodChannelPlugins': webPlugins,
  };

  final File pluginFile = destination.childFile('web_plugin_registrant.dart');

  final String template = webPlugins.isEmpty ? _noopDartPluginRegistryTemplate : _dartPluginRegistryTemplate;

  _renderTemplateToFile(
    template,
    context,
    pluginFile,
    globals.templateRenderer,
  );
}

/// For each platform that uses them, creates symlinks within the platform
/// directory to each plugin used on that platform.
///
/// If |force| is true, the symlinks will be recreated, otherwise they will
/// be created only if missing.
///
/// This uses [project.flutterPluginsDependenciesFile], so it should only be
/// run after refreshPluginList has been run since the last plugin change.
void createPluginSymlinks(FlutterProject project, {bool force = false, @visibleForTesting FeatureFlags? featureFlagsOverride}) {
  final FeatureFlags localFeatureFlags = featureFlagsOverride ?? featureFlags;
  Map<String, Object?>? platformPlugins;
  final String? pluginFileContent = _readFileContent(project.flutterPluginsDependenciesFile);
  if (pluginFileContent != null) {
    final Map<String, Object?>? pluginInfo = json.decode(pluginFileContent) as Map<String, Object?>?;
    platformPlugins = pluginInfo?[_kFlutterPluginsPluginListKey] as Map<String, Object?>?;
  }
  platformPlugins ??= <String, Object?>{};

  if (localFeatureFlags.isWindowsEnabled && project.windows.existsSync()) {
    _createPlatformPluginSymlinks(
      project.windows.pluginSymlinkDirectory,
      platformPlugins[project.windows.pluginConfigKey] as List<Object?>?,
      force: force,
    );
  }
  if (localFeatureFlags.isLinuxEnabled && project.linux.existsSync()) {
    _createPlatformPluginSymlinks(
      project.linux.pluginSymlinkDirectory,
      platformPlugins[project.linux.pluginConfigKey] as List<Object?>?,
      force: force,
    );
  }
}

/// Handler for symlink failures which provides specific instructions for known
/// failure cases.
@visibleForTesting
void handleSymlinkException(FileSystemException e, {
  required Platform platform,
  required OperatingSystemUtils os,
  required String destination,
  required String source,
}) {
  if (platform.isWindows) {
    // ERROR_ACCESS_DENIED
    if (e.osError?.errorCode == 5) {
      throwToolExit(
        'ERROR_ACCESS_DENIED file system exception thrown while trying to '
        'create a symlink from $source to $destination',
      );
    }
    // ERROR_PRIVILEGE_NOT_HELD, user cannot symlink
    if (e.osError?.errorCode == 1314) {
      final String? versionString = RegExp(r'[\d.]+').firstMatch(os.name)?.group(0);
      final Version? version = Version.parse(versionString);
      // Windows 10 14972 is the oldest version that allows creating symlinks
      // just by enabling developer mode; before that it requires running the
      // terminal as Administrator.
      // https://blogs.windows.com/windowsdeveloper/2016/12/02/symlinks-windows-10/
      final String instructions = (version != null && version >= Version(10, 0, 14972))
          ? 'Please enable Developer Mode in your system settings. Run\n'
            '  start ms-settings:developers\n'
            'to open settings.'
          : 'You must build from a terminal run as administrator.';
      throwToolExit('Building with plugins requires symlink support.\n\n$instructions');
    }
  }
}

/// Creates [symlinkDirectory] containing symlinks to each plugin listed in [platformPlugins].
///
/// If [force] is true, the directory will be created only if missing.
void _createPlatformPluginSymlinks(Directory symlinkDirectory, List<Object?>? platformPlugins, {bool force = false}) {
  if (force && symlinkDirectory.existsSync()) {
    // Start fresh to avoid stale links.
    symlinkDirectory.deleteSync(recursive: true);
  }
  symlinkDirectory.createSync(recursive: true);
  if (platformPlugins == null) {
    return;
  }
  for (final Map<String, Object?> pluginInfo in platformPlugins.cast<Map<String, Object?>>()) {
    final String name = pluginInfo[_kFlutterPluginsNameKey]! as String;
    final String path = pluginInfo[_kFlutterPluginsPathKey]! as String;
    final Link link = symlinkDirectory.childLink(name);
    if (link.existsSync()) {
      continue;
    }
    try {
      link.createSync(path);
    } on FileSystemException catch (e) {
      handleSymlinkException(
        e,
        platform: globals.platform,
        os: globals.os,
        destination: 'dest',
        source: 'source',
      );
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
      globals.cocoaPods?.invalidatePodInstallOutput(project.ios);
    }
    if (macOSPlatform) {
      globals.cocoaPods?.invalidatePodInstallOutput(project.macos);
    }
  }
}

/// Injects plugins found in `pubspec.yaml` into the platform-specific projects
/// only at build-time.
///
/// This method is similar to [injectPlugins], but used only for platforms where
/// the plugin files are not required when the app is created (currently: Web).
///
/// This method will create files in the temporary flutter build directory
/// specified by `destination`.
///
/// In the Web platform, `destination` can point to a real filesystem (`flutter build`)
/// or an in-memory filesystem (`flutter run`).
///
/// This method is also used by [WebProject.ensureReadyForPlatformSpecificTooling]
/// to inject a copy of the plugin registrant for web into .dart_tool/dartpad so
/// dartpad can get the plugin registrant without needing to build the complete
/// project. See: https://github.com/dart-lang/dart-services/pull/874
Future<void> injectBuildTimePluginFiles(
  FlutterProject project, {
  required Directory destination,
  bool webPlatform = false,
}) async {
  final List<Plugin> plugins = await findPlugins(project);
  // Sort the plugins by name to keep ordering stable in generated files.
  plugins.sort((Plugin left, Plugin right) => left.name.compareTo(right.name));
  if (webPlatform) {
    await _writeWebPluginRegistrant(project, plugins, destination);
  }
}

/// Injects plugins found in `pubspec.yaml` into the platform-specific projects.
///
/// The injected files are required by the flutter app as soon as possible, so
/// it can be built.
///
/// Files written by this method end up in platform-specific locations that are
/// configured by each [FlutterProject] subclass (except for the Web).
///
/// Web tooling uses [injectBuildTimePluginFiles] instead, which places files in the
/// current build (temp) directory, and doesn't modify the users' working copy.
///
/// Assumes [refreshPluginsList] has been called since last change to `pubspec.yaml`.
Future<void> injectPlugins(
  FlutterProject project, {
  bool androidPlatform = false,
  bool iosPlatform = false,
  bool linuxPlatform = false,
  bool macOSPlatform = false,
  bool windowsPlatform = false,
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
    await writeWindowsPluginFiles(project, plugins, globals.templateRenderer);
  }
  if (!project.isModule) {
    final List<XcodeBasedProject> darwinProjects = <XcodeBasedProject>[
      if (iosPlatform) project.ios,
      if (macOSPlatform) project.macos,
    ];
    for (final XcodeBasedProject subproject in darwinProjects) {
      if (plugins.isNotEmpty) {
        await globals.cocoaPods?.setupPodfile(subproject);
      }
      /// The user may have a custom maintained Podfile that they're running `pod install`
      /// on themselves.
      else if (subproject.podfile.existsSync() && subproject.podfileLock.existsSync()) {
        globals.cocoaPods?.addPodsDependencyToFlutterXcconfig(subproject);
      }
    }
  }
}

/// Returns whether the specified Flutter [project] has any plugin dependencies.
///
/// Assumes [refreshPluginsList] has been called since last change to `pubspec.yaml`.
bool hasPlugins(FlutterProject project) {
  return _readFileContent(project.flutterPluginsFile) != null;
}

/// Resolves the platform implementation for Dart-only plugins.
///
///   * If there is only one dependency on a package that implements the
///     frontend plugin for the current platform, use that.
///   * If there is a single direct dependency on a package that implements the
///     frontend plugin for the current platform, use that.
///   * If there is no direct dependency on a package that implements the
///     frontend plugin, but there is a default for the current platform,
///     use that.
///   * Else fail.
///
///  For more details, https://flutter.dev/go/federated-plugins.
// TODO(stuartmorgan): Expand implementation to apply to all implementations,
// not just Dart-only, per the federated plugin spec.
List<PluginInterfaceResolution> resolvePlatformImplementation(
  List<Plugin> plugins, {
  bool throwOnPluginPubspecError = true,
}) {
  final List<String> platforms = <String>[
    AndroidPlugin.kConfigKey,
    IOSPlugin.kConfigKey,
    LinuxPlugin.kConfigKey,
    MacOSPlugin.kConfigKey,
    WindowsPlugin.kConfigKey,
  ];
  final Map<String, List<PluginInterfaceResolution>> possibleResolutions
      = <String, List<PluginInterfaceResolution>>{};
  final Map<String, String> defaultImplementations = <String, String>{};
  // Generates a key for the maps above.
  String getResolutionKey({required String platform, required String packageName}) {
    return '$packageName:$platform';
  }

  bool hasPubspecError = false;
  for (final Plugin plugin in plugins) {
    for (final String platform in platforms) {
      if (plugin.platforms[platform] == null &&
          plugin.defaultPackagePlatforms[platform] == null) {
        // The plugin doesn't implement this platform.
        continue;
      }
      String? implementsPackage = plugin.implementsPackage;
      if (implementsPackage == null || implementsPackage.isEmpty) {
        final String? defaultImplementation = plugin.defaultPackagePlatforms[platform];
        final bool hasInlineDartImplementation =
          plugin.pluginDartClassPlatforms[platform] != null;
        if (defaultImplementation == null && !hasInlineDartImplementation) {
          if (throwOnPluginPubspecError) {
            globals.printError(
              "Plugin `${plugin.name}` doesn't implement a plugin interface, nor does "
              'it specify an implementation in pubspec.yaml.\n\n'
              'To set an inline implementation, use:\n'
              'flutter:\n'
              '  plugin:\n'
              '    platforms:\n'
              '      $platform:\n'
              '        $kDartPluginClass: <plugin-class>\n'
              '\n'
              'To set a default implementation, use:\n'
              'flutter:\n'
              '  plugin:\n'
              '    platforms:\n'
              '      $platform:\n'
              '        $kDefaultPackage: <plugin-implementation>\n'
              '\n'
              'To implement an interface, use:\n'
              'flutter:\n'
              '  plugin:\n'
              '    implements: <plugin-interface>'
              '\n'
            );
          }
          hasPubspecError = true;
          continue;
        }
        final String defaultImplementationKey = getResolutionKey(platform: platform, packageName: plugin.name);
        if (defaultImplementation != null) {
          defaultImplementations[defaultImplementationKey] = defaultImplementation;
          continue;
        } else {
          // An app-facing package (i.e., one with no 'implements') with an
          // inline implementation should be its own default implementation.
          // Desktop platforms originally did not work that way, and enabling
          // it unconditionally would break existing published plugins, so
          // only treat it as such if either:
          // - the platform is not desktop, or
          // - the plugin requires at least Flutter 2.11 (when this opt-in logic
          //   was added), so that existing plugins continue to work.
          // See https://github.com/flutter/flutter/issues/87862 for details.
          final bool isDesktop = platform == 'linux' || platform == 'macos' || platform == 'windows';
          final semver.VersionConstraint? flutterConstraint = plugin.flutterConstraint;
          final semver.Version? minFlutterVersion = flutterConstraint != null &&
            flutterConstraint is semver.VersionRange ? flutterConstraint.min : null;
          final bool hasMinVersionForImplementsRequirement = minFlutterVersion != null &&
            minFlutterVersion.compareTo(semver.Version(2, 11, 0)) >= 0;
          if (!isDesktop || hasMinVersionForImplementsRequirement) {
            implementsPackage = plugin.name;
            defaultImplementations[defaultImplementationKey] = plugin.name;
          } else {
            // If it doesn't meet any of the conditions, it isn't eligible for
            // auto-registration.
            continue;
          }
        }
      }
      // If there's no Dart implementation, there's nothing to register.
      if (plugin.pluginDartClassPlatforms[platform] == null ||
          plugin.pluginDartClassPlatforms[platform] == 'none') {
        continue;
      }

      // If it hasn't been skipped, it's a candidate for auto-registration, so
      // add it as a possible resolution.
      final String resolutionKey = getResolutionKey(platform: platform, packageName: implementsPackage);
      if (!possibleResolutions.containsKey(resolutionKey)) {
        possibleResolutions[resolutionKey] = <PluginInterfaceResolution>[];
      }
      possibleResolutions[resolutionKey]!.add(PluginInterfaceResolution(
        plugin: plugin,
        platform: platform,
      ));
    }
  }
  if (hasPubspecError && throwOnPluginPubspecError) {
    throwToolExit('Please resolve the errors');
  }

  // Now resolve all the possible resolutions to a single option for each
  // plugin, or throw if that's not possible.
  bool hasResolutionError = false;
  final List<PluginInterfaceResolution> finalResolution = <PluginInterfaceResolution>[];
  for (final MapEntry<String, List<PluginInterfaceResolution>> entry in possibleResolutions.entries) {
    final List<PluginInterfaceResolution> candidates = entry.value;
    // If there's only one candidate, use it.
    if (candidates.length == 1) {
      finalResolution.add(candidates.first);
      continue;
    }
    // Next, try direct dependencies of the resolving application.
    final Iterable<PluginInterfaceResolution> directDependencies = candidates.where((PluginInterfaceResolution r) {
      return r.plugin.isDirectDependency;
    });
    if (directDependencies.isNotEmpty) {
      if (directDependencies.length > 1) {
        globals.printError(
          'Plugin ${entry.key} has conflicting direct dependency implementations:\n'
          '${directDependencies.map((PluginInterfaceResolution r) => '  ${r.plugin.name}\n').join()}'
          'To fix this issue, remove all but one of these dependencies from pubspec.yaml.\n'
        );
        hasResolutionError = true;
      } else {
        finalResolution.add(directDependencies.first);
      }
      continue;
    }
    // Next, defer to the default implementation if there is one.
    final String? defaultPackageName = defaultImplementations[entry.key];
    if (defaultPackageName != null) {
      final int defaultIndex = candidates
          .indexWhere((PluginInterfaceResolution r) => r.plugin.name == defaultPackageName);
      if (defaultIndex != -1) {
        finalResolution.add(candidates[defaultIndex]);
        continue;
      }
    }
    // Otherwise, require an explicit choice.
    if (candidates.length > 1) {
      globals.printError(
        'Plugin ${entry.key} has multiple possible implementations:\n'
        '${candidates.map((PluginInterfaceResolution r) => '  ${r.plugin.name}\n').join()}'
        'To fix this issue, add one of these dependencies to pubspec.yaml.\n'
      );
      hasResolutionError = true;
      continue;
    }
  }
  if (hasResolutionError) {
    throwToolExit('Please resolve the errors');
  }
  return finalResolution;
}

/// Generates the Dart plugin registrant, which allows to bind a platform
/// implementation of a Dart only plugin to its interface.
/// The new entrypoint wraps [currentMainUri], adds the [_PluginRegistrant] class,
/// and writes the file to [newMainDart].
///
/// [mainFile] is the main entrypoint file. e.g. /<app>/lib/main.dart.
///
/// A successful run will create a new generate_main.dart file or update the existing file.
/// Throws [ToolExit] if unable to generate the file.
///
/// This method also validates each plugin's pubspec.yaml, but errors are only
/// reported if [throwOnPluginPubspecError] is [true].
///
/// For more details, see https://flutter.dev/go/federated-plugins.
Future<void> generateMainDartWithPluginRegistrant(
  FlutterProject rootProject,
  PackageConfig packageConfig,
  String currentMainUri,
  File mainFile, {
  bool throwOnPluginPubspecError = false,
}) async {
  final List<Plugin> plugins = await findPlugins(rootProject);
  final List<PluginInterfaceResolution> resolutions = resolvePlatformImplementation(
    plugins,
    throwOnPluginPubspecError: throwOnPluginPubspecError,
  );
  final LanguageVersion entrypointVersion = determineLanguageVersion(
    mainFile,
    packageConfig.packageOf(mainFile.absolute.uri),
    Cache.flutterRoot!,
  );
  final Map<String, Object> templateContext = <String, Object>{
    'mainEntrypoint': currentMainUri,
    'dartLanguageVersion': entrypointVersion.toString(),
    AndroidPlugin.kConfigKey: <Object?>[],
    IOSPlugin.kConfigKey: <Object?>[],
    LinuxPlugin.kConfigKey: <Object?>[],
    MacOSPlugin.kConfigKey: <Object?>[],
    WindowsPlugin.kConfigKey: <Object?>[],
  };
  final File newMainDart = rootProject.dartPluginRegistrant;
  if (resolutions.isEmpty) {
    try {
      if (newMainDart.existsSync()) {
        newMainDart.deleteSync();
      }
    } on FileSystemException catch (error) {
      globals.printWarning(
        'Unable to remove ${newMainDart.path}, received error: $error.\n'
        'You might need to run flutter clean.'
      );
      rethrow;
    }
    return;
  }
  for (final PluginInterfaceResolution resolution in resolutions) {
    assert(templateContext.containsKey(resolution.platform));
    (templateContext[resolution.platform] as List<Object?>?)?.add(resolution.toMap());
  }
  try {
    _renderTemplateToFile(
      _dartPluginRegistryForNonWebTemplate,
      templateContext,
      newMainDart,
      globals.templateRenderer,
    );
  } on FileSystemException catch (error) {
    globals.printError('Unable to write ${newMainDart.path}, received error: $error');
    rethrow;
  }
}
