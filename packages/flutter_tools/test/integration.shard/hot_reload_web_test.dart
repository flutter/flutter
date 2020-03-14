// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import '../src/common.dart';
import 'test_data/hot_reload_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  Directory tempDir;
  final HotReloadProject project = HotReloadProject();
  FlutterRunTestDriver flutter;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('hot_reload_web_test.');
    await project.setUpIn(tempDir);
    flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    await flutter?.stop();
    tryToDelete(tempDir);
  });

  test('newly added code executes during hot restart', () async {
    final StringBuffer stdout = StringBuffer();
    final Completer<void> onReloadWorked = Completer<void>();
    final StreamSubscription<String> subscription = flutter.stdout.listen((String line) {
      if (line.contains('(RELOAD WORKED)')) {
        onReloadWorked.complete();
      }
    });
    await flutter.run(chrome: true);
    project.uncommentHotReloadPrint();
    try {
      await flutter.hotRestart();
      await onReloadWorked.future;
    } finally {
      await subscription.cancel();
    }
  }, skip: !Platform.isLinux); // only linux shards have Chrome installed.
}
