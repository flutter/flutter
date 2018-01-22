// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:process/process.dart';

import '../lib/archive_publisher.dart';

void main() {
  group('ArchivePublisher', () {
    setUp(() async {
      processManager = new MockProcessManager();
      args.clear();
      namedArgs.clear();
      tmpDir = await Directory.systemTemp.createTemp('flutter_');
      outputFile =
      new File(path.join(tmpDir.absolute.path, ArchiveCreator.defaultArchiveName('master')));
      flutterDir = new Directory(path.join(tmpDir.path, 'flutter'));
      flutterDir.createSync(recursive: true);
      flutterExe =
        path.join(flutterDir.path, 'bin', 'flutter');
    });

    tearDown(() async {
      // On Windows, the directory is locked and not able to be deleted, because it is a
      // temporary directory. So we just leave some (very small, because we're not actually
      // building archives here) trash around to be deleted at the next reboot.
      if (!Platform.isWindows) {
        await tmpDir.delete(recursive: true);
      }
    });
  });
}
