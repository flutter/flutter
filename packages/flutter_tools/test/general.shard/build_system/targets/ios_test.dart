// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/ios.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:platform/platform.dart';

import 'package:process/process.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/testbed.dart';

void main() {
  Testbed testbed;

  setUp(() {
    testbed = Testbed();
  });

  test('GenerateDebugSymbols uses the proper arguments', () => testbed.run(() async {
    final Environment environment = Environment.test(
      globals.fs.currentDirectory,
    );
    await const GenerateDebugSymbols().build(environment);
  }, overrides: <Type, Generator>{
    Platform: () => FakePlatform(operatingSystem: 'macos'),
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[
        'xcrun',
        'dsymutil',
        '-o',
        '/dSYMs.noindex/App.framework.dSYM',
        '/App.framework/App',
      ])
    ]),
  }));
}
