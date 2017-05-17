// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:platform/platform.dart';

import 'package:flutter_tools/src/cache.dart';

import 'src/context.dart';

void main() {
  group('$Cache.checkLockAcquired', () {
    setUp(() {
      Cache.enableLocking();
    });

    tearDown(() {
      // Restore locking to prevent potential side-effects in
      // tests outside this group (this option is globally shared).
      Cache.enableLocking();
    });

    test('should throw when locking is not acquired', () {
      expect(() => Cache.checkLockAcquired(), throwsStateError);
    });

    test('should not throw when locking is disabled', () {
      Cache.disableLocking();
      Cache.checkLockAcquired();
    });

    testUsingContext('should not throw when lock is acquired', () async {
      await Cache.lock();
      Cache.checkLockAcquired();
    }, overrides: <Type, Generator>{
      FileSystem: () => new MockFileSystem(),
    });

    testUsingContext('should not throw when FLUTTER_ALREADY_LOCKED is set', () async {
      Cache.checkLockAcquired();
    }, overrides: <Type, Generator>{
      Platform: () => new FakePlatform()..environment = <String, String>{'FLUTTER_ALREADY_LOCKED': 'true'},
    });
  });
}

class MockFileSystem extends MemoryFileSystem {
  @override
  File file(dynamic path) {
    return new MockFile();
  }
}

class MockFile extends Mock implements File {
  @override
  Future<RandomAccessFile> open({FileMode mode: FileMode.READ}) async {
    return new MockRandomAccessFile();
  }
}

class MockRandomAccessFile extends Mock implements RandomAccessFile {}
