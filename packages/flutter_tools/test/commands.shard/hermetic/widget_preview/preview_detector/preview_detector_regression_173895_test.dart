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
import 'package:flutter_tools/src/widget_preview/preview_detector.dart';
import 'package:test/fake.dart';
import 'package:watcher/watcher.dart';

import '../../../../src/common.dart';
import '../../../../src/fakes.dart';
import '../utils/preview_detector_test_utils.dart';

void main() {
  initializeTestPreviewDetectorState();
  group('$PreviewDetector', () {
    late MemoryFileSystem fs;
    late PreviewDetector previewDetector;
    late FakeWatcher watcher;
    late BufferLogger logger;

    setUp(() {
      fs = MemoryFileSystem.test(style: FileSystemStyle.windows);
      watcher = FakeWatcher();
      logger = BufferLogger.test();
      final FlutterProject project = FlutterProject.fromDirectoryTest(
        fs.systemTempDirectory.createTempSync('root'),
      );
      previewDetector = PreviewDetector(
        // Explicitly set the platform to Windows.
        platform: FakePlatform(operatingSystem: 'windows'),
        previewAnalytics: WidgetPreviewAnalytics(
          analytics: getInitializedFakeAnalyticsInstance(
            fakeFlutterVersion: FakeFlutterVersion(),
            // We don't care about anything written by fake analytics, so we're safe to use a different
            // file system here.
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
      await previewDetector.dispose();
      await watcher.close();
    });

    test(
      'regression test https://github.com/flutter/flutter/issues/173895',
      () async {
        // The Windows directory watcher sometimes decides to shutdown on its own. It's
        // automatically restarted by package:watcher, but the FileSystemException is rethrown and
        // needs to be handled. This test verifies that we no longer crash if this exception is
        // encountered on Windows.
        await previewDetector.initialize();
        watcher.controller.addError(
          const FileSystemException(PreviewDetector.kDirectoryWatcherClosedUnexpectedlyPrefix),
        );
        // Insert an asynchronous gap so the onError handler for the Watcher can be invoked.
        await Future<void>.delayed(Duration.zero);
        expect(logger.traceText, contains(PreviewDetector.kWindowsFileWatcherRestartedMessage));
      },
      skip: !const LocalPlatform().isWindows, // [intended] Test is only valid on Windows.
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
