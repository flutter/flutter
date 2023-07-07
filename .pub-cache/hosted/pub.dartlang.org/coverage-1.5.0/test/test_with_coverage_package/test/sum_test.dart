// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

// ignore: avoid_relative_lib_imports
import '../lib/validate_lib.dart';

void main() {
  test('sum', () {
    expect(sum([1, 2]), 3);
  });
}
