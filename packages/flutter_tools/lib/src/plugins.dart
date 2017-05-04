// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:mustache/mustache.dart' as mustache;
import 'package:yaml/yaml.dart';

import 'base/file_system.dart';
import 'dart/package_map.dart';
import 'globals.dart';

class Plugin {
  final String name;
  final String path;
  final String pluginClass;
  final String androidPackage;

  Plugin(this.name, this.path, this.pluginClass, this.androidPackage);

  factory Plugin.fromYaml(String name, String path, dynamic pluginYaml) {
    String androidPackage;
    String pluginClass;
    if (pluginYaml != null) {
      androidPackage = pluginYaml['androidPackage'];
      pluginClass = pluginYaml['pluginClass'];
    }
    return new Plugin(name, path, pluginClass, androidPackage);
  }
}

Plugin _pluginFromPubspec(String name, Uri packageRoot) {
  final String pubspecPath = fs.path.fromUri(packageRoot.resolve('pubspec.yaml'));
  if (!fs.isFileSync(pubspecPath))
    return null;
  final dynamic pubspec = loadYaml(fs.file(pubspecPath).readAsStringSync());
  if (pubspec == null)
    return null;
  final dynamic flutterConfig = pubspec['flutter'];
  if (flutterConfig == null || !flutterConfig.containsKey('plugin'))
    return null;
  final String packageRootPath = fs.path.fromUri(packageRoot);
  printTrace('Found plugin $name at $packageRootPath');
  return new Plugin.fromYaml(name, packageRootPath, flutterConfig['plugin']);
}

List<Plugin> _findPlugins(String directory) {
  final List<Plugin> plugins = <Plugin>[];
  Map<String, Uri> packages;
  try {
    final String packagesFile = fs.path.join(directory, PackageMap.globalPackagesPath);
    packages = new PackageMap(packagesFile).map;
  } on FormatException catch(e) {
    printTrace('Invalid .packages file: $e');
    return plugins;
  }
  packages.forEach((String name, Uri uri) {
    final Uri packageRoot = uri.resolve('..');
    final Plugin plugin = _pluginFromPubspec(name, packageRoot);
    if (plugin != null)
      plugins.add(plugin);
  });
  return plugins;
}

void _writeFlutterPluginsList(String directory, List<Plugin> plugins) {
  final File pluginsProperties = fs.file(fs.path.join(directory, '.flutter-plugins'));
  final String pluginManifest =
    plugins.map((Plugin p) => '${p.name}=${escapePath(p.path)}').join('\n');
  if (pluginManifest.isNotEmpty) {
    pluginsProperties.writeAsStringSync('$pluginManifest\n');
  } else {
    if (pluginsProperties.existsSync()) {
      pluginsProperties.deleteSync();
    }
  }
}

const String _androidPluginRegistryTemplate = '''package io.flutter.plugins;

{{#plugins}}
import io.flutter.plugin.common.PluginRegistry;
import {{package}}.{{class}};
{{/plugins}}

/**
 * Generated file. Do not edit.
 */
public final class GeneratedPluginRegistrant {
  public static void registerWith(PluginRegistry registry) {
{{#plugins}}
    {{class}}.registerWith(registry.registrarFor("{{package}}.{{class}}"));
{{/plugins}}
  }
}
''';

void _writeAndroidPluginRegistry(String directory, List<Plugin> plugins) {
  final List<Map<String, dynamic>> androidPlugins = plugins
      .where((Plugin p) => p.androidPackage != null && p.pluginClass != null)
      .map((Plugin p) => <String, dynamic>{
          'name': p.name,
          'package': p.androidPackage,
          'class': p.pluginClass,
      })
      .toList();
  final Map<String, dynamic> context = <String, dynamic>{
    'plugins': androidPlugins,
  };

  final String pluginRegistry =
      new mustache.Template(_androidPluginRegistryTemplate).renderString(context);
  final String javaSourcePath = fs.path.join(directory, 'android', 'app', 'src', 'main', 'java');
  final Directory registryDirectory =
      fs.directory(fs.path.join(javaSourcePath, 'io', 'flutter', 'plugins'));
  registryDirectory.createSync(recursive: true);
  final File registryFile = registryDirectory.childFile('GeneratedPluginRegistrant.java');
  registryFile.writeAsStringSync(pluginRegistry);
}

const String _iosPluginRegistryHeaderTemplate = '''//
//  Generated file. Do not edit.
//

#ifndef GeneratedPluginRegistrant_h
#define GeneratedPluginRegistrant_h

#import <Flutter/Flutter.h>

{{#plugins}}
#import "{{class}}.h"
{{/plugins}}

@interface GeneratedPluginRegistrant : NSObject
+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry;
@end

#endif /* GeneratedPluginRegistrant_h */
''';

const String _iosPluginRegistryImplementationTemplate = '''//
//  Generated file. Do not edit.
//

#import "GeneratedPluginRegistrant.h"

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
{{#plugins}}
  [{{class}} registerWithRegistrar:[registry registrarForPlugin:@"{{class}}"]];
{{/plugins}}
}

@end
''';

void _writeIOSPluginRegistry(String directory, List<Plugin> plugins) {
  final List<Map<String, dynamic>> iosPlugins = plugins
      .where((Plugin p) => p.pluginClass != null)
      .map((Plugin p) => <String, dynamic>{
    'name': p.name,
    'class': p.pluginClass,
  }).
  toList();
  final Map<String, dynamic> context = <String, dynamic>{
    'plugins': iosPlugins,
  };

  final String pluginRegistryHeader =
      new mustache.Template(_iosPluginRegistryHeaderTemplate).renderString(context);
  final String pluginRegistryImplementation =
      new mustache.Template(_iosPluginRegistryImplementationTemplate).renderString(context);
  final Directory registryDirectory = fs.directory(fs.path.join(directory, 'ios', 'Runner'));
  registryDirectory.createSync(recursive: true);
  final File registryHeaderFile = registryDirectory.childFile('GeneratedPluginRegistrant.h');
  registryHeaderFile.writeAsStringSync(pluginRegistryHeader);
  final File registryImplementationFile = registryDirectory.childFile('GeneratedPluginRegistrant.m');
  registryImplementationFile.writeAsStringSync(pluginRegistryImplementation);

}

/// Finds Flutter plugins in the pubspec.yaml, creates platform injection
/// registries classes and add them to the build depedencies.
///
/// Returns whether any Flutter plugins are added.
bool injectPlugins({String directory}) {
  directory ??= fs.currentDirectory.path;
  final List<Plugin> plugins = _findPlugins(directory);
  _writeFlutterPluginsList(directory, plugins);
  if (fs.isDirectorySync(fs.path.join(directory, 'android')))
    _writeAndroidPluginRegistry(directory, plugins);
  if (fs.isDirectorySync(fs.path.join(directory, 'ios')))
    _writeIOSPluginRegistry(directory, plugins);
  return plugins.isNotEmpty;
}
