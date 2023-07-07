// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/codes.dart';

void main() {
  test('#a', {'a': 'b'}, 'b');
  test('#a #a', {'a': 'b'}, 'b b');
  test('#a #b', {'a': 'b', 'b': 'c'}, 'b c');
  test('#a #b', {'a': '#b', 'b': 'c'}, '#b c');

  test('#a1 #a2', {'a1': 'b', 'a2': 'c'}, 'b c');
  test('#a1 #a2', {'a1': '#a2', 'a2': 'a2'}, '#a2 a2');
  test('#a1 #a1 #a2 #a2', {'a1': '#a2', 'a2': 'b'}, '#a2 #a2 b b');
}

void test(
    String template, Map<String, dynamic>? arguments, String expectedResult) {
  expect(expectedResult, applyArgumentsToTemplate(template, arguments!),
      'Unexpected result for replacing $arguments in "$template"');
}

void expect(expected, actual, String message) {
  if (expected != actual) {
    throw '$message: Expected "$expected", actual "$actual".';
  }
}
