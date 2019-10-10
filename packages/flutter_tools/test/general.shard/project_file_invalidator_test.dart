// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/run_hot.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('ProjectFileInvalidator', () {
    final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
    testUsingContext('No last compile', () async {
      expect(
        ProjectFileInvalidator.findInvalidated(lastCompiled: null, urisToMonitor: <Uri>[], packagesPath: ''),
        isEmpty);
    });

    testUsingContext('Empty project', () async {
      expect(
        ProjectFileInvalidator.findInvalidated(lastCompiled: DateTime.now(), urisToMonitor: <Uri>[], packagesPath: ''),
        isEmpty);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
    });

    testUsingContext('Non-existent files are ignored', () async {
      expect(
        ProjectFileInvalidator.findInvalidated(
            lastCompiled: DateTime.now(),
            urisToMonitor: <Uri>[Uri.parse('/not-there-anymore'),],
            packagesPath: '',
          ),
        isEmpty);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
    });
  });
}
