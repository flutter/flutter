// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// A test script that invokes compute() to start an isolate.

import 'dart:isolate';

import 'package:flutter/src/foundation/_isolates_io.dart';

int getLength(ReceivePort s) {
  return 0;
}

Future<void> main() async {
  final s = ReceivePort();

  var wasError = false;
  try {
    await compute(getLength, s);
  } on Object {
    wasError = true;
  }
  s.close();

  assert(wasError);
}
