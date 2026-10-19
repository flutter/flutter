// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:test/test.dart';

void main() {
  group('BuildMode', () {
    test('fromCliName parses valid build modes and throws on invalid mode', () {
      expect(BuildMode.fromCliName('debug'), BuildMode.debug);
      expect(BuildMode.fromCliName('profile'), BuildMode.profile);
      expect(BuildMode.fromCliName('release'), BuildMode.release);
      expect(BuildMode.fromCliName('jit_release'), BuildMode.jitRelease);
      expect(() => BuildMode.fromCliName('invalid'), throwsArgumentError);
    });

    test('properties and formatting getters return expected values', () {
      expect(BuildMode.debug.isRelease, isFalse);
      expect(BuildMode.debug.isJit, isTrue);
      expect(BuildMode.debug.isPrecompiled, isFalse);
      expect(BuildMode.debug.cliName, 'debug');
      expect(BuildMode.debug.uppercaseName, 'Debug');
      expect(BuildMode.debug.friendlyName, 'debug');
      expect(BuildMode.debug.uppercaseFriendlyName, 'Debug');
      expect(BuildMode.debug.toString(), 'debug');

      expect(BuildMode.profile.isRelease, isFalse);
      expect(BuildMode.profile.isJit, isFalse);
      expect(BuildMode.profile.isPrecompiled, isTrue);
      expect(BuildMode.profile.cliName, 'profile');
      expect(BuildMode.profile.uppercaseName, 'Profile');

      expect(BuildMode.release.isRelease, isTrue);
      expect(BuildMode.release.isJit, isFalse);
      expect(BuildMode.release.isPrecompiled, isTrue);
      expect(BuildMode.release.cliName, 'release');
      expect(BuildMode.release.uppercaseName, 'Release');

      expect(BuildMode.jitRelease.isRelease, isTrue);
      expect(BuildMode.jitRelease.isJit, isTrue);
      expect(BuildMode.jitRelease.isPrecompiled, isFalse);
      expect(BuildMode.jitRelease.cliName, 'jit_release');
      expect(BuildMode.jitRelease.uppercaseName, 'Jit_release');
      expect(BuildMode.jitRelease.friendlyName, 'jit release');
      expect(BuildMode.jitRelease.uppercaseFriendlyName, 'Jit release');
      expect(BuildMode.jitRelease.toString(), 'jit_release');
    });
  });

  group('ExtensionBuildTarget', () {
    test('serializes and deserializes correctly with all fields', () {
      final target = ExtensionBuildTarget(
        description: 'A custom Linux build target.',
        name: 'custom-linux-build',
        nativeAssetsConfig: ExtensionNativeAssetsConfig(
          targetArchitecture: 'arm64',
          targetOs: 'linux',
          cCompilerConfig: ExtensionCCompilerConfig(
            ar: Uri.file('/usr/bin/aarch64-linux-gnu-ar'),
            cc: Uri.file('/usr/bin/aarch64-linux-gnu-gcc'),
            ld: Uri.file('/usr/bin/aarch64-linux-gnu-ld'),
          ),
        ),
        pluginPlatformKey: 'linux',
      );

      final Map<String, Object?> map = target.toMap();
      expect(map[ExtensionBuildTarget.nameKey], 'custom-linux-build');
      expect(map[ExtensionBuildTarget.descriptionKey], 'A custom Linux build target.');
      expect(map[ExtensionBuildTarget.pluginPlatformKeyKey], 'linux');
      expect(map[ExtensionBuildTarget.nativeAssetsConfigKey], isA<Map<String, Object?>>());

      final parsed = ExtensionBuildTarget.fromJson(map);
      expect(parsed, equals(target));
      expect(parsed.hashCode, equals(target.hashCode));
      expect(parsed.toString(), contains('custom-linux-build'));
      expect(parsed.toString(), contains('pluginPlatformKey: linux'));
      expect(parsed.toString(), contains('nativeAssetsConfig:'));
    });

    test('deserializes with default empty strings when fields are missing', () {
      final parsed = ExtensionBuildTarget.fromJson(const <String, Object?>{});
      expect(parsed.name, isEmpty);
      expect(parsed.description, isEmpty);
      expect(parsed.nativeAssetsConfig, isNull);
      expect(parsed.pluginPlatformKey, isNull);
    });

    test('fromJson throws ArgumentError on malformed nativeAssetsConfig or pluginPlatformKey', () {
      expect(
        () => ExtensionBuildTarget.fromJson(const <String, Object?>{
          'name': 't',
          'description': 'd',
          'nativeAssetsConfig': 'not-a-map',
        }),
        throwsArgumentError,
      );
      expect(
        () => ExtensionBuildTarget.fromJson(const <String, Object?>{
          'name': 't',
          'description': 'd',
          'pluginPlatformKey': 123,
        }),
        throwsArgumentError,
      );
    });

    test('listFromJson handles valid and invalid lists', () {
      final validJson = <String, Object?>{
        'name': 'custom-linux-build',
        'description': 'A custom Linux build target.',
      };

      final List<ExtensionBuildTarget> targets = ExtensionBuildTarget.listFromJson(<Object?>[
        validJson,
      ]);
      expect(targets, hasLength(1));
      expect(targets.first.name, 'custom-linux-build');
      expect(targets.first.description, 'A custom Linux build target.');

      expect(ExtensionBuildTarget.listFromJson(null), isEmpty);
      expect(ExtensionBuildTarget.listFromJson('invalid'), isEmpty);
    });

    test('equality and hashCode distinguish different targets', () {
      const target1 = ExtensionBuildTarget(description: 'Target 1', name: 'target-1');
      const target2 = ExtensionBuildTarget(description: 'Target 2', name: 'target-2');

      expect(target1, isNot(equals(target2)));
      expect(target1.hashCode, isNot(equals(target2.hashCode)));
    });
  });

  group('ExtensionBuildResult', () {
    test('serializes and deserializes successful result without errorMessage', () {
      const result = ExtensionBuildResult(success: true);

      final Map<String, Object?> map = result.toMap();
      expect(map[ExtensionBuildResult.successKey], isTrue);
      expect(map.containsKey(ExtensionBuildResult.errorMessageKey), isFalse);

      final parsed = ExtensionBuildResult.fromJson(map);
      expect(parsed, equals(result));
      expect(parsed.hashCode, equals(result.hashCode));
      expect(parsed.toString(), contains('success: true'));
    });

    test('serializes and deserializes failed result with errorMessage', () {
      const result = ExtensionBuildResult(success: false, errorMessage: 'Compilation failed.');

      final Map<String, Object?> map = result.toMap();
      expect(map[ExtensionBuildResult.successKey], isFalse);
      expect(map[ExtensionBuildResult.errorMessageKey], 'Compilation failed.');

      final parsed = ExtensionBuildResult.fromJson(map);
      expect(parsed, equals(result));
      expect(parsed.hashCode, equals(result.hashCode));
      expect(parsed.toString(), contains('Compilation failed.'));
    });

    test('equality and hashCode distinguish different results', () {
      const result1 = ExtensionBuildResult(success: true);
      const result2 = ExtensionBuildResult(success: false, errorMessage: 'Failed');

      expect(result1, isNot(equals(result2)));
      expect(result1.hashCode, isNot(equals(result2.hashCode)));
    });
  });

  group('ExtensionNativeAssetsConfig and ExtensionCCompilerConfig', () {
    test('serializes and deserializes with all fields', () {
      final config = ExtensionNativeAssetsConfig(
        targetArchitecture: 'arm64',
        targetOs: 'linux',
        cCompilerConfig: ExtensionCCompilerConfig(
          ar: Uri.file('/usr/bin/llvm-ar'),
          cc: Uri.file('/usr/bin/clang'),
          envScript: Uri.file('/opt/sdk/env.sh'),
          envScriptArgs: const <String>['--arch', 'arm64'],
          ld: Uri.file('/usr/bin/ld.lld'),
        ),
      );

      final Map<String, Object?> jsonMap = config.toMap();
      expect(jsonMap[ExtensionNativeAssetsConfig.targetOsKey], 'linux');
      expect(jsonMap[ExtensionNativeAssetsConfig.targetArchitectureKey], 'arm64');
      final compilerJson =
          jsonMap[ExtensionNativeAssetsConfig.cCompilerConfigKey]! as Map<String, Object?>;
      expect(compilerJson[ExtensionCCompilerConfig.ccKey], 'file:///usr/bin/clang');
      expect(compilerJson[ExtensionCCompilerConfig.arKey], 'file:///usr/bin/llvm-ar');
      expect(compilerJson[ExtensionCCompilerConfig.ldKey], 'file:///usr/bin/ld.lld');
      expect(compilerJson[ExtensionCCompilerConfig.envScriptKey], 'file:///opt/sdk/env.sh');
      expect(
        compilerJson[ExtensionCCompilerConfig.envScriptArgsKey],
        equals(<String>['--arch', 'arm64']),
      );

      final roundTripped = jsonDecode(jsonEncode(jsonMap)) as Map<String, Object?>;
      final parsed = ExtensionNativeAssetsConfig.fromJson(roundTripped);
      expect(parsed, equals(config));
      expect(parsed.hashCode, equals(config.hashCode));
      expect(parsed.toString(), contains('targetOs: linux'));
      expect(parsed.toString(), contains('targetArchitecture: arm64'));
      expect(parsed.toString(), contains('cc: file:///usr/bin/clang'));
    });

    test('serializes and deserializes with required fields only', () {
      const config = ExtensionNativeAssetsConfig(targetArchitecture: 'x64', targetOs: 'linux');

      final Map<String, Object?> jsonMap = config.toMap();
      expect(jsonMap.containsKey(ExtensionNativeAssetsConfig.cCompilerConfigKey), isFalse);

      final parsed = ExtensionNativeAssetsConfig.fromJson(jsonMap);
      expect(parsed, equals(config));
      expect(parsed.cCompilerConfig, isNull);
    });

    test('fromJson throws ArgumentError on invalid fields', () {
      expect(
        () => ExtensionNativeAssetsConfig.fromJson(const <String, Object?>{'targetOs': 'linux'}),
        throwsArgumentError,
      );
      expect(
        () => ExtensionNativeAssetsConfig.fromJson(const <String, Object?>{
          'targetArchitecture': 'x64',
        }),
        throwsArgumentError,
      );
      expect(
        () => ExtensionNativeAssetsConfig.fromJson(const <String, Object?>{
          'targetArchitecture': 'x64',
          'targetOs': 'linux',
          'cCompilerConfig': 'not-a-map',
        }),
        throwsArgumentError,
      );
      expect(
        () => ExtensionCCompilerConfig.fromJson(const <String, Object?>{
          'ar': 'relative/path/ar',
          'cc': 'file:///usr/bin/clang',
          'ld': 'file:///usr/bin/ld.lld',
        }),
        throwsArgumentError,
      );
      expect(
        () => ExtensionCCompilerConfig.fromJson(const <String, Object?>{
          'ar': 'https://example.com/ar',
          'cc': 'file:///usr/bin/clang',
          'ld': 'file:///usr/bin/ld.lld',
        }),
        throwsArgumentError,
      );
      expect(
        () => ExtensionCCompilerConfig.fromJson(const <String, Object?>{
          'ar': 'file:///usr/bin/llvm-ar',
          'cc': 'file:///usr/bin/clang',
          'ld': 'file:///usr/bin/ld.lld',
          'envScriptArgs': <Object?>[123],
        }),
        throwsArgumentError,
      );
    });

    test('toEnvironmentDefines maps targetOs, targetArchitecture, and compiler paths', () {
      final config = ExtensionNativeAssetsConfig(
        targetArchitecture: 'arm64',
        targetOs: 'ohos',
        cCompilerConfig: ExtensionCCompilerConfig(
          ar: Uri.file('/opt/ohos-sdk/llvm/bin/llvm-ar'),
          cc: Uri.file('/opt/ohos-sdk/llvm/bin/clang'),
          envScript: Uri.file('/opt/ohos-sdk/env.sh'),
          envScriptArgs: const <String>['--arch', 'arm64 with spaces'],
          ld: Uri.file('/opt/ohos-sdk/llvm/bin/ld.lld'),
        ),
      );

      expect(
        config.toEnvironmentDefines(),
        equals(<String, String>{
          ExtensionNativeAssetsConfig.targetOsDefine: 'ohos',
          ExtensionNativeAssetsConfig.targetArchDefine: 'arm64',
          ExtensionNativeAssetsConfig.cCompilerCcDefine: '/opt/ohos-sdk/llvm/bin/clang',
          ExtensionNativeAssetsConfig.cCompilerArDefine: '/opt/ohos-sdk/llvm/bin/llvm-ar',
          ExtensionNativeAssetsConfig.cCompilerLdDefine: '/opt/ohos-sdk/llvm/bin/ld.lld',
          ExtensionNativeAssetsConfig.cCompilerEnvScriptDefine: '/opt/ohos-sdk/env.sh',
          ExtensionNativeAssetsConfig.cCompilerEnvScriptArgsDefine:
              '["--arch","arm64 with spaces"]',
        }),
      );
    });
  });

  group('ExtensionPlugin', () {
    test('serializes, deserializes, and compares nested configuration across JSON round-trip', () {
      final plugin = ExtensionPlugin(
        name: 'url_launcher_linux',
        path: Uri.directory('/pub-cache/url_launcher_linux'),
        configuration: const <String, Object?>{
          'pluginClass': 'UrlLauncherPlugin',
          'ffiPlugin': false,
          'variants': <Object?>['gtk', 'wayland'],
          'nested': <String, Object?>{
            'flags': <Object?>['a', 'b'],
          },
        },
      );

      final Map<String, Object?> jsonMap = plugin.toMap();
      expect(jsonMap[ExtensionPlugin.nameKey], 'url_launcher_linux');
      expect(jsonMap[ExtensionPlugin.pathKey], 'file:///pub-cache/url_launcher_linux/');

      final roundTripped = jsonDecode(jsonEncode(jsonMap)) as Map<String, Object?>;
      final parsed = ExtensionPlugin.fromJson(roundTripped);
      expect(parsed, equals(plugin));
      expect(parsed.hashCode, equals(plugin.hashCode));
      expect(parsed.toString(), contains('url_launcher_linux'));

      final List<ExtensionPlugin> list = ExtensionPlugin.listFromJson(<Object?>[roundTripped]);
      expect(list, equals(<ExtensionPlugin>[plugin]));
      expect(() => ExtensionPlugin.listFromJson(null), throwsArgumentError);
      expect(() => ExtensionPlugin.listFromJson('invalid'), throwsArgumentError);
      expect(() => ExtensionPlugin.listFromJson(<Object?>['not-a-map']), throwsArgumentError);
    });

    test('fromJson throws ArgumentError on missing or invalid fields', () {
      expect(() => ExtensionPlugin.fromJson(const <String, Object?>{}), throwsArgumentError);
      expect(
        () => ExtensionPlugin.fromJson(const <String, Object?>{
          'name': 'my_plugin',
          'path': 'file:///pub-cache/my_plugin',
        }),
        throwsArgumentError,
      );
      expect(
        () => ExtensionPlugin.fromJson(const <String, Object?>{
          'name': 'my_plugin',
          'path': 'relative/my_plugin/',
        }),
        throwsArgumentError,
      );
      expect(
        () => ExtensionPlugin.fromJson(const <String, Object?>{
          'name': 'my_plugin',
          'path': 'file:///pub-cache/my_plugin/',
          'configuration': 'not-a-map',
        }),
        throwsArgumentError,
      );
    });
  });
}
