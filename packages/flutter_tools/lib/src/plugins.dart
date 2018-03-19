// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:mustache/mustache.dart' as mustache;
import 'package:yaml/yaml.dart';

import 'base/file_system.dart';
import 'dart/package_map.dart';
import 'globals.dart';
import 'ios/cocoapods.dart';

class Plugin {
  final String name;
  final String path;
  final String androidPackage;
  final String iosPrefix;
  final String pluginClass;

  Plugin({
    this.name,
    this.path,
    this.androidPackage,
    this.iosPrefix,
    this.pluginClass,
  });

  factory Plugin.fromYaml(String name, String path, dynamic pluginYaml) {
    String androidPackage;
    String iosPrefix;
    String pluginClass;
    if (pluginYaml != null) {
      androidPackage = pluginYaml['androidPackage'];
      iosPrefix = pluginYaml['iosPrefix'] ?? '';
      pluginClass = pluginYaml['pluginClass'];
    }
    return new Plugin(
      name: name,
      path: path,
      androidPackage: androidPackage,
      iosPrefix: iosPrefix,
      pluginClass: pluginClass,
    );
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
  } on FormatException catch (e) {
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

/// Returns true if .flutter-plugins has changed, otherwise returns false.
bool _writeFlutterPluginsList(String directory, List<Plugin> plugins) {
  final File pluginsFile = fs.file(fs.path.join(directory, '.flutter-plugins'));
  final String oldContents = _readFlutterPluginsList(directory);
  final String pluginManifest =
      plugins.map((Plugin p) => '${p.name}=${escapePath(p.path)}').join('\n');
  if (pluginManifest.isNotEmpty) {
    pluginsFile.writeAsStringSync('$pluginManifest\n', flush: true);
  } else {
    if (pluginsFile.existsSync())
      pluginsFile.deleteSync();
  }
  final String newContents = _readFlutterPluginsList(directory);
  return oldContents != newContents;
}

/// Returns the contents of the `.flutter-plugins` file in [directory], or
/// null if that file does not exist.
String _readFlutterPluginsList(String directory) {
  final File pluginsFile = fs.file(fs.path.join(directory, '.flutter-plugins'));
  return pluginsFile.existsSync() ? pluginsFile.readAsStringSync() : null;
}

const String _androidPluginRegistryTemplate = '''package io.flutter.plugins;

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

void _writeAndroidPluginRegistrant(String directory, List<Plugin> plugins) {
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

@interface GeneratedPluginRegistrant : NSObject
+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry;
@end

#endif /* GeneratedPluginRegistrant_h */
''';

const String _iosPluginRegistryImplementationTemplate = '''//
//  Generated file. Do not edit.
//

#import "GeneratedPluginRegistrant.h"
{{#plugins}}
#import <{{name}}/{{class}}.h>
{{/plugins}}

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
{{#plugins}}
  [{{prefix}}{{class}} registerWithRegistrar:[registry registrarForPlugin:@"{{prefix}}{{class}}"]];
{{/plugins}}
}

@end
''';

void _writeIOSPluginRegistrant(String directory, List<Plugin> plugins) {
  final List<Map<String, dynamic>> iosPlugins = plugins
      .where((Plugin p) => p.pluginClass != null)
      .map((Plugin p) => <String, dynamic>{
    'name': p.name,
    'prefix': p.iosPrefix,
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

class InjectPluginsResult{
  InjectPluginsResult({
    @required this.hasPlugin,
    @required this.hasChanged,
  });
  /// True if any flutter plugin exists, otherwise false.
  final bool hasPlugin;
  /// True if plugins have changed since last build.
  final bool hasChanged;
}

/// Injects plugins found in `pubspec.yaml` into the platform-specific projects.
void injectPlugins({String directory}) {
  directory ??= fs.currentDirectory.path;
  if (fs.file(fs.path.join(directory, 'example', 'pubspec.yaml')).existsSync()) {
    // Switch to example app if in plugin project template.
    directory = fs.path.join(directory, 'example');
  }
  final List<Plugin> plugins = _findPlugins(directory);
  final bool changed = _writeFlutterPluginsList(directory, plugins);
  if (fs.isDirectorySync(fs.path.join(directory, 'android')))
    _writeAndroidPluginRegistrant(directory, plugins);
  if (fs.isDirectorySync(fs.path.join(directory, 'ios'))) {
    _writeIOSPluginRegistrant(directory, plugins);
    const CocoaPods cocoaPods = const CocoaPods();
    if (plugins.isNotEmpty)
      cocoaPods.setupPodfile(directory);
    if (changed)
      cocoaPods.invalidatePodInstallOutput(directory);
  }
}

/// Returns whether the Flutter project at the specified [directory]
/// has any plugin dependencies.
bool hasPlugins({String directory}) {
  directory ??= fs.currentDirectory.path;
  return _readFlutterPluginsList(directory) != null;
}
