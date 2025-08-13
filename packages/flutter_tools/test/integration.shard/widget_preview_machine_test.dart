// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/commands/widget_preview.dart';
import 'package:flutter_tools/src/widget_preview/dtd_services.dart';
import 'package:http/http.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import 'test_data/basic_project.dart';
import 'test_utils.dart';

typedef ExpectedEvent = ({String event, FutureOr<void> Function(Map<String, Object?>)? validator});

final launchEvents = <ExpectedEvent>[
  (
    event: 'widget_preview.started',
    validator: (Map<String, Object?> params) async {
      if (params case {'uri': final String uri}) {
        try {
          final Response response = await get(Uri.parse(uri));
          expect(response.statusCode, HttpStatus.ok, reason: 'Failed to retrieve widget previewer');
        } catch (e) {
          fail('Failed to access widget previewer: $e');
        }
      }
    },
  ),
];

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
    required List<ExpectedEvent> expectedEvents,
    bool useWebServer = false,
  }) async {
    expect(expectedEvents, isNotEmpty);
    process = await processManager.start(<String>[
      flutterBin,
      'widget-preview',
      'start',
      '--machine',
      '--${WidgetPreviewStartCommand.kHeadless}',
      if (useWebServer) '--${WidgetPreviewStartCommand.kWebServer}',
    ], workingDirectory: tempDir.path);

    final completer = Completer<void>();
    var nextExpectationIndex = 0;
    process!.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((
      String message,
    ) async {
      printOnFailure('STDOUT: $message');
      if (completer.isCompleted) {
        return;
      }
      try {
        final Object? event = json.decode(message);
        if (event case [final Map<String, Object?> eventObject]) {
          final ExpectedEvent expectation = expectedEvents[nextExpectationIndex];
          if (expectation.event == eventObject['event']) {
            await expectation.validator?.call(eventObject);
            ++nextExpectationIndex;
          }
        }
        if (nextExpectationIndex == expectedEvents.length) {
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
    testWithoutContext('launches in browser', () async {
      await runWidgetPreviewMachineMode(expectedEvents: launchEvents);
    });

    testWithoutContext('launches web server', () async {
      await runWidgetPreviewMachineMode(expectedEvents: launchEvents, useWebServer: true);
    });
  });
}
