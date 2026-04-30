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
  final project = BasicProject();

  setUp(() async {
    logger = BufferLogger.test();
    tempDir = createResolvedTempDirectorySync('widget_preview_detection_test.');
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

      final File newFile = tempDir.childDirectory('lib').childFile('new_preview.dart');
      newFile.createSync(recursive: true);
      newFile.writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

@Preview()
Widget myNewPreview() => Container();
''');

      final reloadCompleter = Completer<void>();
      final StreamSubscription<String> reloadSub = stream.listen((String msg) {
        if (msg.contains('Triggering reload based on update to script:')) {
          reloadCompleter.complete();
        }
      });
      await reloadCompleter.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw StateError('Timed out waiting for reload message in LSP test!'),
      );
      await reloadSub.cancel();

      final DTDResponse result = await dtdConnection.call(
        'Lsp',
        'dart/workspace/getFlutterWidgetPreviews',
      );
      final FlutterWidgetPreviews previews = FlutterWidgetPreviews.fromJson(
        result.result['result']! as Map<String, Object?>,
      );
      if (previews.previews.isEmpty) {
        throw StateError('No previews detected in Add test!');
      }
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

      final File removeFile = tempDir.childDirectory('lib').childFile('remove_preview.dart');
      removeFile.createSync(recursive: true);
      removeFile.writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

@Preview()
Widget myRemovePreview() => Container();
''');

      final initReloadCompleter = Completer<void>();
      final StreamSubscription<String> initReloadSub = stream.listen((String msg) {
        if (msg.contains('Triggering reload based on update to script:')) {
          initReloadCompleter.complete();
        }
      });
      await initReloadCompleter.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () =>
            throw StateError('Timed out waiting for initial reload message in Remove test!'),
      );
      await initReloadSub.cancel();

      DTDResponse result = await dtdConnection.call(
        'Lsp',
        'dart/workspace/getFlutterWidgetPreviews',
      );
      FlutterWidgetPreviews previews = FlutterWidgetPreviews.fromJson(
        result.result['result']! as Map<String, Object?>,
      );
      if (previews.previews.isEmpty) {
        throw StateError('Preview was not detected initially in Remove test!');
      }

      removeFile.deleteSync();

      final deleteReloadCompleter = Completer<void>();
      final StreamSubscription<String> deleteReloadSub = stream.listen((String msg) {
        if (msg.contains('Triggering reload based on update to script:')) {
          deleteReloadCompleter.complete();
        }
      });
      await deleteReloadCompleter.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () =>
            throw StateError('Timed out waiting for deletion reload message in Remove test!'),
      );
      await deleteReloadSub.cancel();

      result = await dtdConnection.call('Lsp', 'dart/workspace/getFlutterWidgetPreviews');
      previews = FlutterWidgetPreviews.fromJson(result.result['result']! as Map<String, Object?>);
      if (previews.previews.isNotEmpty) {
        throw StateError('Preview was still detected after deletion!');
      }
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

      final File modifyFile = tempDir.childDirectory('lib').childFile('modify_preview.dart');
      modifyFile.createSync(recursive: true);
      modifyFile.writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

@Preview(name: 'Initial')
Widget myModifyPreview() => Container();
''');

      final initReloadCompleter = Completer<void>();
      final StreamSubscription<String> initReloadSub = stream.listen((String msg) {
        if (msg.contains('Triggering reload based on update to script:')) {
          initReloadCompleter.complete();
        }
      });
      await initReloadCompleter.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () =>
            throw StateError('Timed out waiting for initial reload message in Modify test!'),
      );
      await initReloadSub.cancel();

      DTDResponse result = await dtdConnection.call(
        'Lsp',
        'dart/workspace/getFlutterWidgetPreviews',
      );
      FlutterWidgetPreviews previews = FlutterWidgetPreviews.fromJson(
        result.result['result']! as Map<String, Object?>,
      );
      if (previews.previews.isEmpty) {
        throw StateError('Preview was not detected initially in Modify test!');
      }

      modifyFile.writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

@Preview(name: 'Updated')
Widget myModifyPreview() => Container();
''');

      final modifyReloadCompleter = Completer<void>();
      final StreamSubscription<String> modifyReloadSub = stream.listen((String msg) {
        if (msg.contains('Triggering reload based on update to script:')) {
          modifyReloadCompleter.complete();
        }
      });
      await modifyReloadCompleter.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () =>
            throw StateError('Timed out waiting for modification reload message in Modify test!'),
      );
      await modifyReloadSub.cancel();

      result = await dtdConnection.call('Lsp', 'dart/workspace/getFlutterWidgetPreviews');
      previews = FlutterWidgetPreviews.fromJson(result.result['result']! as Map<String, Object?>);
      if (previews.previews.isEmpty) {
        throw StateError('Preview was lost after modification!');
      }
      final FlutterWidgetPreviewDetails preview = previews.previews.first;
      if (!preview.previewAnnotation.contains("'Updated'")) {
        throw StateError(
          r'Preview annotation was not updated after modification! Found: ${preview.previewAnnotation}',
        );
      }
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

      final reloadCompleter = Completer<void>();
      final StreamSubscription<String> reloadSub = stream.listen((String msg) {
        if (msg.contains('Triggering reload based on update to script:')) {
          reloadCompleter.complete();
        }
      });
      await reloadCompleter.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw StateError('Timed out waiting for reload message in Parts test!'),
      );
      await reloadSub.cancel();

      final DTDResponse result = await dtdConnection.call(
        'Lsp',
        'dart/workspace/getFlutterWidgetPreviews',
      );
      final FlutterWidgetPreviews previews = FlutterWidgetPreviews.fromJson(
        result.result['result']! as Map<String, Object?>,
      );
      if (previews.previews.isEmpty) {
        throw StateError('No previews detected in Parts test!');
      }

      final FlutterWidgetPreviewDetails preview = previews.previews.first;
      if (preview.functionName != 'myPartPreview') {
        throw StateError(
          r'Wrong preview function detected in Parts test! Found: ${preview.functionName}',
        );
      }
    });
  });
}
