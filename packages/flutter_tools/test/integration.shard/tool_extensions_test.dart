// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';

import '../src/common.dart';
import '../src/package_config.dart';
import 'test_utils.dart';

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

  testWithoutContext('flutter assemble with custom TargetPlatform and ExtensionPluginPlatformKey generates custom platform Dart plugin registrant', () async {
    final Directory workspaceDir = tempHome.childDirectory('custom_assemble_workspace')
      ..createSync(recursive: true);
    final Directory projectDir = workspaceDir.childDirectory('my_app')..createSync(recursive: true);
    final Directory customPluginDir = workspaceDir.childDirectory('path_provider_custom_os')
      ..createSync(recursive: true);
    final Directory otherPluginDir = workspaceDir.childDirectory('path_provider_other')
      ..createSync(recursive: true);
    final Directory flutterStubDir = workspaceDir.childDirectory('flutter_stub')
      ..createSync(recursive: true);
    flutterStubDir
        .childDirectory('lib')
        .childDirectory('src')
        .childFile('dart_plugin_registrant.dart')
        .createSync(recursive: true);

    customPluginDir.childFile('pubspec.yaml').writeAsStringSync('''
name: path_provider_custom_os
environment:
  sdk: ^3.7.0-0
  flutter: ">=1.20.0"
flutter:
  plugin:
    implements: path_provider
    platforms:
      custom_os:
        dartPluginClass: PathProviderCustomOs
''');
    customPluginDir.childDirectory('lib').childFile('path_provider_custom_os.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
class PathProviderCustomOs {
  static void registerWith() {}
}
''');

    otherPluginDir.childFile('pubspec.yaml').writeAsStringSync('''
name: path_provider_other
environment:
  sdk: ^3.7.0-0
  flutter: ">=1.20.0"
flutter:
  plugin:
    implements: path_provider
    platforms:
      other_os:
        dartPluginClass: PathProviderOther
''');
    otherPluginDir.childDirectory('lib').childFile('path_provider_other.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
class PathProviderOther {
  static void registerWith() {}
}
''');

    projectDir.childFile('pubspec.yaml').writeAsStringSync('''
name: my_app
environment:
  sdk: ^3.7.0-0
dependencies:
  path_provider_custom_os:
    path: ../path_provider_custom_os
  path_provider_other:
    path: ../path_provider_other
flutter:
  uses-material-design: false
''');
    projectDir.childDirectory('lib').childFile('main.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() {}\n');
    writePackageConfigFiles(
      directory: projectDir,
      mainLibName: 'my_app',
      packages: <String, String>{
        'flutter': flutterStubDir.path,
        'path_provider_custom_os': customPluginDir.path,
        'path_provider_other': otherPluginDir.path,
      },
    );

    final Directory outputDir = projectDir.childDirectory('build').childDirectory('custom_out');
    final ProcessResult result = await processManager.run(
      <String>[
        flutterBin,
        'assemble',
        '--no-version-check',
        '--output=${outputDir.path}',
        '-dTargetPlatform=custom-arm64',
        '-dExtensionPluginPlatformKey=custom_os',
        '-dBuildMode=debug',
        '-dTargetFile=lib/main.dart',
        'copy_assets',
      ],
      workingDirectory: projectDir.path,
      environment: <String, String>{...baseEnv, 'FLUTTER_TOOL_EXTENSIONS': 'true'},
    );

    expect(result.exitCode, 0, reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}');
    final File registrantFile = projectDir
        .childDirectory('.dart_tool')
        .childDirectory('flutter_build')
        .childFile('dart_plugin_registrant.dart');
    expect(registrantFile.existsSync(), isTrue);
    final String registrantContent = registrantFile.readAsStringSync();
    expect(
      registrantContent,
      contains("const String.fromEnvironment('FLUTTER_CUSTOM_PLATFORM') == 'custom_os'"),
    );
    expect(
      registrantContent,
      contains('path_provider_custom_os.PathProviderCustomOs.registerWith()'),
    );
    expect(registrantContent, isNot(contains('PathProviderOther')));
  });
}
