// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/pre_run_validator.dart';

import '../src/common.dart';
import '../src/fake_process_manager.dart';

void main() {
  group('PreRunValidator', () {
    late MemoryFileSystem fs;
    late FakePlatform platform;
    late UserMessages userMessages;
    late BufferLogger logger;
    late Cache cache;

    setUp(() {
      fs = MemoryFileSystem.test();
      platform = FakePlatform(environment: <String, String>{});
      userMessages = UserMessages();
      logger = BufferLogger.test();
      cache = Cache.test(
        fileSystem: fs,
        processManager: FakeProcessManager.any(),
        logger: logger,
        platform: platform,
      );
    });

    testWithoutContext(
      'succeeds when packages/flutter_tools exists with parameter flutterRoot',
      () {
        final String flutterRoot = fs.path.join('custom', 'flutter', 'root');
        final Directory toolsDir = fs.directory(
          fs.path.join(flutterRoot, 'packages', 'flutter_tools'),
        );
        toolsDir.createSync(recursive: true);

        final validator = PreRunValidator(
          fileSystem: fs,
          flutterRoot: flutterRoot,
          platform: platform,
          userMessages: userMessages,
        );

        expect(() => validator.validate(), returnsNormally);
      },
    );

    testWithoutContext('succeeds when packages/flutter_tools exists with cache.flutterRoot', () {
      final String flutterRoot = cache.flutterRoot;
      final Directory toolsDir = fs.directory(
        fs.path.join(flutterRoot, 'packages', 'flutter_tools'),
      );
      toolsDir.createSync(recursive: true);

      final validator = PreRunValidator(
        fileSystem: fs,
        cache: cache,
        platform: platform,
        userMessages: userMessages,
      );

      expect(() => validator.validate(), returnsNormally);
    });

    testWithoutContext('succeeds when falls back to Cache.defaultFlutterRoot', () {
      final String flutterRoot = Cache.defaultFlutterRoot(
        platform: platform,
        fileSystem: fs,
        userMessages: userMessages,
      );
      final Directory toolsDir = fs.directory(
        fs.path.join(flutterRoot, 'packages', 'flutter_tools'),
      );
      toolsDir.createSync(recursive: true);

      final validator = PreRunValidator(
        fileSystem: fs,
        platform: platform,
        userMessages: userMessages,
      );

      expect(() => validator.validate(), returnsNormally);
    });

    testWithoutContext('throws ToolExit when packages/flutter_tools does not exist', () {
      final String flutterRoot = cache.flutterRoot;
      final Directory toolsDir = fs.directory(
        fs.path.join(flutterRoot, 'packages', 'flutter_tools'),
      );
      expect(toolsDir.existsSync(), isFalse);

      final validator = PreRunValidator(
        fileSystem: fs,
        cache: cache,
        platform: platform,
        userMessages: userMessages,
      );

      expect(
        () => validator.validate(),
        throwsToolExit(message: 'Flutter SDK installation appears corrupted'),
      );
    });
  });
}
