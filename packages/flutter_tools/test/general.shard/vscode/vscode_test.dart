// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/vscode/vscode.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  testUsingContext('VsCode.fromDirectory does not crash when packages.json is malformed', () {
    final BufferLogger bufferLogger = globals.logger as BufferLogger;
    // Create invalid JSON file.
    globals.fs.file(globals.fs.path.join('', 'resources', 'app', 'package.json'))
      ..createSync(recursive: true)
      ..writeAsStringSync('{');

    final VsCode vsCode = VsCode.fromDirectory('', '');

    expect(vsCode.version, Version.unknown);
    expect(bufferLogger.traceText, contains('Error parsing VSCode'));
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
  });
}
