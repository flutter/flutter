// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:io' as io show ProcessSignal;

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';
import 'test_utils.dart';

final String dart = fileSystem.path
    .join(getFlutterRoot(), 'bin', platform.isWindows ? 'dart.bat' : 'dart');

void main() {
  group('Cache.lock', () {
    // Windows locking is too flaky for this to work reliably.
    if (!platform.isWindows) {
      testWithoutContext(
          'should log a message to stderr when lock is not acquired', () async {
        final String oldRoot = Cache.flutterRoot;
        final Directory tempDir = fileSystem.systemTempDirectory.createTempSync('cache_test.');
        final BufferLogger logger = BufferLogger(
          terminal: Terminal.test(supportsColor: false, supportsEmoji: false),
          outputPreferences: OutputPreferences(),
        );
        try {
          Cache.flutterRoot = tempDir.absolute.path;
          final Cache cache = Cache.test(
            fileSystem: fileSystem,
            processManager: FakeProcessManager.any(),
            logger: logger,
          );
          final File cacheFile = fileSystem.file(fileSystem.path
              .join(Cache.flutterRoot, 'bin', 'cache', 'lockfile'))
            ..createSync(recursive: true);
          final File script = fileSystem.file(fileSystem.path
              .join(Cache.flutterRoot, 'bin', 'cache', 'test_lock.dart'));
          script.writeAsStringSync(r'''
import 'dart:async';
import 'dart:io';

Future<void> main(List<String> args) async {
  File file = File(args[0]);
  RandomAccessFile lock = file.openSync(mode: FileMode.write);
  lock.lockSync();
  await Future<void>.delayed(const Duration(milliseconds: 1000));
  exit(0);
}
''');
          final Process process = await const LocalProcessManager().start(
            <String>[dart, script.absolute.path, cacheFile.absolute.path],
          );
          await Future<void>.delayed(const Duration(milliseconds: 500));
          await cache.lock();
          process.kill(io.ProcessSignal.sigkill);
        } finally {
          try {
            tempDir.deleteSync(recursive: true);
          } on FileSystemException {
            // Ignore filesystem exceptions when trying to delete tempdir.
          }
          Cache.flutterRoot = oldRoot;
        }
        expect(logger.statusText, isEmpty);
        expect(logger.errorText,
            equals('Waiting for another flutter command to release the startup lock...\n'));
      });
    }
  });
}
