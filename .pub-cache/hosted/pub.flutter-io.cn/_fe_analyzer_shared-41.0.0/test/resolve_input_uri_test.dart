// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/relativize.dart';
import 'package:_fe_analyzer_shared/src/util/resolve_input_uri.dart';

test() {
  // data URI scheme is supported by default'.
  expect('data', resolveInputUri('data:,foo').scheme);

  // Custom Dart schemes are recognized by default.
  expect('dart', resolveInputUri('dart:foo').scheme);
  expect('package', resolveInputUri('package:foo').scheme);

  // Unknown schemes are recognized by default.
  expect(isWindows ? 'file' : 'c', resolveInputUri('c:/foo').scheme);
  expect('test', resolveInputUri('test:foo').scheme);
  expect('org-dartlang-foo', resolveInputUri('org-dartlang-foo:bar').scheme);
  expect('test', resolveInputUri('test:/foo').scheme);
  expect('org-dartlang-foo', resolveInputUri('org-dartlang-foo:/bar').scheme);
  expect(
      "${Uri.base.resolve('file.txt')}", "${resolveInputUri('file:file.txt')}");
}

main() {
  // Test platform default.
  test();
  // Test non-Windows behavior.
  isWindows = false;
  test();
  // Test Windows behavior.
  isWindows = true;
  test();
}

void expect(expected, actual) {
  if (expected != actual) {
    throw 'Expected $expected, actual $actual';
  }
}
