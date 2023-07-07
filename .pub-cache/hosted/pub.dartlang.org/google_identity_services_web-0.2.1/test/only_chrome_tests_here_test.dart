// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_print

@TestOn('vm')

import 'package:test/test.dart';

void main() {
  test('Tell the user where to find the real tests', () {
    print('---');
    print('This package uses `dart test -p chrome` for its tests.');
    print('See `README.md` for more info.');
    print('---');
  });
}
