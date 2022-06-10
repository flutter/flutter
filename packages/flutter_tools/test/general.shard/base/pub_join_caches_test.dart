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
    joinCaches(
        fileSystem: fileSystem,
        targetPath: target.path,
        extraPath: extra.path
    );

    expect(target.childFile('second.file').existsSync(), true);
    expect(target.childDirectory('dir').childFile('third.file').existsSync(), false);
    expect(extra.childDirectory('dir').childFile('third.file').existsSync(), true);
  });

  testWithoutContext('needs to join cache', () async {
    final MemoryFileSystem fileSystem = MemoryFileSystem();
    final Directory local = fileSystem.currentDirectory.childDirectory('local');
    final Directory global = fileSystem.currentDirectory.childDirectory('global');

    for (final Directory directory in <Directory>[local, global]) {
      directory.createSync();
      final Directory pubCache = directory.childDirectory('.pub-cache');
      pubCache.createSync();
      pubCache.childDirectory('hosted').createSync();
      pubCache.childDirectory('hosted').childDirectory('pub.dartlang.org').createSync();
    }
    final bool pass = needsToJoinCache(
        fileSystem: fileSystem,
        localCachePath: local.path,
        globalCachePath: global.path
    );
    expect(pass, true);

    local.childDirectory('.pub-cache').childDirectory('hosted').deleteSync(recursive: true);
    expect(
      needsToJoinCache(
          fileSystem: fileSystem,
          localCachePath: local.path,
          globalCachePath: global.path
      ),
      false
    );

  });
}
