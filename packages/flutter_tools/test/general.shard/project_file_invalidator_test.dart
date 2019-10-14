// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/run_hot.dart';

import '../src/common.dart';
import '../src/context.dart';

// assumption: tests have a timeout less than 100 days
final DateTime inFuture = DateTime.now().add(const Duration(days: 100));

void main() {
  group('ProjectFileInvalidator', () {
    testUsingContext('No last compile', () async {
      expect(
        ProjectFileInvalidator.findInvalidated(
          lastCompiled: null,
          urisToMonitor: <Uri>[],
          packagesPath: '',
        ),
        isEmpty,
      );
    });

    testUsingContext('Empty project', () async {
      expect(
        ProjectFileInvalidator.findInvalidated(
          lastCompiled: inFuture,
          urisToMonitor: <Uri>[],
          packagesPath: '',
        ),
        isEmpty,
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager(<FakeCommand>[]),
    });

    testUsingContext('Non-existent files are ignored', () async {
      expect(
        ProjectFileInvalidator.findInvalidated(
          lastCompiled: inFuture,
          urisToMonitor: <Uri>[Uri.parse('/not-there-anymore'),],
          packagesPath: '',
        ),
        isEmpty,
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager(<FakeCommand>[]),
    });
  });
}
