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

void main() {
  group('$PreviewDetector', () {
    late MemoryFileSystem fs;
    late FlutterProject project;
    late PreviewDetector previewDetector;
    late FakeWatcher watcher;
    late BufferLogger logger;

    var changeCounter = 0;
    void onChangeDetected(_) {
      changeCounter++;
    }

    setUp(() {
      fs = MemoryFileSystem.test(
        style: const LocalPlatform().isWindows ? FileSystemStyle.windows : FileSystemStyle.posix,
      );
      watcher = FakeWatcher();
      logger = BufferLogger.test();
      project = FlutterProject.fromDirectoryTest(fs.systemTempDirectory.createTempSync('root'));
      previewDetector = PreviewDetector(
        platform: FakePlatform(),
        previewAnalytics: WidgetPreviewAnalytics(
          analytics: getInitializedFakeAnalyticsInstance(
            fakeFlutterVersion: FakeFlutterVersion(),
            fs: fs,
          ),
        ),
        project: project,
        logger: logger,
        fs: fs,
        onChangeDetected: onChangeDetected,
        onPubspecChangeDetected: onChangeDetected,
        watcherBuilder: (_) => watcher,
      );
    });

    tearDown(() async {
      await previewDetector.dispose();
      await watcher.close();
    });

    String buildDartFilePathIn(Directory root) {
      final String filePath = fs.path.join(root.path, 'foo.dart');
      root.childFile(filePath).createSync(recursive: true);
      return filePath;
    }

    test('regression test https://github.com/flutter/flutter/issues/178317', () async {
      await previewDetector.initialize();
      expect(project.ephemeralDirectories, isNotEmpty);
      for (final Directory dir in project.ephemeralDirectories) {
        watcher.controller.add(WatchEvent(ChangeType.ADD, buildDartFilePathIn(dir)));
      }
      // Simulates the watcher detecting a change that doesn't have a valid analysis context.
      watcher.controller.add(WatchEvent(ChangeType.ADD, fs.path.join('foo', 'bar.dart')));

      // Changes to .dart sources under ephemeral directories or sources that don't have valid
      // analysis contexts shouldn't trigger the change detection callback.
      expect(changeCounter, 0);
    });
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
