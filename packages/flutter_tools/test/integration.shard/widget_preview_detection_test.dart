// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dtd/dtd.dart';
import 'package:file/file.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/widget_preview/dtd_services.dart';
import 'package:flutter_tools/src/widget_preview/dtd_types.dart';

import '../src/common.dart';
import '../src/context.dart';
import 'test_data/basic_project.dart';
import 'test_utils.dart';
import 'widget_preview_test_helpers.dart';

void main() {
  late Directory tempDir;
  Logger? logger;
  DtdLauncher? dtdLauncher;
  late BasicProject project;
  var projectCounter = 0;

  setUp(() async {
    logger = BufferLogger.test();
    tempDir = createResolvedTempDirectorySync('widget_preview_detection_test.');
    projectCounter++;
    project = BasicProject(name: 'test_detection_$projectCounter');
    await project.setUpIn(tempDir);
  });

  tearDown(() async {
    await dtdLauncher?.dispose();
    dtdLauncher = null;
    tryToDelete(tempDir);
  });

  group('widget-preview detection', () {
    testUsingContext('Newly added previews are detected (LSP)', () async {
      dtdLauncher = DtdLauncher(
        logger: logger!,
        artifacts: globals.artifacts!,
        processManager: globals.processManager,
      );

      final Uri dtdUri = await dtdLauncher!.launch();
      final DartToolingDaemon dtdConnection = await DartToolingDaemon.connect(dtdUri);

      final Stream<String> stream = await runWidgetPreview(
        tempDir: tempDir,
        expectedMessages: firstLaunchMessagesWeb,
        dtdUri: dtdUri,
      );

      final reloadCompleter = Completer<void>();
      final StreamSubscription<String> reloadSub = stream.listen((String msg) {
        if (msg.contains('Triggering reload based on update to script:')) {
          if (!reloadCompleter.isCompleted) {
            reloadCompleter.complete();
          }
        }
      });

      final File newFile = tempDir.childDirectory('lib').childFile('new_preview.dart');
      newFile.createSync(recursive: true);
      newFile.writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

@Preview()
Widget myNewPreview() => Container();
''');
      await reloadCompleter.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw StateError('Timed out waiting for reload message in LSP test!'),
      );
      await reloadSub.cancel();

      await waitForPreviews(dtdConnection);
    });

    testUsingContext('Removed previews are detected (LSP)', () async {
      dtdLauncher = DtdLauncher(
        logger: logger!,
        artifacts: globals.artifacts!,
        processManager: globals.processManager,
      );

      final Uri dtdUri = await dtdLauncher!.launch();
      final DartToolingDaemon dtdConnection = await DartToolingDaemon.connect(dtdUri);

      final Stream<String> stream = await runWidgetPreview(
        tempDir: tempDir,
        expectedMessages: firstLaunchMessagesWeb,
        dtdUri: dtdUri,
      );

      final initReloadCompleter = Completer<void>();
      final StreamSubscription<String> initReloadSub = stream.listen((String msg) {
        if (msg.contains('Triggering reload based on update to script:')) {
          if (!initReloadCompleter.isCompleted) {
            initReloadCompleter.complete();
          }
        }
      });

      final File removeFile = tempDir.childDirectory('lib').childFile('remove_preview.dart');
      removeFile.createSync(recursive: true);
      removeFile.writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

@Preview()
Widget myRemovePreview() => Container();
''');
      await initReloadCompleter.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () =>
            throw StateError('Timed out waiting for initial reload message in Remove test!'),
      );
      await initReloadSub.cancel();

      await waitForPreviews(dtdConnection);

      final deleteReloadCompleter = Completer<void>();
      final StreamSubscription<String> deleteReloadSub = stream.listen((String msg) {
        if (msg.contains('Triggering reload based on update to script:')) {
          if (!deleteReloadCompleter.isCompleted) {
            deleteReloadCompleter.complete();
          }
        }
      });

      removeFile.deleteSync();
      await deleteReloadCompleter.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () =>
            throw StateError('Timed out waiting for deletion reload message in Remove test!'),
      );
      await deleteReloadSub.cancel();

      // We can safely check for the empty state immediately here because we
      // already waited for the reload trigger above. The tool only triggers
      // the reload after it has successfully processed the deletion, waited
      // for the Analysis Server, and verified the empty state in DTD.
      // This guarantees that DTD is in its final empty state and won't
      // succeed prematurely.
      await waitForPreviews(
        dtdConnection,
        predicate: (FlutterWidgetPreviews p) => p.previews.isEmpty,
      );
    });

    testUsingContext('Modified previews are detected (LSP)', () async {
      dtdLauncher = DtdLauncher(
        logger: logger!,
        artifacts: globals.artifacts!,
        processManager: globals.processManager,
      );

      final Uri dtdUri = await dtdLauncher!.launch();
      final DartToolingDaemon dtdConnection = await DartToolingDaemon.connect(dtdUri);

      final Stream<String> stream = await runWidgetPreview(
        tempDir: tempDir,
        expectedMessages: firstLaunchMessagesWeb,
        dtdUri: dtdUri,
      );

      final initReloadCompleter = Completer<void>();
      final StreamSubscription<String> initReloadSub = stream.listen((String msg) {
        if (msg.contains('Triggering reload based on update to script:')) {
          if (!initReloadCompleter.isCompleted) {
            initReloadCompleter.complete();
          }
        }
      });

      final File modifyFile = tempDir.childDirectory('lib').childFile('modify_preview.dart');
      modifyFile.createSync(recursive: true);
      modifyFile.writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

@Preview(name: 'Initial')
Widget myModifyPreview() => Container();
''');
      await initReloadCompleter.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () =>
            throw StateError('Timed out waiting for initial reload message in Modify test!'),
      );
      await initReloadSub.cancel();

      await waitForPreviews(dtdConnection);

      final modifyReloadCompleter = Completer<void>();
      final StreamSubscription<String> modifyReloadSub = stream.listen((String msg) {
        if (msg.contains('Triggering reload based on update to script:')) {
          if (!modifyReloadCompleter.isCompleted) {
            modifyReloadCompleter.complete();
          }
        }
      });

      modifyFile.writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

@Preview(name: 'Updated')
Widget myModifyPreview() => Container();
''');
      await modifyReloadCompleter.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () =>
            throw StateError('Timed out waiting for modification reload message in Modify test!'),
      );
      await modifyReloadSub.cancel();

      await waitForPreviews(
        dtdConnection,
        predicate: (FlutterWidgetPreviews p) =>
            p.previews.isNotEmpty && p.previews.first.previewAnnotation.contains("'Updated'"),
      );
    });

    testUsingContext('Previews within libraries with parts are detected (LSP)', () async {
      dtdLauncher = DtdLauncher(
        logger: logger!,
        artifacts: globals.artifacts!,
        processManager: globals.processManager,
      );

      final Uri dtdUri = await dtdLauncher!.launch();
      final DartToolingDaemon dtdConnection = await DartToolingDaemon.connect(dtdUri);

      final Stream<String> stream = await runWidgetPreview(
        tempDir: tempDir,
        expectedMessages: firstLaunchMessagesWeb,
        dtdUri: dtdUri,
      );

      final reloadCompleter = Completer<void>();
      final StreamSubscription<String> reloadSub = stream.listen((String msg) {
        if (msg.contains('Triggering reload based on update to script:')) {
          if (!reloadCompleter.isCompleted) {
            reloadCompleter.complete();
          }
        }
      });

      final File libFile = tempDir.childDirectory('lib').childFile('my_library.dart');
      final File partFile = tempDir.childDirectory('lib').childFile('my_part.dart');

      libFile.createSync(recursive: true);
      partFile.createSync(recursive: true);

      libFile.writeAsStringSync('''
library my_library;

part 'my_part.dart';
''');

      partFile.writeAsStringSync('''
part of 'my_library.dart';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

@Preview()
Widget myPartPreview() => Container();
''');
      await reloadCompleter.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw StateError('Timed out waiting for reload message in Parts test!'),
      );
      await reloadSub.cancel();

      final FlutterWidgetPreviews previews = await waitForPreviews(dtdConnection);

      final FlutterWidgetPreviewDetails preview = previews.previews.first;
      if (preview.functionName != 'myPartPreview') {
        throw StateError(
          r'Wrong preview function detected in Parts test! Found: ${preview.functionName}',
        );
      }
    });
  });
}
