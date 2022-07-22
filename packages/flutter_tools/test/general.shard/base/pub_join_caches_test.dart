// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/dart/pub.dart';

import '../../src/common.dart';

void main() {
  testWithoutContext('join two folders', () async {
    final MemoryFileSystem fileSystem = MemoryFileSystem();
    final Directory target = fileSystem.currentDirectory.childDirectory('target');
    final Directory extra = fileSystem.currentDirectory.childDirectory('extra');
    target.createSync();
    target.childFile('first.file').createSync();
    target.childDirectory('dir').createSync();

    extra.createSync();
    extra.childFile('second.file').writeAsBytesSync(<int>[0]);
    extra.childDirectory('dir').createSync();
    extra.childDirectory('dir').childFile('third.file').writeAsBytesSync(<int>[0]);
    extra.childDirectory('dir_2').createSync();
    extra.childDirectory('dir_2').childFile('fourth.file').writeAsBytesSync(<int>[0]);
    extra.childDirectory('dir_3').createSync();
    extra.childDirectory('dir_3').childFile('fifth.file').writeAsBytesSync(<int>[0]);
    joinCaches(
      fileSystem: fileSystem,
      globalCacheDirectory: target,
      dependencyDirectory: extra,
    );

    expect(target.childFile('second.file').existsSync(), true);
    expect(target.childDirectory('dir').childFile('third.file').existsSync(), false);
    expect(target.childDirectory('dir_2').childFile('fourth.file').existsSync(), true);
    expect(target.childDirectory('dir_3').childFile('fifth.file').existsSync(), true);
    expect(extra.childDirectory('dir').childFile('third.file').existsSync(), true);
  });

  group('needsToJoinCache()', (){
    testWithoutContext('make join', () async {
      final MemoryFileSystem fileSystem = MemoryFileSystem();
      final Directory local = fileSystem.currentDirectory.childDirectory('local');
      final Directory global = fileSystem.currentDirectory.childDirectory('global');

      for (final Directory directory in <Directory>[local, global]) {
        directory.createSync();
        directory.childDirectory('hosted').createSync();
        directory.childDirectory('hosted').childDirectory('pub.dartlang.org').createSync();
      }
      final bool pass = needsToJoinCache(
        fileSystem: fileSystem,
        localCachePath: local.path,
        globalDirectory: global,
      );
      expect(pass, true);
    });

    testWithoutContext('detects when global pub-cache does not have a pub.dartlang.org dir', () async {
      final MemoryFileSystem fileSystem = MemoryFileSystem();
      final Directory local = fileSystem.currentDirectory.childDirectory('local');
      final Directory global = fileSystem.currentDirectory.childDirectory('global');
      local.createSync();
      global.createSync();
      local.childDirectory('hosted').createSync();
      local.childDirectory('hosted').childDirectory('pub.dartlang.org').createSync();

      expect(
        needsToJoinCache(
          fileSystem: fileSystem,
          localCachePath: local.path,
          globalDirectory: global
        ),
        false
      );
    });
    testWithoutContext("don't join global directory null", () async {
      final MemoryFileSystem fileSystem = MemoryFileSystem();
      final Directory local = fileSystem.currentDirectory.childDirectory('local');
      const Directory? global = null;
      local.createSync();
      local.childDirectory('hosted').createSync();
      local.childDirectory('hosted').childDirectory('pub.dartlang.org').createSync();

      expect(
        needsToJoinCache(
          fileSystem: fileSystem,
          localCachePath: local.path,
          globalDirectory: global
        ),
        false
      );
    });
  });
}
