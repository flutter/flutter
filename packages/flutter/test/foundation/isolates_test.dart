// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

int test1(int value) {
  return value + 1;
}

int test2(int value) {
  throw 2;
}

Future<int> test1Async(int value) async {
  return value + 1;
}

Future<int> test2Async(int value) async {
  throw 2;
}

void main() {
  test('compute()', () async {
    expect(await compute(test1, 0), 1);
    expect(compute(test2, 0), throwsException);

    expect(await compute(test1Async, 0), 1);
    expect(compute(test2Async, 0), throwsException);
  }, skip: kIsWeb);
}
