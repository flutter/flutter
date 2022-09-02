// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';

import '../integration.shard/test_data/hot_reload_project.dart';
import '../integration.shard/test_driver.dart';
import '../integration.shard/test_utils.dart';
import '../src/common.dart';

import 'test_data/hot_reload_index_html_samples.dart';

void main() async {
  await _testProject(HotReloadProject()); // default
  await _testProject(HotReloadProject(indexHtml: indexHtmlFlutterJsCallback), name: 'flutter.js (callback)');
  await _testProject(HotReloadProject(indexHtml: indexHtmlFlutterJsPromisesFull), name: 'flutter.js (promises)');
  await _testProject(HotReloadProject(indexHtml: indexHtmlFlutterJsPromisesShort), name: 'flutter.js (promises, short)');
  await _testProject(HotReloadProject(indexHtml: indexHtmlNoFlutterJs), name: 'No flutter.js');
}

Future<void> _testProject(HotReloadProject project, {String name = 'Default'}) async {
  late Directory tempDir;
  late FlutterRunTestDriver flutter;

  final String testName = 'Hot reload (index.html: $name)';

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('hot_reload_test.');
    await project.setUpIn(tempDir);
    flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    await flutter.stop();
    await flutter.done;
    tryToDelete(tempDir);
  });

  testWithoutContext('$testName: hot restart works without error', () async {
    await flutter.run(chrome: true, additionalCommandArgs: <String>['--verbose', '--web-renderer=html']);
    await flutter.hotRestart();
  });

  testWithoutContext('$testName: newly added code executes during hot restart', () async {
    final Completer<void> completer = Completer<void>();
    final StreamSubscription<String> subscription = flutter.stdout.listen((String line) {
      if (line.contains('(((((RELOAD WORKED)))))')) {
        completer.complete();
      }
    });
    await flutter.run(chrome: true, additionalCommandArgs: <String>['--verbose', '--web-renderer=html']);
    project.uncommentHotReloadPrint();
    try {
      await flutter.hotRestart();
      await completer.future.timeout(const Duration(seconds: 15));
    } finally {
      await subscription.cancel();
    }
  });

  testWithoutContext('$testName: newly added code executes during hot restart - canvaskit', () async {
    final Completer<void> completer = Completer<void>();
    final StreamSubscription<String> subscription = flutter.stdout.listen((String line) {
      if (line.contains('(((((RELOAD WORKED)))))')) {
        completer.complete();
      }
    });
    await flutter.run(chrome: true,
      additionalCommandArgs: <String>['--dart-define=FLUTTER_WEB_USE_SKIA=true', '--verbose']);
    project.uncommentHotReloadPrint();
    try {
      await flutter.hotRestart();
      await completer.future.timeout(const Duration(seconds: 15));
    } finally {
      await subscription.cancel();
    }
  }, skip: true); // Skipping for https://github.com/flutter/flutter/issues/85043.
}
