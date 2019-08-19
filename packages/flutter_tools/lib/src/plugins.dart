// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:mustache/mustache.dart' as mustache;
import 'package:yaml/yaml.dart';

import 'base/file_system.dart';
import 'dart/package_map.dart';
import 'features.dart';
import 'globals.dart';
import 'macos/cocoapods.dart';
import 'platform_plugins.dart';
import 'project.dart';

void _renderTemplateToFile(String template, dynamic context, String filePath) {
  final String renderedTemplate =
     mustache.Template(template).renderString(context);
  final File file = fs.file(filePath);
  file.createSync(recursive: true);
  file.writeAsStringSync(renderedTemplate);
}

class Plugin {
  Plugin({
    this.name,
    this.path,
    this.platformPlugins,
  });

  /// Parses [Plugin] specification from the provided pluginYaml.
  ///
  /// This currently supports two formats. Legacy and Multi-platform.
  /// Example of the deprecated Legacy format.
  /// flutter:
  ///  plugin:
  ///    androidPackage: io.flutter.plugins.sample
  ///    iosPrefix: FLT
  ///    pluginClass: SamplePlugin
  ///
  /// Example Multi-platform format.
  /// flutter:
  ///  plugin:
  ///    platforms:
  ///      android:
  ///        package: io.flutter.plugins.sample
  ///        pluginClass: SamplePlugin
  ///      ios:
  ///        classPrefix: FLT
  ///        pluginClass: SamplePlugin
  ///      macos:
  ///        pluginClass: SamplePlugin
  factory Plugin.fromYaml(String name, String path, dynamic pluginYaml) {
    // TODO(kaushikiska): Fail if both old and new formats are present.
    if (pluginYaml != null && pluginYaml['platforms'] != null) {
      return Plugin._fromMultiPlatformYaml(name, path, pluginYaml);
    } else {
      return Plugin._fromLegacyYaml(name, path, pluginYaml); // ignore: deprecated_member_use_from_same_package
    }
  }

  factory Plugin._fromMultiPlatformYaml(String name, String path, dynamic pluginYaml) {
    assert (pluginYaml != null && pluginYaml['platforms'] != null,
            'Invalid multi-platform plugin specification.');
    final dynamic platforms = pluginYaml['platforms'];

    final Map<String, PlatformPlugin> platformPlugins = <String, PlatformPlugin>{};

    if (platforms[AndroidPlugin.kConfigKey] != null) {
      platformPlugins[AndroidPlugin.kConfigKey] =
          AndroidPlugin.fromYaml(name, platforms[AndroidPlugin.kConfigKey]);
    }

    if (platforms[IOSPlugin.kConfigKey] != null) {
      platformPlugins[IOSPlugin.kConfigKey] =
          IOSPlugin.fromYaml(name, platforms[IOSPlugin.kConfigKey]);
    }

    if (platforms[MacOSPlugin.kConfigKey] != null) {
      platformPlugins[MacOSPlugin.kConfigKey] =
          MacOSPlugin.fromYaml(name, platforms[MacOSPlugin.kConfigKey]);
    }

    return Plugin(
      name: name,
      path: path,
      platformPlugins: platformPlugins,
    );
  }


  @deprecated
  factory Plugin._fromLegacyYaml(String name, String path, dynamic pluginYaml) {
    final Map<String, PlatformPlugin> platformPlugins = <String, PlatformPlugin>{};
    final String pluginClass = pluginYaml['pluginClass'];
    if (pluginYaml != null && pluginClass != null) {
      final String androidPackage = pluginYaml['androidPackage'];
      if (androidPackage != null) {
        platformPlugins[AndroidPlugin.kConfigKey] =
            AndroidPlugin(
              package: pluginYaml['androidPackage'],
              pluginClass: pluginClass,
            );
      }

      final String iosPrefix = pluginYaml['iosPrefix'] ?? '';
      platformPlugins[IOSPlugin.kConfigKey] =
          IOSPlugin(
            classPrefix: iosPrefix,
            pluginClass: pluginClass,
          );
    }
    return Plugin(
      name: name,
      path: path,
      platformPlugins: platformPlugins,
    );
  }

  final String name;
  final String path;
  final Map<String, PlatformPlugin> platformPlugins;
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
  return Plugin.fromYaml(name, packageRootPath, flutterConfig['plugin']);
}

