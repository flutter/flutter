// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../../io.dart';

void main() {
  setUpAll(precompileTestExecutable);

  test('prints the platform name when running on multiple platforms', () async {
    await d.file('test.dart', '''
import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("success", () {});
}
''').create();

    var test = await runTest([
      '-r', 'expanded', '-p', 'chrome', '-p', 'vm', '-j', '1', //
      'test.dart'
    ]);

    expect(test.stdoutStream(), emitsThrough(contains('[VM]')));
    expect(test.stdout, emitsThrough(contains('[Chrome]')));
    await test.shouldExit(0);
  }, tags: ['chrome']);
}
