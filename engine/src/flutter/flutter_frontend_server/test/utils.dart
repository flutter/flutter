// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

class TestFailure implements Exception {
  TestFailure(this.message) {
    testFailures++;
  }

  static int testFailures = 0;

  final String message;

  @override
  String toString() => 'TestFailure("$message")';
}

void expect(bool b, String message) {
  if (!b) {
    throw TestFailure(message);
  }
}

void test(String name, void Function() fn) {
  stdout.write('Running $name: ');
  try {
    fn();
    stdout.writeln('Passed');
  } on TestFailure catch (e, st) {
    stdout.writeln('Failed\n$e\n$st');
  }
}

void group(String name, void Function() fn) {
  print('Running group $name');
  fn();
}
