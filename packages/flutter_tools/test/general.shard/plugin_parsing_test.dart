// Copyright 2019 The Chromium Authors. All rights reserved.
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

      final dynamic pluginYaml = loadYaml(pluginYamlRaw);
      final Plugin plugin =
          Plugin.fromYaml(_kTestPluginName, _kTestPluginPath, pluginYaml);

      final AndroidPlugin androidPlugin =
          plugin.platforms[AndroidPlugin.kConfigKey];
      final IOSPlugin iosPlugin = plugin.platforms[IOSPlugin.kConfigKey];
      final String androidPluginClass = androidPlugin.pluginClass;
      final String iosPluginClass = iosPlugin.pluginClass;

      expect(iosPluginClass, 'SamplePlugin');
      expect(androidPluginClass, 'SamplePlugin');
      expect(iosPlugin.classPrefix, 'FLT');
      expect(androidPlugin.package, 'com.flutter.dev');
    });

    test('Multi-platform Format', () {
      const String pluginYamlRaw = 'platforms:\n'
          ' macos:\n'
          '  pluginClass: MSamplePlugin\n'
          ' android:\n'
          '  package: com.flutter.dev\n'
          '  pluginClass: ASamplePlugin\n'
          ' ios:\n'
          '  pluginClass: ISamplePlugin\n'
          ' web:\n'
          '  pluginClass: WSamplePlugin\n'
          '  fileName: web_plugin.dart\n';

      final dynamic pluginYaml = loadYaml(pluginYamlRaw);
      final Plugin plugin =
          Plugin.fromYaml(_kTestPluginName, _kTestPluginPath, pluginYaml);

      final AndroidPlugin androidPlugin =
          plugin.platforms[AndroidPlugin.kConfigKey];
      final MacOSPlugin macOSPlugin =
          plugin.platforms[MacOSPlugin.kConfigKey];
      final IOSPlugin iosPlugin = plugin.platforms[IOSPlugin.kConfigKey];
      final WebPlugin webPlugin = plugin.platforms[WebPlugin.kConfigKey];
      final String androidPluginClass = androidPlugin.pluginClass;
      final String iosPluginClass = iosPlugin.pluginClass;

      expect(iosPluginClass, 'ISamplePlugin');
      expect(androidPluginClass, 'ASamplePlugin');
      expect(iosPlugin.classPrefix, '');
      expect(androidPlugin.package, 'com.flutter.dev');
      expect(macOSPlugin.pluginClass, 'MSamplePlugin');
      expect(webPlugin.pluginClass, 'WSamplePlugin');
      expect(webPlugin.fileName, 'web_plugin.dart');
    });
  });
}
