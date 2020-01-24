// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/run_hot.dart';

import 'package:platform/platform.dart';

import '../src/common.dart';
import '../src/mocks.dart';

// assumption: tests have a timeout less than 100 days
final DateTime inFuture = DateTime.now().add(const Duration(days: 100));

void main() {
  BufferLogger bufferLogger;

  setUp(() {
    bufferLogger = BufferLogger(
      terminal: AnsiTerminal(
        stdio: MockStdio(),
        platform: FakePlatform(),
      ),
      outputPreferences: OutputPreferences.test(),
    );
  });

  for (final bool asyncScanning in <bool>[true, false]) {
    testWithoutContext('No last compile, asyncScanning: $asyncScanning', () async {
      final ProjectFileInvalidator projectFileInvalidator = ProjectFileInvalidator(
        fileSystem: MemoryFileSystem(),
        platform: FakePlatform(),
        logger: bufferLogger,
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

    testWithoutContext('Empty project, asyncScanning: $asyncScanning', () async {
      final ProjectFileInvalidator projectFileInvalidator = ProjectFileInvalidator(
        fileSystem: MemoryFileSystem(),
        platform: FakePlatform(),
        logger: bufferLogger,
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

    testWithoutContext('Non-existent files are ignored, asyncScanning: $asyncScanning', () async {
      final ProjectFileInvalidator projectFileInvalidator = ProjectFileInvalidator(
        fileSystem: MemoryFileSystem(),
        platform: FakePlatform(),
        logger: bufferLogger,
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
  }
}
