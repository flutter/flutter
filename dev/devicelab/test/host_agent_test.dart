// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_devicelab/framework/host_agent.dart';
import 'package:platform/platform.dart';

import 'common.dart';

void main() {
  FileSystem fs;
  setUp(() {
    fs = MemoryFileSystem();
    hostAgent.resetDumpDirectory();
  });

  tearDown(() {
    hostAgent.resetDumpDirectory();
  });

  group('dump directory', () {
    test('set by environment', () async {
      final Directory environmentDir = fs.directory(fs.path.join('home', 'logs'));
      final FakePlatform fakePlatform = FakePlatform(
        environment: <String, String>{'FLUTTER_LOGS_DIR': environmentDir.path},
        operatingSystem: 'windows',
      );
      final HostAgent agent = HostAgent(platform: fakePlatform, fileSystem: fs);

      expect(agent.dumpDirectory.existsSync(), isTrue);
      expect(agent.dumpDirectory.path, environmentDir.path);
    });

    test('not set by environment', () async {
      final FakePlatform fakePlatform = FakePlatform(environment: <String, String>{}, operatingSystem: 'windows');
      final HostAgent agent = HostAgent(platform: fakePlatform, fileSystem: fs);

      expect(agent.dumpDirectory.existsSync(), isTrue);
    });

    test('is the same between host agent instances', () async {
      final FakePlatform fakePlatform = FakePlatform(environment: <String, String>{}, operatingSystem: 'windows');
      final HostAgent agent1 = HostAgent(platform: fakePlatform, fileSystem: fs);
      final HostAgent agent2 = HostAgent(platform: fakePlatform, fileSystem: fs);

      expect(agent1.dumpDirectory.path, agent2.dumpDirectory.path);
    });
  });

  group('simulator logs', () {
    test('no-op on Windows', () async {
      final FakePlatform fakePlatform = FakePlatform(operatingSystem: 'windows');
      final HostAgent agent = HostAgent(platform: fakePlatform, fileSystem: fs);

      expect(await agent.dump(), isTrue);
    });

    test('no-op on Linux', () async {
      final FakePlatform fakePlatform = FakePlatform(operatingSystem: 'linux');
      final HostAgent agent = HostAgent(platform: fakePlatform, fileSystem: fs);

      expect(await agent.dump(), isTrue);
    });

    test('fails when home not found logs on macOS', () async {
      final FakePlatform fakePlatform = FakePlatform(environment: <String, String>{}, operatingSystem: 'macos');
      final HostAgent agent = HostAgent(platform: fakePlatform, fileSystem: fs);

      expect(await agent.dump(), isFalse);
    });

    test('copies simulator logs on macOS', () async {
      final Directory homeDir = fs.directory('home')..createSync();
      final FakePlatform fakePlatform = FakePlatform(
        environment: <String, String>{'HOME': homeDir.path},
        operatingSystem: 'macos',
      );
      final Directory simulatorDirectory =homeDir.childDirectory('Library').childDirectory('Logs').childDirectory('CoreSimulator');
      final Directory simulatorDirectory1 = simulatorDirectory.childDirectory('123456789');
      simulatorDirectory1.childFile('system.log')
        ..createSync(recursive: true)
        ..writeAsString('');
      simulatorDirectory1
          .childDirectory('CrashReporter')
          .childDirectory('DiagnosticLogs')
          .childFile('crash_log')
            ..createSync(recursive: true)
            ..writeAsString('');

      final Directory simulatorDirectory2 = simulatorDirectory.childDirectory('0987654321');
      simulatorDirectory2.childFile('system.log.0.gz')
        ..createSync(recursive: true)
        ..writeAsString('');

      // Empty directory to be skipped.
      simulatorDirectory.childDirectory('37129343498').createSync();

      final HostAgent agent = HostAgent(platform: fakePlatform, fileSystem: fs);

      expect(await agent.dump(), isTrue);
      final Directory simulatorRoot = agent.dumpDirectory.childDirectory('ios-simulators');
      expect(simulatorRoot.listSync().length, 2);

      final Directory expectedSimulatorDirectory1 = simulatorRoot.childDirectory('123456789');
      expect(expectedSimulatorDirectory1.listSync().length, 2);
      expect(expectedSimulatorDirectory1.childFile('system.log').existsSync(), isTrue);
      expect(expectedSimulatorDirectory1.childFile('crash_log').existsSync(), isTrue);

      final Directory expectedSimulatorDirectory2 = simulatorRoot.childDirectory('0987654321');
      expect(expectedSimulatorDirectory2.listSync().length, 1);
      expect(expectedSimulatorDirectory2.childFile('system.log.0.gz').existsSync(), isTrue);
    });
  });
}
