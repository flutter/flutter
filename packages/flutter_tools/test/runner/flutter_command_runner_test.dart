// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/common.dart';
import '../src/context.dart';
import 'flutter_command_test.dart';

void main() {
  group('FlutterCommandRunner', () {
    testUsingContext('checks that Flutter installation is up-to-date', () async {
      final MockFlutterVersion version = FlutterVersion.instance;
      bool versionChecked = false;
      when(version.checkFlutterVersionFreshness()).thenAnswer((_) async {
        versionChecked = true;
      });

      await createTestCommandRunner(new DummyFlutterCommand(shouldUpdateCache: false))
          .run(<String>['dummy']);

      expect(versionChecked, isTrue);
    });
  });

  MemoryFileSystem fs;

  setUp(() {
    fs = new MemoryFileSystem();
  });

  testUsingContext('getRepoPackages', () {
    final FlutterCommandRunner runner = new FlutterCommandRunner();
    final String root = fs.path.absolute(Cache.flutterRoot);
    fs.directory(fs.path.join(root, 'examples'))
      .createSync(recursive: true);
    fs.directory(fs.path.join(root, 'packages'))
      .createSync(recursive: true);
    fs.directory(fs.path.join(root, 'dev', 'tools', 'aatool'))
      .createSync(recursive: true);

    fs.file(fs.path.join(root, 'dev', 'tools', 'pubspec.yaml')).createSync();
    fs.file(fs.path.join(root, 'dev', 'tools', 'aatool', 'pubspec.yaml')).createSync();

    final List<String> packagePaths = runner.getRepoPackages()
      .map((Directory d) => d.path).toList();
    expect(packagePaths, <String>[
      fs.directory(fs.path.join(root, 'dev', 'tools', 'aatool')).path,
      fs.directory(fs.path.join(root, 'dev', 'tools')).path,
    ]);
  }, overrides: <Type, Generator>{ FileSystem: () => fs });
}
