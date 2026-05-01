// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/commands/widget_preview.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import 'test_utils.dart';

final RegExp launchingOnDeviceRegExp = RegExp(
  r'Launching the Widget Preview Scaffold on [a-zA-Z]+...',
);

final List<Pattern> firstLaunchMessagesWeb = <Pattern>[
  'Creating widget preview scaffolding at:',
  launchingOnDeviceRegExp,
  'Done loading previews.',
];

final List<Pattern> firstLaunchMessagesWebServer = <Pattern>[
  'Creating widget preview scaffolding at:',
  launchingOnDeviceRegExp,
  'main.dart is being served at',
];

final List<Pattern> subsequentLaunchMessagesWeb = <Pattern>[
  launchingOnDeviceRegExp,
  'Done loading previews.',
];

const ProcessManager _processManager = LocalProcessManager();

Future<Stream<String>> startWidgetPreview({
  required Directory tempDir,
  Uri? dtdUri,
  bool useWebServer = false,
  Uri? devToolsServerAddress,
  bool legacyPreviewDetection = false,
  ProcessManager processManager = _processManager, // Allow overriding for testing if needed
}) async {
  final Process process = await processManager.start(<String>[
    flutterBin,
    'widget-preview',
    'start',
    '--verbose',
    '--${WidgetPreviewStartCommand.kHeadless}',
    '--${WidgetPreviewStartCommand.kDisableDtdServiceUuid}',
    if (useWebServer) '--${WidgetPreviewStartCommand.kWebServer}',
    if (dtdUri != null) '--${WidgetPreviewStartCommand.kDtdUrl}=$dtdUri',
    if (devToolsServerAddress != null)
      '--${FlutterCommand.kDevToolsServerAddress}=$devToolsServerAddress',
    if (legacyPreviewDetection) '--legacy-preview-detection',
  ], workingDirectory: tempDir.path);

  addTearDown(() async {
    process.kill();
    await process.exitCode;
  });

  final controller = StreamController<String>.broadcast();
  process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((String msg) {
    // ignore: avoid_print
    print('[stdout] $msg');
    if (!controller.isClosed) {
      controller.add(msg);
    }
  });

  process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((String msg) {
    // ignore: avoid_print
    print('[stderr] $msg');
  });

  unawaited(
    process.exitCode.then((int exitCode) {
      if (!controller.isClosed) {
        controller.close();
      }
    }),
  );

  return controller.stream;
}

Future<Stream<String>> runWidgetPreview({
  required Directory tempDir,
  required List<Pattern> expectedMessages,
  Uri? dtdUri,
  bool useWebServer = false,
  Uri? devToolsServerAddress,
  bool legacyPreviewDetection = false,
  ProcessManager processManager = _processManager,
}) async {
  expect(expectedMessages, isNotEmpty);
  var i = 0;
  final Stream<String> stream = await startWidgetPreview(
    tempDir: tempDir,
    dtdUri: dtdUri,
    useWebServer: useWebServer,
    devToolsServerAddress: devToolsServerAddress,
    legacyPreviewDetection: legacyPreviewDetection,
    processManager: processManager,
  );

  final completer = Completer<void>();
  final StreamSubscription<String> subscription = stream.listen(
    (String msg) {
      if (completer.isCompleted) {
        return;
      }
      if (msg.contains(expectedMessages[i])) {
        ++i;
      }
      if (i == expectedMessages.length) {
        completer.complete();
      }
    },
    onDone: () {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError(
            'Stream closed before all expected messages were seen! Expected: ${expectedMessages.map((Pattern p) => p.toString()).join(', ')}, but saw only up to index $i',
          ),
        );
      }
    },
  );

  await completer.future;
  await subscription.cancel();
  return stream;
}

void runFlutterClean(Directory tempDir, [ProcessManager processManager = _processManager]) {
  processManager.runSync(<String>[flutterBin, 'clean'], workingDirectory: tempDir.path);
}
