// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/flutter_project_metadata.dart';
import 'package:flutter_tools/src/isolated/mustache_template.dart';
import 'package:flutter_tools/src/template.dart';

import '../src/common.dart';
import '../src/fakes.dart';
import '../src/test_flutter_command_runner.dart';
import '../src/throwing_pub.dart';
import 'test_utils.dart';

void main() {
  group('pass analyze template:', () {
    late Directory tempDir;

    setUp(() {
      tempDir = fileSystem.systemTempDirectory.createTempSync(
        'flutter_tools_analyze_all_template.',
      );
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    // Iterate the enum rather than a hand-written list, so templates added
    // later (such as package_ffi) are analyzed without updating this test.
    for (final FlutterTemplateType template in FlutterTemplateType.values) {
      test('analysis for ${template.cliName}', () async {
        final String flutterRoot = getFlutterRoot();
        final logger = BufferLogger.test();
        final cache = Cache.test(
          flutterRoot: flutterRoot,
          rootOverride: fileSystem.directory(flutterRoot),
          fileSystem: fileSystem,
          logger: logger,
          platform: platform,
          processManager: processManager,
        );
        final toolContext = FakeToolContext(
          cache: cache,
          fs: fileSystem,
          logger: logger,
          os: OperatingSystemUtils(
            fileSystem: fileSystem,
            logger: logger,
            platform: platform,
            processManager: processManager,
          ),
          platform: platform,
          processManager: processManager,
        );
        final featureFlags = TestFeatureFlags(isNativeAssetsEnabled: true);
        final String projectPath = fileSystem.path.join(tempDir.path, 'flutter_project');
        final command = CreateCommand(
          androidContext: FakeAndroidContext(),
          appleContext: FakeAppleContext(),
          featureFlags: featureFlags,
          pub: const ThrowingPub(),
          templatePathProvider: TemplatePathProvider(flutterRoot: flutterRoot),
          templateRenderer: const MustacheTemplateRenderer(),
          toolContext: toolContext,
        );
        final CommandRunner<void> runner = createTestCommandRunner(
          command,
          null,
          toolContext,
          featureFlags,
          const ThrowingPub(),
        );
        await runner.run(<String>[
          'create',
          '--no-pub',
          '--template',
          template.cliName,
          projectPath,
        ]);
        final ProcessResult result = await processManager.run(<String>[
          'flutter',
          'analyze',
        ], workingDirectory: projectPath);

        expect(result, const ProcessResultMatcher());
      });
    }
  });
}
