// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Running in unsound null-safety mode is intended to test for potential miscasts
// or invalid assertions.

import 'package:flutter/src/foundation/_isolates_io.dart';
import 'package:flutter/src/foundation/isolates.dart' as isolates;

int? returnInt(int? arg) {
  return arg;
}

Future<int?> returnIntAsync(int? arg) {
  return Future<int>.value(arg);
}

Future<void> testCompute<T>(isolates.ComputeCallback<T, T> callback, T input) async {
  if (input != await compute(callback, input)) {
    throw Exception('compute returned bad result');
  }
}

void main() async {
  await testCompute(returnInt, 10);
  await testCompute(returnInt, null);
  await testCompute(returnIntAsync, 10);
  await testCompute(returnIntAsync, null);
}
