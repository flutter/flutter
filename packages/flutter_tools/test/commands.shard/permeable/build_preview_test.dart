// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_preview.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  Cache.disableLocking();

  late Directory tempDir;
  late BufferLogger logger;
  final FileSystem fs = LocalFileSystemBlockingSetCurrentDirectory();

  setUp(() {
    tempDir = fs.systemTempDirectory.createTempSync('flutter_tools_packages_test.');
    logger = BufferLogger.test();
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  testUsingContext('flutter build _preview creates preview device', () async {
    final String projectPath = await createProject(
      tempDir,
      arguments: <String>['--no-pub', '--template=app'],
    );
    final BuildPreviewCommand command = BuildPreviewCommand(
      logger: logger,
      verboseHelp: true,
      fs: fs,
      processUtils: globals.processUtils,
      flutterRoot: Cache.flutterRoot!,
      artifacts: globals.artifacts!,
    );
    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>[
      '_preview',
      '--no-pub',
      fs.path.join(projectPath, 'lib', 'main.dart'),
    ]);
    expect(
      fs
          .directory(Cache.flutterRoot)
          .childDirectory('bin')
          .childDirectory('cache')
          .childDirectory('artifacts')
          .childDirectory('flutter_preview')
          .childFile('flutter_preview.exe'),
      exists,
    );
  }, skip: !const LocalPlatform().isWindows); // [intended] Flutter Preview only supported on Windows currently
}