List<Plugin> findPlugins(FlutterProject project) {
  final List<Plugin> plugins = <Plugin>[];
  Map<String, Uri> packages;
  try {
    final String packagesFile = fs.path.join(project.directory.path, PackageMap.globalPackagesPath);
    packages = PackageMap(packagesFile).map;
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
bool _writeFlutterPluginsList(FlutterProject project, List<Plugin> plugins) {
  final File pluginsFile = project.flutterPluginsFile;
  final String oldContents = _readFlutterPluginsList(project);
  final String pluginManifest =
      plugins.map<String>((Plugin p) => '${p.name}=${escapePath(p.path)}').join('\n');
  if (pluginManifest.isNotEmpty) {
    pluginsFile.writeAsStringSync('$pluginManifest\n', flush: true);
  } else {
    if (pluginsFile.existsSync()) {
      pluginsFile.deleteSync();
    }
  }
  final String newContents = _readFlutterPluginsList(project);
  return oldContents != newContents;
}

/// Returns the contents of the `.flutter-plugins` file in [project], or
/// null if that file does not exist.
String _readFlutterPluginsList(FlutterProject project) {
  return project.flutterPluginsFile.existsSync()
      ? project.flutterPluginsFile.readAsStringSync()
      : null;
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

List<Map<String, dynamic>> _filterPlugins(List<Plugin> plugins, String type) {
  final List<Map<String, dynamic>> pluginConfigs = <Map<String, dynamic>>[];
  for (Plugin p in plugins) {
    final PlatformPlugin platformPlugin = p.platformPlugins[type];
    if (platformPlugin != null) {
      pluginConfigs.add(platformPlugin.toMap());
    }
  }
  return pluginConfigs;
}

Future<void> _writeAndroidPluginRegistrant(FlutterProject project, List<Plugin> plugins) async {
  final List<Map<String, dynamic>> androidPlugins = _filterPlugins(plugins, AndroidPlugin.kConfigKey);
  final Map<String, dynamic> context = <String, dynamic>{
    'plugins': androidPlugins,
  };

  final String javaSourcePath = fs.path.join(
    project.android.pluginRegistrantHost.path,
    'src',
    'main',
    'java',
  );
  final String registryPath = fs.path.join(
    javaSourcePath,
    'io',
    'flutter',
    'plugins',
    'GeneratedPluginRegistrant.java',
  );
  _renderTemplateToFile(_androidPluginRegistryTemplate, context, registryPath);
}

const String _objcPluginRegistryHeaderTemplate = '''//
//  Generated file. Do not edit.
//

#ifndef GeneratedPluginRegistrant_h
#define GeneratedPluginRegistrant_h

#import <{{framework}}/{{framework}}.h>

@interface GeneratedPluginRegistrant : NSObject
+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry;
@end

#endif /* GeneratedPluginRegistrant_h */
''';

const String _objcPluginRegistryImplementationTemplate = '''//
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

const String _swiftPluginRegistryTemplate = '''//
//  Generated file. Do not edit.
//
import Foundation
import {{framework}}

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
  s.dependency '{{framework}}'
  {{#plugins}}
  s.dependency '{{name}}'
  {{/plugins}}
end
''';

Future<void> _writeIOSPluginRegistrant(FlutterProject project, List<Plugin> plugins) async {
  final List<Map<String, dynamic>> iosPlugins = _filterPlugins(plugins, IOSPlugin.kConfigKey);
  final Map<String, dynamic> context = <String, dynamic>{
    'os': 'ios',
    'deploymentTarget': '8.0',
    'framework': 'Flutter',
    'plugins': iosPlugins,
  };
  final String registryDirectory = project.ios.pluginRegistrantHost.path;
  if (project.isModule) {
    final String registryClassesDirectory = fs.path.join(registryDirectory, 'Classes');
    _renderTemplateToFile(
      _pluginRegistrantPodspecTemplate,
      context,
      fs.path.join(registryDirectory, 'FlutterPluginRegistrant.podspec'),
    );
    _renderTemplateToFile(
      _objcPluginRegistryHeaderTemplate,
      context,
      fs.path.join(registryClassesDirectory, 'GeneratedPluginRegistrant.h'),
    );
    _renderTemplateToFile(
      _objcPluginRegistryImplementationTemplate,
      context,
      fs.path.join(registryClassesDirectory, 'GeneratedPluginRegistrant.m'),
    );
  } else {
    _renderTemplateToFile(
      _objcPluginRegistryHeaderTemplate,
      context,
      fs.path.join(registryDirectory, 'GeneratedPluginRegistrant.h'),
    );
    _renderTemplateToFile(
      _objcPluginRegistryImplementationTemplate,
      context,
      fs.path.join(registryDirectory, 'GeneratedPluginRegistrant.m'),
    );
  }
}

Future<void> _writeMacOSPluginRegistrant(FlutterProject project, List<Plugin> plugins) async {
  final List<Map<String, dynamic>> macosPlugins = _filterPlugins(plugins, MacOSPlugin.kConfigKey);
  final Map<String, dynamic> context = <String, dynamic>{
    'os': 'macos',
    'framework': 'FlutterMacOS',
    'plugins': macosPlugins,
  };
  final String registryDirectory = project.macos.managedDirectory.path;
  _renderTemplateToFile(
    _swiftPluginRegistryTemplate,
    context,
    fs.path.join(registryDirectory, 'GeneratedPluginRegistrant.swift'),
  );
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
    if (checkProjects && !project.ios.existsSync()) {
      return;
    }
    cocoaPods.invalidatePodInstallOutput(project.ios);
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
  // TODO(stuartmorgan): Revisit the condition here once the plans for handling
  // desktop in existing projects are in place. For now, ignore checkProjects
  // on desktop and always treat it as true.
  if (featureFlags.isMacOSEnabled && project.macos.existsSync()) {
    await _writeMacOSPluginRegistrant(project, plugins);
  }
  for (final XcodeBasedProject subproject in <XcodeBasedProject>[project.ios, project.macos]) {
  if (!project.isModule && (!checkProjects || subproject.existsSync())) {
    final CocoaPods cocoaPods = CocoaPods();
    if (plugins.isNotEmpty) {
      cocoaPods.setupPodfile(subproject);
    }
    /// The user may have a custom maintained Podfile that they're running `pod install`
    /// on themselves.
    else if (subproject.podfile.existsSync() && subproject.podfileLock.existsSync()) {
      cocoaPods.addPodsDependencyToFlutterXcconfig(subproject);
    }
  }
  }
}

/// Returns whether the specified Flutter [project] has any plugin dependencies.
///
/// Assumes [refreshPluginsList] has been called since last change to `pubspec.yaml`.
bool hasPlugins(FlutterProject project) {
  return _readFlutterPluginsList(project) != null;
}
