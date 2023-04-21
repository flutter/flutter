// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_flutter_tree.dart';
import 'test_utils.dart';

Future<void> main() async {
  group('snapshot cache', () {
    tearDownAll(TestFlutterTree.dispose);

    final List<Matcher> upgradeMatcherList = <Matcher>[
      startsWith('pub upgrade:'),
      startsWith('generate-snapshot:'),
    ];

    final Matcher isCacheHit = isNot(anyElement(anyOf(upgradeMatcherList)));
    final Matcher isCacheMiss = containsAllInOrder(upgradeMatcherList);

    test('change nothing -> hit cache', () {
      final TestFlutterTree tree = TestFlutterTree.takeWarm();
      expect(tree.ensureToolWithFakeDart(), isCacheHit);
    });

    test('change engine version -> invalidate snapshot cache', () {
      final TestFlutterTree tree = TestFlutterTree.takeWarm();
      // Simulate rolling the engine version (with no other changes)…
      const String fakeEngineVersion = '0123456789abcdef0123456789abcdef012345678';
      tree.engineVersionFile.writeAsStringSync('$fakeEngineVersion\n');
      tree.runSyncSuccess(commitCmd);
      // … and having already downloaded the new version's Dart SDK.
      tree.engineStampFile.writeAsStringSync('$fakeEngineVersion\n');
      // The entrypoint script should recompile the snapshot.
      expect(tree.ensureToolWithFakeDart(), isCacheMiss);
    });

    test('change tool pubspec.yaml -> invalidate cache', () {
      final TestFlutterTree tree = TestFlutterTree.takeWarm();
      mungeFile(tree.toolsPackageDir.childFile('pubspec.yaml')); // packages/flutter_tools/pubspec.yaml
      tree.runSyncSuccess(commitCmd);
      expect(tree.ensureToolWithFakeDart(), isCacheMiss);
    });

    test('change tool bin-dart script -> invalidate cache', () {
      final TestFlutterTree tree = TestFlutterTree.takeWarm();
      mungeFile(tree.toolsPackageDir.childDirectory('bin').childFile('flutter_tools.dart')); // packages/flutter_tools/bin/flutter_tools.dart
      tree.runSyncSuccess(commitCmd);
      expect(tree.ensureToolWithFakeDart(), isCacheMiss);
    });

    test('change some tool source file -> invalidate cache', () {
      final TestFlutterTree tree = TestFlutterTree.takeWarm();
      final Directory toolsLibSrc = tree.toolsPackageDir.childDirectory('lib').childDirectory('src');
      mungeFile(toolsLibSrc.childFile('device.dart')); // packages/flutter_tools/lib/src/device.dart
      tree.runSyncSuccess(commitCmd);
      expect(tree.ensureToolWithFakeDart(), isCacheMiss);
    });

    test('add a tool source file -> invalidate cache', () {
      final TestFlutterTree tree = TestFlutterTree.takeWarm();
      final Directory toolsLibSrc = tree.toolsPackageDir.childDirectory('lib').childDirectory('src');
      addFile(tree, toolsLibSrc.childFile('device_differently.dart'));
      tree.runSyncSuccess(commitCmd);
      expect(tree.ensureToolWithFakeDart(), isCacheMiss);
    });

    test('remove some tool source file -> invalidate cache', () {
      final TestFlutterTree tree = TestFlutterTree.takeWarm();
      final Directory toolsLibSrc = tree.toolsPackageDir.childDirectory('lib').childDirectory('src');
      removeFile(tree, toolsLibSrc.childFile('device.dart')); // packages/flutter_tools/lib/src/device.dart
      tree.runSyncSuccess(commitCmd);
      // In removing a tool source file, we're counting extra hard on
      // the fake Dart not attempting to actually compile the tool.
      // (If we wanted to remove a source file that's part of the tool -- so that
      // it really should cause a cache miss -- and yet have the resulting tree
      // validly compile, then we'd have to work a lot harder.)
      expect(tree.ensureToolWithFakeDart(), isCacheMiss);
    });

    test('change tool tests -> hit cache', () {
      final TestFlutterTree tree = TestFlutterTree.takeWarm();
      final Directory testDir = tree.toolsPackageDir.childDirectory('test'); // packages/flutter_tools/test/
      mungeFile(testDir.childDirectory('src').childFile('common.dart'));
      mungeFile(testDir.childDirectory('general.shard').childFile('compile_test.dart'));
      mungeFile(testDir.childDirectory('data').childDirectory('asset_test').childDirectory('main').childFile('pubspec.yaml'));
      tree.runSyncSuccess(commitCmd);
      expect(tree.ensureToolWithFakeDart(), isCacheHit);
    });

    test('change framework -> hit cache', () {
      final TestFlutterTree tree = TestFlutterTree.takeWarm();
      mungeFile(tree.frameworkDir.childFile('pubspec.yaml'));
      mungeFile(tree.frameworkDir.childDirectory('lib').childFile('foundation.dart'));
      mungeFile(tree.frameworkDir.childDirectory('lib').childDirectory('src').childDirectory('widgets').childFile('framework.dart'));
      mungeFile(tree.frameworkDir.childDirectory('test').childDirectory('rendering').childFile('box_test.dart'));
      tree.runSyncSuccess(commitCmd);
      expect(tree.ensureToolWithFakeDart(), isCacheHit);
    });

    test('change example app -> hit cache', () {
      final TestFlutterTree tree = TestFlutterTree.takeWarm();
      mungeFile(tree.helloWorldDir.childFile('pubspec.yaml'));
      mungeFile(tree.helloWorldDir.childDirectory('android').childDirectory('app').childFile('build.gradle'));
      mungeFile(tree.helloWorldDir.childDirectory('lib').childFile('main.dart'));
      removeFile(tree, tree.helloWorldDir.childDirectory('lib').childFile('arabic.dart'));
      addFile(tree, tree.helloWorldDir.childDirectory('lib').childFile('other.dart'));
      tree.runSyncSuccess(commitCmd);
      expect(tree.ensureToolWithFakeDart(), isCacheHit);
    });
  },
  // These tests rely on copying directory trees around.  In general that's not
  // as reliable an operation on macOS (or Windows) as one would like, so to
  // reduce the risk of flakes we run these tests only on Linux.
  // (The actual code under test is much less demanding than the tests.)
  skip: !platform.isLinux); // [intended] Windows does not use the bash entrypoint; and avoid possible flakes on macOS

  test('verify terminating flutter/bin/dart terminates the underlying dart process', () async {
    // A test Dart app that will run until it receives SIGTERM
    final File listenForSigtermScript = hostFlutterTree.toolsPackageDir
      .childDirectory('test')
      .childDirectory('integration.shard')
      .childDirectory('test_data')
      .childFile('listen_for_sigterm.dart');

    final Completer<void> childReadyCompleter = Completer<void>();
    String stdout = '';
    final Process process = await processManager.start(
        <String>[
          hostFlutterTree.binDart.path,
          listenForSigtermScript.path,
        ],
    );
    final Future<Object?> stdoutFuture = process.stdout
        .transform<String>(utf8.decoder)
        .forEach((String str) {
          stdout += str;
          if (stdout.contains('Ready to receive signals') && !childReadyCompleter.isCompleted) {
            childReadyCompleter.complete();
          }
        });
    // Ensure that the child app has registered its signal handler
    await childReadyCompleter.future;
    final bool killSuccess = process.kill();
    expect(killSuccess, true);
    // Wait for stdout to complete
    await stdoutFuture;
    // Ensure child exited successfully
    expect(
        await process.exitCode,
        0,
        reason: 'child process exited with code ${await process.exitCode}, and '
        'stdout:\n$stdout',
    );
    expect(stdout, contains('Successfully received SIGTERM!'));
  },
  skip: platform.isWindows); // [intended] Windows does not use the bash entrypoint
}

void mungeFile(File file) {
  assert(file.existsSync());
  file.writeAsStringSync('\n', mode: FileMode.append);
}

void addFile(TestFlutterTree tree, File file) {
  assert(!file.existsSync());
  file.writeAsStringSync('// contents\n');
  tree.runSyncSuccess(<String>['git', 'add', '--', file.path]);
}

void removeFile(TestFlutterTree tree, File file) {
  assert(file.existsSync());
  tree.runSyncSuccess(<String>['git', 'rm', '--', file.path]);
}

const List<String> commitCmd = <String>['git', 'commit', '-am', 'test commit'];
