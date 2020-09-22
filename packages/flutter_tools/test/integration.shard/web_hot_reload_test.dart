// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';

import '../src/common.dart';
import 'test_data/hot_reload_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  Directory tempDir;
  final HotReloadProject project = HotReloadProject();
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

  testWithoutContext('newly added code executes during hot restart', () async {
    final StringBuffer stdout = StringBuffer();
    final Completer<void> onDone = Completer<void>();
    final Completer<void> onStart = Completer<void>();
    flutter.stdout.listen((String line) {
      if (line.contains('RELOAD WORKED')) {
        onDone.complete();
      }
      if (line.contains('TICK 1')) {
        onStart.complete();
      }
      stdout.write(line);
    });
    await flutter.run(chrome: true);
    await onStart.future;
    await Future<void>.delayed(const Duration(seconds: 2));
    project.uncommentHotReloadPrint();

    await flutter.hotRestart();
    await onDone.future;
    expect(stdout.toString(), contains('(((((RELOAD WORKED)))))'));
  });

  testWithoutContext('newly added code executes during hot restart - canvaskit', () async {
    final StringBuffer stdout = StringBuffer();
    final StringBuffer stderr = StringBuffer();
    final Completer<void> onDone = Completer<void>();
    final Completer<void> onStart = Completer<void>();
    flutter.stdout.listen((String line) {
      print(line);
      if (line.contains('RELOAD WORKED')) {
        onDone.complete();
      }
      if (line.contains('TICK 1')) {
        onStart.complete();
      }
      stdout.write(line);
    });

    flutter.stderr.listen(print);
    await flutter.run(chrome: true, dartDefines: <String>['FLUTTER_WEB_USE_SKIA=true']);
    await onStart.future;
    await Future<void>.delayed(const Duration(seconds: 2));
    project.uncommentHotReloadPrint();

    await flutter.hotRestart();
    await onDone.future;
    expect(stdout.toString(), contains('(((((RELOAD WORKED)))))'));
  });
}
