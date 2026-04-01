// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dtd/dtd.dart';
import 'package:file/file.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/commands/widget_preview.dart';
import 'package:flutter_tools/src/devtools_launcher.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/widget_preview/dtd_services.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/fakes.dart';
import 'test_data/basic_project.dart';
import 'test_utils.dart';
import 'widget_preview_test_helpers.dart';

void main() {
  late Directory tempDir;
  Logger? logger;
  DtdLauncher? dtdLauncher;
  DevtoolsServerLauncher? devtoolsLauncher;
  final project = BasicProject();
  const ProcessManager processManager = LocalProcessManager();

  setUp(() async {
    logger = BufferLogger.test();
    tempDir = createResolvedTempDirectorySync('widget_preview_smoke_test.');
    await project.setUpIn(tempDir);
  });

  tearDown(() async {
    await dtdLauncher?.dispose();
    await devtoolsLauncher?.close();
    devtoolsLauncher = null;
    dtdLauncher = null;
    tryToDelete(tempDir);
  });

  group('flutter widget-preview start', () {
    testWithoutContext('smoke test', () async {
      await runWidgetPreview(tempDir: tempDir, expectedMessages: firstLaunchMessagesWeb);
    });

    testWithoutContext('--web-server starts a web server instance', () async {
      await runWidgetPreview(
        tempDir: tempDir,
        expectedMessages: firstLaunchMessagesWebServer,
        useWebServer: true,
      );
    });

    testWithoutContext(
      'runs flutter pub get in widget_preview_scaffold if '
      "widget_preview_scaffold/.dart_tool doesn't exist",
      () async {
        processManager.runSync(<String>[
          flutterBin,
          'widget-preview',
          'start',
          '--no-${WidgetPreviewStartCommand.kLaunchPreviewer}',
        ], workingDirectory: tempDir.path);

        final Directory widgetPreviewScaffoldDartTool = tempDir
            .childDirectory('.dart_tool')
            .childDirectory('widget_preview_scaffold')
            .childDirectory('.dart_tool');
        expect(widgetPreviewScaffoldDartTool, exists);
        expect(widgetPreviewScaffoldDartTool.childFile('package_config.json'), exists);

        widgetPreviewScaffoldDartTool.deleteSync(recursive: true);

        await runWidgetPreview(tempDir: tempDir, expectedMessages: subsequentLaunchMessagesWeb);
      },
      skip: true, // Re-skipping as requested by previous skip annotation
    );

    testWithoutContext('does not recreate project on subsequent runs', () async {
      await runWidgetPreview(tempDir: tempDir, expectedMessages: firstLaunchMessagesWeb);
      await runWidgetPreview(tempDir: tempDir, expectedMessages: subsequentLaunchMessagesWeb);
    }, skip: true);

    testUsingContext('can connect to an existing DTD instance', () async {
      dtdLauncher = DtdLauncher(
        logger: logger!,
        artifacts: globals.artifacts!,
        processManager: globals.processManager,
      );

      final Uri dtdUri = await dtdLauncher!.launch();
      final DartToolingDaemon dtdConnection = await DartToolingDaemon.connect(dtdUri);
      final completer = Completer<void>();

      dtdConnection.onEvent(WidgetPreviewDtdServices.kWidgetPreviewScaffoldStreamRoot).listen((
        DTDEvent event,
      ) {
        expect(event.stream, WidgetPreviewDtdServices.kWidgetPreviewScaffoldStreamRoot);
        expect(event.kind, 'Connected');
        completer.complete();
      });
      await dtdConnection.streamListen(WidgetPreviewDtdServices.kWidgetPreviewScaffoldStreamRoot);

      await runWidgetPreview(
        tempDir: tempDir,
        expectedMessages: firstLaunchMessagesWeb,
        dtdUri: dtdUri,
      );
      await completer.future;
    });

    testUsingContext('can connect to an existing DevTools instance', () async {
      devtoolsLauncher = DevtoolsServerLauncher(
        processManager: processManager,
        logger: logger!,
        botDetector: const FakeBotDetector(true),
        artifacts: globals.artifacts!,
      );

      final Uri devtoolsUri = (await devtoolsLauncher!.serve())!.uri!;

      await runWidgetPreview(
        tempDir: tempDir,
        expectedMessages: <Pattern>[
          'The Flutter DevTools debugger and profiler on Chrome is available at: $devtoolsUri',
        ],
        devToolsServerAddress: devtoolsUri,
      );
    });

    testUsingContext("doesn't crash on flutter clean", () async {
      dtdLauncher = DtdLauncher(
        logger: logger!,
        artifacts: globals.artifacts!,
        processManager: globals.processManager,
      );

      final Uri dtdUri = await dtdLauncher!.launch();
      final DartToolingDaemon dtdConnection = await DartToolingDaemon.connect(dtdUri);
      final completer = Completer<void>();
      var firstConnection = true;

      dtdConnection.onEvent(WidgetPreviewDtdServices.kWidgetPreviewScaffoldStreamRoot).listen((
        DTDEvent event,
      ) {
        expect(event.stream, WidgetPreviewDtdServices.kWidgetPreviewScaffoldStreamRoot);
        expect(event.kind, 'Connected');
        if (firstConnection) {
          firstConnection = false;
          runFlutterClean(tempDir);
          dtdConnection.call(
            WidgetPreviewDtdServices.kWidgetPreviewServiceRoot,
            WidgetPreviewDtdServices.kHotRestartPreviewer,
          );
          return;
        }
        completer.complete();
      });
      await dtdConnection.streamListen(WidgetPreviewDtdServices.kWidgetPreviewScaffoldStreamRoot);

      await runWidgetPreview(
        tempDir: tempDir,
        expectedMessages: firstLaunchMessagesWeb,
        dtdUri: dtdUri,
      );
      await completer.future;
    });
  });
}
