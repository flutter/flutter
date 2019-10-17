// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/unpack.dart';

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
    testbed = Testbed();
  });

  test('Returns success for linux unconditionally', () => testbed.run(() async {
    final UnpackCommand unpackCommand = UnpackCommand();
    applyMocksToCommand(unpackCommand);

    await createTestCommandRunner(unpackCommand).run(
      <String>[
        'unpack',
        '--cache-dir=foo',
        '--target-platform=linux-x64',
      ],
    );
  }));
}
