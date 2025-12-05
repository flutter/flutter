// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// A test script that invokes compute() to start an isolate.

import 'package:flutter/src/foundation/_isolates_io.dart';

int getLength(String s) {
  return s.length;
}

Future<void> main() async {
  const s = 'hello world';
  final int result = await compute(getLength, s);
  if (result != s.length) {
    throw Exception('compute returned bad result');
  }
}
