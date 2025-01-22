// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io' as io;

import 'package:path/path.dart' as p;
import 'package:platform/platform.dart';
import 'package:test/test.dart';

import '../bin/check.dart' as check show run;

void main() {
  late io.Directory tmpFlutterEngineRoot;
  late StringBuffer stdout;
  late StringBuffer stderr;
  late int exitCode;

  late io.Directory tmpFlutterEngineSrc;
  late io.Directory tmpCiBuilders;
  late io.File tmpCiYaml;
  late List<Map<String, Object?>> ciYamlTargets;

  setUp(() {
    tmpFlutterEngineRoot = io.Directory.systemTemp.createTempSync('check_integration_test.');
    stdout = StringBuffer();
    stderr = StringBuffer();
    exitCode = 0;

    // Create a synthetic engine directory.
    tmpFlutterEngineSrc = io.Directory(p.join(tmpFlutterEngineRoot.path, 'flutter', 'src'))
      ..createSync(recursive: true);
    tmpCiBuilders = io.Directory(p.join(tmpFlutterEngineSrc.path, 'flutter', 'ci', 'builders'))
      ..createSync(recursive: true);
    tmpCiYaml = io.File(p.join(p.join(tmpFlutterEngineSrc.path, 'flutter', '.ci.yaml')));
    ciYamlTargets = [];
  });

  tearDown(() {
    tmpFlutterEngineRoot.deleteSync(recursive: true);
  });

  void run(Iterable<String> args, {Platform? platform, bool allowFailure = false}) {
    check.run(
      args,
      stderr: stderr,
      stdout: stdout,
      setExitCode: (newExitCode) {
        exitCode = newExitCode;
      },
      platform: platform ?? FakePlatform(operatingSystem: Platform.linux),
    );
    if (exitCode != 0 && !allowFailure) {
      fail('$args failed: $stderr');
    }
  }

  test('should produce usage on --help', () {
    run(['--help']);

    expect(
      stdout.toString(),
      allOf([contains('--verbose'), contains('--help'), contains('--engine-src-path')]),
    );
  });

  test('fails if no build configurations were found', () {
    run(['--engine-src-path=${tmpFlutterEngineSrc.path}'], allowFailure: true);

    expect(stderr.toString(), contains('❌ Loaded build configs under'));
  });

  void addConfig(String name, {bool releaseBuild = false, bool malformed = false}) {
    io.File(
      p.join(tmpCiBuilders.path, '$name.json'),
    ).writeAsStringSync(malformed ? 'bad{}' : jsonEncode({'builds': <Object?>[]}));

    ciYamlTargets.add({
      'name': name,
      'properties': {'config_name': name, if (releaseBuild) 'release_build': 'true'},
    });
    tmpCiYaml.writeAsStringSync(jsonEncode({'targets': ciYamlTargets}));
  }

  test('fails if .ci.yaml is not valid', () {
    addConfig('linux_unopt');
    run(['--engine-src-path=${tmpFlutterEngineSrc.path}'], allowFailure: true);

    expect(stderr.toString(), contains('❌ .ci.yaml at'));
  });

  test('fails if a configuration file had a deserialization error', () {
    addConfig('linux_unopt', malformed: true);
    run(['--engine-src-path=${tmpFlutterEngineSrc.path}'], allowFailure: true);

    expect(stderr.toString(), contains('❌ .ci.yaml at'));
  });
}
