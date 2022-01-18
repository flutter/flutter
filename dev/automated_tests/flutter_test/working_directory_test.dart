// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

void main() {
  test('working directory is the root of this package', () {
    expect(Directory.current.path, endsWith('automated_tests'));
   });
}
