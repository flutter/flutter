// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/java_core.dart';
import 'package:test/test.dart';

main() {
  test('formatList', () {
    expect(
      format('Hello, {0} {1}!', 'John', 'Doe'),
      'Hello, John Doe!',
    );
  });

  test('formatList', () {
    expect(
      formatList('Hello, {0} {1}!', ['John', 'Doe']),
      'Hello, John Doe!',
    );
  });
}
