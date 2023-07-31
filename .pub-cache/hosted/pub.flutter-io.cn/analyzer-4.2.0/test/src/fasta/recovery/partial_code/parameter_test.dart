// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  ParameterTest().buildAll();
}

class ParameterTest extends PartialCodeTest {
  buildAll() {
    buildTests(
      'required',
      [
        TestDescriptor(
          'functionType_noIdentifier',
          'f(Function(void)) {}',
          [
            ScannerErrorCode.EXPECTED_TOKEN,
          ],
          'f(Function(void) _s_) {}',
          failing: ['eof'],
        ),
        TestDescriptor(
          'typeArgument_noGt',
          '''
          class C<E> {}
          f(C<int Function(int, int) c) {}
          ''',
          [
            ScannerErrorCode.EXPECTED_TOKEN,
          ],
          '''
          class C<E> {}
          f(C<int Function(int, int)> c) {}
          ''',
          failing: ['eof'],
        ),
      ],
      [],
    );
  }
}
