// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:yaml/yaml.dart';

import '../src/common.dart';
import 'test_utils.dart';

const _linuxPrototypePackageName = 'flutter_tools_extension_linux_prototype';

Future<(Uri, Uri, ExtensionPackageConfig)> _resolveLinuxPrototypeExtension() async {
  final Uri? libUri = await Isolate.resolvePackageUri(
    Uri.parse('package:$_linuxPrototypePackageName/$_linuxPrototypePackageName.dart'),
  );
  expect(libUri, isNotNull);
  final Uri entrypointUri = libUri!.resolve('../bin/$_linuxPrototypePackageName.dart');
  final Uri? packageConfigUri = await Isolate.packageConfig;
  expect(packageConfigUri, isNotNull);

  final Uri configUri = libUri.resolve('../extension/flutter_tools/config.yaml');
  final rawYaml = loadYaml(fileSystem.file(configUri).readAsStringSync()) as YamlMap;
  final expectedConfig = ExtensionPackageConfig.fromMap(
    rawYaml.cast<String, Object?>(),
    packageName: _linuxPrototypePackageName,
  );
  return (entrypointUri, packageConfigUri!, expectedConfig);
}

void main() {
  final bool isLinux = const LocalPlatform().isLinux;
  late Directory tempHome;
  late Map<String, String> baseEnv;

  setUpAll(() {
    tempHome = createResolvedTempDirectorySync('tool_extensions_home.');
    baseEnv = <String, String>{
      'HOME': tempHome.path,
      'USERPROFILE': tempHome.path,
      'APPDATA': tempHome.path,
      'BOT': 'true',
    };
  });

  tearDownAll(() {
    tryToDelete(tempHome);
  });

  testWithoutContext('flutter doctor executes extension validators when enabled', () async {
    final ProcessResult result = await processManager.run(
      <String>[flutterBin, 'doctor', '-v'],
      environment: <String, String>{...baseEnv, 'FLUTTER_TOOL_EXTENSIONS': 'true'},
    );

    if (isLinux) {
      expect(result.stdout, contains('[✓] Linux Custom Extension Prototype'));
      expect(result.stdout, contains('Linux custom extension toolchain is operational'));
    } else {
      expect(result.stdout, isNot(contains('Linux Custom Extension Prototype')));
    }
    expect(result.exitCode, 0);
  });

  testWithoutContext('flutter config outputs extension settings when enabled', () async {
    final ProcessResult result = await processManager.run(
      <String>[flutterBin, 'config', '--list'],
      environment: <String, String>{...baseEnv, 'FLUTTER_TOOL_EXTENSIONS': 'true'},
    );

    if (isLinux) {
      expect(result.stdout, contains('Extension Settings:'));
      expect(result.stdout, contains('  Linux Custom Extension Prototype:'));
      expect(result.stdout, contains('    enable-linux-custom-prototype:'));
    } else {
      expect(result.stdout, isNot(contains('Extension Settings:')));
    }
    expect(result.exitCode, 0);
  });

  testWithoutContext('flutter devices outputs custom extension device when enabled', () async {
    final ProcessResult result = await processManager.run(
      <String>[flutterBin, 'devices'],
      environment: <String, String>{...baseEnv, 'FLUTTER_TOOL_EXTENSIONS': 'true'},
    );

    if (isLinux) {
      expect(result.stdout, contains('Linux Custom Extension Prototype Device'));
    } else {
      expect(result.stdout, isNot(contains('Linux Custom Extension Prototype Device')));
    }
    expect(result.exitCode, 0);
  });

  testWithoutContext('tool extensions are disabled by default', () async {
    final ProcessResult doctorResult = await processManager.run(<String>[
      flutterBin,
      'doctor',
      '-v',
    ], environment: baseEnv);
    expect(doctorResult.stdout, isNot(contains('Linux Custom Extension Prototype')));
    expect(doctorResult.exitCode, 0);
    final ProcessResult configResult = await processManager.run(<String>[
      flutterBin,
      'config',
      '--list',
    ], environment: baseEnv);
    expect(configResult.stdout, isNot(contains('Extension Settings:')));
    expect(configResult.exitCode, 0);

    final ProcessResult devicesResult = await processManager.run(<String>[
      flutterBin,
      'devices',
    ], environment: baseEnv);
    expect(devicesResult.stdout, isNot(contains('Linux Custom Extension Prototype Device')));
    expect(devicesResult.exitCode, 0);
  });

  testWithoutContext('flutter create with custom template succeeds when enabled', () async {
    final Directory projectDir = tempHome.childDirectory('custom_app');
    if (projectDir.existsSync()) {
      projectDir.deleteSync(recursive: true);
    }

    final ProcessResult result = await processManager.run(
      <String>[flutterBin, 'create', '--template=custom-linux-app', projectDir.path],
      environment: <String, String>{...baseEnv, 'FLUTTER_TOOL_EXTENSIONS': 'true'},
    );

    if (isLinux) {
      expect(result.exitCode, 0, reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}');
      expect(projectDir.existsSync(), isTrue);
      final File verificationFile = projectDir.childFile('.custom_device_extension_info');
      expect(verificationFile.existsSync(), isTrue);
      expect(
        verificationFile.readAsStringSync().trim(),
        'Custom Linux Device Extension App Template Verified',
      );
    } else {
      expect(
        result.exitCode,
        isNot(0),
        reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}',
      );
      expect(result.stderr, contains('custom-linux-app'));
      expect(projectDir.existsSync(), isFalse);
    }
  });

  testWithoutContext('flutter create with custom template fails when disabled', () async {
    final Directory projectDir = tempHome.childDirectory('custom_app_disabled');
    if (projectDir.existsSync()) {
      projectDir.deleteSync(recursive: true);
    }

    final ProcessResult result = await processManager.run(
      <String>[flutterBin, 'create', '--template=custom-linux-app', projectDir.path],
      environment: baseEnv, // disabled by default
    );

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('is not an allowed value for option "--template"'));
    expect(projectDir.existsSync(), isFalse);
  });

  testWithoutContext('flutter create with custom template succeeds when enabled', () async {
    final Directory projectDir = tempHome.childDirectory('custom_app');
    if (projectDir.existsSync()) {
      projectDir.deleteSync(recursive: true);
    }

    final ProcessResult result = await processManager.run(
      <String>[flutterBin, 'create', '--template=custom-linux-app', projectDir.path],
      environment: <String, String>{...baseEnv, 'FLUTTER_TOOL_EXTENSIONS': 'true'},
    );

    if (isLinux) {
      expect(result.exitCode, 0, reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}');
      expect(projectDir.existsSync(), isTrue);
      final File verificationFile = projectDir.childFile('.custom_device_extension_info');
      expect(verificationFile.existsSync(), isTrue);
      expect(
        verificationFile.readAsStringSync().trim(),
        'Custom Linux Device Extension App Template Verified',
      );
    } else {
      expect(
        result.exitCode,
        isNot(0),
        reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}',
      );
      expect(result.stderr, contains('custom-linux-app'));
      expect(projectDir.existsSync(), isFalse);
    }
  });

  testWithoutContext('flutter create with custom template fails when disabled', () async {
    final Directory projectDir = tempHome.childDirectory('custom_app_disabled');
    if (projectDir.existsSync()) {
      projectDir.deleteSync(recursive: true);
    }

    final ProcessResult result = await processManager.run(
      <String>[flutterBin, 'create', '--template=custom-linux-app', projectDir.path],
      environment: baseEnv, // disabled by default
    );

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('is not an allowed value for option "--template"'));
    expect(projectDir.existsSync(), isFalse);
  });

  // Regression tests moved from general.shard for https://github.com/flutter/flutter/issues/195966.
  testWithoutContext(
    'ExtensionConnection.spawnUri spawns extension script and completes handshake',
    () async {
      final logger = BufferLogger.test();
      final (Uri entrypointUri, Uri packageConfigUri, ExtensionPackageConfig expectedConfig) =
          await _resolveLinuxPrototypeExtension();

      final ExtensionConnection connection = await ExtensionConnection.spawnUri(
        entrypointUri,
        expectedConfig: expectedConfig,
        extensionName: _linuxPrototypePackageName,
        logger: logger,
        packageConfigUri: packageConfigUri,
      );
      addTearDown(connection.dispose);

      expect(connection.extensionName, _linuxPrototypePackageName);
      expect(
        connection.capabilities.services,
        containsAll(const <String>['diagnostics', 'config', 'build', 'template']),
      );
    },
  );

  testWithoutContext('ExtensionConnection.spawnUri throws StateError when expectedConfig does not match capabilities', () async {
    final logger = BufferLogger.test();
    final (Uri entrypointUri, Uri packageConfigUri, ExtensionPackageConfig prototypeConfig) =
        await _resolveLinuxPrototypeExtension();

    await expectLater(
      ExtensionConnection.spawnUri(
        entrypointUri,
        expectedConfig: ExtensionPackageConfig(
          name: _linuxPrototypePackageName,
          hostPlatforms: prototypeConfig.hostPlatforms,
          services: const <String>{'diagnostics'},
        ),
        logger: logger,
        packageConfigUri: packageConfigUri,
      ),
      throwsA(
        isA<StateError>().having(
          (StateError e) => e.message,
          'message',
          contains('capabilities mismatch: extension/flutter_tools/config.yaml declares services'),
        ),
      ),
    );

    await expectLater(
      ExtensionConnection.spawnUri(
        entrypointUri,
        expectedConfig: ExtensionPackageConfig(
          name: _linuxPrototypePackageName,
          hostPlatforms: const <String>{'macos'},
          services: prototypeConfig.services,
        ),
        logger: logger,
        packageConfigUri: packageConfigUri,
      ),
      throwsA(
        isA<StateError>().having(
          (StateError e) => e.message,
          'message',
          contains(
            'capabilities mismatch: extension/flutter_tools/config.yaml declares host_platforms',
          ),
        ),
      ),
    );
  });
}
