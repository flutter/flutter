// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/commands/widget_preview.dart';
import 'package:flutter_tools/src/widget_preview/dtd_services.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import 'test_data/basic_project.dart';
import 'test_utils.dart';

const launchEvents = <String>['widget_preview.started'];

void main() {
  late Directory tempDir;
  Process? process;
  DtdLauncher? dtdLauncher;
  final project = BasicProject();
  const ProcessManager processManager = LocalProcessManager();

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('widget_preview_test.');
    await project.setUpIn(tempDir);
  });

  tearDown(() async {
    process?.kill();
    process = null;
    await dtdLauncher?.dispose();
    dtdLauncher = null;
    tryToDelete(tempDir);
  });

  Future<void> runWidgetPreviewMachineMode({
    required List<String> expectedEvents,
    bool useWebServer = false,
  }) async {
    expect(expectedEvents, isNotEmpty);
    var i = 0;
    process = await processManager.start(<String>[
      flutterBin,
      'widget-preview',
      'start',
      '--machine',
      '--${WidgetPreviewStartCommand.kHeadless}',
      if (useWebServer) '--${WidgetPreviewStartCommand.kWebServer}',
    ], workingDirectory: tempDir.path);

    final completer = Completer<void>();
    process!.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((
      String message,
    ) {
      printOnFailure('STDOUT: $message');
      if (completer.isCompleted) {
        return;
      }
      try {
        final Object? event = json.decode(message);
        if (event case [{'event': final String event}]) {
          if (expectedEvents[i] == event) {
            ++i;
          }
        }
        if (i == expectedEvents.length) {
          completer.complete();
        }
      } on FormatException {
        // Do nothing.
      }
    });

    process!.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((String msg) {
      printOnFailure('STDERR: $msg');
    });

    unawaited(
      process!.exitCode.then((int exitCode) {
        if (completer.isCompleted) {
          return;
        }
        completer.completeError(
          TestFailure('The widget previewer exited unexpectedly (exit code: $exitCode)'),
        );
      }),
    );
    await completer.future;
  }

  group('flutter widget-preview start --machine', () {
    testWithoutContext('smoke test', () async {
      await runWidgetPreviewMachineMode(expectedEvents: launchEvents);
    });
  });
}
