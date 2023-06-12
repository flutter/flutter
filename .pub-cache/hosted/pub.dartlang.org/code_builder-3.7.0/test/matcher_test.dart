// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';

void main() {
  test('describes mismatches', () {
    const actual = Code('final x=1;');
    equalsDart('final y=2;').expectMismatch(actual, '''
  Expected: final y=2;
    Actual: StaticCode:<final x=1;>
     Which: is different.
            Expected: final y=2;
              Actual: final x=1;
                            ^
             Differ at offset 6
''');
  });
}

extension on Matcher {
  void expectMismatch(dynamic actual, String mismatch) {
    expect(
        () => expect(actual, this),
        throwsA(isA<TestFailure>().having(
            (e) => e.message, 'message', equalsIgnoringWhitespace(mismatch))));
  }
}
