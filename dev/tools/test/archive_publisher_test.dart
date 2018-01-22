// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

import '../lib/archive_publisher.dart';
import 'fake_process_manager.dart';

void main() {
  group('ArchivePublisher', () {
    FakeProcessManager processManager;
    Directory tmpDir;

    void _setupResults(Map<String, List<String>> results) {
      final Map<String, List<ProcessResult>> resultCodeUnits = <String, List<ProcessResult>>{};
      for (String key in results.keys) {
        resultCodeUnits[key] =
            results[key].map((String result) => new ProcessResult(0, 0, result.codeUnits, <int>[]));
      }
      processManager = new FakeProcessManager(resultCodeUnits);
    }

    setUp(() async {
      tmpDir = await Directory.systemTemp.createTemp('flutter_');
    });

    tearDown(() async {
      // On Windows, the directory is locked and not able to be deleted, because it is a
      // temporary directory. So we just leave some (very small, because we're not actually
      // building archives here) trash around to be deleted at the next reboot.
      if (!Platform.isWindows) {
        await tmpDir.delete(recursive: true);
      }
    });

    test('calls the right processes', () {
      _setupResults(<String, List<String>>{
        'ls foo bar': <String>['foo\nbar\n']
      });
      new ArchivePublisher('deadbeef', '1.2.3', 'dev', processManager: processManager);
    });
  });
}
