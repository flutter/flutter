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
    extra.createSync();
    extra.childFile('second.file').writeAsBytesSync(<int>[0]);
    extra.childDirectory('dir').createSync();
    extra.childDirectory('dir').childFile('third.file').writeAsBytesSync(<int>[0]);
    joinCaches(fileSystem, target.path, extra.path);

    expect(target.childFile('second.file').existsSync(), true);
    expect(target.childDirectory('dir').childFile('third.file').existsSync(), true);
    expect(extra.existsSync(), false);
  });
}
