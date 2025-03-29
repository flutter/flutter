// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/darwin.dart';
import 'package:flutter_tools/src/project.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../base/logger_test.dart';

void main() {
  testUsingContext(
    'flutterPluginsDependenciesSource matches FlutterProject.flutterPluginsDependenciesFile',
    () {
      final FileSystem fs = MemoryFileSystem.test();
      final Directory projectDir = fs.directory('foo_app')..createSync();
      final Environment environment = Environment.test(
        projectDir,
        artifacts: Artifacts.test(),
        processManager: FakeProcessManager.any(),
        fileSystem: fs,
        logger: FakeLogger(),
      );
      final SourceVisitor visitor = SourceVisitor(environment);
      final FlutterProject project = FlutterProject.fromDirectory(projectDir);

      flutterPluginsDependenciesSource.accept(visitor);

      expect(
        visitor.sources.single.absolute.path,
        project.flutterPluginsDependenciesFile.absolute.path,
      );
    },
  );
}
