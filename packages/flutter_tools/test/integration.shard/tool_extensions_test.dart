// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';

import '../src/common.dart';
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

    expect(result.exitCode, 0, reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}');
    expect(projectDir.existsSync(), isTrue);
    final File verificationFile = projectDir.childFile('.custom_device_extension_info');
    expect(verificationFile.existsSync(), isTrue);
    expect(
      verificationFile.readAsStringSync().trim(),
      'Custom Linux Device Extension App Template Verified',
    );
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
}
