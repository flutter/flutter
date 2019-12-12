// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:mockito/mockito.dart';
import 'package:watcher/watcher.dart';

import '../src/common.dart';

// assumption: tests have a timeout less than 100 days
final DateTime inFuture = DateTime.now().add(const Duration(days: 100));
final DateTime inPast = DateTime.now().subtract(const Duration(days: 100));

void main() {
  FakeDirectoryWatcherFactory fakeDirectoryWatcherFactory;
  StreamController<WatchEvent> watchController;
  FakePlatform platform;
  BufferLogger logger;

  setUp(() {
    platform = FakePlatform();
    logger = BufferLogger();
    fakeDirectoryWatcherFactory = FakeDirectoryWatcherFactory();
    watchController = StreamController<WatchEvent>.broadcast();
    when(fakeDirectoryWatcherFactory.watcher.events)
      .thenAnswer((Invocation invocation) {
        return watchController.stream;
      });
  });

  for (bool asyncScanning in <bool>[true, false]) {
    test('No last compile', () async {
      final ProjectFileInvalidator projectFileInvalidator = ProjectFileInvalidator(
        MemoryFileSystem(),
        fakeDirectoryWatcherFactory,
        platform,
        logger,
        '',
      );

      expect(
        await projectFileInvalidator.findInvalidated(
          lastCompiled: null,
          urisToMonitor: <Uri>[],
          packagesPath: '',
          asyncScanning: asyncScanning,
        ),
        isEmpty,
      );
    });

    test('Empty project', () async {
      final ProjectFileInvalidator projectFileInvalidator = ProjectFileInvalidator(
        MemoryFileSystem(),
        fakeDirectoryWatcherFactory,
        platform,
        logger,
        '',
      );

      expect(
        await projectFileInvalidator.findInvalidated(
          lastCompiled: inFuture,
          urisToMonitor: <Uri>[],
          packagesPath: '',
          asyncScanning: asyncScanning,
        ),
        isEmpty,
      );
    });

    test('Non-existent files are ignored', () async {
      final ProjectFileInvalidator projectFileInvalidator = ProjectFileInvalidator(
        MemoryFileSystem(),
        fakeDirectoryWatcherFactory,
        platform,
        logger,
        '',
      );

      expect(
        await projectFileInvalidator.findInvalidated(
          lastCompiled: inFuture,
          urisToMonitor: <Uri>[Uri.parse('/not-there-anymore'),],
          packagesPath: '',
          asyncScanning: asyncScanning,
        ),
        isEmpty,
      );
    });

    test('Does not start watcher if sources cannot be located', () async {
      final ProjectFileInvalidator projectFileInvalidator = ProjectFileInvalidator(
        MemoryFileSystem(),
        fakeDirectoryWatcherFactory,
        platform,
        logger,
        '',
      );
      await projectFileInvalidator.findInvalidated(
        lastCompiled: null,
        urisToMonitor: <Uri>[],
        packagesPath: '',
        asyncScanning: asyncScanning,
      );

      expect(projectFileInvalidator.watchingFlutter, true);
    });

    test('Begins watching flutter directory after detecting change', () async {
      final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
      memoryFileSystem.directory('packages/flutter').createSync(recursive: true);
      final ProjectFileInvalidator projectFileInvalidator = ProjectFileInvalidator(
        memoryFileSystem,
        fakeDirectoryWatcherFactory,
        platform,
        logger,
        '',
      );
      await projectFileInvalidator.findInvalidated(
        lastCompiled: null,
        urisToMonitor: <Uri>[],
        packagesPath: '',
        asyncScanning: asyncScanning,
      );

      expect(projectFileInvalidator.watchingFlutter, false);

      watchController.add(WatchEvent(ChangeType.MODIFY, ''));
      await null;

      expect(projectFileInvalidator.watchingFlutter, true);
      expect(logger.traceText, contains('Adding flutter sources to watch list.'));
    });

    test('Does not stat file from flutter directory if watchingFlutter is false', () async {
      final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
      memoryFileSystem.file('packages/flutter/lib/foo.dart')
        ..createSync(recursive: true)
        ..setLastModifiedSync(inFuture);
      final ProjectFileInvalidator projectFileInvalidator = ProjectFileInvalidator(
        memoryFileSystem,
        fakeDirectoryWatcherFactory,
        platform,
        logger,
        '',
      );
      final List<Uri> results = await projectFileInvalidator.findInvalidated(
        lastCompiled: inPast,
        urisToMonitor: <Uri>[Uri.parse('packages/flutter/lib/foo.dart')],
        packagesPath: '',
        asyncScanning: asyncScanning,
      );

      expect(results, hasLength(1)); // only contains packages file.
    });

    test('Does stat file from flutter directory if watchingFlutter is true', () async {
      final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
      memoryFileSystem.file('packages/flutter/lib/foo.dart')
        ..createSync(recursive: true)
        ..setLastModifiedSync(inFuture);
      final ProjectFileInvalidator projectFileInvalidator = ProjectFileInvalidator(
        memoryFileSystem,
        fakeDirectoryWatcherFactory,
        platform,
        logger,
        '',
      );
      await projectFileInvalidator.findInvalidated(
        lastCompiled: null,
        urisToMonitor: <Uri>[],
        packagesPath: '',
        asyncScanning: asyncScanning,
      );
      watchController.add(WatchEvent(ChangeType.MODIFY, ''));
      await null;

      final List<Uri> results = await projectFileInvalidator.findInvalidated(
        lastCompiled: inPast,
        urisToMonitor: <Uri>[Uri.parse('packages/flutter/lib/foo.dart')],
        packagesPath: '',
        asyncScanning: asyncScanning,
      );

      expect(results, hasLength(2));
    });
  }
}

class FakeDirectoryWatcherFactory implements DirectoryWatcherFactory {
  Watcher watcher = MockWatcher();

  @override
  Watcher watchDirectory(String path) {
    return watcher;
  }
}

class MockWatcher extends Mock implements Watcher {}
