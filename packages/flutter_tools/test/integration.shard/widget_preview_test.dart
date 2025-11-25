// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:dtd/dtd.dart';
import 'package:file/file.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/commands/widget_preview.dart';
import 'package:flutter_tools/src/devtools_launcher.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/widget_preview/dtd_services.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/fakes.dart';
import 'test_data/basic_project.dart';
import 'test_utils.dart';

final launchingOnDeviceRegExp = RegExp(r'Launching the Widget Preview Scaffold on [a-zA-Z]+...');

final firstLaunchMessagesWeb = <Pattern>[
  'Creating widget preview scaffolding at:',
  launchingOnDeviceRegExp,
  'Done loading previews.',
];

final firstLaunchMessagesWebServer = <Pattern>[
  'Creating widget preview scaffolding at:',
  launchingOnDeviceRegExp,
  'main.dart is being served at',
  'Done loading previews.',
];

final subsequentLaunchMessagesWeb = <Pattern>[launchingOnDeviceRegExp, 'Done loading previews.'];

void main() {
  late Directory tempDir;
  Process? process;
  Logger? logger;
  DtdLauncher? dtdLauncher;
  DevtoolsLauncher? devtoolsLauncher;
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
    await devtoolsLauncher?.close();
    devtoolsLauncher = null;
    dtdLauncher = null;
    tryToDelete(tempDir);
  });

  Future<void> runWidgetPreview({
    required List<Pattern> expectedMessages,
    Uri? dtdUri,
    bool useWebServer = false,
    Uri? devToolsServerAddress,
  }) async {
    expect(expectedMessages, isNotEmpty);
    var i = 0;
    process = await processManager.start(<String>[
      flutterBin,
      'widget-preview',
      'start',
      '--verbose',
      '--${WidgetPreviewStartCommand.kHeadless}',
      if (useWebServer) '--${WidgetPreviewStartCommand.kWebServer}',
      if (dtdUri != null) '--${WidgetPreviewStartCommand.kDtdUrl}=$dtdUri',
      if (devToolsServerAddress != null)
        '--${FlutterCommand.kDevToolsServerAddress}=$devToolsServerAddress',
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

  void runFlutterClean() {
    processManager.runSync(<String>[flutterBin, 'clean'], workingDirectory: tempDir.path);
  }

  group('flutter widget-preview start', () {
    testWithoutContext('smoke test', () async {
      await runWidgetPreview(expectedMessages: firstLaunchMessagesWeb);
    });

    testWithoutContext('--web-server starts a web server instance', () async {
      await runWidgetPreview(expectedMessages: firstLaunchMessagesWebServer, useWebServer: true);
    });

    testWithoutContext(
      'runs flutter pub get in widget_preview_scaffold if '
      "widget_preview_scaffold/.dart_tool doesn't exist",
      () async {
        // Regression test for https://github.com/flutter/flutter/issues/178660
        // Generate the widget preview scaffold, but don't bother launching it.
        processManager.runSync(<String>[
          flutterBin,
          'widget-preview',
          'start',
          '--no-${WidgetPreviewStartCommand.kLaunchPreviewer}',
        ], workingDirectory: tempDir.path);

        // Ensure widget_preview_scaffold/.dart_tool/package_config.json exists.
        final Directory widgetPreviewScaffoldDartTool = tempDir
            .childDirectory('.dart_tool')
            .childDirectory('widget_preview_scaffold')
            .childDirectory('.dart_tool');
        expect(widgetPreviewScaffoldDartTool, exists);
        expect(widgetPreviewScaffoldDartTool.childFile('package_config.json'), exists);

        // Delete widget_preview_scaffold/.dart_tool/. This simulates an interrupted
        // flutter widget-preview start where 'flutter pub get' wasn't run after
        // the widget_preview_scaffold project was created.
        widgetPreviewScaffoldDartTool.deleteSync(recursive: true);

        // Ensure we don't crash due to the package_config.json lookup pointing to
        // the parent project's package_config.json due to
        // widget_preview_scaffold/.dart_tool/package_config.json not existing.
        await runWidgetPreview(expectedMessages: subsequentLaunchMessagesWeb);
      },
      // Project is always regenerated.
      skip: true, // See https://github.com/flutter/flutter/issues/179036.
    );

    testWithoutContext(
      'does not recreate project on subsequent runs',
      () async {
        // The first run of 'flutter widget-preview start' should generate a new preview scaffold
        await runWidgetPreview(expectedMessages: firstLaunchMessagesWeb);

        // We shouldn't regenerate the scaffold after the initial run.
        await runWidgetPreview(expectedMessages: subsequentLaunchMessagesWeb);
      },
      // Project is always regenerated.
      skip: true, // See https://github.com/flutter/flutter/issues/179036.
    );

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

    testUsingContext('can connect to an existing DevTools instance', () async {
      devtoolsLauncher = DevtoolsServerLauncher(
        processManager: processManager,
        logger: logger!,
        botDetector: const FakeBotDetector(true),
        artifacts: globals.artifacts!,
      );

      // Start a DevTools instance.
      final Uri devtoolsUri = (await devtoolsLauncher!.serve())!.uri!;

      // Start the widget preview and wait for the DevTools message.
      await runWidgetPreview(
        expectedMessages: [
          'The Flutter DevTools debugger and profiler on Chrome is available at: $devtoolsUri',
        ],
        devToolsServerAddress: devtoolsUri,
      );
    });

    testUsingContext("doesn't crash on flutter clean", () async {
      // Regression test for https://github.com/flutter/flutter/issues/175058.\
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
      var firstConnection = true;
      dtdConnection.onEvent(kWidgetPreviewScaffoldStream).listen((DTDEvent event) {
        expect(event.stream, kWidgetPreviewScaffoldStream);
        expect(event.kind, 'Connected');
        if (firstConnection) {
          firstConnection = false;
          runFlutterClean();
          dtdConnection.call(
            WidgetPreviewDtdServices.kWidgetPreviewService,
            WidgetPreviewDtdServices.kHotRestartPreviewer,
          );
          return;
        }
        // The second `Connected` event should come after the previewer is hot restarted after
        // we perform the `flutter clean`. This event won't be sent again if the previewer has
        // crashed.
        completer.complete();
      });
      await dtdConnection.streamListen(kWidgetPreviewScaffoldStream);

      // Start the widget preview and wait for the 'Connected' event.
      await runWidgetPreview(expectedMessages: firstLaunchMessagesWeb, dtdUri: dtdUri);
      await completer.future;
    });
  });
}
