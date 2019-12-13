// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:meta/meta.dart';

import '../src/common.dart';
import '../src/context.dart';

// assumption: tests have a timeout less than 100 days
final DateTime inFuture = DateTime.now().add(const Duration(days: 100));

void main() {
  group('ProjectFileInvalidator', () {
    _testProjectFileInvalidator(asyncScanning: false);
  });
  group('ProjectFileInvalidator (async scanning)', () {
    _testProjectFileInvalidator(asyncScanning: true);
  });
}

void _testProjectFileInvalidator({@required bool asyncScanning}) {
  const ProjectFileInvalidator projectFileInvalidator = ProjectFileInvalidator();

  testUsingContext('No last compile', () async {
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

  testUsingContext('Empty project', () async {
    expect(
      await projectFileInvalidator.findInvalidated(
        lastCompiled: inFuture,
        urisToMonitor: <Uri>[],
        packagesPath: '',
        asyncScanning: asyncScanning,
      ),
      isEmpty,
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Non-existent files are ignored', () async {
    expect(
      await projectFileInvalidator.findInvalidated(
        lastCompiled: inFuture,
        urisToMonitor: <Uri>[Uri.parse('/not-there-anymore'),],
        packagesPath: '',
        asyncScanning: asyncScanning,
      ),
      isEmpty,
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
  });
}
