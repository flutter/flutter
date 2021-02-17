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

  group('dump files', () {
    test('copies files and directories', () async {
      final File resultsFile = fs.file('results.json')..writeAsString('');
      final Directory resultsDirectory = fs.directory('results')..createSync();
      resultsDirectory.childFile('A.trace').writeAsString('');
      resultsDirectory.childFile('B.trace').writeAsString('');
      resultsDirectory.childDirectory('more_results').createSync();

      final FakePlatform fakePlatform = FakePlatform(environment: <String, String>{}, operatingSystem: 'windows');
      final HostAgent agent = HostAgent(platform: fakePlatform, fileSystem: fs);

      agent.dumpFiles(<String>[
        resultsFile.path,
        resultsDirectory.path,
      ]);

      final Directory dumpDirectory = fs.directory(agent.dumpDirectory.path);
      expect(dumpDirectory.childFile('results.json').existsSync(), isTrue);

      final Directory copiedResultsDirectory = dumpDirectory.childDirectory('results');
      expect(copiedResultsDirectory.childFile('A.trace').existsSync(), isTrue);
      expect(copiedResultsDirectory.childFile('B.trace').existsSync(), isTrue);
      expect(copiedResultsDirectory.childDirectory('more_results').existsSync(), isTrue);
    });

    test('handles null files', () async {
      final FakePlatform fakePlatform = FakePlatform(environment: <String, String>{}, operatingSystem: 'windows');
      final HostAgent agent = HostAgent(platform: fakePlatform, fileSystem: fs);

      // Doesn't throw.
      agent.dumpFiles(null);
    });

    test('handles empty files', () async {
      final FakePlatform fakePlatform = FakePlatform(environment: <String, String>{}, operatingSystem: 'windows');
      final HostAgent agent = HostAgent(platform: fakePlatform, fileSystem: fs);

      // Doesn't throw.
      agent.dumpFiles(<String>[]);
    });
  });
}
