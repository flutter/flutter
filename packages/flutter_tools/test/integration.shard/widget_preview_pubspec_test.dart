// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';

import '../src/common.dart';
import '../src/context.dart';
import 'test_data/basic_project.dart';
import 'test_utils.dart';
import 'widget_preview_test_helpers.dart';

void main() {
  late Directory tempDir;
  final project = BasicProject();

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('widget_preview_pubspec_test.');
    await project.setUpIn(tempDir);
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  testUsingContext('Modified pubspec.yaml is detected (LSP)', () async {
    final Stream<String> stream = await startWidgetPreview(tempDir: tempDir);

    final initCompleter = Completer<void>();
    final StreamSubscription<String> subscription = stream.listen((String msg) {
      if (msg.contains('Done loading previews.')) {
        initCompleter.complete();
      }
    });
    await initCompleter.future.timeout(
      const Duration(seconds: 120),
      onTimeout: () =>
          throw StateError('Timed out waiting for initial Done loading in Pubspec test!'),
    );
    await subscription.cancel();

    final File pubspecFile = tempDir.childFile('pubspec.yaml');
    final String content = pubspecFile.readAsStringSync();
    pubspecFile.writeAsStringSync('''
$content
flutter:
  assets:
    - assets/my_asset.png
''');

    final reloadCompleter = Completer<void>();
    final StreamSubscription<String> reloadSub = stream.listen((String msg) {
      if (msg.contains('Triggering restart based on update to pubspec.yaml:')) {
        reloadCompleter.complete();
      }
    });
    await reloadCompleter.future.timeout(
      const Duration(seconds: 120),
      onTimeout: () => throw StateError('Timed out waiting for reload message in Pubspec test!'),
    );
    await reloadSub.cancel();
  });
}
