// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/dart.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/mocks.dart';
import '../../src/testbed.dart';

void main() {
  Testbed testbed;

  setUpAll(() {
    Cache.disableLocking();
  });

  tearDownAll(() {
    Cache.enableLocking();
  });

  setUp(() {
    testbed = Testbed(overrides: <Type, Generator>{
      BuildSystem: () => MockBuildSystem(),
    });
  });

  test('invokes assemble for android aot build.', () => testbed.run(() async {
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    when(buildSystem.build(any, any)).thenAnswer((Invocation invocation) async {
      return BuildResult(success: true);
    });
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);

    await createTestCommandRunner(command).run(<String>[
      'build',
      'aot',
      '--target-platform=android-arm',
      '--no-pub',
    ]);

    final Environment environment = verify(buildSystem.build(any, captureAny)).captured.single;
    expect(environment.defines, <String, String>{
      kTargetFile: fs.path.absolute(fs.path.join('lib', 'main.dart')),
      kBuildMode: 'release',
      kTargetPlatform: 'android-arm',
    });
  }));
}

class MockBuildSystem extends Mock implements BuildSystem {}
