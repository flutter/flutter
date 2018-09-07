// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';

import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/base/io.dart' show InternetAddress, SocketException;

import 'src/common.dart';
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
      FileSystem: () => MockFileSystem(),
    });

    testUsingContext('should not throw when FLUTTER_ALREADY_LOCKED is set', () async {
      Cache.checkLockAcquired();
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform()..environment = <String, String>{'FLUTTER_ALREADY_LOCKED': 'true'},
    });
  });

  group('Cache', () {
    test('should not be up to date, if some cached artifact is not', () {
      final CachedArtifact artifact1 = MockCachedArtifact();
      final CachedArtifact artifact2 = MockCachedArtifact();
      when(artifact1.isUpToDate()).thenReturn(true);
      when(artifact2.isUpToDate()).thenReturn(false);
      final Cache cache = Cache(artifacts: <CachedArtifact>[artifact1, artifact2]);
      expect(cache.isUpToDate(), isFalse);
    });
    test('should be up to date, if all cached artifacts are', () {
      final CachedArtifact artifact1 = MockCachedArtifact();
      final CachedArtifact artifact2 = MockCachedArtifact();
      when(artifact1.isUpToDate()).thenReturn(true);
      when(artifact2.isUpToDate()).thenReturn(true);
      final Cache cache = Cache(artifacts: <CachedArtifact>[artifact1, artifact2]);
      expect(cache.isUpToDate(), isTrue);
    });
    test('should update cached artifacts which are not up to date', () async {
      final CachedArtifact artifact1 = MockCachedArtifact();
      final CachedArtifact artifact2 = MockCachedArtifact();
      when(artifact1.isUpToDate()).thenReturn(true);
      when(artifact2.isUpToDate()).thenReturn(false);
      final Cache cache = Cache(artifacts: <CachedArtifact>[artifact1, artifact2]);
      await cache.updateAll();
      verifyNever(artifact1.update());
      verify(artifact2.update());
    });
    testUsingContext('failed storage.googleapis.com download shows China warning', () async {
      final CachedArtifact artifact1 = MockCachedArtifact();
      final CachedArtifact artifact2 = MockCachedArtifact();
      when(artifact1.isUpToDate()).thenReturn(false);
      when(artifact2.isUpToDate()).thenReturn(false);
      final MockInternetAddress address = MockInternetAddress();
      when(address.host).thenReturn('storage.googleapis.com');
      when(artifact1.update()).thenThrow(SocketException(
        'Connection reset by peer',
        address: address,
      ));
      final Cache cache = Cache(artifacts: <CachedArtifact>[artifact1, artifact2]);
      try {
        await cache.updateAll();
        fail('Mock thrown exception expected');
      } catch (e) {
        verify(artifact1.update());
        // Don't continue when retrieval fails.
        verifyNever(artifact2.update());
        expect(
          testLogger.errorText,
          contains('https://github.com/flutter/flutter/wiki/Using-Flutter-in-China'),
        );
      }
    });
  });

  testUsingContext('flattenNameSubdirs', () {
    expect(flattenNameSubdirs(Uri.parse('http://flutter.io/foo/bar')), 'flutter.io/foo/bar');
    expect(flattenNameSubdirs(Uri.parse('http://docs.flutter.io/foo/bar')), 'docs.flutter.io/foo/bar');
    expect(flattenNameSubdirs(Uri.parse('https://www.flutter.io')), 'www.flutter.io');
  }, overrides: <Type, Generator>{
    FileSystem: () => MockFileSystem(),
  });
}

class MockFileSystem extends ForwardingFileSystem {
  MockFileSystem() : super(MemoryFileSystem());

  @override
  File file(dynamic path) {
    return MockFile();
  }
}

class MockFile extends Mock implements File {
  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) async {
    return MockRandomAccessFile();
  }
}

class MockRandomAccessFile extends Mock implements RandomAccessFile {}
class MockCachedArtifact extends Mock implements CachedArtifact {}
class MockInternetAddress extends Mock implements InternetAddress {}
