// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:dtd/dtd.dart';
import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/commands/widget_preview.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:flutter_tools/src/widget_preview/dtd_services.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';
import 'test_data/basic_project.dart';
import 'test_utils.dart';

final launchingOnDeviceRegExp = RegExp(r'Launching the Widget Preview Scaffold on [a-zA-Z]+...');

final firstLaunchMessagesWeb = <Pattern>[
  'Creating widget preview scaffolding at:',
  launchingOnDeviceRegExp,
  'Done loading previews.',
];

final subsequentLaunchMessagesWeb = <Pattern>[launchingOnDeviceRegExp, 'Done loading previews.'];

void main() {
  late Directory tempDir;
  Process? process;
  Logger? logger;
  DtdLauncher? dtdLauncher;
  final project = BasicProject();
  const ProcessManager processManager = LocalProcessManager();

  setUp(() async {
    logger = BufferLogger.test();
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

  Future<void> runWidgetPreview({required List<Pattern> expectedMessages, Uri? dtdUri}) async {
    expect(expectedMessages, isNotEmpty);
    var i = 0;
    process = await processManager.start(<String>[
      flutterBin,
      'widget-preview',
      'start',
      '--verbose',
      '--${WidgetPreviewStartCommand.kHeadless}',
      if (dtdUri != null) '--${FlutterGlobalOptions.kDtdUrl}=$dtdUri',
    ], workingDirectory: tempDir.path);

    final completer = Completer<void>();
    process!.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((String msg) {
      printOnFailure('STDOUT: $msg');
      if (completer.isCompleted) {
        return;
      }
      if (msg.contains(expectedMessages[i])) {
        ++i;
      }
      if (i == expectedMessages.length) {
        completer.complete();
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

  group('flutter widget-preview start', () {
    testWithoutContext('smoke test', () async {
      await runWidgetPreview(expectedMessages: firstLaunchMessagesWeb);
    });

    testWithoutContext('does not recreate project on subsequent runs', () async {
      // The first run of 'flutter widget-preview start' should generate a new preview scaffold
      await runWidgetPreview(expectedMessages: firstLaunchMessagesWeb);

      // We shouldn't regenerate the scaffold after the initial run.
      await runWidgetPreview(expectedMessages: subsequentLaunchMessagesWeb);
    });

    testUsingContext('can connect to an existing DTD instance', () async {
      dtdLauncher = DtdLauncher(
        logger: logger!,
        artifacts: globals.artifacts!,
        processManager: globals.processManager,
      );

      // Start a DTD instance.
      final Uri dtdUri = await dtdLauncher!.launch();

      // Connect to it and listen to the WidgetPreviewScaffold stream.
      //
      // The preview scaffold will send a 'Connected' event on this stream once it has initialized
      // and is ready.
      final DartToolingDaemon dtdConnection = await DartToolingDaemon.connect(dtdUri);
      const kWidgetPreviewScaffoldStream = 'WidgetPreviewScaffold';
      final completer = Completer<void>();
      dtdConnection.onEvent(kWidgetPreviewScaffoldStream).listen((DTDEvent event) {
        expect(event.stream, kWidgetPreviewScaffoldStream);
        expect(event.kind, 'Connected');
        completer.complete();
      });
      await dtdConnection.streamListen(kWidgetPreviewScaffoldStream);

      // Start the widget preview and wait for the 'Connected' event.
      await runWidgetPreview(expectedMessages: firstLaunchMessagesWeb, dtdUri: dtdUri);
      await completer.future;
    });
  });
}
