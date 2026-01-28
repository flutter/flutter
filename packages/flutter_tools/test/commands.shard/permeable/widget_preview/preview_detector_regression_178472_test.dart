// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/widget_preview/analytics.dart';
import 'package:flutter_tools/src/widget_preview/dependency_graph.dart';
import 'package:flutter_tools/src/widget_preview/preview_detector.dart';
import 'package:test/fake.dart';
import 'package:watcher/watcher.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/fakes.dart';

void main() {
  group('$PreviewDetector regression test https://github.com/flutter/flutter/issues/178472 -', () {
    late LocalFileSystem fs;
    late FlutterProject project;
    late PreviewDetector previewDetector;
    late FakeWatcher watcher;
    late BufferLogger logger;

    setUp(() {
      fs = LocalFileSystem.test(signals: FakeSignals());
      watcher = FakeWatcher();
      logger = BufferLogger.test();
      project = FlutterProject.fromDirectoryTest(fs.systemTempDirectory.createTempSync('root'));
      previewDetector = PreviewDetector(
        platform: FakePlatform(),
        previewAnalytics: WidgetPreviewAnalytics(
          analytics: getInitializedFakeAnalyticsInstance(
            fakeFlutterVersion: FakeFlutterVersion(),
            // We don't care about analytics in this test, so don't worry about having to
            // provide a local file system.
            fs: MemoryFileSystem.test(),
          ),
        ),
        project: project,
        logger: logger,
        fs: fs,
        onChangeDetected: (_) {},
        onPubspecChangeDetected: (_) {},
        watcherBuilder: (_) => watcher,
      );
    });

    tearDown(() async {
      // Don't explicitly tear down the previewDetector as we've already disposed
      // the underlying analysis context collection. If we try and dispose it again,
      // we'll hang.
      await watcher.close();
    });

    test('do not throw when watch event is sent after the analysis context is disposed', () async {
      final File file = project.directory.childDirectory('lib').childFile('foo.dart')
        ..createSync(recursive: true);
      final String filePath = file.path;
      await previewDetector.initialize();
      await previewDetector.collection.dispose();
      watcher.controller.add(WatchEvent(ChangeType.ADD, filePath));
    });

    test(
      'do not throw when findPreviewFunctions is invoked after the analysis context is disposed',
      () async {
        final File file = project.directory.childDirectory('lib').childFile('foo.dart')
          ..createSync(recursive: true);
        await previewDetector.initialize();
        await previewDetector.collection.dispose();
        final PreviewDependencyGraph result = await previewDetector.mutex.runGuarded(
          () => previewDetector.findPreviewFunctions(file),
        );
        expect(result.entries, isEmpty);
      },
    );
  });
}

class FakeWatcher extends Fake implements Watcher {
  final controller = StreamController<WatchEvent>();

  @override
  Stream<WatchEvent> get events => controller.stream;

  @override
  bool get isReady => true;

  @override
  Future<void> get ready => Future.value();

  Future<void> close() => controller.close();
}
