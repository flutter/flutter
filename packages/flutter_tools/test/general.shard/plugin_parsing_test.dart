// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/platform_plugins.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:yaml/yaml.dart';

import '../src/common.dart';

const _kTestPluginName = 'test_plugin_name';
const _kTestPluginPath = 'test_plugin_path';

void main() {
  testWithoutContext('Plugin creation from the legacy format', () {
    const pluginYamlRaw =
        'androidPackage: com.flutter.dev\n'
        'iosPrefix: FLT\n'
        'pluginClass: SamplePlugin\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    final plugin = Plugin.fromYaml(
      _kTestPluginName,
      _kTestPluginPath,
      pluginYaml,
      null,
      const <String>[],
      isDevDependency: false,
    );

    final androidPlugin = plugin.platforms[AndroidPlugin.kConfigKey]! as AndroidPlugin;
    final iosPlugin = plugin.platforms[IOSPlugin.kConfigKey]! as IOSPlugin;

    expect(iosPlugin.pluginClass, 'SamplePlugin');
    expect(iosPlugin.classPrefix, 'FLT');
    expect(iosPlugin.sharedDarwinSource, isFalse);
    expect(androidPlugin.pluginClass, 'SamplePlugin');
    expect(androidPlugin.package, 'com.flutter.dev');
  });

  testWithoutContext('Plugin creation from the multi-platform format', () {
    const pluginYamlRaw =
        'platforms:\n'
        ' android:\n'
        '  package: com.flutter.dev\n'
        '  pluginClass: ASamplePlugin\n'
        ' ios:\n'
        '  pluginClass: ISamplePlugin\n'
        '  sharedDarwinSource: true\n'
        ' linux:\n'
        '  pluginClass: LSamplePlugin\n'
        ' macos:\n'
        '  pluginClass: MSamplePlugin\n'
        '  sharedDarwinSource: true\n'
        ' web:\n'
        '  pluginClass: WebSamplePlugin\n'
        '  fileName: web_plugin.dart\n'
        ' windows:\n'
        '  pluginClass: WinSamplePlugin\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    final plugin = Plugin.fromYaml(
      _kTestPluginName,
      _kTestPluginPath,
      pluginYaml,
      null,
      const <String>[],
      isDevDependency: false,
    );

    final androidPlugin = plugin.platforms[AndroidPlugin.kConfigKey]! as AndroidPlugin;
    final iosPlugin = plugin.platforms[IOSPlugin.kConfigKey]! as IOSPlugin;
    final linuxPlugin = plugin.platforms[LinuxPlugin.kConfigKey]! as LinuxPlugin;
    final macOSPlugin = plugin.platforms[MacOSPlugin.kConfigKey]! as MacOSPlugin;
    final webPlugin = plugin.platforms[WebPlugin.kConfigKey]! as WebPlugin;
    final windowsPlugin = plugin.platforms[WindowsPlugin.kConfigKey]! as WindowsPlugin;

    expect(iosPlugin.pluginClass, 'ISamplePlugin');
    expect(iosPlugin.classPrefix, '');
    expect(iosPlugin.sharedDarwinSource, isTrue);
    expect(androidPlugin.pluginClass, 'ASamplePlugin');
    expect(androidPlugin.package, 'com.flutter.dev');
    expect(linuxPlugin.pluginClass, 'LSamplePlugin');
    expect(macOSPlugin.pluginClass, 'MSamplePlugin');
    expect(macOSPlugin.sharedDarwinSource, isTrue);
    expect(webPlugin.pluginClass, 'WebSamplePlugin');
    expect(webPlugin.fileName, 'web_plugin.dart');
    expect(windowsPlugin.pluginClass, 'WinSamplePlugin');
  });

  testWithoutContext(
    'Plugin parsing of unknown fields are allowed (allows some future compatibility)',
    () {
      const pluginYamlRaw =
          'implements: same_plugin\n' // this should be ignored by the tool
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

      final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
      final plugin = Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
      );

      final androidPlugin = plugin.platforms[AndroidPlugin.kConfigKey]! as AndroidPlugin;
      final iosPlugin = plugin.platforms[IOSPlugin.kConfigKey]! as IOSPlugin;
      final linuxPlugin = plugin.platforms[LinuxPlugin.kConfigKey]! as LinuxPlugin;
      final macOSPlugin = plugin.platforms[MacOSPlugin.kConfigKey]! as MacOSPlugin;
      final webPlugin = plugin.platforms[WebPlugin.kConfigKey]! as WebPlugin;
      final windowsPlugin = plugin.platforms[WindowsPlugin.kConfigKey]! as WindowsPlugin;

      expect(iosPlugin.pluginClass, 'ISamplePlugin');
      expect(iosPlugin.classPrefix, '');
      expect(iosPlugin.sharedDarwinSource, isFalse);
      expect(androidPlugin.pluginClass, 'ASamplePlugin');
      expect(androidPlugin.package, 'com.flutter.dev');
      expect(linuxPlugin.pluginClass, 'LSamplePlugin');
      expect(macOSPlugin.pluginClass, 'MSamplePlugin');
      expect(macOSPlugin.sharedDarwinSource, isFalse);
      expect(webPlugin.pluginClass, 'WebSamplePlugin');
      expect(webPlugin.fileName, 'web_plugin.dart');
      expect(windowsPlugin.pluginClass, 'WinSamplePlugin');
    },
  );

  testWithoutContext('Plugin parsing allows for Dart-only plugins without a pluginClass', () {
    const pluginYamlRaw =
        'implements: same_plugin\n' // this should be ignored by the tool
        'platforms:\n'
        ' android:\n'
        '  dartPluginClass: ASamplePlugin\n'
        ' ios:\n'
        '  dartPluginClass: ISamplePlugin\n'
        ' linux:\n'
        '  dartPluginClass: LSamplePlugin\n'
        ' macos:\n'
        '  dartPluginClass: MSamplePlugin\n'
        ' windows:\n'
        '  dartPluginClass: WinSamplePlugin\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    final plugin = Plugin.fromYaml(
      _kTestPluginName,
      _kTestPluginPath,
      pluginYaml,
      null,
      const <String>[],
      isDevDependency: false,
    );

    final androidPlugin = plugin.platforms[AndroidPlugin.kConfigKey]! as AndroidPlugin;
    final iOSPlugin = plugin.platforms[IOSPlugin.kConfigKey]! as IOSPlugin;
    final linuxPlugin = plugin.platforms[LinuxPlugin.kConfigKey]! as LinuxPlugin;
    final macOSPlugin = plugin.platforms[MacOSPlugin.kConfigKey]! as MacOSPlugin;
    final windowsPlugin = plugin.platforms[WindowsPlugin.kConfigKey]! as WindowsPlugin;

    expect(androidPlugin.pluginClass, isNull);
    expect(iOSPlugin.pluginClass, isNull);
    expect(linuxPlugin.pluginClass, isNull);
    expect(macOSPlugin.pluginClass, isNull);
    expect(windowsPlugin.pluginClass, isNull);
    expect(androidPlugin.dartPluginClass, 'ASamplePlugin');
    expect(iOSPlugin.dartPluginClass, 'ISamplePlugin');
    expect(linuxPlugin.dartPluginClass, 'LSamplePlugin');
    expect(macOSPlugin.dartPluginClass, 'MSamplePlugin');
    expect(windowsPlugin.dartPluginClass, 'WinSamplePlugin');
  });

  testWithoutContext('Plugin parsing allows a dartFileName field with dartPluginClass', () {
    const pluginYamlRaw =
        'platforms:\n'
        ' android:\n'
        '  dartPluginClass: AndroidClass\n'
        '  dartFileName: src/android_class.dart\n'
        ' ios:\n'
        '  dartPluginClass: IosClass\n'
        '  dartFileName: src/ios_class.dart\n'
        ' linux:\n'
        '  dartPluginClass: LinuxClass\n'
        '  dartFileName: src/linux_class.dart\n'
        ' macos:\n'
        '  dartPluginClass: MacOSClass\n'
        '  dartFileName: src/macos_class.dart\n'
        ' windows:\n'
        '  dartPluginClass: WindowsClass\n'
        '  dartFileName: src/windows_class.dart\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    final plugin = Plugin.fromYaml(
      _kTestPluginName,
      _kTestPluginPath,
      pluginYaml,
      null,
      const <String>[],
      isDevDependency: false,
    );

    expect(plugin.pluginDartClassPlatforms, <String, DartPluginClassAndFilePair>{
      'android': const (dartClass: 'AndroidClass', dartFileName: 'src/android_class.dart'),
      'ios': const (dartClass: 'IosClass', dartFileName: 'src/ios_class.dart'),
      'linux': const (dartClass: 'LinuxClass', dartFileName: 'src/linux_class.dart'),
      'macos': const (dartClass: 'MacOSClass', dartFileName: 'src/macos_class.dart'),
      'windows': const (dartClass: 'WindowsClass', dartFileName: 'src/windows_class.dart'),
    });
  });

  testWithoutContext('dartFileName without dartPluginClass throws (Android)', () {
    const pluginYamlRaw =
        'platforms:\n'
        ' android:\n'
        '  package: com.example\n'
        '  pluginClass: AndroidClass\n'
        '  dartFileName: src/android_class.dart\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    expect(
      () => Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
      ),
      throwsToolExit(
        message:
            '"dartFileName" cannot be specified without "dartPluginClass" in Android platform of plugin "$_kTestPluginName"',
      ),
    );
  });

  testWithoutContext('dartFileName without dartPluginClass throws (iOS)', () {
    const pluginYamlRaw =
        'platforms:\n'
        ' ios:\n'
        '  pluginClass: IosClass\n'
        '  dartFileName: src/ios_class.dart\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    expect(
      () => Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
      ),
      throwsToolExit(
        message:
            '"dartFileName" cannot be specified without "dartPluginClass" in iOS platform of plugin "$_kTestPluginName"',
      ),
    );
  });

  testWithoutContext('dartFileName without dartPluginClass throws (Linux)', () {
    const pluginYamlRaw =
        'platforms:\n'
        ' linux:\n'
        '  pluginClass: LinuxClass\n'
        '  dartFileName: src/linux_class.dart\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    expect(
      () => Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
      ),
      throwsToolExit(
        message:
            '"dartFileName" cannot be specified without "dartPluginClass" in Linux platform of plugin "$_kTestPluginName"',
      ),
    );
  });

  testWithoutContext('dartFileName without dartPluginClass throws (MacOS)', () {
    const pluginYamlRaw =
        'platforms:\n'
        ' macos:\n'
        '  pluginClass: MacOSClass\n'
        '  dartFileName: src/macos_class.dart\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    expect(
      () => Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
      ),
      throwsToolExit(
        message:
            '"dartFileName" cannot be specified without "dartPluginClass" in macOS platform of plugin "$_kTestPluginName"',
      ),
    );
  });

  testWithoutContext('dartFileName without dartPluginClass throws (Windows)', () {
    const pluginYamlRaw =
        'platforms:\n'
        ' windows:\n'
        '  pluginClass: WindowsClass\n'
        '  dartFileName: src/windows_class.dart\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    expect(
      () => Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
      ),
      throwsToolExit(
        message:
            '"dartFileName" cannot be specified without "dartPluginClass" in Windows platform of plugin "$_kTestPluginName"',
      ),
    );
  });

  testWithoutContext(
    'Plugin parsing of legacy format and multi-platform format together is not allowed '
    'and fatal error message contains plugin name',
    () {
      const pluginYamlRaw =
          'androidPackage: com.flutter.dev\n'
          'platforms:\n'
          ' android:\n'
          '  package: com.flutter.dev\n';

      final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;

      expect(
        () => Plugin.fromYaml(
          _kTestPluginName,
          _kTestPluginPath,
          pluginYaml,
          null,
          const <String>[],
          isDevDependency: false,
        ),
        throwsToolExit(message: _kTestPluginName),
      );
    },
  );

  testWithoutContext('Plugin parsing allows a default_package field', () {
    const pluginYamlRaw =
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

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    final plugin = Plugin.fromYaml(
      _kTestPluginName,
      _kTestPluginPath,
      pluginYaml,
      null,
      const <String>[],
      isDevDependency: false,
    );

    expect(plugin.platforms, <String, PluginPlatform>{});
    expect(plugin.defaultPackagePlatforms, <String, String>{
      'android': 'sample_package_android',
      'ios': 'sample_package_ios',
      'linux': 'sample_package_linux',
      'macos': 'sample_package_macos',
      'windows': 'sample_package_windows',
    });
    expect(plugin.pluginDartClassPlatforms, <String, String>{});
  });

  testWithoutContext('Desktop plugin parsing allows a dartPluginClass field', () {
    const pluginYamlRaw =
        'platforms:\n'
        ' linux:\n'
        '  dartPluginClass: LinuxClass\n'
        ' macos:\n'
        '  dartPluginClass: MacOSClass\n'
        ' windows:\n'
        '  dartPluginClass: WindowsClass\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    final plugin = Plugin.fromYaml(
      _kTestPluginName,
      _kTestPluginPath,
      pluginYaml,
      null,
      const <String>[],
      isDevDependency: false,
    );

    expect(plugin.pluginDartClassPlatforms, <String, DartPluginClassAndFilePair>{
      'linux': const (dartClass: 'LinuxClass', dartFileName: 'test_plugin_name.dart'),
      'macos': const (dartClass: 'MacOSClass', dartFileName: 'test_plugin_name.dart'),
      'windows': const (dartClass: 'WindowsClass', dartFileName: 'test_plugin_name.dart'),
    });
  });

  testWithoutContext('Windows allows supported mode lists', () {
    const pluginYamlRaw =
        'platforms:\n'
        ' windows:\n'
        '  pluginClass: WinSamplePlugin\n'
        '  supportedVariants:\n'
        '    - win32\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    final plugin = Plugin.fromYaml(
      _kTestPluginName,
      _kTestPluginPath,
      pluginYaml,
      null,
      const <String>[],
      isDevDependency: false,
    );

    final windowsPlugin = plugin.platforms[WindowsPlugin.kConfigKey]! as WindowsPlugin;
    expect(windowsPlugin.supportedVariants, <PluginPlatformVariant>[PluginPlatformVariant.win32]);
  });

  testWithoutContext('Web plugin tool exits if fileName field missing', () {
    const pluginYamlRaw =
        'platforms:\n'
        ' web:\n'
        '  pluginClass: WebSamplePlugin\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    expect(
      () => Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
      ),
      throwsToolExit(
        message:
            'The plugin `$_kTestPluginName` is missing the required field `fileName` in pubspec.yaml',
      ),
    );
  });

  testWithoutContext('Windows assumes win32 when no variants are given', () {
    const pluginYamlRaw =
        'platforms:\n'
        ' windows:\n'
        '  pluginClass: WinSamplePlugin\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    final plugin = Plugin.fromYaml(
      _kTestPluginName,
      _kTestPluginPath,
      pluginYaml,
      null,
      const <String>[],
      isDevDependency: false,
    );

    final windowsPlugin = plugin.platforms[WindowsPlugin.kConfigKey]! as WindowsPlugin;
    expect(windowsPlugin.supportedVariants, <PluginPlatformVariant>[PluginPlatformVariant.win32]);
  });

  testWithoutContext('Windows ignores unknown variants', () {
    const pluginYamlRaw =
        'platforms:\n'
        ' windows:\n'
        '  pluginClass: WinSamplePlugin\n'
        '  supportedVariants:\n'
        '    - not_yet_invented_variant\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    final plugin = Plugin.fromYaml(
      _kTestPluginName,
      _kTestPluginPath,
      pluginYaml,
      null,
      const <String>[],
      isDevDependency: false,
    );

    final windowsPlugin = plugin.platforms[WindowsPlugin.kConfigKey]! as WindowsPlugin;
    expect(windowsPlugin.supportedVariants, <PluginPlatformVariant>{});
  });

  testWithoutContext('Plugin parsing throws a fatal error on an empty plugin', () {
    final pluginYaml = loadYaml('') as YamlMap?;

    expect(
      () => Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
      ),
      throwsToolExit(message: 'Invalid "plugin" specification.'),
    );
  });

  testWithoutContext('Plugin parsing throws a fatal error on empty platforms', () {
    const pluginYamlRaw = 'platforms:\n';
    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;

    expect(
      () => Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
      ),
      throwsToolExit(message: 'Invalid "platforms" specification.'),
    );
  });

  test('Plugin parsing throws a fatal error on an empty platform key', () {
    const pluginYamlRaw =
        'platforms:\n'
        ' android:\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    expect(
      () => Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
      ),
      throwsToolExit(message: 'Invalid "android" plugin specification.'),
    );
  });

  testWithoutContext('Plugin parsing reports all errors across platforms at once', () {
    const pluginYamlRaw =
        'platforms:\n'
        ' android:\n'
        ' ios:\n'
        '  pluginClass: IosClass\n'
        '  dartFileName: src/ios_class.dart\n'
        ' linux:\n'
        '  dartPluginClass: LinuxClass\n'
        '  dartFileName: ../invalid_path.dart\n'
        ' web:\n'
        '  pluginClass: "Invalid Class"\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    expect(
      () => Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
      ),
      throwsToolExit(
        message:
            'Invalid plugin specification $_kTestPluginName.\n'
            'Invalid "android" plugin specification.\n'
            '"dartFileName" cannot be specified without "dartPluginClass" in iOS platform of plugin "$_kTestPluginName"\n'
            'The plugin `$_kTestPluginName` has an invalid `dartFileName` for platform `linux` in pubspec.yaml.\n'
            'Invalid "web" plugin specification: the "pluginClass" field must be a valid identifier, optionally with dot-separated segments.\n'
            'The plugin `$_kTestPluginName` is missing the required field `fileName` in pubspec.yaml',
      ),
    );
  });

  testWithoutContext('Plugin parsing allows an empty web platform key', () {
    const pluginYamlRaw =
        'platforms:\n'
        ' android:\n'
        '  ffiPlugin: true\n'
        ' web:\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    final plugin = Plugin.fromYaml(
      _kTestPluginName,
      _kTestPluginPath,
      pluginYaml,
      null,
      const <String>[],
      isDevDependency: false,
    );

    expect(plugin.platforms.keys, contains(AndroidPlugin.kConfigKey));
    expect(plugin.platforms.keys, isNot(contains(WebPlugin.kConfigKey)));
    expect(Plugin.validatePluginYaml(pluginYaml, packageName: _kTestPluginName), isEmpty);
  });

  testWithoutContext('Plugin parsing rejects non-string implements, non-bool flags, and non-string supportedVariants', () {
    const pluginYamlRaw =
        'implements: 123\n'
        'platforms:\n'
        ' android:\n'
        '  ffiPlugin: "true"\n'
        ' ios:\n'
        '  pluginClass: IosClass\n'
        '  sharedDarwinSource: "yes"\n'
        ' windows:\n'
        '  pluginClass: WinClass\n'
        '  supportedVariants:\n'
        '   - 1\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    expect(
      () => Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
      ),
      throwsToolExit(
        message:
            'Invalid plugin specification $_kTestPluginName.\n'
            'Invalid "android" plugin specification: the "ffiPlugin" field must be a boolean.\n'
            'Invalid "ios" plugin specification: the "sharedDarwinSource" field must be a boolean.\n'
            'Invalid "windows" plugin specification: the "supportedVariants" field must be a list of strings.\n'
            'Invalid "implements" specification.',
      ),
    );
  });

  testWithoutContext('Plugin parsing rejects invalid dartPluginClass next to default_package', () {
    const pluginYamlRaw =
        'platforms:\n'
        ' linux:\n'
        '  default_package: some_package\n'
        '  dartPluginClass: "Invalid Class"\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    expect(
      () => Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
      ),
      throwsToolExit(
        message:
            'Invalid plugin specification $_kTestPluginName.\n'
            'Invalid "linux" plugin specification: the "dartPluginClass" field must be a valid identifier, optionally with dot-separated segments.',
      ),
    );
  });

  testWithoutContext(
    'Plugin parsing rejects sharedDarwinSource without pluginClass or ffiPlugin',
    () {
      const pluginYamlRaw =
          'platforms:\n'
          ' ios:\n'
          '  sharedDarwinSource: true\n'
          ' macos:\n'
          '  dartPluginClass: MacOSClass\n'
          '  sharedDarwinSource: true\n';

      final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
      expect(
        () => Plugin.fromYaml(
          _kTestPluginName,
          _kTestPluginPath,
          pluginYaml,
          null,
          const <String>[],
          isDevDependency: false,
        ),
        throwsToolExit(
          message:
              'Invalid plugin specification $_kTestPluginName.\n'
              'Invalid "ios" plugin specification: "sharedDarwinSource" cannot be specified without "pluginClass" or "ffiPlugin".\n'
              'Invalid "macos" plugin specification: "sharedDarwinSource" cannot be specified without "pluginClass" or "ffiPlugin".',
        ),
      );
    },
  );

  testWithoutContext('Plugin parsing allows sharedDarwinSource with ffiPlugin', () {
    const pluginYamlRaw =
        'platforms:\n'
        ' ios:\n'
        '  ffiPlugin: true\n'
        '  sharedDarwinSource: true\n'
        ' macos:\n'
        '  ffiPlugin: true\n'
        '  sharedDarwinSource: true\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    final plugin = Plugin.fromYaml(
      _kTestPluginName,
      _kTestPluginPath,
      pluginYaml,
      null,
      const <String>[],
      isDevDependency: false,
    );

    final iosPlugin = plugin.platforms[IOSPlugin.kConfigKey]! as IOSPlugin;
    final macOSPlugin = plugin.platforms[MacOSPlugin.kConfigKey]! as MacOSPlugin;

    expect(iosPlugin.ffiPlugin, isTrue);
    expect(iosPlugin.sharedDarwinSource, isTrue);
    expect(macOSPlugin.ffiPlugin, isTrue);
    expect(macOSPlugin.sharedDarwinSource, isTrue);
  });
}
