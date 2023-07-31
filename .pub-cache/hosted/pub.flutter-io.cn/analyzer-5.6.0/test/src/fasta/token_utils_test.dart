// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart';
import 'package:analyzer/src/fasta/token_utils.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreviousTokenTest);
  });
}

@reflectiveTest
class PreviousTokenTest {
  void test_findPrevious() {
    Token a =
        scanString('a b c /* comment */ d e', includeComments: true).tokens;
    Token b = a.next!;
    Token c = b.next!;
    Token d = c.next!;
    Token e = d.next!;

    expect(findPrevious(a, b), a);
    expect(findPrevious(a, c), b);
    expect(findPrevious(a, d), c);
    expect(findPrevious(d.precedingComments!, e), d);

    Token x = scanString('x').tokens;
    expect(findPrevious(a, x), null);
    expect(findPrevious(b, b), null);
    expect(findPrevious(d, b), null);
    expect(findPrevious(a, null), null);
  }
}
