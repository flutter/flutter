// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/ios/ios_deploy.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import '../../src/common.dart';

class MockArtifacts extends Mock implements Artifacts {}
class MockCache extends Mock implements Cache {}
class MockLogger extends Mock implements Logger {}
class MockPlatform extends Mock implements Platform {}
class MockProcessManager extends Mock implements ProcessManager {}

void main () {
  group('IOSDeploy()', () {
    Artifacts artifacts;
    Cache cache;
    Logger logger;
    Platform platform;
    ProcessManager processManager;

    setUp(() {
      artifacts = MockArtifacts();
      cache = MockCache();
      logger = MockLogger();
      platform = MockPlatform();
      processManager = MockProcessManager();
    });

    testWithoutContext('successfully instantiates', () {
      IOSDeploy(
        artifacts: artifacts,
        cache: cache,
        logger: logger,
        platform: platform,
        processManager: processManager,
      );
    });
  });
}
