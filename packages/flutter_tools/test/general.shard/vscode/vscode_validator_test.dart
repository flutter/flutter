// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/vscode/vscode.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

void main() {
  testWithoutContext('VsCode search locations on windows supports an empty environment', () {
    final FileSystem fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
    final Platform platform = FakePlatform(
      operatingSystem: 'windows',
      environment: <String, String>{},
    );

    expect(VsCode.allInstalled(fileSystem, platform, FakeProcessManager.any()), isEmpty);
  });
}
