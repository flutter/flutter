// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// A test script that invokes compute() to start an isolate.

import 'package:flutter/src/foundation/_isolates_io.dart';

int getLength(String s) {
  throw 10;
}

Future<void> main() async {
  const s = 'hello world';
  try {
    await compute(getLength, s);
  } catch (e) {
    if (e != 10) {
      throw Exception('compute threw bad result');
    }
  }
}
