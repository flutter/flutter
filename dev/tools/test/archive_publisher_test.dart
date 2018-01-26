// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

import 'package:path/path.dart' as path;

import '../lib/archive_publisher.dart';
import 'fake_process_manager.dart';

void main() {
  group('ArchivePublisher', () {
    final List<String> emptyStdout = <String>[''];
    FakeProcessManager processManager;
    Directory tempDir;

    setUp(() async {
      processManager = new FakeProcessManager();
      tempDir = await Directory.systemTemp.createTemp('flutter_');
    });

    tearDown(() async {
      // On Windows, the directory is locked and not able to be deleted, because it is a
      // temporary directory. So we just leave some (very small, because we're not actually
      // building archives here) trash around to be deleted at the next reboot.
      if (!Platform.isWindows) {
        await tempDir.delete(recursive: true);
      }
    });

    test('calls the right processes', () {
      final Map<String, List<String>> calls = <String, List<String>>{
        'gsutil acl get gs://flutter_infra/releases/releases.json': emptyStdout,
        'gsutil cp gs://flutter_infra/flutter/deadbeef/flutter_linux_deadbeef.tar.xz '
            'gs://flutter_infra/releases/dev/linux/flutter_linux_1.2.3-dev.tar.xz': emptyStdout,
        'gsutil cp gs://flutter_infra/flutter/deadbeef/flutter_mac_deadbeef.tar.xz '
            'gs://flutter_infra/releases/dev/mac/flutter_mac_1.2.3-dev.tar.xz': emptyStdout,
        'gsutil cp gs://flutter_infra/flutter/deadbeef/flutter_win_deadbeef.zip '
            'gs://flutter_infra/releases/dev/win/flutter_win_1.2.3-dev.zip': emptyStdout,
        'gsutil cat gs://flutter_infra/releases/releases.json': <String>[
          '''{
    "base_url": "https://storage.googleapis.com/flutter_infra/releases",
    "current_beta": "6da8ec6bd0c4801b80d666869e4069698561c043",
    "current_dev": "f88c60b38c3a5ef92115d24e3da4175b4890daba",
    "releases": {
        "6da8ec6bd0c4801b80d666869e4069698561c043": {
            "linux_archive": "beta/linux/flutter_linux_0.21.0-beta.tar.xz",
            "mac_archive": "beta/mac/flutter_mac_0.21.0-beta.tar.xz",
            "windows_archive": "beta/win/flutter_win_0.21.0-beta.tar.xz",
            "release_date": "2017-12-19T10:30:00,847287019-08:00",
            "release_notes": "beta/release_notes_0.21.0-beta.html",
            "version": "0.21.0-beta"
        },
        "f88c60b38c3a5ef92115d24e3da4175b4890daba": {
            "linux_archive": "dev/linux/flutter_linux_0.22.0-dev.tar.xz",
            "mac_archive": "dev/mac/flutter_mac_0.22.0-dev.tar.xz",
            "windows_archive": "dev/win/flutter_win_0.22.0-dev.tar.xz",
            "release_date": "2018-01-19T13:30:09,728487019-08:00",
            "release_notes": "dev/release_notes_0.22.0-dev.html",
            "version": "0.22.0-dev"
        }
    }
}
'''],
        'gsutil cp ${tempDir.path}/releases.json gs://flutter_infra/releases/releases.json':
            emptyStdout,
      };
      processManager.setResults(calls);
      new ArchivePublisher('deadbeef', '1.2.3', Channel.dev,
          processManager: processManager, tempDir: tempDir)
        ..publishArchive();
      processManager.verifyCalls(calls.keys);
      final File outputFile = new File(path.join(tempDir.path, 'releases.json'));
      expect(outputFile.existsSync(), isTrue);
      final String contents = outputFile.readAsStringSync();
      expect(contents, contains('"current_dev": "deadbeef"'));
      expect(contents, contains('"deadbeef": {'));
    });
  });
}
