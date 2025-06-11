// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/persistent_tool_state.dart';
import 'package:flutter_tools/src/version.dart';

import '../src/common.dart';

void main() {
  testWithoutContext('state can be set and persists', () {
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final Directory directory = fileSystem.directory('state_dir');
    directory.createSync();
    final File stateFile = directory.childFile('.flutter_tool_state');
    final PersistentToolState state1 = PersistentToolState.test(
      directory: directory,
      logger: BufferLogger.test(),
    );
    expect(state1.shouldRedisplayWelcomeMessage, null);
    state1.setShouldRedisplayWelcomeMessage(true);
    expect(stateFile.existsSync(), true);
    expect(state1.shouldRedisplayWelcomeMessage, true);
    state1.setShouldRedisplayWelcomeMessage(false);
    expect(state1.shouldRedisplayWelcomeMessage, false);

    final PersistentToolState state2 = PersistentToolState.test(
      directory: directory,
      logger: BufferLogger.test(),
    );
    expect(state2.shouldRedisplayWelcomeMessage, false);
  });

  testWithoutContext('channel versions can be cached and stored', () {
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final Directory directory = fileSystem.directory('state_dir')..createSync();
    final PersistentToolState state1 = PersistentToolState.test(
      directory: directory,
      logger: BufferLogger.test(),
    );

    state1.updateLastActiveVersion('abc', Channel.master);
    state1.updateLastActiveVersion('ghi', Channel.beta);
    state1.updateLastActiveVersion('jkl', Channel.stable);

    final PersistentToolState state2 = PersistentToolState.test(
      directory: directory,
      logger: BufferLogger.test(),
    );

    expect(state2.lastActiveVersion(Channel.master), 'abc');
    expect(state2.lastActiveVersion(Channel.beta), 'ghi');
    expect(state2.lastActiveVersion(Channel.stable), 'jkl');
  });
}
