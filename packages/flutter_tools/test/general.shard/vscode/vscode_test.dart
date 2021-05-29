// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/vscode/vscode.dart';

import '../../src/common.dart';

void main() {
  testWithoutContext('VsCode.fromDirectory does not crash when packages.json is malformed', () {
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    // Create invalid JSON file.
    fileSystem.file(fileSystem.path.join('', 'resources', 'app', 'package.json'))
      ..createSync(recursive: true)
      ..writeAsStringSync('{');

    final VsCode vsCode = VsCode.fromDirectory('', '', fileSystem: fileSystem);

    expect(vsCode.version, Version.unknown);
  });
}
