// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:flutter_tools/src/base/file_system.dart';

import '../src/common.dart';
import 'test_data/single_widget_reload_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  Directory tempDir;
  final SingleWidgetReloadProject project = SingleWidgetReloadProject();
  FlutterRunTestDriver flutter;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('hot_reload_test.');
    await project.setUpIn(tempDir);
    flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    await flutter?.stop();
    tryToDelete(tempDir);
  });

  testWithoutContext('newly added code executes during hot reload with single widget reloads, but only invalidated widget', () async {
    final StringBuffer stdout = StringBuffer();
    final StreamSubscription<String> subscription = flutter.stdout.listen(stdout.writeln);
    await flutter.run(singleWidgetReloads: true);
    project.uncommentHotReloadPrint();
    try {
      await flutter.hotReload();
      expect(stdout.toString(), allOf(
        contains('(((TICK 1)))'),
        contains('(((((RELOAD WORKED)))))'),
        // Does not invalidate parent widget, so second tick is not output.
        isNot(contains('(((TICK 2)))'),
      )));
    } finally {
      await subscription.cancel();
    }
  });

  testWithoutContext('changes outside of the class body triggers a full reload', () async {
    final StringBuffer stdout = StringBuffer();
    final StreamSubscription<String> subscription = flutter.stdout.listen(stdout.writeln);
    await flutter.run(singleWidgetReloads: true);
    project.modifyFunction();
    try {
      await flutter.hotReload();
      expect(stdout.toString(), allOf(
        contains('(((TICK 1)))'),
        contains('(((TICK 2)))'),
      ));
    } finally {
      await subscription.cancel();
    }
  });
}
