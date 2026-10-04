// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../src/common.dart';
import '../src/context.dart';
import 'test_data/basic_project.dart';
import 'test_utils.dart';
import 'widget_preview_test_helpers.dart';

void main() {
  late Directory tempDir;
  final project = BasicProject();

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('widget_preview_legacy_test.');
    await project.setUpIn(tempDir);
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  testUsingContext('Newly added previews are detected (Legacy)', () async {
    final Stream<String> stream = await startWidgetPreview(
      tempDir: tempDir,
      legacyPreviewDetection: true,
    );

    final initCompleter = Completer<void>();
    String? scaffoldPath;
    final StreamSubscription<String> subscription = stream.listen((String msg) {
      if (msg.contains('Creating widget preview scaffolding at:')) {
        scaffoldPath = msg.split('Creating widget preview scaffolding at:')[1].trim();
      }
      if (msg.contains('Done loading previews.')) {
        initCompleter.complete();
      }
    });
    await initCompleter.future.timeout(
      const Duration(seconds: 120),
      onTimeout: () =>
          throw StateError('Timed out waiting for initial Done loading in Legacy test!'),
    );
    await subscription.cancel();

    if (scaffoldPath == null) {
      throw StateError('Failed to capture scaffold path in Legacy test!');
    }

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
      if (msg.contains('Triggering reload based on change to preview set:')) {
        reloadCompleter.complete();
      }
    });
    await reloadCompleter.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw StateError('Timed out waiting for reload message in Legacy test!'),
    );
    await reloadSub.cancel();

    final File generatedFile = globals.fs.file(
      globals.fs.path.join(scaffoldPath!, 'lib', 'src', 'generated_preview.dart'),
    );
    if (!generatedFile.existsSync()) {
      throw StateError('generated_preview.dart was not created!');
    }
    final String content = generatedFile.readAsStringSync();
    if (!content.contains('myNewPreview')) {
      throw StateError('generated_preview.dart does not contain myNewPreview!');
    }
  });
}
