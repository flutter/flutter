// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:platform/platform.dart';
import 'package:test/test.dart';

void _expectPlatformsEqual(Platform actual, Platform expected) {
  expect(actual.numberOfProcessors, expected.numberOfProcessors);
  expect(actual.pathSeparator, expected.pathSeparator);
  expect(actual.operatingSystem, expected.operatingSystem);
  expect(actual.operatingSystemVersion, expected.operatingSystemVersion);
  expect(actual.localHostname, expected.localHostname);
  expect(actual.environment, expected.environment);
  expect(actual.executable, expected.executable);
  expect(actual.resolvedExecutable, expected.resolvedExecutable);
  expect(actual.script, expected.script);
  expect(actual.executableArguments, expected.executableArguments);
  expect(actual.packageConfig, expected.packageConfig);
  expect(actual.version, expected.version);
  expect(actual.localeName, expected.localeName);
}

void main() {
  group('FakePlatform', () {
    late FakePlatform fake;
    late LocalPlatform local;

    setUp(() {
      fake = FakePlatform();
      local = LocalPlatform();
    });

    group('fromPlatform', () {
      setUp(() {
        fake = FakePlatform.fromPlatform(local);
      });

      test('copiesAllProperties', () {
        _expectPlatformsEqual(fake, local);
      });

      test('convertsPropertiesToMutable', () {
        String key = fake.environment.keys.first;

        expect(fake.environment[key], local.environment[key]);
        fake.environment[key] = 'FAKE';
        expect(fake.environment[key], 'FAKE');

        expect(
            fake.executableArguments.length, local.executableArguments.length);
        fake.executableArguments.add('ARG');
        expect(fake.executableArguments.last, 'ARG');
      });
    });

    group('copyWith', () {
      setUp(() {
        fake = FakePlatform.fromPlatform(local);
      });

      test('overrides a value, but leaves others intact', () {
        FakePlatform copy = fake.copyWith(
          numberOfProcessors: -1,
        );
        expect(copy.numberOfProcessors, equals(-1));
        expect(copy.pathSeparator, local.pathSeparator);
        expect(copy.operatingSystem, local.operatingSystem);
        expect(copy.operatingSystemVersion, local.operatingSystemVersion);
        expect(copy.localHostname, local.localHostname);
        expect(copy.environment, local.environment);
        expect(copy.executable, local.executable);
        expect(copy.resolvedExecutable, local.resolvedExecutable);
        expect(copy.script, local.script);
        expect(copy.executableArguments, local.executableArguments);
        expect(copy.packageConfig, local.packageConfig);
        expect(copy.version, local.version);
        expect(copy.localeName, local.localeName);
      });
      test('can override all values', () {
        fake = FakePlatform(
          numberOfProcessors: 8,
          pathSeparator: ':',
          operatingSystem: 'fake',
          operatingSystemVersion: '0.1.0',
          localHostname: 'host',
          environment: <String, String>{'PATH': '.'},
          executable: 'executable',
          resolvedExecutable: '/executable',
          script: Uri.file('/platform/test/fake_platform_test.dart'),
          executableArguments: <String>['scriptarg'],
          version: '0.1.1',
          stdinSupportsAnsi: false,
          stdoutSupportsAnsi: true,
          localeName: 'local',
        );
        FakePlatform copy = fake.copyWith(
          numberOfProcessors: local.numberOfProcessors,
          pathSeparator: local.pathSeparator,
          operatingSystem: local.operatingSystem,
          operatingSystemVersion: local.operatingSystemVersion,
          localHostname: local.localHostname,
          environment: local.environment,
          executable: local.executable,
          resolvedExecutable: local.resolvedExecutable,
          script: local.script,
          executableArguments: local.executableArguments,
          packageConfig: local.packageConfig,
          version: local.version,
          stdinSupportsAnsi: local.stdinSupportsAnsi,
          stdoutSupportsAnsi: local.stdoutSupportsAnsi,
          localeName: local.localeName,
        );
        _expectPlatformsEqual(copy, local);
      });
    });

    group('json', () {
      test('fromJson', () {
        String json = io.File('test/platform.json').readAsStringSync();
        fake = FakePlatform.fromJson(json);
        expect(fake.numberOfProcessors, 8);
        expect(fake.pathSeparator, '/');
        expect(fake.operatingSystem, 'macos');
        expect(fake.operatingSystemVersion, '10.14.5');
        expect(fake.localHostname, 'platform.test.org');
        expect(fake.environment, <String, String>{
          'PATH': '/bin',
          'PWD': '/platform',
        });
        expect(fake.executable, '/bin/dart');
        expect(fake.resolvedExecutable, '/bin/dart');
        expect(fake.script, Uri.file('/platform/test/fake_platform_test.dart'));
        expect(fake.executableArguments, <String>['--checked']);
        expect(fake.packageConfig, null);
        expect(fake.version, '1.22.0');
        expect(fake.localeName, 'de/de');
      });

      test('fromJsonToJson', () {
        fake = FakePlatform.fromJson(local.toJson());
        _expectPlatformsEqual(fake, local);
      });
    });
  });

  test('Throws when unset non-null values are read', () {
    final FakePlatform platform = FakePlatform();

    expect(() => platform.numberOfProcessors, throwsA(isStateError));
    expect(() => platform.pathSeparator, throwsA(isStateError));
    expect(() => platform.operatingSystem, throwsA(isStateError));
    expect(() => platform.operatingSystemVersion, throwsA(isStateError));
    expect(() => platform.localHostname, throwsA(isStateError));
    expect(() => platform.environment, throwsA(isStateError));
    expect(() => platform.executable, throwsA(isStateError));
    expect(() => platform.resolvedExecutable, throwsA(isStateError));
    expect(() => platform.script, throwsA(isStateError));
    expect(() => platform.executableArguments, throwsA(isStateError));
    expect(() => platform.version, throwsA(isStateError));
    expect(() => platform.localeName, throwsA(isStateError));
  });
}
