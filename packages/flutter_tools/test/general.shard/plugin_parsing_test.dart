// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

      expect(plugin.pluginClass, 'SamplePlugin');
      expect(plugin.iosPrefix, 'FLT');
      expect(plugin.androidPackage, 'com.flutter.dev');
    });

    test('Multi-platform Format', () {
      const String pluginYamlRaw = 'platforms:\n'
          ' android:\n'
          '  package: com.flutter.dev\n'
          '  pluginClass: SamplePlugin\n'
          ' ios:\n'
          '  classPrefix: FLT\n'
          '  pluginClass: SamplePlugin\n';

      final dynamic pluginYaml = loadYaml(pluginYamlRaw);
      final Plugin plugin =
          Plugin.fromYaml(_kTestPluginName, _kTestPluginPath, pluginYaml);

      expect(plugin.pluginClass, 'SamplePlugin');
      expect(plugin.iosPrefix, 'FLT');
      expect(plugin.androidPackage, 'com.flutter.dev');
    });

    test('Multi-platform Format', () {
      const String pluginYamlRaw = 'platforms:\n'
          ' android:\n'
          '  package: com.flutter.dev\n'
          '  pluginClass: SamplePlugin\n'
          ' ios:\n'
          '  classPrefix: FLT\n'
          '  pluginClass: SamplePlugin\n';

      final dynamic pluginYaml = loadYaml(pluginYamlRaw);
      final Plugin plugin =
          Plugin.fromYaml(_kTestPluginName, _kTestPluginPath, pluginYaml);

      expect(plugin.pluginClass, 'SamplePlugin');
      expect(plugin.iosPrefix, 'FLT');
      expect(plugin.androidPackage, 'com.flutter.dev');
    });

    test('Multi-platform Format currently expects unique "pluginClass"', () {
      const String pluginYamlRaw = 'platforms:\n'
          ' android:\n'
          '  package: com.flutter.dev\n'
          '  pluginClass: SamplePlugin1\n'
          ' ios:\n'
          '  classPrefix: FLT\n'
          '  pluginClass: SamplePlugin2\n';

      final dynamic pluginYaml = loadYaml(pluginYamlRaw);
      expect(
          () => Plugin.fromYaml(_kTestPluginName, _kTestPluginPath, pluginYaml),
          throwsException);
    });
  });
}
