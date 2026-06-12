// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:dtd/dtd.dart';
import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/commands/widget_preview.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/widget_preview/dtd_types.dart';
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
    if (platform.isWindows) {
      try {
        processManager.runSync(<String>['taskkill', '/F', '/T', '/PID', '${process.pid}']);
      } on Object catch (_) {
        process.kill();
      }
      await process.exitCode;
    } else {
      process.kill();
      await process.exitCode;
    }
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

Future<DTDResponse> getPreviews(DartToolingDaemon dtdConnection) async {
  if (platform.isWindows) {
    // Give the slow Windows filesystem and analysis server plenty of time
    // to finish subsequent analysis runs and rebuild the semantic model.
    await Future<void>.delayed(const Duration(seconds: 2));
  }
  return dtdConnection.call('Lsp', 'dart/workspace/getFlutterWidgetPreviews');
}

/// Polls DTD for widget previews until the [predicate] is met, or [timeout] is reached.
///
/// This is useful in integration tests to wait for the background analysis server
/// to finish analyzing changes and updating the semantic model.
///
/// Polls DTD for widget previews until the [predicate] is met, or [timeout] is reached.
///
/// If [predicate] is null, it defaults to waiting until the previews list is not empty.
///
/// This is useful in integration tests to wait for the background analysis server
/// to finish analyzing changes and updating the semantic model.
///
/// Gracefully ignores all [Object]s (such as DTD connection issues, RPC errors, or
/// temporary parsing errors) during polling, as these are often temporary while
/// the server is re-analyzing. Swallowed errors are logged to stdout for diagnostics
/// in case of timeouts.
Future<FlutterWidgetPreviews> waitForPreviews(
  DartToolingDaemon dtdConnection, {
  bool Function(FlutterWidgetPreviews)? predicate,
  Duration timeout = const Duration(seconds: 10),
  Duration pollInterval = const Duration(milliseconds: 200),
}) async {
  final stopwatch = Stopwatch()..start();
  late FlutterWidgetPreviews previews;
  final bool Function(FlutterWidgetPreviews) actualPredicate =
      predicate ?? (FlutterWidgetPreviews p) => p.previews.isNotEmpty;
  while (stopwatch.elapsed < timeout) {
    try {
      final DTDResponse result = await dtdConnection.call(
        'Lsp',
        'dart/workspace/getFlutterWidgetPreviews',
      );
      previews = FlutterWidgetPreviews.fromJson(result.result['result']! as Map<String, Object?>);
      if (actualPredicate(previews)) {
        return previews;
      }
    } on Object catch (e) {
      // During file modification, the background Analysis Server re-analyzes the project.
      // This transition state can cause DTD to temporarily return RPC errors (e.g., if the
      // LSP service is temporarily re-registering or busy), socket/connection issues, or
      // transient JSON parsing errors if we query in the middle of an update.
      //
      // We catch and ignore all errors here to allow the polling loop to continue and tolerate
      // these transient hiccups. Any genuine, non-transient errors will eventually cause a
      // timeout, at which point we will perform a final query without a try-catch to propagate
      // the real failure.
      //
      // We print the swallowed error so that if the test does time out, the developer can
      // see the history of transient errors in the test output for diagnostics.
      // ignore: avoid_print
      print('waitForPreviews: swallowed transient error during polling: $e');
    }
    await Future<void>.delayed(pollInterval);
  }

  // If we timed out, we perform one last query *without* a try-catch. If the failure is
  // permanent (e.g., the Analysis Server crashed or the method is genuinely unimplemented),
  // this call will throw and propagate the real exception/stack trace to fail the test clearly.
  final DTDResponse result = await dtdConnection.call(
    'Lsp',
    'dart/workspace/getFlutterWidgetPreviews',
  );
  previews = FlutterWidgetPreviews.fromJson(result.result['result']! as Map<String, Object?>);
  if (actualPredicate(previews)) {
    return previews;
  }
  throw StateError(
    'Timed out waiting for previews condition. Last value had ${previews.previews.length} previews.',
  );
}
