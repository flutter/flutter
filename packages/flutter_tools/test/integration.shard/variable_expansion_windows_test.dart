// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  // Regression test for https://github.com/flutter/flutter/issues/84270 .
  testWithoutContext('dart command will not expand variables on windows', () async {
    final ProcessResult result = await processManager.run(<String>[
      fileSystem.path.join(getFlutterRoot(), 'bin', 'dart.bat'),
      fileSystem.path.join(
        getFlutterRoot(),
        'packages',
        'flutter_tools',
        'test',
        'integration.shard',
        'variable_expansion_windows.dart',
      ),
      r'^(?!Golden).+',
    ]);
    expect(result.stdout, contains(r'args: [^(?!Golden).+]'));
  }, skip: !platform.isWindows);
}
