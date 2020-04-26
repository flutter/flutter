// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/platform_plugins.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:yaml/yaml.dart';

import '../src/common.dart';

const String _kTestPluginName = 'test_plugin_name';
const String _kTestPluginPath = 'test_plugin_path';

void main() {
  group('PluginParsing', () {
    test('Legacy Format', () {
      const String pluginYamlRaw = 'androidPackage: com.flutter.dev\n'
          'iosPrefix: FLT\n'
          'pluginClass: SamplePlugin\n';

      final YamlMap pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
      final Plugin plugin =
          Plugin.fromYaml(_kTestPluginName, _kTestPluginPath, pluginYaml, const <String>[]);

      final AndroidPlugin androidPlugin =
          plugin.platforms[AndroidPlugin.kConfigKey] as AndroidPlugin;
      final IOSPlugin iosPlugin = plugin.platforms[IOSPlugin.kConfigKey] as IOSPlugin;
      final String androidPluginClass = androidPlugin.pluginClass;
      final String iosPluginClass = iosPlugin.pluginClass;

      expect(iosPluginClass, 'SamplePlugin');
      expect(androidPluginClass, 'SamplePlugin');
      expect(iosPlugin.classPrefix, 'FLT');
      expect(androidPlugin.package, 'com.flutter.dev');
    });

    test('Multi-platform Format', () {
      const String pluginYamlRaw = 'platforms:\n'
          ' android:\n'
          '  package: com.flutter.dev\n'
          '  pluginClass: ASamplePlugin\n'
          ' ios:\n'
          '  pluginClass: ISamplePlugin\n'
          ' linux:\n'
          '  pluginClass: LSamplePlugin\n'
          ' macos:\n'
          '  pluginClass: MSamplePlugin\n'
          ' web:\n'
          '  pluginClass: WebSamplePlugin\n'
          '  fileName: web_plugin.dart\n'
          ' windows:\n'
          '  pluginClass: WinSamplePlugin\n';

      final YamlMap pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
      final Plugin plugin =
          Plugin.fromYaml(_kTestPluginName, _kTestPluginPath, pluginYaml, const <String>[]);

      final AndroidPlugin androidPlugin =
          plugin.platforms[AndroidPlugin.kConfigKey] as AndroidPlugin;
      final IOSPlugin iosPlugin = plugin.platforms[IOSPlugin.kConfigKey] as IOSPlugin;
      final LinuxPlugin linuxPlugin =
          plugin.platforms[LinuxPlugin.kConfigKey] as LinuxPlugin;
      final MacOSPlugin macOSPlugin =
          plugin.platforms[MacOSPlugin.kConfigKey] as MacOSPlugin;
      final WebPlugin webPlugin = plugin.platforms[WebPlugin.kConfigKey] as WebPlugin;
      final WindowsPlugin windowsPlugin =
          plugin.platforms[WindowsPlugin.kConfigKey] as WindowsPlugin;
      final String androidPluginClass = androidPlugin.pluginClass;
      final String iosPluginClass = iosPlugin.pluginClass;

      expect(iosPluginClass, 'ISamplePlugin');
      expect(androidPluginClass, 'ASamplePlugin');
      expect(iosPlugin.classPrefix, '');
      expect(androidPlugin.package, 'com.flutter.dev');
      expect(linuxPlugin.pluginClass, 'LSamplePlugin');
      expect(macOSPlugin.pluginClass, 'MSamplePlugin');
      expect(webPlugin.pluginClass, 'WebSamplePlugin');
      expect(webPlugin.fileName, 'web_plugin.dart');
      expect(windowsPlugin.pluginClass, 'WinSamplePlugin');
    });

    test('Unknown fields are allowed (allows some future compatibility)', () {
      const String pluginYamlRaw = 'implements: same_plugin\n' // this should be ignored by the tool
          'platforms:\n'
          ' android:\n'
          '  package: com.flutter.dev\n'
          '  pluginClass: ASamplePlugin\n'
          '  anUnknownField: ASamplePlugin\n' // this should be ignored by the tool
          ' ios:\n'
          '  pluginClass: ISamplePlugin\n'
          ' linux:\n'
          '  pluginClass: LSamplePlugin\n'
          ' macos:\n'
          '  pluginClass: MSamplePlugin\n'
          ' web:\n'
          '  pluginClass: WebSamplePlugin\n'
          '  fileName: web_plugin.dart\n'
          ' windows:\n'
          '  pluginClass: WinSamplePlugin\n';

      final dynamic pluginYaml = loadYaml(pluginYamlRaw);
      final Plugin plugin =
      Plugin.fromYaml(_kTestPluginName, _kTestPluginPath, pluginYaml as YamlMap, const <String>[]);

      final AndroidPlugin androidPlugin = plugin.platforms[AndroidPlugin.kConfigKey] as AndroidPlugin;
      final IOSPlugin iosPlugin = plugin.platforms[IOSPlugin.kConfigKey] as IOSPlugin;
      final LinuxPlugin linuxPlugin = plugin.platforms[LinuxPlugin.kConfigKey] as LinuxPlugin;
      final MacOSPlugin macOSPlugin = plugin.platforms[MacOSPlugin.kConfigKey] as MacOSPlugin;
      final WebPlugin webPlugin = plugin.platforms[WebPlugin.kConfigKey] as WebPlugin;
      final WindowsPlugin windowsPlugin = plugin.platforms[WindowsPlugin.kConfigKey] as WindowsPlugin;
      final String androidPluginClass = androidPlugin.pluginClass;
      final String iosPluginClass = iosPlugin.pluginClass;

      expect(iosPluginClass, 'ISamplePlugin');
      expect(androidPluginClass, 'ASamplePlugin');
      expect(iosPlugin.classPrefix, '');
      expect(androidPlugin.package, 'com.flutter.dev');
      expect(linuxPlugin.pluginClass, 'LSamplePlugin');
      expect(macOSPlugin.pluginClass, 'MSamplePlugin');
      expect(webPlugin.pluginClass, 'WebSamplePlugin');
      expect(webPlugin.fileName, 'web_plugin.dart');
      expect(windowsPlugin.pluginClass, 'WinSamplePlugin');
    });

    test('Allow for Dart-only plugins without a pluginClass', () {
      /// This is currently supported only on macOS, linux, Windows.
      const String pluginYamlRaw = 'implements: same_plugin\n' // this should be ignored by the tool
          'platforms:\n'
          ' linux:\n'
          '  dartPluginClass: LSamplePlugin\n'
          ' macos:\n'
          '  dartPluginClass: MSamplePlugin\n'
          ' windows:\n'
          '  dartPluginClass: WinSamplePlugin\n';

      final dynamic pluginYaml = loadYaml(pluginYamlRaw);
      final Plugin plugin =
      Plugin.fromYaml(_kTestPluginName, _kTestPluginPath, pluginYaml as YamlMap, const <String>[]);

      final LinuxPlugin linuxPlugin = plugin.platforms[LinuxPlugin.kConfigKey] as LinuxPlugin;
      final MacOSPlugin macOSPlugin = plugin.platforms[MacOSPlugin.kConfigKey] as MacOSPlugin;
      final WindowsPlugin windowsPlugin = plugin.platforms[WindowsPlugin.kConfigKey] as WindowsPlugin;

      expect(linuxPlugin.pluginClass, isNull);
      expect(macOSPlugin.pluginClass, isNull);
      expect(windowsPlugin.pluginClass, isNull);
      expect(linuxPlugin.dartPluginClass, 'LSamplePlugin');
      expect(macOSPlugin.dartPluginClass, 'MSamplePlugin');
      expect(windowsPlugin.dartPluginClass, 'WinSamplePlugin');
    });

    test('Legacy Format and Multi-Platform Format together is not allowed and error message contains plugin name', () {
      const String pluginYamlRaw = 'androidPackage: com.flutter.dev\n'
          'platforms:\n'
          ' android:\n'
          '  package: com.flutter.dev\n';

      final YamlMap pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
      expect(
        () => Plugin.fromYaml(_kTestPluginName, _kTestPluginPath, pluginYaml, const <String>[]),
        throwsToolExit(message: _kTestPluginName),
      );
    });

    test('A default_package field is allowed', () {
      const String pluginYamlRaw =
          'platforms:\n'
          ' android:\n'
          '  default_package: sample_package_android\n'
          ' ios:\n'
          '  default_package: sample_package_ios\n'
          ' linux:\n'
          '  default_package: sample_package_linux\n'
          ' macos:\n'
          '  default_package: sample_package_macos\n'
          ' web:\n'
          '  default_package: sample_package_web\n'
          ' windows:\n'
          '  default_package: sample_package_windows\n';

      final dynamic pluginYaml = loadYaml(pluginYamlRaw);
      final Plugin plugin =
      Plugin.fromYaml(_kTestPluginName, _kTestPluginPath, pluginYaml as YamlMap, const <String>[]);

      expect(plugin.platforms, <String, PluginPlatform> {});
    });

    test('error on empty plugin', () {
      const String pluginYamlRaw = '';

      final YamlMap pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
      expect(
            () => Plugin.fromYaml(_kTestPluginName, _kTestPluginPath, pluginYaml, const <String>[]),
        throwsToolExit(message: 'Invalid "plugin" specification.'),
      );
    });

    test('error on empty platforms', () {
      const String pluginYamlRaw = 'platforms:\n';

      final YamlMap pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
      expect(
            () => Plugin.fromYaml(_kTestPluginName, _kTestPluginPath, pluginYaml, const <String>[]),
        throwsToolExit(message: 'Invalid "platforms" specification.'),
      );
    });

    test('error on empty platform', () {
      const String pluginYamlRaw =
          'platforms:\n'
          ' android:\n';

      final YamlMap pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
      expect(
            () => Plugin.fromYaml(_kTestPluginName, _kTestPluginPath, pluginYaml, const <String>[]),
        throwsToolExit(message: 'Invalid "android" plugin specification.'),
      );
    });
  });
}
